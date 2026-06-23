unit NetConn;

interface

uses System.SysUtils, System.Classes, System.SyncObjs, Winapi.ActiveX,
     AbstractDev, IdTCPClient, IdGlobal, RootImpl, DeviceIntf, debug_except, RootIntf, ExtendIntf, tools, Container;

type
  // Реализация для TCP
  ENetConnectIOException = class(EConnectIOException);

  TNetConnectIO = class(TAbstractNetConnectIO, INetConnectIO)
  protected
    FNet: TIdTCPClient;
    FLock: TCriticalSection;
    FEvent: TEvent;
   type
    TReadThread = class(TThread)
    protected
      NetConnect: TNetConnectIO;
      FDbgName: string;
      procedure Execute; override;
      constructor Create(AOwner: TNetConnectIO; const DbgName: string);
    end;
   var
    FReadThread: TReadThread;
    procedure SetConnectInfo(const Value: string); override;
    procedure Open; override;
    procedure Close; override;
    function IsOpen: Boolean; override;
  public
    constructor Create(); override;
    destructor Destroy; override;
    procedure CheckOpen; override;
    procedure Send(Data: Pointer; Cnt: Integer; Event: TReceiveDataRef = nil; WaitTime: Integer = -1); override;
  end;

implementation

{ TNetConnectIO }

constructor TNetConnectIO.Create();
begin
  inherited;
  FEvent := TEvent.Create;
  FLock := TCriticalSection.Create;
  FConnectInfo := '192.168.43.5:5000';
  FNet := TIdTCPClient.Create(nil);
  FNet.Port := 5000;
  FNet.ConnectTimeout := 2000;
  FNet.Host := '192.168.43.5';
  FReadThread :=  TReadThread.Create(Self, Name);
end;

destructor TNetConnectIO.Destroy;
begin
  FReadThread.Terminate;
  FEvent.SetEvent;
  FReadThread.WaitFor;
  FReadThread.Free;
  FNet.Free;
  FLock.Free;
  FEvent.Free;
  inherited;
end;

procedure TNetConnectIO.Send(Data: Pointer; Cnt: Integer; Event: TReceiveDataRef; WaitTime: Integer);
 var
  b: TIdBytes;
begin
  if Assigned(FProtocol) then
   begin
    if not Assigned(Data) then raise ENetConnectIOException.Create('Data not initialized');
    FEventReceiveData := Event;
    if WaitTime >= 0 then FTimerRxTimeOut.Interval := WaitTime
    else FTimerRxTimeOut.Interval := FComWait;
    SetLength(b, $200);
    Move(Data^,b[0], Cnt);
    FProtocol.TxChar(Self, @b[0], Cnt);
    FTimerRxTimeOut.Enabled := True;
    CheckOpen;
    FLock.Acquire;
    try
     if Cnt > 0 then
      begin
       FEvent.SetEvent;
       FNet.IOHandler.Write(b, cnt);
      end;
    finally
     FLock.Release;
    end;
    if Assigned(FIOEvent) then FIOEvent(iosTx, @b[0], cnt);
   end
  else raise ENetConnectIOException.Create(RS_SendData);
end;

procedure TNetConnectIO.CheckOpen;
begin
  FLock.Acquire;
  try
   if not FNet.Connected then raise ENetConnectIOException.CreateFmt('Connection closed %s', [FNet.Host]);
  finally
   FLock.Release;
  end;
end;

procedure TNetConnectIO.Close;
begin
  inherited Close;
  try
    FLock.Acquire;
    try
     FNet.Disconnect;
    finally
     FLock.Release;
    end;
  except
   S_Status := S_Status + [iosError];
   raise
  end;
end;

function TNetConnectIO.IsOpen: Boolean;
begin
  FLock.Acquire;
  try
   Result := FNet.Connected;
   UpdateOpenStatus(Result);
  finally
   FLock.Release;
  end;
end;

procedure TNetConnectIO.Open;
begin
  FLock.Acquire;
  try
    if FNet.Connected then raise ENetConnectIOException.CreateFmt(RS_NeedCloseNet, [FNet.Host]);
    try
     FNet.Connect;
     inherited Open;
    except
     S_Status := S_Status + [iosError];
     raise
    end;
  finally
   FLock.Release;
  end;
end;

procedure TNetConnectIO.SetConnectInfo(const Value: string);
begin
  if not SameText(FConnectInfo, Value) then
   begin
    if IsOpen then raise EComConnectIOException.CreateFmt(RS_NeedCloseNet, [FNet.Host]);
    FNet.Host := ExtractHost(Value);
    FNet.Port := ExtractPort(Value);
    inherited SetConnectInfo(Value);
   end;
end;

{ TNetConnectIO.TReadThread }

constructor TNetConnectIO.TReadThread.Create(AOwner: TNetConnectIO; const DbgName: string);
begin
  NetConnect := AOwner;
  FDbgName := DbgName;
  inherited Create(False);
end;

procedure TNetConnectIO.TReadThread.Execute;
 var
  cnt: Integer;
  VBuffer: TIdBytes;
  function UpdateCnt: boolean;
  begin
    cnt := 0;
    NetConnect.FLock.Acquire;
    try
     if not NetConnect.FNet.Connected then Exit(False);
     cnt := NetConnect.FNet.IOHandler.InputBuffer.Size;
     Result := cnt > 0;
    finally
     NetConnect.FLock.Release;
    end;
  end;
begin
  CoInitialize(nil);
  try
  NameThreadForDebugging(FDbgName);
  with NetConnect do while not Terminated do
  try
   Fevent.WaitFor();
   Fevent.ResetEvent;
   while FTimerRxTimeOut.Enabled and not Terminated do
    begin
     if not UpdateCnt then Continue;
     SetLength(VBuffer, 0);
     FLock.Acquire;
     try
      FNet.IOHandler.ReadBytes(VBuffer, cnt, false);
     finally
      FLock.Release;
     end;
     if (FICount+cnt) > $8000 then FICount := 0;
     Move(VBuffer[0], FInput[FICount], cnt);
     Inc(FICount, cnt);
     Synchronize(procedure
     begin
       if Assigned(FIOEvent) then FIOEvent(iosRx, @FInput[FICount-cnt], cnt);
       if Assigned(FProtocol) then FProtocol.EventRxChar(NetConnect);
     end);
    end;
  except
   on E: Exception do TDebug.DoException(E, False);
  end;
  finally
    CoUninitialize;
  end;
end;

initialization
  RegisterClass(TNetConnectIO);
  TRegister.AddType<TNetConnectIO, IConnectIO>.LiveTime(ltSingletonNamed);
finalization
  GContainer.RemoveModel<TNetConnectIO>;
end.

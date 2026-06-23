unit UDPBinConn;

interface

uses System.SysUtils, System.Classes, System.SyncObjs, Winapi.ActiveX,   IdStack,
     AbstractDev, IdUDPClient, IdGlobal, RootImpl, DeviceIntf, debug_except, RootIntf, ExtendIntf, tools, Container;

resourcestring
  RS_UDPData_NotInit='Данные не инициализированны';
  RS_UDP_Connclose='Соединение закрыто %s';

type
  // Реализация для TCP
  ENetConnectIOException = class(EConnectIOException);

  TUDPBinConnectIO = class(TAbstractNetConnectIO, IUDPBinConnectIO)
  protected
    FNet: TIdUDPClient;
   // FLock: TCriticalSection;
    FEvent: TEvent;
   type
    TReadThread = class(TThread)
    protected
      NetConnect: TUDPBinConnectIO;
      FDbgName: string;
      procedure Execute; override;
      constructor Create(AOwner: TUDPBinConnectIO; const DbgName: string);
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

constructor TUDPBinConnectIO.Create();
begin
  inherited;
  FEvent := TEvent.Create;
 // FLock := TCriticalSection.Create;
  FConnectInfo := '192.168.4.1:5000';
  FNet := TIdUDPClient.Create(nil);
  FNet.Port := 5000;
//  FNet.ConnectTimeout := 2000;
  FNet.Host := '192.168.4.1';
  FReadThread :=  TReadThread.Create(Self, Name);
end;

destructor TUDPBinConnectIO.Destroy;
begin
  FReadThread.Terminate;
  FEvent.SetEvent;
  FReadThread.WaitFor;
  FReadThread.Free;
  FNet.Free;
 // FLock.Free;
  FEvent.Free;
  inherited;
end;

procedure TUDPBinConnectIO.Send(Data: Pointer; Cnt: Integer; Event: TReceiveDataRef; WaitTime: Integer);
 var
  b: TIdBytes;
begin
  if Assigned(FProtocol) then
   begin
    if not Assigned(Data) then raise ENetConnectIOException.Create(RS_UDPData_NotInit);
    FEventReceiveData := Event;
    if WaitTime >= 0 then FTimerRxTimeOut.Interval := WaitTime
    else FTimerRxTimeOut.Interval := FComWait;
    SetLength(b, $200);
    Move(Data^,b[0], Cnt);
    FProtocol.TxChar(Self, @b[0], Cnt);
    SetLength(b, Cnt);
    FTimerRxTimeOut.Enabled := True;
    CheckOpen;
  //  FLock.Acquire;
    try
     if Cnt > 0 then
      begin
       FEvent.SetEvent;
       FNet.SendBuffer(b);
      end;
    finally
  //   FLock.Release;
    end;
    if Assigned(FIOEvent) then FIOEvent(iosTx, @b[0], cnt);
   end
  else raise ENetConnectIOException.Create(RS_SendData);
end;

procedure TUDPBinConnectIO.CheckOpen;
begin
 // FLock.Acquire;
  try
   if not FNet.Connected then raise ENetConnectIOException.CreateFmt(RS_UDP_Connclose, [FNet.Host]);
  finally
  // FLock.Release;
  end;
end;

procedure TUDPBinConnectIO.Close;
begin
  inherited Close;
  try
  //  FLock.Acquire;
    try
     FNet.Disconnect;
    finally
  //   FLock.Release;
    end;
  except
   S_Status := S_Status + [iosError];
   raise
  end;
end;

function TUDPBinConnectIO.IsOpen: Boolean;
begin
//  FLock.Acquire;
  try
   Result := FNet.Connected;
   UpdateOpenStatus(Result);
  finally
//   FLock.Release;
  end;
end;

procedure TUDPBinConnectIO.Open;
begin
  //FLock.Acquire;
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
 //  FLock.Release;
  end;
end;

procedure TUDPBinConnectIO.SetConnectInfo(const Value: string);
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

constructor TUDPBinConnectIO.TReadThread.Create(AOwner: TUDPBinConnectIO; const DbgName: string);
begin
  NetConnect := AOwner;
  FDbgName := DbgName;
  inherited Create(False);
end;

procedure TUDPBinConnectIO.TReadThread.Execute;
 var
  cnt: Integer;
  VBuffer: TIdBytes;
//  function UpdateCnt: boolean;
//  begin
//    cnt := 0;
//    NetConnect.FLock.Acquire;
//    try
//     if not NetConnect.FNet.Connected then Exit(False);
//     cnt := NetConnect.FNet.IOHandler.InputBuffer.Size;
//     Result := cnt > 0;
//    finally
//     NetConnect.FLock.Release;
//    end;
//  end;
begin
  CoInitialize(nil);
  try
  NameThreadForDebugging(FDbgName);
  with NetConnect do while not Terminated do
  try
   Fevent.WaitFor();
   Fevent.ResetEvent;
   SetLength(VBuffer, $8000);
   while FTimerRxTimeOut.Enabled and not Terminated and FNet.Connected do
    begin
     //if not UpdateCnt then Continue;
  //   FLock.Acquire;
     try
      cnt := FNet.ReceiveBuffer(VBuffer, 300);
     except
       on e: EIdNotASocket do
        begin
         FNet.Disconnect;
         //TDebug.DoException(E, False);
        end
     else
       raise
//     finally
 //     FLock.Release;
     end;
     if Terminated then Exit;
     if cnt = 0 then Continue;

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
  RegisterClass(TUDPBinConnectIO);
  TRegister.AddType<TUDPBinConnectIO, IConnectIO>.LiveTime(ltSingletonNamed);
finalization
  GContainer.RemoveModel<TUDPBinConnectIO>;
end.

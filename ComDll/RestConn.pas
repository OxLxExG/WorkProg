unit RestConn;

interface

uses
     System.SysUtils, System.Classes, System.SyncObjs, Winapi.ActiveX,
    REST.Types,
    REST.Client,
    AbstractDev, RootImpl, DeviceIntf, debug_except, RootIntf, ExtendIntf, tools, Container;

type
  // Реализация для TCP
  ENetConnectIOException = class(EConnectIOException);

  TRestConnectIO = class(TAbstractNetConnectIO, IRestConnectIO)
  protected
    FHttpClient: TRESTClient;
    FRequest: TRESTRequest;
    FResponse: TRESTResponse;
//    FLock: TCriticalSection;
//    FEvent: TEvent;
//   type
//    TReadThread = class(TThread)
//    protected
//      NetConnect: TRestConnectIO;
//      FDbgName: string;
//      procedure Execute; override;
//      constructor Create(AOwner: TRestConnectIO; const DbgName: string);
//    end;
//   var
//    FReadThread: TReadThread;
    procedure SetConnectInfo(const Value: string); override;
    procedure Open; override;
    procedure Close; override;
//    function IsOpen: Boolean; override;
  public
    constructor Create(); override;
    destructor Destroy; override;
//    procedure CheckOpen; override;
    procedure Send(Data: Pointer; Cnt: Integer; Event: TReceiveDataRef = nil; WaitTime: Integer = -1); override;
  end;

implementation

{ TNetConnectIO }

constructor TRestConnectIO.Create();
begin
  inherited;
//  FEvent := TEvent.Create;
//  FLock := TCriticalSection.Create;
  FConnectInfo := '127.0.0.1:3000';
  FHttpClient := TRESTClient.Create(nil);
  FHttpClient.ContentType := 'multipart/form-data';
  FRequest := TRESTRequest.Create(FHttpClient);
  FResponse := TRESTResponse.Create(FRequest);
  FRequest.Response := FResponse;
  FRequest.Resource := 'connect';
//  FRequest.Params.Clear;
//  FRequest.Body.ClearBody;
  FRequest.Method := rmGET;
  FRequest.Timeout := 2000;
//  FNet.Host := '192.168.43.5';
//  FReadThread :=  TReadThread.Create(Self, Name);
end;

destructor TRestConnectIO.Destroy;
begin
//  FReadThread.Terminate;
//  FEvent.SetEvent;
//  FReadThread.WaitFor;
//  FReadThread.Free;
  FHttpClient.Free;
//  FLock.Free;
//  FEvent.Free;
  inherited;
end;

procedure TRestConnectIO.Send(Data: Pointer; Cnt: Integer; Event: TReceiveDataRef; WaitTime: Integer);
 var
  b: TBytes;
  bs: TBytesStream;
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
    SetLength(b, Cnt);
    CheckOpen;
    if Assigned(FIOEvent) then FIOEvent(iosTx, @b[0], cnt);
//    FLock.Acquire;
    try
      FTimerRxTimeOut.Enabled := True;
      FRequest.Timeout := FTimerRxTimeOut.Interval;
      FRequest.Params.Clear;

      FRequest.Body.ClearBody;
      FRequest.Method := rmPOST;
      FRequest.ResourceSuffix := 'send';
      bs := TBytesStream.Create(b);
      bs.Position := 0;
      FRequest.Params.AddItem('data', bs,
          TRESTRequestParameterKind.pkREQUESTBODY,
          [TRESTRequestParameterOption.poDoNotEncode],
          TRESTContentType.ctAPPLICATION_OCTET_STREAM);
       FRequest.ExecuteAsync(procedure
         var
          cnt: Integer;
        begin
          bs.Free;
          Tdebug.log(' %d  %s  %s',[FResponse.StatusCode, FResponse.StatusText,  FResponse.ContentType]);
          cnt := Length(FResponse.RawBytes);
          if (FICount+cnt) > $8000 then FICount := 0;
          Move(FResponse.RawBytes[0], FInput[FICount], cnt);
          Inc(FICount, cnt);
//          FLock.Release;
          if Assigned(FIOEvent) then FIOEvent(iosRx, @FInput[FICount-cnt], cnt);
          if Assigned(FProtocol) then FProtocol.EventRxChar(Self);
        end);
    except
//     FLock.Release;
     raise
    end;
   end
  else raise ENetConnectIOException.Create(RS_SendData);
end;

{procedure TRestConnectIO.CheckOpen;
begin
  FLock.Acquire;
  try
   if not FNet.Connected then raise ENetConnectIOException.CreateFmt('Соединение закрыто %s', [FNet.Host]);
  finally
   FLock.Release;
  end;
end;}

procedure TRestConnectIO.Close;
begin
//  FLock.Acquire;
  try
    try
      FRequest.Params.Clear;
      FRequest.Body.ClearBody;
      FRequest.Method := rmGET;
      FRequest.ResourceSuffix := 'close';
      TDebug.Log('rest close ' + FRequest.GetFullRequestURL);
      FRequest.Timeout := 1000;
      FRequest.Execute;
      if FResponse.Content = 'OK' then inherited Close
      else raise ENetConnectIOException.Create('Error close port  :'+ FResponse.Content);
    except
     S_Status := S_Status + [iosError];
     raise
    end;
  finally
//   FLock.Release;
  end;
end;

//function TRestConnectIO.IsOpen: Boolean;
//begin
//  FLock.Acquire;
//  try
//   Result := FNet.Connected;
//   UpdateOpenStatus(Result);
//  finally
//   FLock.Release;
//  end;
//end;

procedure TRestConnectIO.Open;
begin
//  FLock.Acquire;
  try
    if IsOpen then raise ENetConnectIOException.CreateFmt(RS_NeedCloseNet, [FHttpClient.BaseURL]);
    try
      FRequest.Params.Clear;
      FRequest.Body.ClearBody;
      FRequest.Method := rmGET;
      FRequest.ResourceSuffix := 'open';
      FRequest.Timeout := 1000;
      TDebug.Log('rest open ' + FRequest.GetFullRequestURL);
      FRequest.Execute;
      if FResponse.Content = 'OK' then inherited Open
      else raise ENetConnectIOException.Create('Error open port :'+ FResponse.Content);
    except
     S_Status := S_Status + [iosError];
     raise
    end;
  finally
//   FLock.Release;
  end;
end;

procedure TRestConnectIO.SetConnectInfo(const Value: string);
begin
  if not SameText(FHttpClient.BaseURL, Value) then
   begin
    if IsOpen then raise EComConnectIOException.CreateFmt(RS_NeedCloseNet, [FHttpClient.BaseURL]);
    FHttpClient.BaseURL := Value;
    inherited SetConnectInfo(Value);
   end;
end;

{ TNetConnectIO.TReadThread }

{constructor TRestConnectIO.TReadThread.Create(AOwner: TRestConnectIO; const DbgName: string);
begin
  NetConnect := AOwner;
  FDbgName := DbgName;
  inherited Create(False);
end;

procedure TRestConnectIO.TReadThread.Execute;
 var
  cnt: Integer;
  VBuffer: TBytes;
  function UpdateCnt: boolean;
  begin
    cnt := 0;
    NetConnect.FLock.Acquire;
    try
     if not NetConnect.FHttpClient.Connected then Exit(False);
     cnt := NetConnect.FHttpClient.IOHandler.InputBuffer.Size;
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
      FHttpClient.IOHandler.ReadBytes(VBuffer, cnt, false);
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
end;    }

initialization
  RegisterClass(TRestConnectIO);
  TRegister.AddType<TRestConnectIO, IConnectIO>.LiveTime(ltSingletonNamed);
finalization
  GContainer.RemoveModel<TRestConnectIO>;
end.

//Data.Bind.ObjectScope            16 ICODE bindcomp230.bpl
//IPPeerAPI                         8 CODE  customiptransport230.bpl
//REST.Json.Interceptors            8 CODE  restcomponents230.bpl


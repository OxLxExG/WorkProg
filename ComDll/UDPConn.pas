unit UDPConn;

interface

uses System.SysUtils, System.Classes, System.SyncObjs, System.Generics.Collections, System.Generics.Defaults,
     AbstractDev,
     IdSocketHandle, IdUDPServer, IdBaseComponent, IdComponent, IdUDPBase, IdUDPClient, IdGlobal,
     RootImpl, DeviceIntf, debug_except, RootIntf, ExtendIntf, tools, Container;
type
  // Реализация для UDP
  EUDPConnectIOException = class(EConnectIOException);

  TUDPConnectIO = class(TAbstractNetConnectIO, IUDPConnectIO)
  private
   type
    TQeTask = record
      data_out: string;
      Event : TReceiveUDPRef;
      WaitTime: Integer;
      constructor Create(const Adata: string; AEvent: TReceiveUDPRef; AWaitTime: Integer);
    end;
    procedure ReadEvent(AThread: TIdUDPListenerThread; const AData: TIdBytes; ABinding: TIdSocketHandle);
    procedure Exec(data: TQeTask);
    procedure DoEvent(const Data: string; status: integer);
  protected
    FQueue: TQueue<TQeTask>;
    FClient: TIdUDPClient;
    FServer: TIdUDPServer;
    procedure OnTimerRxTimeOut(Sender: TObject); override;
    procedure SetConnectInfo(const Value: string); override;
    procedure Open; override;
    procedure Close; override;
    function IsOpen: Boolean; override;
    procedure Send(const cmd: string; ev: TReceiveUDPRef = nil; TimeOut: Integer = -1); reintroduce;
  public
    constructor Create(); override;
    destructor Destroy; override;
    procedure CheckOpen; override;
  end;


implementation

{ TUDPConnectIO.TQeTask }

constructor TUDPConnectIO.TQeTask.Create(const Adata: string; AEvent: TReceiveUDPRef; AWaitTime: Integer);
begin
  data_out := Adata;
  Event := Aevent;
  WaitTime := AWaitTime;
end;

{ TUDPConnectIO }

constructor TUDPConnectIO.Create;
begin
  inherited;
  FQueue := TQueue<TQeTask>.Create;
  FConnectInfo := '192.168.10.253:10005';
  FClient := TIdUDPClient.Create(nil);
  FServer := TIdUDPServer.Create(nil);
  FServer.OnUDPRead := ReadEvent;
  FClient.Host := '192.168.10.253';
  FServer.DefaultPort := 10005;
  FClient.Port := 10005;
  FComWait := 100;
end;

destructor TUDPConnectIO.Destroy;
begin
  FServer.Active := False;
  FClient.Free;
  FServer.Free;
  FQueue.Free;
  inherited;
end;

procedure TUDPConnectIO.DoEvent(const Data: string; status: integer);
 var
  t: TQeTask;
begin
  FTimerRxTimeOut.Enabled := False;
  if FQueue.Count = 0 then Exit;
  try
   t := FQueue.Dequeue;
   if Assigned(t.Event) then t.Event(Data, status);
   if Assigned(FIOEventString) then
    if (status >= 0) then FIOEventString(iosRx, Data)
    else FIOEventString(iosTimeOut, Data);
  finally
   if FQueue.Count > 0 then Exec(FQueue.Peek);
  end;
end;

procedure TUDPConnectIO.Exec(data: TQeTask);
begin
  if data.WaitTime > 0 then FTimerRxTimeOut.Interval := data.WaitTime
  else FTimerRxTimeOut.Interval := FComWait;
  FClient.Send(data.data_out + #$A);
  if Assigned(FIOEventString) then FIOEventString(iosTx, data.data_out);
  FTimerRxTimeOut.Enabled := True;
end;

procedure TUDPConnectIO.CheckOpen;
begin
  if not FServer.Active then raise EUDPConnectIOException.CreateFmt('Соединение закрыто %s', [FClient.Host]);
end;

procedure TUDPConnectIO.Close;
begin
  inherited Close;
  try
   FServer.Active := False;
  except
   S_Status := S_Status + [iosError];
   raise
  end;
end;

procedure TUDPConnectIO.OnTimerRxTimeOut(Sender: TObject);
begin
  FTimerRxTimeOut.Enabled := False;
  DoEvent('',  -1);
end;

procedure TUDPConnectIO.Open;
begin
  if FServer.Active then raise EUDPConnectIOException.CreateFmt(RS_NeedCloseNet, [FClient.Host]);
  try
   FServer.Active := True;
   inherited Open;
  except
   S_Status := S_Status + [iosError];
   raise
  end;
end;

procedure TUDPConnectIO.ReadEvent(AThread: TIdUDPListenerThread; const AData: TIdBytes; ABinding: TIdSocketHandle);
 var
  s: string;
begin
  s := BytesToString(AData);
  DoEvent(s, Length(s));
end;

function TUDPConnectIO.IsOpen: Boolean;
begin
   Result := FServer.Active;
   UpdateOpenStatus(Result);
end;

procedure TUDPConnectIO.Send(const cmd: string; ev: TReceiveUDPRef; TimeOut: Integer);
begin
  FQueue.Enqueue(TQeTask.Create(cmd, Ev, TimeOut));
  if FQueue.Count = 1 then Exec(FQueue.Peek);
end;

procedure TUDPConnectIO.SetConnectInfo(const Value: string);
begin
  if not SameText(FConnectInfo, Value) then
   begin
    if IsOpen then raise EComConnectIOException.CreateFmt(RS_NeedCloseNet, [FClient.Host]);
    FClient.Host := ExtractHost(Value);
    FClient.Port := ExtractPort(Value);
    FServer.DefaultPort := FClient.Port;
    inherited SetConnectInfo(Value);
   end;
end;

initialization
  RegisterClass(TUDPConnectIO);
  TRegister.AddType<TUDPConnectIO, IConnectIO>.LiveTime(ltSingletonNamed);
finalization
  GContainer.RemoveModel<TUDPConnectIO>;
end.

unit DevUakiCom;

interface

uses System.SysUtils, System.Classes, Vcl.Graphics, tools, DevUaki,
     System.Generics.Collections, System.Generics.Defaults,
     UakiIntf, DeviceIntf, AbstractDev, debug_except, ExtendIntf, Container, PluginAPI, RootImpl;
type

 TDevUakiCom = class(TDevUaki)
 private
    procedure OnEvent(Data: Pointer; DataSize: integer);
    type
    TQeTask = record
      data_out: string;
      Event : TReceiveUDPRef;
      WaitTime: Integer;
      constructor Create(const Adata: string; AEvent: TReceiveUDPRef; AWaitTime: Integer);
    end;
 protected
    FQueue: TQueue<TQeTask>;
    procedure DoSetConnect(AIConnectIO: IConnectIO); override;
    procedure DoRegister; override;
    procedure Exec(data: TQeTask);
    procedure DoEvent(const Data: string; status: integer);
    procedure Send(const cmd: string; ev: TReceiveUDPRef = nil; TimeOut: Integer = -1); override;
  public
    constructor Create(); override;
    destructor Destroy; override;
    procedure CheckConnect(); override;
    function ConnectOpen(): boolean; override;
    procedure ConnectClose(); override;
 end;


implementation

uses IdGlobal;
type
  TProtocolUakiCom = class(TAbstractProtocol)
  protected
    procedure EventRxTimeOut(Sender: TAbstractConnectIO); override;
    procedure EventRxChar(Sender: TAbstractConnectIO); override;
    procedure TxChar(Sender: TAbstractConnectIO; Data: Pointer; var Cnt: Integer; maxsend: Integer = $200); override;
  end;

  { TProtocolUakiCom }

procedure TProtocolUakiCom.EventRxChar(Sender: TAbstractConnectIO);
 var
  c: TComConnectIO;
//  a: AnsiString;
begin
  c := Sender as TComConnectIO;
  if c.FInput[c.FICount-1] = $A then
   begin
     c.FTimerRxTimeOut.Enabled := False;
//    SetString(a, PAnsiChar(@c.FInput[0]), c.FICount);
    Sender.DoEvent(@c.FInput[0],c.FICount);
   end;
end;

procedure TProtocolUakiCom.EventRxTimeOut(Sender: TAbstractConnectIO);
begin
  Sender.DoEvent(nil,-1);
end;

procedure TProtocolUakiCom.TxChar(Sender: TAbstractConnectIO; Data: Pointer; var Cnt: Integer; maxsend: Integer);
 var
  c: TComConnectIO;
//  a: AnsiString;
begin
  c := Sender as TComConnectIO;
  c.FICount := 0;
end;


{ TDevUakiCom }



procedure TDevUakiCom.CheckConnect;
begin
  inherited;
  if not Assigned(ConnectIO.FProtocol) or not (TAbstractProtocol(ConnectIO.FProtocol) is TProtocolUakiCom) then
   begin
    ConnectIO.FProtocol := TProtocolUakiCom.Create;
   end;
end;

procedure TDevUakiCom.ConnectClose;
begin
  inherited;
    var s := IConnect.ConnectInfo.Split([';'])[0];
    IConnect.ConnectInfo := s+ ';115200;0';
//  IConnect.ConnectInfo := IConnect.ConnectInfo+ ';;';
end;

function TDevUakiCom.ConnectOpen: boolean;
begin
  Result := IConnect.IsOpen;
  if not Result then
   begin
    TComConnectIO(ConnectIO).AsString := True;
    var s := IConnect.ConnectInfo.Split([';'])[0];
    IConnect.ConnectInfo := s+ ';115200;0';
    IConnect.Open;
   end;
end;

constructor TDevUakiCom.Create;
begin
  inherited;
  FViz := GetAxisVizClass.Create(self as IInterface, ADR_AXIS_VIZ, 1/8,0, 8,0);
  FZen := GetAxisVizClass.Create(self as IInterface, ADR_AXIS_ZU, 1,180,  1,-180);
  FCyclePeriod := 500;
  FAddressArray := TAddressRec(ADR_UAKI_COM.ToString());
  FQueue := TQueue<TQeTask>.Create;
  FtenSupport := False;
end;

destructor TDevUakiCom.Destroy;
begin
  FQueue.Free;
  inherited;
end;

procedure TDevUakiCom.DoEvent(const Data: string; status: integer);
 var
  t: TQeTask;
begin
  if FQueue.Count = 0 then Exit;
  try
   t := FQueue.Dequeue;
   if Assigned(t.Event) then t.Event(Data, status);
  finally
   if FQueue.Count > 0 then Exec(FQueue.Peek);
  end;
end;

procedure TDevUakiCom.DoRegister;
begin
  TRegister.AddType<TDevUakiCom>.AddInstance(Name, Self as IInterface);
end;

procedure TDevUakiCom.DoSetConnect(AIConnectIO: IConnectIO);
begin
  if Assigned(AIConnectIO) and not Supports(AIConnectIO, IComPortConnectIO) then
    raise EConnectIOException.CreateFmt('%s не COM соединение. ¬озможно только COM соединение!',[AIConnectIO.ConnectInfo]);
//    (AIConnectIO as TComConnectIO).AsString := True;
end;

procedure TDevUakiCom.Exec(data: TQeTask);
begin
  with ConnectIO do
   begin
    var b := ToBytes(data.data_out);
    (IConnect as TComConnectIO).Send(@b[0], Length(b), OnEvent , data.WaitTime);
   end;
end;

procedure TDevUakiCom.OnEvent(Data: Pointer; DataSize: integer);
 var
  a: AnsiString;
begin
 if Assigned(Data) then
  begin
   SetString(a, PAnsiChar(Data), DataSize);
   DoEvent(string(a), Length(a));
  end
  else DoEvent('', -1);
end;

procedure TDevUakiCom.Send(const cmd: string; ev: TReceiveUDPRef; TimeOut: Integer);
begin
  FQueue.Enqueue(TQeTask.Create(cmd+#$A, Ev, TimeOut));
  if FQueue.Count = 1 then Exec(FQueue.Peek);
end;

{ TDevUakiCom.TQeTask }

constructor TDevUakiCom.TQeTask.Create(const Adata: string; AEvent: TReceiveUDPRef; AWaitTime: Integer);
begin
  data_out := Adata;
  Event := Aevent;
  WaitTime := AWaitTime;
end;


initialization
  RegisterClass(TDevUakiCom);
  TRegister.AddType<TDevUakiCom, IDevice>.LiveTime(ltSingletonNamed);
finalization
  GContainer.RemoveModel<TDevUakiCom>;
end.

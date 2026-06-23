unit DevUaki2;

interface

uses System.SysUtils, System.Classes, Vcl.Graphics, tools, DevUaki, Vcl.Forms,
     UakiIntf, DeviceIntf, AbstractDev, debug_except, ExtendIntf, Container, PluginAPI, RootImpl;

const
  UAKSI_COMMAND_IDLE = 00;
// выход на точку (поворот в нужное положение) в текущей плоскости
  UAKSI_COMMAND_GOTO_POINT = $55;
// автоматический поиск маркеров угловых датчиков
  UAKSI_COMMAND_AUTO_FIND_MARKER = $56;

type

  TAxis2 = class(TAxis)
  private
    function AxisName: AnsiChar;
  protected
    procedure UpdateAngleData; override;
    procedure FindMarker; override;
    procedure TermimateMoving; override;
    procedure GotoAngle(Angle: TAngle; MaxSpeed: Integer = 255); override;
    function GetTOlerance: Double; override;
    procedure SetTolerance(const Value: Double); override;
  end;

  TAxisAzi2 = class(TAxis2, IAxisAZI);
  TAxisZen2 = class(TAxis2, IAxisZEN);
  TAxisViz2 = class(TAxis2, IAxisVIZ);

  TDevUakiRes = reference to procedure (n: Integer; const LastAns: AnsiString);
  TDevUaki2 = class(TDevUaki)
  private
    FPortLocked: Boolean;
    procedure DoEvent(n: Integer; const LastAns: AnsiString; Event: TDevUakiRes);
//    procedure StartComm;
//    procedure StopComm;
  protected
    procedure DoCycle; override;
    procedure DoSetConnect(AIConnectIO: IConnectIO); override;
    procedure DoRegister; override;
    procedure TermimateMoving; override;
    function GetAxisAziClass: TAxisClass; override;
    function GetAxisZenClass: TAxisClass; override;
    function GetAxisVizClass: TAxisClass; override;
  public
    procedure Send(const Cmd: AnsiString; Event: TDevUakiRes = nil; WaitTime: Integer = -1);
    procedure CheckConnect(); override;
    function ConnectOpen(): boolean; override;
    procedure ConnectClose(); override;
  end;

implementation

{ TDevUaki2 }

procedure TDevUaki2.CheckConnect;
begin
  inherited;
  if not Assigned(ConnectIO.FProtocol) or not (TAbstractProtocol(ConnectIO.FProtocol) is TProtocolPsk) then
   begin
    ConnectIO.FProtocol := TProtocolPsk.Create;
   end;
end;

procedure TDevUaki2.ConnectClose;
begin
  inherited;
  IConnect.ConnectInfo := IConnect.ConnectInfo+ ';;';
end;

function TDevUaki2.ConnectOpen: boolean;
begin
  Result := IConnect.IsOpen;
  if not Result then
   begin
    TComConnectIO(ConnectIO).AsString := True;
    IConnect.ConnectInfo := IConnect.ConnectInfo+ ';115200;0';
    IConnect.Open;
   end;
end;

                    // вывод информации о положении датчиков
            //        A, Z, O
/// post name=lir sens0=0 val0=0.999 sens1=1 val1=1.999 sens2=2 val2=2.999
                    // вывод информации о скорости вращения
///               sens3=3 val3=3.333 sens4=4 val4=4.333 sens5=5 val5=5.333
                    // дополнительная информация о выполняемых командах
///               sens6=6 val6=6.777 sens7=7 val7=7.777 sens8=8 val8=8.777
                    // состояние подчиненных устройств
///               sens9=9 sens10=10 sens11=11 sens12=12 sens13=13 sens14=14 sens15=15


procedure TDevUaki2.DoCycle;
 const
   TST_STR = 'post name=lir sens0=3 val0=0.026 sens1=241 val1=2.118 sens2=-12 val2=-0.013 sens3=0 val3=0 sens4=0 val4=0 sens5=0 val5=0 sens6=0 val6=0 sens7=0 val7=0 sens8=0 val8=0 sens9=1 sens10=1 sens11=1 sens12=1 sens13=1 sens14=1 sens15=117';
//   'post name=lir sens0=0 val0=0.999 sens1=1 val1=1.999 sens2=2 val2=2.999'+
//   ' sens3=3 val3=3.333 sens4=4 val4=4.333 sens5=5 val5=5.333'+
//   ' sens6=85 val6=6.777 sens7=0 val7=7.777 sens8=85 val8=8.777'+
//   ' sens9=9 sens10=10 sens11=11 sens12=12 sens13=13 sens14=14 sens15=15';
   POS_A = 6;
   POS_Z = 10;
   POS_V = 14;
   VEL_A = 18;
   VEL_Z = 22;
   VEL_V = 26;
   CMD_A = 28;
   CMD_Z = 32;
   CMD_V = 36;
   TAG_A = 30;
   TAG_Z = 34;
   TAG_V = 38;
begin
  if FPortLocked then Exit;
  Send('d', procedure (n: Integer; const LastAns: AnsiString)
   function SetCmt(cmd: Byte): Char;
   begin
     case cmd of
      0: Result := 's';
      $55: Result := 'G';
      $56: Result := 'f';
      else Result := 'x';
     end;
   end;
   var
    a: TArray<string>;
  begin

     n := TST_STR.Length;

    if n >= $80 then
     begin
      a := string({TST_STR}LastAns).Split([' ', '=', #$D], TStringSplitOptions.ExcludeEmpty);
      Azi.FCurrentAngle := a[POS_A].ToDouble();
      Zen.FCurrentAngle := a[POS_Z].ToDouble();
      Viz.FCurrentAngle := a[POS_V].ToDouble();
      Azi.FMotor := SetCmt(a[CMD_A].ToInteger());
      Zen.FMotor := SetCmt(a[CMD_Z].ToInteger());
      Viz.FMotor := SetCmt(a[CMD_V].ToInteger());
      Azi.FReper := 'M';
      Zen.FReper := 'M';
      Viz.FReper := 'M';
      Azi.FEndTumbler := 'o';
      Zen.FEndTumbler := 'o';
      Viz.FEndTumbler := 'o';
      S_AxisUpdate := ADR_AXIS_AZI;
      S_AxisUpdate := ADR_AXIS_ZU;
      S_AxisUpdate := ADR_AXIS_VIZ;
     end;
  end);
end;

procedure TDevUaki2.DoRegister;
begin
  TRegister.AddType<TDevUaki2>.AddInstance(Name, Self as IInterface);
end;

procedure TDevUaki2.DoSetConnect(AIConnectIO: IConnectIO);
begin
  if Assigned(AIConnectIO) and not Supports(AIConnectIO, IComPortConnectIO) then
    raise EConnectIOException.CreateFmt('%s не COM соединение. Возможно только COM соединение!',[AIConnectIO.ConnectInfo]);
end;

function TDevUaki2.GetAxisAziClass: TAxisClass;
begin
  Result := TAxisAzi2;
end;

function TDevUaki2.GetAxisVizClass: TAxisClass;
begin
  Result := TAxisViz2;
end;

function TDevUaki2.GetAxisZenClass: TAxisClass;
begin
  Result := TAxisZen2;
end;

procedure TDevUaki2.DoEvent(n: Integer; const LastAns: AnsiString; Event: TDevUakiRes);
begin
  try
    if Assigned(Event) then Event(n, LastAns);
  finally
    FPortLocked := False;
  end;
end;

procedure TDevUaki2.Send(const Cmd: AnsiString; Event: TDevUakiRes; WaitTime: Integer);
 var
  e: TReceiveDataRef;
begin
  e := procedure(p: Pointer; n: integer)
   var
    a: AnsiString;
    pa: PAnsiChar;
  begin
    a := '';
    pa := p;
    if n > 0 then
     if pa[n-1] = #$D then
      begin
       SetString(a, PAnsiChar(p), n);
       DoEvent(n, a, Event);
      end
     else
      begin
       ConnectIO.FTimerRxTimeOut.Enabled := True;
       ConnectIO.FEventReceiveData := e;
      end
    else DoEvent(n, a, Event);
  end;
  FPortLocked := True;
  ConnectIO.FICount := 0;
 // FRunCmd := Cmd;
  ConnectIO.Send(@Cmd[1], Length(Cmd), e, WaitTime);
end;

procedure TDevUaki2.TermimateMoving;
begin
  Send('S');
end;

{procedure TDevUaki2.StartComm;
begin
  CheckConnect;
  CheckLocked;
  if not IConnect.IsOpen() then IConnect.ConnectInfo := IConnect.ConnectInfo+ ';9600;1';
  ConnectOpen();
  ConnectLock;
  TComConnectIO(ConnectIO).AsString := True;
end;

procedure TDevUaki2.StopComm;
begin
  ConnectUnLock;
  ConnectClose();
  IConnect.ConnectInfo := IConnect.ConnectInfo+ ';;';
end;}

{$REGION 'Axis 2'}

{ TAxis2 }

function TAxis2.AxisName: AnsiChar;
begin
  case GetAdr of
    ADR_AXIS_AZI: Result :=  'x';
    ADR_AXIS_ZU:  Result :=  'y';
  else Result :=  'z';
  end;
end;

procedure TAxis2.FindMarker;
begin
  TDevUaki2(Controller).Cycle.SetCycle(False);
  while TDevUaki2(Controller).Cycle.GetCycle do Application.ProcessMessages;
  FReper := 'f';
  TDevUaki2(Controller).ConnectOpen();
  TDevUaki2(Controller).Send(AnsiString('s'+AxisName+'f'), procedure (n: Integer; const LastAns: AnsiString)
  begin
    TDevUaki2(Controller).ConnectClose();
    TDevUaki2(Controller).Cycle.SetCycle(True);
  end);
end;

function TAxis2.GetTOlerance: Double;
begin
  raise EDevUakiException.Create('Не поддерживается');
end;

procedure TAxis2.GotoAngle(Angle: TAngle; MaxSpeed: Integer);
begin
  TDevUaki2(Controller).Cycle.SetCycle(False);
  while TDevUaki2(Controller).Cycle.GetCycle do Application.ProcessMessages;
  FMotor := 'G';
  TDevUaki2(Controller).ConnectOpen();
  TDevUaki2(Controller).Send(AnsiString('s'+AxisName+'G'+ Angle.ToStringUAKI+ ' '), procedure (n: Integer; const LastAns: AnsiString)
  begin
    TDevUaki2(Controller).ConnectClose();
    TDevUaki2(Controller).Cycle.SetCycle(True);
  end);
end;

procedure TAxis2.SetTolerance(const Value: Double);
begin
  raise EDevUakiException.Create('Не поддерживается');
end;

procedure TAxis2.TermimateMoving;
begin
  raise EDevUakiException.Create('Не поддерживается');
end;

procedure TAxis2.UpdateAngleData;
begin
  raise EDevUakiException.Create('Не поддерживается');
end;
{$ENDREGION}

initialization
  RegisterClass(TDevUaki2);
  TRegister.AddType<TDevUaki2, IDevice>.LiveTime(ltSingletonNamed);
finalization
  GContainer.RemoveModel<TDevUaki2>;
end.

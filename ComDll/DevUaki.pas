unit DevUaki;

interface

uses System.SysUtils, System.Classes, Vcl.Graphics, tools,
     UakiIntf, DeviceIntf, AbstractDev, debug_except, ExtendIntf, Container, PluginAPI, RootImpl;
type

  TAxis = class(TAggObject, IAxis)
  private
    FNeedAngle: TAngle;
    FDeltaAngle: TAngle;
    FAdr: Integer;
    FInfo: string;
    procedure OnCurrentData(const Data: string; status: integer);
    function AngleFromStol(stol: Double): TAngle;
    function AngleToStol(angle: TAngle): Double;
  protected
//ЂE7; E6; E5; WDTR; MAX; MIN; WDG; PCCї , где
  const
   ERR_COD: array[0..4] of string = ('ЂPCCї Ч потер€ св€зи с компьютером'#$A,
                                   'ЂWDGї Ч заклинивание'#$A,
                                   'ЂMINї Ч выход за минимальную позицию'#$A,
                                   'ЂMAXї Ч выход за максимальную позицию'#$A, 'ЂWDTRї Ч срабатывание сторожевого таймера');
    procedure UpdateAngleData; virtual;
    procedure FindMarker; virtual;
    procedure ClearDeltaAngle;
    procedure TermimateMoving; virtual;
    procedure GotoAngle(Angle: TAngle; MaxSpeed: Integer = 255); virtual;

    function MotorToString: string;
    function MotorToColor: TColor;
    function ReperToString: string;
    function ReperToColor: TColor;
    function EndTumblerToString: string;
    function EndTumblerToColor: TColor;
    function ErrorToText: string;
  // private
    function GetEndTumbler: Char;
    function GetReper: Char;
    function GetMotor: Char;
    function GetError: Byte;

    function GetAdr: Integer;

    function GetCurrentAngle: TAngle;
    procedure SetCurrentAngle(Value: TAngle);
    function GetNeedAngle: TAngle;
    function GetDeltaAngle: TAngle;
    procedure SetDeltaAngle(Value: TAngle);

    procedure SetNeedAngle(Value: TAngle);

    function GetTOlerance: Double; virtual;
    procedure SetTolerance(const Value: Double); virtual;
   public
    FCurrentAngle: TAngle;
    FMotor: Char;
    FReper: Char;
    FKmultoStol:     Double;
    FAngAddtoStol:   Double;
    FKmulFromStol:   Double;
    FAngAddFromStol: Double;
    FEndTumbler: Char;
    FError: Byte;
    constructor Create(const Controller: IInterface; addr: Integer;
    KmultoStol:     Double;
    AngAddtoStol:   Double;
    KmulFromStol:   Double;
    AngAddFromStol: Double);
    property NeedAngle: TAngle read FNeedAngle write SetNeedAngle;
  end;
  TAxisClass = class of TAxis;

  TAxisAzi = class(TAxis, IAxisAZI);
  TAxisZen = class(TAxis, IAxisZEN);
  TAxisViz = class(TAxis, IAxisVIZ);

  EDevUakiException = class(EDeviceException);

  TDevUaki = class(TDevice, IDevice, IUaki, ICycle, IAxisAZI, IAxisZEN, IAxisVIZ)
  private
    FS_AxisUpdate: Integer;
    FTemp: TArray<Double>;
    FTen: array[0..2] of Integer;
    FS_TenUpdate: Integer;
    FIsTenPower: Boolean;
    FMagnitAmp: Double;
    FMaxTenPower: Integer;
    procedure SetS_AxisUpdate(const Value: Integer);
   type
    TCycleUAK = class(TCycle)
    protected
      procedure DoCycle; override;
    end;
   var
    FCycle: TCycleUAK;
  protected
    FAzi: TAxis;
    FZen: TAxis;
    FViz: TAxis;
    FtenSupport: Boolean;
    procedure DoCycle; virtual;

    procedure UpdateTenData;
    procedure OnCurrentData(const Data: string; status: integer);
    // IUaki
    function GetAzi: IAxisAZI;
    function GetZen: IAxisZEN;
    function GetViz: IAxisVIZ;
    function  GetTenPower(Index: Integer): Integer;
    procedure SetTenPower(Index, Value: Integer);
    function GetTemperature: TArray<Double>;
    procedure TenStop;
    procedure TenStart;

    function GetIsTenPower: Boolean;
    procedure SetIsTenPower(const Value: Boolean);

    function GetMaxTenPower: Integer;
    procedure SetMaxTenPower(const Value: Integer);

    function GetMagnitAmp: Double;
    procedure SetMagnitAmp(const Value: Double);

    procedure TermimateMoving; virtual;

    function GetAxisAziClass: TAxisClass; virtual;
    function GetAxisZenClass: TAxisClass; virtual;
    function GetAxisVizClass: TAxisClass; virtual;

    procedure SetConnect(AIConnectIO: IConnectIO); override;

    procedure DoSetConnect(AIConnectIO: IConnectIO); virtual;
    procedure DoRegister; virtual;
    procedure Send(const cmd: string; ev: TReceiveUDPRef = nil; TimeOut: Integer = -1); virtual;

  public
    constructor Create(); override;
    constructor CreateWithAddr(const AddressArray: TAddressArray; const DeviceName, ModulesNames: string); override;
    destructor Destroy; override;
    property Cycle: TCycleUAK read FCycle implements  ICycle;
    property Azi: TAxis read FAzi implements  IAxisAZI;
    property Zen: TAxis read FZen implements  IAxisZEN;
    property Viz: TAxis read FViz implements  IAxisVIZ;
    property IzTenPower: Boolean  read GetIsTenPower write SetIsTenPower;
    property S_AxisUpdate: Integer read FS_AxisUpdate write SetS_AxisUpdate;
    property S_TenUpdate: Integer read FS_TenUpdate write FS_TenUpdate;
    property MagnitAmp: Double  read GetMagnitAmp write SetMagnitAmp;
    property MaxTenPower: Integer read GetMaxTenPower write SetMaxTenPower;

  published
    property CyclePeriod;
  end;

implementation

{ TDevUaki.TCycleUAK }

procedure TDevUaki.TCycleUAK.DoCycle;
begin
  TDevUaki(Controller).DoCycle;
end;

{ TDevUaki }

constructor TDevUaki.Create;
begin
  inherited;
  FAzi := GetAxisAziClass.Create(self as IInterface, ADR_AXIS_AZI,1,0,1,0);
  FZen := GetAxisZenClass.Create(self as IInterface, ADR_AXIS_ZU,1,0,1,0);
  FViz := GetAxisVizClass.Create(self as IInterface, ADR_AXIS_VIZ,1,0,1,0);
  FCycle := TCycleUAK.Create(Self);
  FAddressArray := TAddressRec(ADR_UAKI.ToString());
  FDName := 'UAKI';
  FStatus := dsReady;
  FCyclePeriod := 500;
  FS_TenUpdate := Length(FTen);
  FMagnitAmp := 1000;
  FMaxTenPower := 128;
  FtenSupport := True;
end;

constructor TDevUaki.CreateWithAddr(const AddressArray: TAddressArray; const DeviceName, ModulesNames: string);
begin
  inherited;
  DoRegister;
end;

destructor TDevUaki.Destroy;
begin
  TDebug.Log('----------------TDevUaki.Destroy----------------');
  FCycle.SetCycle(False);
  while FCycle.GetCycle do TThread.Yield;
  FCycle.Free;
  FAzi.Free;
  FZen.Free;
  FViz.Free;
  inherited;
end;

procedure TDevUaki.DoRegister;
begin
  TRegister.AddType<TDevUaki>.AddInstance(Name, Self as IInterface);
end;

procedure TDevUaki.DoCycle;
begin
  UpdateTenData;
  Azi.UpdateAngleData;
  Zen.UpdateAngleData;
  Viz.UpdateAngleData;
end;

function TDevUaki.GetAxisAziClass: TAxisClass;
begin
  Result := TAxisAzi;
end;

function TDevUaki.GetAxisVizClass: TAxisClass;
begin
  Result := TAxisViz;
end;

function TDevUaki.GetAxisZenClass: TAxisClass;
begin
  Result := TAxisZen;
end;

function TDevUaki.GetAzi: IAxisAZI;
begin
  Fazi.QueryInterface(IAxisAZI, Result)
end;

function TDevUaki.GetIsTenPower: Boolean;
begin
  Result := FIsTenPower
end;

function TDevUaki.GetMagnitAmp: Double;
begin
  Result := FMagnitAmp;
end;

function TDevUaki.GetMaxTenPower: Integer;
begin
  Result := FMaxTenPower;
end;

function TDevUaki.GetTemperature: TArray<Double>;
begin
  Result := FTemp;
end;

function TDevUaki.GetTenPower(Index: Integer): Integer;
begin
  Result := FTen[Index];
end;

function TDevUaki.GetViz: IAxisVIZ;
begin
  FViz.QueryInterface(IAxisVIZ, Result)
end;

function TDevUaki.GetZen: IAxisZEN;
begin
  FZen.QueryInterface(IAxisZEN, Result)
end;

procedure TDevUaki.DoSetConnect(AIConnectIO: IConnectIO);
begin
  if Assigned(AIConnectIO) and not Supports(AIConnectIO, IUDPConnectIO) then raise EDevUakiException.Create('¬озможно только UDP соединение!');
end;

procedure TDevUaki.Send(const cmd: string; ev: TReceiveUDPRef; TimeOut: Integer);
begin
  (IConnect as IUDPConnectIO).Send(cmd,ev,TimeOut);
end;

procedure TDevUaki.SetConnect(AIConnectIO: IConnectIO);
begin
  DoSetConnect(AIConnectIO);
  inherited;
end;

procedure TDevUaki.SetIsTenPower(const Value: Boolean);
begin
  if FIsTenPower <> Value then
     if Value then TenStart else TenStop;
end;

procedure TDevUaki.SetMagnitAmp(const Value: Double);
begin
  FMagnitAmp := Value;
end;

procedure TDevUaki.SetMaxTenPower(const Value: Integer);
begin
  FMaxTenPower := Value;
  if FMaxTenPower > 128  then FMaxTenPower := 128
end;

procedure TDevUaki.SetS_AxisUpdate(const Value: Integer);
begin
  FS_AxisUpdate := Value;
  Notify('S_AxisUpdate');
end;

procedure TDevUaki.SetTenPower(Index, Value: Integer);
begin
  FTen[Index] := Value;
  TenStart;
end;

procedure TDevUaki.TenStart;
  function p2d(p: integer): Integer;
  begin
    if p>255 then p := 255;
    if p<0 then p := 0;
    Result := p;
//    else if p>100 then p := 100;
//    Result := Round(p*255/100);
  end;
begin
  if FtenSupport then
   begin
    //(IConnect as IUDPConnectIO).
    Send(Format('14p%d,%d,%d',[p2d(FTen[0]),p2d(FTen[1]),p2d(FTen[2])]));
   end;
   FIsTenPower := True;
end;

procedure TDevUaki.TenStop;
begin
  if FtenSupport then
   begin
    //(IConnect as IUDPConnectIO).
    Send('14p0,0,0');
   end;
  FIsTenPower := False;
end;

procedure TDevUaki.TermimateMoving;
begin
  Azi.TermimateMoving;
  Zen.TermimateMoving;
  Viz.TermimateMoving;
end;

procedure TDevUaki.UpdateTenData;
begin
  //(IConnect as IUDPConnectIO).
  if FtenSupport then Send('14a', OnCurrentData);
end;
procedure TDevUaki.OnCurrentData(const Data: string; status: integer);
 var
  a: TArray<string>;
  i: Integer;
begin
  if status >= 24 then
   begin
    a := Data.Trim.Replace('*', '').Split(['{', '[',' ', ',',']', '}'], TStringSplitOptions.ExcludeEmpty);
    if Length(a) >= 4 then for I := 0 to 2 do Ften[i] := a[i+1].Trim.ToInteger; //Ften[i] := Round(a[i+1].Trim.ToInteger*100/255);
    if Length(a)-4 > 0 then
     begin
      SetLength(FTemp, Length(a)-4);
      for I := 0 to Length(a)-4-1 do FTemp[i] := StrToIntDef(a[i+4].Trim, 0) / 100;
     end
    else SetLength(FTemp, 0);
    Notify('S_TenUpdate');
   end;
end;

{ TAxis }

procedure TAxis.ClearDeltaAngle;
begin
  FDeltaAngle.Angle := 0;
end;

constructor TAxis.Create(const Controller: IInterface; addr: Integer;
    KmultoStol:     Double;
    AngAddtoStol:   Double;
    KmulFromStol:   Double;
    AngAddFromStol: Double);

begin
  inherited Create(Controller);
  FKmultoStol:=      KmultoStol;
  FAngAddtoStol:=    AngAddtoStol;
  FKmulFromStol:=    KmulFromStol;
  FAngAddFromStol:=  AngAddFromStol;

  FMotor := 'x';
  FReper := 'x';
  FEndTumbler := 'x';
  Fadr := Addr;
end;

function TAxis.EndTumblerToColor: TColor;
begin
  Result := clYellow;
  case FEndTumbler of
   'o': Result := clBtnFace;
   'L', 'R': Result := clRed;
  end;
end;

function TAxis.EndTumblerToString: string;
begin
  Result := 'неопознано: (' + FEndTumbler +')';
  case FEndTumbler of
   'o': Result := 'ни один концевой выключатель не сработал';
   'L': Result := 'срабатывание левого концевого выключател€';
   'R': Result := 'срабатывание правого концевого выключател€';
  end;
end;

function TAxis.ReperToColor: TColor;
begin
  Result := clYellow;
  case FReper of
   'p': Result := clRed;
   'M': Result := clBtnFace;
   'f': Result := clRed;
   'n': Result := clRed;
   'b': Result := clRed;
   'e': Result := clRed;
   'w': Result := clRed;
   'E': Result := clRed;
  end;
end;

function TAxis.ReperToString: string;
begin
  case FReper of
   'p': Result := 'сброс по включению питани€(начальное состо€ние)';
   'M': Result := 'репер найден(рабочее состо€ние)';
   'f': Result := 'поиск репера';
   'n': Result := 'репер не найден';
   'b': Result := 'сброс по снижению питани€';
   'e': Result := 'аппаратный сброс';
   'w': Result := 'сброс по сторожевому таймеру';
   'E': Result := 'ошибка';
  else  Result := 'неопознано: (' + FReper +')';
  end;
end;

procedure TAxis.SetCurrentAngle(Value: TAngle);
begin
  FCurrentAngle := Value - FDeltaAngle;
end;

procedure TAxis.SetDeltaAngle(Value: TAngle);
 var
  d: TAngle;
begin
  d := Value - FCurrentAngle;
  if FDeltaAngle.Angle <> d.Angle then
   begin
    FDeltaAngle := d;
    (Controller as TDevUaki).PubChange;
   end;
end;

procedure TAxis.SetNeedAngle(Value: TAngle);
begin
  if FNeedAngle.Angle <> Value.Angle then
   begin
    FNeedAngle := Value;
    (Controller as TDevUaki).PubChange;
   end;
end;

function TAxis.MotorToColor: TColor;
begin
  case FMotor of
   's': Result := clBtnFace;
   'G': Result := clRed;
  else  Result := clYellow;
  end;
end;

function TAxis.MotorToString: string;
begin
  case FMotor of
   's': Result := 'остановлен';
   'G': Result := 'двигаетс€';
  else  Result := 'неопознано: (' + FMotor +')';
  end;
end;

function TAxis.ErrorToText: string;
 var
  i: Integer;
begin
  Result := '';
  for i := 0 to 4 do if (FError and (1 shl i)) <> 0 then Result := Result+ERR_COD[i];
  if Result = '' then Result := 'нет ошибок';
end;

procedure TAxis.FindMarker;
begin
//  ((Controller as IDevice).IConnect as IUDPConnectIO)
  (Controller as IUaki).Send(Fadr.ToString()+'m');
end;

function TAxis.GetAdr: Integer;
begin
  Result := Fadr;
end;

function TAxis.GetCurrentAngle: TAngle;
begin
  Result := FCurrentAngle + FDeltaAngle;
end;

function TAxis.GetDeltaAngle: TAngle;
begin
  Result := FDeltaAngle;
end;

function TAxis.GetEndTumbler: Char;
begin
  Result := FEndTumbler;
end;

function TAxis.GetError: Byte;
begin
  Result := FError;
end;

function TAxis.GetMotor: Char;
begin
  Result := FMotor;
end;

function TAxis.GetNeedAngle: TAngle;
begin
  Result.Angle := FNeedAngle.Angle;
end;

function TAxis.GetReper: Char;
begin
  Result := FReper;
end;

function TAxis.GetTOlerance: Double;
begin
//  FInfo := '-360000; 360000; 255; 500';
  if FInfo <> '' then
   begin
    Result := FInfo.Split([','])[3].Trim.ToInteger/1000
   end
  else
   begin
    Result := 0.05;
    (Controller as IUaki).Send(Fadr.ToString + '?', procedure(const Data: string; status: integer)
//    ((Controller as IDevice).IConnect as IUDPConnectIO).Send(Fadr.ToString + '?', procedure(const Data: string; status: integer)
    begin
      if Data <> '' then FInfo := Data.Split(['[',']'])[1];
    end);
   end;
end;

procedure TAxis.SetTolerance(const Value: Double);
 var
  a: TArray<string>;
  s: string;
begin
  if FInfo = '' then raise EDevUakiException.Create('ƒанные не считаны');
  a := FInfo.Split([',']);
  a[0] := a[0].Trim;
  a[1] := a[1].Trim;
  a[2] := a[2].Trim;
  a[3] := Round(Value*1000).ToString;
  s := Fadr.ToString + '!'+string.Join(' ', a)+'';
  (Controller as IUaki).Send(s, procedure(const Data: string; status: integer)
//  ((Controller as IDevice).IConnect as IUDPConnectIO).Send(s, procedure(const Data: string; status: integer)
  begin
    if Data <> '' then FInfo := Data.Split(['[',']'])[1];
  end);
end;

function TAxis.AngleFromStol(stol: Double): TAngle;
begin
  Result := stol/1000 * FKmulFromStol;
  Result := Result + TAngle(FAngAddFromStol);
end;

function TAxis.AngleToStol(angle: TAngle): Double;
begin
  angle := angle + TAngle(FAngAddtoStol);
  Result := angle.Angle*1000 * FKmulToStol;
//  TDebug.Log2Exept('[AngleToStol '+Fadr.ToString+']', Format('%d Curr %f Delta %f',[Round(Result), FCurrentAngle.Angle, FDeltaAngle.Angle]),'');
end;

procedure TAxis.GotoAngle(Angle: TAngle; MaxSpeed: Integer);
begin
  FMotor := 'G';
  if Freper <> 'M' then
    (Controller as IUaki).Send(Fadr.ToString + 'g' + Round(AngleToStol(Angle)).ToString + ','+ MaxSpeed.ToString, OnCurrentData)
//        ((Controller as IDevice).IConnect as IUDPConnectIO).Send(Fadr.ToString + 'g' + Round(Angle.Angle*1000).ToString + ','+ MaxSpeed.ToString, OnCurrentData)
  else  //((Controller as IDevice).IConnect as IUDPConnectIO).Send(Fadr.ToString + 'g' + Round(Double(Angle-FDeltaAngle)*1000).ToString + ','+ MaxSpeed.ToString, OnCurrentData);
    (Controller as IUaki).Send(Fadr.ToString + 'g' + Round(AngleToStol(Angle-FDeltaAngle)).ToString + ','+ MaxSpeed.ToString, OnCurrentData);
end;

procedure TAxis.OnCurrentData(const Data: string; status: integer);
 var
  a: TArray<string>;
  s: string;
begin
  if status >= 21 then
   begin
    a := Data.Split(['{', ',', '}'], TStringSplitOptions.ExcludeEmpty);

//    FCurrentAngle :=a[1].Trim.ToInteger / -1000/ FKDiv;
    FCurrentAngle :=AngleFromStol(a[1].Trim.ToInteger);
  //  NeedAngle :=     a[2].Trim.ToInteger / 1000;
    s :=             a[3].Trim;
    FReper := s.Chars[0];
    FMotor := s.Chars[1];
    FEndTumbler := s.Chars[2];
    FError := ('$'+ s.Substring(4,2)).ToInteger;
    (Controller as TDevUaki).S_AxisUpdate := FAdr;
   end;
end;

procedure TAxis.TermimateMoving;
begin
  (Controller as IUaki).Send(Fadr.ToString()+'s');
  //((Controller as IDevice).IConnect as IUDPConnectIO).Send(Fadr.ToString()+'s');
end;

procedure TAxis.UpdateAngleData;
begin
  (Controller as IUaki).Send(Fadr.ToString()+'a', OnCurrentData);
  //((Controller as IDevice).IConnect as IUDPConnectIO).Send(Fadr.ToString()+'a', OnCurrentData);
end;

initialization
  RegisterClass(TDevUaki);
  TRegister.AddType<TDevUaki, IDevice>.LiveTime(ltSingletonNamed);
finalization
  GContainer.RemoveModel<TDevUaki>;
end.

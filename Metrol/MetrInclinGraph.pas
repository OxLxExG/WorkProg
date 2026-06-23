
{$DEFINE Y_BASE}
//{$DEFINE TEST_1}

unit MetrInclinGraph;

interface

uses DeviceIntf, PluginAPI, ExtendIntf, RootIntf, RootImpl, Container, Actns, debug_except, DockIForm, math, MetrInclin,
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics, System.Bindings.Expression, Xml.XMLIntf,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, VirtualTrees, Vcl.Menus, Vcl.PlatformDefaultStyleActnCtrls, Vcl.ActnPopup, Vcl.ImgList, Vcl.ExtCtrls, Vcl.StdCtrls,
  MetrForm, Vcl.ComCtrls, AutoMetr.Inclin, FrameInclinGraph,LuaInclin.Math;

type
 TFormInclinADV = class(TFormInclin)
  private
   const
    AX=0;
    AY=1;
    AZ=2;
    HX=3;
    HY=4;
    HZ=5;
    ARR_TITLE: array [0..5] of string = ('GX','GY','GZ','HX','HY','HZ');
   var
    FNewAlgoritm: TMenuItem;
    FFrmGraph: TArray<TFrmInclinGraph>;
    function GetRoll(const tip, axis: string; alg: IXMLNode): TRollData;
//    function GetAxis(stp: Integer; const tip, axis: string; alg: IXMLNode):Double;
    procedure SolvRol(const tip, axis: string; alg: IXMLNode; ShowGraph: TFrmInclinGraph; out rez: TResultSolvRoll);
    {$IFDEF TEST_1}
    procedure _TEST_(Step: Integer; alg, trr: IXMLNode);
    {$ENDIF}
  protected
   const
    NICON = 55;
    class function ClassIcon: Integer; override;
    function AddTabSheet(const nme, title: string; unload: Boolean = True): TTabSheet;
    function AddGraph(prnt: TTabSheet): TFrmInclinGraph;
    procedure Loaded; override;
    function UserExecStep(Step: Integer; alg, trr: IXMLNode): Boolean; override;
    function UserSetupAlg(alg: IXMLNode): Boolean; override;
  public
    [StaticAction('Калибровка график отклонитель', 'Метрология', NICON, '0:Метрология.Инклинометры:-1')]
    class procedure DoCreateForm(Sender: IAction); override;
    class function MetrolType: string; override;
    constructor CreateUser(const aName: string =''); override;
 end;


implementation

uses tools;

{ TFormInclinADV }

function TFormInclinADV.AddGraph(prnt: TTabSheet): TFrmInclinGraph;
begin
  Result := TFrmInclinGraph.Create(pc);
  Result.Name := 'FRM_'+prnt.Name;
  Result.Parent := prnt;
  Result.Show;
  CArray.Add<TFrmInclinGraph>(FFrmGraph, Result);
end;

function TFormInclinADV.AddTabSheet(const nme, title: string; unload: Boolean): TTabSheet;
begin
  Result := TTabSheet.Create(pc);
  Result.PageControl := pc;
  if unload then Result.Tag := $12345678;
  Result.Caption := title;
  Result.Name := nme;
end;

class function TFormInclinADV.ClassIcon: Integer;
begin
  Result := NICON;
end;

constructor TFormInclinADV.CreateUser(const aName: string);
 var
  s: TTabSheet;
begin
  inherited;
  s := AddTabSheet('SpepMetr', 'Шаг метрологии', False);
  Tree.Parent := s;
  s.PageIndex := 0;
  pc.ActivePageIndex := 0;
end;

class procedure TFormInclinADV.DoCreateForm(Sender: IAction);
begin
  inherited;
end;

//function TFormInclinADV.GetAxis(stp: Integer; const tip, axis: string; alg: IXMLNode): Double;
//begin
//  Result := GetXNode(alg, Format('STEP%d.%s.%s.%s', [stp, tip, axis, T_DEV])).Attributes[AT_VALUE];
//end;

procedure TFormInclinADV.Loaded;
 var
  s: string;
begin
  inherited;
  FNewAlgoritm := AddToNCMenu('Рассчет новый', nil, 7, 1);
//  FNewAlgoritm.AutoCheck := True;
//  FNewAlgoritm.Checked := True;
//  FNewAlgoritm.MenuIndex := 7;
  for s in ARR_TITLE do AddGraph(AddTabSheet(s, s));
  pc.ActivePageIndex := 0;
end;

class function TFormInclinADV.MetrolType: string;
begin
  Result := 'T_OLD'
end;

function TFormInclinADV.UserSetupAlg(alg: IXMLNode): Boolean;
 var
  s: Variant;
begin
  Result := True;
  s := XtoVar(TMetrInclinMath.AddStep(1, 'Установить стол: Зенит 0, визирный угол 0 стол градусов.', alg));
  s.TASK.Vizir_Stol := 0;
  s.TASK.Zenit_Stol := 0;
  s.TASK.Dalay_Kadr := 5;
  s := XtoVar(TMetrInclinMath.AddStep(2, 'стол: визирный угол 90 градусов.', alg));
  s.TASK.Vizir_Stol := 90;
  s.TASK.Dalay_Kadr := 5;
  s := XtoVar(TMetrInclinMath.AddStep(3, 'стол: визирный угол 180 градусов.', alg));
  s.TASK.Vizir_Stol := 180;
  s.TASK.Dalay_Kadr := 5;
  s := XtoVar(TMetrInclinMath.AddStep(4, 'стол: визирный угол 270 градусов.', alg));
  s.TASK.Vizir_Stol := 270;
  s.TASK.Dalay_Kadr := 5;
  s := XtoVar(TMetrInclinMath.AddStep(5, 'стол: Установить стол: Зенит 19.5, Азимут 0, визирный угол 0 градусов.', alg));
  s.TASK.Vizir_Stol := 0;
  s.TASK.Azimut_Stol := 0;
  s.TASK.Zenit_Stol := 19.5;
  s.TASK.Dalay_Kadr := 5;
  s := XtoVar(TMetrInclinMath.AddStep(6, 'стол: визирный угол 90 градусов.', alg));
  s.TASK.Vizir_Stol := 90;
  s.TASK.Dalay_Kadr := 5;
  s :=XtoVar(TMetrInclinMath.AddStep(7, 'стол: визирный угол 180 градусов.', alg));
  s.TASK.Vizir_Stol := 180;
  s.TASK.Dalay_Kadr := 5;
  s := XtoVar(TMetrInclinMath.AddStep(8, 'стол: визирный угол 270 градусов.', alg));
  s.TASK.Vizir_Stol := 270;
  s.TASK.Dalay_Kadr := 5;
  TMetrInclinMath.SetupRoll(9, 90, 90, alg);
  s := XtoVar(TMetrInclinMath.AddStep(45, 'стол: Азимут стол 180, Зенит 70.5, прибор: визир 0 градусов.', alg));
  s.TASK.Azimut_Stol := 180;
  s.TASK.Zenit_Stol := 70.5;
  s.TASK.Vizir_Dev :=  0;
  s.TASK.Dalay_Kadr := 5;
end;

{$IFDEF TEST_1}
procedure TFormInclinADV._TEST_(Step: Integer; alg, trr: IXMLNode);
 {$J+}
  const C: TMetrInclinMath.TConvert = (m11: 1.2;    m12: 0.02;   m13: -0.01;   m14: -50;
                                       m21: 0.01;      m22: 1.7;    m23: 0.003;     m24:  100;
                                       m31: -0.05;      m32: -0.08;      m33: 1.5;   m34: -400);
 {$J-}
 var
  Hx1,Hy1,Hz1,
  Hx0,Hy0,Hz0,
  Hx,Hy,Hz,
  x,y,z: Double;
  v: Variant;
begin
  TMetrInclinMath.M3x4ToHorizont(1, C);
  with C do
   begin
    v := XToVar(GetXNode(alg, Format('STEP%d.magnit', [Step])));

    x := v.X.DEV.VALUE;
    y := v.Y.DEV.VALUE;
    z := v.Z.DEV.VALUE;

    Hx1 := m11*x + m12*y + m13*z + m14;
    Hy1 := m21*x + m22*y + m23*z + m24;
    Hz1 := m31*x + m32*y + m33*z + m34;

    Kxy := Pi * kxy / 180;
    Kxz := Pi * kxz / 180;
    Kyx := Pi * kyx / 180;
    Kyz := Pi * kyz / 180;
    kzx := Pi * kzx / 180;
    kzy := Pi * kzy / 180;

    Hx := (x - Sx)/Kx;
    Hy := (y - Sy)/Ky;
    Hz := (z - Sz)/Kz;

//    Hx0 := Hx * (1 +   Kyz*Kzy) - Hy * (kxy - kxz*kzy) + Hz * (kxy*kyz + kxz);
//    Hy0 := Hx * (Kyz*Kzx + Kyx) + Hy * (1 +   kxz*kzx) - Hz * (kyz - kxz*kyx);
//    Hz0 := Hx * (Kyx*Kzy - Kzx) + Hy * (kxy*kzx + kzy) + Hz * (1 +   kxy*kyx);
//
    Hx0 := Hx * (1 +   0) - Hy * (kxy - 0) + Hz * (0 + kxz);
    Hy0 := Hx * (0 + Kyx) + Hy * (1 +   0) - Hz * (kyz - 0);
    Hz0 := Hx * (0 - Kzx) + Hy * (0 + kzy) + Hz * (1 +   0);

   TDebug.Log('%.4f  |  %.4f  |  %.4f             ', [Hx1 - Hx0, Hy1 - Hy0, Hz1 - Hz0]);
   end;
end;
{$ENDIF}

function TFormInclinADV.GetRoll(const tip, axis: string; alg: IXMLNode): TRollData;
 var
  i: Integer;
begin
  for i := 0 to 35 do Result[i] := GetAxis(i+9, tip, axis, alg);
end;

procedure TFormInclinADV.SolvRol(const tip, axis: string; alg: IXMLNode; ShowGraph: TFrmInclinGraph; out rez: TResultSolvRoll);
 var
  Y: TRollData;
  i: Integer;
begin
  Y := GetRoll(tip, axis, alg);
  TMetrInclinMath.SolvRoll(Y, rez);
  ShowGraph.sb.Panels[1].Text := Format('Fz:%1.2f гр.', [RadToDeg(rez.Faza)]);
  ShowGraph.sb.Panels[2].Text := Format('Am:%1.2f', [rez.Amp]);
  ShowGraph.sb.Panels[3].Text := Format('dz:%1.2f', [rez.d0]);
  ShowGraph.sb.Panels[4].Text := Format('Ang:%d гр.', [rez.MaxErrIndex]);
  ShowGraph.sb.Panels[5].Text := Format('Err:%1.2f', [rez.MaxErr]);
  ShowGraph.sb.Panels[6].Text := Format('NEr:%1.2f%%', [rez.StdNormErr]);
  for i := 0 to 3 do ShowGraph.cht.Series[i].Clear;
  for i := 0 to 35 do
   begin
    ShowGraph.srData.Add(Y[i]);
    ShowGraph.srIst.Add(rez.IstData[i]);
    ShowGraph.srErrSin.Add(rez.Err[i]);
    ShowGraph.srErr.Add(rez.Noise[i]);
   end;
end;

function TFormInclinADV.UserExecStep(Step: Integer; alg, trr: IXMLNode): Boolean;
 type
  TZpoint = record
    Zamp, kX, kY, Zd0: Double;
  end;
 var
  rep: array[0..5] of TResultSolvRoll;
  zpH, zpG, zpHkor, zpGkor: TZpoint;
  function GetAmp(idrep: Integer): Double;
  begin
    if rep[idrep].Amp = 0 then Result := 0 else Result := 1000/rep[idrep].Amp
  end;
  function GetD0(idrep: Integer): Double;
  begin
    if rep[idrep].Amp = 0 then Result := 0 else Result := -rep[idrep].D0*1000/rep[idrep].Amp
  end;
  function FindAvg4(stp: Integer; const tip, axis: string): Double;
   var
    i: Integer;
  begin
    Result := 0;
    for i := stp to stp+4-1 do Result := Result + GetAxis(i, tip, axis, alg);
    Result := Result/4;
  end;
  function FindZP(stp: Integer; const tip: string): TZpoint;
  begin
    Result.Zamp := FindAvg4(stp, tip, 'Z');
    Result.kX := FindAvg4(stp, tip, 'X');
    Result.kY := FindAvg4(stp, tip, 'Y');
  end;
  function findZPkor(const tip: string; zp: TZpoint; rpidx: integer): TZpoint;
   var
    v: Variant;
  begin
    v := XToVar(GetXNode(trr, tip+'.m3x4'));
    Result.Zamp := 1000/(zp.Zamp - rep[rpidx+AZ].D0);
    Result.Zd0 := -rep[rpidx+AZ].D0*Result.Zamp;
    Result.kX := -(zp.kX - rep[rpidx+AX].D0) * GetAmp(rpidx+AX)/1000 * Result.Zamp;
    Result.kY := -(zp.kY - rep[rpidx+AY].D0) * GetAmp(rpidx+AY)/1000 * Result.Zamp;
    v.m13  :=  Result.kX;
    v.m23  :=  Result.kY;
    v.m33  := Result.Zamp;
    v.m34  := Result.Zd0;
  end;
  procedure findFazaRoll(const tip: string; rpidx: integer);
   var
    v: Variant;
  begin
    v := XToVar(GetXNode(trr, tip+'.m3x4'));
    {$IFDEF Y_BASE}
    v.m12 := rep[rpidx+AY].Faza - pi/2 - rep[rpidx+AX].Faza;
    if v.m12 > pi then v.m12 := v.m12-pi*2;
    if v.m12 < -pi then v.m12 := v.m12+pi*2;
    v.m12 := v.m12*v.m22;
    {$ELSE}
    v.m21 :=  (rep[rpidx+AY].Faza - pi/2 - rep[rpidx+AX].Faza)*v.m11;
    {$ENDIF}
  end;
  // без учета v.m21 или v.m12
  procedure findZRoll(const tip: string; rpidx: integer);
   var
    v: Variant;
  begin
    v := XToVar(GetXNode(trr, tip+'.m3x4'));
//    v.m31 := -rep[rpidx+AZ].Amp*v.m33/1000 * sin(pi/2 - rep[rpidx+AX].Faza + rep[rpidx+AZ].Faza)* v.m11;
//    v.m32 := -rep[rpidx+AZ].Amp*v.m33/1000 * sin(pi/2 - rep[rpidx+AY].Faza + rep[rpidx+AZ].Faza)* v.m22;
    v.m31 := -rep[rpidx+AZ].Amp*v.m33/1000 * cos(rep[rpidx+AZ].Faza - rep[rpidx+AX].Faza)* v.m11;
    v.m32 := -rep[rpidx+AZ].Amp*v.m33/1000 * cos(rep[rpidx+AZ].Faza - rep[rpidx+AY].Faza)* v.m22;
  end;
  procedure findFazaH();
   var
    x,y, xt,yt, ky: Double;
    v: Variant;
  begin
    v := XToVar(GetXNode(trr, 'magnit.m3x4'));

    xt := XToVar(alg).STEP45.accel.X.CLC.VALUE;
    yt := XToVar(alg).STEP45.accel.Y.CLC.VALUE;

    x := XToVar(alg).STEP45.magnit.X.CLC.VALUE;
    y := XToVar(alg).STEP45.magnit.Y.CLC.VALUE;

    ky := ArcTan2(y, -x) - ArcTan2(yt, -xt);


    v.m14 := v.m14 -sin(ky)*v.m24;
    v.m24 := v.m24 + sin(ky)*v.m14;

    v.m12 := -sin(ky) * v.m22;
    v.m21 := v.m21 + sin(ky)*v.m11;
  end;
  procedure SetResult(const tip: string; r: TLMFitting.TResult);
   var
    v: Variant;
  begin
    v := XToVar(GetXNode(trr, tip+'.m3x4'));
    v.m11 := r.m11; v.m12 := r.m12; v.m13 := r.m13; v.m14 := r.m14;
    v.m21 := r.m21; v.m22 := r.m22; v.m23 := r.m23; v.m24 := r.m24;
    v.m31 := r.m31; v.m32 := r.m32; v.m33 := r.m33; v.m34 := r.m34;
  end;
 var
  v: Variant;
  ResH, ResG: TLMFitting.TResult;
begin
  {$IFDEF TEST_1}
  _TEST_(Step, alg, trr);
  {$ENDIF}
  Result := True;
  if Step = 44 then
   begin

    SolvRol('accel',  'X', alg, FFrmGraph[AX], rep[AX]);
    SolvRol('accel',  'Y', alg, FFrmGraph[AY], rep[AY]);
    SolvRol('accel',  'Z', alg, FFrmGraph[AZ], rep[AZ]);
    SolvRol('magnit', 'X', alg, FFrmGraph[HX], rep[HX]);
    SolvRol('magnit', 'Y', alg, FFrmGraph[HY], rep[HY]);
    SolvRol('magnit', 'Z', alg, FFrmGraph[HZ], rep[HZ]);
    if FNewAlgoritm.Checked then
     begin
      TLMFitting.Run(GetRoll('accel', 'X', alg),
                     GetRoll('accel', 'Y', alg),
                     GetRoll('accel', 'Z', alg),
                     FindAvg4(1, 'accel', 'Z'),
                     FindAvg4(1, 'accel', 'X'),
                     FindAvg4(1, 'accel', 'Y'), ResG);
      SetResult('accel', ResG);

      TLMFitting.Run(GetRoll('magnit', 'X', alg),
                     GetRoll('magnit', 'Y', alg),
                     GetRoll('magnit', 'Z', alg),
                     FindAvg4(5, 'magnit', 'Z'),
                     FindAvg4(5, 'magnit', 'X'),
                     FindAvg4(5, 'magnit', 'Y'), ResH);
      SetResult('magnit', ResH);
     end
    else
     begin
      v := XToVar(trr);

      v.accel.m3x4.m11 := GetAmp(AX); v.accel.m3x4.m14 := GetD0(AX);
      v.accel.m3x4.m22 := GetAmp(AY); v.accel.m3x4.m24 := GetD0(AY);

      v.magnit.m3x4.m11 := GetAmp(HX); v.magnit.m3x4.m14 := GetD0(HX);
      v.magnit.m3x4.m22 := GetAmp(HY); v.magnit.m3x4.m24 := GetD0(HY);

      zpG := FindZP(1, 'accel');
      zpH := FindZP(5, 'magnit');

      zpGkor := findZPkor('accel',  zpG, AX);
      zpHkor := findZPkor('magnit', zpH, HX);

      findFazaRoll('accel',  AX);
      findFazaRoll('magnit', HX);

      findZRoll('accel',  AX);
      findZRoll('magnit', HX);
     end;
   end
  else if Step = 45 then findFazaH();
end;

initialization
//  TMetrInclinMath.Nop();
  RegisterClasses([TFormInclinADV, TTabSheet]);
  TRegister.AddType<TFormInclinADV, IForm>.LiveTime(ltSingletonNamed);
finalization
  GContainer.RemoveModel<TFormInclinADV>;
end.

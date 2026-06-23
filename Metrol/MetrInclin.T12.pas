unit MetrInclin.T12;

interface

uses AutoMetr.Inclin, LuaInclin.Math, MetrForm,
  DeviceIntf, PluginAPI, ExtendIntf, RootIntf, RootImpl, Container, Actns, debug_except, DockIForm, math, MetrInclin,
  Winapi.Windows, Winapi.Messages,
  System.SysUtils, System.Variants, System.Classes, Vcl.Graphics, System.Bindings.Expression,
  Xml.XMLIntf,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, VirtualTrees, Vcl.Menus, Vcl.PlatformDefaultStyleActnCtrls, Vcl.ActnPopup, Vcl.ImgList,
  Vcl.ExtCtrls, Vcl.StdCtrls,
  Vcl.ComCtrls;

type
 TFormInclinT12 = class(TFormInclin)
  private
//   const
//    AX=0;
//    AY=1;
//    AZ=2;
//    HX=3;
//    HY=4;
//    HZ=5;
//    ARR_TITLE: array [0..5] of string = ('GX','GY','GZ','HX','HY','HZ');
//   var
//    FNewAlgoritm: TMenuItem;
//    FFrmGraph: TArray<TFrmInclinGraph>;
//    function GetRoll(const tip, axis: string; alg: IXMLNode): TRollData;
//    function GetAxis(stp: Integer; const tip, axis: string; alg: IXMLNode):Double;
//    procedure SolvRol(const tip, axis: string; alg: IXMLNode; ShowGraph: TFrmInclinGraph; out rez: TResultSolvRoll);
//    {$IFDEF TEST_1}
//    procedure _TEST_(Step: Integer; alg, trr: IXMLNode);
//    {$ENDIF}
  protected
   const
    NICON = 59;
    class function ClassIcon: Integer; override;
//    function AddTabSheet(const nme, title: string; unload: Boolean = True): TTabSheet;
//    function AddGraph(prnt: TTabSheet): TFrmInclinGraph;
//    procedure Loaded; override;
    function UserExecStep(Step: Integer; alg, trr: IXMLNode): Boolean; override;
    function UserSetupAlg(alg: IXMLNode): Boolean; override;
  public
    [StaticAction('Новая калибровка Т12', 'Метрология', NICON, '0:Метрология.Инклинометры:-1')]
    class procedure DoCreateForm(Sender: IAction); override;
    class function MetrolType: string; override;
//    constructor CreateUser(const aName: string =''); override;
 end;


implementation

uses tools;

{ TFormInclinADV }

class function TFormInclinT12.ClassIcon: Integer;
begin
  Result := NICON;
end;

class procedure TFormInclinT12.DoCreateForm(Sender: IAction);
begin
  inherited;
end;

class function TFormInclinT12.MetrolType: string;
begin
  Result := 'T12'
end;

function TFormInclinT12.UserSetupAlg(alg: IXMLNode): Boolean;
 var
  s: Variant;
begin
  Result := True;
  s := TMetrInclinMath.AddStep(1, 'Cтол: Зенит 0 градусов.', alg);
 // s.TASK.Vizir_Stol := 0;
  s.TASK.Zenit_Stol := 0;
  s.TASK.Dalay_Kadr := 5;
  s := TMetrInclinMath.AddStep(2, 'Cтол: Зенит 180 градусов.', alg);
//  s.TASK.Vizir_Stol := 90;
  s.TASK.Zenit_Stol := 180;
  s.TASK.Dalay_Kadr := 5;
  s := TMetrInclinMath.AddStep(3, 'Cтол: Зенит 90 градусов. Датчик: Gy3 = N0 ~ 0, Gx3 < 0, Визир ~ 0', alg);
  s.TASK.Dalay_Kadr := 5;
  s := TMetrInclinMath.AddStep(4, 'Cтол: Визир повернуть на 180 градусов Gy3 = Gy4. Повторять 3,4 пока N0 = (Gy3+Gy4)/2. Установить смещение Визира', alg);
  s.TASK.Dalay_Kadr := 5;
  s := TMetrInclinMath.AddStep(5, 'Cтол: Визир установить на 90 градусов.', alg);
  s.TASK.Dalay_Kadr := 5;
  s := TMetrInclinMath.AddStep(6, 'Cтол: Визир установить на 270 градусов.', alg);
  s.TASK.Dalay_Kadr := 5;

  s := TMetrInclinMath.AddStep(7, 'Cтол: Зенит Z0(Hx,Hy посттоянные при вращении по оси), Азимут 0.', alg);
  s.TASK.Dalay_Kadr := 5;
  s := TMetrInclinMath.AddStep(8, 'Cтол: Зенит повернуть на 180 градусов.', alg);
  s.TASK.Dalay_Kadr := 5;
  s := TMetrInclinMath.AddStep(9, 'Стол: Азимут 90, Зенит 90, Визир 180+Z0.', alg);
  s.TASK.Dalay_Kadr := 5;
  s := TMetrInclinMath.AddStep(10, 'Cтол: Визир Z0 градусов.', alg);
  s.TASK.Dalay_Kadr := 5;
  s := TMetrInclinMath.AddStep(11, 'Cтол: Визир 90+Z0 градусов.', alg);
  s.TASK.Dalay_Kadr := 5;
  s := TMetrInclinMath.AddStep(12, 'Cтол: Визир 270+Z0 градусов.', alg);
  s.TASK.Dalay_Kadr := 5;
end;


function TFormInclinT12.UserExecStep(Step: Integer; alg, trr: IXMLNode): Boolean;
 var
  c, d: TMetrInclinMath.TConvert;
  x1, x2, x3, x4, x5, x6: Double;
  y1, y2, y3, y4, y5, y6: Double;
  z1, z2, z3, z4, z5, z6: Double;
  procedure UpdateAxis(const tip: string);
   var
    d: Integer;
  begin
    if tip = 'accel' then d := 0 else d := 6;

    x1 := GetAxis(d+1, tip, 'X',alg);
    x2 := GetAxis(d+2, tip, 'X',alg);
    x3 := GetAxis(d+3, tip, 'X',alg);
    x4 := GetAxis(d+4, tip, 'X',alg);
    x5 := GetAxis(d+5, tip, 'X',alg);
    x6 := GetAxis(d+6, tip, 'X',alg);

    y1 := GetAxis(d+1, tip, 'Y',alg);
    y2 := GetAxis(d+2, tip, 'Y',alg);
    y3 := GetAxis(d+3, tip, 'Y',alg);
    y4 := GetAxis(d+4, tip, 'Y',alg);
    y5 := GetAxis(d+5, tip, 'Y',alg);
    y6 := GetAxis(d+6, tip, 'Y',alg);

    z1 := GetAxis(d+1, tip, 'Z',alg);
    z2 := GetAxis(d+2, tip, 'Z',alg);
    z3 := GetAxis(d+3, tip, 'Z',alg);
    z4 := GetAxis(d+4, tip, 'Z',alg);
    z5 := GetAxis(d+5, tip, 'Z',alg);
    z6 := GetAxis(d+6, tip, 'Z',alg);
  end;
  procedure UpdateTRR(const tip: string);
   var
    v: Variant;
    ml: Integer;
  begin
    v := XToVar(GetXNode(trr, tip+'.m3x4'));
    TMetrInclinMath.HorizontToM3x4(1, c);
    v.m11 := c.m11;
    v.m12 := c.m12;
    v.m13 := c.m13;
    v.m14 := c.m14;

    v.m21 := c.m21;
    v.m22 := c.m22;
    v.m23 := c.m23;
    v.m24 := c.m24;

    v.m31 := c.m31;
    v.m32 := c.m32;
    v.m33 := c.m33;
    v.m34 := c.m34;
  end;
  procedure FindReal(x,y,z: Double; var rx,ry,rz: Double);
  begin
    rx := d.Kx*(       X + d.Kxy*Y - d.Kxz*Z) + d.Sx;
    ry := d.Ky*(-d.Kyx*X +       Y + d.Kyz*Z) + d.Sy;
    rz := d.Kz*( d.Kzx*X - d.Kzy*Y +       Z) + d.Sz;
  end;
  procedure test;
  begin
    d.Sx := 10;
    d.Sy := -17;
    d.Sz := 30.5;

    d.Kx := 1.123;
    d.Ky := 0.987;
    d.Kz := 1.321;

    d.Kxz := 0.01;
    d.Kyz := -0.02;

    d.Kyx := -0.03;
    d.Kxy := -0.04;

    d.Kzx := 0.05;
    d.Kzy := -0.06;
    FindReal(0,0,1000,  x1,y1,z1);
    FindReal(0,0,-1000, x2,y2,z2);
    FindReal(1000,0,0,  x3,y3,z3);
    FindReal(-1000,0,0, x4,y4,z4);
    FindReal(0,1000,0,  x5,y5,z5);
    FindReal(0,-1000,0, x6,y6,z6);

    c.Kx := (x3-x4)/2/1000;
    c.Ky := (y5-y6)/2/1000;
    c.Kz := (z1-z2)/2/1000;

    c.Sx := (x1+x2)/2;
    c.Sy := (y1+y2)/2;
    c.Sz := (z3+z4+z5+z6)/4;

 //   if (x4-x3 <> 0) and (y5-y6 <> 0) and (z1-z2 <> 0) then
     begin
      c.Kxz := ((x2-x1)/(x3-x4));
      c.Kyz := ((y1-y2)/(y5-y6));

      c.Kyx := ((y4-y3)/(y5-y6));
      c.Kxy := ((x5-x6)/(x3-x4));

      c.Kzx := ((z3-z4)/(z1-z2));
      c.Kzy := ((z6-z5)/(z1-z2));
     end;
  end;
begin
  Result := True;
  test;
  if Step = 6 then
   begin
    UpdateAxis('accel');

    c.Kx := (x4-x3)/2/1000;
    c.Ky := (y5-y6)/2/1000;
    c.Kz := (z1-z2)/2/1000;

    c.Sx := (x1+x2)/2;
    c.Sy := (y1+y2)/2;
    c.Sz := (z3+z4+z5+z6)/4;

   // if (x4-x3 <> 0) and (y5-y6 <> 0) and (z1-z2 <> 0) then
     begin
      c.Kxz := RadToDeg((x2-x1)/(x4-x3));
      c.Kyz := RadToDeg((y1-y2)/(y5-y6));

      c.Kyx := 0;
      c.Kxy := RadToDeg((x5-x6)/(x4-x3));

      c.Kzx := RadToDeg((z4-z3)/(z1-z2));
      c.Kzy := RadToDeg((z6-z5)/(z1-z2));
     end;

    UpdateTRR('accel');
   end
  else if Step = 12 then
   begin
    UpdateAxis('magnit');

    c.Kx := (x3-x4)/2/1000;
    c.Ky := (y5-y6)/2/1000;
    c.Kz := (z1-z2)/2/1000;

    c.Sx := (x1+x2)/2;
    c.Sy := (y1+y2)/2;
    c.Sz := (z3+z4+z5+z6)/4;

 //   if (x4-x3 <> 0) and (y5-y6 <> 0) and (z1-z2 <> 0) then
     begin
      c.Kxz := RadToDeg((x2-x1)/(x3-x4));
      c.Kyz := RadToDeg((y1-y2)/(y5-y6));

      c.Kyx := RadToDeg((y4-y3)/(y5-y6));
      c.Kxy := RadToDeg((x5-x6)/(x3-x4));

      c.Kzx := RadToDeg((z3-z4)/(z1-z2));
      c.Kzy := RadToDeg((z6-z5)/(z1-z2));
     end;

    UpdateTRR('magnit');
   end;
end;

initialization
  RegisterClasses([TFormInclinT12, TTabSheet]);
//  TRegister.AddType<TFormInclinT12, IForm>.LiveTime(ltSingletonNamed);
finalization
//  GContainer.RemoveModel<TFormInclinT12>;
end.

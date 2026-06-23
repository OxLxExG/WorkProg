unit MetrInclin.TrrAndP2;

interface

uses System.SysUtils, Xml.XMLIntf, System.Classes, Vcl.Menus, Vector,  MathIntf,  Vcl.Dialogs,
     PluginAPI, ExtendIntf, RootIntf, Container, Actns, debug_except, DockIForm, math, MetrForm, AutoMetr.Inclin, RootImpl,
     LuaInclin.Math, MetrInclin.Math2, XMLLua.Math, UakiIntf, MetrInclin.CheckForm;

type
  TFormInclinTrrAndP2 = class(TFormInclinCheck)
  private
    FNNoStol: TMenuItem;
    FNProblemML: TMenuItem;
    FNsolver: TMenuItem;
    FSaveAccel: TMatrix4;
    FTempTrr: IXMLNode;
    ErrOld, tG , tH: TMatrix4;
    class procedure _TEST_ApplyHGfromStol(alg: IXMLNode; from, too: Integer; Incl, Amp: Double; TrrA, TrrH: TMatrix4);
  protected
    FDirAzim, FDirViz: Integer;
//    procedure NNoStolClick(Sender: TObject);
//    procedure NProblemMLClick(Sender: TObject);
//    procedure NsolverClick(Sender: TObject);
    procedure FindMagnit(from, too: Integer; alg, trr: IXMLNode);
    procedure FindAccel(from, too: Integer; alg, trr: IXMLNode);
    /// количество поворотов вдоль оси для точек from, too включительно
    function ToRollCounts(alg: IXMLNode; from, too: Integer): TArray<Integer>;
    function ToInpRoll(alg,tr: IXMLNode; from, too: Integer; TrueAccFalseMag: Boolean; Trr: TMatrix4):TZAlignLS.TInput;
    function ToInpML(alg: IXMLNode; from, too: Integer): TArray<TInclPoint>;
    function ToInp(alg,tr: IXMLNode; from, too: Integer): TAngleFtting.TInput; overload;
    function ToInp(alg,tr: IXMLNode; from, too: Integer; TrueAccFalseMag: Boolean; Trr: TMatrix4): TZAlignLS.TZConstPoints; overload;
    function ToInp(alg,tr: IXMLNode; from, too: Integer; TrrA, TrrH: TMatrix4): TCrossConstLS.TInclPoints; overload;
    function ToInp(alg,tr: IXMLNode; from, too: Integer; TrrA: TMatrix4): TCrossConstLS.TInclPoints; overload;
    function AddVizir(v: Double): Variant;
    function UserSetupAlg(alg: IXMLNode): Boolean; override;
    procedure DoSetupAlg; virtual;
    function UserExecStep(Step: Integer; alg, trr: IXMLNode): Boolean; override;
    function NextAngle(DeltaAngle, DeltaCycle: Double; var IncDir: Integer; var Curr: Double): boolean;
    procedure CreateStepsFixZU(DeltaA, DeltaV, Zu: Double);
    procedure Loaded; override;
    class function ClassIcon: Integer; override;
   const
    NICON = 345;
  public
    [StaticAction('Новая калибровка 64 точки', 'Метрология', NICON, '0:Метрология.Инклинометры:-1')]
    class procedure DoCreateForm(Sender: IAction); override;
    class function MetrolType: string; override;
  end;

implementation

uses tools;

{ TFormInclinTrrAndP2 }

class function TFormInclinTrrAndP2.ClassIcon: Integer;
begin
  Result := NICON;
end;

class procedure TFormInclinTrrAndP2.DoCreateForm(Sender: IAction);
begin
  inherited;
end;

class function TFormInclinTrrAndP2.MetrolType: string;
begin
  Result := 'P_2';
end;

function TFormInclinTrrAndP2.NextAngle(DeltaAngle, DeltaCycle: Double; var IncDir: Integer; var Curr: Double): boolean;
begin
  if IncDir = 1 then Result := Curr + DeltaAngle < 360
  else Result := Curr - DeltaAngle >= 0;
  if not Result then
   begin
    IncDir := -IncDir;
    Curr := Curr + DeltaCycle;
   end
  else Curr := Curr + IncDir * DeltaAngle
end;

{procedure TFormInclinTrrAndP2.NNoStolClick(Sender: TObject);
begin

end;

procedure TFormInclinTrrAndP2.NProblemMLClick(Sender: TObject);
begin

end;

procedure TFormInclinTrrAndP2.NsolverClick(Sender: TObject);
begin

end;}

function TFormInclinTrrAndP2.AddVizir(v: Double): Variant;
begin
  FCurViz := v;
  Result := AddStep('стол: визирный угол %2:g градусов.', FCurAzim, FCurZu, FCurViz);
  Result.TASK.Vizir_Stol := v;
  Result.TASK.Dalay_Kadr := 5;
end;

procedure TFormInclinTrrAndP2.CreateStepsFixZU(DeltaA, DeltaV, Zu: Double);
 var
  s: Variant;
begin
  FCurZu := Zu;
  s := AddStep('стол: Азимут %g Зенит %g визир %g градусов.', FCurAzim, FCurZu, FCurViz);
  FCurZu := Zu;
  s.TASK.Azimut_Stol := FCurAzim;
  s.TASK.Zenit_Stol := zu;
  s.TASK.Vizir_Stol := FCurViz;
  s.TASK.Dalay_Kadr := 5;
  repeat
   while NextAngle(DeltaV, 0, FDirViz, FCurViz) do AddVizir(FCurViz);
   if not NextAngle(DeltaA, 0, FDirAzim, FCurAzim) then Break;
   s := AddStep('стол: Азимут %g градусов.', FCurAzim, Zu, FCurViz);
   s.TASK.Azimut_Stol := FCurAzim;
   s.TASK.Dalay_Kadr := 5;
  until False;
end;

procedure TFormInclinTrrAndP2.DoSetupAlg;
begin
  CreateStepsFixZU(60,72,45);
  CreateStepsFixZU(60,72,90);
end;

function TFormInclinTrrAndP2.UserSetupAlg(alg: IXMLNode): Boolean;
 var
  s: Variant;
  i: Integer;
begin
  Result := True;
  FStep.root := alg;
  FStep.stp := 1;

  FCurAzim := 0;
  FCurViz := 270;
  FCurZu := 0;

  s := AddStep('стол: Зенит 0, визир %2:g градусов.', 0, 0, 270);
  s.TASK.Vizir_Stol := 270;
  s.TASK.Zenit_Stol := 0;
  s.TASK.Dalay_Kadr := 5;

  for I := 2 downto 0 do AddVizir(i*90);

  FCurAzim := 0; FCurViz := 0;
  FDirAzim := 1; FDirViz := 1;

  DoSetupAlg;
end;

class procedure TFormInclinTrrAndP2._TEST_ApplyHGfromStol(alg: IXMLNode; from, too: Integer; Incl, Amp: Double; TrrA, TrrH: TMatrix4);
type
  Tfdata = array[0..65*3] of double;
  Pfdata = ^Tfdata;

 var
  i: Integer;
  v:Variant;
  P: TInclPoint;
  m3G, m3H: TMatrix3;
  v3G, v3H: TVector3;

  e: INoise;
  noise: Pfdata;



  const
   {$J+}
   a: Double = 90;
   z: Double = 90;
   o: Double = 90;
   {$J-}
begin
  m3H := TMatrix3(TrrH).inv;
  m3G := TMatrix3(TrrA).inv;
  v3H := TrrH.Vector(3);
  v3G := TrrA.Vector(3);

  NoiseFactory(e);
  CheckMath(e, e.normal(too-from+1, 1, PdoubleArray(noise)));

  for i := from to too do
   begin
     v := XToVar(GetXNode(alg, Format('STEP%d',[I])));
     try
      a := v.TASK.Azimut_Stol;
     except
     end;
     try
      z := v.TASK.Zenit_Stol;
     except
     end;
     try
      o := v.TASK.Vizir_Stol;
     except
     end;
     P := TMetrInclinMath.FindXYZ(a,z, o, Incl, Amp);
     P.G := m3G * (P.G-v3G);
     P.H := m3H * (P.H-v3H);
     v.accel.X.DEV.VALUE := p.G.X;
     v.accel.Y.DEV.VALUE := p.G.Y;
     v.accel.Z.DEV.VALUE := p.G.Z;
     v.magnit.X.DEV.VALUE := p.H.X;
     v.magnit.Y.DEV.VALUE := p.H.Y + noise[i];
     v.magnit.Z.DEV.VALUE := p.H.Z;
     v.СТОЛ.азимут := a;
     v.СТОЛ.зенит := z;
   end;
end;

function TFormInclinTrrAndP2.ToInp(alg,tr: IXMLNode; from, too: Integer): TAngleFtting.TInput;
 var
  i: Integer;
  v:Variant;

  n: IXMLNode;
  g,h: TVector3;

begin
  SetLength(Result, too-from+1);
  for i := 0 to High(Result) do
   begin
    v := XToVar(GetXNode(alg, Format('STEP%d',[I+from])));
    with Result[i] do
     begin
        g.x := v.accel.X.DEV.VALUE;
        g.y := v.accel.Y.DEV.VALUE;
        g.z := v.accel.Z.DEV.VALUE;
        h.x := v.magnit.X.DEV.VALUE;
        h.y := v.magnit.Y.DEV.VALUE;
        h.z := v.magnit.Z.DEV.VALUE;

        n := GetXNode(alg, Format('STEP%d.T.DEV',[I+from]));
        if Assigned(FTempTrr) and Assigned(n) then
         begin
          g := TTrrT.Find(g,n.Attributes[AT_VALUE],true);
          h := TTrrT.Find(h,n.Attributes[AT_VALUE],false);
         end;

      gx := g.X;
      gy := g.Y;
      gz := g.Z;
      hx := h.X;
      hy := h.Y;
      hz := h.Z;
      AziStol := v.СТОЛ.азимут + FAziCorr;
      ZenStol := v.СТОЛ.зенит + FZenCorr;
      try
      MagAmp := v.СТОЛ.амплит_magnit;
      except

      end;
     end;
   end;
end;


function TFormInclinTrrAndP2.ToInp(alg,tr: IXMLNode; from, too: Integer; TrrA, TrrH: TMatrix4): TCrossConstLS.TInclPoints;
 var
  i: Integer;
  v: Variant;
  n: IXMLNode;
  g,h: TVector3;
begin
  SetLength(Result, too-from+1);
  for i := 0 to High(Result) do
   begin
    v := XToVar(GetXNode(alg, Format('STEP%d',[I+from])));

//  v.accel.X.DEV.VALUE := v.accel.X.DEV.VALUE*1000;
//  v.accel.Y.DEV.VALUE := v.accel.Y.DEV.VALUE*1000;
//  v.accel.Z.DEV.VALUE := v.accel.Z.DEV.VALUE*1000;
//  v.magnit.X.DEV.VALUE := v.magnit.X.DEV.VALUE*1000;
//  v.magnit.Y.DEV.VALUE := v.magnit.Y.DEV.VALUE*1000;
//  v.magnit.Z.DEV.VALUE := v.magnit.Z.DEV.VALUE*1000;

    g.x := v.accel.X.DEV.VALUE;
    g.y := v.accel.Y.DEV.VALUE;
    g.z := v.accel.Z.DEV.VALUE;
    h.x := v.magnit.X.DEV.VALUE;
    h.y := v.magnit.Y.DEV.VALUE;
    h.z := v.magnit.Z.DEV.VALUE;

    n := GetXNode(alg, Format('STEP%d.T.DEV',[I+from]));
    if Assigned(FTempTrr) and Assigned(n) then
     begin
      g := TTrrT.Find(g,n.Attributes[AT_VALUE],true);
      h := TTrrT.Find(h,n.Attributes[AT_VALUE],false);
     end;

    Result[i].A := TrrA * g;
    Result[i].H := TrrH * h;
   end;
end;

function TFormInclinTrrAndP2.ToInp(alg,tr: IXMLNode; from, too: Integer; TrrA: TMatrix4): TCrossConstLS.TInclPoints;
 var
  i: Integer;
  v: Variant;
  n: IXMLNode;
  g,h: TVector3;
begin
  SetLength(Result, too-from+1);
  for i := 0 to High(Result) do
   begin
    v := XToVar(GetXNode(alg, Format('STEP%d',[I+from])));
    g.x := v.accel.X.DEV.VALUE;
    g.y := v.accel.Y.DEV.VALUE;
    g.z := v.accel.Z.DEV.VALUE;
    h.x := v.magnit.X.DEV.VALUE;
    h.y := v.magnit.Y.DEV.VALUE;
    h.z := v.magnit.Z.DEV.VALUE;

    n := GetXNode(alg, Format('STEP%d.T.DEV',[I+from]));
    if Assigned(FTempTrr) and Assigned(n) then
     begin
      g := TTrrT.Find(g,n.Attributes[AT_VALUE],true);
      h := TTrrT.Find(h,n.Attributes[AT_VALUE],false);
     end;

    Result[i].A := TrrA * g;
    Result[i].H := h;
   end;
end;


function TFormInclinTrrAndP2.ToInpML(alg: IXMLNode; from, too: Integer): TArray<TInclPoint>;
 var
  i: Integer;
  v: Variant;
begin
  SetLength(Result, too-from+1);
  for i := 0 to High(Result) do Result[i] := XToVar(GetXNode(alg, Format('STEP%d',[I+from])));
end;

function TFormInclinTrrAndP2.ToRollCounts(alg: IXMLNode; from, too: Integer): TArray<Integer>;
 var
  i, n: Integer;
  v: Variant;
  zen, azi: Double;
  function IsRol: Boolean;
   var
    a, z: Double;
  begin
    v := XToVar(GetXNode(alg, 'STEP'+I.ToString));
    z := v.СТОЛ.зенит;
    a := v.СТОЛ.азимут;
    Result := (Abs(TMetrInclinMath.DeltaAngle(azi - a)) < 10) and (Abs(TMetrInclinMath.DeltaAngle(zen - z)) < 1.5);
  end;
begin
  i := from;
  v := XToVar(GetXNode(alg, 'STEP'+I.ToString));
  repeat
   zen := v.СТОЛ.зенит;
   azi := v.СТОЛ.азимут;
   n := 0;
   while (i <= too) and IsRol do
    begin
     inc(n);
     inc(i);
    end;
   Result := Result + [n];
  until i > too;
end;

function TFormInclinTrrAndP2.ToInp(alg,tr: IXMLNode; from, too: Integer; TrueAccFalseMag: Boolean; Trr: TMatrix4): TZAlignLS.TZConstPoints;
 const
  AM: array[Boolean] of string = ('magnit', 'accel');
 var
  i: Integer;
  v: Variant;
  n: IXMLNode;
  p: TVector3;
begin
  SetLength(Result, too-from+1);
  for i := 0 to High(Result) do
   begin
    v := XToVar(GetXNode(alg, Format('STEP%d.%s',[I+from, AM[TrueAccFalseMag]])));
    p.X := v.X.DEV.VALUE;
    p.Y := v.Y.DEV.VALUE;
    p.Z := v.Z.DEV.VALUE;
    n := GetXNode(alg, Format('STEP%d.T.DEV',[I+from]));
    if Assigned(FTempTrr) and Assigned(n) then
     begin
      p := TTrrT.Find(p,n.Attributes[AT_VALUE],TrueAccFalseMag);
     end;
    Result[i] := Trr * p;
   end;
end;

function TFormInclinTrrAndP2.ToInpRoll(alg,tr: IXMLNode; from, too: Integer; TrueAccFalseMag: Boolean; Trr: TMatrix4): TZAlignLS.TInput;
 var
  ArrCnt: TArray<Integer>;
  i, first: Integer;
begin
  ArrCnt := ToRollCounts(alg, from, too);
  SetLength(Result, Length(ArrCnt));
  first := from;
  for i := 0 to High(ArrCnt) do
   begin
    Result[i] := ToInp(alg,tr, first, first + ArrCnt[i]-1, TrueAccFalseMag, Trr);
    Inc(first, ArrCnt[i]);
   end;
end;


procedure TFormInclinTrrAndP2.FindAccel(from, too: Integer; alg, trr: IXMLNode);
 var
  m: TAngleFtting.TMetr;
  inp: TAngleFtting.TInput;
  Res: TMatrix4;
  alignInp: TZAlignLS.TInput;
  i: Integer;
  a, b : Double;

begin
{  tG := Matrix4Identity;
  tH := Matrix4Identity;
  with tG do
   begin
    m11 :=	0.91;      m12 :=	0.0012;        m13 :=	 -0.0013;   m14 := -1.4;
    m21 :=	0;        m22 :=	0.92;           m23 :=	0.0023;     m24 := 2.4;
    m31 :=	0.0031;   m32 :=	-0.0032;      m33 :=	 0.93;  m34 := -3.4;
   end;

  with tH do
   begin
    m11 :=	 1.71;         m21 :=	0.003;       m31 :=	-0.0031;
    m12 :=	-0.0112;       m22 :=	1.72;         m32 :=	-0.0032;
    m13 :=	-0.0013;       m23 :=	0.0023;       m33 :=	1.73;
    m14 :=	-10.4;          m24 :=	20.4;          m34 :=	-30.4;
   end;}
//  _TEST_ApplyHGfromStol(alg, from, too, 10.9, 1000, tG, tH);
   FTempTrr := trr.ChildNodes.FindNode('T');
   if Assigned(FTempTrr) then TTrrT.FindTrrTemp(trr);

  inp := ToInp(alg,trr, from, too);

  if FNNoStol.Checked then
   begin
    // без стола
    TSphereLS.RunZ(inp, Res);
{    SetLength(alignInp, 12);//6
    for I := 0 to High(alignInp) do alignInp[i] := ToInp(alg, 5+i*5, 9+i*5, True, Res);}
    alignInp := ToInpRoll(alg,trr, from, too, True, Res);
    //  SetLength(alignInp, 1);
    //  i := 1;
    //  alignInp[0] := ToInp(alg, 35+i*5, 39+i*5, True, Res);

   if FNsolver.Checked then
    begin
     TZAlignLS.RunLeMa(alignInp, a,b);
     FSaveAccel := TZAlignLS.ApplyLeMa(Res, a, b);
    end
   else
    begin
     TZAlignLS.Run(alignInp, a,b);
     FSaveAccel := TZAlignLS.Apply(Res, a, b);
    end;

    Matrix4AssignToVariant(FSaveAccel, XToVar(GetXNode(trr, 'accel')));
   end
  else
   begin
    TSphereLS.RunZ(inp, Res);
    {SetLength(alignInp, 12);//6
    for I := 0 to High(alignInp) do alignInp[i] := ToInp(alg, 5+i*5, 9+i*5, True, Res);}
    alignInp := ToInpRoll(alg,trr, from, too, True, Res);

    TZAlignLS.Run(alignInp, a,b);
    FSaveAccel := TZAlignLS.Apply(Res, a, b);
    m := TAngleFtting.Tmetr(FSaveAccel);// {* (1/FSaveAccel.m22)   }
    m.m21 := m.m22;
    // LEVENBERG
//    m.Reset;
    TAngleFtting.RunZ(inp, m);
//    m := TAngleFtting.Tmetr(FSaveAccel {* (1/FSaveAccel.m22)});
    m.AssignTo(XToVar(GetXNode(trr, 'accel')));
   end;
end;

//var
//__tatA: Double = -0.004;
{procedure _sts( alg: IXMLNode);
 var
  v: Variant;
  i: Integer;
begin
  for i := 1 to 4 do
   begin
    v := XToVar(GetXNode(alg, Format('STEP%d',[i])));

  v.accel.X.DEV.VALUE := v.accel.X.DEV.VALUE*1000;
  v.accel.Y.DEV.VALUE := v.accel.Y.DEV.VALUE*1000;
  v.accel.Z.DEV.VALUE := v.accel.Z.DEV.VALUE*1000;
  v.magnit.X.DEV.VALUE := v.magnit.X.DEV.VALUE*1000;
  v.magnit.Y.DEV.VALUE := v.magnit.Y.DEV.VALUE*1000;
  v.magnit.Z.DEV.VALUE := v.magnit.Z.DEV.VALUE*1000;
   end;
end;}


procedure TFormInclinTrrAndP2.FindMagnit(from, too: Integer; alg, trr: IXMLNode);
 var
  m: TAngleFtting.TMetr;
  inp: TAngleFtting.TInput;
  Res, m2, m3, m4, e: TMatrix4;
  alignInp: TZAlignLS.TInput;
  i: Integer;
  a, b, incl, inclML: Double;
begin
  inp := ToInp(alg,trr, from, too);
  if FNNoStol.Checked then
   begin
//    _sts(alg);
//     без стола
    TSphereLS.RunA(inp, Res);
    {SetLength(alignInp, 12);//6
    for I := 0 to High(alignInp) do alignInp[i] := ToInp(alg, 5+i*5, 9+i*5, False, Res);}
    alignInp := ToInpRoll(alg,trr, from, too, False, Res);

   if FNsolver.Checked then
    begin
//   LEVENBERG
     TZAlignLS.RunLeMa(alignInp, a,b);
     m2 := TZAlignLS.ApplyLeMa(Res, a, b);
     TCrossConstLS.RunLeMa(ToInp(alg,trr, from, too, FSaveAccel, m2), a, b);
     m3 := TCrossConstLS.ApplyLeMa(m2, a);
    end
   else
    begin
//   NMK
     TZAlignLS.Run(alignInp, a,b);
     m2 := TZAlignLS.Apply(Res, a, b);
     TCrossConstLS.Run(ToInp(alg,trr, from, too, FSaveAccel, m2), a, b);
     m3 := TCrossConstLS.Apply(m2, a);
    end;
//    incl := RadToDeg(Arccos(b/1000/1000));
    if FNProblemML.Checked then TTrrML.Run(b, m3, FSaveAccel, ToInpML(alg, 1, too), m4, inclML)
    else m4 := m3;

 //   m4 := m2;
//
    Matrix4AssignToVariant(m4, XToVar(GetXNode(trr, 'magnit')));

//    e := -m4 + tH;
//    ErrOld := e;
   end
  else
   begin
    // LEVENBERG
    TAngleFtting.RunA(inp, m);
    m.AssignTo(XToVar(GetXNode(trr, 'magnit')));

//    e := -Tmatrix4(m) + tH;
//    ErrOld := e;
   end;
end;

procedure TFormInclinTrrAndP2.Loaded;
begin
  inherited;
  FNNoStol := AddToNCMenu('Не использовать данные стола', nil, 2, 0, FExtendMenus);
  FNProblemML := AddToNCMenu('Использовать метод МП', nil, 3, 0, FExtendMenus);
  FNsolver := AddToNCMenu('Не использовать НМК', nil, 4, 0, FExtendMenus);
  AddToNCMenu('-', nil, 5, -1, FExtendMenus);
end;

function TFormInclinTrrAndP2.UserExecStep(Step: Integer; alg, trr: IXMLNode): Boolean;
begin
  Result := True;
  //UserExecStepUpdateStolAngle(Step, alg, trr);
  case Step of
   64:
      begin
       if FNewAlg then FindAccel(1, 64, alg, trr);
       RefindZen(1, 64, alg, trr);
       if FNewAlg then  FindMagnit(5,64, alg, trr);
       RefindAzi(1, 64, alg, trr);
       FNewAlg := False;
       alg.Attributes['ErrZU']  := FindMaxErr(alg, 1, 64, 'err_зенит');
       alg.Attributes['ErrAZ']  := FindMaxErr(alg, 5, 64, 'err_азимут');
       alg.Attributes['ErrAZ5']  := -1000;
      end;
  end;
end;

initialization
  RegisterClass(TFormInclinTrrAndP2);
  TRegister.AddType<TFormInclinTrrAndP2, IForm>.LiveTime(ltSingletonNamed);
finalization
  GContainer.RemoveModel<TFormInclinTrrAndP2>;
end.

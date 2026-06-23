unit XMLScript.Math;

interface

uses  XMLScript, tools, debug_except, MathIntf, System.UITypes,{ WinAPI.GDIPObj, WinAPI.GDIPApi,}
    SysUtils, o_iinterpreter, o_ipascal, Xml.XMLIntf, System.Generics.Collections, System.Classes, math, System.Variants;

type
  TXMLScriptMath = class
  private
    class constructor Create;
    class destructor Destroy;
  public
    class function CallMeth(Instance: TObject; ClassType: TClass; const MethodName: String; var Params: Variant): Variant;
    class procedure ExecStepGK1(stp: integer; alg, trr: variant; IsGk: boolean); static;

    class function AddMetrology(root: Variant; const Title, eu: string; Znd: Double = 0; varTip: Integer = 5): Variant; static;
    class function AddMetrologyFM(root: Variant; Digits, Aqu: Integer): Variant; static;
    class function AddMetrologyRG(root: Variant; Lo, Hi: Double): Variant; static;
    class function AddMetrologyCL(root: Variant; Color: TAlphaColor; Width: Single = 2; Dash: Integer = 0): Variant; static;

    class procedure TrrVect3D(root, Inp: Variant; Scale: Integer = 1); static;
    class procedure AddXmlMatrix(root: Variant; Row, col: Integer); overload; static;
    class procedure AddXmlMatrix(root: IXMLNode; Row, col: Integer); overload; static;
    class function AddXmlPath(root: Variant; const path: string): Variant; static;
    class function FindXmlRoot(cur: Variant; const Section, root: string; var p: Variant): Boolean; static;
    class function Hypot3D(X, Y, Z: Double): Double; static;
    class procedure GetH(Azi, Zen, Otk: Double; out X,Y,Z: Double; I: Double = 19.2;  Amp: Double = 1000); static;
    class function GetAzi(Zen, Otk, X,Y,Z: Double): Double; static;
    class procedure ImportNNK10(const TrrFile: string; NewTrr: Variant); static;
    class procedure SGK_FindGK(root: variant); static;
    class function RadToDeg180(Rad: Double): Double; static;
    class function RadToDeg360(Rad: Double): Double; static;
    class function RbfInterp(xy: Variant; x1, x2: Double): Double; static;
    class function XmlPathExists(root: Variant; const path: string): Boolean; static;
  end;

implementation

{ TXMLScriptMath }

class function TXMLScriptMath.CallMeth(Instance: TObject; ClassType: TClass; const MethodName: String; var Params: Variant): Variant;
 var
  v: Variant;
begin
  if      MethodName = 'KADRTOSTR'      then Result := CTime.AsString(CTime.FromKadr(Params[0]))
  else if MethodName = 'EXECSTEPGK1'    then           ExecStepGK1(   Params[0], Params[1], Params[2], Params[3])
  else if MethodName = 'ADDXMLMATRIX'   then           AddXmlMatrix(  Params[0], Params[1], Params[2])
  else if MethodName = 'ADDXMLPATH'     then Result := AddXmlPath(    Params[0], Params[1])
  else if MethodName = 'ADDMETROLOGY'   then Result := AddMetrology(  Params[0], Params[1], Params[2], Params[3], Params[4])
  else if MethodName = 'ADDMETROLOGYFM' then Result := AddMetrologyFM(Params[0], Params[1], Params[2])
  else if MethodName = 'ADDMETROLOGYRG' then Result := AddMetrologyRG(Params[0], Params[1], Params[2])
  else if MethodName = 'ADDMETROLOGYCL' then Result := AddMetrologyCL(Params[0], Params[1], Params[2], Params[3])
  else if MethodName = 'TRRVECT3D'      then           TrrVect3D(     Params[0], Params[1], Integer(Params[2]))
  else if MethodName = 'ARCTAN2'        then Result := ArcTan2(       Params[0], Params[1])
  else if MethodName = 'HYPOT'          then Result := Hypot(         Params[0], Params[1])
  else if MethodName = 'HYPOT3D'        then Result := Hypot3D(       Params[0], Params[1], Params[2])
  else if MethodName = 'SGK_FINDGK'     then           SGK_FindGK(    Params[0])
  else if MethodName = 'RADTODEG_0_180' then Result := RadToDeg180(   Params[0])
  else if MethodName = 'RADTODEG_0_360' then Result := RadToDeg360(   Params[0])
  else if MethodName = 'RADTODEG'       then Result := RadToDeg(      Params[0])
  else if MethodName = 'ARCCOS'         then Result := Arccos(        Params[0])
  else if MethodName = 'VARASTYPE'      then Result := VarAsType(     Params[0], Params[1])
//  else if MethodName = 'IDWINTERP'      then Result := IDWInterp(   Params[0], Params[1])
  else if MethodName = 'RBFINTERP'      then Result := RbfInterp(     Params[0], Params[1], Params[2])
  else if MethodName = 'XMLPATHEXISTS'  then Result := XmlPathExists( Params[0], Params[1])
  else if MethodName = 'IMPORTNNK10'    then           ImportNNK10(   Params[0], Params[1])
  else if MethodName = 'FINDXMLROOT'    then
   begin
    Result := FindXmlRoot(Params[0], Params[1], Params[2], V);
    Params[3] := V;
   end;
end;

class constructor TXMLScriptMath.Create;
begin
  TXmlScriptInner.RegisterMethods([
  'procedure ExecStepGK1(stp: integer; alg, trr: variant; IsGk: boolean)',
  'function AddXmlPath(root: Variant; const path: string): Variant',
  'procedure AddXmlMatrix(root: Variant; Row, col: Integer)',
//  'procedure AddMetrology(root: Variant; const eu, fmt: string; RangeLo, RangeHi: Double; Znd: Double = 0)',
  'function AddMetrology(root: Variant; const Title, eu: string; Znd: Double = 0; varTip: Integer = 5): Variant',
  'function AddMetrologyFM(root: Variant; Digits, Aqu: Integer): Variant',
  'function AddMetrologyRG(root: Variant; Lo, Hi: Double): Variant',
  'function AddMetrologyCL(root: Variant; Color: TAlphaColor; Width: Double = 2.0; Dash: Integer = 0): Variant',
  'procedure XmlMatrixMulVect(root, Inp: Variant; var res: Variant)',
  'procedure TrrVect3D(root, Inp: Variant; Scale: Integer = 1)',
  'function Hypot(X, Y: Double): Double',
  'function Hypot3D(X, Y, Z: Double): Double',
  'function ArcTan2(Y, X: Double): Double',
  'procedure SGK_FindGK(root: variant)',
  'function RadToDeg_0_180(Rad: Double): Double',
  'function RadToDeg_0_360(Rad: Double): Double',
  'function RadToDeg(Rad: Double): Double',
  'function ArcCos(Rad: Double): Double',
  'function VarAsType(const V: Variant; AVarType: Integer): Variant',
// function IDWInterp(data, point: Variant): Double;', CallMeth);
  'function RbfInterp(xy: Variant; x1, x2: Double): Double',
  'function XmlPathExists(root: Variant; const path: string): Boolean',
  'function FindXmlRoot(cur: Variant; const Section, root: string; var p: Variant): Boolean',
  'procedure ImportNNK10(const TrrFile: string; NewTrr: Variant)',
  'function KadrToStr(Kadr: Integer): string'], CallMeth);
end;

class destructor TXMLScriptMath.Destroy;
begin
  TXmlScriptInner.UnRegisterMethods(CallMeth);
end;

class procedure TXMLScriptMath.ExecStepGK1(stp: integer; alg, trr: variant; IsGk: boolean);
 type
  Tfuncs = array[0..1] of Double;
 var
  ls: ILSFitting;
  y: TArray<Double>;
  fmatrix: TArray<Tfuncs>;
  n, info: Integer;
  c: PDoubleArray;
  Rep: PSLFittingReport;
  x: IXMLNode;
  v, vngk: Variant;
  fx: Tfuncs;
  procedure vTovngk;
  begin
    if IsGk then vngk := v.гк
    else  vngk := v.нгк
  end;
// const                    (8.28125, 22.34375, 34.21875, 63.59375, 90.75, 117.625, 153.75, 307.5625, 458.4375, 616.15625)
//                          ((1, 0), (1, 5), (1, 10), (1, 20), (1, 30), (1, 40), (1, 50), (1, 100), (1, 150), (1, 200))
//  fmatrix: array [0..9,0..1]of Double = ((1,0),(1,5),(1,10),(1,20),(1,30),(1,40),(1,50),(1,100),(1,150),(1,200));
begin
  LSFittingFactory(ls);
  SetLength(Y,0);
  SetLength(fmatrix, 0);
  fx[0]:= 1;
  n := 0;
  for x in XEnum(TVxmlData(alg).Node) do if x.HasAttribute('EXECUTED') then
   begin
    v := XToVar(x);
    fx[1] := v.RT;
    vTovngk;
    CArray.Add<Double>(y, vngk.DEV.VALUE);
    CArray.Add<Tfuncs>(fmatrix, fx);
    inc(n);
   end;
  if n > 1 then
   begin
    CheckMath(ls, ls.Linear(@y[0], @fmatrix[0, 0], n, 2, info, c, Rep));
    if info <> 1 then raise Exception.Create('Error ILSFitting');
    trr.Delta := c[0];
    if c[1] = 0 then Exit;

   if IsGk then trr.kGK := 1/c[1] else trr.kNGK := 1/c[1];
  //  i :=0;
    for x in XEnum(TVxmlData(alg).Node) do if x.HasAttribute('EXECUTED') then
     begin
      v := XToVar(x);
      vTovngk;
      vngk.CLC.VALUE := (vngk.DEV.VALUE-c[0])/c[1];
      if v.RT>0 then v.DELTA := (vngk.CLC.VALUE - v.RT)*100/v.RT
      else v.DELTA := (vngk.CLC.VALUE - v.RT)*100/5;
      //v.DELTA := PDoubleArray(Rep.errcurve.ptr)[i];
  //    inc(i);
     end;
   end;
end;

class function TXMLScriptMath.AddMetrology(root: Variant; const Title, eu: string; Znd: Double = 0; varTip: Integer = 5): Variant;
 var
  r: IXMLNode;
begin
  r := TVxmlData(root).Node;
  if not CNode.IsData(r) then r := CNode.GetCalc(r);
  if not r.HasAttribute(AT_TIP) then r.Attributes[AT_TIP] := varTip;
  if eu <> '' then r.Attributes[AT_EU] := eu;
  if Title <> '' then r.Attributes[AT_TITLE] := Title;
  if Znd <> 0 then r.Attributes[AT_ZND] := Znd;
  Result := XToVar(r);
end;

class function TXMLScriptMath.AddMetrologyCL(root: Variant; Color: TAlphaColor; Width: Single; Dash: Integer): Variant;
 var
  r: IXMLNode;
begin
  r := TVxmlData(root).Node;
  if not CNode.IsData(r) then r := CNode.GetCalc(r);
  r.Attributes[AT_COLOR] := Color;
  if Width <> 2 then r.Attributes[AT_WIDTH] := Width;
  if Dash <> 0 then r.Attributes[AT_DASH] := Dash;
  Result := XToVar(r);
end;

class function TXMLScriptMath.AddMetrologyFM(root: Variant; Digits, Aqu: Integer): Variant;
 var
  r: IXMLNode;
begin
  r := TVxmlData(root).Node;
  if not CNode.IsData(r) then r := CNode.GetCalc(r);
  r.Attributes[AT_DIGITS] := Digits;
  r.Attributes[AT_AQURICY] := Aqu;
  Result := XToVar(r);
end;

class function TXMLScriptMath.AddMetrologyRG(root: Variant; Lo, Hi: Double): Variant;
 var
  r: IXMLNode;
begin
  r := TVxmlData(root).Node;
  if not CNode.IsData(r) then r := CNode.GetCalc(r);
  r.Attributes[AT_RLO] := Lo;
  r.Attributes[AT_RHI] := Hi;
  r.Attributes[AT_VALUE] := (Hi - Lo)/2;
  Result := XToVar(r);
end;


class procedure TXMLScriptMath.TrrVect3D(root, Inp: Variant; Scale: Integer = 1);
 var
  x,y,z: Double;
  ix,iy,iz, rx,ry,rz, r: IXMLNode;
  m11,m12,m13,m14, m21,m22,m23,m24, m31,m32,m33,m34: Double;
begin
  r := TVxmlData(root).Node;
  rx := TVxmlData(Inp).Node.ChildNodes.FindNode('X');
  ry := TVxmlData(Inp).Node.ChildNodes.FindNode('Y');
  rz := TVxmlData(Inp).Node.ChildNodes.FindNode('Z');

  ix := DevNode(rx);
  iy := DevNode(ry);
  iz := DevNode(rz);

  x := Double(ix.Attributes[AT_VALUE])*Scale;
  y := Double(iy.Attributes[AT_VALUE])*Scale;
  z := Double(iz.Attributes[AT_VALUE])*Scale;
  m11 := Double(r.Attributes['m11']);
  m12 := Double(r.Attributes['m12']);
  m13 := Double(r.Attributes['m13']);
  m14 := Double(r.Attributes['m14']);
  m21 := Double(r.Attributes['m21']);
  m22 := Double(r.Attributes['m22']);
  m23 := Double(r.Attributes['m23']);
  m24 := Double(r.Attributes['m24']);
  m31 := Double(r.Attributes['m31']);
  m32 := Double(r.Attributes['m32']);
  m33 := Double(r.Attributes['m33']);
  m34 := Double(r.Attributes['m34']);

  ix := CalcNode(rx);
  iy := CalcNode(ry);
  iz := CalcNode(rz);

  ix.Attributes[AT_VALUE] := m11*x + m12*y + m13*z + m14;
  iy.Attributes[AT_VALUE] := m21*x + m22*y + m23*z + m24;
  iz.Attributes[AT_VALUE] := m31*x + m32*y + m33*z + m34;
//  ix.Attributes[AT_TIP] := varDouble;
//  iy.Attributes[AT_TIP] := varDouble;
//  iz.Attributes[AT_TIP] := varDouble;
//  x := Double(Inp.X.ROW)*Scale;
//  y := Double(Inp.Y.ROW)*Scale;
//  z := Double(Inp.Z.ROW)*Scale;
//  Inp.X.TRR := 1;//root.m21*x + root.m22*y + root.m23*z + root.m24;
//  Inp.Y.TRR := 1;//root.m21*x + root.m22*y + root.m23*z + root.m24;
//  Inp.Z.TRR := 1;//root.m31*x + root.m32*y + root.m33*z + root.m34;}
end;


class procedure TXMLScriptMath.AddXmlMatrix(root: Variant; Row, col: Integer);
begin
  AddXmlMatrix(TVxmlData(root).Node, Row, col);
end;

class procedure TXMLScriptMath.AddXmlMatrix(root: IXMLNode; Row, col: Integer);
 var
  r, c: Integer;
  mn: string;
begin
  mn := Format('m%dx%d',[Row, col]);
  if Assigned(root.ChildNodes.FindNode(mn)) then Exit;
  root := root.AddChild(mn);
  for r := 1 to Row do for c := 1 to Col do root.Attributes[Format('m%d%d',[r, c])] := 0;
end;

class function TXMLScriptMath.AddXmlPath(root: Variant; const path: string): Variant;
begin
  Result := XToVar(GetXNode(TVxmlData(root).Node, path, True));
end;

class function TXMLScriptMath.XmlPathExists(root: Variant; const path: string): Boolean;
begin
//  TDebug.Log(TVxmlData(root).Node.NodeName);
  Result := Assigned(GetXNode(TVxmlData(root).Node, path, False));
end;

class function TXMLScriptMath.FindXmlRoot(cur: Variant; const Section, root: string; var p: Variant): Boolean;
 var
  r, n: IXMLNode;
begin
  r := TVxmlData(cur).Node;
  while Assigned(r.ParentNode) do r := r.ParentNode;
  Result := FindXmlNode(r, Section, root, n);
  if Result then p := XToVar(n);
end;

class function TXMLScriptMath.GetAzi(Zen, Otk, X, Y, Z: Double): Double;
 var
  os,oc,zs,zc: Double;
  Hx, Hy : Double;
begin
  Zen := DegToRad(Zen);
  Otk := DegToRad(Otk);

  os := Sin(Otk);
  oc := Cos(Otk);
  zs := Sin(Zen);
  zc := Cos(Zen);

  Hx := (x*oc - y*os)*zc + z*zs;
  Hy :=  x*os + y*oc;
//  Hz :=-(x*oc - y*os)*zs + z*zc;

  Result := RadToDeg360(-Arctan2(Hy, Hx));
end;

class procedure TXMLScriptMath.GetH(Azi, Zen, Otk: Double; out X, Y, Z: Double; I, Amp: Double);
 var
  so,co,sz,cz,sa,ca, si, ci: Double;
begin
  Azi := DegToRad(Azi);
  Zen := DegToRad(Zen);
  Otk := DegToRad(Otk);
  I := DegToRad(I);

  so := Sin(Otk);
  co := Cos(Otk);
  sa := Sin(Azi);
  ca := Cos(Azi);
  sz := Sin(Zen);
  cz := Cos(Zen);
  si := Sin(I);
  ci := Cos(I);

  X := (si*( co*cz*ca - so*sa) - ci*co*sz)*Amp;
  Y := (si*(-so*cz*ca - co*sa) + ci*so*sz)*Amp;
  Z := (si*     sz*ca          + ci   *cz)*Amp;
end;

class function TXMLScriptMath.Hypot3D(X, Y, Z: Double): Double;
begin
  X := Abs(X);
  Y := Abs(Y);
  Z := Abs(Z);
  if (X.SpecialType = fsZero) and (Y.SpecialType = fsZero) and (z.SpecialType = fsZero) then Exit(0)
  else if (X<=Z) and (Y<=Z) then Result := Z * Sqrt(1 + Sqr(X/Z)+ Sqr(Y/Z))
  else if (X<=Y) and (Z<=Y) then Result := Y * Sqrt(1 + Sqr(X/Y)+ Sqr(Z/Y))
  else Result := X * Sqrt(1 + Sqr(Z/X)+ Sqr(Y/X))
end;

class function TXMLScriptMath.RadToDeg180(Rad: Double): Double;
begin
  Result := DegNormalize(RadToDeg(Rad));
end;

class function TXMLScriptMath.RadToDeg360(Rad: Double): Double;
begin
  Result := DegNormalize(RadToDeg(Rad));
end;

class function TXMLScriptMath.RbfInterp(xy: Variant; x1, x2: Double): Double;
 var
  r: IXMLNode;
  oi: IOwnIntfXMLNode;
  rbf: IRbf;
  res: PRbfReport;
begin
  r := TVxmlData(xy).Node;
  if not Supports(r, IOwnIntfXMLNode, oi) then raise EBaseException.Create('Not Supports IOwnIntfXMLNode');
  if not Assigned(oi.Intf) then
   begin
    RbfFactory(rbf);
    oi.Intf := IInterface(rbf);
    rbf.Create(2,1);
    CheckMath(rbf, rbf.Points(PAnsiChar(AnsiString(r.Attributes['XY']))));
    CheckMath(rbf, rbf.Build(res));
   end;
  rbf := IRbf(oi.Intf);
  CheckMath(rbf, rbf.Calc2(x1,x2, Result));
end;

class procedure TXMLScriptMath.SGK_FindGK(root: variant);
 var
  s,d: string;
  Sm : Integer;
begin
  s := root.СГК.DEV.VALUE;
  sm := 0;
  for d in s.Split([' '], ExcludeEmpty) do sm := sm + d.ToInteger;
  root.гк.DEV.VALUE := Sm;
end;

class procedure TXMLScriptMath.ImportNNK10(const TrrFile: string; NewTrr: Variant);
 var
  ss: TStrings;
  i: Integer;
//  s: string;
  root, dev: IXMLNode;
  sp: TArray<string>;
  procedure UpdatePoint(d, kp, k1, k2, gk: Double);
    var
     skp: string;
     n: IXMLNode;
  begin
    if kp = 100 then skp := 'Вода' else skp := FloatToStr(kp);
    for n in XEnum(root) do if (n.Attributes['KP'] = skp) and (n.Attributes['D'] = d) then
     begin
      n.Attributes['EXECUTED'] := True;
      DevNode(n.ChildNodes['нк1']).Attributes[AT_VALUE] := k1;
      DevNode(n.ChildNodes['нк2']).Attributes[AT_VALUE] := k2;
      DevNode(n.ChildNodes['нгк']).Attributes[AT_VALUE] := gk;
      Break;
     end;
  end;
{  function Next(): Double ;
  begin
    if pos(' ', s) >0  then
     begin
      Result := StrToFloat(Copy(s, 1, pos(' ', s)));
      Delete(s, 1, pos(' ', s));
      s := Trim(s);
     end
    else Result := StrToFloat(s);
  end;}
begin
  root := TVxmlData(NewTrr).Node;
  dev := root.ParentNode.ParentNode.ParentNode;
 // TDebug.Log(root.NodeName);
  ss := TStringList.Create();
  try
   ss.LoadFromFile(TrrFile);
   if ss.Count <> 17 then raise EBaseException.Createfmt('У файла %s %d (17)строк', [TrrFile, ss.Count]);
   dev.Attributes[AT_SERIAL] := Trim(Copy(ss[0],5 ,3));
   root.Attributes[AT_TIMEATT] := Trim(Copy(ss[1],1 , 12));
   root.Attributes['ISTOCHNIK'] := Trim(Copy(ss[2],1 , pos('Источник', ss[2])-1));
   for i := 1 to 13 do
    begin
     sp := ss[i+3].Trim.split([' '], ExcludeEmpty);
     UpdatePoint(sp[0].ToDouble, sp[1].ToDouble, sp[2].ToDouble, sp[3].ToDouble, sp[4].ToDouble);
    end;
{    begin
     s := Trim(ss[i+3]);
     UpdatePoint(Next(), Next(), Next(), Next(), Next());
    end;}
  finally
   ss.Free;
  end;
end;


{type
  IShepard  = interface
    function Calc(vx: Variant): Double;
  end;

  TShepard = class(TInterfacedObject, IShepard)
    z: IDWInterpolant;
    function Calc(vx: Variant): Double;
    class function Get(root: Variant): IShepard;
//    destructor Destroy; override;
  end;

//destructor TShepard.Destroy;
//begin
//  TDebug.Log('========= TShepard.Destroy ===============');
//  inherited;
//end;

class function TShepard.Get(root: Variant): IShepard;
 const
  QUADRATIC_MODEL = 2;
  LINEAR_MODEL = 1;
  NQ = 1;
  NW = 1;
 var
  xy: TReal2DArray;
  n, nx: Integer;
  i,j: Integer;
  r: IXMLNode;
begin
  r := TVxml.TVxmlData(root).Node;
  Result := TShepard.Create;
  n := r.ChildNodes.Count;
  nx := r.ChildNodes[0].AttributeNodes.Count;
  SetLength(xy, n, nx);
  for i := 0 to n-1 do
   for j := 0 to nx-1 do
    xy[i,j] := Double(r.ChildNodes[i].AttributeNodes[j].NodeValue);
  with TShepard(Result) do IDWBuildModifiedShepard(xy, n, nx-1, 2, NQ, NW, z);
//  with TShepard(Result) do IDWBuildNoisy(xy, n, nx-1, 2, NQ, NW, z);
//  with TShepard(Result) do IDWBuildModifiedShepardR(xy, n, nx-1, 0.1, z);
end;

function TShepard.Calc(vx: Variant): Double;
 var
  x: TReal1DArray;
  h, i: Integer;
begin
  h := VarArrayHighBound(vx, 1);
  SetLength(x, h + 1);
  for i := 0 to h do x[i] := Double(vx[i]); // DynArrayFromVariant
  Result := IDWCalc(z, x);
end;

class function TXmlScript.IDWInterp(data, point: Variant): Double;
 var
  r, oi: IXMLNode;
begin
  r := TVxml.TVxmlData(data).Node;
  oi := r.ParentNode.ChildNodes.FindNode(r.NodeName + '_ISHEPARD');
  if not Assigned(oi) then
   begin
    oi := TOwnIntfXMLNode.GetIOwnIntf(r.ParentNode, r.NodeName + '_ISHEPARD');
    (oi as IOwnIntfXMLNode).Intf := TShepard.Get(data) as IInterface;
   end;
  Result := ((oi as IOwnIntfXMLNode).Intf as IShepard).Calc(point);
end;   }
end.

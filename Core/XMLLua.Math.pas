unit XMLLua.Math;

interface

uses
  XMLLua, tools, debug_except, MathIntf, System.UITypes,System.DateUtils, VerySimple.Lua.Lib,  Vector,
  Container, ExtendIntf, SysUtils, Xml.XMLIntf, System.Generics.Collections,
  System.Classes, math, System.Variants, TrrInclin.Temp.PolyModel;

 {$M+}

type
  TXMLScriptMath = class
  private
    class constructor Create;
    class destructor Destroy;
    class var
      NoneLinearLSCB: string;
    class var
      NoneLinearLSN: integer;
    class var
      NoneLinearLSM: integer;
    class var
      NoneLinearLSK: integer;
    class var
      NoneLinearLSLua: lua_State;
    class procedure cbNoneLinearLSFit(const c, x: PDoubleArray; out f: Double); cdecl; static;
  public
//    class function CallMeth(Instance: TObject; ClassType: TClass; const MethodName: String; var Params: Variant): Variant;
//    class procedure ExecStepGK1_t(stp: integer; alg, trr: IXMLNode; IsGk: boolean); static;

  //  class function AddMetrology(root: Variant; const Title, eu: string; Znd: Double = 0; varTip: Integer = 5): Variant; static;
//    class function AddMetrologyFM(root: Variant; Digits, Aqu: Integer): Variant; static;
//    class function AddMetrologyRG(root: Variant; Lo, Hi: Double): Variant; static;
//    class function AddMetrologyCL(root: Variant; Color: TAlphaColor; Width: Single = 2; Dash: Integer = 1): Variant; static;

    class procedure TrrVect3D3T(t, v: IXMLNode; const path: string; var x, y, z: Double; Scale: Integer = 1; TrrAngle: Boolean = True); overload; static;
    class procedure TrrVectAll3D4T(trr, v: IXMLNode; var ax,ay,az, x, y, z: Double; Scale: Integer = 1; TrrAngle: Boolean = True); overload; static;
    class function SenseToKoefs(sns: IXMLNode): TArray<Double>;
    class procedure TrrVectPoly(trr, v: IXMLNode; var ax,ay,az, x, y, z: Double; ScaleA: Double = 1; ScaleH: Double = 1); overload; static;
    class procedure TrrVect3D(r, Inp: IXMLNode; var x: Double; var y: Double; var z: Double; Scale: Integer = 1; xyzInVar: Boolean = false); overload; static;
//    class procedure AddXmlMatrix(root: IXMLNode; Row, col: Integer); overload; static;
//    class function AddXmlPath(root: Variant; const path: string): Variant; static;
//    class function FindXmlRoot(cur: Variant; const Section, root: string; var p: Variant): Boolean; static;
    class function Hypot3D(X, Y, Z: Double): Double; overload; static;
    class procedure GetH(Azi, Zen, Otk: Double; out X, Y, Z: Double; I: Double = 19.2; Amp: Double = 1000); static;
    class procedure GetHExt(Azi, Zen, Otk: Double; out Xh, Yh, Zh, Xa, Ya, Za: Double; I: Double = 19.2; Amp: Double = 1000); static;
    class function GetAzi(Zen, Otk, X, Y, Z: Double): Double; static;
//    class procedure ImportNNK10(const TrrFile: string; NewTrr: Variant); static;
//    class procedure SGK_FindGK(root: variant); static;
//    class function RadToDeg180(Rad: Double): Double; static;
//    class function RadToDeg360(Rad: Double): Double; static;
    class function RbfInterp(xy: variant; x1, x2: Double): Double; overload; static;
//    class function XmlPathExists(root: Variant; const path: string): Boolean; static;
    class function AddMetrology(r: IXMLNode; const Title, eu: string; Znd: Double = 0; varTip: Integer = 5): IXMLNode; overload; static;
    class function AddMetrologyFM(r: IXMLNode; Digits, Aqu: Integer): IXMLNode; overload; static;
    class function AddMetrologyRG(r: IXMLNode; Lo, Hi: Double): IXMLNode; overload; static;
    class function AddMetrologyCL(r: IXMLNode; Color: TAlphaColor; Width: Single = 2; Dash: Integer = 1): IXMLNode; overload; static;
    class function AddXmlPath(root: IXMLNode; const path: string): IXMLNode; overload; static;
    class function AddXmlPath(root: Variant; const path: string): Variant; overload; static;
    class function RadToDeg360(r: Double): Double; overload; static;
    class function AddPolyTrr(root: IXMLNode; const ModelA,ModelH: string; CreateOnly: Boolean): IXMLNode; overload; static;
  published
    class function ExecStepGK1(L: lua_State): Integer; cdecl; static;
    class function AddMetrology(L: lua_State): Integer; overload; cdecl; static;
    class function AddMetrologyFM(L: lua_State): Integer; overload; cdecl; static;
    class function AddMetrologyRG(L: lua_State): Integer; overload; cdecl; static;
    class function AddMetrologyCL(L: lua_State): Integer; overload; cdecl; static;
    class function TrrVect3D(L: lua_State): Integer; overload; cdecl; static;
    class function TrrVect3D3T(L: lua_State): Integer; overload; cdecl; static;
    class function TrrVectAll3D4T(L: lua_State): Integer; overload; cdecl; static;
    class function TrrVectPoly(L: lua_State): Integer; overload; cdecl; static;
    class function AddXmlMatrix(L: lua_State): Integer; cdecl; static;
    class function Add4PolTrr(L: lua_State): Integer; cdecl; static;
    class function AddPolyTrr(L: lua_State): Integer; overload; cdecl; static;
    class function SetIfNotExist(L: lua_State): Integer; cdecl; static;
    class function AddXmlPath(L: lua_State): Integer; overload; cdecl; static;
    class function HasXmlPath(L: lua_State): Integer; cdecl; static;
    class function FindXmlRoot(L: lua_State): Integer; cdecl; static;
    class function DebugLog(L: lua_State): Integer; cdecl; static;

    class function GetProjectOption(L: lua_State): Integer; cdecl; static;
    class function SetProjectOption(L: lua_State): Integer; cdecl; static;

    class function ArcTan2(L: lua_State): Integer; cdecl; static;
    class function KadrToStr(L: lua_State): Integer; cdecl; static;
    class function UtmToStr(L: lua_State): Integer; cdecl; static;
    class function NtToStr(L: lua_State): Integer; cdecl; static;
    class function Hypot(L: lua_State): Integer; cdecl; static;
    class function Hypot3D(L: lua_State): Integer; overload; cdecl; static;
    class function RadToDeg(L: lua_State): Integer; cdecl; static;
    class function RadToDeg180(L: lua_State): Integer; cdecl; static;
    class function RadToDeg360(L: lua_State): Integer; overload; cdecl; static;
    class function Arccos(L: lua_State): Integer; cdecl; static;
    class function Now(L: lua_State): Integer; cdecl; static;
//    class function VarAsType(L: lua_State): Integer; cdecl; static;
    class function RbfInterp(L: lua_State): Integer; overload; cdecl; static;
    class function PolyAprox(L: lua_State): Integer; cdecl; static;
    class function LinearLS(L: lua_State): Integer; cdecl; static;
    class function NoneLinearLSFit(L: lua_State): Integer; cdecl; static;
    class function XmlPathExists(L: lua_State): Integer; cdecl; static;
    class function SGK_FindGK(L: lua_State): Integer; cdecl; static;
    class function ImportNNK10(L: lua_State): Integer; cdecl; static;
  end;

  TXMLLuaBKS = class
  private
    type
      TCurrentArray = array[0..7] of Double;

      TBKSPoint = record
        Current: TCurrentArray;
        Vizir: Double;
      end;
    const
      FZOND: TCurrentArray = (0, pi / 4, pi / 2, 3 * pi / 4, pi, 5 * pi / 4, 6 * pi / 4, 7 * pi / 4);
    class var
      CurY: TBKSPoint;
    class var
      X0: array[0..2] of Double;
    class var
      X0L: array[0..2] of Double;
    class var
      X0U: array[0..2] of Double;
    class procedure cb_Bks_func(const x, f: PDoubleArray); cdecl; static;
    class procedure cb_Bks_jac(const x, f: PDoubleArray; const jac: PMatrix); cdecl; static;
  public
    class procedure FindBKS(focus: IXMLNode; otk: Double; XOut: PDoubleArray); overload; static;
  published
    class function FindBKS(L: lua_State): Integer; overload; cdecl; static;
  end;

implementation

class constructor TXMLScriptMath.Create;
begin
  TXMLLua.RegisterLuaMethods(TXMLScriptMath);
  TXMLLua.RegisterLuaMethods(TXMLLuaBKS);
  TXMLLuaBKS.X0[1] := 0;
  TXMLLuaBKS.X0L[0] := 0;
  TXMLLuaBKS.X0L[1] := -pi;
  TXMLLuaBKS.X0L[2] := 0;
  TXMLLuaBKS.X0U[0] := 10000;
  TXMLLuaBKS.X0U[1] := pi;
  TXMLLuaBKS.X0U[2] := 10000;
end;

class function TXMLScriptMath.DebugLog(L: lua_State): Integer;
var
  i: integer;
  dat: string;
begin
  dat := '';
  for i := 2 to Lua_GetTop(L) do
    dat := dat + ', ' + string(lua_tostring(L, i));
  if Assigned(TDebug.ExeptionEvent) then
    TDebug.ExeptionEvent(string(lua_tostring(L, 1)), dat, '');
  Result := 0;
end;

class destructor TXMLScriptMath.Destroy;
begin
//  TXmlScriptInner.UnRegisterMethods(CallMeth);
end;

class function TXMLScriptMath.ExecStepGK1(L: lua_State): Integer;
var
  //stp: integer;
  alg, trr: IXMLNode;
  IsGk: boolean;
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
    if IsGk then
      vngk := v.гк
    else
      vngk := v.нгк
  end;

begin
  //stp := lua_tointeger(L,1);
  alg := TXMLLua.XNode(L, 2);
  trr := TXMLLua.XNode(L, 3);
  IsGk := Boolean(lua_toboolean(L, 4));

  LSFittingFactory(ls);
  SetLength(y, 0);
  SetLength(fmatrix, 0);
  fx[0] := 1;
  n := 0;
  for x in XEnum(alg) do
    if x.HasAttribute('EXECUTED') then
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
    if info <> 1 then
      raise Exception.Create('Error ILSFitting');
    trr.Attributes['Delta'] := c[0];
    if c[1] = 0 then
      Exit(0);

    if IsGk then
      trr.Attributes['kGK'] := 1 / c[1]
    else
      trr.Attributes['kNGK'] := 1 / c[1];
  //  i :=0;
    for x in XEnum(alg) do
      if x.HasAttribute('EXECUTED') then
      begin
        v := XToVar(x);
        vTovngk;
        vngk.CLC.VALUE := (vngk.DEV.VALUE - c[0]) / c[1];
        if v.RT > 0 then
          v.DELTA := (vngk.CLC.VALUE - v.RT) * 100 / v.RT
        else
          v.DELTA := (vngk.CLC.VALUE - v.RT) * 100 / 5;
      //v.DELTA := PDoubleArray(Rep.errcurve.ptr)[i];
  //    inc(i);
      end;
  end;
  Result := 0;
end;


class function TXMLScriptMath.AddMetrology(L: lua_State): Integer;
var
  Title, eu: string;
  Znd: Double; // = 0;
  varTip: Integer; // = 5
  r: IXMLNode;
  ArgCount: integer;
begin
  ArgCount := Lua_GetTop(L);
  r := TXMLLua.XNode(L, 1);
  Title := string(lua_tostring(L, 2));
  eu := string(lua_tostring(L, 3));
  Znd := lua_tonumber(L, 4);
  if ArgCount >= 5 then
    varTip := lua_tointeger(L, 5)
  else
    varTip := 5;

  if not CNode.IsData(r) then
    r := CNode.GetCalc(r);
  if not r.HasAttribute(AT_TIP) then
    r.Attributes[AT_TIP] := varTip;
  if eu <> '' then
    r.Attributes[AT_EU] := eu;
  if Title <> '' then
    r.Attributes[AT_TITLE] := Title;
  if Znd <> 0 then
    r.Attributes[AT_ZND] := Znd;

  TXMLLua.PushXmlToTable(L, r);
  Result := 1;
end;

class function TXMLScriptMath.AddMetrology(r: IXMLNode; const Title, eu: string; Znd: Double; varTip: Integer): IXMLNode;
begin
  if not CNode.IsData(r) then
    r := CNode.GetCalc(r);
  if not r.HasAttribute(AT_TIP) then
    r.Attributes[AT_TIP] := varTip;
  if eu <> '' then
    r.Attributes[AT_EU] := eu;
  if Title <> '' then
    r.Attributes[AT_TITLE] := Title;
  if Znd <> 0 then
    r.Attributes[AT_ZND] := Znd;
  Result := r;
end;

class function TXMLScriptMath.AddMetrologyCL(L: lua_State): Integer;
var
  Color: TAlphaColor;
  Width: Single;
  Dash: Integer;
  r: IXMLNode;
  ArgCount: integer;
//  Width: Single = 2; Dash: Integer = 1
begin
  ArgCount := Lua_GetTop(L);
  r := TXMLLua.XNode(L, 1);
  Color := lua_tointeger(L, 2);
  if ArgCount >= 3 then
    Width := lua_tonumber(L, 3)
  else
    Width := 1;
  if ArgCount >= 4 then
    Dash := lua_tointeger(L, 4)
  else
    Dash := 0;

  if not CNode.IsData(r) then
    r := CNode.GetCalc(r);
  r.Attributes[AT_COLOR] := Color;
  r.Attributes[AT_WIDTH] := Width;
  r.Attributes[AT_DASH] := Dash;

  TXMLLua.PushXmlToTable(L, r);
  Result := 1;
end;

class function TXMLScriptMath.AddMetrologyCL(r: IXMLNode; Color: TAlphaColor; Width: Single; Dash: Integer): IXMLNode;
begin
  if not CNode.IsData(r) then
    r := CNode.GetCalc(r);
  r.Attributes[AT_COLOR] := Color;
  r.Attributes[AT_WIDTH] := Width;
  r.Attributes[AT_DASH] := Dash;
  Result := r;
end;

class function TXMLScriptMath.AddMetrologyFM(r: IXMLNode; Digits, Aqu: Integer): IXMLNode;
begin
  if not CNode.IsData(r) then
    r := CNode.GetCalc(r);
  r.Attributes[AT_DIGITS] := Digits;
  r.Attributes[AT_AQURICY] := Aqu;
  Result := r;
end;

class function TXMLScriptMath.AddMetrologyFM(L: lua_State): Integer;
var
  r: IXMLNode;
  Digits, Aqu: Integer;
begin
  r := TXMLLua.XNode(L, 1);
  Digits := lua_tointeger(L, 2);
  Aqu := lua_tointeger(L, 3);

  if not CNode.IsData(r) then
    r := CNode.GetCalc(r);
  r.Attributes[AT_DIGITS] := Digits;
  r.Attributes[AT_AQURICY] := Aqu;

  TXMLLua.PushXmlToTable(L, r);
  Result := 1;
end;

class function TXMLScriptMath.AddMetrologyRG(r: IXMLNode; Lo, Hi: Double): IXMLNode;
begin
  if not CNode.IsData(r) then
    r := CNode.GetCalc(r);
  r.Attributes[AT_RLO] := Lo;
  r.Attributes[AT_RHI] := Hi;
  r.Attributes[AT_VALUE] := (Hi - Lo) / 2;
  Result := r;
end;

class function TXMLScriptMath.AddMetrologyRG(L: lua_State): Integer;
var
  Lo, Hi: Double;
  r: IXMLNode;
begin
  r := TXMLLua.XNode(L, 1);
  Lo := lua_tonumber(L, 2);
  Hi := lua_tonumber(L, 3);

  if not CNode.IsData(r) then
    r := CNode.GetCalc(r);
  r.Attributes[AT_RLO] := Lo;
  r.Attributes[AT_RHI] := Hi;
  r.Attributes[AT_VALUE] := (Hi - Lo) / 2;

  TXMLLua.PushXmlToTable(L, r);
  Result := 1;
end;

class function TXMLScriptMath.AddPolyTrr(root: IXMLNode; const ModelA, ModelH: string; CreateOnly: Boolean): IXMLNode;
 const
  xyz = ['X','Y','Z'];
  function SetAx(ax: AnsiChar; m: PolyModel): string;
   var
    k: TArray<string>;
  begin
    SetLength(k, m.KoeffCnt);
    for var i := 0 to High(k) do k[i] := '0';
    case ax of
     'X': k[0] := '1';
     'Y': k[m.KuCnt] := '1';
     'Z': k[m.KuCnt*2] := '1';
    end;
    Result := string.join(' ',k);
  end;
  procedure SetSence(r: IXMLNode; const sense, model: string);
  begin
    var sns := GetXNode(r, sense, true);
    sns.Attributes['Model'] := model.Replace(',',' ');
    for var ax in xyz do
    sns.Attributes[ax] := SetAx(ax, model);
  end;
begin
  if CreateOnly and Assigned(root.ChildNodes.FindNode('Poly')) then Exit;
  Result := GetXNode(root,'Poly', true);
  SetSence(Result,'accel', ModelA);
  SetSence(Result,'magnit',ModelH);
end;

class function TXMLScriptMath.AddPolyTrr(L: lua_State): Integer;
 var
  ma, mh: string;
  root: IXMLNode;
  c: Boolean;
begin
  root := TXMLLua.XNode(L, 1);
  ma := string(lua_tostring(L, 2));
  mh := string(lua_tostring(L, 3));
  c := Boolean(lua_toboolean(L,4));

  TXMLLua.PushXmlToTable(L, AddPolyTrr(root, ma, mh,c));
  Result := 1;
end;

class procedure TXMLScriptMath.TrrVect3D(r, Inp: IXMLNode; var x: Double; var y: Double; var z: Double; Scale: Integer = 1; xyzInVar: Boolean = false);
var
  tx, ty, tz: Double;
  ix, iy, iz, rx, ry, rz: IXMLNode;
  m11, m12, m13, m14, m21, m22, m23, m24, m31, m32, m33, m34: Double;
begin

  //r.OwnerDocument.SaveToFile('e:\inclMetr.xml');

  rx := Inp.ChildNodes.FindNode('X');
  ry := Inp.ChildNodes.FindNode('Y');
  rz := Inp.ChildNodes.FindNode('Z');

  ix := DevNode(rx);
  iy := DevNode(ry);
  iz := DevNode(rz);

  if xyzInVar then
  begin
    tx := x;
    ty := y;
    tz := z;
  end
  else
  begin
    tx := Double(ix.Attributes[AT_VALUE]); // *Scale; НЕВЕРНО !!! т.к. m*X + m*Y + m*Z + d =tX  d- осталось без масштабирования
    ty := Double(iy.Attributes[AT_VALUE]); // *Scale;
    tz := Double(iz.Attributes[AT_VALUE]); // *Scale;
  end;

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

  x := m11 * tx + m12 * ty + m13 * tz + m14;
  y := m21 * tx + m22 * ty + m23 * tz + m24;
  z := m31 * tx + m32 * ty + m33 * tz + m34;
  ix.Attributes[AT_VALUE] := x * Scale; // *Scale; ВЕРНО !!!
  iy.Attributes[AT_VALUE] := y * Scale;
  iz.Attributes[AT_VALUE] := z * Scale;
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

class function TXMLScriptMath.TrrVect3D(L: lua_State): Integer;
var
  x, y, z: Double;
  r, Inp: IXMLNode;
  Scale: Integer;
//  m11,m12,m13,m14, m21,m22,m23,m24, m31,m32,m33,m34: Double;
  ArgCount: integer;
begin
  ArgCount := Lua_GetTop(L);
  r := TXMLLua.XNode(L, 1);
  Inp := TXMLLua.XNode(L, 2);
  if ArgCount >= 3 then
    Scale := lua_tointeger(L, 3)
  else
    Scale := 1;

  TrrVect3D(r, Inp, x, y, z, Scale);

  lua_pushnumber(L, x);
  lua_pushnumber(L, y);
  lua_pushnumber(L, z);

  Result := 3;

{  rx := Inp.ChildNodes.FindNode('X');
  ry := Inp.ChildNodes.FindNode('Y');
  rz := Inp.ChildNodes.FindNode('Z');

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

class procedure TXMLScriptMath.TrrVect3D3T(t, v: IXMLNode; const path: string; var x, y, z: Double; Scale: Integer; TrrAngle: Boolean);
var
  temp, tx, ty, tz: Double;
  ix, iy, iz, rx, ry, rz, r, Inp: IXMLNode;
  atxOld, atx, dtx: Double;
  atyOld, aty, dty: Double;
  atzOld, atz, dtz: Double;
  dt0x, dt0y, dt0z: Double;
begin

  //r.OwnerDocument.SaveToFile('e:\inclMetr.xml');
  var nodeT := GetXNode(v, 'T.DEV');
  var troot := t.ChildNodes.FindNode('T');
  if Assigned(nodeT) and Assigned(troot) then
  begin
    temp := Double(nodeT.Attributes[AT_VALUE]);
    for var ti in Xenum(troot) do
    begin
      var t0 := Double(ti.Attributes['t0']);
      var t1 := Double(ti.Attributes['t1']);
      if temp < t1 then
      begin
        var tp := ti.ChildNodes.FindNode(path);
        var vp := v.ChildNodes.FindNode(path);

        rx := vp.ChildNodes.FindNode('X');
        ry := vp.ChildNodes.FindNode('Y');
        rz := vp.ChildNodes.FindNode('Z');

        ix := DevNode(rx);
        iy := DevNode(ry);
        iz := DevNode(rz);

        tx := Double(ix.Attributes[AT_VALUE]);
        ty := Double(iy.Attributes[AT_VALUE]);
        tz := Double(iz.Attributes[AT_VALUE]);

        rx := tp.ChildNodes.FindNode('X');
        ry := tp.ChildNodes.FindNode('Y');
        rz := tp.ChildNodes.FindNode('Z');

        atxOld := Double(rx.Attributes['kOld']);
        atx := Double(rx.Attributes['k']);
        dtx := Double(rx.Attributes['d']);
        dt0x := Double(rx.Attributes['d0']);
        atyOld := Double(rx.Attributes['kOld']);
        aty := Double(ry.Attributes['k']);
        dty := Double(ry.Attributes['d']);
        dt0y := Double(ry.Attributes['d0']);
        atzOld := Double(rx.Attributes['kOld']);
        atz := Double(rz.Attributes['k']);
        dtz := Double(rz.Attributes['d']);
        dt0z := Double(rz.Attributes['d0']);

        var tc := temp - t0;

  //      x := tx + tc*(atx*tx + dtx);
  //      y := ty + tc*(aty*ty + dty);
  //      z := tz + tc*(atz*tz + dtz);
        x := (tx + dt0x + tc * dtx) * atxOld * (1 + atx * tc);
        y := (ty + dt0y + tc * dty) * atyOld * (1 + aty * tc);
        z := (tz + dt0z + tc * dtz) * atzOld * (1 + atz * tc);

        Break;
      end;
    end;
  end
  else
  begin
    var vp := v.ChildNodes.FindNode(path);

    rx := vp.ChildNodes.FindNode('X');
    ry := vp.ChildNodes.FindNode('Y');
    rz := vp.ChildNodes.FindNode('Z');

    ix := DevNode(rx);
    iy := DevNode(ry);
    iz := DevNode(rz);

    x := Double(ix.Attributes[AT_VALUE]);
    y := Double(iy.Attributes[AT_VALUE]);
    z := Double(iz.Attributes[AT_VALUE]);
  end;
  if TrrAngle then
  begin
    r := t.ChildNodes.FindNode(path).ChildNodes.FindNode('m3x4');
    Inp := v.ChildNodes.FindNode(path);
    TrrVect3D(r, Inp, x, y, z, Scale, True);
  end;
end;

class function TXMLScriptMath.TrrVect3D3T(L: lua_State): Integer;
var
  x, y, z: Double;
  rt, t, r, Inp: IXMLNode;
  Scale: Integer;
  ArgCount: integer;
  path: string;
begin
  ArgCount := Lua_GetTop(L);
  rt := TXMLLua.XNode(L, 1);
  t := TXMLLua.XNode(L, 2);
  path := string(lua_tostring(L, 3));

  if ArgCount >= 4 then
    Scale := lua_tointeger(L, 4)
  else
    Scale := 1;

  TrrVect3D3T(rt, t, path, x, y, z, Scale);

  lua_pushnumber(L, x);
  lua_pushnumber(L, y);
  lua_pushnumber(L, z);

  Result := 3;
end;

function TrrAxis(axies, tpower, k: TArray<Double>): Double;
begin
  Result := 0;
  var i := 0;
    for var a in axies do
      for var t in tpower do
       begin
        Result := Result + a*t*k[i];
        Inc(i);
       end;
end;

class function TXMLScriptMath.SenseToKoefs(sns: IXMLNode): TArray<Double>;
begin
    var ksa := string(sns.Attributes['X']+' '+sns.Attributes['Y']+' '+sns.Attributes['Z']).Split([' ']);
    Result := [];
    for var sk in ksa do Result := Result +[sk.ToDouble];
end;

class procedure TXMLScriptMath.TrrVectPoly(trr, v: IXMLNode; var ax, ay, az, x, y, z: Double; ScaleA: Double = 1; ScaleH: Double = 1);

 var
  at: TArray<Double>;

  procedure RunTrr(sence: IXMLNode; k: TArray<Double>; pm: PolyModel; var rx, ry, rz: Double; Scale: Double; coso: boolean);
  begin
    var vs := XToVar(sence);
    var r := pm.CreateRow(at,[vs.X.DEV.VALUE,vs.Y.DEV.VALUE,vs.Z.DEV.VALUE], Scale);
    if coso then pm.FindAxisKoso(@k[0], r, rx, ry, rz)
    else pm.FindAxis(@k[0], r, rx, ry, rz);
  end;

 var
  pmA, pmH: PolyModel;
begin
  var d := XToVar(v);
  var acc := GetXNode(trr, 'Poly.accel');
  var mag := GetXNode(trr, 'Poly.magnit');

  pma :=  acc.Attributes['Model'];
  pmh :=  mag.Attributes['Model'];

  var pwt := pmH.MaxPowT; if pmA.MaxPowT > pwt then pwt := pmA.MaxPowT;
  at := pmA.CreatePowerT(d.T.DEV.VALUE, pwt);

  var sens := GetXNode(v, 'accel');
  var ak := SenseToKoefs(acc);
  var coso := ak[pma.KyIdx] = 0;
  RunTrr(sens, ak, pmA, ax, ay, az, ScaleA, coso);

  var vs := XtoVar(sens);
  TXMLScriptMath.AddXmlPath(vs.X,'CLC').VALUE := ax;
  TXMLScriptMath.AddXmlPath(vs.Y,'CLC').VALUE := ay;
  TXMLScriptMath.AddXmlPath(vs.Z,'CLC').VALUE := az;

  sens := GetXNode(v, 'magnit');
  ak := SenseToKoefs(mag);
  RunTrr(sens,ak,pmH, x,  y,  z, ScaleH, coso);

  vs := XtoVar(sens);
  TXMLScriptMath.AddXmlPath(vs.X,'CLC').VALUE := x;
  TXMLScriptMath.AddXmlPath(vs.Y,'CLC').VALUE := y;
  TXMLScriptMath.AddXmlPath(vs.Z,'CLC').VALUE := z;

end;

class procedure TXMLScriptMath.TrrVectAll3D4T(trr, v: IXMLNode; var ax, ay, az, x, y, z: Double; Scale: Integer;
  TrrAngle: Boolean);
  var
   t,t2,t3: Double;
   ix,iy,iz: Double;
  function SetA(atRow: Variant): Double;
  begin
    Result := ix*(atRow.k1 + atRow.k2*t +  atRow.k3*t2 +  atRow.k4*t3) +
              iy*(atRow.k5 + atRow.k6*t +  atRow.k7*t2 +  atRow.k8*t3) +
              iz*(atRow.k9 + atRow.k10*t + atRow.k11*t2 + atRow.k12*t3) +
                 atRow.k13 + atRow.k14*t + atRow.k15*t2 + atRow.k16*t3
  end;
begin
   var d := XToVar(v);
   var dt := XToVar(trr);

   t := ((d.T.DEV.VALUE) - 25)/100;
   t2 := t*t;
   t3 := t2*t;

   ix := d.accel.X.DEV.VALUE;
   iy := d.accel.Y.DEV.VALUE;
   iz := d.accel.Z.DEV.VALUE;
   ax := SetA(dt.accel.X);
   ay := SetA(dt.accel.Y);
   az := SetA(dt.accel.Z);
   TXMLScriptMath.AddXmlPath(d.accel.X,'CLC').VALUE := ax;
   TXMLScriptMath.AddXmlPath(d.accel.Y,'CLC').VALUE := ay;
   TXMLScriptMath.AddXmlPath(d.accel.Z,'CLC').VALUE := az;
//   d.accel.X.CLC.VALUE := ax;
//   d.accel.Y.CLC.VALUE := ay;
//   d.accel.Z.CLC.VALUE := az;

   ix := d.magnit.X.DEV.VALUE;
   iy := d.magnit.Y.DEV.VALUE;
   iz := d.magnit.Z.DEV.VALUE;
   x := SetA(dt.magnit.X);
   y := SetA(dt.magnit.Y);
   z := SetA(dt.magnit.Z);
   TXMLScriptMath.AddXmlPath(d.magnit.X,'CLC').VALUE := x;
   TXMLScriptMath.AddXmlPath(d.magnit.Y,'CLC').VALUE := y;
   TXMLScriptMath.AddXmlPath(d.magnit.Z,'CLC').VALUE := z;
//   d.magnit.X.CLC.VALUE := x;
//   d.magnit.Y.CLC.VALUE := y;
//   d.magnit.Z.CLC.VALUE := z;

end;

class function TXMLScriptMath.TrrVectAll3D4T(L: lua_State): Integer;
var
  ax, ay, az,x, y, z: Double;
  rt, t, r, Inp: IXMLNode;
  Scale: Integer;
  ArgCount: integer;
  path: string;
begin
  ArgCount := Lua_GetTop(L);
  rt := TXMLLua.XNode(L, 1);
  t := TXMLLua.XNode(L, 2);

  if ArgCount >= 3 then
    Scale := lua_tointeger(L, 3)
  else
    Scale := 1;

  TrrVectAll3D4T(rt, t, ax, ay, az, x, y, z, Scale);

  lua_pushnumber(L, ax);
  lua_pushnumber(L, ay);
  lua_pushnumber(L, az);
  lua_pushnumber(L, x);
  lua_pushnumber(L, y);
  lua_pushnumber(L, z);

  Result := 6;
end;

class function TXMLScriptMath.TrrVectPoly(L: lua_State): Integer;
var
  ax, ay, az,x, y, z: Double;
  rt, t, r, Inp: IXMLNode;
  ScaleA, ScaleH: Integer;
  ArgCount: integer;
  path: string;
begin
  ArgCount := Lua_GetTop(L);
  rt := TXMLLua.XNode(L, 1);
  t := TXMLLua.XNode(L, 2);

  if ArgCount >= 3 then
    ScaleA := lua_tointeger(L, 3)
  else
    ScaleA := 1;
  if ArgCount >= 4 then
    ScaleH := lua_tointeger(L, 4)
  else
    ScaleH := 1;

  TrrVectPoly(rt, t, ax, ay, az, x, y, z, ScaleA, ScaleH);

  lua_pushnumber(L, ax);
  lua_pushnumber(L, ay);
  lua_pushnumber(L, az);
  lua_pushnumber(L, x);
  lua_pushnumber(L, y);
  lua_pushnumber(L, z);

  Result := 6;
end;

class function TXMLScriptMath.Add4PolTrr(L: lua_State): Integer;
var
  r, c: Integer;
  Row, col: Integer;
  mn: string;
  root: IXMLNode;
  const
  XYZ: TArray<Char> = ['X','Y','Z'];
begin
  root := TXMLLua.XNode(L, 1);
  if Assigned(root.ChildNodes.FindNode('Z')) then
  begin
    lua_pushboolean(L, 0);
    Exit(1);
  end;
  for var i := 0 to 2 do
   begin
    var s := root.AddChild(XYZ[i]);
    for var j := 1 to 16 do s.Attributes['k'+j.ToString] := 0;
   end;
  lua_pushboolean(L, 1);
  Result := 1;
end;

class function TXMLScriptMath.AddXmlMatrix(L: lua_State): Integer;
var
  r, c: Integer;
  Row, col: Integer;
  mn: string;
  root: IXMLNode;
begin
  root := TXMLLua.XNode(L, 1);
  Row := lua_tointeger(L, 2);
  col := lua_tointeger(L, 3);
  mn := Format('m%dx%d', [Row, col]);
  if Assigned(root.ChildNodes.FindNode(mn)) then
  begin
    lua_pushboolean(L, 0);
    Exit(1);
  end;
  root := root.AddChild(mn);
  for r := 1 to Row do
    for c := 1 to col do
      root.Attributes[Format('m%d%d', [r, c])] := 0;

  lua_pushboolean(L, 1);
  Result := 1;
end;

class function TXMLScriptMath.AddXmlPath(root: Variant; const path: string): Variant;
begin
  Result := XToVar(GetXNode(TVxmlData(root).Node, path, True));
end;

class function TXMLScriptMath.AddXmlPath(root: IXMLNode; const path: string): IXMLNode;
begin
  Result := GetXNode(root, path, True);
end;

class function TXMLScriptMath.AddXmlPath(L: lua_State): Integer;
var
  root: IXMLNode;
  path: string;
//  ArgCount: Integer;
begin
//  ArgCount := Lua_GetTop(L);

  root := TXMLLua.XNode(L, 1);
  path := string(lua_tostring(L, 2));
  TXMLLua.PushXmlToTable(L, GetXNode(root, path, True));
  Result := 1;
end;

class function TXMLScriptMath.XmlPathExists(L: lua_State): Integer;
var
  root: IXMLNode;
  path: string;
begin
  root := TXMLLua.XNode(L, 1);
  path := string(lua_tostring(L, 2));
//  TDebug.Log(TVxmlData(root).Node.NodeName);
  lua_pushboolean(L, Integer(Assigned(GetXNode(root, path, False))));
  Result := 1;
end;

class function TXMLScriptMath.FindXmlRoot(L: lua_State): Integer;
var
  Section, root: string;
  r, n: IXMLNode;
begin
  r := TXMLLua.XNode(L, 1);
  Section := string(lua_tostring(L, 2));
  root := string(lua_tostring(L, 3));
  Result := 2;
  while Assigned(r.ParentNode) do
  begin
    r := r.ParentNode;
    if r.HasAttribute(AT_ADDR) then
    begin
      r := r.ParentNode;
      break;
    end;
  end;
  lua_pushboolean(L, Integer(FindXmlNode(r, Section, root, n)));
  if Assigned(n) then
    TXMLLua.PushXmlToTable(L, n)
  else
    Result := 1;
end;

class function TXMLScriptMath.GetAzi(Zen, Otk, X, Y, Z: Double): Double;
var
  os, oc, zs, zc: Double;
  Hx, Hy: Double;
begin
  Zen := DegToRad(Zen);
  Otk := DegToRad(Otk);

  os := Sin(Otk);
  oc := Cos(Otk);
  zs := Sin(Zen);
  zc := Cos(Zen);

  Hx := (X * oc - Y * os) * zc + Z * zs;
  Hy := X * os + Y * oc;
//  Hz :=-(x*oc - y*os)*zs + z*zc;

  Result := DegNormalize(Math.RadToDeg(-math.Arctan2(Hy, Hx)));
end;

class procedure TXMLScriptMath.GetH(Azi, Zen, Otk: Double; out X, Y, Z: Double; I, Amp: Double);
var
  so, co, sz, cz, sa, ca, si, ci: Double;
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

  X := (si * (co * cz * ca - so * sa) - ci * co * sz) * Amp;
  Y := (si * (-so * cz * ca - co * sa) + ci * so * sz) * Amp;
  Z := (si * sz * ca + ci * cz) * Amp;
end;

class procedure TXMLScriptMath.GetHExt(Azi, Zen, Otk: Double; out Xh, Yh, Zh, Xa, Ya, Za: Double; I, Amp: Double);
var
  so, co, sz, cz, sa, ca, si, ci: Double;
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

  Xa := -sz * co * Amp;
  Ya := sz * so * Amp;
  Za := cz * Amp;


  Xh := (si * (co * cz * ca - so * sa) - ci * co * sz) * Amp;
  Yh := (si * (-so * cz * ca - co * sa) + ci * so * sz) * Amp;
  Zh := (si * sz * ca + ci * cz) * Amp;
end;

class function TXMLScriptMath.Hypot3D(L: lua_State): Integer;
var
  X, Y, Z, r: Double;
begin
  X := Abs(lua_tonumber(L, 1));
  Y := Abs(lua_tonumber(L, 2));
  Z := Abs(lua_tonumber(L, 3));

  if (X.SpecialType = fsZero) and (Y.SpecialType = fsZero) and (Z.SpecialType = fsZero) then
    r := 0
  else if (X <= Z) and (Y <= Z) then
    r := Z * Sqrt(1 + Sqr(X / Z) + Sqr(Y / Z))
  else if (X <= Y) and (Z <= Y) then
    r := Y * Sqrt(1 + Sqr(X / Y) + Sqr(Z / Y))
  else
    r := X * Sqrt(1 + Sqr(Z / X) + Sqr(Y / X));

  lua_pushnumber(L, r);
  Result := 1;
end;

//class function TXMLScriptMath.VarAsType(L: lua_State): Integer;
//begin
//  lua_pushinteger(System.Variants.VarAsType(
//end;

class function TXMLScriptMath.Arccos(L: lua_State): Integer;
begin
  lua_pushnumber(L, math.ArcCos(lua_tonumber(L, 1)));
  Result := 1;
end;

class function TXMLScriptMath.ArcTan2(L: lua_State): Integer;
begin
  lua_pushnumber(L, math.ArcTan2(lua_tonumber(L, 1), lua_tonumber(L, 2)));
  Result := 1;
end;

class function TXMLScriptMath.Hypot3D(X, Y, Z: Double): Double;
begin
  X := Abs(X);
  Y := Abs(Y);
  Z := Abs(Z);

  if (X.SpecialType = fsZero) and (Y.SpecialType = fsZero) and (Z.SpecialType = fsZero) then
    Result := 0
  else if (X <= Z) and (Y <= Z) then
    Result := Z * Sqrt(1 + Sqr(X / Z) + Sqr(Y / Z))
  else if (X <= Y) and (Z <= Y) then
    Result := Y * Sqrt(1 + Sqr(X / Y) + Sqr(Z / Y))
  else
    Result := X * Sqrt(1 + Sqr(Z / X) + Sqr(Y / X));
end;

class function TXMLScriptMath.HasXmlPath(L: lua_State): Integer;
var
  root: IXMLNode;
  path: string;
//  ArgCount: Integer;
begin
//  ArgCount := Lua_GetTop(L);

  root := TXMLLua.XNode(L, 1);
  path := string(lua_tostring(L, 2));
  lua_pushboolean(L, Integer(Assigned(root.childnodes.FindNode(path))));
  Result := 1;
end;

class function TXMLScriptMath.Hypot(L: lua_State): Integer;
begin
  lua_pushnumber(L, math.Hypot(lua_tonumber(L, 1), lua_tonumber(L, 2)));
  Result := 1;
end;

class function TXMLScriptMath.KadrToStr(L: lua_State): Integer;
var
  m: TMarshaller;
begin
  lua_pushstring(L, m.AsAnsi((CTime.AsString(CTime.FromKadr(lua_tointeger(L, 1))))).ToPointer);
  Result := 1;
end;
                                                    // K  M
class function TXMLScriptMath.UtmToStr(L: lua_State): Integer;
var
  m: TMarshaller;
begin
  lua_pushstring(L, m.AsAnsi(DateTimeToStr(UnixToDateTime(lua_tointeger(L, 1)))).ToPointer);
  Result := 1;
end;


class function TXMLScriptMath.NtToStr(L: lua_State): Integer;
var
  m: TMarshaller;
  function UInt32RTCToDateTime(AnRTC: UInt32): TDateTime;
const
  FramePeriodSec = 2.097152;
  SecInDay       = 86400.0;
  FrameInDays    = FramePeriodSec / SecInDay;
  DateEpoch      = 36526.0; // TDateTime для 01.01.2000
  begin
    Result := DateEpoch + (AnRTC * FrameInDays);
  end;
begin
  lua_pushstring(L, m.AsAnsi(DateTimeToStr(UInt32RTCToDateTime(lua_tointeger(L, 1)))).ToPointer);
  Result := 1;
end;

class procedure TXMLScriptMath.cbNoneLinearLSFit(const c, x: PDoubleArray; out f: Double); cdecl;
begin
  var L := NoneLinearLSLua;
//  var top := lua_gettop(L);
  if not lua_isfunction(L, 13) then
  begin
    raise Exception.Create('if not lua_isfunction(L, 13) then');
  end;
  lua_pushvalue(L, 13);
  lua_createtable(L, NoneLinearLSK, 0);
  for var i := 1 to NoneLinearLSK do
  begin
    lua_pushnumber(L, c[i - 1]);
    lua_rawseti(L, -2, i);
  end;
  lua_createtable(L, NoneLinearLSM, 0);
  for var i := 1 to NoneLinearLSM do
  begin
    lua_pushnumber(L, x[i - 1]);
    lua_rawseti(L, -2, i);
  end;
  lua_call(NoneLinearLSLua, 2, 1);
  f := lua_tonumber(NoneLinearLSLua, -1);
  lua_pop(NoneLinearLSLua, 1);
//  var tope := lua_gettop(L);
//  Tdebug.Log('dtop %d %d', [top,tope]);
//				var del := c[0]*x[0] + c[1];
//				if del = 0 then
//					f := 10000000
//				else
//					F := (x[2] - c[2]*x[1])/del
end;

class function TXMLScriptMath.NoneLinearLSFit(L: lua_State): Integer;
var
  f: ILSFitting;
  s: string;
  x, y, c, bl, bh, cs: TArray<Double>;
  cOut: PDoubleArray;
  n, m, k, info, niter: Integer;
  diffstep, epsx: Double;
  Rep: PSLFittingReport;

  function LoadTable(LuaStack: Integer): TArray<Double>;
  var
    Res: Tarray<Double>;
  begin
    luaL_checktype(L, LuaStack, LUA_TTABLE);
    var n := lua_rawlen(L, LuaStack);
    SetLength(Res, n);
    for var i := 1 to n do
    begin
      lua_rawgeti(L, LuaStack, i);
      Res[i - 1] := lua_tonumber(L, -1);
    end;
    Result := Res;
  end;

begin
//  var top := lua_gettop(L);
  x := LoadTable(1);
  c := LoadTable(2);
  y := LoadTable(3);
  n := lua_tointeger(L, 4);
  m := lua_tointeger(L, 5);
  k := lua_tointeger(L, 6);
  diffstep := lua_tonumber(L, 7);
  epsx := lua_tonumber(L, 8);
  niter := lua_tointeger(L, 9);
  if lua_type(L, 10) <> LUA_TTABLE then
    bl := nil
  else
    bl := LoadTable(10);
  if lua_type(L, 11) <> LUA_TTABLE then
    bh := nil
  else
    bh := LoadTable(11);
  if lua_type(L, 12) <> LUA_TTABLE then
    cs := nil
  else
    cs := LoadTable(12);
  if not lua_isfunction(L, 13) then
  begin
    raise Exception.Create('if not lua_isfunction(L, 13) then');
  end;
  NoneLinearLSCB := s;
  NoneLinearLSLua := L;
  NoneLinearLSN := n;
  NoneLinearLSM := m;
  NoneLinearLSK := k;

  LSFittingFactory(f);
  CheckMath(f, f.NoneLinear(PDouble(x), PDouble(c), PDouble(y), n, m, k, diffstep, epsx, niter, PDouble(bl), PDouble(bh), PDouble(cs), @cbNoneLinearLSFit, PDoubleArray(cOut), info, Rep));
//  var tope := lua_gettop(L);
//  Tdebug.Log('dtop %d %d', [top,tope]);
  for var i := 0 to k - 1 do
    lua_pushnumber(L, cOut[i]);
  Result := k;
end;

class function TXMLScriptMath.Now(L: lua_State): Integer;
begin
  lua_pushnumber(L, SysUtils.now);
  Result := 1;
end;

class function TXMLScriptMath.LinearLS(L: lua_State): Integer;
var
  e: IEquations;
  a, b: TArray<Double>;
  nrows, ncols, cna, cnb, i: Integer;
  info: Integer;
  x: PDoubleArray;
  R2: Double;
  n: Integer;
  k: Integer;
  cx: IDoubleMatrix;
begin
  luaL_checktype(L, 1, LUA_TTABLE);
  nrows := lua_tointeger(L, 2);
  ncols := lua_tointeger(L, 3);
  luaL_checktype(L, 4, LUA_TTABLE);
  cna := lua_rawlen(L, 1);
  SetLength(a, cna);
  for i := 1 to cna do
  begin
    lua_rawgeti(L, 1, i);
    a[i - 1] := lua_tonumber(L, -1);
  end;
  cnb := lua_rawlen(L, 4);
  SetLength(b, cnb);
  for i := 1 to cnb do
  begin
    lua_rawgeti(L, 4, i);
    b[i - 1] := lua_tonumber(L, -1);
  end;

  EquationsFactory(e);
  CheckMath(e, e.LinearLS(@a[0], nrows, ncols, @b[0], info, x, R2, n, k, cx));
  for i := 0 to n - 1 do
    lua_pushnumber(L, x[i]);
  lua_pushnumber(L, R2);
  Result := n + 1;
end;

class function TXMLScriptMath.PolyAprox(L: lua_State): Integer;
var
  ib: IBaryCentric;
  x, y: TArray<Double>;
  pow2: PDouble;
  info, n, nres, i: Integer;
begin
  luaL_checktype(L, 1, LUA_TTABLE);
  luaL_checktype(L, 2, LUA_TTABLE);
  n := lua_rawlen(L, 1);
  SetLength(x, n);
  SetLength(y, n);
  for i := 1 to n do
  begin
    lua_rawgeti(L, 1, i);
    x[i - 1] := lua_tonumber(L, -1);
    lua_rawgeti(L, 2, i);
    y[i - 1] := lua_tonumber(L, -1);
    lua_pop(L, 2);
  end;
  nres := lua_tointeger(L, 3);
  BaryCentricFactory(ib);
  CheckMath(ib, ib.FitV(@x[0], @y[0], n, nres, info));
  CheckMath(ib, ib.GetLastPow2(pow2));
//  lua_createtable(L, nres, 0);
  for i := 1 to nres do
  begin
    lua_pushnumber(L, pow2^);
//     lua_rawseti(L, -2, i);
    inc(pow2);
  end;
  Result := nres; {1}
end;

class function TXMLScriptMath.RadToDeg(L: lua_State): Integer;
begin
  lua_pushnumber(L, DegNormalize(math.RadToDeg(lua_tonumber(L, 1))));
  Result := 1;
end;

class function TXMLScriptMath.RadToDeg180(L: lua_State): Integer;
begin
  lua_pushnumber(L, DegNormalize(math.RadToDeg(lua_tonumber(L, 1))));
  Result := 1;
end;

class function TXMLScriptMath.RadToDeg360(r: Double): Double;
begin
  Result := DegNormalize(math.RadToDeg(r));
end;

class function TXMLScriptMath.RadToDeg360(L: lua_State): Integer;
begin
  lua_pushnumber(L, DegNormalize(math.RadToDeg(lua_tonumber(L, 1))));
  Result := 1;
end;

class function TXMLScriptMath.RbfInterp(xy: Variant; x1, x2: Double): Double;
var
  r: IXMLNode;
  oi: IOwnIntfXMLNode;
  rbf: IRbf;
  res: PRbfReport;
  rz: Double;
begin
  r := TVxmlData(xy).node;

  if not Supports(r, IOwnIntfXMLNode, oi) then
    raise EBaseException.Create('Not Supports IOwnIntfXMLNode');
  if not Assigned(oi.Intf) then
  begin
    RbfFactory(rbf);
    oi.Intf := IInterface(rbf);
    rbf.Create(2, 1);
    CheckMath(rbf, rbf.Points(PAnsiChar(AnsiString(r.Attributes['XY']))));
    CheckMath(rbf, rbf.Build(res));
  end;
  rbf := IRbf(oi.Intf);
  CheckMath(rbf, rbf.Calc2(x1, x2, rz));
  Result := rz;
end;

class function TXMLScriptMath.RbfInterp(L: lua_State): Integer;
var
  r: IXMLNode;
  oi: IOwnIntfXMLNode;
  rbf: IRbf;
  res: PRbfReport;
  x1, x2, rz: Double;
begin
  r := TXMLLua.XNode(L, 1);
  x1 := lua_tonumber(L, 2);
  x2 := lua_tonumber(L, 3);

  if not Supports(r, IOwnIntfXMLNode, oi) then
    raise EBaseException.Create('Not Supports IOwnIntfXMLNode');
  if not Assigned(oi.Intf) then
  begin
    RbfFactory(rbf);
    oi.Intf := IInterface(rbf);
    rbf.Create(2, 1);
    CheckMath(rbf, rbf.Points(PAnsiChar(AnsiString(r.Attributes['XY']))));
    CheckMath(rbf, rbf.Build(res));
  end;
  rbf := IRbf(oi.Intf);
  CheckMath(rbf, rbf.Calc2(x1, x2, rz));
  lua_pushnumber(L, rz);
  Result := 1;
end;

class function TXMLScriptMath.SetIfNotExist(L: lua_State): Integer;
var
  root: IXMLNode;
  path: string;
begin
  root := TXMLLua.XNode(L, 1);
  path := string(lua_tostring(L, 2));
  if not root.HasAttribute(path) then
    if lua_isnumber(L, 3) = 0 then
      root.Attributes[path] := string(lua_tostring(L, 3))
    else
      root.Attributes[path] := lua_tonumber(L, 3);
  Result := 0;
end;

class function TXMLScriptMath.GetProjectOption(L: lua_State): Integer;
var
  m: TMarshaller;
  d: Variant;
  opt: string;
  tip: Integer;
begin
  opt := string(lua_tostring(L, 1));
  d := (GContainer as IProjectOptions).Option[opt];
  tip := (GContainer as IProjectOptions).GetOptionType(opt);
  if d = null then
    lua_pushnil(L)
  else
    case tip of
      PRG_TIP_INT:
        lua_pushinteger(L, d);
      PRG_TIP_REAL:
        lua_pushnumber(L, d);
      PRG_TIP_BOOL:
        lua_pushboolean(L, Integer(d));
    else
      lua_pushstring(L, m.AsAnsi(d).ToPointer);
    end;
  Result := 1;
end;

class function TXMLScriptMath.SetProjectOption(L: lua_State): Integer;
var
  opt: string;
begin
  opt := string(lua_tostring(L, 1));
  case lua_type(L, 1) of
   //LUA_TNIL: Node.Attributes[name] := nil;
    LUA_TBOOLEAN:
      (GContainer as IProjectOptions).Option[opt] := Boolean(lua_toboolean(L, 2));
    LUA_TNUMBER:
      (GContainer as IProjectOptions).Option[opt] := lua_tonumber(L, 2);
    LUA_TSTRING:
      (GContainer as IProjectOptions).Option[opt] := string(lua_tostring(L, 2));
  else
    raise ELuaException.Createfmt('Error SetProjectOption type: %s', [string(lua_typename(L, 2))]);
  end;
  lua_settop(L, 0);
  Result := 0;
end;

class function TXMLScriptMath.SGK_FindGK(L: lua_State): Integer;
var
  s, d: string;
  Sm: Integer;
  root: variant;
begin
  root := Xtovar(TXMLLua.XNode(L, 1));
  s := root.СГК.DEV.VALUE;
  Sm := 0;
  for d in s.Split([' '], TStringSplitOptions.ExcludeEmpty) do
    Sm := Sm + d.ToInteger;
  root.гк.DEV.VALUE := Sm;
  Result := 0;
end;

class function TXMLScriptMath.ImportNNK10(L: lua_State): Integer;
var
  ss: TStrings;
  i: Integer;
//  s: string;
  root, dev: IXMLNode;
  sp: TArray<string>;
  TrrFile: string;
//  NewTrr: Variant);

  procedure UpdatePoint(d, kp, k1, k2, gk: Double);
  var
    skp: string;
    n: IXMLNode;
  begin
    if kp = 100 then
      skp := 'Вода'
    else
      skp := FloatToStr(kp);
    for n in XEnum(root) do
      if (n.Attributes['KP'] = skp) and (n.Attributes['D'] = d) then
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
  root := TXMLLua.XNode(L, 1); //TVxmlData(NewTrr).Node;
  dev := root.ParentNode.ParentNode.ParentNode;
 // TDebug.Log(root.NodeName);
  ss := TStringList.Create();
  try
    ss.LoadFromFile(TrrFile);
    if ss.Count <> 17 then
      raise EBaseException.Createfmt('У файла %s %d (17)строк', [TrrFile, ss.Count]);
    dev.Attributes[AT_SERIAL] := Trim(Copy(ss[0], 5, 3));
    root.Attributes[AT_TIMEATT] := Trim(Copy(ss[1], 1, 12));
    root.Attributes['ISTOCHNIK'] := Trim(Copy(ss[2], 1, pos('Источник', ss[2]) - 1));
    for i := 1 to 13 do
    begin
      sp := ss[i + 3].Trim.split([' '], TStringSplitOptions.ExcludeEmpty);
      UpdatePoint(sp[0].ToDouble, sp[1].ToDouble, sp[2].ToDouble, sp[3].ToDouble, sp[4].ToDouble);
    end;
{    begin
     s := Trim(ss[i+3]);
     UpdatePoint(Next(), Next(), Next(), Next(), Next());
    end;}
  finally
    ss.Free;
  end;
  Result := 0;
end;

class procedure TXMLLuaBKS.cb_Bks_func(const x, f: PDoubleArray);
var
  i: Integer;
begin
  for i := 0 to 7 do
    f[i] := x[0] * Cos(FZOND[i] + CurY.Vizir + x[1]) + x[2] - CurY.Current[i];
end;

class procedure TXMLLuaBKS.cb_Bks_jac(const x, f: PDoubleArray; const jac: PMatrix);
var
  i: Integer;
  s, c: Double;
begin
  for i := 0 to 7 do
  begin
    Math.SinCos(FZOND[i] + CurY.Vizir + x[1], s, c);
    f[i] := x[0] * c + x[2] - CurY.Current[i];
    jac[i, 0] := c;
    jac[i, 1] := -x[0] * s;
    jac[i, 2] := 1;
  end;
end;

class procedure TXMLLuaBKS.FindBKS(focus: IXMLNode; otk: Double; XOut: PDoubleArray);

  procedure FindX0;
  var
    i, nmi, nma: Integer;
    max, min, sred: Double;
  begin
    sred := 0;
    max := Double.MinValue;
    min := Double.MaxValue;
    nma := 0;
    nmi := 0;
    for i := 0 to 7 do
    begin
      sred := sred + CurY.Current[i];
      if CurY.Current[i] > max then
      begin
        max := CurY.Current[i];
        nma := i;
      end;
      if CurY.Current[i] < min then
      begin
        min := CurY.Current[i];
        nmi := i;
      end;
    end;
    X0[0] := max - min;
    //X0[1] := FZOND[nma];
    X0[2] := sred / 8;
  end;

var
  e: ILMFitting;
  i: Integer;
  rep: PLMFittingReport;
  X: PDoubleArray;
begin
  if not Assigned((focus as IOwnIntfXMLNode).Intf) then
  begin
    LMFittingFactory(e);
    (focus as IOwnIntfXMLNode).Intf := e;
  end
  else
    e := ILMFitting((focus as IOwnIntfXMLNode).Intf);
  CurY.Vizir := DegtoRad(360 - otk);
  for i := 1 to 8 do
    CurY.Current[i - 1] := focus.Childnodes.FindNode('I' + i.tostring).Childnodes.FindNode(T_CLC).Attributes[AT_VALUE];
  FindX0();
  CheckMath(e, e.FitJB(3, 8, PDoubleArray(@X0[0]), PDoubleArray(@X0L[0]), PDoubleArray(@X0U[0]), 0.00000001, 1000, cb_Bks_func, cb_Bks_jac, X, rep));
  XOut[0] := X[0];
  XOut[1] := X[1];
  XOut[2] := X[2];
  X := nil;
end;

class function TXMLLuaBKS.FindBKS(L: lua_State): Integer;
var
  X: array[0..6] of Double;
begin
  FindBKS(TXMLLua.XNode(L, 1), lua_tonumber(L, 2), @X);
  Result := 3;
  lua_pushnumber(L, X[0]);

//  d := (RadToDeg(X[1]));
  X0L[1] := X[1] - pi / 2;
  X0[1] := X[1];
  X0U[1] := X[1] + pi / 2;
  X[1] := DegNormalize(RadToDeg(X[1]));

//  if d < 0 then d := 360 + d;
  lua_pushnumber(L, X[1]);
  lua_pushnumber(L, X[2]);
end;

end.


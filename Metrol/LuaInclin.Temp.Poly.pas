unit LuaInclin.Temp.Poly;

interface

uses tools, VirtualTrees.Types,
  System.SysUtils, Xml.XMLIntf, VirtualTrees,
  XMLLua.Math, Math,  Vector, Vcl.Graphics,
  LuaInclin.Math,
  MetrInclin.Temp.stat,
  TrrInclin.Temp.PolyModel,
  MetrInclin.Temp.MathPoly;

type
  TPolyModelHelper = record helper for PolyModel
   function ResultHeaders: TArray<string>;
   function ResultText(axies: IXMLNode): TArray<string>;
  end;


  TpolyMathHelper = class helper for TpolyMath
   class procedure ResultToXML(trr: IXMLNode; G, H: TVArray<Double>);
   class procedure KosoToXML(trr: IXMLNode; G, H: TVArray<Double>);
   class procedure FindInkl(trr, Res: IXMLNode; scA,scH: Double; var Incl: TInclRes);
   class var EStat: array[0..5] of TeStat;
//   class var CorrStolA, CorrStolz, CorrStolv, CorrStoli, CorrStolMag: Double;
   class procedure findErr(alg, trr: IXMLNode; scA,scH, amp, nak: Double; Iskoso: Boolean);
   class procedure FindInklKoso(inx: Integer; var Incl: TInclRes);
   class function StepToIdx(st: integer): Integer;
   class function EStatToStr(const Fmt: string): string;
  end;

  TColumn = class
    name: string;
    width: Integer;
    function Get(st: IXMLNode): string; virtual;
    procedure Paint(st: IXMLNode; const TargetCanvas: TCanvas); virtual;
    constructor Create(const name: string; width: Integer = 40);
  end;

  TColumnXML = class(TColumn)
    width: Integer;
    path: string;
    Fmt: string;
    attr: string;
    function Get(st: IXMLNode): string; override;
    constructor Create(const name: string;
                       const path: string='';
                       const attr: string='VALUE';
                       const Fmt: string='%7.1f';
                       width: Integer = 70);
  end;

  TColumnEtalon = class(TColumn)
    sns: SetSetsor;
    v: Integer;
    Fmt: string;
    function GetSens(r: TInclRes): TSensorVect; virtual;
    function Get(st: IXMLNode): string; override;
    constructor Create(const name: string;
                        sns: SetSetsor;
                        v: SetVector;
                        width: Integer = 70);
  end;

  TColumnTrr = class(TColumnEtalon)
    function GetSens(r: TInclRes): TSensorVect; override;
    constructor Create(const name: string;
                        sns: SetSetsor;
                        v: SetVector;
                        width: Integer = 70);
  end;
  TColumnErr = class(TColumnEtalon)
    function GetSens(r: TInclRes): TSensorVect; override;
  end;

  TColumnAngle = class(TColumn)
    type ColumnAnglePath = (cacsA,caA, caE);
    var
    sp :ColumnAnglePath;
    Fmt: string;
    function GetPath(r: TInclRes): Double; virtual;
    function Get(st: IXMLNode): string; override;
    constructor Create(const name: string;
                        sp: ColumnAnglePath;
                        width: Integer = 70);
  end;
  TColumnAngleZ = class(TColumnAngle)
    function GetPath(r: TInclRes): Double; override;
    constructor Create(const name: string;
                        sp: TColumnAngle.ColumnAnglePath;
                        width: Integer = 70);
  end;
  TColumnAngleV = class(TColumnAngle)
    function GetPath(r: TInclRes): Double; override;
  end;
  TColumnAngleI = class(TColumnAngle)
    function GetPath(r: TInclRes): Double; override;
  end;

  TColumnAmp = class(TColumn)
    sns: SetSetsor;
    isErr: Boolean;
    function Get(st: IXMLNode): string; override;
    constructor Create(const name: string;
                        sns: SetSetsor;
                        isErr: Boolean = False;
                        width: Integer = 70);
  end;

  TColumns = class
   private
   class var cls: TArray<TColumn>;
   public
   class function Get(col: Integer; st: IXMLNode): string; static;
   class procedure Paint(col: Integer; st: IXMLNode; const TargetCanvas: TCanvas); static;
   class procedure SetTreeColumns(Tree: TVirtualStringTree); static;
  end;


implementation

{ TPolyModelHelper }

function TPolyModelHelper.ResultHeaders: TArray<string>;
 var
  s: TArray<string>;
  function Af(const ax: string): TArray<string>;
  begin
    SetLength(Result, Length(s));
    for var i := 0 to High(s) do Result[i] := Format(s[i], [ax]);
  end;
begin
  s := [];
  for var axs := 0 to High(ax) do
   begin
    var si: string := '%s';
    if axs > 0 then si := '%s' + IntToStr(axs+1);
    for var t := 0 to ax[axs] do
     begin
      var sit: string := si;
      if t = 1 then sit := si+'t';
      if t > 1 then sit := si + 't' + t.ToString;
      s := s + [sit];
     end;
   end;
  Result := Af('x')+Af('y')+Af('z');
  for var t := 0 to dz do
   begin
    if t = 0 then Result := Result + ['1'];
    if t = 1 then Result := Result + ['t'];
    if t > 1 then Result := Result + ['t' + t.ToString];
   end;
end;

function TPolyModelHelper.ResultText(axies: IXMLNode): TArray<string>;
  var
   ax: Char;
   nins, axv: TArray<string>;
   procedure Doins(first, last: Integer);
   begin
     Insert(nins, axv, last+KuCnt);
     Insert(nins, axv, first+KuCnt);
   end;
begin
  var n := AxCnt - KuCnt;
  SetLength(nins, n);
  ax := axies.NodeName[1];
  axv := string(axies.NodeValue).Split([' '], TStringSplitOptions.ExcludeEmpty);

  case  ax of
   'X': Doins(pXy,pXz);
   'Y': Doins(pYx,pYz);
   'Z': Doins(pZx,pZy);
  end;

  Result := axv;
end;

{ TpolyMathHelper }

class function TpolyMathHelper.EStatToStr(const Fmt: string): string;
begin
  Result := Format(Fmt,
  [
  EStat[0].Step+1,
  EStat[0].Pik/RES_AMP*100,
  EStat[0].Av/RES_AMP*100,
  EStat[1].Step+1,
  EStat[1].Pik/RES_AMP*100,
  EStat[1].Av/RES_AMP*100,
  EStat[2].Step+1,
  EStat[2].Pik,
  EStat[2].Av,
  eStat[3].Step+1,
  eStat[3].Pik,
  eStat[3].Av,
  eStat[4].Step+1,
  eStat[4].Pik,
  eStat[4].Av,
  eStat[5].Step+1,
  eStat[5].Pik,
  eStat[5].Av
  ]);

end;

class procedure TpolyMathHelper.findErr(alg, trr: IXMLNode; scA,scH, amp, nak: Double; Iskoso: Boolean);
  var
   inpIdx: Integer;
begin

  for var e in eStat do if Assigned(e) then e.Free;
  eStat[0] := TAccStat.Create;
  eStat[1] := TMagStat.Create;
  eStat[2] := TInclStat.Create;
  eStat[3] := TZenStat.Create;
  eStat[4] := TAziStat.Create;
  eStat[5] := TotkStat.Create;

  if Length(InclRes) <> Length(InpData.Inpt) then  SetLength(InclRes, Length(InpData.Inpt));
  inpIdx := 0;
  for var i := 0 to alg.ChildNodes.Count-1 do
   begin
    var xst := alg.ChildNodes[i];
    var st := XToVar(xst);
    if string(st.INFO).Contains('NotUse') or (string(st.EXECUTED) = 'false') then Continue;

    InclRes[inpIdx].Inp := @InpData.Inpt[inpIdx];
    if Iskoso then  FindInklKoso(inpIdx, InclRes[inpIdx])
    else FindInkl(trr, xst, scA, scH, InclRes[inpIdx]);

    for var e in eStat do e.Test(i, InclRes[inpIdx]);
    Inc(inpIdx);
   end;
  for var e in eStat do e.SetAV();
end;

class procedure TpolyMathHelper.FindInkl(trr, Res: IXMLNode; scA, scH: Double; var Incl: TInclRes);
 var
  mo,hx,hy,hz,a,b,
  o,zu, os,oc,zs,zc,
  ax, ay, az, x, y, z: Double;
  sA,sZ,sO,sN: Double;
begin
  TXMLScriptMath.TrrVectPoly(trr, Res, ax, ay, az, x, y, z, scA, scH);

  FindInclRes(VecCollect(ax, ay, az, x, y, z ), eStol, Incl);
  {$REGION 'old'}

//  o := Arctan2(ay, -ax);
//  zu := Arctan2(Hypot(ax, ay), az);
//
//  os := sin(o);
//  oc := cos(o);
//  zs := sin(zu);
//  zc := cos(zu);
//
//  Hx := (x*oc - y*os)*zc + z*zs;
//  Hy :=  x*os + y*oc;
//  Hz :=-(x*oc - y*os)*zs + z*zc;
//
//  a := -Arctan2(Hy, Hx);
//  b := Arctan2(Hypot(Hx, Hy), Hz);
//
//  Incl.trrSens[sAcc] := TVector3.Create(ax,ay,az);
//  Incl.trrSens[sMag] := TVector3.Create(x,y,z);
//  Incl.errSens[sAcc] := Incl.trrSens[sAcc] - Incl.etaSens[sAcc];
//  Incl.errSens[sMag] := Incl.trrSens[sMag] - Incl.etaSens[sMag];
//  Incl.Amp[sAcc] := TXMLScriptMath.Hypot3D(ax, ay, az);
//  Incl.Amp[sMag] := TXMLScriptMath.Hypot3D(x, y, z);
//  Incl.MO := Arctan2(y, -x);
//  Incl.zen := TXMLScriptMath.RadToDeg360(zu);
//  Incl.otk := TXMLScriptMath.RadToDeg360(o);
//  Incl.azi := TXMLScriptMath.RadToDeg360(a);
//  Incl.Nakl := TXMLScriptMath.RadToDeg360(b);
//
//  sA := inp.Azi;
//  sZ := inp.Zen;
//  sO := inp.Vis;
//  sN := InpData.MNak;
////  Incl.azi.Stol := sA;
////  Incl.zen.Stol := sZ;
////  Incl.otk.Stol := sO;
////  Incl.Nakl.Stol := sN;
//  eStol.Correct(sA,sZ,sO,sN);
//  Incl.azi.CorStol := sA;
//  Incl.zen.CorStol := sZ;
//  Incl.otk.CorStol := sO;
//  Incl.Nakl.CorStol := sN;
//  Incl.etaAmpH := RES_AMP * Inp.EtalonMag/1000;
//
//  var v := XToVar(Res);
//  TXMLScriptMath.AddXmlPath(v,'маг_наклон.CLC').VALUE := TXMLScriptMath.RadToDeg360(b);
//  v.маг_наклон.CLC.VALUE  := TXMLScriptMath.RadToDeg360(b);
//  v.маг_отклон.CLC.VALUE  := TXMLScriptMath.RadToDeg360(mo);
// TXMLScriptMath.AddXmlPath(v,'маг_отклон.CLC').VALUE := TXMLScriptMath.RadToDeg360(mo);
//  v.азимут.CLC.VALUE      := TXMLScriptMath.RadToDeg360(a);
// TXMLScriptMath.AddXmlPath(v,'азимут.CLC').VALUE := TXMLScriptMath.RadToDeg360(a);
//  v.амплит_magnit.CLC.VALUE := TXMLScriptMath.Hypot3D(x, y, z);
//  TXMLScriptMath.AddXmlPath(v,'амплит_magnit.CLC').VALUE := TXMLScriptMath.Hypot3D(x, y, z);
//  v.отклонитель.CLC.VALUE := TXMLScriptMath.RadToDeg360(o);
//  TXMLScriptMath.AddXmlPath(v,'отклонитель.CLC').VALUE :=  TXMLScriptMath.RadToDeg360(o);
//  v.зенит.CLC.VALUE       := TXMLScriptMath.RadToDeg360(zu);
//  TXMLScriptMath.AddXmlPath(v,'зенит.CLC').VALUE := TXMLScriptMath.RadToDeg360(zu);
//  TXMLScriptMath.AddXmlPath(v,'амплит_accel.CLC').VALUE := TXMLScriptMath.Hypot3D(ax, ay, az);
//  Incl.azi := v.азимут.CLC.VALUE;
//  Incl.zen := v.зенит.CLC.VALUE;
//  Incl.otk := v.отклонитель.CLC.VALUE;
//  Incl.G := v.амплит_accel.CLC.VALUE;
//  Incl.H := v.амплит_magnit.CLC.VALUE;
//  Incl.i := v.маг_наклон.CLC.VALUE;
{$ENDREGION}
end;


class procedure TpolyMathHelper.FindInklKoso(inx: Integer; var Incl: TInclRes);
begin
  KosoFindInkl(inx, KosRes, Incl);
end;

class procedure TpolyMathHelper.KosoToXML(trr: IXMLNode; G, H: TVArray<Double>);
 procedure AssignSensor(sns: IXMLNode; snsks: TVArray<Double>; pm: PolyModel; kos: TKosUgol);
  var
    r: TVArray<Double>;
 begin
   r := snsks;
   r[vX][pm.pXy] := kos.Xy; r[vX][pm.pXz] := kos.Xz;
   r[vY][pm.pYx] := kos.Yx; r[vY][pm.pYz] := kos.Yz;
   r[vZ][pm.pZx] := kos.Zx; r[vZ][pm.pZy] := kos.Zy;

   for var v in SVectors do
    begin
     var sa: TArray<string> := [];
     for var d in r[v] do sa := sa + [d.ToString];
     sns.Attributes[SVectorsNames[v]] := string.Join(' ', sa);
    end;
 end;
begin
  AssignSensor(GetXNode(trr,'Poly.accel'), G, InpData.pmA, KosRes.kos[sAcc]);
  AssignSensor(GetXNode(trr,'Poly.magnit'), H, InpData.pmH, KosRes.kos[sMag]);
end;

class procedure TpolyMathHelper.ResultToXML(trr: IXMLNode; G, H: TVArray<Double>);
 procedure AssignSensor(sns: IXMLNode; snsks: TVArray<Double>);
 begin
   for var v in SVectors do
    begin
     var sa: TArray<string> := [];
     for var d in snsks[v] do sa := sa + [d.ToString];
     sns.Attributes[SVectorsNames[v]] := string.Join(' ', sa);
    end;
 end;
begin
  AssignSensor(GetXNode(trr,'Poly.accel'), G);
  AssignSensor(GetXNode(trr,'Poly.magnit'), H);
end;

class function TpolyMathHelper.StepToIdx(st: integer): Integer;
  var
   spt: Integer;
begin
  if Length(InpData.Inpt) >= st then spt := st-1
  else spt := High(InpData.Inpt);
  for var i:= spt downto 0 do
    if InpData.Inpt[i].Step = st then Exit(i);
end;


{ TColumns }

class function TColumns.Get(col: Integer; st: IXMLNode): string;
begin
  var f := cls[col];
  if Assigned(f) then Result := f.Get(st);
end;

class procedure TColumns.Paint(col: Integer; st: IXMLNode; const TargetCanvas: TCanvas);
begin
  var f := cls[col];
  if Assigned(f) then f.Paint(st, TargetCanvas);
end;

class procedure TColumns.SetTreeColumns(Tree: TVirtualStringTree);
  function AddCol(d: TColumn): TVirtualTreeColumn;
  begin
    Result := Tree.Header.Columns.Add;
    Result.Options := [coEnabled,coParentBidiMode,coParentColor,coResizable,coShowDropMark,coVisible,coAllowFocus];
    Result.Text := d.name;
    Result.Width := d.width;
//    Result.MinWidth := d.width;
  end;
begin
  Tree.BeginUpdate;
  try
   for var t in cls do AddCol(t);
  finally
   Tree.EndUpdate;
  end;
end;

{ TColumn }

constructor TColumn.Create(const name: string; width: Integer);
begin
  Self.name := name;
  Self.width := width;
end;

function TColumn.Get(st: IXMLNode): string;
begin
  Result := name;
end;

procedure TColumn.Paint(st: IXMLNode; const TargetCanvas: TCanvas);
begin
  var z := Double(st.ChildNodes['СТОЛ'].Attributes['зенит']);
  var a := Double(st.ChildNodes['СТОЛ'].Attributes['азимут']);
  if (z < 1) or (z > 359) then
    TargetCanvas.Font.Color := if CurrentThemeIsDark then $00FF00FF else $005F005F
  else if Abs(z -180) < 1  then
    TargetCanvas.Font.Color := if CurrentThemeIsDark then $00FFFF00 else $005F5F00
  else if Abs(z - TpolyMath.InpData.MNak) < 1  then
    TargetCanvas.Font.Color := if CurrentThemeIsDark then $0000FFFF else $00005F5F
  else if Abs(z - 180 - TpolyMath.InpData.MNak) < 1  then
    TargetCanvas.Font.Color := if CurrentThemeIsDark then clSkyBlue else $005f0000
  else if Abs(a - 90) < 1  then
    TargetCanvas.Font.Color := if CurrentThemeIsDark then $000000Ff else $0000005f
  else if Abs(a - 260) < 1  then
    TargetCanvas.Font.Color := if CurrentThemeIsDark then $0000Ff00 else $00005f00

end;

{ TColumn }

constructor TColumnXML.Create(const name, path, attr, Fmt: string; width: Integer);
begin
  inherited Create(name, width);
  Self.path := path;
  Self.attr := attr;
  Self.Fmt := Fmt;
end;

function TColumnXML.Get(st: IXMLNode): string;
 var
  V: IXMLNode;
begin
  Result := name;
  if TryGetX(st, path, V, attr) then
    if fmt ='' then
      Result := V.NodeValue
    else
      Result := Format(fmt, [Double(V.NodeValue)])
   else
     Result := '1000';
end;

{ TColumnEtalon }

constructor TColumnEtalon.Create(const name: string; sns: SetSetsor; v: SetVector; width: Integer);
begin
  inherited Create(name, width);
  Self.sns := sns;
  Self.v := Integer(v);
  if RES_AMP = 1 then  Fmt := '%7.4f'
  else   Fmt := '%7.2f'
end;

function TColumnEtalon.Get(st: IXMLNode): string;
begin
   var i := TpolyMath.StepToIdx(st.Attributes['STEP']);
   if i >= Length(TpolyMath.InclRes) then Exit;
   Result := Format(fmt,[ GetSens(TpolyMath.InclRes[i])[sns].V[v]] );
end;

function TColumnEtalon.GetSens(r: TInclRes): TSensorVect;
begin
  Result := r.etaSens;
end;

{ TColumnTrr }

constructor TColumnTrr.Create(const name: string; sns: SetSetsor; v: SetVector; width: Integer);
begin
  inherited;
  if RES_AMP = 1 then  Fmt := '%7.4f'
  else   Fmt := '%7.1f'
end;

function TColumnTrr.GetSens(r: TInclRes): TSensorVect;
begin
  Result := r.trrSens;
end;

{ TColumnErr }

function TColumnErr.GetSens(r: TInclRes): TSensorVect;
begin
  Result := r.errSens;
end;

{ TColumnAngle }

constructor TColumnAngle.Create(const name: string; sp: ColumnAnglePath; width: Integer);
begin
  inherited Create(name,width);
  Self.sp := sp;
  Fmt := '%7.1f';
end;

function TColumnAngle.Get(st: IXMLNode): string;
begin
   var i := TpolyMath.StepToIdx(st.Attributes['STEP']);
   if i >= Length(TpolyMath.InclRes) then Exit;
   if sp = caE then Fmt := '%7.3f';
   Result := Format(fmt,[ GetPath(TpolyMath.InclRes[i])]);
end;

function TColumnAngle.GetPath(r: TInclRes): Double;
begin
   case sp of
     cacsA: Result := r.Azi.CorStol;
     caA: Result := r.Azi.Angle;
     caE: Result := r.Azi.Error;
   end;
end;

{ TColumnAngleZ }

constructor TColumnAngleZ.Create(const name: string; sp: TColumnAngle.ColumnAnglePath; width: Integer);
begin
  inherited;
  Fmt := '%7.2f';
end;

function TColumnAngleZ.GetPath(r: TInclRes): Double;
begin
   case sp of
     cacsA: Result := r.Zen.CorStol;
     caA: Result := r.Zen.Angle;
     caE: Result := r.Zen.Error;
   end;
end;

{ TColumnAngleV }

function TColumnAngleV.GetPath(r: TInclRes): Double;
begin
   case sp of
     cacsA: Result := r.Otk.CorStol;
     caA: Result := r.Otk.Angle;
     caE: Result := r.Otk.Error;
   end;
end;

{ TColumnAngleI }

function TColumnAngleI.GetPath(r: TInclRes): Double;
begin
   case sp of
     cacsA: Result := r.Nakl.CorStol;
     caA: Result := r.Nakl.Angle;
     caE: Result := r.Nakl.Error;
   end;
end;

{ TColumnH }


constructor TColumnAmp.Create(const name: string; sns: SetSetsor; isErr: Boolean; width: Integer);
begin
  inherited Create(name, width);
  Self.sns := sns;
  Self.isErr := isErr;
end;

function TColumnAmp.Get(st: IXMLNode): string;
  function GetPath(r: TInclRes): Double;
   var
   sd: TSensorData<Double>;
  begin
    if isErr then sd := r.erAmp else sd := r.Amp;
    Result := sd[sns]
  end;
begin
  var i := TpolyMath.StepToIdx(st.Attributes['STEP']);
  if i >= Length(TpolyMath.InclRes) then Exit;
  Result := Format('%7.3f',[ GetPath(TpolyMath.InclRes[i])]);
end;


initialization
 TColumns.cls := [
   TColumnXML.Create('№','','STEP','',50),
   TColumnXML.Create('T','T.DEV'),
   TColumnXML.Create( 'sZu','СТОЛ','зенит','%7.2f'),
   TColumnAngleZ.Create( 'csZu', cacsA ),
   TColumnAngleZ.Create( 'Zu'  , caA   ),
   TColumnAngleZ.Create( 'eZU' , caE   ),
   TColumnXML.Create('sAz','СТОЛ','азимут'),
   TColumnAngle.Create( 'csAz', cacsA ),
   TColumnAngle.Create( 'Az'  , caA   ),
   TColumnAngle.Create( 'eAz' , caE   ),
   TColumnXML.Create('sVis','СТОЛ','визир'),
   TColumnAngleV.Create( 'csViz', cacsA ),
   TColumnAngleV.Create( 'Vis'  , caA   ),
   TColumnAngleV.Create( 'eVis' , caE   ),
   TColumnXML.Create( 'sH','СТОЛ','амплит_magnit'),
   TColumnAmp.Create( 'H',sMag),
   TColumnAmp.Create( 'eH',sMag, True),
   TColumnAmp.Create( 'G',sAcc),
   TColumnAmp.Create( 'eG',sAcc,True),
   TColumnAngleI.Create( 'I', caA),
   TColumnAngleI.Create( 'eI',caE),
   TColumnXML.Create('GX','accel.X.DEV'),
   TColumnXML.Create('GY','accel.Y.DEV'),
   TColumnXML.Create('GZ','accel.Z.DEV'),
   TColumnEtalon.Create('эGX',sAcc,vX),
   TColumnEtalon.Create('эGY',sAcc,vY),
   TColumnEtalon.Create('эGZ',sAcc,vZ),
   TColumnTrr.Create( 'tGX',sAcc,vX),
   TColumnTrr.Create( 'tGY',sAcc,vY),
   TColumnTrr.Create( 'tGZ',sAcc,vZ),
   TColumnErr.Create( 'eGX',sAcc,vX),
   TColumnErr.Create( 'eGY',sAcc,vY),
   TColumnErr.Create( 'eGZ',sAcc,vZ),
   TColumnXML.Create( 'HX','magnit.X.DEV'),
   TColumnXML.Create( 'HY','magnit.Y.DEV'),
   TColumnXML.Create( 'HZ','magnit.Z.DEV'),
   TColumnEtalon.Create( 'эHX', sMag, vX),
   TColumnEtalon.Create( 'эHY', sMag, vY),
   TColumnEtalon.Create( 'эHZ', sMag, vZ),
   TColumnTrr.Create( 'tHX', sMag, vX),
   TColumnTrr.Create( 'tHY', sMag, vY),
   TColumnTrr.Create( 'tHZ', sMag, vZ),
   TColumnErr.Create( 'eHX', sMag, vX),
   TColumnErr.Create( 'eHY', sMag, vY),
   TColumnErr.Create( 'eHZ', sMag, vZ)
 ];
end.

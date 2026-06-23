unit MetrInclin.Temp.MathPoly;

interface

uses System.SysUtils, System.Classes, TrrInclin.Temp.PolyModel, LuaInclin.Math, Math,
     MathIntf, XMLLua.Math, Vector, MetrInclin.Temp.Stat;

//   SENS : array[0..1] of string = ('accel', 'magnit');
type

{$REGION 'old'}
//  // x,y,z
//  T3DPoint = array [0..2] of Double;
//   // искомые коэфициенты
//  TVekModel = array[0..3] of Double;
//  //     |k0|
//  //     |k1|     model inclin
//  // K=  |k2|
//  //     |k3|
//
//  TTModel = array[0..3] of Double;
//
//  // Ti = |1,t,tt,ttt|      ti = 25 60 100 125 25
//  TAxisModel = array[0..3] of TVekModel;
//  // модель сенсора в векторном виде
//  // Xэ = (K1 + Xij*K2 +  Yij*K3 +  Zij*K4)*Ti
//  // Yэ = (K5 + Xij*K6 +  Yij*K7 +  Zij*K8)*Ti
//  // Zэ = (K9 + Xij*K10 + Yij*K11 + Zij*K12)*Ti
//  TSensorModel = array[0..2] of TAxisModel;
//  // j - 48 пространственных точек
//  // Az90, Zu90, 8Vis
//  // Az270,Zu90, 8Vis
//  // Az0,  Zu0,  8Vis
//  // Az0,  Zu180,8Vis
//  // Az0,  Zu18, 8Vis
//  // Az0,  Zu198,8Vis
//
//  // 48*5  =240 уравнений
//
//  // делим на три системы уравнений для каждой оси
//
//  // k = 16 неизвестных оа ось
//  // ряд матрицы А измеренные X,Y,Z,t
//  // Э = Xi,Xit,Xitt,Xittt, Yi,Yit,Yitt,Yittt, Zi,Zit,Zitt,Zittt, 1,t,tt,ttt
//  // Э - вектор (X,Y,Z) (делим на три системы уравнений для каждой оси!)
//  TARow = TArray<Double>;
//  // заготовка для НМК по каждой точке (240 строк)
//  // B = A*x
//  // A одинакова для всех осей!
//  TAmatrix = TArray<TARow>;
//  // B => Э => X,Y,Z- зталоны полученные из данных стола А.З.О.Маг.Нак (точка измерения в пространстве при текущей температуре t)
//  // Xetalon,Yetalon,Zetalon: TBVector (делим на три системы уравнений для каждой оси! ARow,A-одинаковые для всех осей!)
//  TBVector = TArray<Double>;
{$ENDREGION}


    PFindLMKosStol = ^TFindLMKosStol;
    TFindLMKosStol = record
      kos: TSensorData<TKosUgol>;
      StolError: TStolError;
    end;

//  TSensRes = record
//   ex,ey,ez,//эталон
//   tx,ty,tz: Double;//тарированные
//   Amp: Double;
//  end;
  TPolyRes = record
     G, H: TVArray<Double>;
     function RowH :TArray<Double>;
     function RowG :TArray<Double>;
     procedure toArray(var r: array of Double);
     procedure fromArray(r: array of Double);
     function ArrayLen: Integer;
    end;

   PFindLMKosStolV2 = ^TFindLMKosStolV2;
   TFindLMKosStolv2 = record
    ks: TFindLMKosStol;
    t: array[0..1000] of Double;
    function Len:Integer;
   end;

  TpolyMath = class
  private
    class procedure SetupKoso(Bl,bh: PFindLMKosStol);

    class procedure RunLsT(pm: PolyModel; idxs: TArray<Integer>; sns: SetSetsor; vec: SetVector; var Res: TArray<Double>);

    class procedure RunLsSensor(pm: PolyModel; data: TArray<RowModel>; sns: SetSetsor; var Res: TVArray<Double>);
    class procedure RunLMSensor(pm: PolyModel; data: TArray<RowModel>; sns: SetSetsor; var Res: TVArray<Double>);
    class var LMAmpData : record
      m: PolyModel;
      bl, bh: TArray<Double>; //n
      kBegin: TArray<Double>; //n
      d: TArray<RowModel>;  //m
    end;
    class var KorrTVectors: TArray<TSensorVect>;
    class procedure KorrTVectors_int();
    class var IsKosoV2: Boolean;
//    class procedure func_cb_ZY_StolZ(const k, f: PDoubleArray); static; cdecl;
    class procedure func_cb_koso(const k, f: PDoubleArray); static; cdecl;
    class procedure func_cb_amp(const k, f: PDoubleArray); static; cdecl;
    class procedure func_cb_zen(const k, f: PDoubleArray); static; cdecl;
  public

    class var eStol: TStolError;

   // class var EtalonData : TArray<TSensorVect>;

    class var InpData : record
      pmA, pmH: PolyModel;
      MNak: Double;
      Inpt: TArray<TinclInput>;
    end;

    class var SetupData : record
      CorStolVisir,
      CorStolZenit,
      CorStolMagnit: Boolean;
    end;
    class var KosRes:  TFindLMKosStol;
//    class var KosResv2:  TFindLMKosStolv2;

    class var mag, acc: TArray<RowModel>;

    class var InclRes: Tarray<TInclRes>;

    class var Res: TPolyRes;

    class procedure Init(pmA,pmH: PolyModel; Naklon: Double; Inp: TArray<TinclInput>);
    class procedure RunAmp;
    class procedure RunLS;
    class procedure RunZ;
//    class procedure RunXYAndStolZ(arz: TArray<Integer>);
    class procedure RunT;
    class procedure RunKoso;
    class procedure RunKosoV2;
    class procedure ClearStolError;

    class procedure KosoFindInkl(ivec: Integer; const koso: TFindLMKosStol; var Incl: TInclRes);
    class procedure FindInclRes(const vec: TSensorVect; const eS: TStolError; var Incl: TInclRes);
  end;

procedure VecExtract(vec: TSensorVect; var ax,ay,az,hx,hy,hz: Double);
function VecCollect(ax,ay,az,hx,hy,hz: Double): TSensorVect;


implementation

function VecCollect(ax,ay,az,hx,hy,hz: Double): TSensorVect;
begin
  Result[sAcc].X := ax;
  Result[sAcc].Y := ay;
  Result[sAcc].z := az;
  Result[sMag].X := hx;
  Result[sMag].Y := hy;
  Result[sMag].z := hz;
end;

procedure VecExtract(vec: TSensorVect; var ax,ay,az,hx,hy,hz: Double);
begin
  ax := vec[sAcc].X;
  ay := vec[sAcc].Y;
  az := vec[sAcc].Z;
  hx := vec[sMag].X;
  hy := vec[sMag].Y;
  hz := vec[sMag].Z;
end;




{ TpolyMath }


class procedure TpolyMath.Init(pmA,pmH: PolyModel; Naklon: Double; Inp: TArray<TinclInput>);
 var
  pwt: Integer;
begin
  InpData.pmA := pmA;
  InpData.pmH := pmH;
  InpData.MNak := Naklon;
  InpData.Inpt := Inp;

  SetLength(acc, Length(inp));
  SetLength(mag, Length(inp));

  pwt := pmH.MaxPowT; if pmA.MaxPowT > pwt then pwt := pmA.MaxPowT;

  for var i := 0 to High(inp) do
   begin
    var at: TArray<Double>;
    at := pmA.CreatePowerT(Inp[i].t, pwt);
    acc[i] := pmA.CreateRow(at, Inp[i].G.V, SCALE_A);
    mag[i] := pmH.CreateRow(at, Inp[i].H.V, SCALE_H);
   end;
end;


class procedure TpolyMath.RunLsSensor(pm: PolyModel; data: TArray<RowModel>; sns: SetSetsor; var Res: TVArray<Double>);
 var
  e: IEquations;
  info: Integer;
  x: PDoubleArray;
  R2: Double;
  n: Integer;
  k: Integer;
  cx: IDoubleMatrix;
  aaa: TVArray<Double>;
  bbb: TVArray<Double>;
begin
  //for var i := 0 to 2 do SetLength(aaa[i], Length(acc)*InpData.pmA.KoeffCnt);
  for var i := 0 to High(data) do
   begin
    var a := pm.RowToArrays(data[i]);
    var b := InclRes[i].etaSens[sns].V;
    //var b := EtalonData[i][sns].V;
    for var vk in SVectors do
     begin
      aaa[vk] := aaa[vk] + a[vk];
      bbb[vk] := bbb[vk] + [b[Integer(vk)]];
     end;
   end;
  EquationsFactory(e);
  for var vk in SVectors do
   begin
    CheckMath(e, e.LinearLS(@aaa[vk][0], Length(data), pm.KoeffCnt, @bbb[vk][0], info, x, R2, n, k, cx));
    SetLength(Res[vk], pm.KoeffCnt);
    for var I := 0 to pm.KoeffCnt-1 do Res[vk][i] := x[i];
   end;
end;

class procedure TpolyMath.RunLsT(pm: PolyModel; idxs: TArray<Integer>; sns: SetSetsor; vec: SetVector; var Res: TArray<Double>);
 var
  e: IEquations;
  info: Integer;
  x: PDoubleArray;
  R2: Double;
  n: Integer;
  k: Integer;
  cx: IDoubleMatrix;
  row: Tarray<RowModel>;
  aa: TArray<Double>;
  bb: TArray<Double>;
  pax: Integer;
  function RowToArrays(r: RowModel): TArray<Double>;
   begin
     Result := r.axs[vec] + r.dzs;
   end;
begin
  aa := [];
  bb := [];
  if sns = sAcc then row := acc else row := mag;
  for var i in idxs do
   begin
    var a := RowToArrays(row[i]);
    var b := InclRes[i].etaSens[sns].V[Integer(vec)];
    aa := aa + a;
    bb := bb + [b];
   end;
   EquationsFactory(e);
   CheckMath(e, e.LinearLS(@aa[0], Length(idxs), pm.AxCnt + pm.DzCnt, @bb[0], info, x, R2, n, k, cx));
   SetLength(Res, pm.KoeffCnt);
   for var I := 0 to High(Res) do Res[i]:= 0;
   case vec of
     vX: pax := pm.pXX;
     vY: pax := pm.pYY;
     vZ: pax := pm.pZZ;
   end;
   for var I := 0 to pm.AxCnt-1 do Res[pax+i] := x[i];
   for var I := 0 to pm.DzCnt-1 do Res[pm.pD+i] := x[pm.AxCnt+i];
end;

class procedure TpolyMath.RunT;
 var
  arrz, arrx, arry: TArray<Integer>;
  hrrz, hrrx, hrry: TArray<Integer>;
//  Res: TArray<Double>;
begin
 var n := InpData.MNak;
 for var ix := 0 to High(InpData.Inpt) do
  begin
    var i := InpData.Inpt[ix];
    if (i.Zen < 1) or (i.Zen > 359) or (Abs(i.Zen-180)<1) then arrz := arrz + [ix];
    if (Abs(i.Zen-90)<1) then
     begin
      if (i.Vis < 2) or (i.Vis > 358) or (Abs(i.Vis-180) < 4) then arrx := arrx + [ix];
      if (Abs(i.Vis-90) < 2) or (Abs(i.Vis-270) < 2) then arry := arry + [ix];
      if (Abs(i.Azi-90)<1) then
       begin
        if (Abs(i.Vis-n) < 1) or (Abs(i.Vis-180-n) < 1) then hrrx := hrrx + [ix];
        if (Abs(i.Vis-n-90) < 1) or (Abs(i.Vis-270-n) < 1) then hrry := hrry + [ix];
       end;
      if (Abs(i.Azi-270)<1) then
       begin
        if (Abs(i.Vis+n) < 2) or(Abs((i.Vis+n-360)) < 2) or (Abs(i.Vis-180+n) < 2) then hrrx := hrrx + [ix];
        if (Abs(i.Vis+n-90) < 1) or (Abs(i.Vis-270+n) < 1) then hrry := hrry + [ix];
       end
     end;
    if (abs(i.Zen - n) < 1) or (Abs(i.Zen - n -180)<1) then hrrz := hrrz + [ix];
  end;
  RunLsT(InpData.pmA,arrx,sAcc,vX, Res.G[vX]);
  RunLsT(InpData.pmA,arry,sAcc,vY, Res.G[vY]);
  RunLsT(InpData.pmA,arrz,sAcc,vZ, Res.G[vZ]);
  RunLsT(InpData.pmH,hrrx,sMag,vX, Res.H[vX]);
  RunLsT(InpData.pmH,hrry,sMag,vY, Res.H[vY]);
  RunLsT(InpData.pmH,hrrz,sMag,vZ, Res.H[vZ]);

//  RunXYAndStolZ(arrz);
end;

//class procedure TpolyMath.RunXYAndStolZ(arz: TArray<Integer>);
// var
//  e: ILMFitting;
//  xout, kb: PDoubleArray;
//  Rep: PLMFittingReport;
//
//begin
//   SetLength(arz, 8);
//   LMFittingFactory(e);
//   CheckMath(e, e.FitV(4, Length(arz)*3, @kb, 0.000001, 0, 0, 0, 100000, func_cb_ZY_StolZ, xout, rep));
//end;

function ResToVarray(xout: PDoubleArray; KoeffCnt: integer): TVArray<Double>;
begin
   var n := 0;
   for var vk in SVectors do
    begin
     SetLength(Result[vk], KoeffCnt);
     for var I := 0 to KoeffCnt-1 do
      begin
       Result[vk][i] := xout[n]; Inc(n);
      end;
    end;
end;

class procedure TpolyMath.RunZ;
 var
  e: ILMFitting;
  xout: PDoubleArray;
  Rep: PLMFittingReport;
  bl,bh: TArray<Double>;
begin
   LMFittingFactory(e);
   var kb := Res.G[vx] + Res.G[vY]+ Res.G[vZ];
   var kc := InpData.pmA.KoeffCnt;
   var YxIdx := InpData.pmA.KyIdx;
   SetLength(bl,kc*3);
   SetLength(bh,kc*3);
   for var I := 0 to High(bl) do
    begin
     bl[i] := -Abs(kb[i]);
     bh[i] :=  Abs(kb[i]);
    end;
   bl[YxIdx] := kb[YxIdx];
   bh[YxIdx] := kb[YxIdx];


   CheckMath(e, e.FitVB(Length(kb), Length(acc)*2, @kb[0],@bl[0],@bh[0], 0.0000000001, 0, 0,0, 100000, func_cb_zen, xout, rep));
   Res.G := ResToVarray(xout, InpData.pmA.KoeffCnt);
end;

class procedure TpolyMath.RunLMSensor(pm: PolyModel; data: TArray<RowModel>; sns: SetSetsor; var Res: TVArray<Double>);
 var
  e: ILMFitting;
  xout: PDoubleArray;
  Rep: PLMFittingReport;
begin
  var YxIdx := pm.KyIdx;
  with LMAmpData do
  begin
   m:= pm;
   d := data;
   SetLength(bl,m.KoeffCnt*3);
   SetLength(bh,m.KoeffCnt*3);
   kBegin := Res[vx] + Res[vY]+ Res[vZ];
   for var I := 0 to High(bl) do
    begin
     bl[i] := -Abs(kBegin[i]*4);
     bh[i] :=  Abs(kBegin[i]*4);
    end;
   bl[YxIdx] := kBegin[YxIdx];
   bh[YxIdx] := kBegin[YxIdx];
   LMFittingFactory(e);
   CheckMath(e, e.FitVB(Length(kBegin), Length(d), @kBegin[0], @bl[0],@bh[0], 0.000001, 0, 0, 0, 10000, func_cb_amp, xout, rep));
   Res := ResToVarray(xout, m.KoeffCnt);
  end;
end;

class procedure TpolyMath.RunLS;
begin
  SetLength(InclRes, Length(InpData.Inpt));

  for var i := 0 to High(InpData.Inpt) do InclRes[i].etaSens := InpData.Inpt[i].VecEtalon(RES_AMP, InpData.MNak, eStol);
  RunLsSensor(InpData.pmA, acc, sAcc, Res.G);
  RunLsSensor(InpData.pmH, mag, sMag, Res.H);
end;

class procedure TpolyMath.RunAmp;
begin
  RunLMSensor(InpData.pmA, acc, sAcc, Res.G);
  RunLMSensor(InpData.pmH, mag, sMag, Res.H);
end;

class procedure TpolyMath.SetupKoso(Bl, bh: PFindLMKosStol);
begin
  bl^ := Default(TFindLMKosStol);
  bh^ := Default(TFindLMKosStol);
  for var i := 0 to TKosUgol.Length-1 do
   begin
    bl.kos[sAcc].V[i] := -1;
    bh.kos[sAcc].V[i] :=  1;
    bl.kos[sMag].V[i] := -1;
    bh.kos[sMag].V[i] :=  1;
   end;
  bh.kos[sAcc].Yx := 0;
  bl.kos[sAcc].Yx := 0;

  if SetupData.CorStolZenit then
   begin
    bl.StolError.cZenA := -0.2;
    bh.StolError.cZenA :=  0.2;
    bl.StolError.cZenAng := -90;
    bh.StolError.cZenAng :=  90;
   end;
  if SetupData.CorStolVisir then
   begin
    bl.StolError.cVis := -10;
    bh.StolError.cVis :=  10;
   end;

  if SetupData.CorStolMagnit then
   begin
    bl.StolError.cAzi := -1;
    bh.StolError.cAzi :=  1;

    bl.StolError.cNakl := -1;
    bh.StolError.cNakl :=  1;
   end;

end;


class procedure TpolyMath.KorrTVectors_int;
begin
  SetLength(KorrTVectors, Length(acc));
  for var i:= 0 to High(acc) do
   begin
     var r: TSensorVect;
     InpData.pmA.FindAxis(@Res.RowG[0], Acc[i], r[sAcc].X, r[sAcc].Y, r[sAcc].Z);
     InpData.pmH.FindAxis(@Res.RowH[0], Mag[i], r[sMag].X, r[sMag].Y, r[sMag].Z);
     KorrTVectors[i] := r;
   end;

end;

// k - 6+6 koso + 5 stol
// f zenErr, AziErr, AmpAer, ampHer Nakl;
class procedure TpolyMath.RunKoso;
 var
  bl,bh,kb: TFindLMKosStol;
  e: ILMFitting;
  xout: PDoubleArray;
  Rep: PLMFittingReport;
begin
  IsKosoV2 := False;
  SetupKoso(@Bl,@bh);

  KorrTVectors_int;

  kb := Default(TFindLMKosStol);

  LMFittingFactory(e);
  var lenk := SizeOf(TFindLMKosStol) div SizeOf(Double);
  var lenf := Length(InpData.Inpt)*6;
  CheckMath(e, e.FitVB(lenk, lenf, @kb, @bl, @bh, 0.0001, 0, 0, 0, 100000, func_cb_koso, xout, rep));

  KosRes := PFindLMKosStol(xout)^;
  eStol := KosRes.StolError;
end;

class procedure TpolyMath.RunKosoV2;
 var
  bl,bh,kb: TFindLMKosStolV2;
  e: ILMFitting;
  xout: PDoubleArray;
  Rep: PLMFittingReport;
begin
  SetLength(KorrTVectors, Length(acc));
  IsKosoV2 := True;

  SetupKoso(@Bl.ks,@bh.ks);

  Res.toArray(bl.t);
  Res.toArray(bh.t);
  for var I := 0 to Res.ArrayLen-1 do
   if i <> InpData.pmA.KyIdx then
   begin
    bl.t[i] := bl.t[i]-0.02;
    bh.t[i] := bh.t[i]+0.02;
   end;

  kb.ks := KosRes;// Default(TFindLMKosStol);
  Res.toArray(kb.t);

  LMFittingFactory(e);
  var lenk := SizeOf(TFindLMKosStol) div SizeOf(Double) + InpData.pmA.KoeffCnt*3 + InpData.pmH.KoeffCnt*3;
  var lenf := Length(InpData.Inpt)*6;
  CheckMath(e, e.FitVB(lenk, lenf, @kb, @bl, @bh, 0.00001, 0, 0, 0, 100000, func_cb_koso, xout, rep));

  KosRes := PFindLMKosStolV2(xout)^.ks;
  Res.fromArray(PFindLMKosStolV2(xout)^.t);
  eStol := KosRes.StolError;
//  KorrTVectors_int;
end;


class procedure TpolyMath.KosoFindInkl(ivec: Integer; const koso: TFindLMKosStol; var Incl: TInclRes);
 var
   ax, ay, az, x, y, z: Double;
begin

  VecExtract(KorrTVectors[ivec], ax, ay, az, x, y, z);
  koso.kos[sAcc].Find(ax, ay, az);
  koso.kos[sMag].Find(x, y, z);
  FindInclRes(VecCollect(ax, ay, az, x, y, z), koso.StolError, incl);
end;

class procedure TpolyMath.ClearStolError;
begin
  eStol := Default(TStolError);
end;

class procedure TpolyMath.FindInclRes(const vec: TSensorVect; const eS: TStolError; var Incl: TInclRes);
 var
  mo,hx,hy,hz,a,b,
  o,zu, os,oc,zs,zc,
  ax, ay, az, x, y, z: Double;
  sA,sZ,sO,sN: Double;
begin
  VecExtract(vec, ax, ay, az, x, y, z);

  o := Arctan2(ay, -ax);
  zu := Arctan2(Hypot(ax, ay), az);

  os := sin(o);
  oc := cos(o);
  zs := sin(zu);
  zc := cos(zu);

  Hx := (x*oc - y*os)*zc + z*zs;
  Hy :=  x*os + y*oc;
  Hz :=-(x*oc - y*os)*zs + z*zc;

  a := -Arctan2(Hy, Hx);
  b := Arctan2(Hypot(Hx, Hy), Hz);

  Incl.Amp[sAcc] := TXMLScriptMath.Hypot3D(ax, ay, az);
  Incl.Amp[sMag] := TXMLScriptMath.Hypot3D(x, y, z);
  Incl.MO := Arctan2(y, -x);
  Incl.zen := TXMLScriptMath.RadToDeg360(zu);
  Incl.otk := TXMLScriptMath.RadToDeg360(o);
  Incl.azi := TXMLScriptMath.RadToDeg360(a);
  Incl.Nakl := TXMLScriptMath.RadToDeg360(b);

  sA := Incl.inp.Azi;
  sZ := Incl.inp.Zen;
  sO := Incl.inp.Vis;
  sN := InpData.MNak;
  eS.Correct(sA,sZ,sO,sN);
  Incl.azi.CorStol := sA;
  Incl.zen.CorStol := sZ;
  Incl.otk.CorStol := sO;
  Incl.Nakl.CorStol := sN;

  Incl.Azi.Error := TAziStat.FindErr(incl);
  Incl.Zen.Error := TZenStat.FindErr(incl);
  Incl.Otk.Error := TotkStat.FindErr(incl);
  Incl.Nakl.Error := TInclStat.FindErr(incl);

  Incl.etaSens := Incl.inp.VecEtalon(RES_AMP,InpData.MNak, eS);

  Incl.trrSens[sAcc] := TVector3.Create(ax,ay,az);
  Incl.trrSens[sMag] := TVector3.Create(x,y,z);
  Incl.errSens[sAcc] := Incl.trrSens[sAcc] - Incl.etaSens[sAcc];
  Incl.errSens[sMag] := Incl.trrSens[sMag] - Incl.etaSens[sMag];

//  Incl.etaAmpH := RES_AMP * Inp.EtalonMag/1000;

  incl.erAmp[sAcc] := TAccStat.FindErr(incl);
  incl.erAmp[sMag] := TMagStat.FindErr(incl);
end;

class procedure TpolyMath.func_cb_amp(const k, f: PDoubleArray);
 var
  x,y,z: Double;
begin
  with LMAmpData do
  for var i := 0 to High(d) do
   begin
    m.FindAxis(k, d[i], x,y,z);
    f[i] := sqr(RES_AMP - TXMLScriptMath.Hypot3D(x,y,z));
   end;
end;


class procedure TpolyMath.func_cb_koso(const k, f: PDoubleArray);
  var
   zen: Double;
   vec: TSensorVect;
   Res: TInclRes;
begin
  with PFindLMKosStol(k)^ do
  for var i := 0 to High(InpData.Inpt) do
  begin
    if IsKosoV2 then
     with PFindLMKosStolV2(k)^ do
      begin
       InpData.pmA.FindAxisNoKoso(@t[0], Acc[i], vec[sAcc].X, vec[sAcc].Y, vec[sAcc].Z);
       InpData.pmH.FindAxisNoKoso(@t[InpData.pmA.KoeffCnt*3], Mag[i], vec[sMag].X, vec[sMag].Y, vec[sMag].Z);
      end
    else
     begin
      vec := KorrTVectors[i];
     end;

    kos[sAcc].Find(vec[sAcc].X,vec[sAcc].Y,vec[sAcc].Z);
    kos[sMag].Find(vec[sMag].X,vec[sMag].Y,vec[sMag].Z);

    Res.Inp := @InpData.Inpt[i];
    FindInclRes(vec, StolError, Res);
    f[i*6+0] := Sqr(Res.Zen.Error);
    f[i*6+1] := Res.erAmp[sAcc];
    f[i*6+2] := Res.erAmp[sMag];
    f[i*6+3] := Sqr(Res.Azi.Error);
    f[i*6+4] := Sqr(Res.Nakl.Error);
    f[i*6+5] := Sqr(Res.Otk.Error)/100;

    zen := Res.Zen;
    if Zen > 170 then zen := zen - 180;
    if Abs(zen) < 5 then
      begin
//       f[i*6+0] := 0;
       f[i*6+3] := 0;
       f[i*6+5] := 0;
      end;
  end;
end;

class procedure TpolyMath.func_cb_zen(const k, f: PDoubleArray);
begin
  with InpData do for var i := 0 to High(acc) do
   begin
    var x,y,z, dang: Double;
    pmA.FindAxis(k, acc[i], x,y,z);
    var zu := DegNormalize(RadToDeg(arctan2(Hypot(x, y), z)));
    if Inpt[i].Zen > 180 then
      dang := TMetrInclinMath.DeltaAngle(Zu-(360 - Inpt[i].Zen))
    else
      dang := TMetrInclinMath.DeltaAngle(Zu-Inpt[i].Zen);

    f[i*2] := sqr(dang);
    f[i*2+1] := sqr(RES_AMP - TXMLScriptMath.Hypot3D(x,y,z))*10;
   end;
end;


//class procedure TpolyMath.func_cb_ZY_StolZ(const k, f: PDoubleArray);
//begin
//
//end;


{ TPolyRes }

function TPolyRes.ArrayLen: Integer;
begin
  Result := Length(G[vX])*3 + Length(H[vX])*3;
end;

procedure TPolyRes.fromArray(r: array of Double);
begin
  var ka := TpolyMath.InpData.pmA.KoeffCnt;
  for var I := 0 to High(G[vX]) do
   begin
    G[vX][i] := r[i];
    G[vY][i] := r[ka+i];
    G[vZ][i] := r[ka*2+i];
   end;
  var kh := TpolyMath.InpData.pmh.KoeffCnt;
  for var I := 0 to High(G[vX]) do
   begin
    H[vX][i] := r[ka*3 + i];
    H[vY][i] := r[ka*3 + kh + i];
    H[vZ][i] := r[ka*3 + kh*2 + i];
   end;
end;

function TPolyRes.RowG: TArray<Double>;
begin
  Result := G[vx] + G[vY] + G[vz];
end;

function TPolyRes.RowH: TArray<Double>;
begin
  Result := H[vx] + H[vY] + H[vz];
end;

procedure TPolyRes.toArray(var r: array of Double);
 var
  idx: Integer;
begin
  idx := 0;
  for var k in RowG do
   begin
    r[idx] := k; inc(idx);
   end;
  for var k in  RowH do
   begin
    r[idx] := k; inc(idx);
   end;
end;

{ TFindLMKosStolv2 }

function TFindLMKosStolv2.Len: Integer;
begin
  Result := SizeOf(TFindLMKosStol) div SizeOf(Double) +
  TpolyMath.InpData.pmA.KoeffCnt*3 + TpolyMath.InpData.pmH.KoeffCnt*3;
end;

end.

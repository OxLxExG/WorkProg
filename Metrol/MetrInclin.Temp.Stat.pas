unit MetrInclin.Temp.Stat;

interface


uses math, Vector, LuaInclin.Math, tools, sysutils;


  const
   SCALE_A =7700;// 7000;
   SCALE_H =12000;// 14000;
   RES_AMP = 1;

type
  SetSetsor = (sAcc, sMag);
  TSensorData<T> = array[SetSetsor] of T;
  TSensorVect = TSensorData<TVector3>;

  // модель ошибок стола
   TStolError = record
    const Length = 5;
    procedure Correct(var a,z,v,i: Double);
     // cVis : косоугольность Yx -> 0;
    case Integer of
      0: (V: array[0..4]of Double;);
      1:
     (cVis,
     // ошибка по азимуту и по магнитному наклонению
     cAzi, cNakl: Double;

//  var corr := vizir*cos(DegToRad(zu)) + a;
//  zen_crrect := DegNormalize(zu + cZenA *Cos(DegToRad(corr - cZenAng)));
     cZenA, cZenAng: Double;)
   end;

  // копия XML файла  тарировки
  PinclInput = ^TinclInput;
  TinclInput = record
    SetNo: integer;
    Step: Integer;
    Info: string;
    // данные стола
    Azi,Zen,Vis: Double;
    EtalonMag: Double;
    // данные инклинометра
    T: double;
    G, H: TVector3;
    // конвертор данные стола в эталонные данные сенсоров
    function VecEtalon(const Amp, MagNaklon: Double; const eS: TStolError): TSensorVect;
    class operator Implicit(V: Variant): TinclInput;
  end;

  TinclTestInfo = record
  // прибор
    DevName, // название
    Serial, //  серийный номер
    Maker,  //  производитель
  // параметры метрологии
    UsedStol, // изпользуемое оборудование
    Category, // категория и принадлежность средства измерения
    Room,     // условия проверки
  // результат
    TestTime, //  время поверки
    Metrolog: string;  // кто проводил
    class operator Implicit(V: Variant): TinclTestInfo;
  end;

  // копия XML файла поверки
  PinclTest = ^TinclTest;
  TinclTest = record
    Step: Integer;
    Info: string;
    // данные стола
    Stol: record
     Azi, Zen, Vis: Double;
     EtalonMag: Double;
    end;
    // данные инклинометра
    Dev: record
     Azi, Zen, Vis: Double;

     G,H, MagNaklon: Double;

     T: double;
    end;
    // конвертор данные стола в эталонные данные сенсоров
    class operator Implicit(V: Variant): TinclTest;
  end;


  TAngRes = record
   CorStol: Double;
   Angle, Error: Double;
   class operator Implicit(Ang: Double): TAngRes;
   class operator Implicit(Ang: TAngRes): Double;
  end;

  TInclRes = record
    Inp: PinclInput;
    Azi, Zen, Otk, MO, Nakl: TAngRes;
    etaSens, trrSens, errSens: TSensorVect;
    Amp, erAmp: TSensorData<Double>;
  end;

  TeStat = class
   Pik, Av: Double;
   cnt: Integer;
   Step: Integer;
   Temp: Double;
   // данные стола
   Azi,Zen,Vis: Double;

   procedure Test(stNo: Integer; var Incl: TInclRes); virtual; abstract;
   procedure ApplyStat(ne: double; stNo: Integer; Incl: TInclRes);
   procedure SetAV;
   class function FindErr(Incl: TInclRes):Double; virtual; abstract;
  end;
  TAccStat = class(TeStat)
   procedure Test(stNo: Integer; var Incl: TInclRes); override;
   class function FindErr(Incl: TInclRes):Double; override;
  end;
  TMagStat = class(TeStat)
   procedure Test(stNo: Integer; var Incl: TInclRes); override;
   class function FindErr(Incl: TInclRes):Double; override;
  end;
  TInclStat = class(TeStat)
   procedure Test(stNo: Integer; var Incl: TInclRes); override;
   class function FindErr(Incl: TInclRes):Double; override;
  end;

  TotkStat = class(TeStat)
   procedure Test(stNo: Integer; var Incl: TInclRes); override;
   class function FindErr(Incl: TInclRes):Double; override;
  end;
  TZenStat = class(TeStat)
   procedure Test(stNo: Integer; var Incl: TInclRes); override;
   class function FindErr(Incl: TInclRes):Double; override;
  end;
  TAziStat = class(TeStat)
   procedure Test(stNo: Integer; var Incl: TInclRes); override;
   class function FindErr(Incl: TInclRes):Double; override;
  end;

implementation

{ TAngRes }

class operator TAngRes.Implicit(Ang: Double): TAngRes;
begin
  Result.Angle := Ang;
  Result.Error := 0;
  Result.CorStol := 0;
end;

class operator TAngRes.Implicit(Ang: TAngRes): Double;
begin
  Result := Ang.Angle;
end;


{ TAziStat }

class function TAziStat.FindErr(Incl: TInclRes): Double;
 var
  azi,zen: Double;
begin

//    a:= 181; z := 360- 200; o := 180;
//    a:= 1; z := 200; o := 0;

  azi := Incl.azi;
  zen := Incl.zen;

  if Incl.zen.CorStol > 180 then
   begin
    azi := DegNormalize(azi + 180);
   end;
   Result := TMetrInclinMath.DeltaAngle(azi - Incl.Azi.CorStol);
end;

procedure TAziStat.Test(stNo: Integer; var Incl: TInclRes);
 var
  zen: Double;
begin
  zen := Incl.zen;

  Incl.azi.Error := FindErr(Incl);

  if Zen > 170 then zen := zen - 180;
  if Abs(zen) > 5 then ApplyStat(Incl.azi.Error, stno, Incl);
end;

{ TotkStat }

class function TotkStat.FindErr(Incl: TInclRes): Double;
var
 otk,zen: Double;
begin
  otk := Incl.otk;
  zen := Incl.zen;

  if Incl.zen.CorStol > 190 then
   begin
    otk := DegNormalize(otk+180);
   end;

  Result := TMetrInclinMath.DeltaAngle(otk - Incl.otk.CorStol);
end;

procedure TotkStat.Test(stNo: Integer; var Incl: TInclRes);
var
 zen: Double;
begin
  zen := Incl.zen;

  Incl.otk.Error :=  FindErr(Incl);

  if Zen > 170 then zen := zen - 180;
  if Abs(zen) > 5 then ApplyStat(Incl.otk.Error, stno, Incl);
end;

{ TZenStat }

class function TZenStat.FindErr(Incl: TInclRes): Double;
var
 zen: Double;
begin
  zen := incl.zen;
  if incl.zen.CorStol > 180 then Result := TMetrInclinMath.DeltaAngle(zen -(360 - incl.zen.CorStol))
  else Result := TMetrInclinMath.DeltaAngle(zen - incl.zen.CorStol);
end;

procedure TZenStat.Test(stNo: Integer; var Incl: TInclRes);
begin
  Incl.zen.Error :=  FindErr(Incl);
  ApplyStat(Incl.zen.Error, stno, Incl);
end;

{ TAngleStat }

procedure TeStat.ApplyStat(ne: double; stNo: Integer; Incl: TInclRes);
begin
  av := av + Abs(ne);
  Inc(cnt);
  if Abs(Pik)  < Abs(ne) then
  begin
   Pik := ne;
   Step := stNo;
   Temp := Incl.Inp.T;
   Azi := Incl.Inp.Azi;
   Zen := Incl.Inp.Zen;
   Vis := Incl.Inp.Vis;
  end;
end;

procedure TeStat.SetAV;
begin
  av:= Av/cnt;
end;

{ TAccStat }

class function TAccStat.FindErr(Incl: TInclRes): Double;
begin
  Result := Incl.Amp[sAcc] - RES_AMP;
end;

procedure TAccStat.Test(stNo: Integer; var Incl: TInclRes);
begin
   Incl.erAmp[sAcc] := FindErr(Incl);
   ApplyStat(Incl.erAmp[sAcc], stno, Incl);
end;

{ TMagStat }

class function TMagStat.FindErr(Incl: TInclRes): Double;
begin
  Result := Incl.Amp[sMag] - RES_AMP * Incl.Inp.EtalonMag/1000;
end;

procedure TMagStat.Test(stNo: Integer; var Incl: TInclRes);
begin
  Incl.erAmp[sMag] := FindErr(Incl);
  ApplyStat(Incl.erAmp[sMag], stno, Incl);
end;

{ TMaklStat }

class function TInclStat.FindErr(Incl: TInclRes): Double;
begin
  Result := Incl.Nakl.Angle - Incl.Nakl.CorStol;
end;

procedure TInclStat.Test(stNo: Integer; var Incl: TInclRes);
begin
  Incl.Nakl.Error := FindErr(Incl);
  ApplyStat(Incl.Nakl.Error, stno, Incl);
end;

{ TStolError }

procedure TStolError.Correct(var a, z, v, i: Double);
begin

  var corr := v*cos(DegToRad(z)) + a;
  z := DegNormalize(z + cZenA *Cos(DegToRad(corr - cZenAng)));

  a := DegNormalize(a + cAzi);
  v := DegNormalize(v + cVis);
  i := DegNormalize(i + cNakl);
end;

{ TinclInput }

function TinclInput.VecEtalon(const Amp, MagNaklon: Double; const eS: TStolError): TSensorVect;
 var
  co, so: Double;
  cz, sz: Double;
  ca, sa: Double;
  ci, si: Double;
  A,Z,O,N, AmpH: Double;
begin
  AmpH := Amp*EtalonMag/1000;

  A := Azi;
  Z := Zen;
  O := Vis;
  N := MagNaklon;

  eS.Correct(A,Z,O,N);

  so := Sin(DegToRad(O));
  co := Cos(DegToRad(O));
  sz := Sin(DegToRad(Z));
  cz := Cos(DegToRad(Z));
  sa := Sin(DegToRad(A));
  ca := Cos(DegToRad(A));
  N := 90 - (N);
  si := Sin(DegToRad(N));
  ci := Cos(DegToRad(N));
  Result[sMag].X := -AmpH*(ci*(sa*so - ca*co*cz) + co*si*sz);
  Result[sMag].Y := -AmpH*(ci*(co*sa + ca*cz*so) - si*so*sz);
  Result[sMag].Z :=  AmpH*(cz*si + ca*ci*sz);
  Result[sAcc].X := -Amp*co*sz;
  Result[sAcc].Y :=  Amp*so*sz;
  Result[sAcc].Z :=  Amp*cz;
end;


class operator TinclTestInfo.Implicit(V: Variant): TinclTestInfo;
begin
  Result.DevName := V.DevName;
  try
    Result.Serial := TVxmlData(V).Node.ParentNode.ParentNode.ParentNode.Attributes[AT_SERIAL];
  except
    Result.Serial := '1';
  end;
  Result.Maker := V.Maker;
  Result.UsedStol:= V.UsedStol;
  Result.Category:= V.Category;
  Result.Room:= V.Room;
  Result.TestTime:= V.TIME_ATT;
  Result.Metrolog:= V.Metrolog;
end;

class operator TinclTest.Implicit(V: Variant): TinclTest;
begin
  Result.Step := v.STEP;
  Result.Info := v.INFO;
  Result.Stol.Azi :=  v.СТОЛ.азимут;
  Result.Stol.Zen :=  v.СТОЛ.зенит;
  var n := TVxmlData(v.СТОЛ).Node;
  if n.HasAttribute('визир') then Result.Stol.Vis := v.СТОЛ.визир;
  if n.HasAttribute('амплит_magnit') then Result.Stol.EtalonMag := v.СТОЛ.амплит_magnit
  else Result.Stol.EtalonMag := 1000;
  Result.Dev.Azi := V.азимут.DEV.VALUE;
  Result.Dev.Zen := V.зенит.DEV.VALUE;
  Result.Dev.Vis := V.отклонитель.DEV.VALUE;
  Result.Dev.MagNaklon := V.маг_наклон.DEV.VALUE;
  Result.Dev.G := V.амплит_accel.DEV.VALUE;
  Result.Dev.H := V.амплит_magnit.DEV.VALUE;
  try
   Result.Dev.T := v.T.DEV.VALUE;
  except
   Result.Dev.T := 32;
  end;
end;


class operator TinclInput.Implicit(V: Variant): TinclInput;
begin
  Result.Step := v.STEP;
  Result.Info := v.INFO;
  Result.G.X := v.accel.X.DEV.VALUE;
  Result.G.y := v.accel.Y.DEV.VALUE;
  Result.G.z := v.accel.Z.DEV.VALUE;
  Result.h.x := v.magnit.X.DEV.VALUE;
  Result.h.y := v.magnit.Y.DEV.VALUE;
  Result.h.z := v.magnit.Z.DEV.VALUE;
  Result.Azi :=  v.СТОЛ.азимут;
  Result.Zen :=  v.СТОЛ.зенит;
  var n := TVxmlData(v.СТОЛ).Node;
  if n.HasAttribute('визир') then Result.Vis := v.СТОЛ.визир;
  if n.HasAttribute('амплит_magnit') then Result.EtalonMag := v.СТОЛ.амплит_magnit
  else Result.EtalonMag := 1000;
  var inf: string := string(v.INFO)[2];
  Result.SetNo :=  StrToInt(inf)-1;


//  try
//   Result.EtalonMag := v.СТОЛ.амплит_magnit;
//  except
//    v.СТОЛ.амплит_magnit := 1000;
//    Result.EtalonMag := 1000;
//  end;
  try
   Result.T := v.T.DEV.VALUE;
  except
   Result.T := 32;
  end;
end;

end.

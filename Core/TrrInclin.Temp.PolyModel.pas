unit TrrInclin.Temp.PolyModel;

interface

uses   System.SysUtils,
 Vector, MathIntf;

  type SetVector = (vX, vY, vZ);
  const SVectors = [vX, vY, vZ];//  set of SetVector
  const SVectorsNames:  array [SetVector] of Char = ('X','Y','Z');

type
  TVArray<T> = array [SetVector] of TArray<T>;

  // Вариант
  //  Xl = kX*(1+k1t+ k2tt..)+k2XX*(1+kt+ ktt..) + k*(1+kt+ktt);
  //  Xku = Xl+kuy*Yl+kuz*Zl;
  RowModel = record
   axs: TVArray<Double>;
   kus: TVArray<Double>;
   dzs: TArray<Double>;
  end;

  TKosUgol = record
    const Length = 6;
    procedure Find(var x,y,z: Double);
    case Integer of
      0: (V: array[0..5]of Double;);
      1:
      (Xy,Xz,
      Yx,Yz,
      Zx,Zy: Double;);
  end;


  PolyModel = record
   //              AX                                     KU                                    DZ
   // x := kX*(1+k1t+ k2tt..)+k2XX*(1+kt+ ktt..) +kY*(1+kt+ ktt..)+k2YY*(1+kt+ ktt..) ... + k*(1+kt+ktt)
   // Power T array
   // если x = kx to длина ax = 1
   // если x = kx+kXX to длина ax = 2
   ax: TArray<Integer>;
   // как правило меньше ао длине и по значениям
   ku: TArray<Integer>;
   // Power T DZ;
   dz: Integer;
   function KoeffCnt():Integer;
   function DzCnt(): Integer;
   function AxCnt(): Integer;
   function KuCnt(): Integer;
   function KxIdx(): Integer;
   function KyIdx(): Integer;
   function KzIdx(): Integer;
   function pXX: Integer;function pXy: Integer;function pXz: Integer;
   function pYx: Integer;function pYY: Integer;function pYz: Integer;
   function pZx: Integer;function pZY: Integer;function pZZ: Integer;
   function pD: Integer;
   function MaxPowT: Integer;
   function KoefToKoso(const k : PDoubleArray): TKosUgol;
   function RowToArrays(r: RowModel): TVArray<Double>;
   function CreatePowerT(t: Double; tPpow: Integer): TArray<Double>;
   function CreateRow(art,axies: TArray<Double>; scale: Double = 1): RowModel;overload;
   function CreateRow(art: TArray<Double>; axies: TVector3Array; scale: Double = 1): RowModel;overload;
   procedure FindAxis(const k : PDoubleArray; const rm : RowModel;  var x,y,z: Double);overload;
   procedure FindAxis(const k, rm : PDoubleArray; var x,y,z: Double); overload;
   procedure FindAxisNoKoso(const k : PDoubleArray; const rm : RowModel;  var x,y,z: Double);overload;
   procedure FindAxisKoso(const k : PDoubleArray; const rm : RowModel;  var x,y,z: Double);overload;
   procedure FindAxisKoso(const k, rm : PDoubleArray; var x,y,z: Double); overload;
   class operator Implicit(const s: string): PolyModel;
  end;


implementation

{ TKosUgol }

procedure TKosUgol.Find(var x, y, z: Double);
 var
  cx,cy,cz: Double;
begin
  cx := x;
  cy := y;
  cz := z;
  x := cx + Xy*cy + Xz*cz;
  y := Yx*cx + cy + Yz*cz;
  z := Zx*cx + Zy*cy + cz;
end;


{$REGION 'PolyModel'}

{ PolyModel }

function PolyModel.AxCnt: Integer;
begin
  Result := 0;
  for var a in ax do Inc(Result, 1+a);
end;
function PolyModel.KuCnt: Integer;
begin
  Result := 0;
  for var k in ku do Inc(Result, 1+k);
end;
function PolyModel.DzCnt: Integer;
begin
  Result := 1+dz;
end;
function PolyModel.KoeffCnt: Integer;
begin
  Result := AxCnt + DzCnt + 2*KuCnt;
end;

function PolyModel.KoefToKoso(const k: PDoubleArray): TKosUgol;
begin
  Result.Xy := k[pXy];
  Result.Xz := k[pXz];
  Result.Yx := k[KyIdx+pYx];
  Result.Yz := k[KyIdx+pYz];
  Result.Zx := k[KzIdx+pZx];
  Result.Zy := k[KzIdx+pZy];
end;

function PolyModel.KxIdx: Integer;
begin
  Result := 0;
end;
function PolyModel.KyIdx: Integer;
begin
  Result := KoeffCnt;
end;
function PolyModel.KzIdx: Integer;
begin
  Result := KoeffCnt*2;
end;

function PolyModel.pD: Integer;
begin
  Result := AxCnt + 2*KuCnt;
end;

function PolyModel.pXX: Integer;
begin
  Result := 0;
end;

function PolyModel.pXy: Integer;
begin
  Result := AxCnt;
end;

function PolyModel.pXz: Integer;
begin
  Result := AxCnt + KuCnt;
end;

function PolyModel.pYx: Integer;
begin
  Result := 0;
end;

function PolyModel.pYY: Integer;
begin
  Result := KuCnt;
end;

function PolyModel.pYz: Integer;
begin
  Result := AxCnt + KuCnt;
end;

function PolyModel.pZx: Integer;
begin
  Result := 0;
end;

function PolyModel.pZY: Integer;
begin
  Result := KuCnt;
end;

function PolyModel.pZZ: Integer;
begin
  Result := 2*KuCnt;
end;

function PolyModel.MaxPowT: Integer;
begin
  Result := dz;
  for var a in ax do if a > Result then Result := a;
  for var k in ku do if k > Result then Result := k;
end;

function PolyModel.RowToArrays(r: RowModel): TVArray<Double>;
begin
//       rm  := axs[0] + kus[1]+ kus[2] + dzs[0] +
//              kus[0] + axs[1]+ kus[2] + dzs[1] +
//              kus[0] + kus[1]+ axs[2] + dzs[2] ;
  with r do
   begin
     Result[vX] := axs[vX] + kus[vY]+ kus[vZ] + dzs;
     Result[vY] := kus[vX] + axs[vY]+ kus[vZ] + dzs;
     Result[vZ] := kus[vX] + kus[vY]+ axs[vZ] + dzs;
   end;
end;

function PolyModel.CreatePowerT(t: Double; tPpow: Integer): TArray<Double>;
begin
  Result := [1];
  if tPpow = 0 then Exit;
  // T model 1,t,tt,ttt,...
  // Тр температука для расчетов
  // все температурные коэфф = 0 при 25 Тр = 0 градусах  125 град = Тр = 1
  Result := [1, (t-25)/100];
   for var i := 2 to tPpow do
      Result := Result + [Result[1]*Result[i-1]];
end;

function PolyModel.CreateRow(art, axies: TArray<Double>; scale: Double): RowModel;
  function ModelFind(axis: Double; modelT: TArray<Integer>):TArray<Double>;
  begin
     var cura := axis;
     Result := [];
     for var nt in modelT do
      begin
       for var i := 0 to nt do Result := Result +[cura * art[i]];
       cura := cura*axis;
      end;
  end;
begin
  with Result do
   begin
    for var v in SVectors do
     begin
      axs[v] := ModelFind(axies[Integer(v)]/scale, ax);
      kus[v] := ModelFind(axies[Integer(v)]/scale, ku);
     end;
    dzs := ModelFind(1,     [dz]);
   end;
end;

function PolyModel.CreateRow(art: TArray<Double>; axies: TVector3Array; scale: Double = 1): RowModel;
begin
  Result := CreateRow(art, [axies[0],axies[1],axies[2]],scale)
end;

procedure PolyModel.FindAxis(const k, rm: PDoubleArray; var x, y, z: Double);
//       rm  := axs[0] + kus[1]+ kus[2] + dzs[0] +
//              kus[0] + axs[1]+ kus[2] + dzs[1] +
//              kus[0] + kus[1]+ axs[2] + dzs[2] ;
//       from row model
 function fa(axisidx: Integer): Double;
 begin
   Result := 0;
   for var i := 0 to KoeffCnt-1 do
     Result := Result +k[axisidx+i]*rm[axisidx+i];
 end;
begin
//  if k[KyIdx] = 0 then FindAxisKoso(k, rm, x, y, z)
//  else
   begin
    x := fa(KxIdx);
    y := fa(KyIdx);
    z := fa(KzIdx);
  end;
end;

procedure PolyModel.FindAxisKoso(const k: PDoubleArray; const rm: RowModel; var x, y, z: Double);
 function FindA(Axi: SetVector; ki: Integer): Double;
 begin
   Result := 0;
   for var i := 0 to AxCnt-1 do
        Result := Result + rm.axs[axi][i]*k[ki+i];
 end;
 function FindD(ki: Integer): Double;
 begin
   Result := 0;
   for var i := 0 to DzCnt-1 do
        Result := Result + rm.dzs[i]*k[ki+i];
 end;
begin
  x := FindA(vX,KxIdx) + FindD(KxIdx+pD);
  y := FindA(vY, KyIdx+pYY) + FindD(KyIdx+pD);
  z := FindA(vZ, KzIdx+pZZ) + FindD(KzIdx+pD);
  var koso := KoefToKoso(k);
  koso.Find(x,y,z);
end;

procedure PolyModel.FindAxisKoso(const k, rm: PDoubleArray; var x, y, z: Double);
 function FindA(Axi: Integer): Double;
 begin
   Result := 0;
   for var i := 0 to AxCnt-1 do
        Result := Result + rm[axi+i]*k[axi+i];
 end;
 function FindD(ki: Integer): Double;
 begin
   Result := 0;
   for var i := 0 to DzCnt-1 do
        Result := Result + rm[ki+i]*k[ki+i];
 end;
begin
  x := FindA(KxIdx+pXX) + FindD(KxIdx+pD);
  y := FindA(KyIdx+pYY) + FindD(KyIdx+pD);
  z := FindA(KzIdx+pZZ) + FindD(KzIdx+pD);
  var koso := KoefToKoso(k);
  koso.Find(x,y,z);
end;


procedure PolyModel.FindAxisNoKoso(const k: PDoubleArray; const rm: RowModel; var x, y, z: Double);
 function FindA(Axi: SetVector; ki: Integer): Double;
 begin
   Result := 0;
   for var i := 0 to AxCnt-1 do
        Result := Result + rm.axs[axi][i]*k[ki+i];
 end;
 function FindD(ki: Integer): Double;
 begin
   Result := 0;
   for var i := 0 to DzCnt-1 do
        Result := Result + rm.dzs[i]*k[ki+i];
 end;
begin
  x := FindA(vX,KxIdx) + FindD(KxIdx+pD);
  y := FindA(vY, KyIdx+pYY) + FindD(KyIdx+pD);
  z := FindA(vZ, KzIdx+pZZ) + FindD(KzIdx+pD);
end;

procedure PolyModel.FindAxis(const k: PDoubleArray; const rm: RowModel; var x, y, z: Double);
 function FindK(Axi: SetVector; ki: Integer): Double;
 begin
   Result := 0;
   for var i := 0 to KuCnt-1 do
        Result := Result + rm.kus[axi][i]*k[ki+i];
 end;
 function FindA(Axi: SetVector; ki: Integer): Double;
 begin
   Result := 0;
   for var i := 0 to AxCnt-1 do
        Result := Result + rm.axs[axi][i]*k[ki+i];
 end;
 function FindD(ki: Integer): Double;
 begin
   Result := 0;
   for var i := 0 to DzCnt-1 do
        Result := Result + rm.dzs[i]*k[ki+i];
 end;
begin
//  if k[KyIdx] = 0 then FindAxisKoso(k, rm, x, y, z)
//  else
   begin
    x := FindA(vX,KxIdx) + FindK(vY, KxIdx+pXy) + FindK(vZ, KxIdx+pXz) + FindD(KxIdx+pD);
    y := FindK(vX,KyIdx) + FindA(vY, KyIdx+pYY) + FindK(vZ, KyIdx+pYz) + FindD(KyIdx+pD);
    z := FindK(vX,KzIdx) + FindK(vY, KzIdx+pZy) + FindA(vZ, KzIdx+pZZ) + FindD(KzIdx+pD);
  end
end;

class operator PolyModel.Implicit(const s: string): PolyModel;
 function s2i(const a: string): TArray<Integer>;
 begin
   Result := [];
   for var i:= 1 to Length(a) do Result := Result + [string(a[i]).ToInteger];
 end;
begin
  var sa :=  s.Split([';',' ',','], TStringSplitOptions.ExcludeEmpty);
  Result.ax := s2i(sa[0]);
  if Length(sa)>0 then  Result.ku := s2i(sa[1]) else      Result.ku := [0];
  if Length(sa)>1 then  Result.dz := sa[2].ToInteger else Result.dz := 2;
end;

{$ENDREGION PolyModel}

end.

unit PID;

interface

uses
  MathIntf, math, System.SysUtils;

type
  TPidPoint = record
    time: TTime;
    inp: Double;
    outp: Double;
  end;

  Tpid = class
  private
    A0, A1, A0d, A1d, A2d: Double;

    error: array[0..2] of Double;

    tau, alpha: Double;
    d0, d1, fd0, fd1: Double;

    Kp, Ki, Kd, dt, u0, Foutput: Double;

    N: Integer;
    FSetpoint: Double;
  public
    constructor Create(AKp, AKi, AKd, Adt, Au0: Double);
    procedure Run(measured_value: Double);
    property Setpoint: Double read FSetpoint write FSetpoint;
    property output: Double read Foutput;
  end;

/// <summary>
/// вторая производная гладкой функции по 9ти точкам
///  Симметричные коэффициенты
/// </summary>
/// <param name="ym4">Y(x0-4h)</param>
/// <param name="ym3">Y(x0-3h)</param>
/// <param name="ym2">Y(x0-2h)</param>
/// <param name="ym1">Y(x0-1h)</param>
/// <param name="y0">Y(x0)</param>
/// <param name="y1">Y(x0+1h)</param>
/// <param name="y2">Y(x0+2h)</param>
/// <param name="y3">Y(x0+3h)</param>
/// <param name="y4">Y(x0+4h)</param>
/// <param name="h">шаг дискретизации</param>
/// <returns>
/// вторая производная
/// </returns>
function dir2x9(y0: PDouble; h: Double = 1): Double;
/// <summary>
/// первая производная гладкой функции по 9ти точкам
///  Симметричные коэффициенты
/// </summary>
/// <param name="y0">указатель на центральную точку</param>
/// <param name="h">шаг дискретизации</param>
/// <returns>первая производная</returns>

function dir1x9(y0: PDouble; h: Double = 1): Double;

function dir2xy9(y, x: PDoubleArray): Double;

procedure ddY(const [Ref] y: TArray<Double>; h, scale: Double; Dshag, Nsred, Nsredy: Integer; var dd: TArray<Double>; Dy: Boolean = false);

procedure Resample(const [Ref] x, y, newX: TArray<Double>; var newY: TArray<Double>);

procedure PID_ZieglerNichols(const [Ref] x, y, dy, ddy: TArray<Double>; scaleD, scaleDD: Double; off, onn, stab: TPidPoint; var output: TArray<Double>;
var Kp, Ki, Kd: Double; IsCin: Boolean = false);

type pidMethod = (CohenCoon, lambda, coon);
procedure PID_CohenCoon(const [Ref] x, y, dy, ddy: TArray<Double>; scaleD, scaleDD: Double; off, onn, stab: TPidPoint; var output: TArray<Double>; var Kp, Ki, Kd: Double; Method: pidMethod = CohenCoon);

implementation

procedure GetS(const [Ref] x, y, dy, ddy: TArray<Double>; scaleD, scaleDD: Double; Y_out0, Y_outEnd: Double; out tL,tT,
dY_at_ddY0, d_at_ddY0: Double);
var
  index_ddY0: Integer;
  X_at_ddY0: Double;
  Y_at_ddY0: Double;
begin
  index_ddY0 := 0;
  for var i := 0 to High(y) do
  begin
    if ddy[i] < 0 then
    begin
      index_ddY0 := i - 1; //tst
      X_at_ddY0 := x[i - 1] + (x[i] - x[i - 1]) * (0 - ddy[i - 1]) / (ddy[i] - ddy[i - 1]);
      var dx := (X_at_ddY0 - x[i - 1]) / (x[i] - x[i - 1]);
      dY_at_ddY0 := (dy[i - 1] + dx * (dy[i] - dy[i - 1])) / scaleD;
     // dyex := (y[i] - y[i - 1]) / (x[i] - x[i - 1]); //tst
      Y_at_ddY0 := y[i - 1] + dx * (y[i] - y[i - 1]);
      d_at_ddY0 := Y_at_ddY0 - dY_at_ddY0 * X_at_ddY0;
      tL := (Y_out0 - d_at_ddY0) / dY_at_ddY0;
      tT := (Y_outEnd - d_at_ddY0) / dY_at_ddY0;
      Break;
    end;
  end;
end;

type
 TAperiodZveno2 = class
  private
    class var _k, _Y0, _X0: Double;
    class var M,N0: Integer;

    class var x, y: TArray<Double>;
    class procedure cb_func(const t, f: PDoubleArray); static; cdecl;
  public
   class var T1, T2, Td: Double;
    class var output: TArray<Double>;
   class procedure Run(const [Ref] ax, ay: TArray<Double>;
                              off, onn, stab: TPidPoint); static;
 end;

{ TAperiodZveno2 }

class procedure TAperiodZveno2.cb_func(const t, f: PDoubleArray);
begin
  for var i := 0 to M-1 do
   begin
      var T1 := t[0];
      var T2 := t[1];
      var Td := t[2];
      _K := t[3];

      var tm := x[i+N0]-_X0-Td;
      if T1 <> T2 then f[i] :=( _Y0 + _K * (1 - T1/(T1-T2)*Exp(-tm/T1) + T2/(T1-T2)*Exp(-tm/T2)) - Y[i+N0])
      else f[i] := 1000000;
   end;

end;

class procedure TAperiodZveno2.Run(const [Ref] ax, ay: TArray<Double>; off, onn, stab: TPidPoint);
 var
  lm: ILMFitting;
  tLo,tHi, tBegin:TArray<Double>;
  tOut: PDoubleArray;
  rep: PLMFittingReport;
  Tdmax: Double;
begin
  _X0 := (onn.time + off.time) / 2;
  _Y0 := (onn.outp + off.outp) / 2;
  _k := (stab.outp - _Y0);

  x := Ax;
  y := ay;

  for var i := 0 to High(x) do if x[i]>=onn.time then
   begin
    N0 := i;
    Break;
   end;
  for var i := 0 to High(x) do if x[i]>=stab.time then
   begin
    M := i - N0 + 1;
    Break;
   end;
  for var i := 0 to High(y) do if (y[0]+1) <= y[i] then
   begin
    Tdmax := x[i-1] - _X0;
    Break;
   end;

  var st := stab.time-_X0;
  tBegin := [st/2, st/3, 0, _k];

  tLo := [Tdmax, Tdmax,  0  , _k-3];
  tHi := [st,    st,   Tdmax/2, _k+3];


  LMFittingFactory(lm);
//    function FitVB(n, m: Integer; const xin, bndL, bndU: PDoubleArray;
//    const diffstep, epsg, epsf, epsx: Double; const maxits: Integer;
//    func: TLMFittingCB; out xout: PDoubleArray; out Rep: PLMFittingReport): HRESULT; stdcall;

  CheckMath(lm, lm.FitVB(4,M,@tBegin[0], @tLo[0],@tHi[0],
                         0.001,
                         0.01, 0.01, 0.01,
                         1000000,
                         cb_func,
                          tOut,
                          rep));

  T1 := tOut[0];
  T2 := tOut[1];
  Td := tOut[2];
  _k := tOut[3];

  SetLength(output, Length(x));
  for var i := 0 to High(output) do
   begin
    var tm := x[i]-_X0-Td;
    output[i] := _Y0 + _k * (1 - T1/(T1-T2)*Exp(-tm/T1) + T2/(T1-T2)*Exp(-tm/T2))
   end;


end;

type TampOpti = class
 public
  a1,a2,tay,k: Double;
  A: array[0..5] of Double;
  kp,ki,kd: Double;
  function geta(idx: Integer): Double;
  function getmtxA(idx: Integer): Double;
  constructor Create(aa1,aa2,atay,ak: Double);
end;

{ TampOpti }

constructor TampOpti.Create(aa1, aa2, atay, ak: Double);
 var
  e: IEquations;
  ma: array[0..2,0..2]of Double;
  b: array[0..2]of Double;
  inf: Integer;
  x: PDoubleArray;
begin
  a1 := aa1;
  a2 := aa2;
  tay := atay;
  k   := ak;
  for var i := 0 to 5 do a[i] := getmtxA(i);

  EquationsFactory(e);

  ma[0,0]:= -a[1]; ma[0,1]:= a[0];  ma[0,2]:= 0;
  ma[1,0]:= -a[3]; ma[1,1]:= -a[2]; ma[1,2]:= -a[1];
  ma[2,0]:= -a[5]; ma[2,1]:= a[4];  ma[2,2]:= -A[3];

  b[0]:= -0.5;
  b[1]:= 0;
  b[2]:= 0;
  CheckMath(e, e.Linear(@A, 3, @B, inf, x));

  kp := x[0];
  ki := x[1];
  kd := x[2];

end;

function TampOpti.geta(idx: Integer): Double;
begin
   if idx = 0 then exit(1)
   else if idx = 1 then  exit(a1)
   else if idx = 2 then  exit(a2)
   else Exit(0);
end;

function FacIterative(n: Word): Integer;
var
  f: Integer;
  i: Integer;
begin
  f := 1;
  for i := 2 to n do
    f := f * i;
  Result := f;
end;

function TampOpti.getmtxA(idx: Integer): Double;
begin
   if idx = 0 then Exit(k)
   else if idx = 1 then  exit(k * (a1 + tay))
   else if idx = 2 then  exit(K*(-a2+(tay*tay)/(1*2)) + getmtxA(1)*a1)
   else
    begin
     Result := K*IntPower(tay, idx)/FacIterative(idx);
     for var i := 1 to idx-1 do Result := Result + IntPower(-1, idx+i-1)*getmtxA(i)*geta(idx-i)
    end;
end;



procedure PID_CohenCoon(const [Ref] x, y, dy, ddy: TArray<Double>; scaleD, scaleDD: Double; off, onn, stab: TPidPoint;
                        var output: TArray<Double>;
                        var Kp, Ki, Kd: Double; Method: pidMethod);
var
  t0,t1,t2,tTau,tdel,tau,ti,td: Double;
  A,B,K,r: Double;

  dInp: Double;
  tOnn: Double;
  Y_out0, Y_outEnd: Double;
  tL, tT: Double;
  L, T: Double;
  X_at_ddY0: Double;
  dY_at_ddY0, Y_at_ddY0, d_at_ddY0, dyex: Double;

  idxT2,idxtTau: Integer;
  function FindT23(yt: Double; out idx: Integer):Double;
  begin
    Result := 0;
    idx := 0;
    for var i := 0 to High(y) do if y[i] >= yt then
     begin
      var i1 := i-1;
      var i2 := i;
      idx := i;
      Result := x[i1]+(yt-y[i1])*(x[i2]-x[i1])/(y[i2]-y[i1]);
      exit;
     end;
  end;
begin
  dInp := onn.inp - off.inp;
  tOnn := (onn.time + off.time) / 2;
  Y_out0 := (onn.outp + off.outp) / 2;
  Y_outEnd := stab.outp;
  GetS(x, y, dy, ddy, scaleD, scaleDD, Y_out0, Y_outEnd,tL,tT, dY_at_ddY0, d_at_ddY0);

  TAperiodZveno2.Run(x,y, off, onn, stab);

  t1 := TAperiodZveno2.T1 + TAperiodZveno2._X0;
  t2 := TAperiodZveno2.T2 + TAperiodZveno2._X0;
  tdel := TAperiodZveno2.Td + TAperiodZveno2._X0;


  td := tL - tOnn; //( час )
  B := Y_outEnd - Y_out0;
  tTau := FindT23(Y_out0+B*0.632, idxTtau);
  tau := tTau - tL;

//  t1 := (t2 - t3*Ln(2))/(1-Ln(2));
//  tau := t3 - t1;
//  tdel := t1 - t0;
  K := B/dInp;

//var topt := TampOpti.Create(TAperiodZveno2.T1 + TAperiodZveno2.T2,
//                            TAperiodZveno2.T1 * TAperiodZveno2.T2, TAperiodZveno2.Td, k);

var topt := TampOpti.Create(1.56,1.4229,0.2,0.37);

  Kp := 1.35/K*(tau/td + 0.185);
  Ti := 2.5*td*(tau + 0.185*td)/(tau + 0.166*td);
  td := 0.37*td*tau /(tau + 0.185*td);

  if Method = Lambda then
   begin
     Kp := tau/k/(3*tau+td);
     Ti := tau;
     td := 0;
   end
  else if Method = coon then
   begin
    Kp := 1/K;
    ti := 0.66*(TAperiodZveno2.T1+TAperiodZveno2.T2+TAperiodZveno2.Td);
    Td := 0.17*(TAperiodZveno2.T1+TAperiodZveno2.T2+TAperiodZveno2.Td);
   end;

  // ki := 1/k/0.05;
//  r := tdel/tau;
//  Kp := 1/(r*K)*(4/3 + r/4);
//  ti := tdel*(32+6*r)/(13+8*r);
//  td := tdel*4/(11+2*r);
  Ki := Kp/ti;   // pwr/Град / час
  Kd := Kp*td; // pwr/Град * час

  SetLength(output, Length(y));
//  for var i := 0 to High(y) do
//    if x[i] <= tL then
//      output[i] := Y_out0
//    else if x[i] >= tT then
//      output[i] := Y_outEnd
//    else
//      output[i] := dY_at_ddY0 * x[i] + d_at_ddY0;

  for var i := 0 to High(y) do output[i] := TAperiodZveno2.output[i];

  for var i := 0 to High(x) do if x[i] >= t1 then
   begin
    output[i] := 0;
    Break;
   end;
  for var i := 0 to High(x) do if x[i] >= t2 then
   begin
    output[i] := 0;
    Break;
   end;
  for var i := 0 to High(x) do if x[i] >= td then
   begin
    output[i] := 0;
    Break;
   end;

  output[idxTtau] := 0;

end;

procedure PID_ZieglerNichols(const [Ref] x, y, dy, ddy: TArray<Double>; scaleD, scaleDD: Double; off, onn, stab: TPidPoint;
 var output: TArray<Double>; var Kp, Ki, Kd: Double; IsCin: Boolean = false);
 /// Kp = dInp/RL
 /// R = dy|ddy=0 - скорости реакции  dT/dt
 /// L = Время простоя процесса
 /// τi = Время интеграл
 /// τd = Время дифф
var
  dInp: Double;
  tOnn: Double;
  Y_out0, Y_outEnd: Double;
  tL, tT: Double;
  L, T, R: Double;
 // X_at_ddY0: Double;
  dY_at_ddY0, Y_at_ddY0, d_at_ddY0, dyex: Double;
begin
  dInp := onn.inp - off.inp;
  tOnn := (onn.time + off.time) / 2;
  Y_out0 := (onn.outp + off.outp) / 2;
  Y_outEnd := stab.outp;
  GetS(x, y, dy, ddy, scaleD, scaleDD, Y_out0, Y_outEnd,tL,tT, dY_at_ddY0, d_at_ddY0);
  SetLength(output, Length(y));
  for var i := 0 to High(y) do
    if x[i] <= tL then
      output[i] := Y_out0
    else if x[i] >= tT then
      output[i] := Y_outEnd
    else
      output[i] := dY_at_ddY0 * x[i] + d_at_ddY0;

  L := tL - tOnn; //( час )
  T := tT - tL; //( час )
  R := dY_at_ddY0; //( Град/час )

//  var T1 := X_at_ddY0-tL;
  var k := (Y_outEnd - Y_out0)/dInp;


  kp := 1.2*T/(k*l);
  ki := 0.6*T/(k*l*l);
  kd := 0.6*T/(k);

  Kp := 1/(0.83*dY_at_ddY0*l/dInp);
  Ki := Kp/2/l;
  Kd := Kp*0.5*l;

  if IsCin then
   begin
    Kp := 1/(1.05*k*l/T);
    Ki := Kp/2.5/l;
    Kd := Kp*0.42*l;
   end
  else
   begin
    Kp := 1.2*dInp/(R*L); // pwr*час/(Град*час) = pwr/Град
    var ti := 2*L; //( час )
    Ki := Kp/ti;   // pwr/Град / час
    var td := 0.5*L; //( час )
    Kd := Kp*td; // pwr/Град * час
  end;
end;
//function dir2xy3(y, x: PDouble): Double;
//begin
//   Dec
//   var d1 := (y[1]-y[0])/(x[1]-x[0]);
//   var d0 := (y[0]-y[-1])/(x[0]-x[-1]);
//end;

procedure ddy(const [Ref] y: TArray<Double>; h, scale: Double; Dshag, Nsred, Nsredy: Integer; var dd: TArray<Double>; Dy: Boolean = false);
var
  hh: double;
  dd1, y1: TArray<Double>;
  s: Double;
  i, j, k: Integer;
begin
  if Dy then
    hh := h * Dshag * 2
  else
    hh := h * h * Dshag * Dshag;

  var n := Length(y);

  SetLength(dd, n);
  SetLength(dd1, n);
  SetLength(y1, n);

  for i := 0 to n - 1 do
  begin
    s := 0.0;
    for j := -Nsredy to Nsredy do
    begin
      k := i + j;
      if (k >= 0) and (k < n) then
        s := s + y[k];
    end;
    y1[i] := s / (Nsredy * 2 + 1);
  end;

  for i := 0 to Nsredy - 1 do
  begin
    y1[i] := y1[Nsredy];
    y1[n - Nsredy + i] := y1[n - 1 - Nsredy];
  end;

  if Dy then
    for i := Dshag to n - 1 - Dshag do
      dd1[i] := (-y1[i - Dshag] + y1[i + Dshag]) / hh
  else
    for i := Dshag to n - 1 - Dshag do
      dd1[i] := (y1[i - Dshag] - 2 * y1[i] + y1[i + Dshag]) / hh;

  for i := 0 to Dshag - 1 do
  begin
    dd1[i] := dd1[Dshag];
    dd1[n - Dshag + i] := dd1[n - 1 - Dshag];
  end;

  for i := 0 to n - 1 do
  begin
    s := 0.0;
    for j := -Nsred to Nsred do
    begin
      k := i + j;
      if (k >= 0) and (k < n) then
        s := s + dd1[k];
    end;
    dd[i] := s / (Nsred * 2 + 1) * scale
  end;
end;

procedure Resample(const [Ref] x, y, newX: TArray<Double>; var newY: TArray<Double>);
var
  Resample: IResample;
  nY: PDoubleArray;
begin
  ResampleFactory(Resample);
  CheckMath(Resample, Resample.Resample(@x[0], @y[0], Length(x), @newX[0], Length(newX), nY));
  SetLength(newY, Length(newX));
  for var i := 0 to Length(newX) - 1 do
    newY[i] := nY[i];
end;

function dir2xy9(y, x: PDoubleArray): Double;
var
  e: IEquations;
  a: array[0..8, 0..8] of Double;
  b: array[0..8] of Double;
  c: PDoubleArray;
  inf: Integer;
  xj: Double;
begin
  EquationsFactory(e);
  xj := x[Length(b) div 2];
  b[0] := 0;
  b[1] := 0;
  b[2] := 2;
  b[3] := 2 * 3 * xj;
  b[4] := 3 * 4 * xj * xj;
  b[5] := 4 * 5 * xj * xj * xj;
  b[6] := 5 * 6 * xj * xj * xj * xj;
  b[7] := 6 * 7 * xj * xj * xj * xj * xj;
  b[8] := 7 * 8 * xj * xj * xj * xj * xj * xj;
  for var col := 0 to 8 do
    for var row := 0 to 8 do
    begin
      a[row, col] := Math.IntPower(x[col], row);
    end;
  CheckMath(e, e.Linear(@a[0], 9, @b[0], inf, c));

  Result := 0;
  if inf = 1 then
  begin
    for var i := 0 to 8 do
      Result := Result + y[i] * c[i];
    if (Result > 100) or (Result < -100) then
      Result := 0;
  end
  else
  begin
    raise Exception.Create('Error Message');
  end;

end;

function dir1x9(y0: PDouble; h: Double = 1): Double;
const
  R: TArray<Double> = [1 / 280, -4 / 105, 1 / 5, -4 / 5, 0, 4 / 5, -1 / 5, 4 / 105, -1 / 280];
begin
  Result := 0;
  Dec(y0, 4);
  for var k in R do
  begin
    Result := Result + k * y0^;
    Inc(y0);
  end;
  Result := Result / (h * h);
end;

function dir2x9(y0: PDouble; h: Double): Double;
const
//  R: TArray<Double> = [-1/560, 8/315,-1/5, 8/5,	-205/72, 8/5, -1/5, 8/315, -1/560];
  R: TArray<Double> = [1, -2, 1];
begin
  Result := 0;
  Dec(y0, Length(R) div 2);
  for var k in R do
  begin
    Result := Result + k * y0^;
    Inc(y0);
  end;
  Result := Result / (h * h);
//   Result := (-1/560*(y0-4)^ +	8/315*ym3	-1/5*ym2 +	8/5*ym1	-205/72*y0^ +	8/5*y1	-1/5*y2 +	8/315*y3 -1/560*y4)/(h*h)
end;

{ Tpid }

constructor Tpid.Create(AKp, AKi, AKd, Adt{часы}, Au0{pwr}: Double);
begin
  Kp := AKp;
  Ki := AKi;
  Kd := AKd;
  dt := Adt;
  u0 := Au0;

  A0 := Kp + Ki * dt;
  A1 := -Kp;
  error[2] := 0; // e(t-2)
  error[1] := 0; // e(t-1)
  error[0] := 0; // e(t)
  Foutput := u0;  // Usually the current value of the actuator

  if Kd = 0 then Exit;
  A0d := Kd / dt;
  A1d := -2.0 * Kd / dt;
  A2d := Kd / dt;
  n := 5;
  tau := Kd / (Kp * n); // IIR filter time constant
  if tau > 0 then alpha := dt / (2 * tau)
  else alpha := 0;
  d0 := 0;
  d1 := 0;
  fd0 := 0;
  fd1 := 0;
end;

procedure Tpid.Run(measured_value: Double);
begin
  error[2] := error[1];
  error[1] := error[0];
  error[0] := FSetpoint - measured_value;
    // PI
  Foutput := Foutput + A0 * error[0] + A1 * error[1];

  if Kd = 0 then Exit;
    // Filtered D
  d1 := d0;
  d0 := A0d * error[0] + A1d * error[1] + A2d * error[2];
  fd1 := fd0;
  fd0 := ((alpha) / (alpha + 1)) * (d0 + d1) - ((alpha - 1) / (alpha + 1)) * fd1;
  Foutput := Foutput + fd0;
end;

end.


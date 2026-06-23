unit MetrInclin.Math2;

interface

uses  Vector, System.Math.Vectors, LuaInclin.Math,
      SysUtils, System.Classes, math, System.Variants, Container, RootImpl, System.Generics.Collections, Winapi.ActiveX,
      tools, debug_except, MathIntf, Xml.XMLIntf, ExtendIntf;


type

koeff_t = record
  k,d,d0: Single;
end;

sensorTrrT_t = record
  X,Y,Z: koeff_t;
end;

TrrT_t = record
  t0,t1: Single;
  accel, magnit: sensorTrrT_t;
end;

TTrrT = class
 class var root: IXMLNode;
 class var TrrTemp:  array [0..1] of TrrT_t;
 class procedure FindTrrTemp(root: IXMLNode);
 class function Find(dat: TVector3; T: Double; IsAccel: Boolean):TVector3;
 end;

type
  TTrrML = class
   type
    TCovar = record
     m11, m12,m13: Double;
          m22,m23: Double;
              m33: Double;
     class operator Implicit(const C: TCovar): TMatrix3;
     procedure Identity;
    end;
    Pnoise = ^Tnoise;
    Tnoise = record
      G,H: TCovar;
    end;
    Ptrr = ^Ttrr;
    Ttrr = record
          m11, m12, m13, m14: Double;
          m21, m22, m23, m24: Double;
          m31, m32, m33, m34: Double;
          Incl: Double;
     class operator Implicit(const C: Ttrr): TMatrix4;
     class operator Implicit(const C: TMatrix4): Ttrr;
    end;
    Tfdata = array[0..65*3] of double;
    Pfdata = ^Tfdata;
    class var
       // данные тарированнве и сырые
       RealIncl, TrrIncl: TArray<TInclPoint>;
       // шумы
       NoiseIncl: TArray<TInclPoint>;

       TrrA: TMatrix4;
       NoiseHinv, NoiseGinv: TMatrix3;
       //NormEg: TArray<Double>;
       z0n: TVector3;
//       LogDet: Double;
      // TrrH: Ttrr;
    class procedure cb_noise(const k, f: PDoubleArray); static; cdecl;
    class procedure cb_trr(const k, f: PDoubleArray); static; cdecl;

    class procedure UpdateNoise(const m0n: TVector3; const TrrMag: TMatrix4; const rot: TArray<TMatrix4>); static;

    class function FindRotations(const m0n: TVector3): TArray<TMatrix4>; static;

    class procedure Run(DotAH: Double; TrrMag, TrrAcc: TMatrix4; InclData: TArray<TInclPoint>;out TrrML: TMatrix4; out Incl: Double); static;
  end;

 ///
 ///  косоугольность
 ///      |1  a   b  dx|
 /// D =  |0  ay  c  dy|
 ///      |0   0 az  dz|
 ///
 ///   Xi = D*[X; 1]
 ///
 ///   Xi`*Xi-R^2 == 0  // сфера
 ///
 ///
 ///
 TSphereLS = class
  type
    TAmtx = array[0..8,0..8] of Double;
    TBvec = array[0..8] of Double;
    PLSRes = ^TLSRes;
    TLSRes = record
     Sa, Sb, Sdx, Say, Sc, Sdy, Saz, Sdz, SR: Double;
    end;
    TRes = record
     a, b, c, ay, az, dx, dy, dz, R: Double;
    end;
   class procedure InitVars(x,y,z: Double; var A: TAmtx; var B: TBvec); static;
   class procedure SummVars(A: TAmtx; B: TBvec; var SumA: TAmtx; var SumB: TBvec); static;
   class procedure FindRes(ls: TLSRes; var res: TRes); static;
   class procedure FindLS(A: TAmtx; B: TBvec; var ls: TLSRes); static;
   class procedure ToM3x4(res: TRes; var conv: TMatrix4); static;
   class procedure RunZ(AInp: TAngleFtting.TInput; out Res: TMatrix4); static;
   class procedure RunA(AInp: TAngleFtting.TInput; out Res: TMatrix4); static;
 end;


/// соосность
/// Вращая по X  устанавливаем Y в истиноое значение a,b - малы
///  Вращая по Y  устанавливаем X,Z в истиноое значение
///
///  RX * RY = RY * RX - т.к. a,b - малы
///
///  inv(Rx*RY) = RY(-b)*RX(-a) =
///
///  det = 1
///
///       |1   0  0|
///  RX = |0   1  a|
///       |0  -a  1|
///
///       | 1  0  b|
///  RY = | 0  1  0|
///       |-b  0  1|
///                  | 1  0  b|
///  RR = RY * RX =  | 0  1  a|
///                  |-b -a  1|
///
///  -b*x -a*y + z = Cz;
///   (x + b*z)^2 + (y + a*z)^2 = R^2 - Cz^2
///
///  a*(SY2 - SY^2/N)) + b*(SXY - SX*SY/N) + (SY*SZ/N - SZY)
///  a*(SXY - SX*SY/N) + b*(SX2 - SX^2/N)) + (SX*SZ/N - SZX)
///
///
 TZAlignLS = class
  public
  type
   TAmtx = array[0..1,0..1] of Double;
   TBvec = array[0..1] of Double;
   TZConstPoints = TArray<TVector3>;
   TInput = array of TZConstPoints;
   TSumm = record
     SX2, SY2, SX, SY, SZ, SXY, SXZ, SYZ: Double;
   end;
  private
    class var FInput: TInput;
    class procedure cb_Rz(const k, f: PDoubleArray); static; cdecl;
  public
   class procedure Run(Inp: TInput; out ResA, ResB: Double); static;
   class function Apply(Trr: TMatrix4; A,B: Double): TMatrix4; static;
   class procedure RunLeMa(Inp: TInput; out ResA, ResB: Double); static;
   class function ApplyLeMa(Trr: TMatrix4; A,B: Double): TMatrix4; static;
 end;
///
///  совмещаем Hy c Ay
///
///       | 1  a  0|
///  RZ = |-a  1  0|
///       | 0  0  1|
///
///    скалярное произведение = const
///    min(A`*RZ*H - C)^2
///
///   НМК (a, c)
///
///    | K^2   -K|     |-K*SP|
/// A= |-K      1|  B= |   SP|
///
///  K = Ax*Hy-Ay*Hx
///  SP = A'*H = Ax*Hx + Ay*Hy + Az*Hz
///
///
 TCrossConstLS = class
 public
  type
   TInclPo = record
    A, H: TVector3;
   end;
   TInclPoints = TArray<TInclPo>;
   PCrossCorrData = ^TCrossCorrData;
   TCrossCorrData = record
         m12, m13, m14: Double;
    m21, m22, m23, m24: Double;
    m31, m32, m33, m34: Double;
    Cross: Double;
    m11: Double;
    class operator implicit(d: TMatrix4): TCrossCorrData;
    class operator implicit(d: TCrossCorrData): TMatrix4;
   end;
 private
   class var FInput: TInclPoints;
   class var Fm11: Double;
   class procedure cb_Cross(const k, f: PDoubleArray); static; cdecl;
   class procedure cb_CrossCorr(const k, f: PDoubleArray); static; cdecl;
 public
   class procedure Run(Inp: TInclPoints; out ResA, ResI: Double); static;
   class function Apply(Trr: TMatrix4; A: Double): TMatrix4; static;
   class procedure RunLeMa(Inp: TInclPoints; out ARad, Cross: Double); static;
   class function ApplyLeMa(Trr: TMatrix4; A: Double): TMatrix4; static;
   // Finput Акселерометр тарированные значения Н-сырые
   class function CorrectInclLeMa(Inp: TInclPoints; Trr: TMatrix4; Cross: Double): TMatrix4; static;
 end;

implementation

class procedure TSphereLS.ToM3x4(res: TRes; var conv: TMatrix4);
 var
  k: Double;
begin
  k := 1000/res.R;
  with conv, res do
   begin
     m11 := k; m12 := a*k;   m13 := b*k;  m14 := dx*k;
     m21 := 0; m22 := ay*k;  m23 := c*k;  m24 := dy*k;
     m31 := 0; m32 :=   0;   m33 :=az*k;  m34 := dz*k;
   end;
end;

{ TMathLSNoStol }

class procedure TSphereLS.FindLS(A: TAmtx; B: TBvec;  var ls: TLSRes);
 var
  x: PDoubleArray;
  inf: Integer;
  e: IEquations;
begin
  EquationsFactory(e);
  CheckMath(e, e.Linear(@A, 9,@B, inf, x));
  ls := PLSRes(x)^;
end;

class procedure TSphereLS.FindRes(ls: TLSRes; var res: TRes);
{                           2*alpha   // Sa
                           2*betta   // Sb
                              2*dx   // Sdx
                    alpha^2 + ay^2   // Say
        2*alpha*betta + 2*ay*gamma   // Sc
              2*alpha*dx + 2*ay*dy   // Sdy
          az^2 + betta^2 + gamma^2   // Saz
 2*az*dz + 2*betta*dx + 2*dy*gamma   // Sdz
        - R^2 + dx^2 + dy^2 + dz^2   // Sr}

 var
  S2: Double;
begin
  with ls, res do
   begin
    a := Sa/2;
    b := Sb/2;
    dx := Sdx/2;
    ay := Sqrt(Say - a*a);
    c := (Sc/2-a*b)/ay;
    dy := (Sdy/2-a*dx)/ay;
    az := Sqrt(Saz - b*b - c*c);
    dz := (Sdz/2 - b*dx - c*dy)/az;
    R := Sqrt(dx*dx + dy*dy + dz*dz  - SR);
   end;
end;

class procedure TSphereLS.InitVars(x, y, z: Double; var A: TAmtx; var B: TBvec);
 var
  xp3,xp2,yp4,yp3,yp2,zp4,zp3,zp2: Double;
begin
  xp2 := x*x;
  xp3 := xp2*x;
  yp2 := y*y;
  yp3 := yp2*y;
  yp4 := yp3*y;
  zp2 := z*z;
  zp3 := zp2*z;
  zp4 := zp3*z;

  A[0,0] :=  xp2*yp2;  A[0,1] :=  xp2*y*z;  A[0,2] :=  xp2*y;  A[0,3] :=    x*yp3;  A[0,4] :=  x*yp2*z;  A[0,5] :=  x*yp2;  A[0,6] :=  x*y*zp2;  A[0,7] :=  x*y*z;  A[0,8] :=  x*y;
  A[1,0] :=  xp2*y*z;  A[1,1] :=  xp2*zp2;  A[1,2] :=  xp2*z;  A[1,3] :=  x*yp2*z;  A[1,4] :=  x*y*zp2;  A[1,5] :=  x*y*z;  A[1,6] :=    x*zp3;  A[1,7] :=  x*zp2;  A[1,8] :=  x*z;
  A[2,0] :=    xp2*y;  A[2,1] :=    xp2*z;  A[2,2] :=    xp2;  A[2,3] :=    x*yp2;  A[2,4] :=    x*y*z;  A[2,5] :=    x*y;  A[2,6] :=    x*zp2;  A[2,7] :=    x*z;  A[2,8] :=    x;
  A[3,0] :=    x*yp3;  A[3,1] :=  x*yp2*z;  A[3,2] :=  x*yp2;  A[3,3] :=      yp4;  A[3,4] :=    yp3*z;  A[3,5] :=    yp3;  A[3,6] :=  yp2*zp2;  A[3,7] :=  yp2*z;  A[3,8] :=  yp2;
  A[4,0] :=  x*yp2*z;  A[4,1] :=  x*y*zp2;  A[4,2] :=  x*y*z;  A[4,3] :=    yp3*z;  A[4,4] :=  yp2*zp2;  A[4,5] :=  yp2*z;  A[4,6] :=    y*zp3;  A[4,7] :=  y*zp2;  A[4,8] :=  y*z;
  A[5,0] :=    x*yp2;  A[5,1] :=    x*y*z;  A[5,2] :=    x*y;  A[5,3] :=      yp3;  A[5,4] :=    yp2*z;  A[5,5] :=    yp2;  A[5,6] :=    y*zp2;  A[5,7] :=    y*z;  A[5,8] :=    y;
  A[6,0] :=  x*y*zp2;  A[6,1] :=    x*zp3;  A[6,2] :=  x*zp2;  A[6,3] :=  yp2*zp2;  A[6,4] :=    y*zp3;  A[6,5] :=  y*zp2;  A[6,6] :=      zp4;  A[6,7] :=    zp3;  A[6,8] :=  zp2;
  A[7,0] :=    x*y*z;  A[7,1] :=    x*zp2;  A[7,2] :=    x*z;  A[7,3] :=    yp2*z;  A[7,4] :=    y*zp2;  A[7,5] :=    y*z;  A[7,6] :=      zp3;  A[7,7] :=    zp2;  A[7,8] :=    z;
  A[8,0] :=      x*y;  A[8,1] :=      x*z;  A[8,2] :=      x;  A[8,3] :=      yp2;  A[8,4] :=      y*z;  A[8,5] :=      y;  A[8,6] :=      zp2;  A[8,7] :=      z;  A[8,8] :=    1;

  B[0] := -xp3*y;
  B[1] := -xp3*z;
  B[2] := -xp3;
  B[3] := -xp2*yp2;
  B[4] := -xp2*y*z;
  B[5] := -xp2*y;
  B[6] := -xp2*zp2;
  B[7] := -xp2*z;
  B[8] := -xp2;
end;

class procedure TSphereLS.SummVars(A: TAmtx; B: TBvec; var SumA: TAmtx; var SumB: TBvec);
 var
  i,j: Integer;
begin
  for I := 0 to 8 do for j := 0 to 8 do SumA[i,j] := SumA[i,j] + A[i,j];
  for I := 0 to 8 do SumB[i] := SumB[i] + B[i];
end;

class procedure TSphereLS.RunA(AInp: TAngleFtting.TInput; out Res: TMatrix4);
 var
  r: TAngleFtting.TInputRec;
  A, Sa: TAmtx;
  B, Sb: TBvec;
  ls: TLSRes;
  rs: TRes;
begin
  Sa := default(TAmtx);
  Sb := default(TBvec);
  Res := default( TMatrix4);
  ls := default(TLSRes);
  rs := default(TRes);
  for r in AInp do
   begin
    InitVars(r.hx, r.hy, r.hz, A, B);
    SummVars(A,B, Sa, Sb);
   end;
  FindLS(Sa,Sb,ls);
  FindRes(ls, rs);
  ToM3x4(rs, Res);
end;

class procedure TSphereLS.RunZ(AInp: TAngleFtting.TInput; out Res: TMatrix4);
 var
  r: TAngleFtting.TInputRec;
  A, Sa: TAmtx;
  B, Sb: TBvec;
  ls: TLSRes;
  rs: TRes;
begin
  Sa := default(TAmtx);
  Sb := default(TBvec);
  Res := default(TMatrix4);
  ls := default(TLSRes);
  rs := default(TRes);
  for r in AInp do
   begin
    InitVars(r.gx, r.gy, r.gz, A, B);
    SummVars(A,B, Sa, Sb);
   end;
  FindLS(Sa,Sb,ls);
  FindRes(ls, rs);
  ToM3x4(rs, Res);
end;

{ TZAxisLS }

class function TZAlignLS.Apply(Trr: TMatrix4; A, B: Double): TMatrix4;
begin
  with Trr do
   begin
    Result.m11 := m11 - b*m31;     Result.m12 := m12 - b*m32;    Result.m13 := m13 - b*m33; Result.m14 := m14 - b*m34;
    Result.m21 := m21 + a*m31;     Result.m22 := m22 + a*m32;    Result.m23 := m23 + a*m33; Result.m24 := m24 + a*m34;
    Result.m31 := m31-a*m21+b*m11; Result.m32 := m32-a*m22+b*m12;Result.m33 := m33 - a*m23 + b*m13;   Result.m34 := m34 - a*m24 + b*m14;
   end;
 end;

class function TZAlignLS.ApplyLeMa(Trr: TMatrix4; A, B: Double): TMatrix4;
begin
  with Trr do
   begin
    Result.m11 := m11*cos(b) - m31*cos(a)*sin(b) + m21*sin(a)*sin(b);
    Result.m12 := m12*cos(b) - m32*cos(a)*sin(b) + m22*sin(a)*sin(b);
    Result.m13 := m13*cos(b) - m33*cos(a)*sin(b) + m23*sin(a)*sin(b);
    Result.m14 := m14*cos(b) - m34*cos(a)*sin(b) + m24*sin(a)*sin(b);
    Result.m21 := m21*cos(a) + m31*sin(a);
    Result.m22 := m22*cos(a) + m32*sin(a);
    Result.m23 := m23*cos(a) + m33*sin(a);
    Result.m24 := m24*cos(a) + m34*sin(a);
    Result.m31 := m11*sin(b) + m31*cos(a)*cos(b) - m21*cos(b)*sin(a);
    Result.m32 := m12*sin(b) + m32*cos(a)*cos(b) - m22*cos(b)*sin(a);
    Result.m33 := m13*sin(b) + m33*cos(a)*cos(b) - m23*cos(b)*sin(a);
    Result.m34 := m14*sin(b) + m34*cos(a)*cos(b) - m24*cos(b)*sin(a);
   end;
end;

class procedure TZAlignLS.cb_Rz(const k, f: PDoubleArray);
 var
  p: TZConstPoints;
  j, i: integer;
  zold, fn, dz : Double;
  n: Integer;
  function CorrectZ(p: TVector3): Double;
  begin
    Result := p.x*sin(k[1]) - p.y*cos(k[1])*sin(k[0]) + p.z*cos(k[0])*cos(k[1])
  end;
begin
  n := 0;
  for i := 0 to High(Finput) do
   for j := 0 to High(Finput[i]) do
    begin
     dz := CorrectZ(Finput[i][j]) - k[i+2];
     f[n] := Sqr(dz);
     Inc(n);
    end;
end;

class procedure TZAlignLS.RunLeMa(Inp: TInput; out ResA, ResB: Double);
 var
  e: ILMFitting;
  rep: PLMFittingReport;
  a: TArray<Double>;
  HOut: PDoubleArray;
  p: TZConstPoints;
  iv: TVector3;
  len,i,j: Integer;
begin
  SetLength(a, 2+Length(Inp));
  a[0] := 0;
  a[1] := 0;
  for i := 0 to High(Inp) do
  begin
   a[i+2] := 0;
   for iv in Inp[i] do a[i+2] := a[i+2] + iv.Z;
   a[i+2] := a[i+2]/ Length(Inp[i]);
  end;

  FInput := Inp;
  len := 0;
  for p in Inp do Inc(len, Length(p));
//   for i := 0 to High(p) do
//    for j := i+1 to High(p) do
//     Inc(len, 1);
  LMFittingFactory(e);
//  CheckMath(e, e.FitV(2, len, @a, 0.000001, 0, 0, 0, 10000, cb_Rz, HOut, rep));
  CheckMath(e, e.FitV(Length(a), len, PDoubleArray(@a[0]), 0.0000001, 0, 0, 0, 10000, cb_Rz, HOut, rep));
  ResA := HOut[0];
  ResB := HOut[1];
end;


class procedure TZAlignLS.Run(Inp: TInput; out ResA, ResB: Double);
 var
  s: TSumm;
  zp: TZConstPoints;
  p: TVector3;
  A: TAmtx;
  B: TBvec;
  N: Integer;
  x: PDoubleArray;
  inf: Integer;
  e: IEquations;
begin
  A := default(TAmtx);
  B := default(TBvec);
  for zp in Inp do
   begin
    s := default(TSumm);
    with s do
     begin
      for p in zp do with p do
       begin
        SX2 := SX2 + X*X;
        SY2 := SY2 + Y*Y;
        SX := SX + X;
        SY := SY + Y;
        SZ := SZ + Z;
        SXY := SXY + X*Y;
        SXZ := SXZ + X*Z;
        SYZ := SYZ + Y*Z;
       end;
      N := Length(zp);
//    a*(SY2 - Sy*Sy/N) + b*(Sx*Sy/N - Sxy) = Syz - Sz*Sy/N
//    a*(Sxy - Sx*Sy/N) + b*(Sx*Sx/N - Sx2) = Sxz - Sz*Sx/N
      a[0,0] := a[0,0] + SY2 - SY*SY/N;  a[0,1] := a[0,1] - SXY + SX*SY/N;
      a[1,0] := a[1,0] + SXY - SX*SY/N;  a[1,1] := a[1,1] - SX2 + SX*SX/N;
      b[0] := b[0] + SYZ - SY*SZ/N;
      b[1] := b[1] + SXZ - SX*SZ/N;
     end;
   end;
  EquationsFactory(e);
  CheckMath(e, e.Linear(@A, 2, @B, inf, x));
  ResA := x[0];
  ResB := x[1];
end;

{ TCrossConstLS }

class function TCrossConstLS.Apply(Trr: TMatrix4; A: Double): TMatrix4;
begin
  with Trr do
   begin
    Result.m11 := m11 + a*m21; Result.m12 := m12 + a*m22; Result.m13 := m13 + a*m23; Result.m14 := m14 + a*m24;
    Result.m21 := m21 - a*m11; Result.m22 := m22 - a*m12; Result.m23 := m23 - a*m13; Result.m24 := m24 - a*m14;
    Result.m31 := m31; Result.m32 := m32; Result.m33 := m33; Result.m34 := m34;
   end;
end;

class function TCrossConstLS.ApplyLeMa(Trr: TMatrix4; A: Double): TMatrix4;
begin
  with Trr do
   begin
    Result.m11 := m11*cos(a) + m21*sin(a); Result.m12 := m12*cos(a) + m22*sin(a);
    Result.m13 := m13*cos(a) + m23*sin(a); Result.m14 := m14*cos(a) + m24*sin(a);
    Result.m21 := m21*cos(a) - m11*sin(a); Result.m22 := m22*cos(a) - m12*sin(a);
    Result.m23 := m23*cos(a) - m13*sin(a); Result.m24 := m24*cos(a) - m14*sin(a);
    Result.m31 := m31; Result.m32 := m32; Result.m33 := m33; Result.m34 := m34 ;
   end;
end;

class procedure TCrossConstLS.cb_Cross(const k, f: PDoubleArray);
 var
  i: integer;
begin
  for i := 0 to High(finput) do
   with finput[i] do
    f[i] := sqr(cos(k[0])*A.x*H.x + sin(k[0])*A.x*H.Y + (-sin(k[0]))*A.y*H.X + cos(k[0])*A.y*H.y + A.z*H.z - k[1])
end;

class procedure TCrossConstLS.cb_CrossCorr(const k, f: PDoubleArray);
 var
  i: integer;
  ch: TVector3;
  cr: double;
begin
  for i := 0 to High(finput) do with PCrossCorrData(k)^, finput[i]  do
   begin
    with H do
     begin
      ch.X := Fm11*x + m12*y + m13*z + m14;
      ch.Y := m21*x + m22*y + m23*z + m24;
      ch.Z := m31*x + m32*y + m33*z + m34;
     end;
    cr := A.X*ch.X + A.Y*ch.Y + A.Z*ch.Z- Cross;
    f[i] := Sqr(cr);
   end;
end;

class function TCrossConstLS.CorrectInclLeMa(Inp: TInclPoints; Trr: TMatrix4; Cross: Double): TMatrix4;
 var
  e: ILMFitting;
  rep: PLMFittingReport;
  Din: TCrossCorrData;
  DOut: PDoubleArray;
begin
  Din := default(TCrossCorrData);
  Din.m22 := Trr.m22;
  Din.m33 := Trr.m33;
  Din.Cross := Cross;
  FInput := Inp;
  Fm11 := Trr.m11;
  LMFittingFactory(e);
  CheckMath(e, e.FitV(SizeOf(TCrossCorrData) div sizeof(Double)-1, Length(Inp), PDoubleArray(@Din), 0.0000001, 0, 0, 0, 100000, cb_CrossCorr, DOut, rep));

  Result := PCrossCorrData(DOut)^;
  Result.m11 := Fm11;
end;

class procedure TCrossConstLS.RunLeMa(Inp: TInclPoints; out ARad, Cross: Double);
 var
  e: ILMFitting;
  rep: PLMFittingReport;
  a: array[0..1] of Double;
  HOut: PDoubleArray;
begin
  LMFittingFactory(e);
  a[0] := 0;
  a[1] := Degtorad(10);
  FInput := Inp;
  CheckMath(e, e.FitV(2, Length(Inp), PDoubleArray(@a), 0.000001, 0, 0, 0, 10000, cb_Cross, HOut, rep));
  ARad := HOut[0];
  Cross := HOut[1];
end;

class procedure TCrossConstLS.Run(Inp: TInclPoints; out ResA, ResI: Double);
 var
  r: TInclPo;
  A, Sa: TZAlignLS.TAmtx;
  B, Sb: TZAlignLS.TBvec;
  D, CRS: Double;
  x: PDoubleArray;
  inf: Integer;
  e: IEquations;
begin
  Sa := Default(TZAlignLS.TAmtx);
  Sb := default(TZAlignLS.TBvec);
  for r in Inp do
   begin
///   D = Ax*Hy-Ay*Hx;
//    a*S(D^2) + R*S(-D)  = S(-D*CRS)
//    a*S(D)   + R*(-N)   = S(-CRS)

    D := r.A.x*r.h.y - r.A.y*r.h.x;
    CRS := r.A.x*r.h.x + r.A.y*r.h.y + r.A.z*r.h.z;

    Sa[0,0] := Sa[0,0] + D*D; Sa[0,1] := Sa[0,1] - D; Sb[0] := Sb[0] - D*CRS;
    Sa[1,0] := Sa[1,0] + D;   Sa[1,1] := Sa[1,1] - 1; Sb[1] := Sb[1] - CRS;
   end;
  EquationsFactory(e);
  CheckMath(e, e.Linear(@SA, 2, @SB, inf, x));
  ResA := x[0];
  ResI := x[1];// RadToDeg(Arccos(x[1]/1000/1000));
end;

{ TCrossConstLS.TCrossCorrData }

class operator TCrossConstLS.TCrossCorrData.implicit(d: TMatrix4): TCrossCorrData;
begin
  with Result do
   begin
    m11 := d.m11; m12 := d.m12; m13 := d.m13; m14 := d.m14;
    m21 := d.m21; m22 := d.m22; m23 := d.m23; m24 := d.m24;
    m31 := d.m31; m32 := d.m32; m33 := d.m33; m34 := d.m34;
    Cross := 0;
   end;
end;

class operator TCrossConstLS.TCrossCorrData.implicit(d: TCrossCorrData): TMatrix4;
begin
  with Result do
   begin
    m11 := d.m11; m12 := d.m12; m13 := d.m13; m14 := d.m14;
    m21 := d.m21; m22 := d.m22; m23 := d.m23; m24 := d.m24;
    m31 := d.m31; m32 := d.m32; m33 := d.m33; m34 := d.m34;
   end;
end;

{ TQtmath }

{function TQtmath.L: TMatrix3D;
begin
  Result := TMatrix3D.Create(V[0],-V[1],-V[2],-V[3],
                             V[1], V[0],-V[3], V[2],
                             V[2], V[3], V[0],-V[1],
                             V[3],-V[2], V[1], V[0]);
end;

function TQtmath.R: TMatrix3D;
begin
  Result := TMatrix3D.Create(V[0],-V[1],-V[2],-V[3],
                             V[1], V[0], V[3],-V[2],
                             V[2],-V[3], V[0], V[1],
                             V[3], V[2],-V[1], V[0]);
end;}

{ TMatrix3Dhelper }

//class function TRotationFind.Add(a, b: TMatrix3D): TMatrix3D;
// var
//  i, j: Integer;
//begin
//  for i := 0 to High(a.M) do for j := 0 to High(a.M[0].V) do Result.M[i].V[j] := a.M[i].V[j] + b.M[i].V[j];
//end;
//
//class function TRotationFind.Negative(const m: TMatrix3D): TMatrix3D;
// var
//  i, j: Integer;
//begin
//  for i := 0 to High(m.M) do for j := 0 to High(m.M[0].V) do Result.M[i].V[j] := -m.M[i].V[j];
//end;

{ TRotationFind }

//class function TRotationFind.L(p: TPoint3D): TMatrix3D;
//begin
//  with p do
//   begin
//    Result := TMatrix3D.Create(0,-X,-Y,-Z,
//                               X, 0,-Z, Y,
//                               Y, Z, 0,-X,
//                               Z,-Y, X, 0);
//   end;
//end;
//
//class function TRotationFind.R(p: TPoint3D): TMatrix3D;
//begin
//  with p do
//   begin
//    Result := TMatrix3D.Create(0,-X,-Y,-Z,
//                               X, 0, Z,-Y,
//                               Y,-Z, 0, X,
//                               Z, Y,-X, 0);
//   end;
//end;

class function TTrrML.FindRotations(const m0n: TVector3): TArray<TMatrix4>;
 var
  i, n: Integer;
  a, incl, z0: TMatrix4;
  g0,h0: TVector3;
  e: Ieig;
  Res: LongBool;
  w: PDoubleArray;
  z: IDoubleMatrix;
  ip : TInclPoint;
  q: TQuaternion;
  s: string;
begin
  SetLength(Result, Length(TrrIncl));
  incl := m0n.R;
  z0 := z0n.R;
  EigFactory(e);
  n := 0;
  for ip in TrrIncl do
   begin
    a := -(ip.H.L*incl + ip.G.L*z0);
    CheckMath(e, e.sevd(@a.m11, 4, 1, Res, w, z));
//    for i := 0 to z.Rows-1  do TDebug.Log('  %f   %f   %f   %f   ', [z.Items[i, 0], z.Items[i, 1], z.Items[i, 2], z.Items[i, 3] ]);
    for i := 0 to 3 do
     begin
//      TDebug.Log('%d %f', [i, w[i]]);
      q.V[i] := z[i,3];
     end;
    Result[n] := q;
    Result[n] := Result[n].T;  /// ?????????????? { TODO : FIND ERROR ORнепонимаю теорию}
//    h0 := m0n - Result[n].T * ip.H;
//    g0 := z0n - Result[n].T * ip.G;
   // TDebug.Log('%1.3f  %1.3f  %1.3f', [TXMLScriptMath.RadToDeg360(Result[n].Azimut), RadToDeg(Result[n].zenit), TXMLScriptMath.RadToDeg360(Result[n].Otklonitel)]);
    Inc(n);
   end;
end;

class procedure TTrrML.Run(DotAH: Double; TrrMag, TrrAcc: TMatrix4; InclData: TArray<TInclPoint>; out TrrML: TMatrix4; out Incl: Double);
 var
  m0n: TVector3;
  rot: TArray<TMatrix4>;
  i: integer;
  e: ILMFitting;
  rep: PLMFittingReport;
  Din : Tnoise;
  Dout: Pnoise;
  Dout2: Ptrr;
  trrh: Ttrr;
begin
  SetLength(RealIncl, Length(InclData));
  SetLength(TrrIncl, Length(InclData));
  SetLength(NoiseIncl, Length(InclData));

  z0n := TVector3.Create(0, 0, 1)*1000;

  DotAH := DotAH/1000/1000; //cos i
  m0n := TVector3.Create(Sqrt(1 - DotAH*DotAH), 0, DotAH)*1000;

  TrrML := TrrMag;
  TrrA := TrrAcc;

  for i := 0 to High(InclData) do
   begin
    TrrIncl[i].G := TrrAcc * TTrrT.Find(InclData[i].G, InclData[i].T, True); // тарированные Асс
    TrrIncl[i].H := TrrML * TTrrT.Find(InclData[i].H, InclData[i].T, False); // тарированные MAG
   end;
  RealIncl := InclData;

  rot := FindRotations(m0n);

  UpdateNoise(m0n, TrrML, rot);

{  m3H := TMatrix3(TrrML).inv;
  m3G := TMatrix3(TrrA).inv;
  v3H := TrrML.Vector(3);
  v3G := TrrA.Vector(3);

  for I := 0 to High(rot) do //шумы в системе координат измеряемой
   begin
    NoiseIncl[i].G := RealIncl[i].G - m3G*((rot[i] * z0n)-v3G);
    NoiseIncl[i].H := RealIncl[i].H - m3H*((rot[i] * m0n)-v3H);
//    eH[i] := id[i].H - rot[i] * m0n;
   end;}


  LMFittingFactory(e);

  Din.G.Identity;
  Din.H.Identity;

  CheckMath(e, e.FitV(6*2, Length(RealIncl)*2{+2}, PDoubleArray(@Din), 0.0000001, 0, 0, 0, 100000, cb_noise, PDoubleArray(DOut), rep));
  NoiseGinv := Tmatrix3(DOut^.G).inv;
  NoiseHinv := Tmatrix3(DOut^.H).inv;

   TrrH := TrrMag;
//   TrrH.m11 := 2;
   TrrH.Incl := DotAH;

   LMFittingFactory(e);

   CheckMath(e, e.FitV(SizeOf(TrrH) div SizeOf(Double), Length(RealIncl)*2, PDoubleArray(@TrrH), 0.0000001, 0, 0, 0, 100000, cb_trr, PDoubleArray(DOut2), rep));

   TrrML := TMatrix4(DOut2^);
end;


class procedure TTrrML.UpdateNoise(const m0n: TVector3; const TrrMag: TMatrix4; const rot: TArray<TMatrix4>);
 var
  m3G, m3H: TMatrix3;
  v3G, v3H: TVector3;
  i: Integer;
begin
  m3H := TMatrix3(TrrMag).inv;
  m3G := TMatrix3(TrrA).inv;
  v3H := TrrMag.Vector(3);
  v3G := TrrA.Vector(3);

  for I := 0 to High(rot) do //шумы в системе координат измеряемой
   begin
//    vg := rot[i] * z0n;
//    vh := rot[i] * m0n;
//    NoiseIncl[i].G := TrrIncl[i].G - vg;
//    NoiseIncl[i].H := TrrIncl[i].H - vh;

//    NoiseIncl[i].G := RealIncl[i].G - m3G*(TrrIncl[i].G-v3G);
//    NoiseIncl[i].H := RealIncl[i].H - m3H*(TrrIncl[i].H-v3H);
    NoiseIncl[i].G := RealIncl[i].G - m3G*((rot[i] * z0n)-v3G);
    NoiseIncl[i].H := RealIncl[i].H - m3H*((rot[i] * m0n)-v3H);
   end;
end;

class procedure TTrrML.cb_noise(const k, f: PDoubleArray);
 var
  i, ke: Integer;
  n: Pnoise;
  mg, mh, mginv, mhinv: TMatrix3;
  pfd: Pfdata;
begin
  n := Pnoise(k);

  mg := TMatrix3(n.G);
  mh := TMatrix3(n.H);

  mginv := mg.inv;
  mhinv := mh.inv;
  ke := Length(NoiseIncl);
  pfd := Pfdata(f);

  for I := 0 to ke-1 do with NoiseIncl[i] do
   begin
    f[i]    := G.dot(mginv * G);
    f[i+ke] := H.dot(mhinv * H);
   end;

{  f[ke] := Sqr(ke/2*abs(ln(mg.det)));
  if mh.det > 0 then
   begin
    F[ke+1] := Sqr(ke/2*ln(mh.det));
   end
   else
    begin
    F[ke+1] := Sqr(ke/2*abs(ln(mh.det)));
    end;}
end;


class procedure TTrrML.cb_trr(const k, f: PDoubleArray);
 var
  m0n: TVector3;
  trr: Ptrr;
  i: Integer;
  m4 : TMatrix4;
  rot: TArray<TMatrix4>;
  pfd: Pfdata;
begin
  pfd := Pfdata(f);

  trr := Ptrr(k);
  m0n := TVector3.Create(Sqrt(1 - trr.Incl*trr.Incl), 0, trr.Incl)*1000;
  m4 := TMatrix4(Trr^);

  for i := 0 to High(TrrIncl) do  TrrIncl[i].H := m4 * RealIncl[i].H; // тарированные MAG

  rot := FindRotations(m0n);

  UpdateNoise(m0n, m4, rot);

  for I := 0 to High(NoiseIncl) do with NoiseIncl[i] do
   begin
    f[i] := G.dot(NoiseGinv * G);
    f[i + Length(NoiseIncl)] := H.dot(NoiseHinv * H);
   // f[i + Length(NoiseIncl)*2] := sqr(1 - TrrIncl[i].H.dot(TrrIncl[i].H)/ 1000000);
   end;
end;


{ TTrrML.TCovar }

procedure TTrrML.TCovar.Identity;
begin
  m11 := 1; m12 := 0; m13 := 0;
            m22 := 1; m23 := 0;
                      m33 := 1;
end;

class operator TTrrML.TCovar.Implicit(const C: TCovar): TMatrix3;
begin
  Result.m11 := c.m11; Result.m12 := c.m12; Result.m13 := c.m13;
  Result.m21 := c.m12; Result.m22 := c.m22; Result.m23 := c.m23;
  Result.m31 := c.m13; Result.m32 := c.m23; Result.m33 := c.m33;
end;

{ TTrrML.TtrrML }

class operator TTrrML.Ttrr.Implicit(const C: Ttrr): TMatrix4;
begin
  Result.m11 := c.m11; Result.m12 := c.m12; Result.m13 := c.m13; Result.m14 := c.m14;
  Result.m21 := c.m21; Result.m22 := c.m22; Result.m23 := c.m23; Result.m24 := c.m24;
  Result.m31 := c.m31; Result.m32 := c.m32; Result.m33 := c.m33; Result.m34 := c.m34;
  Result.m41 := 0;     Result.m42 := 0;     Result.m43 := 0;     Result.m44 := 1;
end;

class operator TTrrML.Ttrr.Implicit(const C: TMatrix4): Ttrr;
begin
  Result.m11 := c.m11; Result.m12 := c.m12; Result.m13 := c.m13; Result.m14 := c.m14;
  Result.m21 := c.m21; Result.m22 := c.m22; Result.m23 := c.m23; Result.m24 := c.m24;
  Result.m31 := c.m31; Result.m32 := c.m32; Result.m33 := c.m33; Result.m34 := c.m34;
//  Result.Incl := 0;
end;

{ TTrrT }

//class function TTrrT.FindAcc(xyz: IXMLNode, t): TVector3;
//begin
//  Result.X := xyz.ChildNodes.FindNode('X').ChildNodes.FindNode(T_DEV).Attributes[AT_VALUE];
//  Result.Y := xyz.ChildNodes.FindNode('Y').ChildNodes.FindNode(T_DEV).Attributes[AT_VALUE];
//  Result.Z := xyz.ChildNodes.FindNode('Z').ChildNodes.FindNode(T_DEV).Attributes[AT_VALUE];
//  if Assigned(root) then
//  Result.X :=(
//
//end;

//class function TTrrT.FindMag(xyz: IXMLNode): TVector3;
//begin
//
//end;

class function TTrrT.Find(dat: TVector3; T: Double; IsAccel: Boolean): TVector3;
 var
  tdat: sensorTrrT_t;
begin
  //Exit(dat);
  if not Assigned(root) then Exit(dat);
  for var d in TrrTemp do if T < d.t1 then
   begin
    if IsAccel then  tdat := d.accel else tdat := d.magnit;
    var tc := T-d.t0;
    Result.X := (dat.X + tdat.X.d0 + tdat.X.d*tc) * (1 + tdat.X.k*tc);
    Result.Y := (dat.Y + tdat.Y.d0 + tdat.Y.d*tc) * (1 + tdat.Y.k*tc);
    Result.Z := (dat.Z + tdat.Z.d0 + tdat.Z.d*tc) * (1 + tdat.Z.k*tc);
    Break;
   end;
end;
//
class procedure TTrrT.FindTrrTemp(root: IXMLNode);
 procedure AssignK(p: IXMLNode; var v:koeff_t);
 begin
   v.k := p.Attributes['k'];
   v.d := p.Attributes['d'];
   v.d0 := p.Attributes['d0'];
 end;
 procedure AssignP(p: IXMLNode; var v:sensorTrrT_t);
 begin
  AssignK(p.ChildNodes.FindNode('X'),v.X);
  AssignK(p.ChildNodes.FindNode('Y'),v.Y);
  AssignK(p.ChildNodes.FindNode('Z'),v.Z);
 end;
begin
  TTrrT.root := root.ChildNodes.FindNode('T');
  if not Assigned(TTrrT.root) then Exit;
  for var i := 0 to TTrrT.root.ChildNodes.Count-1 do
   begin
    var n := TTrrT.root.ChildNodes[i];
    TrrTemp[i].t0 := n.Attributes['t0'];
    TrrTemp[i].t1 := n.Attributes['t1'];
    var a := n.ChildNodes.FindNode('accel');
    AssignP(n.ChildNodes.FindNode('accel'), TrrTemp[i].accel);
    AssignP(n.ChildNodes.FindNode('magnit'), TrrTemp[i].magnit);
   end;
end;

end.


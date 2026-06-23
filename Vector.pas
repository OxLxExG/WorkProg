unit Vector;

interface

uses System.SysUtils, System.Math;

 type
    TVector3Array = array [0..2] of Double;
    TVector4Array = array [0..3] of Double;
    TMatrix3Data = array[0..2] of TVector3Array;
    TMatrix4Data = array[0..3] of TVector4Array;

  TVector3 = record
    constructor Create(AX,AY,AZ: Double);
    function L: TMatrix4Data;
    function R: TMatrix4Data;
    function dot(const APoint: TVector3): Double;
    function cross(const APoint: TVector3): TVector3;
    function Length: Double;
    class operator Add(const APoint1, APoint2: TVector3): TVector3;
    class operator Subtract(const APoint1, APoint2: TVector3): TVector3;
//    class operator Equal(const APoint1, APoint2: TVector3): Boolean; inline;
//    class operator NotEqual(const APoint1, APoint2: TVector3): Boolean; inline;
    class operator Negative(const APoint: TVector3): TVector3;
    class operator Multiply(const APoint: TVector3; const AFactor: Double): TVector3; inline;
    class operator Multiply(const AFactor: Double; const APoint: TVector3): TVector3; inline;
    class operator Divide(const APoint: TVector3; const AFactor: Double): TVector3;
    case Integer of
      0: (V: TVector3Array;);
      1: (X: Double;
          Y: Double;
          Z: Double;);
  end;

  TMatrix3 = record
  private
    function Scale(const AFactor: Double): TMatrix3;
  public
    class operator Multiply(const M: TMatrix3; const V: TVector3): TVector3;
    class operator Multiply(const AMatrix1, AMatrix2: TMatrix3): TMatrix3;
    function det: Double;
    function inv: TMatrix3;
    function Adjoint: TMatrix3;
    case Integer of
      0: (M: TMatrix3Data;);
      1: (m11, m12, m13: Double;
          m21, m22, m23: Double;
          m31, m32, m33: Double;);
  end;


  PMatrix4 = ^TMatrix4;
  TMatrix4 = record
  private
    function DetInternal(const a1, a2, a3, b1, b2, b3, c1, c2, c3: Double): Double; inline;
    function Scale(const AFactor: Double): TMatrix4;
  public
    constructor Create(const AM11, AM12, AM13, AM14, AM21, AM22, AM23, AM24, AM31, AM32, AM33,
      AM34, AM41, AM42, AM43, AM44: Double);
    class function CreateRotationAZO(const AAzi, AZen, AOtk: Double): TMatrix4; static;
    class operator Implicit(const Matrix4Data: TMatrix4Data): TMatrix4; inline;
    class operator Explicit(const M: TMatrix4): TMatrix3;
//    class operator Implicit(const M: TMatrix4): variant;
    class operator Multiply(const APoint1, APoint2: TMatrix4): TMatrix4;
    class operator Multiply(const M: TMatrix4; V:TVector3): TVector3;
    class operator Multiply(const M: TMatrix4; F: Double): TMatrix4;
    class operator Add(const a, b: TMatrix4): TMatrix4;
    class operator Negative(const m: TMatrix4): TMatrix4;
    function T: TMatrix4;
    function det: Double;
    function inv: TMatrix4;
    function Adjoint: TMatrix4;
    // если матрица вращения то получаем углы Эйлера
    function Azimut: Double;
    function Zenit: Double;
    function Otklonitel: Double;
    function Vector(index: Integer): TVector3;
    case Integer of
      0: (M: TMatrix4Data;);
      1: (m11, m12, m13, m14: Double;
          m21, m22, m23, m24: Double;
          m31, m32, m33, m34: Double;
          m41, m42, m43, m44: Double);
  end;

 const Matrix4Identity: TMatrix4 = (m11: 1; m12: 0; m13: 0; m14: 0;
                                     m21: 0; m22: 1; m23: 0; m24: 0;
                                     m31: 0; m32: 0; m33: 1; m34: 0;
                                     m41: 0; m42: 0; m43: 0; m44: 1;);
 type
  TQuaternion = record
    constructor Create(const AAxis: TVector3; const AAngle: Double); overload;
//    constructor Create(const AAzi, AZen, AOtk: Double); overload;
//    constructor Create(const AMatrix: TMatrix3D); overload;

    class operator Implicit(const AQuaternion: TQuaternion): TMatrix4;
    class operator Multiply(const AQuaternion1, AQuaternion2: TQuaternion): TQuaternion;

    // calculates quaternion magnitude
    function Length:  Double;
    function Normalize: TQuaternion;

    case Integer of
      0: (V: TVector4Array;);
      1: (Re: Double;
          Im: TVector3;);
      2: (W,X,Y,Z: Double;);
      3: (q0,q1,q2,q3: Double;);
    end;


implementation

{ TVector3 }

class operator TVector3.Add(const APoint1, APoint2: TVector3): TVector3;
begin
  Result.X := APoint1.X + APoint2.X;
  Result.Y := APoint1.Y + APoint2.Y;
  Result.Z := APoint1.Z + APoint2.Z;
end;

constructor TVector3.Create(AX, AY, AZ: Double);
begin
  Self.X := AX;
  Self.Y := AY;
  Self.Z := AZ;
end;

function TVector3.cross(const APoint: TVector3): TVector3;
begin
  Result.X := (Self.Y * APoint.Z) - (Self.Z * APoint.Y);
  Result.Y := (Self.Z * APoint.X) - (Self.X * APoint.Z);
  Result.Z := (Self.X * APoint.Y) - (Self.Y * APoint.X);
end;

class operator TVector3.Divide(const APoint: TVector3; const AFactor: Double): TVector3;
begin
  if AFactor <> 0 then Result := APoint * (1 / AFactor)
  else Result := APoint;
end;

function TVector3.dot(const APoint: TVector3): Double;
begin
  Result := (Self.X * APoint.X) + (Self.Y * APoint.Y) + (Self.Z * APoint.Z);
end;

class operator TVector3.Multiply(const AFactor: Double; const APoint: TVector3): TVector3;
begin
  Result.X := APoint.X * AFactor;
  Result.Y := APoint.Y * AFactor;
  Result.Z := APoint.Z * AFactor;
end;

class operator TVector3.Multiply(const APoint: TVector3; const AFactor: Double): TVector3;
begin
  Result.X := APoint.X * AFactor;
  Result.Y := APoint.Y * AFactor;
  Result.Z := APoint.Z * AFactor;
end;

class operator TVector3.Negative(const APoint: TVector3): TVector3;
begin
  Result.X := - APoint.X;
  Result.Y := - APoint.Y;
  Result.Z := - APoint.Z;
end;

class operator TVector3.Subtract(const APoint1, APoint2: TVector3): TVector3;
begin
  Result.X := APoint1.X - APoint2.X;
  Result.Y := APoint1.Y - APoint2.Y;
  Result.Z := APoint1.Z - APoint2.Z;
end;

function TVector3.L: TMatrix4Data;
begin
  Result := TMatrix4.Create(0,-X,-Y,-Z,
                            X, 0,-Z, Y,
                            Y, Z, 0,-X,
                            Z,-Y, X, 0).M;
end;

function TVector3.Length: Double;
begin
  Result := Sqrt(Self.dot(Self));
end;

function TVector3.R: TMatrix4Data;
begin
    Result := TMatrix4.Create(0,-X,-Y,-Z,
                               X, 0, Z,-Y,
                               Y,-Z, 0, X,
                               Z, Y,-X, 0).M;
end;

{ TMatrix4 }

class operator TMatrix4.Add(const a, b: TMatrix4): TMatrix4;
 var
  i, j: Integer;
begin
  for i := 0 to High(a.M) do for j := 0 to High(a.M[0]) do Result.M[i][j] := a.M[i][j] + b.M[i][j];
end;

function TMatrix4.Adjoint: TMatrix4;
var
  a1, a2, a3, a4, b1, b2, b3, b4, c1, c2, c3, c4, d1, d2, d3, d4: Double;
begin
  a1 := Self.M[0][0];
  b1 := Self.M[0][1];
  c1 := Self.M[0][2];
  d1 := Self.M[0][3];
  a2 := Self.M[1][0];
  b2 := Self.M[1][1];
  c2 := Self.M[1][2];
  d2 := Self.M[1][3];
  a3 := Self.M[2][0];
  b3 := Self.M[2][1];
  c3 := Self.M[2][2];
  d3 := Self.M[2][3];
  a4 := Self.M[3][0];
  b4 := Self.M[3][1];
  c4 := Self.M[3][2];
  d4 := Self.M[3][3];

  Result.M[0][0] := DetInternal(b2, b3, b4, c2, c3, c4, d2, d3, d4);
  Result.M[1][0] := -DetInternal(a2, a3, a4, c2, c3, c4, d2, d3, d4);
  Result.M[2][0] := DetInternal(a2, a3, a4, b2, b3, b4, d2, d3, d4);
  Result.M[3][0] := -DetInternal(a2, a3, a4, b2, b3, b4, c2, c3, c4);

  Result.M[0][1] := -DetInternal(b1, b3, b4, c1, c3, c4, d1, d3, d4);
  Result.M[1][1] := DetInternal(a1, a3, a4, c1, c3, c4, d1, d3, d4);
  Result.M[2][1] := -DetInternal(a1, a3, a4, b1, b3, b4, d1, d3, d4);
  Result.M[3][1] := DetInternal(a1, a3, a4, b1, b3, b4, c1, c3, c4);

  Result.M[0][2] := DetInternal(b1, b2, b4, c1, c2, c4, d1, d2, d4);
  Result.M[1][2] := -DetInternal(a1, a2, a4, c1, c2, c4, d1, d2, d4);
  Result.M[2][2] := DetInternal(a1, a2, a4, b1, b2, b4, d1, d2, d4);
  Result.M[3][2] := -DetInternal(a1, a2, a4, b1, b2, b4, c1, c2, c4);

  Result.M[0][3] := -DetInternal(b1, b2, b3, c1, c2, c3, d1, d2, d3);
  Result.M[1][3] := DetInternal(a1, a2, a3, c1, c2, c3, d1, d2, d3);
  Result.M[2][3] := -DetInternal(a1, a2, a3, b1, b2, b3, d1, d2, d3);
  Result.M[3][3] := DetInternal(a1, a2, a3, b1, b2, b3, c1, c2, c3);
end;

constructor TMatrix4.Create(const AM11, AM12, AM13, AM14, AM21, AM22, AM23, AM24, AM31, AM32, AM33, AM34, AM41, AM42, AM43, AM44: Double);
begin
  Self.m11 := AM11;
  Self.m12 := AM12;
  Self.m13 := AM13;
  Self.m14 := AM14;
  Self.m21 := AM21;
  Self.m22 := AM22;
  Self.m23 := AM23;
  Self.m24 := AM24;
  Self.m31 := AM31;
  Self.m32 := AM32;
  Self.m33 := AM33;
  Self.m34 := AM34;
  Self.m41 := AM41;
  Self.m42 := AM42;
  Self.m43 := AM43;
  Self.m44 := AM44;
end;

class function TMatrix4.CreateRotationAZO(const AAzi, AZen, AOtk: Double): TMatrix4;
var
  sA, sZ, sO: Extended;
  cA, cZ, cO: Extended;
begin
  System.SineCosine(AAzi, sA, cA);
  System.SineCosine(AZen, sZ, cZ);
  System.SineCosine(AOtk, sO, cO);

  Result := Matrix4Identity;
/// по Горизонту
  Result.m11 :=  cO*cZ*cA - sO*sA;   Result.m12 :=  cO*cZ*sA + sO*cA;   Result.m13 := -cO*sZ;
  Result.m21 := -sO*cZ*cA - cO*sA;   Result.m22 := -sO*cZ*sA + cO*cA;   Result.m23 :=  sO*sZ;
  Result.m31 :=  sZ*cA;              Result.m32 :=  sZ*sA;              Result.m33 :=  cZ;
/// по буржуйски
//  Result.m11 := (cA * cO) + (sA * sZ * sO);   Result.m12 := (- cA * sO) + (sA * sZ * cO); Result.m13 := sA * cZ;
//  Result.m21 := sO * cZ;                      Result.m22 := cO * cZ;                      Result.m23 := - sZ;
//  Result.m31 := (- sA * cO) + (cA * sZ * sO); Result.m32 := (sO * sA) + (cA * sZ * cO);   Result.m33 := cA * cZ;
end;

function TMatrix4.Otklonitel: Double;
begin
/// по Горизонту
  Result := ArcTan2(m23, -m13);
end;

function TMatrix4.Azimut: Double;
begin
/// по Горизонту
  Result := ArcTan2(m32, m31);
end;

function TMatrix4.Zenit: Double;
begin
/// по Горизонту
  Result := ArcCos(m33);
end;

function TMatrix4.det: Double;
begin
  Result :=
    Self.M[0][0] * DetInternal(Self.M[1][1], Self.M[2][1], Self.M[3][1], Self.M[1][2],
    Self.M[2][2], Self.M[3][2], Self.M[1][3], Self.M[2][3], Self.M[3][3])
    - Self.M[0][1] * DetInternal(Self.M[1][0], Self.M[2][0], Self.M[3][0], Self.M[1][2], Self.M[2][2],
    Self.M[3][2], Self.M[1][3], Self.M[2][3], Self.M[3][3])
    + Self.M[0][2] * DetInternal(Self.M[1][0], Self.M[2][0], Self.M[3][0], Self.M[1][1], Self.M[2][1],
    Self.M[3][1], Self.M[1][3], Self.M[2][3], Self.M[3][3])
    - Self.M[0][3] * DetInternal(Self.M[1][0], Self.M[2][0], Self.M[3][0], Self.M[1][1], Self.M[2][1],
    Self.M[3][1], Self.M[1][2], Self.M[2][2], Self.M[3][2]);
end;

function TMatrix4.DetInternal(const a1, a2, a3, b1, b2, b3, c1, c2, c3: Double): Double;
begin
  Result := a1 * (b2 * c3 - b3 * c2) - b1 * (a2 * c3 - a3 * c2) + c1 * (a2 * b3 - a3 * b2);
end;

class operator TMatrix4.Explicit(const M: TMatrix4): TMatrix3;
begin
  Result.m11 := M.m11; Result.m12 := M.m12; Result.m13 := M.m13;
  Result.m21 := M.m21; Result.m22 := M.m22; Result.m23 := M.m23;
  Result.m31 := M.m31; Result.m32 := M.m32; Result.m33 := M.m33;
end;

//class operator TMatrix4.Implicit(const M: TMatrix4): variant;
//begin
//  Result.m3x4.m11 := M.m11; Result.m3x4.m12 := M.m12; Result.m3x4.m13 := M.m13; Result.m3x4.m14 := M.m14;
//  Result.m3x4.m21 := M.m21; Result.m3x4.m22 := M.m22; Result.m3x4.m23 := M.m23; Result.m3x4.m24 := M.m24;
//  Result.m3x4.m31 := M.m31; Result.m3x4.m32 := M.m32; Result.m3x4.m33 := M.m33; Result.m3x4.m34 := M.m34;
//end;

class operator TMatrix4.Implicit(const Matrix4Data: TMatrix4Data): TMatrix4;
begin
  Result.M := Matrix4Data;
end;

function TMatrix4.inv: TMatrix4;
begin
  Result := Self.Adjoint.Scale(1/det);
end;

class operator TMatrix4.Multiply(const M: TMatrix4; F: Double): TMatrix4;
begin
  Result := M.Scale(F);
end;

class operator TMatrix4.Multiply(const M: TMatrix4; V: TVector3): TVector3;
begin
  with M, V do
   begin
    Result.X := m11*x + m12*y + m13*z + m14;
    Result.Y := m21*x + m22*y + m23*z + m24;
    Result.Z := m31*x + m32*y + m33*z + m34;
   end;
end;

class operator TMatrix4.Negative(const m: TMatrix4): TMatrix4;
 var
  i, j: Integer;
begin
  for i := 0 to High(m.M) do for j := 0 to High(m.M[0]) do Result.M[i][j] := -m.M[i][j];
end;

function TMatrix4.Scale(const AFactor: Double): TMatrix4;
var
  i: Integer;
begin
  for i := 0 to 3 do
  begin
    Result.M[i][0] := Self.M[i][0] * AFactor;
    Result.M[i][1] := Self.M[i][1] * AFactor;
    Result.M[i][2] := Self.M[i][2] * AFactor;
    Result.M[i][3] := Self.M[i][3] * AFactor;
  end;
end;

function TMatrix4.T: TMatrix4;
begin
  Result.M[0][0] := Self.M[0][0];
  Result.M[0][1] := Self.M[1][0];
  Result.M[0][2] := Self.M[2][0];
  Result.M[0][3] := Self.M[3][0];
  Result.M[1][0] := Self.M[0][1];
  Result.M[1][1] := Self.M[1][1];
  Result.M[1][2] := Self.M[2][1];
  Result.M[1][3] := Self.M[3][1];
  Result.M[2][0] := Self.M[0][2];
  Result.M[2][1] := Self.M[1][2];
  Result.M[2][2] := Self.M[2][2];
  Result.M[2][3] := Self.M[3][2];
  Result.M[3][0] := Self.M[0][3];
  Result.M[3][1] := Self.M[1][3];
  Result.M[3][2] := Self.M[2][3];
  Result.M[3][3] := Self.M[3][3];
end;

function TMatrix4.Vector(index: Integer): TVector3;
begin
  Result.X := Self.M[0][index];
  Result.Y := Self.M[1][index];
  Result.Z := Self.M[2][index];
end;

class operator TMatrix4.Multiply(const APoint1, APoint2: TMatrix4): TMatrix4;
begin
  Result.M[0][0] := APoint1.M[0][0] * APoint2.M[0][0] + APoint1.M[0][1] * APoint2.M[1][0]
    + APoint1.M[0][2] * APoint2.M[2][0] + APoint1.M[0][3] * APoint2.M[3][0];
  Result.M[0][1] := APoint1.M[0][0] * APoint2.M[0][1] + APoint1.M[0][1] * APoint2.M[1][1]
    + APoint1.M[0][2] * APoint2.M[2][1] + APoint1.M[0][3] * APoint2.M[3][1];
  Result.M[0][2] := APoint1.M[0][0] * APoint2.M[0][2] + APoint1.M[0][1] * APoint2.M[1][2]
    + APoint1.M[0][2] * APoint2.M[2][2] + APoint1.M[0][3] * APoint2.M[3][2];
  Result.M[0][3] := APoint1.M[0][0] * APoint2.M[0][3] + APoint1.M[0][1] * APoint2.M[1][3]
    + APoint1.M[0][2] * APoint2.M[2][3] + APoint1.M[0][3] * APoint2.M[3][3];
  Result.M[1][0] := APoint1.M[1][0] * APoint2.M[0][0] + APoint1.M[1][1] * APoint2.M[1][0]
    + APoint1.M[1][2] * APoint2.M[2][0] + APoint1.M[1][3] * APoint2.M[3][0];
  Result.M[1][1] := APoint1.M[1][0] * APoint2.M[0][1] + APoint1.M[1][1] * APoint2.M[1][1]
    + APoint1.M[1][2] * APoint2.M[2][1] + APoint1.M[1][3] * APoint2.M[3][1];
  Result.M[1][2] := APoint1.M[1][0] * APoint2.M[0][2] + APoint1.M[1][1] * APoint2.M[1][2]
    + APoint1.M[1][2] * APoint2.M[2][2] + APoint1.M[1][3] * APoint2.M[3][2];
  Result.M[1][3] := APoint1.M[1][0] * APoint2.M[0][3] + APoint1.M[1][1] * APoint2.M[1][3]
    + APoint1.M[1][2] * APoint2.M[2][3] + APoint1.M[1][3] * APoint2.M[3][3];
  Result.M[2][0] := APoint1.M[2][0] * APoint2.M[0][0] + APoint1.M[2][1] * APoint2.M[1][0]
    + APoint1.M[2][2] * APoint2.M[2][0] + APoint1.M[2][3] * APoint2.M[3][0];
  Result.M[2][1] := APoint1.M[2][0] * APoint2.M[0][1] + APoint1.M[2][1] * APoint2.M[1][1]
    + APoint1.M[2][2] * APoint2.M[2][1] + APoint1.M[2][3] * APoint2.M[3][1];
  Result.M[2][2] := APoint1.M[2][0] * APoint2.M[0][2] + APoint1.M[2][1] * APoint2.M[1][2]
    + APoint1.M[2][2] * APoint2.M[2][2] + APoint1.M[2][3] * APoint2.M[3][2];
  Result.M[2][3] := APoint1.M[2][0] * APoint2.M[0][3] + APoint1.M[2][1] * APoint2.M[1][3]
    + APoint1.M[2][2] * APoint2.M[2][3] + APoint1.M[2][3] * APoint2.M[3][3];
  Result.M[3][0] := APoint1.M[3][0] * APoint2.M[0][0] + APoint1.M[3][1] * APoint2.M[1][0]
    + APoint1.M[3][2] * APoint2.M[2][0] + APoint1.M[3][3] * APoint2.M[3][0];
  Result.M[3][1] := APoint1.M[3][0] * APoint2.M[0][1] + APoint1.M[3][1] * APoint2.M[1][1]
    + APoint1.M[3][2] * APoint2.M[2][1] + APoint1.M[3][3] * APoint2.M[3][1];
  Result.M[3][2] := APoint1.M[3][0] * APoint2.M[0][2] + APoint1.M[3][1] * APoint2.M[1][2]
    + APoint1.M[3][2] * APoint2.M[2][2] + APoint1.M[3][3] * APoint2.M[3][2];
  Result.M[3][3] := APoint1.M[3][0] * APoint2.M[0][3] + APoint1.M[3][1] * APoint2.M[1][3]
    + APoint1.M[3][2] * APoint2.M[2][3] + APoint1.M[3][3] * APoint2.M[3][3];
end;

{ TQuaternion }

//constructor TQuaternion.Create(const AAzi, AZen, AOtk: Double);
//begin
//  Self := TQuaternion.Create(TVector3.Create(0, 0, 1), AAzi)
//        * TQuaternion.Create(TVector3.Create(0, 1, 0), AZen)
//        * TQuaternion.Create(TVector3.Create(0, 0, 1), AOtk);
//end;

constructor TQuaternion.Create(const AAxis: TVector3; const AAngle: Double);
 var
  AxisLen, Sine, Cosine: Extended;
begin
  AxisLen := AAxis.Length;
  SineCosine(AAngle / 2, Sine, Cosine);
  Self.Re := Cosine;
  Self.Im := AAxis * (Sine / AxisLen);
end;

class operator TQuaternion.Implicit(const AQuaternion: TQuaternion): TMatrix4;
var
  NormQuat: TQuaternion;
  xx, xy, xz, xw, yy, yz, yw, zz, zw: Double;
begin
  NormQuat := AQuaternion.Normalize;

  xx := NormQuat.X * NormQuat.X;
  xy := NormQuat.X * NormQuat.Y;
  xz := NormQuat.X * NormQuat.Z;
  xw := NormQuat.X * NormQuat.W;
  yy := NormQuat.Y * NormQuat.Y;
  yz := NormQuat.Y * NormQuat.Z;
  yw := NormQuat.Y * NormQuat.W;
  zz := NormQuat.Z * NormQuat.Z;
  zw := NormQuat.Z * NormQuat.W;

  FillChar(Result, Sizeof(Result), 0);
  Result.M11 := 1 - 2 * (yy + zz);
  Result.M21 := 2 * (xy - zw);
  Result.M31 := 2 * (xz + yw);
  Result.M12 := 2 * (xy + zw);
  Result.M22 := 1 - 2 * (xx + zz);
  Result.M32 := 2 * (yz - xw);
  Result.M13 := 2 * (xz - yw);
  Result.M23 := 2 * (yz + xw);
  Result.M33 := 1 - 2 * (xx + yy);
  Result.M44 := 1;
end;

function TQuaternion.Length: Double;
begin
  Result := Sqrt(Im.Dot(Im) + Re * Re);
end;

class operator TQuaternion.Multiply(const AQuaternion1, AQuaternion2: TQuaternion): TQuaternion;
begin
  Result.W := AQuaternion1.W * AQuaternion2.W - AQuaternion1.X * AQuaternion2.X - AQuaternion1.Y * AQuaternion2.Y - AQuaternion1.Z * AQuaternion2.Z;
  Result.X := AQuaternion1.W * AQuaternion2.X + AQuaternion2.W * AQuaternion1.X + AQuaternion1.Y * AQuaternion2.Z - AQuaternion1.Z * AQuaternion2.Y;
  Result.Y := AQuaternion1.W * AQuaternion2.Y + AQuaternion2.W * AQuaternion1.Y + AQuaternion1.Z * AQuaternion2.X - AQuaternion1.X * AQuaternion2.Z;
  Result.Z := AQuaternion1.W * AQuaternion2.Z + AQuaternion2.W * AQuaternion1.Z + AQuaternion1.X * AQuaternion2.Y - AQuaternion1.Y * AQuaternion2.X;
end;

function TQuaternion.Normalize: TQuaternion;
 var
  InvLen: Double;
begin
  InvLen := 1 / Self.Length;
  Result.Im := Self.Im * InvLen;
  Result.Re := Self.Re * InvLen;
end;

{ TMatrix3 }

function TMatrix3.Adjoint: TMatrix3;
var
  a1, a2, a3, b1, b2, b3, c1, c2, c3: Double;
begin
  a1 := Self.M[0][0];
  a2 := Self.M[0][1];
  a3 := Self.M[0][2];
  b1 := Self.M[1][0];
  b2 := Self.M[1][1];
  b3 := Self.M[1][2];
  c1 := Self.M[2][0];
  c2 := Self.M[2][1];
  c3 := Self.M[2][2];

  Result.M[0][0] := (b2 * c3 - c2 * b3);
  Result.M[1][0] := -(b1 * c3 - c1 * b3);
  Result.M[2][0] := (b1 * c2 - c1 * b2);

  Result.M[0][1] := -(a2 * c3 - c2 * a3);
  Result.M[1][1] := (a1 * c3 - c1 * a3);
  Result.M[2][1] := -(a1 * c2 - c1 * a2);

  Result.M[0][2] := (a2 * b3 - b2 * a3);
  Result.M[1][2] := -(a1 * b3 - b1 * a3);
  Result.M[2][2] := (a1 * b2 - b1 * a2);
end;

function TMatrix3.det: Double;
begin
  Result := Self.M[0][0] * (Self.M[1][1] * Self.M[2][2] - Self.M[2][1] * Self.M[1][2]) - Self.M[0][1]
    * (Self.M[1][0] * Self.M[2][2] - Self.M[2][0] * Self.M[1][2]) + Self.M[0][2] * (Self.M[1][0]
    * Self.M[2][1] - Self.M[2][0] * Self.M[1][1]);
end;

function TMatrix3.inv: TMatrix3;
begin
  Result:= Self.Adjoint.Scale(1 / Det);
end;

class operator TMatrix3.Multiply(const AMatrix1, AMatrix2: TMatrix3): TMatrix3;
begin
  Result.m11 := AMatrix1.m11 * AMatrix2.m11 + AMatrix1.m12 * AMatrix2.m21 + AMatrix1.m13 * AMatrix2.m31;
  Result.m12 := AMatrix1.m11 * AMatrix2.m12 + AMatrix1.m12 * AMatrix2.m22 + AMatrix1.m13 * AMatrix2.m32;
  Result.m13 := AMatrix1.m11 * AMatrix2.m13 + AMatrix1.m12 * AMatrix2.m23 + AMatrix1.m13 * AMatrix2.m33;
  Result.m21 := AMatrix1.m21 * AMatrix2.m11 + AMatrix1.m22 * AMatrix2.m21 + AMatrix1.m23 * AMatrix2.m31;
  Result.m22 := AMatrix1.m21 * AMatrix2.m12 + AMatrix1.m22 * AMatrix2.m22 + AMatrix1.m23 * AMatrix2.m32;
  Result.m23 := AMatrix1.m21 * AMatrix2.m13 + AMatrix1.m22 * AMatrix2.m23 + AMatrix1.m23 * AMatrix2.m33;
  Result.m31 := AMatrix1.m31 * AMatrix2.m11 + AMatrix1.m32 * AMatrix2.m21 + AMatrix1.m33 * AMatrix2.m31;
  Result.m32 := AMatrix1.m31 * AMatrix2.m12 + AMatrix1.m32 * AMatrix2.m22 + AMatrix1.m33 * AMatrix2.m32;
  Result.m33 := AMatrix1.m31 * AMatrix2.m13 + AMatrix1.m32 * AMatrix2.m23 + AMatrix1.m33 * AMatrix2.m33;
end;

class operator TMatrix3.Multiply(const M: TMatrix3; const V: TVector3): TVector3;
begin
  with M, V do
   begin
    Result.X := m11*x + m12*y + m13*z;
    Result.Y := m21*x + m22*y + m23*z;
    Result.Z := m31*x + m32*y + m33*z;
   end;
end;

function TMatrix3.Scale(const AFactor: Double): TMatrix3;
var
  I: Integer;
begin
  for I := 0 to 2 do
  begin
    Result.M[I][0] := Self.M[I][0] * AFactor;
    Result.M[I][1] := Self.M[I][1] * AFactor;
    Result.M[I][2] := Self.M[I][2] * AFactor;
  end;
end;

end.

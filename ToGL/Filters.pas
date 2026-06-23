unit Filters;

interface

uses System.IOUtils,  System.Generics.Collections, Data.DB, RLDataSet, DateUtils, Math, System.Math.Vectors,
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.Menus, Vcl.ComCtrls;


procedure Monotone(const x: TArray<Double>; y : TArray<Double>);
procedure Mave(const x: TArray<Double>; y : TArray<Double>; n: Integer);
procedure Speed(const x: TArray<Double>; y : TArray<Double>; speed: Double);
procedure DelJumps(const x: TArray<Double>; y : TArray<Double>; MinDelta:Double; MaxTime: TDateTime);


implementation

uses ToGLMainForm;

procedure Monotone(const x: TArray<Double>; y : TArray<Double>);
begin
  for var i := 1 to High(x) do if x[i-1] >= x[i] then
   begin
    raise Exception.Createfmt('DateTime Error x[i-1] >= x[i] i:%d ',[i]);
   end;
  if y[0] < Y[High(Y)] then
   begin
     var cur := y[0];
     for var i := 1 to High(y) do
      if y[i] < cur then y[i] := cur
      else cur := y[i];
   end
  else
   begin
     var cur := y[0];
     for var i := 1 to High(y) do
      if y[i] > cur then y[i] := cur
      else cur := y[i];
   end
end;

function dir1x9(y0: PDouble; h: Double = 1): Double;
const
  R: TArray<Double> = [1 / 280, -4 / 105, 1 / 5, -4 / 5, 0, 4 / 5, -1 / 5, 4 / 105, -1 / 280];
 // R: TArray<Double> = [-1/2, 0, 1.2];
 //R: TArray<Double> = [1/12,	-2/3,	0,	2/3,	-1/12];
begin
  Result := 0;
  Dec(y0, Length(R) div 2);
  for var k in R do
  begin
    Result := Result + k * y0^;
    Inc(y0);
  end;
  Result := Result / (h * h);
end;

procedure DelJumps(const x: TArray<Double>; y : TArray<Double>; MinDelta: Double; MaxTime: TDateTime);
 var
 i, i0: Integer;
 R0,Ri,x0: Double;
 function VLen(i,j: Integer): Double;
 begin
   Result := Hypot(x[i]-x[j],y[i]-y[j]);
 end;
begin
   i := 0;
   while i < Length(y)-1 do
   begin
    var d := y[i]-y[i+1];
    if Abs(d) >= MinDelta then
     begin
      x0 := x[i];
      R0 := VLen(i,i+1);
      i0 := i;
      Inc(i);
      while (i < Length(x)) and ((x[i]-x0) < MaxTime)  do
       begin
         Ri := VLen(i0,i);
         if (Ri < R0) and ((Ri/R0*100) < 10) then
          begin
           for var j := i0+1 to i-1 do y[j] := y[j] +d;
            Break;
          end;
         Inc(i);
       end;
     end
     else Inc(i);
   end;
end;



procedure Mave(const x: TArray<Double>; y : TArray<Double>; n: Integer);
 var
  yf: TArray<Double>;
begin
  SetLength(yf,Length(y));
  for var I := n to High(y)-n do
   begin
    yf[i] :=0;
    for var j := i-n to i+n do yf[i] := yf[i]+ y[j];
    yf[i] := yf[i]/(2*n+1);
   end;
  for var I := n to High(y)-n do y[i] := yf[i];

end;

procedure Speed(const x: TArray<Double>; y : TArray<Double>; speed: Double);
 var
  yf: TArray<Double>;
begin
  SetLength(yf,Length(y));
  for var I := 4 to High(y)-4 do yf[i] := dir1x9(@y[i]);
  for var I := 0 to High(y) do y[i] := yf[i];

end;

end.

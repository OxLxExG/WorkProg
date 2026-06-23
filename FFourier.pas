// Gunnar Bolle, FPrefect@t-online.de
// Simple FFT component
// Feel free to use this code
// Based upon some free pascal code i found somewhere i can't remember :(
// If you've seen these fragments before please let me know, i'll give the
// author his credit.
//
// Please note : I didn't have the time to write a sample application for this.
//               Please do not ask me about how to use this one ...
//               If you're aware of FFT you'll know how. Otherwise, try
//               some of those neat Button components at DSP. They're quite easy
//               to handle.


unit FFourier;

interface

uses MathIntf, debug_except,
  Windows, Messages, SysUtils, Classes, math;

//procedure Register;

type
//TComplex = Record
//   Real : double;
//   imag : double;
//end;
//
//TOnGetDataEvent = procedure(index : integer; var Value : TComplex) of Object;

//TComplexArray = array [0..1024] of TComplex;
//PComplexArray = ^TComplexArray;

EFastFourierError = class(EBaseException);

TFFourier = Class(TInterfacedObject, IFourier, ILastMathError)
private
    FNumSamples: integer;
    FNumBits: Word;
    FInBuffer, FOutBuffer: TArray<TComplex>;
    Fres: TArray<Double>;
//    FInBuffer      : PComplexArray;
//    FOutBuffer     : PComplexArray;
//    FOnGetData     : TOnGetDataEvent;

    function  IsPowerOfTwo ( x: word ): boolean;
    function  NumberOfBitsNeeded ( PowerOfTwo: word ): word;
    function  ReverseBits ( index, NumBits: word ): word;
    procedure FourierTransform (const ain: TArray<TComplex>;var aout: TArray<TComplex>; AngleNumerator:  double );


protected
  	function GetLastError(out err: PAnsiChar): HRESULT; stdcall;
 	  function fft(const x: PDouble; Len: Integer): HRESULT; stdcall;
 	  function ifft(var x: PDouble): HRESULT; stdcall;
 	  function GetLastFF(out x: PComplex): HRESULT; stdcall;
end;

implementation


function TFFourier.GetLastError(out err: PAnsiChar): HRESULT;
begin
  Result := S_OK;
end;

function TFFourier.GetLastFF(out x: PComplex): HRESULT;
begin
  Result := S_OK;
  x := @FOutBuffer[0];
end;

function TFFourier.ifft(var x: PDouble): HRESULT;
 var
  i: word;
begin
  FourierTransform(FOutBuffer, FInBuffer, -2*PI);
  SetLength(Fres, FNumSamples);
  (* Normalize the resulting time samples... *)
  for i := 0 to FNumSamples-1 do Fres[i] := FInBuffer[i].x / FNumSamples;
  x := @Fres[0];
  Result := S_OK;
end;

function TFFourier.fft(const x: PDouble; Len: Integer): HRESULT;
 var
  i: Integer;

begin
  Result := S_OK;
  FNumSamples := Len;
  if not IsPowerOfTwo(FNumSamples) or (FNumSamples<2) then raise EFastFourierError.Create('NumSamples is not a positive integer power of 2');
  FNumBits := NumberOfBitsNeeded(FNumSamples);
  SetLength(FInBuffer, FNumSamples);
  SetLength(FOutBuffer, FNumSamples);
  for I := 0 to len-1 do
   begin
    FInBuffer[i].x := PdoubleArray(x)[i];
    FInBuffer[i].y := 0;
   end;
  FourierTransform(FInBuffer, FOutBuffer,2*PI);
end;

function TFFourier.IsPowerOfTwo ( x: word ): boolean;
 var
  i, y:  word;
begin
    y := 2;
    for i := 1 to 31 do
     begin
      if x = y then exit(True);
      y := y SHL 1;
     end;
    Result := FALSE;
end;


function TFFourier.NumberOfBitsNeeded ( PowerOfTwo: word ): word;
 var
  i: word;
begin
  for i := 0 to 16 do if (PowerOfTwo AND (1 SHL i)) <> 0 then exit(I);
  Result := 0;
end;


function TFFourier.ReverseBits (index, NumBits: word): word;
  var
   i: word;
begin
    Result := 0;
    for i := 0 to NumBits-1 do
    begin
      Result := (Result SHL 1) OR (index AND 1);
      index := index SHR 1;
    end;
end;


procedure TFFourier.FourierTransform (const ain: TArray<TComplex>; var aout: TArray<TComplex>; AngleNumerator:  double);
var
    i, j, k, n, BlockSize, BlockEnd: word;
    delta_angle, delta_ar: double;
    alpha, beta: double;
    tr, ti, ar, ai: double;
begin
    for i := 0 to FNumSamples-1 do aout[ReverseBits (i, FNumBits)] := ain[i];
    BlockEnd := 1;
    BlockSize := 2;
    while BlockSize <= FNumSamples do
    begin
        delta_angle := AngleNumerator / BlockSize;
        alpha := sin ( 0.5 * delta_angle );
        alpha := 2.0 * alpha * alpha;
        beta := sin ( delta_angle );

        i := 0;
        while i < FNumSamples do
        begin
            ar := 1.0;    (* cos(0) *)
            ai := 0.0;    (* sin(0) *)

            j := i;
            for n := 0 to BlockEnd-1 do
             begin
                k := j + BlockEnd;
                tr := ar*aout[k].x - ai*aout[k].y;
                ti := ar*aout[k].y + ai*aout[k].x;
                aout[k].x := aout[j].x - tr;
                aout[k].y := aout[j].y - ti;
                aout[j].x := aout[j].x + tr;
                aout[j].y := aout[j].y + ti;
                delta_ar := alpha*ar + beta*ai;
                ai := ai - (alpha*ai - beta*ar);
                ar := ar - delta_ar;
                INC(j);
             end;
            i := i + BlockSize;
        end;
        BlockEnd := BlockSize;
        BlockSize := BlockSize SHL 1;
    end;
end;


{procedure TFFourier.fft;
begin
  FourierTransform( 2*PI);
end;


procedure TFFourier.ifft;
var
    i: word;
begin
    FourierTransform ( -2*PI);

    (* Normalize the resulting time samples... *)
    for i := 0 to FNumSamples-1 do begin
        FOutBuffer[i].x := FOutBuffer[i].x / FNumSamples;
        FOutBuffer[i].y := FOutBuffer[i].y / FNumSamples;
    end;
end;   }


{procedure TFFourier.CalcFrequency (FrequencyIndex: word);
var
    k: word;
    cos1, cos2, cos3, theta, beta: double;
    sin1, sin2, sin3: double;
begin
    FOutBuffer[0].Real := 0.0;
    FOutBuffer[0].Imag := 0.0;
    theta := 2*PI * FrequencyIndex / FNumSamples;
    sin1 := sin ( -2 * theta );
    sin2 := sin ( -theta );
    cos1 := cos ( -2 * theta );
    cos2 := cos ( -theta );
    beta := 2 * cos2;
    for k := 0 to FNumSamples-1 do begin
        sin3 := beta*sin2 - sin1;
        sin1 := sin2;
        sin2 := sin3;
        cos3 := beta*cos2 - cos1;
        cos1 := cos2;
        cos2 := cos3;
        FOutBuffer[0].Real := FOutBuffer[0].Real + FInBuffer[k].Real*cos3 - FInBuffer[k].Imag*sin3;
        FOutBuffer[0].Imag := FOutBuffer[0].Imag + FInBuffer[k].Imag*cos3 + FInBuffer[k].Real*sin3;
    end;
end; }

{procedure Register;
begin
  RegisterComponents('System', [TFFourier]);
end;}

end.

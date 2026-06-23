unit Fifo.FFT;

interface

uses debug_except, Fifo, CFifo, MathIntf, IndexBuffer,
     System.SysUtils, System.Classes, System.Math, System.Generics.Collections, System.SyncObjs, System.Threading;

const
    FFT_LEN_1 = 1024;
//    FFT_OVERSAMP = FFT_LEN div 4;

//    FFT_SAMPLES = FFT_LEN - FFT_OVERSAMP*2;// FFT_LEN div 2;
//    FFT_AMP_LEN = FFT_LEN div 2;

type
  TfifoFFT = class(TIndexFifoDouble)
//  TfifoFFT = class(TBookmarkFifoDouble)
  public
    type
     TDataReady = reference to procedure(d: PDouble; cnt: Integer);
  private
    FFourier: IFourier;
    FLength: Integer;
    FOverSamp: Integer;
    FFdataFlt: TArray<Double>;
    FFdata: TArray<Double>;
    FDataOut: PDoubleArray;
    FDataIn: TIndexArray;
    FltCoeff: TArray<Double>;
    FFirst: Boolean;
    FFirstFFTIndex: Integer;
    FLastFFTIndex: Integer;
    FFaza64: Double;
    FFaza32: Double;
    procedure SetLen(const Value: Integer);
    procedure SetOverSamp(const Value: Integer);
    function GetSamp: Integer;
    function GetAmpLen: Integer;
    function GetIn(index: Integer): Double;
    function GetOut(index: Integer): Double;
  protected
    SendIndex: Integer;
    procedure SetFirstIndex(const Value: GlobIdx); override;
  public
    constructor Create(Owner: TPersistent; aCapacity: Integer); override;
//    procedure ClearBuffer; //override;
    // filtr
    procedure ClearFilter;
    procedure ApplyLoFlt(from , too: integer);
    procedure ApplyHiFlt(from , too: integer);
    procedure ApplyBoundFlt(fq, width: integer);

    procedure ExecFFT(OnData: TDataReady);
    function GetLeakData: TIndexArray;

    property Len: Integer read FLength write SetLen;
    property OverSamp: Integer read FOverSamp write SetOverSamp;
    property Samp: Integer read GetSamp;

    property InputData[index: Integer]: Double read GetIn;
    property OutputData[index: Integer]: Double read GetOut;
    property FirstFFTIndex: Integer read FFirstFFTIndex;
    property LastFFTIndex: Integer read FLastFFTIndex;

    property AmpFF: TArray<Double> read FFdata;
    property FilteredFF: TArray<Double> read FFdataFlt;
    property FilterKoef: TArray<Double> read FltCoeff;
    property AmpLen: Integer read GetAmpLen;
    property Faza32: Double read FFaza32;
    property Faza64: Double read FFaza64;
  end;

implementation

{ TfifoFFT }

procedure TfifoFFT.ApplyBoundFlt(fq, width: integer);
 var
  i: Integer;
begin
  if fq <= 0 then Exit;
  FltCoeff[fq] := 0;
  if width <= 0 then Exit;
  for i := 1 to width do
   begin
    FltCoeff[fq+i] := Sin(i * PI/2 / (width));
    if fq-i >= 0 then FltCoeff[fq-i] := FltCoeff[fq+i];
   end;
end;

procedure TfifoFFT.ApplyHiFlt(from, too: integer);
 var
  i: Integer;
begin
  for i := from to too do FltCoeff[i] := Cos((i-from) * PI/2 / (too-from));
  for i := too to AmpLen div 4 do FltCoeff[i] := 0;
end;

procedure TfifoFFT.ApplyLoFlt(from, too: integer);
 var
  i: Integer;
begin
  for i := 0 to from do FltCoeff[i] := 0;
  for i := from to too do FltCoeff[i] := Sin((i-from) * PI/2 / (too-from));
end;

//procedure TfifoFFT.ClearBuffer;
//begin
//  inherited;
//  SendIndex := FirstIndex;
//  FFirst := True;
//  FFirstFFTIndex := SendIndex;
//  FLastFFTIndex := SendIndex-1;
//end;

procedure TfifoFFT.ClearFilter;
 var
  i: Integer;
begin
  for i := 0 to AmpLen div 4-1  do FltCoeff[i] := 1;
end;

constructor TfifoFFT.Create(Owner: TPersistent; aCapacity: Integer);
begin
  Len := FFT_LEN_1;
  OverSamp := len div 4;
  inherited Create(Owner, Len*4);
  FourierFactory(FFourier);
  ClearFilter;
  SetFirstIndex(FirstIndex);
  // особые точки 0 и максимальная гармоника n/2 не нужны приравниваем 0 при фильтровании
  //       1 == n-1 .... n/2-1 = n/2+1
  //      0 1..n/2-1 n/2 n/2+1..n-1
//  SetLength(FltCoeff, FFT_AMP_LEN-1); // нет 0
//  FNCH(15, 45);
//  FBCH(Round(m-m/1.7), Round(m-m/3));
end;

procedure TfifoFFT.ExecFFT(OnData: TDataReady);
  procedure Amp(var d: TArray<Double>; co: PComplex);
   var
    i: Integer;
  begin
    for i := 0 to Length(d) - 1 do
     begin
      d[i] := Hypot(co.X, co.Y);
      inc(co);
     end;
  end;
  procedure ApplyFlt(co: PComplex);
   var
    i: Integer;
    ce: PComplex;
  begin
    ce := co;
    inc(ce, Len-1); // начинаем с последней гармоники = 1 гармонике
    co.x := 0; // обнуляем 0 гармонику
    co.y := 0;
    inc(co); // начинаем с 1 гармоники
    for i := 0 to Length(FltCoeff)-1 do
     begin
      co.x := FltCoeff[i]*co.x;
      co.y := FltCoeff[i]*co.y;
      ce.x := FltCoeff[i]*ce.x;
      ce.y := FltCoeff[i]*ce.y;
      Inc(co);
      Dec(ce);
     end;
    co.x := 0; // обнуляем N/2 гармонику
    co.y := 0;
  end;
  procedure Faza(co: PComplex);
  begin
    inc(co,32);
    FFaza32 := RadToDeg(ArcTan2(co.x, -co.y));
    inc(co,32);
    FFaza64 := RadToDeg(ArcTan2(co.x, -co.y));
  end;
 var
  frm: integer;
  c: PComplex;
begin
  while SendIndex + Len < LastIndex do
   begin
    FDataIn := Read(SendIndex, Len);
    //CheckMath(FFourier, FFourier.fft(PDouble(Pbuf[SendIndex]), Len));
    CheckMath(FFourier, FFourier.fft(@FDataIn.Data[0], Len));
    CheckMath(FFourier, FFourier.GetLastFF(c));
    Faza(c);
    Amp(FFData, c);
    ApplyFlt(c);
    Amp(FFDataFlt, c);
    CheckMath(FFourier, FFourier.ifft(PDouble(FDataOut)));
    if FFirst then frm := 0 else frm := OverSamp;
    FFirst := False;
    FFirstFFTIndex := SendIndex + OverSamp;
    FLastFFTIndex := FFirstFFTIndex + Samp - 1;
    OnData(@FDataOut[frm], Len-OverSamp-frm);
    SendIndex := SendIndex + Samp;
   end;
end;

function TfifoFFT.GetAmpLen: Integer;
begin
  Result := Len div 2;
end;

function TfifoFFT.GetIn(index: Integer): Double;
begin
//  Result := Data[index];// Buf[index];
  Result := FDataIn.Data[FDataIn.Local(index)];
end;

function TfifoFFT.GetOut(index: Integer): Double;
begin
  Result := FDataOut[index - FFirstFFTIndex + OverSamp]
end;

function TfifoFFT.GetSamp: Integer;
begin
  Result := Len - OverSamp*2;
end;

function TfifoFFT.GetLeakData: TIndexArray;
begin
  Result := Read(SendIndex, LastIndex-SendIndex+1);
end;

procedure TfifoFFT.SetFirstIndex(const Value: GlobIdx);
begin
  inherited;
  SendIndex := FirstIndex;
  FFirst := True;
  FFirstFFTIndex := SendIndex;
  FLastFFTIndex := SendIndex-1;
end;

procedure TfifoFFT.SetLen(const Value: Integer);
begin
  if FLength = Value then Exit;
  FLength := Value;
  Capacity := FLength * 4;
  // особые точки 0 и максимальная гармоника n/2 не нужны приравниваем 0 при фильтровании
  //       1 == n-1 .... n/2-1 = n/2+1
  //      0 1..n/2-1 n/2 n/2+1..n-1
  SetLength(FltCoeff, AmpLen-1); // нет 0
  SetLength(FFdata, AmpLen);
  SetLength(FFdataFlt, AmpLen);
end;

procedure TfifoFFT.SetOverSamp(const Value: Integer);
begin
  if FOverSamp <> Value then
   begin
    if not FFirst then SendIndex := SendIndex + FOverSamp - Value;
    FOverSamp := Value;
   end;
end;

end.

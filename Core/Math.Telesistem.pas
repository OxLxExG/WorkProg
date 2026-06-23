unit Math.Telesistem;

interface

uses System.SysUtils, System.Classes, Fibonach, MathIntf, System.Math, debug_except, DeviceIntf,
     System.Generics.Collections, tools;

type
   TUsoData = record
    Data: PDouble;
    Size: Integer;
    BookMark: LongWord;
    IsBookMark: Boolean;
    Fifo: TFifoDouble;
   end;

   TFFTData = record
     InData, OutData: PDouble;
     SampleSize: Integer;
     FF, FFFiltered: PDouble;
     FFTSize: Integer;
     FifoData: TFifoDouble;
     FifoFShum: TFifoDouble;
   end;

{ TTelesistemBuffer = class
 public
  type
   TChanel = (tbcUso1, tbcUso2, tbcNoise, tbcFFT, tbcCoor);
   TDataRec = record
     Data: TArray<Double>;
     Index: Integer;
//     class function Create: TDataRec;
     function Count: Integer;
     procedure Add(const pData: PDouble; len: integer);
     procedure Delete(max: Integer);
   end;
 private
   FDic: TDictionary<TChanel, TDataRec>;
   FRemoveChanel: TChanel;
   FCount: Integer;
   FIndex: Integer;
   procedure SetCount(const Value: Integer);
   procedure SetIndex(const Value: Integer);
 public
   constructor Create();
   destructor Destroy; override;
   procedure Add(ch: TChanel; data: PDouble; len: Integer);
   property Count: Integer read FCount write SetCount;
   property Index: Integer read FIndex write SetIndex;
 end;}

{$REGION 'TCorrelatorState'}
   TCorrelatorState = (
    ///	<summary>
    ///	  Поиск СП, длительный процесс
    ///	</summary>
   csFindSP,
    ///	<summary>
    ///	  принятие решения о синхронизации
    ///	</summary>
   csSP,
    ///	<summary>
    ///	  выдаются коды
    ///	</summary>
   csCode,
    ///	<summary>
    ///	  проверка СП в состоянии csCode
    ///	</summary>
   csCheckSP,
    ///	<summary>
    ///	  принято решение о потере синхронизации из-за множества ошибок
    ///   и начале поиска СП
    ///	</summary>
   csBadCodes,
    ///	<summary>
    ///	  пользователь принял решение о потере синхронизации
    ///   и начале поиска СП
    ///	</summary>
   csUserToFindSP,
    ///	<summary>
    ///	  пользователь принял решение о синхронизации
    ///	</summary>
   csUserToSP);

{$ENDREGION}

{$REGION 'TTelesistemDecoder'}
   TTelesistemDecoder = class;
   TSPEvent = procedure (Sender: TTelesistemDecoder; Takt: LongWord) of object;
   TTelesistemDecoder = class
   public
    type
     TBufferType = (bftCorr, bftMul, bftBit, bftZerro);
     TSetBufferType = set of TBufferType;
//     TCodBuffer = record
//       BufferType: TBufferType;
//       Data: TArray<Double>;
//       constructor Create(bt: TBufferType);
//     end;
     TDeleteEvent = reference to procedure (DelSize: Integer);
     TFindSPData = record
      Max1: Double;
      Max2: Double;
      Min1: Double;
      Min2: Double;
     ///	<summary>
     ///	  Локальный счетчик поиска ср SP
     ///	</summary>
      FindSPCount: Integer;
     ///	<summary>
     ///	  Локальные указательи на Buf
     ///    Buf[Index + Max1Index] не меняется
     ///	</summary>
      Max1Index: Integer;
      Min1Index: Integer;
      Max2Index: Integer;
      Min2Index: Integer;
      Corr: TArray<Double>;
     end;
     TSPData = record
      Amp: Double;
      Porog: Double;
      Corr: TArray<Double>;
     end;
     TSPIndex = record
      Faza: Integer;
      Idx: Integer;
      GlobalTakt: LongWord;
     end;
     TCheckSPIndex = record
      FazaNew: Integer;
      Dkadr: Integer;
      GlobalTakt: LongWord;
     end;
     TCodData = record
      Code: Integer;
      Porog : Double;
      IsBad: Boolean;
      CodBuf: array [TBufferType] of TArray<Double>;
     end;
     TPaketCodes = record
      CodeCnt: Integer;
      BadCodes: Integer;
      CodData: TArray<TCodData>;
     end;
   private
     // установки пакета
     FBits, FDataCnt, FNoiseCnt, FDataCodLen, FSPcodLen: Integer;
     // состояние автомата
     FState: TCorrelatorState;

     FAmpPorogSP: Double;
     FPorogSP: Double;
     FPorogCod: Double;
     FPorogBadCodes: Integer;
     // поиск СП
     FFindSPData: TFindSPData;
     // СП
     FSPData: TSPData;
     FCodes: TPaketCodes;
     FSPIndex: TSPIndex;
     FCHIndex: TCheckSPIndex;
     FBitFilterOn: Boolean;
     FBitFilter: Tarray<Double>;
     FFirst: LongWord;
     procedure SetState(const Value: TCorrelatorState);
     function GetFindSPData: TFindSPData;
     procedure RunAutomat;
    function GetCodeTypes: TSetBufferType;
    function GetKadrBezShuma: Integer;
   protected
     Buf: TArray<Double>;
     ///	<summary>
     ///	  Глобальный указатель на Buf после Index все данные обработаны
     ///    значение меняется с приходом новых данных но содержимое Buf[Index] не меняется
     ///	</summary>
     Index: integer;
     // польсобытие
     FEvent: TNotifyEvent;
     FSPEvent: TSPEvent;

     function GetOversampDataLen: Integer; virtual;
     function GetDataLen: Integer; virtual;
     function GetKadrLen: Integer; virtual;
     function GetSPLen: Integer; virtual;
     function GetCount: Integer; virtual;
     function GetBuffer: PDoubleArray; virtual;

     function CorrSP(var fs: TFindSPData; idx, cnt: Integer): TArray<Double>; virtual;

     function CorrCode(var cd: TCodData):Integer; virtual;

     procedure ForceState(const Value: TCorrelatorState); // StartState

     function BitFilter(n: Integer): Double; inline;

     property Count: Integer read GetCount;
     property Buffer: PDoubleArray read GetBuffer;
     class function ToPorog(Amp, Amp2: Double): Double; static; inline;
     class function ToPorogSP(Amp, Amp2: Double): Double; static; inline;
   public
     constructor Create(ABits, ADataCnt, ANoiseCnt, ADataCodLen, ASPCodLen: Integer; AEvent: TNotifyEvent; ASPEvent: TSPEvent); virtual;
     procedure AddData(data: PDouble; len: Integer; DelEvent: TDeleteEvent);

     function IndexBuffer(ExtBuff: TFifoDouble): PDoubleArray;

     property State: TCorrelatorState read FState write SetState;
     // константы
     property KadrLen: Integer read GetKadrLen;
     property KadrBezShumaLen: Integer read GetKadrBezShuma;
     property SPLen: Integer read GetSPLen;
     property DataLen: Integer read GetDataLen;
     property OversampDataLen: Integer read GetOversampDataLen;

     property SPCodLen: Integer read FSPcodLen;
     property DataCnt: Integer read FDataCnt;
     property NoiseCnt: Integer read FNoiseCnt;

     property DataCodLen: Integer read FDataCodLen;
     property Bits: Integer read FBits;
     property CodeTypes: TSetBufferType read GetCodeTypes;
     // пользовательские данные
     ///	<summary>
     ///	  Амплитуда СП настоько большая что можно принять решение не дожидаясь конца пакета
     ///	</summary>
     property AmpPorogSP: Double read FAmpPorogSP write FAmpPorogSP;
     ///	<summary>
     ///	  Разниза Max1 Max2 в процентах
     ///	</summary>
     property PorogSP: Double read FPorogSP write FPorogSP;
     ///	<summary>
     ///	  Разниза Max1 Max2 в процентах
     ///	</summary>
     property PorogCod: Double read FPorogCod write FPorogCod;
     ///	<summary>
     ///	  Разниза Max1 Max2 в процентах
     ///	</summary>
     property BitFilterOn: Boolean read FBitFilterOn write FBitFilterOn;


     property PorogBadCodes: Integer read FPorogBadCodes write FPorogBadCodes;

     property FindSPData: TFindSPData read GetFindSPData;
     property SPData: TSPData read FSPData;
     property Codes: TPaketCodes read FCodes;
     property SPIndex: TSPIndex read FSPIndex;
     property CheckSPIndex: TCheckSPIndex read FCHIndex;
     property First: LongWord read FFirst;
   end;
   TDecoderClass = class of TTelesistemDecoder;
{$ENDREGION}

  TFibonachiDecoder = class(TTelesistemDecoder)
  private
    FPorogAmpCod: Double;
    FAlgIsMull: Boolean;
    FFindZeroes: Boolean;
  protected
    function CorrCode(var cd: TTelesistemDecoder.TCodData):Integer; override;
  public
    property PorogAmpCod: Double read FPorogAmpCod;
    property AlgIsMull: Boolean read FAlgIsMull write FAlgIsMull;
    property FindZeroes: Boolean read FFindZeroes write FFindZeroes;
  end;

  TFSKDecoder = class(TTelesistemDecoder)
  private
    FPorogAmpCod: Double;
//    FAlgIsMull: Boolean;
   Etalon: TArray<Double>;
  protected
    function CorrCode(var cd: TTelesistemDecoder.TCodData):Integer; override;
  public
    constructor Create(ABits, ADataCnt, ANoiseCnt, ADataCodLen, ASPCodLen: Integer; AEvent: TNotifyEvent; ASPEvent: TSPEvent); override;
    property PorogAmpCod: Double read FPorogAmpCod;
//    property AlgIsMull: Boolean read FAlgIsMull write FAlgIsMull;
  end;

  TFSK2Decoder = class(TTelesistemDecoder)
  private
   FPorogAmpCod: Double;
   FAlgIsMull: Boolean;
   Etalon0, Etalon1: TArray<Double>;
  protected
    function GetOversampDataLen: Integer; override;
    function CorrCode(var cd: TTelesistemDecoder.TCodData):Integer; override;
  public
    constructor Create(ABits, ADataCnt, ANoiseCnt, ADataCodLen, ASPCodLen: Integer; AEvent: TNotifyEvent; ASPEvent: TSPEvent); override;
    property PorogAmpCod: Double read FPorogAmpCod;
    property AlgIsMull: Boolean read FAlgIsMull write FAlgIsMull;
  end;

  TFSKDecoderFFT = class(TTelesistemDecoder)
  private
   {FDataIn, FDataOut,} FFData, FFDataFlt, FltCoeff: TArray<Double>;
   FFLength: Integer;
   FData: TFFTData;
   FOversampDataLen: Integer;
   FFourier: IFourier;
  protected
    function GetOversampDataLen: Integer; override;
    function CorrCode(var cd: TTelesistemDecoder.TCodData):Integer; override;
  public
    constructor Create(ABits, ADataCnt, ANoiseCnt, ADataCodLen, ASPCodLen: Integer; AEvent: TNotifyEvent; ASPEvent: TSPEvent); override;
    property Data: TFFTData read FData;
  end;

  TCorFibonachDecoder =  class(TTelesistemDecoder)
  private
    FSimbLen: Integer;
    procedure SetSimbLen(const Value: Integer);
  protected
    function CorrCode(var cd: TTelesistemDecoder.TCodData):Integer; override;
  public
    property SimbLen: Integer read FSimbLen write SetSimbLen;
  end;

  TManchsterDecoder = class(TTelesistemDecoder)

  end;



  TRMCodes = array [0..31, 0..31] of Integer;

  procedure EncodeRM(const Data: array of Byte; Bits: Integer; var bin: TArray<Boolean>);
  function Tst_DecodeFM(): TRMCodes;

implementation

{$REGION 'EncodeRM'}
 const RMCBIN: TRMCodes =(
  (-1, 1,-1, 1, 1,-1,-1, 1,-1, 1,-1, 1, 1,-1, 1,-1, 1,-1, 1,-1,-1, 1, 1,-1,-1, 1, 1,-1, 1,-1, 1,-1),
  (-1, 1, 1,-1, 1,-1, 1,-1,-1, 1, 1,-1, 1,-1,-1, 1, 1,-1,-1, 1,-1, 1,-1, 1,-1, 1,-1, 1, 1,-1,-1, 1),
  (-1, 1,-1, 1,-1, 1, 1,-1,-1, 1,-1, 1,-1, 1,-1, 1, 1,-1, 1,-1, 1,-1,-1, 1,-1, 1, 1,-1,-1, 1,-1, 1),
  (-1, 1, 1,-1,-1, 1,-1, 1,-1, 1, 1,-1,-1, 1, 1,-1, 1,-1,-1, 1, 1,-1, 1,-1,-1, 1,-1, 1,-1, 1, 1,-1),
  (-1, 1,-1, 1, 1,-1,-1, 1, 1,-1, 1,-1,-1, 1,-1, 1, 1,-1, 1,-1,-1, 1, 1,-1, 1,-1,-1, 1,-1, 1,-1, 1),
  (-1, 1, 1,-1, 1,-1, 1,-1, 1,-1,-1, 1,-1, 1, 1,-1, 1,-1,-1, 1,-1, 1,-1, 1, 1,-1, 1,-1,-1, 1, 1,-1),
  (-1, 1,-1, 1,-1, 1, 1,-1, 1,-1, 1,-1, 1,-1, 1,-1, 1,-1, 1,-1, 1,-1,-1, 1, 1,-1,-1, 1, 1,-1, 1,-1),
  (-1, 1, 1,-1,-1, 1,-1, 1, 1,-1,-1, 1, 1,-1,-1, 1, 1,-1,-1, 1, 1,-1, 1,-1, 1,-1, 1,-1, 1,-1,-1, 1),
  (-1, 1,-1, 1, 1,-1,-1, 1,-1, 1,-1, 1, 1,-1, 1,-1,-1, 1,-1, 1, 1,-1,-1, 1, 1,-1,-1, 1,-1, 1,-1, 1),
  (-1, 1, 1,-1, 1,-1, 1,-1,-1, 1, 1,-1, 1,-1,-1, 1,-1, 1, 1,-1, 1,-1, 1,-1, 1,-1, 1,-1,-1, 1, 1,-1),
  (-1, 1,-1, 1,-1, 1, 1,-1,-1, 1,-1, 1,-1, 1,-1, 1,-1, 1,-1, 1,-1, 1, 1,-1, 1,-1,-1, 1, 1,-1, 1,-1),
  (-1, 1, 1,-1,-1, 1,-1, 1,-1, 1, 1,-1,-1, 1, 1,-1,-1, 1, 1,-1,-1, 1,-1, 1, 1,-1, 1,-1, 1,-1,-1, 1),
  (-1, 1,-1, 1, 1,-1,-1, 1, 1,-1, 1,-1,-1, 1,-1, 1,-1, 1,-1, 1, 1,-1,-1, 1,-1, 1, 1,-1, 1,-1, 1,-1),
  (-1, 1, 1,-1, 1,-1, 1,-1, 1,-1,-1, 1,-1, 1, 1,-1,-1, 1, 1,-1, 1,-1, 1,-1,-1, 1,-1, 1, 1,-1,-1, 1),
  (-1, 1,-1, 1,-1, 1, 1,-1, 1,-1, 1,-1, 1,-1, 1,-1,-1, 1,-1, 1,-1, 1, 1,-1,-1, 1, 1,-1,-1, 1,-1, 1),
  (-1, 1, 1,-1,-1, 1,-1, 1, 1,-1,-1, 1, 1,-1,-1, 1,-1, 1, 1,-1,-1, 1,-1, 1,-1, 1,-1, 1,-1, 1, 1,-1),
  ( 1,-1, 1,-1,-1, 1, 1,-1, 1,-1, 1,-1,-1, 1,-1, 1,-1, 1,-1, 1, 1,-1,-1, 1, 1,-1,-1, 1,-1, 1,-1, 1),
  ( 1,-1,-1, 1,-1, 1,-1, 1, 1,-1,-1, 1,-1, 1, 1,-1,-1, 1, 1,-1, 1,-1, 1,-1, 1,-1, 1,-1,-1, 1, 1,-1),
  ( 1,-1, 1,-1, 1,-1,-1, 1, 1,-1, 1,-1, 1,-1, 1,-1,-1, 1,-1, 1,-1, 1, 1,-1, 1,-1,-1, 1, 1,-1, 1,-1),
  ( 1,-1,-1, 1, 1,-1, 1,-1, 1,-1,-1, 1, 1,-1,-1, 1,-1, 1, 1,-1,-1, 1,-1, 1, 1,-1, 1,-1, 1,-1,-1, 1),
  ( 1,-1, 1,-1,-1, 1, 1,-1,-1, 1,-1, 1, 1,-1, 1,-1,-1, 1,-1, 1, 1,-1,-1, 1,-1, 1, 1,-1, 1,-1, 1,-1),
  ( 1,-1,-1, 1,-1, 1,-1, 1,-1, 1, 1,-1, 1,-1,-1, 1,-1, 1, 1,-1, 1,-1, 1,-1,-1, 1,-1, 1, 1,-1,-1, 1),
  ( 1,-1, 1,-1, 1,-1,-1, 1,-1, 1,-1, 1,-1, 1,-1, 1,-1, 1,-1, 1,-1, 1, 1,-1,-1, 1, 1,-1,-1, 1,-1, 1),
  ( 1,-1,-1, 1, 1,-1, 1,-1,-1, 1, 1,-1,-1, 1, 1,-1,-1, 1, 1,-1,-1, 1,-1, 1,-1, 1,-1, 1,-1, 1, 1,-1),
  ( 1,-1, 1,-1,-1, 1, 1,-1, 1,-1, 1,-1,-1, 1,-1, 1, 1,-1, 1,-1,-1, 1, 1,-1,-1, 1, 1,-1, 1,-1, 1,-1),
  ( 1,-1,-1, 1,-1, 1,-1, 1, 1,-1,-1, 1,-1, 1, 1,-1, 1,-1,-1, 1,-1, 1,-1, 1,-1, 1,-1, 1, 1,-1,-1, 1),
  ( 1,-1, 1,-1, 1,-1,-1, 1, 1,-1, 1,-1, 1,-1, 1,-1, 1,-1, 1,-1, 1,-1,-1, 1,-1, 1, 1,-1,-1, 1,-1, 1),
  ( 1,-1,-1, 1, 1,-1, 1,-1, 1,-1,-1, 1, 1,-1,-1, 1, 1,-1,-1, 1, 1,-1, 1,-1,-1, 1,-1, 1,-1, 1, 1,-1),
  ( 1,-1, 1,-1,-1, 1, 1,-1,-1, 1,-1, 1, 1,-1, 1,-1, 1,-1, 1,-1,-1, 1, 1,-1, 1,-1,-1, 1,-1, 1,-1, 1),
  ( 1,-1,-1, 1,-1, 1,-1, 1,-1, 1, 1,-1, 1,-1,-1, 1, 1,-1,-1, 1,-1, 1,-1, 1, 1,-1, 1,-1,-1, 1, 1,-1),
  ( 1,-1, 1,-1, 1,-1,-1, 1,-1, 1,-1, 1,-1, 1,-1, 1, 1,-1, 1,-1, 1,-1,-1, 1, 1,-1,-1, 1, 1,-1, 1,-1),
  ( 1,-1,-1, 1, 1,-1, 1,-1,-1, 1, 1,-1,-1, 1, 1,-1, 1,-1,-1, 1, 1,-1, 1,-1, 1,-1, 1,-1, 1,-1,-1, 1));

function Tst_DecodeFM(): TRMCodes;
 var
  c,i: Integer;
begin
  for c := 0 to 31 do for i := 0 to 31 do
   begin
     Result[c,i] := RMCBIN[c,i]*RMCBIN[c, (i+1) mod 32];
     if Result[c,i] = -1 then Result[c,i] := 0;
   end;
end;

procedure EncodeRM(const Data: array of Byte; Bits: Integer; var bin: TArray<Boolean>);
  var
   n: Integer;
   procedure AddBit(bit: Boolean);
    var
     i: Integer;
   begin
     for I := 0 to bits-1 do bin[n+i] := Bit;
     Inc(n, bits);
   end;
  var
   b: Integer;
   d: Byte;
begin
  n := Length(bin);
  SetLength(bin, n + Bits*(Length(Data)*32) );
  for d in Data do
   begin
    if d >= 32 then raise Exception.Create('BAD NUMBER I >= 32');
    for b in RMCBIN[d] do AddBit(b = 1);
   end;
end;
{$ENDREGION}

{$REGION 'OLD ECHO'}
{ TTelesistemDecoder }

constructor TTelesistemDecoder.Create(ABits, ADataCnt,  ANoiseCnt, ADataCodLen, ASPCodLen: Integer; AEvent: TNotifyEvent;  ASPEvent: TSPEvent);
 var
  i: Integer;
begin
  FBits := ABits;
  FDataCnt := ADataCnt;
  FNoiseCnt := ANoiseCnt;
  FDataCodLen := ADataCodLen;
  FSPcodLen := ASPCodLen;
  FEvent := AEvent;
  FSPEvent := ASPEvent;
            //ADC USO 16 бит
  FAmpPorogSP := $8000 * 0.85;
  FPorogSP := 70;  //%
  FPorogCod := 50; //%
  FPorogBadCodes := FDataCnt div 2;

  SetLength(FBitFilter, FBits);
  for i := 0 to FBits-1 do  FBitFilter[i] := Sin(i/Bits*pi);
end;

function TTelesistemDecoder.GetKadrBezShuma: Integer;
begin
  Result := Bits * ((DataCnt - NoiseCnt) * DataCodLen + SPcodLen)
end;

function TTelesistemDecoder.GetKadrLen: Integer;
begin
  Result := Bits * (DataCnt * DataCodLen + SPcodLen)
end;

function TTelesistemDecoder.GetOversampDataLen: Integer;
begin
  Result := 0;
end;

function TTelesistemDecoder.GetSPLen: Integer;
begin
  Result := Bits * SPcodLen
end;

function TTelesistemDecoder.IndexBuffer(ExtBuff: TFifoDouble): PDoubleArray;
begin
//  TDebug.Log('ExtBuff.Count %d     Index %d    ', [ExtBuff.Count, Index]);
  Assert(ExtBuff.Count > Index, 'Length(ExtBuff) < Index');
  Result := PDoubleArray(@ExtBuff.Data[Index]);
end;

function TTelesistemDecoder.GetBuffer: PDoubleArray;
begin
  Result := PDoubleArray(@Buf[Index]);
end;

function TTelesistemDecoder.GetCodeTypes: TSetBufferType;
begin
  Result := [bftCorr, bftBit];
end;

function TTelesistemDecoder.GetCount: Integer;
begin
  Result := Length(Buf)- Index;
end;

function TTelesistemDecoder.GetDataLen: Integer;
begin
  Result := Bits * DataCodLen;
end;

function TTelesistemDecoder.GetFindSPData: TFindSPData;
begin
//  Assert(FState = csFindSP, 'FState <> csFindSP');
  Result := FFindSPData;
end;

procedure TTelesistemDecoder.SetState(const Value: TCorrelatorState);
begin
  if FState <> Value then
   begin
    ForceState(Value);
    if FState in [csUserToSP, csUserToFindSP] then RunAutomat;
   end;
end;

procedure TTelesistemDecoder.ForceState(const Value: TCorrelatorState);  // StartState
begin
  FState := Value;
  case Value of
    csFindSP: FFindSPData := default(TFindSPData);
    csCode: with FCodes do
     begin
      CodeCnt := 0;
      BadCodes := 0;
      SetLength(CodData, DataCnt);
     end;
  end;
end;

procedure TTelesistemDecoder.AddData(data: PDouble; len: Integer; DelEvent: TDeleteEvent);
 var
  n: Integer;
begin
  n := Length(Buf);
  SetLength(Buf, n+len);
  Move(data^, Buf[n], len*SizeOf(Double));
  n := Length(Buf) - KadrLen*2;
  if n > 0 then
   begin
    Delete(Buf,0, n);
    Dec(Index, n);
    inc(FFirst, n);
    DelEvent(n);
    Assert(Index >= 0, 'Index < 0');
//    TDebug.Log('NEW CORR LEN %d  INDEX %d     N %d', [Length(Buf), index, n] );
   end;
  RunAutomat;
end;

function TTelesistemDecoder.BitFilter(n: Integer): Double;
begin
  if FBitFilterOn then Result := FBitFilter[n] else Result := 1;
end;

function TTelesistemDecoder.CorrCode(var cd: TCodData): Integer;
 var
   m, c, j, i: Integer;
   mx1,  mx2: Double;
   mxi1: Integer;
begin
  SetLength(cd.CodBuf[bftcorr], 32);
  mxi1 := 0;
  mx1 := 0;
  mx2 := 0;
  for c := 0 to 31 do
   begin
    m := 0;
    cd.CodBuf[bftcorr][c] := 0;
    for i := 0 to 31 do for j := 0 to Bits-1 do
     begin
      cd.CodBuf[bftcorr][c] := cd.CodBuf[bftcorr][c] + RMCBIN[c,i] * buffer[m] * BitFilter(j);
      Inc(m);
     end;
    cd.CodBuf[bftcorr][c] := cd.CodBuf[bftcorr][c]/32/Bits;
    if FSPIndex.Faza = -1 then cd.CodBuf[bftcorr][c] := -cd.CodBuf[bftcorr][c];
    if cd.CodBuf[bftcorr][c] >= mx1 then
     begin
      mx2 := mx1;
      mx1 := cd.CodBuf[bftcorr][c];
      mxi1 := c;
     end;
   end;
  cd.Code := mxi1;
  cd.Porog := ToPorog(mx1, mx2);
  cd.IsBad := cd.Porog < PorogCod;
  if cd.IsBad then Result := 1 else Result := 0;
end;

function TTelesistemDecoder.CorrSP(var fs: TFindSPData; idx, cnt: Integer): TArray<Double>;
 const
  CSPCODLEN = 128;
  SP: array [0..CSPCODLEN-1] of integer =
         ( -1, 1,-1, 1,-1, 1,-1, 1,-1, 1,-1, 1, 1,-1, 1,-1,
            1,-1, 1,-1, 1,-1,-1, 1, 1,-1, 1,-1, 1,-1, 1,-1,
           -1, 1,-1, 1, 1,-1, 1,-1, 1,-1,-1, 1, 1,-1,-1, 1,
            1,-1, 1,-1,-1, 1,-1, 1,-1, 1,-1, 1, 1,-1,-1, 1,
            1,-1, 1,-1, 1,-1,-1, 1,-1, 1,-1, 1, 1,-1, 1,-1,
           -1, 1, 1,-1, 1,-1,-1, 1, 1,-1,-1, 1,-1, 1, 1,-1,
           -1, 1,-1, 1,-1, 1, 1,-1,-1, 1,-1, 1, 1,-1, 1,-1,
           -1, 1,-1, 1, 1,-1,-1, 1, 1,-1,-1, 1, 1,-1,-1, 1);
 var
  i, j, n: Integer;
begin
  Assert(FSPcodLen = CSPCODLEN, Format('d.SPLen %d <> Length(SP) 128', [FSPcodLen]));
  Assert(Index + idx + cnt <= Length(Buf) - SPLen, 'idx + cnt > Length(d.Buf) - Length(SP) * d.Bits');
  SetLength(Result, cnt);
  with fs do for n := 0 to cnt-1 do
   begin
    Result[n] := 0;
    for i := 0 to CSPCODLEN-1 do for j := 0 to Bits-1 do Result[n] := Result[n] + SP[i] * Buffer[Idx + i*Bits + j];
    Result[n] := Result[n]/Bits/CSPCODLEN;
     if  Max2 < Result[n] then
      begin
       if  Max1 < Result[n] then
        begin
         if idx > Max1Index + Bits then
          begin
           Max2 := Max1;
           Max2Index := Max1Index;
          end;
         Max1Index := idx;
         Max1 := Result[n];
        end
       else if idx > Max1Index + Bits then
        begin
         Max2 := Result[n];
         Max2Index := idx;
        end;
      end;
     if  Min2 > Result[n] then
      begin
       if  Min1 > Result[n] then
        begin
         if idx > Min1Index + Bits then
          begin
           Min2 := Min1;
           Min2Index := Min1Index;
          end;
         Min1Index := idx;
         Min1 := Result[n];
        end
       else if idx > Min1Index + Bits then
        begin
         Min2 := Result[n];
         Min2Index := idx;
        end;
      end;
    Inc(Idx);
   end;
end;

class function TTelesistemDecoder.ToPorog(Amp, Amp2: Double): Double;
begin
  if (Amp2 = 0) or (Amp < 0) then Result := 0
  else if Amp > amp2 then Result := 100
  else Result := (1 - Amp/Amp2) * 100;
end;

class function TTelesistemDecoder.ToPorogSP(Amp, Amp2: Double): Double;
begin
  if (Amp = 0) or (Amp2 > amp) then Result := 0
  else Result := (1 - Amp2/Amp) * 100;
end;

procedure TTelesistemDecoder.RunAutomat;
  procedure SafeExceEvent;
  begin
    try
     FEvent(Self);
    except
     on E: Exception do TDebug.DoException(E);
    end;
  end;
  procedure SetcsSP(Fz, SPidx: Integer; spAmp, Prg: Double);
   var
    si: Integer;
    z: TArray<Double>;
    d: TFindSPData;
  begin
   { TODO : set bookmark uso }
    with FSPData, FSPIndex do
     begin
      Faza := Fz;
      Idx := SPidx;
      Amp := spAmp;
      Porog := Prg;
      GlobalTakt := First + Index + SPidx;
      if Assigned(FSPEvent) then FSPEvent(Self, GlobalTakt);
     end;
    si := FSPIndex.Idx - Bits*2;
    if si + Index < 0 then
     begin
      si := -si - Index;
      FSPData.Corr := CorrSP(d, 0, Bits*4 - si);
      SetLength(z, si);
      FSPData.Corr := z + FSPData.Corr;
     end
    else FSPData.Corr := CorrSP(d, si, Bits*4);
    ForceState(csSP);
    RunAutomat;
  end;
  // особый случай когда СП в перыых 8 тактах  |SP|_____|SP|
  function UniqeCaseSP(m1idx, m2idx: Integer): Boolean;
  begin
    Result := (m1idx < 3) and (m2idx > KadrLen - 3);
  end;
  procedure ResetToFindSP;
  begin
    if Index > Length(Buf) - KadrLen div 2 then Index := Length(Buf) - KadrLen div 2;
    ForceState(csFindSP);
    RunAutomat;
  end;
 var
  cnt: Integer;
  pr: Double;
  fs: TFindSPData;
begin
   case State of
    csFindSP: with FFindSPData do
     begin
      cnt := Count - FindSPCount - SPLen;
      if cnt > 0 then
       begin
        if FindSPCount + cnt > KadrLen then cnt := KadrLen - FindSPCount;
        Corr := Corr + CorrSP(FFindSPData, FindSPCount, cnt);
        Inc(FindSPCount, cnt);
        SafeExceEvent();
        if FindSPCount = KadrLen then //  конeц пакета
         begin
          if (Max1 > -Min1) then
           begin
            pr := ToPorogSP(Max1,  Max2);
            if (pr >= FPorogSP) or UniqeCaseSP(Max1Index, Max2Index) then
             begin
              SetcsSP( 1, Max1Index,  Max1, pr);
              Exit;
             end
           end
          else
           begin
            pr := ToPorogSP(-Min1, -Min2);
            if (pr >= FPorogSP) or UniqeCaseSP(Min1Index, Min2Index) then
             begin
              SetcsSP(-1, Min1Index, -Min1, pr);
              Exit;
             end;
           end;
          ForceState(csFindSP); // StartState
          inc(Index, KadrLen);
         end
        else
         // Амплитуда СП настоько большая что можно принять решение не дожидаясь конца пакета
         if (Max1 > -Min1) then
          if (Max1Index > FindSPCount + Bits*2) and (Max1 > FAmpPorogSP) then
              SetcsSP( 1, Max1Index,  Max1, ToPorogSP( Max1,  Max2))
          else if (Min1Index > FindSPCount + Bits*2) and (-Min1 > FAmpPorogSP) then
              SetcsSP(-1, Min1Index, -Min1, ToPorogSP(-Min1, -Min2));
       end;
     end;
    csSP:
     begin
      SafeExceEvent();
      inc(Index, FSPIndex.Idx + SPLen);
      ForceState(csCode);
      RunAutomat;
     end;
    csCode: while Count >= DataLen + OversampDataLen do with FCodes do
     begin
      Inc(BadCodes, CorrCode(CodData[CodeCnt]));
      Inc(CodeCnt);
      Inc(Index, DataLen);
      SafeExceEvent();
      if CodeCnt >= DataCnt then
       begin
        ForceState(csCheckSP);
        Exit;
       end
      else if BadCodes > PorogBadCodes then
       begin
        ForceState(csBadCodes);
        RunAutomat;
        Exit;
       end;
     end;
    csCheckSP: if Count >= SPLen + Bits*2 then with FSPData, FCHIndex do
     begin
      fs := default(TFindSPData);
      Corr := CorrSP(fs, -Bits*2, Bits*4);
      if fs.Max1 > -fs.Min1 then
       begin
        FazaNew := 1;
        Dkadr := fs.Max1Index;
        Amp := fs.Max1;
        Porog := ToPorogSP(fs.Max1, fs.Max2);
        GlobalTakt := First + Index + Dkadr;
        if Assigned(FSPEvent) then FSPEvent(Self, GlobalTakt);
       end
      else
       begin
        FazaNew := -1;
        Dkadr := fs.Min1Index;
        Amp := -fs.Min1;
        Porog := ToPorogSP(-fs.Min1, -fs.Min2);
        GlobalTakt := First + Index + Dkadr;
        if Assigned(FSPEvent) then FSPEvent(Self, GlobalTakt);
       end;
      SafeExceEvent();
      if (FazaNew = FSPIndex.Faza) and (Porog >= FPorogSP) and (Dkadr < 8) then
       begin
        inc(Index, SPLen + Dkadr);
        ForceState(csCode);
       end
      else ResetToFindSP;
     end;
    csBadCodes, csUserToFindSP:
     begin
      SafeExceEvent();
      ResetToFindSP;
     end;
    csUserToSP:
     begin
      SafeExceEvent();
      with FFindSPData do
       if (Max1 > -Min1) then SetcsSP( 1, Max1Index,  Max1, ToPorogSP( Max1,  Max2))
       else SetcsSP(-1, Min1Index, -Min1, ToPorogSP(-Min1, -Min2));
     end
  end;
end;
{$ENDREGION}

{$REGION 'Fibonachi'}

{ TFibonachiDecoder }

function TFibonachiDecoder.CorrCode(var cd: TTelesistemDecoder.TCodData): Integer;
 var
  m, j, i: Integer;
  ones, zeroes, amp: Double;
  flt0: TArray<Double>;
begin
  SetLength(cd.CodBuf[bftcorr], DataCodLen);
  SetLength(cd.CodBuf[bftMul], DataLen);
  SetLength(cd.CodBuf[bftBit], DataLen);
  SetLength(cd.CodBuf[bftZerro], DataLen);

  SetLength(flt0, DataCodLen);

  if FAlgIsMull then FPorogAmpCod := 0
  else FPorogAmpCod := FSPData.Amp * PorogCod/100;

  m := 0;
  ones := Double.MaxValue;
  zeroes := Double.MinValue;
  for i := 0 to DataCodLen-1 do
   begin
    cd.CodBuf[bftcorr][i] := 0;
    flt0[i] := 0;
    for j := 0 to Bits-1 do if FAlgIsMull then
     begin
      cd.CodBuf[bftMul][m] := buffer[m] * buffer[m-bits]/ FSPData.Amp;
      cd.CodBuf[bftBit][m] := cd.CodBuf[bftMul][m] * BitFilter(j);
      cd.CodBuf[bftZerro][m] := buffer[m] * buffer[m-2*bits]/ FSPData.Amp;

      cd.CodBuf[bftcorr][i] := cd.CodBuf[bftcorr][i] + buffer[m] * buffer[m-bits] * BitFilter(j);
      if FFindZeroes then flt0[i] := flt0[i] + buffer[m] * buffer[m-2*bits] * BitFilter(j);
      Inc(m);
     end
    else
     begin
      cd.CodBuf[bftcorr][i] := cd.CodBuf[bftcorr][i] + (buffer[m] + buffer[m-bits]) * BitFilter(j);
      if FFindZeroes then flt0[i] := flt0[i] + (buffer[m] + buffer[m-2*bits]) * BitFilter(j);
      Inc(m);
     end;
   end;
  for i := 0 to DataCodLen-1 do
    if flt0[i] > 0 then
     begin
      cd.CodBuf[bftcorr][i] := cd.CodBuf[bftcorr][i] - flt0[i];
      if (i > 0) and (flt0[i-1] < 0) then cd.CodBuf[bftcorr][i-1] := cd.CodBuf[bftcorr][i-1] - flt0[i];
      if (i < DataCodLen-1) and (flt0[i-1] < 0) then cd.CodBuf[bftcorr][i-1] := cd.CodBuf[bftcorr][i-1] - flt0[i];
     end;
  cd.Code := 0;
  for i := 0 to DataCodLen-1 do
   begin
    if FAlgIsMull then cd.CodBuf[bftcorr][i] := cd.CodBuf[bftcorr][i]/bits/FSPData.Amp
    else cd.CodBuf[bftcorr][i] := Abs(cd.CodBuf[bftcorr][i])/bits/2; // неуверен при сложении
    cd.Code := cd.Code shl 1;
    amp := cd.CodBuf[bftcorr][i];
    if amp > FPorogAmpCod then
     begin
      cd.Code := cd.Code or 1;
      if ones > amp then ones := amp;
     end
    else if zeroes < amp then zeroes := amp;
   end;
  if FAlgIsMull then cd.Porog := Min(ToPorog(ones, Abs(FSPData.Amp)), ToPorog(-zeroes,  Abs(FSPData.Amp)))
  else cd.Porog := ToPorog(ones, zeroes);
  cd.IsBad := Odd(cd.Code); //!!! в две строчки
  cd.IsBad := not Decode(cd.Code shr 1, cd.Code) or cd.IsBad; //!!!
  if cd.IsBad then cd.Porog := 0;

  if cd.IsBad then Result := 1 else Result := 0;
end;
{$ENDREGION}

{$REGION 'FSK'}
{ TFSKDecoder }
function TFSKDecoder.CorrCode(var cd: TTelesistemDecoder.TCodData): Integer;
 var
  m, j, i: Integer;
//  tmp: TArray<Double>;
begin
  SetLength(cd.CodBuf[bftcorr], DataCodLen div 2);
  FPorogAmpCod := FSPData.Amp * PorogCod/100;
  m := 0;
  cd.Code := 0;
//  SetLength(tmp, Bits*2);
  for i := 0 to DataCodLen div 2 - 1 do
   begin
    cd.CodBuf[bftcorr][i] := 0;
    for j := 0 to Bits*4-1 do cd.CodBuf[bftcorr][i] := cd.CodBuf[bftcorr][i] + buffer[m + j] * Etalon[j];
    Inc(m, Bits*2);                 //sin
    cd.CodBuf[bftcorr][i] := cd.CodBuf[bftcorr][i]/Bits/4/0.7;
    cd.Code := cd.Code shl 1;
    if cd.CodBuf[bftcorr][i] > FPorogAmpCod then cd.Code := cd.Code or 1;
   end;
  cd.IsBad := Odd(cd.Code); //!!! в две строчки
  cd.IsBad := not Decode(cd.Code shr 1, cd.Code) or cd.IsBad; //!!!
  if cd.IsBad then Result := 1 else Result := 0;
end;

constructor TFSKDecoder.Create(ABits, ADataCnt, ANoiseCnt, ADataCodLen, ASPCodLen: Integer; AEvent: TNotifyEvent; ASPEvent: TSPEvent);
 var
  i: Integer;
begin
  inherited;
  SetLength(Etalon, ABits*4);
  for i := 0 to High(Etalon) do Etalon[i] := Sin(i*PI/ABits/2);
end;

{ TFSKDecoderFFT }
function TFSKDecoderFFT.CorrCode(var cd: TTelesistemDecoder.TCodData): Integer;
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
    inc(ce, FFLength-1); // начинаем с последней гармоники = 1 гармонике
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
 var
  c: PComplex;
begin
  FData.InData := @buffer[0];
  CheckMath(FFourier, FFourier.fft(@buffer[-OversampDataLen], FFLength));
  CheckMath(FFourier, FFourier.GetLastFF(c));
  Amp(FFData, c);
  ApplyFlt(c);
  Amp(FFDataFlt, c);
  CheckMath(FFourier, FFourier.ifft(FData.OutData));
  inc(FData.OutData, OversampDataLen);
  if cd.IsBad then Result := 1 else Result := 0;
end;

constructor TFSKDecoderFFT.Create(ABits, ADataCnt, ANoiseCnt, ADataCodLen, ASPCodLen: Integer; AEvent: TNotifyEvent; ASPEvent: TSPEvent);
  const
   AVL_FF: array [0..5] of Integer = (32,64,128,256,512,1024);
  var
   i: Integer;
begin
  inherited;
  FourierFactory(FFourier);
  for i := 0 to 4 do if (AVL_FF[i] <= DataLen) and (DataLen <= AVL_FF[i+1]) then
    begin
     FFLength := AVL_FF[i+1];
     FOversampDataLen := (FFLength - DataLen) div 2;
     Break;
    end;
//  SetLength(FdataIn, FFLength);
//  SetLength(FDataOut, FFLength);
  // особые точки 0 и максимальная гармоника n/2 не нужны приравниваем 0 при фильтровании
  //       1 == n-1 .... n/2-1 = n/2+1
  //      0 1..n/2-1 n/2 n/2+1..n-1
  SetLength(FltCoeff, FFLength div 2 - 1); // нет 0
  for i := 0 to FFLength div 8 - 1  do FltCoeff[i] := 1;

//  FNCH(9, 17);
//  FBCH(Round(m-m/1.7), Round(m-m/3));

  SetLength(FFdata, FFLength div 2);
  SetLength(FFdataFlt, FFLength div 2);
  FData.FF := @FFdata[0];
  FData.FFFiltered := @FFdataFlt[0];
  FData.FFTSize := FFLength div 2;
  FData.InData := @buffer[0];//@FdataIn[FOversampDataLen];
  FData.SampleSize := DataLen;
end;

function TFSKDecoderFFT.GetOversampDataLen: Integer;
begin
  Result := FOversampDataLen;
end;
{$ENDREGION}

{$REGION 'CorFibonachDecoder'}

{ TCorFibonachDecoder }

procedure TCorFibonachDecoder.SetSimbLen(const Value: Integer);
begin
  if Value in [2..16,18] then FSimbLen := Value
  else raise Exception.CreateFmt('SimbLen Value %d not in [2..18]', [Value]);
end;

function TCorFibonachDecoder.CorrCode(var cd: TTelesistemDecoder.TCodData): Integer;
 var
  m, oldm, c: Integer;
  procedure CrrBit(bit: Boolean);
   var
    i: Integer;
  begin
    if bit then for i := 0 to Bits-1 do cd.CodBuf[bftcorr][c] := cd.CodBuf[bftcorr][c] + buffer[m+i] * BitFilter(i)
    else        for i := 0 to Bits-1 do cd.CodBuf[bftcorr][c] := cd.CodBuf[bftcorr][c] - buffer[m+i] * BitFilter(i);
    Inc(m, bits);
  end;
 var
  i: Integer;
  mx1,  mx2: Double;
  mxi1: Integer;
  cod: Word;
  //
  ArrBit, etbit: TArray<Boolean>;
  SimbTrom: Integer;
  SimbTo: Integer;
  procedure CodToBits(a: TArray<Boolean>; cd: Word);
   var
    i: Integer;
  begin
    for i := 1 to 16 do
     begin
      a[i] := Cd and $8000 <> 0;
      cd := cd shl 1;
     end;
    a[0] := not a[1];
    a[17] := not a[16];
  end;
begin
  SetLength(cd.CodBuf[bftcorr], 2584);

  if FSimbLen < 18 then
   begin
    SetLength(ArrBit, 18);
    SetLength(etbit, 18);

    CodToBits(etbit, FIBONACH_ENCODED_PSK[2090]);
    cd.Code := 2090;
    cd.IsBad := False;
    for c := 0 to 2583 do
    begin
     CodToBits(ArrBit, FIBONACH_ENCODED_PSK[c]);
     m := 0;
     SimbTrom := 0;
     SimbTo := FSimbLen;
     while true do
      begin
       cd.CodBuf[bftcorr][c] := 0;
       oldm := m;
       for i := SimbTrom to SimbTo-1 do CrrBit(etbit[i]);
       m := oldm;
       mx1 := cd.CodBuf[bftcorr][c]/(SimbTo-SimbTrom)/Bits;
       cd.CodBuf[bftcorr][c] := 0;
       for i := SimbTrom to SimbTo-1 do CrrBit(ArrBit[i]);
       cd.CodBuf[bftcorr][c] := cd.CodBuf[bftcorr][c]/(SimbTo-SimbTrom)/Bits;
       if cd.CodBuf[bftcorr][c] > mx1 then
        begin
         cd.Code := c;
         cd.IsBad := True;
        end;
       if SimbTo = 18 then Break;
       SimbTrom := SimbTo;
       SimbTo := SimbTo + FSimbLen;
       if SimbTo > 18 then SimbTo := 18;
      end;
    end;
   end
  else
   begin
    mxi1 := 0;
    mx1 := 0;
    mx2 := 0;
    for c := 0 to 2583 do
     begin
      m := 0;
      cd.CodBuf[bftcorr][c] := 0;

      Cod := FIBONACH_ENCODED_PSK[c];

      //  inv15 15H..0L inv0
      CrrBit(Cod and $8000 = 0); //
      for i := 0 to 14 do
       begin
        CrrBit(Cod and $8000 <> 0);
        cod := cod shl 1;
       end;
      CrrBit(Cod and $8000 <> 0);
      CrrBit(Cod and $8000 = 0);

      cd.CodBuf[bftcorr][c] := cd.CodBuf[bftcorr][c]/18/Bits;
      if FSPIndex.Faza = -1 then cd.CodBuf[bftcorr][c] := -cd.CodBuf[bftcorr][c];
      if cd.CodBuf[bftcorr][c] >= mx1 then
       begin
        mx2 := mx1;
        mx1 := cd.CodBuf[bftcorr][c];
        mxi1 := c;
       end;
     end;
    cd.Code := mxi1;
    cd.Porog := ToPorog(mx1, mx2);
    cd.IsBad := cd.Porog < PorogCod;
   end;
  if cd.IsBad then Result := 1 else Result := 0;
end;
{$ENDREGION}

{ TFSK2Decoder }

function TFSK2Decoder.CorrCode(var cd: TTelesistemDecoder.TCodData): Integer;
 var
  m, j, i: Integer;
//  tmp: TArray<Double>;
begin
  SetLength(cd.CodBuf[bftcorr], DataCodLen div 4);
  FPorogAmpCod := FSPData.Amp * PorogCod/100;
  m := 0;
  cd.Code := 0;
  for i := 0 to DataCodLen div 4 - 1 do
   begin
    cd.CodBuf[bftcorr][i] := 0;
    if AlgIsMull then
          for j := 0 to Bits*4-1 do cd.CodBuf[bftcorr][i] := cd.CodBuf[bftcorr][i] - buffer[m + j - 8] * buffer[m + j + 8]
    else  for j := 0 to Bits*4-1 do cd.CodBuf[bftcorr][i] := cd.CodBuf[bftcorr][i] - buffer[m + j] * Etalon0[j] + buffer[m + j] * Etalon1[j];
    Inc(m, Bits*4);                 //sin
    if AlgIsMull then cd.CodBuf[bftcorr][i] := cd.CodBuf[bftcorr][i]/Bits/4
    else  cd.CodBuf[bftcorr][i] := cd.CodBuf[bftcorr][i]/Bits/4/0.7;
    cd.Code := cd.Code shl 1;
    if cd.CodBuf[bftcorr][i] > 0 then cd.Code := cd.Code or 1;
   end;
 // cd.IsBad := Odd(cd.Code); //!!! в две строчки
  cd.IsBad := not Decode(cd.Code{ shr 1}, cd.Code) or cd.IsBad; //!!!
  if cd.IsBad then Result := 1 else Result := 0;
end;

constructor TFSK2Decoder.Create(ABits, ADataCnt, ANoiseCnt, ADataCodLen, ASPCodLen: Integer; AEvent: TNotifyEvent; ASPEvent: TSPEvent);
 var
  i: Integer;
begin
  inherited;
//  AlgIsMull := True;
  SetLength(Etalon0, ABits*4);
  SetLength(Etalon1, ABits*4);
  for i := 0 to High(Etalon1) do Etalon1[i] := Sin(i*PI*2/Length(Etalon1));
  for i := 0 to High(Etalon0) do Etalon0[i] := Sin(i*PI*4/Length(Etalon0));
end;

function TFSK2Decoder.GetOversampDataLen: Integer;
begin
  if AlgIsMull then Result := 8 else Result := 0;
end;

{ TTelesistemBuffer }

{constructor TTelesistemBuffer.Create;
begin
  FDic := TDictionary<TChanel, TDataRec>.Create(Ord(High(TChanel))+1);
  FRemoveChanel := High(TChanel);
  FCount := $8000;
end;

destructor TTelesistemBuffer.Destroy;
begin

  inherited;
end;

procedure TTelesistemBuffer.SetCount(const Value: Integer);
begin
  FCount := Value;
end;

procedure TTelesistemBuffer.SetIndex(const Value: Integer);
begin
  FIndex := Value;
end;

procedure TTelesistemBuffer.Add(ch: TChanel; data: PDouble; len: Integer);
 var
  b: TDataRec;
begin
  if not FDic.TryGetValue(ch, b) then FDic.Add(ch, b);
  b.Add(data, len);
  b.Delete(FCount);
end;

procedure TTelesistemBuffer.TDataRec.Add(const pData: PDouble; len: integer);
 var
  n: Integer;
begin
  n := Length(Data);
  SetLength(Data, n+len);
  Move(pData^, Data[n], len*SizeOf(Double));
end;

procedure TTelesistemBuffer.TDataRec.Delete(max: Integer);
 var
  n: Integer;
begin
  n := Length(Data) - max;
  if n > 0 then
   begin
    System.Delete(Data, 0, n);
    Dec(Index, n);
    Assert(Index >= 0, 'Index < 0');
   end;
end;

function TTelesistemBuffer.TDataRec.Count: Integer;
begin
  Result := Length(Data);
end;  }

end.

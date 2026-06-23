unit Math.Telesistem.Custom;

interface

uses JDtools, RootImpl, debug_except, RootIntf, ExtendIntf, MathIntf, Container,
     System.DateUtils, IndexBuffer,
     System.SysUtils, System.Classes, System.Math,
     System.Generics.Defaults,
     System.Generics.Collections;

type


{$REGION 'TCorrelatorState'}
   [EnumCaptions('Поиск СП, принятие решения о синхронизации,выдаются коды, проверка СП,'+
   'принято решение о потере синхронизации, пользователь принял решение о потере синхронизации,'+
   'пользователь принял решение о синхронизации')]
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

{$REGION 'TYPES'}
  ///	<summary>
  ///	  буфер поиска СП
  ///	</summary>
  TFindSP = record
    Max1, Max2, Min1, Min2: TBufPoint;
    Corr: TIndexArray;
    function Count: LocIdx;
    /// LastIndex указывает на последние данные!!!
    function LastIndex: GlobIdx;
    procedure Add(const d: TIndexArray; Bits: Integer);
    procedure Reset(AFirstIdx: GlobIdx);
  end;

  ///	<summary>
  ///	  информация о СП
  ///	</summary>
  TSPData = record
  ///	  точка СП
    sp: TBufPoint;
  ///	 буфер СП
    Corr: TIndexArray;
  ///	 качество СП в %
    Quality: Double;
  ///	 Начальная фаза при первом поиске СП (1 или -1)
    FazaFind: Integer;
  ///	 фаза (1 или -1) при проверке СП в режиме Кодов (при первом поиске СП = 0)
    FazaCheck: Integer;
  ///	 смещение тактов между кадрами (при первом поиске СП неиспользуется)
    DTakt: Integer;
    function Faza: Integer;
    function SPIndex: GlobIdx;
  end;

  TBufferType = (bftData, bftBit, bftCorr, bftMul, bftZerro, bftSigShum, bftNoise, bftPorog);

  TCodeData = record
  private
    CodBuf: TArray<TIndexArray>;
    function GetBuf(bt: TBufferType): TIndexArray;
    procedure SetBuf(bt: TBufferType; const Value: TIndexArray);
  public
    BufferType: TArray<TBufferType>;
    Code: Integer;
    Quality: Double;
    IsBad: Boolean;
    property Buf[bt: TBufferType]: TIndexArray read GetBuf write SetBuf;
  end;

  TCodes = record
    Idx: GlobIdx;
    BadCodes: Integer;
    CodData: TArray<TCodeData>;
  private
    procedure Reset(AFirstIdx: GlobIdx);
    procedure Add(const cd: TCodeData);
  public
    function Count: Integer;
    function Curr: TCodeData;
  end;
{$ENDREGION 'TYPES'}

  TCustomDecoder = class;
  TCorrCodeFunc = function (Owner: TCustomDecoder; idx: GlobIdx): TCodeData;
  TSpCreateFunc = function : TArray<Integer>;
  TGetUSOData = function(out USOData: IUSOData): Boolean of object;


{$REGION 'TCustomDecoder'}
  ///
  ///  Для баинда нужен врапер т.к. унаследован TICollectionItem
  TCustomDecoder = class(TICollectionItem, ICaption)
  protected
    const SP_M: array[0..7] of Byte = ($3, $EF, $3A, $C2, $E3, $69, $13, $2A);
    function GetCaption: string;
    procedure SetCaption(const Value: string);
  private
    FBitFilter: Tarray<Double>;
    FCaption: string;
    Fbuf: TIndexBufDouble;
    FBitLen: Integer;
    FSPBits: Integer;
    FNoiseBits: Integer;
    FCodeBits: Integer;
    FDataCnt: Integer;
    FPorogBadCodes: Integer;
    FPorogSP: Double;
    FPorogCod: Double;
    FAmpPorogSP: Double;
    FFindSP: TFindSP;
    FSPData: TSPData;
    FCodes: TCodes;
    FBitFilterOn: Boolean;
    FOnState: TNotifyEvent;
    TryUsoData: TGetUSOData;
    function GetKadrLen: Integer; inline;
    function GetSPLen: Integer; inline;
    function GetKadrBits: Integer; inline;
    function GetDataLen: Integer; inline;
    function GetNoiseLen: Integer; inline;
    function GetCodeLen: Integer; inline;
    procedure UserSetState(const Value: TCorrelatorState);
    function GetFirstIdx: GlobIdx;
    function GetLastIdx: GlobIdx;
    procedure SetBuf(const Value: TIndexBufDouble);
    procedure SetBitLen(const Value: Integer);
  protected
    Fsp: TArray<Integer>;
    FState: TCorrelatorState;
    FCorrCode: TCorrCodeFunc;
    function UniqeCaseSP(const m1, m2: TBufPoint): Boolean;
    ///	<summary>
    ///	  Проверка на Порог при окончании поиска СП (csFindSP)
    ///	</summary>
    function TestKadrSP(out Res: TSPData): Boolean; virtual;
    ///	<summary>
    ///	  Проверка СП по окончании кадра (csCod, csCheckSP)
    ///	</summary>
    function TestCheckSP(const FndSP: TFindSP; var Spd: TSPData): Boolean;virtual;
    ///	<summary>
    ///	  Проверка на Превышение Амплитуды при поиске СП (csFindSP)
    ///	</summary>
    function TestCurrentSP(out Res: TSPData): Boolean; virtual;
    function CorrSP(idx: GlobIdx; cnt: Integer): TIndexArray; virtual;
    function CorrCode(idx: GlobIdx): TCodeData; virtual;

    procedure DoStart_csFindSP(idx: GlobIdx); virtual;
    ///	<summary>
    ///	  NewSp.sp = max1 или Min1 - локальная точка  FindSP.Corr !!!
    ///	</summary>
    procedure DoStart_csSP(const NewSp: TSPData); virtual;
    procedure DoStart_csCheckSP(idx: GlobIdx); virtual;
    procedure DoRun_csFindSP; virtual;
    procedure DoRun_csCheckSP; virtual;
    procedure DoRun_csUserToSP; virtual;
    procedure NotifyNewState; virtual;
    ///
    ///  Вконструкторе
    ///  для удобства
    ///
    procedure SetConst(ABitLen, ACodeBits, ADataCnt, ANoiseBits: Integer; ACorrCode: TCorrCodeFunc; SpFind: TSpCreateFunc);
    procedure DoSetConst; virtual;
  public
    constructor Create(Collection: TCollection); override;
    procedure RunAutomat;
    function BitFilter(n: Integer): Double; inline;
    class function ToPorogSP(Amp, Amp2: TBufPoint): Double; static;
    ///	<summary>
    ///	  глобальный диапазон данных
    ///	</summary>
    [ShowProp('First', true)] property FirstIdx: GlobIdx read GetFirstIdx;
    [ShowProp('Last', true)] property LastIdx: GlobIdx read GetLastIdx;

    property Buf: TIndexBufDouble read FBuf write SetBuf;
    ///	<summary>
    ///	  локальная длина буфера
    ///	</summary>
//    property Count: Integer read FBuf.Count;

    // константы пакета данных
    ///	<summary>
    ///	  длина бита данных
    ///	</summary>
    [ShowProp('длина бита данных', true)] property BitLen: Integer read FBitLen write SetBitLen default 8;
    ///	<summary>
    ///	  число бит одного данного
    ///	</summary>
    [ShowProp('число бит одного данного', true)] property CodeBits: Integer read FCodeBits write FCodeBits;
    ///	<summary>
    ///	  число данных
    ///	</summary>
    [ShowProp('число данных', true)] property DataCnt: Integer read FDataCnt write FDataCnt;
    ///	<summary>
    ///	  число бит Всего шума
    ///	</summary>
    [ShowProp('число бит Всего шума', true)] property NoiseBits: Integer read FNoiseBits write FNoiseBits;

    // константы вычисляемые

    ///	<summary>
    ///	  число бит СП
    ///	</summary>
    [ShowProp('число бит СП', true)] property SPBits: Integer read FSPBits default 128;
    ///	<summary>
    ///	  число бит кадра
    ///	</summary>
    [ShowProp('число бит кадра', true)] property KadrBits: Integer read GetKadrBits;
    ///	<summary>
    ///	  длина СП
    ///	</summary>
    [ShowProp('длина СП', true)] property SPLen: Integer read GetSPLen;
    ///	<summary>
    ///	  длина одного данного
    ///	</summary>
    [ShowProp('длина одного данного', true)] property CodeLen: Integer read GetCodeLen;
    ///	<summary>
    ///	  длина данных
    ///	</summary>
    [ShowProp('длина данных', true)] property DataLen: Integer read GetDataLen;
    ///	<summary>
    ///	  длина шумов
    ///	</summary>
    [ShowProp('длина шумов', true)] property NoiseLen: Integer read GetNoiseLen;
    ///	<summary>
    ///	  длина кадкра
    ///	</summary>
    [ShowProp('длина кадкра', true)] property KadrLen: Integer read GetKadrLen;
  published
    // изменяемые пользовательские данные
    ///	<summary>
    ///	  Амплитуда СП настоько большая что можно принять решение не дожидаясь конца пакета
    ///	</summary>
    [ShowProp('Порог амплитуды СП')] property AmpPorogSP: Double read FAmpPorogSP write FAmpPorogSP;
    ///	<summary>
    ///	  Порог принятия решения об СП ( Разниза Max1 Max2 в процентах)
    ///	</summary>
    [ShowProp('Порог СП %')] property PorogSP: Double read FPorogSP write FPorogSP;
    ///	<summary>
    ///    Порог принятия решения о Коде
    ///	  Разниза Max1 Max2 кодов в процентах
    ///    или качество кода каким либо методом
    ///	</summary>
    [ShowProp('Порог Кодов %')] property PorogCod: Double read FPorogCod write FPorogCod;
    ///	<summary>
    ///	  Число плохих кодов для принятия решения о поиске сп
    ///	</summary>
    [ShowProp('Число плохих кодов')]property PorogBadCodes: Integer read FPorogBadCodes write FPorogBadCodes;

  public
    property Text: string read FCaption write SetCaption;
    property OnState: TNotifyEvent read FOnState write FOnState;
    property GetUSOData: TGetUSOData read TryUsoData write TryUsoData;
    ///	<summary>
    ///	  Состояние автомата
    ///	</summary>
    [ShowProp('Состояние автомата', true)] property State: TCorrelatorState read FState write UserSetState;
  protected
    ///	<summary>
    ///	  синусный фильтр Бита
    ///	</summary>
    [ShowProp('синусный фильтр Бита')] property BitFilterOn: Boolean read FBitFilterOn write FBitFilterOn;
  public
    // результаты работы
    property FindSP: TFindSP read FFindSP;
    property SPData: TSPData read FSPData;
    property Codes: TCodes read FCodes;
  end;
{$ENDREGION 'TCustomDecoder'}

  TCustomDecoderClass = class of TCustomDecoder;
  TCustomDecoderCollection = class(TICollection);


  TCustomDecoderWrap = TBindObjWrap;// TBindObjWrap<TCustomDecoder>;
//  record
//    obj: TCustomDecoder;
//    class operator Implicit(d: TCustomDecoderWrap): TCustomDecoder;
//    class operator Implicit(d: TCustomDecoder): TCustomDecoderWrap;
//  end;

  TCustomDecoderFourier = class(TCustomDecoder)
  protected
    FFourier: IFourier;
  public
    constructor Create(Collection: TCollection); override;
  end;

  TDecoderManchRetr = class(TCustomDecoderFourier)
  protected
    procedure DoSetConst; override;
  end;

 TWindowDecoder = class(TCustomDecoderFourier)
 private
    FSPDelta: Integer;
    FSPIndex: GlobIdx;
    FSPBeginBit: GlobIdx;
    function GetStartTime: TDateTime;
 protected
    procedure DoRun_csFindSP; override;
    procedure DoStart_csFindSP(idx: GlobIdx); override;
    procedure DoSetConst; override;
    procedure UpdateSPWindow(idx: GlobIdx);
//    function TestKadrSP(out Res: TSPData): Boolean; override;
    procedure DoRun_csUserToSP; override;
 public
    property SPStartTime: TDateTime read GetStartTime;
    property SPWindow: GlobIdx read FSPIndex write FSPIndex;
    // 0 - telesis N-renranslator
    property SPBeginBit: GlobIdx read FSPBeginBit write FSPBeginBit;
 published
    [ShowProp('Уход тактов (Бит)')] property SPDeltaBit: Integer read FSPDelta write FSPDelta default 10;
 end;

  TDecoderFMRetr = class(TCustomDecoderFourier)
  private
    FCmdSendFlag: Boolean;
    FusoIdx: Integer;
    FCmd: Byte;
    procedure SetCmdSendFlag(const Value: Boolean);
    procedure UsoEvent(Uso: TObject);
    procedure InitUsoEvent;
    function GetStartTime: TDateTime;
  protected
    property SPStartTime: TDateTime read GetStartTime;
    procedure DoSetConst; override;
    procedure DoRun_csFindSP; override;
 published
    [ShowProp('Посылать команды управения')] property CmdSendFlag: Boolean read FCmdSendFlag write SetCmdSendFlag default False;
  end;

  TWindowDecoderFM = class(TWindowDecoder)
  protected
    procedure DoSetConst; override;
  end;


 /// LastIndex + Cur In Buf  Последние данные с USO

function RMCorrCode(Owner: TCustomDecoder; idx: GlobIdx): TCodeData;
function Manchester2CorrCode(Owner: TCustomDecoder; idx: GlobIdx): TCodeData;
function Manchester2SpCreate: TArray<Integer>;
function FmCorrCode(Owner: TCustomDecoder; idx: GlobIdx): TCodeData;
function FmSpCreate: TArray<Integer>;


implementation

function FmSpCreate: TArray<Integer>;
 var
  i, j, n: Integer;
  d: Byte;
begin
  with TCustomDecoder do
   begin
    SetLength(Result, Length(SP_M)*8*4);
    n := 0;
    for i := 0 to High(SP_M) do
     begin
      d := SP_M[i];
      for j := 0 to 7 do
       begin
        if (d and $80) = 0 then
         begin
          Result[n] := -1;
          inc(n);
          Result[n] :=  1;
          inc(n);
          Result[n] := -1;
          inc(n);
          Result[n] :=  1;
          inc(n);
         end
        else
         begin
          Result[n] := -1;
          inc(n);
          Result[n] := -1;
          inc(n);
          Result[n] :=  1;
          inc(n);
          Result[n] :=  1;
          inc(n);
         end;
         d := d shl 1;
       end;
     end;
   end;
end;

function Manchester2SpCreate: TArray<Integer>;
 var
  i, j, n: Integer;
  d: Byte;
begin
  with TCustomDecoder do
   begin
    SetLength(Result, Length(SP_M)*8*2);
    n := 0;
    for i := 0 to High(SP_M) do
     begin
      d := SP_M[i];
      for j := 0 to 7 do
       begin
        if (d and $80) = 0 then
         begin
          Result[n] := -1;
          inc(n);
          Result[n] :=  1;
          inc(n);
         end
        else
         begin
          Result[n] :=  1;
          inc(n);
          Result[n] := -1;
          inc(n);
         end;
         d := d shl 1;
       end;
     end;
   end;
end;

    {$REGION 'CorrCode'}

function FmCorrCode(Owner: TCustomDecoder; idx: GlobIdx): TCodeData;
//type
 // вероятности 0 1
// TLogProb = record
//  case Byte of
//    0: (p0, p1, Eall: Double);
//    1: (p: array [0..2] of Double);
//  end;
 var
  dat, corr: TIndexArray;
//  lps: TArray<TLogProb>;
  c, Cf, c2f: PComplex;
  i, Ccod, DecodeBits: Integer;
  Eall, E1r, E2r, p, Epsum, Esum: Double;
  Fourier: IFourier;
begin
  Fourier := (Owner as TCustomDecoderFourier).FFourier;
  with Owner do
   begin
    // HART из 4 бит один бит инф
    DecodeBits := CodeBits div 4;
    // Будем искать число с максимальной вероятностью Log(P(AA*AB*BC*CD*DE*EF*FG*GH)) = SUM(Lop(P(nn))
    // подготовка буферов
//    SetLength(lps, DecodeBits);
    // буфер Сырые данные
    dat := Buf.Read(idx, CodeLen);
    Result.Buf[bftData] := dat;
    // буфер вероятности bit кода
    corr.FirstIdx := idx;
    SetLength(corr.Data, DecodeBits);
    Result.Buf[bftCorr] := Corr;
    Esum := 0;
    Epsum := 0;
    Ccod := 0;
    // таблица логарифмов вероятостей появления 1 бит (4бита FM)
    for i := 0 to DecodeBits-1 do
     begin               // FFT бит
                         // интересуют 1 2 гармоники
      CheckMath(Fourier, Fourier.fft(@dat.Data[i*4*BitLen], BitLen*4));
      CheckMath(Fourier, Fourier.GetLastFF(c));
      Inc(c);
      Cf := c; // +Re(cf) = Amp code 1
      E1r := Owner.SPData.FazaFind*c.Y;
      Inc(c);
      C2f := c; // 2FQ +Re(c2f) = Amp code 0
      E2r := Owner.SPData.FazaFind*c.Y;
      Eall := Hypot(cf.x,cf.y) + Hypot(c2f.x, c2f.y); // полная энергия двух гармоник
      // типа log P
      Ccod := Ccod shl 1;
      if E1r > E2r then
       begin
        Ccod := Ccod or 1;
        p := E1r;
       end
      else p := E2r;
      Corr.Data[i] := p/Eall*100;
      Epsum := Epsum + p;
      Esum := Esum + Eall;
     end;
    Result.Code := Ccod;
    Result.Quality := Epsum/Esum*100;// (Esum+pold)/Esum*100;
    Result.IsBad := Result.Quality < PorogCod;
   end;
end;

function Manchester2CorrCode(Owner: TCustomDecoder; idx: GlobIdx): TCodeData;
type
 // вероятности 00 01 10 11
 TLogProb = record
  case Byte of
    0: (p00, p01, p10, p11, Eall: Double);
    1: (p: array [0..4] of Double);
  end;
 var
  dat, corr: TIndexArray;
  lps: TArray<TLogProb>;
  c, Cf, c2f: PComplex;
  i, j, cod, Ccod, CorrLen, DecodeBits: Integer;
  Eall, Er, E2i, p, pold, Esum: Double;
  Fourier: IFourier;
begin
  Fourier := (Owner as TCustomDecoderFourier).FFourier;
  with Owner do
   begin
    // манчестер2 из двух бит один бит инф
    DecodeBits := CodeBits div 2;
    // Будем искать число с максимальной вероятностью Log(P(AA*AB*BC*CD*DE*EF*FG*GH)) = SUM(Lop(P(nn))
    // подготовка буферов
    SetLength(lps, DecodeBits - 1);
    // буфер Сырые данные
    dat := Buf.Read(idx, CodeLen);
    Result.Buf[bftData] := dat;
    // буфер вероятности кода
    CorrLen := 2 shl (DecodeBits-1);
    corr.FirstIdx := idx;
    SetLength(corr.Data, CorrLen);
    Result.Buf[bftCorr] := Corr;
    Esum := 0;
    // таблица логарифмов вероятостей появления двухбитных (2бита данных 4бита манчестера) кусков кода
    for i := 0 to DecodeBits-2 do
     begin               // FFT двух бит (характерные кривые см Блокнот)
                         // интересуют 1 2 гармоники
      CheckMath(Fourier, Fourier.fft(@dat.Data[i*2*BitLen], BitLen*4));
      CheckMath(Fourier, Fourier.GetLastFF(c));
      Inc(c);
      Cf := c; // FQ +Re(cf) = Amp code 10 -Re(cf) = Amp code 01
      Er := Owner.SPData.FazaFind*c.x;
      Inc(c);
      C2f := c; // 2FQ +Im(c2f) = Amp code 00 -Im(c2f) = Amp code 11
      E2i := Owner.SPData.FazaFind*c.y;
      Eall := Hypot(cf.x,cf.y) + Hypot(c2f.x, c2f.y); // полная энергия двух гармоник
      // типа log P
      lps[i].p00 :=  E2i - Eall; // = 0   если 00 без шумов
      lps[i].p11 := -E2i - Eall; // = -2S
      lps[i].p10 :=  Er - Eall;  // = -S
      lps[i].p01 := -Er - Eall;  // = -S
      lps[i].Eall := Eall;
      Esum := Esum + Eall;
     end;
    // пока тупым перебором 256 вариантов { TODO : алгоритм левенберга-маркварда }
    pold := pold.MinValue;
    Ccod := 0;

    for i := 0 to CorrLen - 1 do
     begin
      p := 0;
      for j := 0 to DecodeBits-2 do
       begin
        cod := i shr (DecodeBits - 2 - j); // H7...L0
        p := p + lps[j].p[cod and 3];
       end;
       p := (Esum+p)/Esum*100;
       Corr.Data[i] := p;
       if p > pold then
        begin
         pold := p;
         Ccod := i;
        end;
     end;
    Result.Code := Ccod;
    Result.Quality := pold;// (Esum+pold)/Esum*100;
    Result.IsBad := Result.Quality < PorogCod;
   end;
end;

function RMCorrCode(Owner: TCustomDecoder; idx: GlobIdx): TCodeData;
 const
  RMCBIN: array [0..31, 0..31] of Integer =
         ((1,-1,1,-1,1,-1,-1,1,-1,1,-1,1,1,-1,1,-1,  1,-1,-1,1,1,-1,1,-1,-1,1,1,-1,1,-1,-1,1),      {cod0}
          (-1,1,-1,1,-1,1,1,-1,1,-1,1,-1,-1,1,-1,1, -1,1,1,-1,-1,1,-1,1,1,-1,-1,1,-1,1,1,-1),      {cod1}
          (-1,1,-1,1,-1,1,1,-1,1,-1,1,-1,-1,1,-1,1,  1,-1,-1,1,1,-1,1,-1,-1,1,1,-1,1,-1,-1,1),      {cod2}
          (1,-1,1,-1,1,-1,-1,1,-1,1,-1,1,1,-1,1,-1, -1,1,1,-1,-1,1,-1,1,1,-1,-1,1,-1,1,1,-1),      {cod3}
          (-1,1,-1,1,-1,1,1,-1,-1,1,-1,1,1,-1,1,-1,
           -1,1,1,-1,-1,1,-1,1,-1,1,1,-1,1,-1,-1,1),      {cod4}
          (1,-1,1,-1,1,-1,-1,1,1,-1,1,-1,-1,1,-1,1,
           1,-1,-1,1,1,-1,1,-1,1,-1,-1,1,-1,1,1,-1),      {cod5}
          (1,-1,1,-1,1,-1,-1,1,1,-1,1,-1,-1,1,-1,1,
           -1,1,1,-1,-1,1,-1,1,-1,1,1,-1,1,-1,-1,1),      {cod6}
          (-1,1,-1,1,-1,1,1,-1,-1,1,-1,1,1,-1,1,-1,
           1,-1,-1,1,1,-1,1,-1,1,-1,-1,1,-1,1,1,-1),      {cod7}
          (-1,1,-1,1,1,-1,-1,1,1,-1,1,-1,1,-1,1,-1,
           -1,1,1,-1,1,-1,1,-1,1,-1,-1,1,1,-1,-1,1),      {cod8}
          (1,-1,1,-1,-1,1,1,-1,-1,1,-1,1,-1,1,-1,1,
           1,-1,-1,1,-1,1,-1,1,-1,1,1,-1,-1,1,1,-1),      {cod9}
          (1,-1,1,-1,-1,1,1,-1,-1,1,-1,1,-1,1,-1,1,
           -1,1,1,-1,1,-1,1,-1,1,-1,-1,1,1,-1,-1,1),      {cod1-1}
          (-1,1,-1,1,1,-1,-1,1,1,-1,1,-1,1,-1,1,-1,
           1,-1,-1,1,-1,1,-1,1,-1,1,1,-1,-1,1,1,-1),      {cod11}
          (1,-1,1,-1,-1,1,1,-1,1,-1,1,-1,1,-1,1,-1,
           1,-1,-1,1,-1,1,-1,1,1,-1,-1,1,1,-1,-1,1),      {cod12}
          (-1,1,-1,1,1,-1,-1,1,-1,1,-1,1,-1,1,-1,1,
           -1,1,1,-1,1,-1,1,-1,-1,1,1,-1,-1,1,1,-1),      {cod13}
          (-1,1,-1,1,1,-1,-1,1,-1,1,-1,1,-1,1,-1,1,
           1,-1,-1,1,-1,1,-1,1,1,-1,-1,1,1,-1,-1,1),      {cod14}
          (1,-1,1,-1,-1,1,1,-1,1,-1,1,-1,1,-1,1,-1,
           -1,1,1,-1,1,-1,1,-1,-1,1,1,-1,-1,1,1,-1),      {cod15}
          (-1,1,1,-1,-1,1,-1,1,1,-1,-1,1,-1,1,1,-1,
           -1,1,-1,1,-1,1,1,-1,1,-1,1,-1,-1,1,-1,1),      {cod16}
          (1,-1,-1,1,1,-1,1,-1,-1,1,1,-1,1,-1,-1,1,
           1,-1,1,-1,1,-1,-1,1,-1,1,-1,1,1,-1,1,-1),      {cod17}
          (1,-1,-1,1,1,-1,1,-1,-1,1,1,-1,1,-1,-1,1,
           -1,1,-1,1,-1,1,1,-1,1,-1,1,-1,-1,1,-1,1),      {cod18}
          (-1,1,1,-1,-1,1,-1,1,1,-1,-1,1,-1,1,1,-1,
           1,-1,1,-1,1,-1,-1,1,-1,1,-1,1,1,-1,1,-1),      {cod19}
          (1,-1,-1,1,1,-1,1,-1,1,-1,-1,1,-1,1,1,-1,
           1,-1,1,-1,1,-1,-1,1,1,-1,1,-1,-1,1,-1,1),      {cod21}
          (-1,1,1,-1,-1,1,-1,1,-1,1,1,-1,1,-1,-1,1,
           -1,1,-1,1,-1,1,1,-1,-1,1,-1,1,1,-1,1,-1),      {cod21}
          (-1,1,1,-1,-1,1,-1,1,-1,1,1,-1,1,-1,-1,1,
           1,-1,1,-1,1,-1,-1,1,1,-1,1,-1,-1,1,-1,1),      {cod22}
          (1,-1,-1,1,1,-1,1,-1,1,-1,-1,1,-1,1,1,-1,
           -1,1,-1,1,-1,1,1,-1,-1,1,-1,1,1,-1,1,-1),      {cod23}
          (1,-1,-1,1,-1,1,-1,1,-1,1,1,-1,-1,1,1,-1,
           1,-1,1,-1,-1,1,1,-1,-1,1,-1,1,-1,1,-1,1),      {cod24}
          (-1,1,1,-1,1,-1,1,-1,1,-1,-1,1,1,-1,-1,1,
           -1,1,-1,1,1,-1,-1,1,1,-1,1,-1,1,-1,1,-1),      {cod25}
          (-1,1,1,-1,1,-1,1,-1,1,-1,-1,1,1,-1,-1,1,
           1,-1,1,-1,-1,1,1,-1,-1,1,-1,1,-1,1,-1,1),      {cod26}
          (1,-1,-1,1,-1,1,-1,1,-1,1,1,-1,-1,1,1,-1,
           -1,1,-1,1,1,-1,-1,1,1,-1,1,-1,1,-1,1,-1),      {cod27}
          (-1,1,1,-1,1,-1,1,-1,-1,1,1,-1,-1,1,1,-1,
           -1,1,-1,1,1,-1,-1,1,-1,1,-1,1,-1,1,-1,1),      {cod28}
          (1,-1,-1,1,-1,1,-1,1,1,-1,-1,1,1,-1,-1,1,
           1,-1,1,-1,-1,1,1,-1,1,-1,1,-1,1,-1,1,-1),      {cod29}
          (1,-1,-1,1,-1,1,-1,1,1,-1,-1,1,1,-1,-1,1,
           -1,1,-1,1,1,-1,-1,1,-1,1,-1,1,-1,1,-1,1),      {cod30}
          (-1,1,1,-1,1,-1,1,-1,-1,1,1,-1,-1,1,1,-1,
           1,-1,1,-1,-1,1,1,-1,1,-1,1,-1,1,-1,1,-1));      {cod31}
 var
  cor, dat, bit: TIndexArray;
  m, c, j, i: Integer;
  mx1,  mx2: TBufPoint;
begin
  // подготовка буферов
  // буфер Сырые данные
  mx1.dat := 0;
  dat := Owner.Buf.Read(idx, 32 * Owner.BitLen);
  Result.Buf[bftData] := dat;
  // буфер битовый фильтр
  if Owner.BitFilterOn then
   begin
    bit := dat.Copy(function (Idx: integer; Dat: Double): Double
    begin
      Result := Dat * Owner.BitFilter(Idx mod Owner.BitLen)
    end);
    Result.Buf[bftBit] := bit;
   end
  else bit := dat;
  // буфер корреляция
  cor.FirstIdx := idx;
  SetLength(cor.Data, 32);
  Result.Buf[bftCorr] := cor;
  // поиск корреляции
  for c := 0 to 31 do
   begin
    m := 0;
    cor.Data[c] := 0;
    for i := 0 to 31 do for j := 0 to Owner.BitLen-1 do
     begin
      cor.Data[c] := cor.Data[c] + RMCBIN[c,i] * bit.Data[m];
      Inc(m);
     end;
    cor.Data[c] := Owner.SPData.FazaFind*cor.Data[c]/32/Owner.BitLen;
    //if Owner.SPData.FazaFind = -1 then cor.Data[c] := -cor.Data[c];
    if cor.Data[c] >= mx1.dat then
     begin
      mx2 := mx1;
      mx1.Assign(cor.Data[c], c);
     end;
   end;
  Result.Code := mx1.idx;
  Result.Quality := Owner.ToPorogSP(mx1, mx2);
  Result.IsBad := Result.Quality < Owner.PorogCod;
end;
{$ENDREGION 'CorrCode'}


{$REGION 'B U F E R S'}

{ TFindSP }


procedure TFindSP.Add(const d: TIndexArray; Bits: Integer);
 var
  n: LocIdx;
  function Curr: Double;
  begin
    Result := Corr.Data[n];
  end;
begin
  n := Count;
  Corr := Corr + d;
  while n < Count do
   begin
     if Max2.dat < Curr then
      begin
       if  Max1.dat < Curr then
        begin
         if n > Max1.idx + Bits then Max2 := Max1;
         Max1.Assign(Curr, n);
        end
       else if n > Max1.idx + Bits then Max2.Assign(Curr, n);
      end;
     if  Min2.dat > Curr then
      begin
       if  Min1.dat > Curr then
        begin
         if n > Min1.idx + Bits then Min2 := Min1;
         Min1.Assign(Curr, n);
        end
       else if n > Min1.idx + Bits then Min2.Assign(Curr, n);
      end;
    Inc(n);
   end;
end;


function TFindSP.Count: LocIdx;
begin
  Result := Length(Corr.Data);
end;

function TFindSP.LastIndex: GlobIdx;
begin
  Result := Corr.Global(Length(Corr.Data)-1);
end;

procedure TFindSP.Reset(AFirstIdx: GlobIdx);
begin
  SetLength(Corr.Data, 0);
  Corr.FirstIdx := AFirstIdx;
  Max1.Assign(-100, 0);
  Max2.Assign(-100, 0);
  Min1.Assign(100, 0);
  Min2.Assign(100, 0);
end;

{ TSPData }

function TSPData.Faza: Integer;
begin
  if FazaCheck = 0 then Result := FazaFind
  else Result := FazaCheck;
end;

function TSPData.SPIndex: GlobIdx;
begin
  Result := Corr.Global(sp.idx);
end;

{ TCodeData }

function TCodeData.GetBuf(bt: TBufferType): TIndexArray;
 var
  i: Integer;
begin
  for i := 0 to Length(BufferType)-1 do if BufferType[i] = bt then Exit(CodBuf[i]);
  raise Exception.Create('TCodeData.GetBuf(bt: TBufferType): TIndexArray');
end;

procedure TCodeData.SetBuf(bt: TBufferType; const Value: TIndexArray);
 var
  i: Integer;
begin
  for i := 0 to Length(BufferType)-1 do if BufferType[i] = bt then
   begin
    CodBuf[i] := Value;
    Exit;
   end;
  BufferType := BufferType + [bt];
  CodBuf := CodBuf + [Value];
end;

{ TCodes }

procedure TCodes.Add(const cd: TCodeData);
begin
  CodData := CodData + [cd];
  if cd.IsBad then Inc(BadCodes);
end;

function TCodes.Count: Integer;
begin
  Result := Length(CodData);
end;

function TCodes.Curr: TCodeData;
begin
  Result := CodData[High(CodData)];
end;

procedure TCodes.Reset(AFirstIdx: GlobIdx);
begin
  SetLength(CodData, 0);
  BadCodes := 0;
  Idx := AFirstIdx;
end;

{$ENDREGION 'B U F E R S'}


{$REGION 'TCustomDecoder'}

{ TCustomDecoder }

function TCustomDecoder.GetCaption: string;
begin
  Result := FCaption;
end;

function TCustomDecoder.GetCodeLen: Integer;
begin
  Result := CodeBits*BitLen;
end;

function TCustomDecoder.GetDataLen: Integer;
begin
  Result := CodeBits*BitLen*DataCnt;
end;

function TCustomDecoder.GetFirstIdx: GlobIdx;
begin
  Result := Fbuf.FirstIndex;
end;

function TCustomDecoder.GetKadrBits: Integer;
begin
  Result := SPBits + CodeBits*DataCnt + NoiseBits;
end;

function TCustomDecoder.GetKadrLen: Integer;
begin
  Result := KadrBits*BitLen;
end;

function TCustomDecoder.GetLastIdx: GlobIdx;
begin
  Result := Fbuf.LastIndex;
end;

function TCustomDecoder.GetNoiseLen: Integer;
begin
  Result := NoiseBits*BitLen;
end;

function TCustomDecoder.GetSPLen: Integer;
begin
  Result := SPBits*BitLen;
end;

procedure TCustomDecoder.NotifyNewState;
begin
  if Assigned(FOnState) then FOnState(self);  
end;

procedure TCustomDecoder.SetBitLen(const Value: Integer);
 var
  i: Integer;
begin
  FBitLen := Value;
  SetLength(FBitFilter, FBitLen);
  for i := 0 to FBitLen-1 do  FBitFilter[i] := Sin(i/FBitLen*pi);
end;

procedure TCustomDecoder.SetBuf(const Value: TIndexBufDouble);
begin
  if FBuf <> Value then
   begin
    FBuf := Value;
    if FBuf.Capacity < KadrLen*8 then FBuf.Capacity := KadrLen*8;
    DoStart_csFindSP(FBuf.LastIndex+1);
   end;
end;

procedure TCustomDecoder.SetCaption(const Value: string);
begin
  FCaption := Value;
end;

class function TCustomDecoder.ToPorogSP(Amp, Amp2: TBufPoint): Double;
begin
  if (Amp.dat = 0) or (Abs(Amp2.dat) > Abs(amp.dat)) then Result := 0
  else Result := (1 - Abs(Amp2.dat/Amp.dat)) * 100;
end;

function __SetRes(out Res: TSPData; Faza: Integer; sp: TBufPoint; Porog: Double): Boolean;
begin
  Result := True;
  Res.FazaFind := Faza;
  Res.Quality := Porog;
  Res.sp := sp;
end;

function TCustomDecoder.TestCheckSP(const FndSP: TFindSP; var Spd: TSPData): Boolean;
 var
  idx: GlobIdx;
begin
  idx := Spd.SPIndex;
  with FndSP do if (Max1.dat > -Min1.dat) then
   begin
    Spd.Quality := ToPorogSP(Max1,  Max2);
    Spd.FazaCheck := 1;
    Spd.sp := Max1;
   end
  else
   begin
    Spd.Quality := ToPorogSP(Min1, Min2);
    Spd.FazaCheck := -1;
    Spd.sp := Min1;
   end;
  Spd.Corr := FndSP.Corr;
  spd.DTakt := Spd.SPIndex  - kadrLen - idx;
  Result := (Spd.Quality > FPorogSP) and (Spd.FazaCheck = spd.FazaFind) and (Abs(spd.DTakt) < 8);
end;

function TCustomDecoder.TestCurrentSP(out Res: TSPData): Boolean;
begin
  Result := False;
   // Амплитуда СП настоько большая что можно принять решение не дожидаясь конца пакета
  with FFindSP do if (Max1.dat > -Min1.dat) then
   begin
    if (Max1.idx < Count - BitLen*2) and ( Max1.dat > FAmpPorogSP) then Result := __SetRes(Res, 1, Max1, ToPorogSP(Max1,  Max2));
   end
  else
   begin
    if (Min1.Idx < Count - BitLen*2) and (-Min1.dat > FAmpPorogSP) then Result := __SetRes(Res, -1, Min1, ToPorogSP(Min1, Min2));
   end;
end;

function TCustomDecoder.UniqeCaseSP(const m1, m2: TBufPoint): Boolean;
begin
  Result := (m1.idx < BitLen div 2) and (m2.idx > KadrLen - BitLen div 2);
end;

function TCustomDecoder.TestKadrSP(out Res: TSPData): Boolean;
 var
  pr: Double;
  // особый случай когда СП в перыых BitLen тактах  |SP|_____|SP|
begin
  Result := False;
  with FFindSP do if (Max1.dat > -Min1.dat) then
   begin
    pr := ToPorogSP(Max1,  Max2);
    __SetRes(Res,  1, Max1, pr);
    if (pr >= FPorogSP) or UniqeCaseSP(Max1, Max2) then Exit(True);
   end
  else
   begin
    pr := ToPorogSP(Min1, Min2);
    __SetRes(Res, -1, Min1, pr);
    if (pr >= FPorogSP) or UniqeCaseSP(Min1, Min2) then Exit(True);
   end;
end;

procedure TCustomDecoder.UserSetState(const Value: TCorrelatorState);
begin
  if ((Value = csUserToFindSP) and (FState in [csCode, csCheckSP, csUserToSP])) or ((Value = csUserToSP) and (FState = csFindSP)) then
   begin
    FState := Value;
    NotifyNewState;
    RunAutomat;
   end;
end;

function TCustomDecoder.BitFilter(n: Integer): Double;
begin
  if FBitFilterOn then Result := FBitFilter[n] else Result := 1;
end;

function TCustomDecoder.CorrCode(idx: GlobIdx): TCodeData;
begin
  Result := FCorrCode(Self, idx);
end;

function TCustomDecoder.CorrSP(idx: GlobIdx; cnt: Integer): TIndexArray;
// const
//  CSPCODLEN = 128;
//  SP: array [0..CSPCODLEN-1] of integer =
//         ( -1, 1,-1, 1,-1, 1,-1, 1,-1, 1,-1, 1, 1,-1, 1,-1,
//            1,-1, 1,-1, 1,-1,-1, 1, 1,-1, 1,-1, 1,-1, 1,-1,
//           -1, 1,-1, 1, 1,-1, 1,-1, 1,-1,-1, 1, 1,-1,-1, 1,
//            1,-1, 1,-1,-1, 1,-1, 1,-1, 1,-1, 1, 1,-1,-1, 1,
//            1,-1, 1,-1, 1,-1,-1, 1,-1, 1,-1, 1, 1,-1, 1,-1,
//           -1, 1, 1,-1, 1,-1,-1, 1, 1,-1,-1, 1,-1, 1, 1,-1,
//           -1, 1,-1, 1,-1, 1, 1,-1,-1, 1,-1, 1, 1,-1, 1,-1,
//           -1, 1,-1, 1, 1,-1,-1, 1, 1,-1,-1, 1, 1,-1,-1, 1);
 var
  i, j, n: Integer;
begin
  //lidx := Fbuf.Local(idx);
  SetLength(Result.Data, cnt);
  for n := 0 to cnt-1 do
   begin
    Result.Data[n] := 0;
    for i := 0 to FSPbits-1 do for j := 0 to BitLen-1 do Result.Data[n] := Result.Data[n] + fSP[i] * Buf.Data[idx + n + i*BitLen + j];
    Result.Data[n] := Result.Data[n]/BitLen/FSPbits;
   end;
  Result.FirstIdx := idx;
end;

procedure TCustomDecoder.SetConst(ABitLen, ACodeBits, ADataCnt, ANoiseBits: Integer; ACorrCode: TCorrCodeFunc; SpFind: TSpCreateFunc);
begin
  BitLen := ABitLen;
  FCodeBits := ACodeBits;
  FDataCnt := ADataCnt;
  FNoiseBits := ANoiseBits;
  FCorrCode := ACorrCode;
  Fsp := SpFind;
  FSPbits := Length(Fsp);
  FPorogBadCodes := FDataCnt div 2;
end;

constructor TCustomDecoder.Create(Collection: TCollection);
begin
  inherited Create(Collection);
  DoSetConst;
end;

procedure TCustomDecoder.DoRun_csCheckSP;
 var
  idx: GlobIdx;
  fs: TfindSP;
begin
  if LastIdx < FSPData.SPIndex + KadrLen + SPLen + BitLen*2 then Exit;
  idx := FSPData.SPIndex + KadrLen - BitLen*2;
  fs.Reset(idx);
  fs.Add(CorrSP(idx, BitLen*4), BitLen);
  if TestCheckSP(fs, FSPData) then
   begin
//    NotifyNewState; // результат  csCheckSP
    FState := csSP;
    NotifyNewState; // результат  csSP и csCheckSP
    RunAutomat;
   end
  else
   begin
    NotifyNewState; // результат  csCheckSP bad
    DoStart_csFindSP(idx);
   end;
end;

procedure TCustomDecoder.DoRun_csFindSP;
 var
  cnt: Integer;
  spd: TSPData;
begin
  cnt := LastIdx - FFindSP.LastIndex - SPlen;
  if cnt <= 0 then Exit;
  /// обрезка по кадру
  if FindSP.Count + cnt > KadrLen then cnt := KadrLen - FindSP.Count;
//  Tdebug.log('         count find=%d            ',[cnt]);
  if cnt > 0 then FFindSP.Add(CorrSP(FFindSP.LastIndex+1, cnt), BitLen);
  /// заполнился кадр
  if FFindSP.Count = KadrLen then
    if TestKadrSP(spd) then
     begin
      /// Добавились данные
      NotifyNewState;
      /// СП
      DoStart_csSP(spd)
     end
    else
     begin
      /// Добавились данные
      NotifyNewState;
      /// снова поиск СП
      DoStart_csFindSP(FFindSP.LastIndex + 1)
     end
  else
  ///  кадр в поцессе заполнения
   if TestCurrentSP(spd) then
    begin
      /// Добавились данные
     NotifyNewState;
     /// Высокая амплитуда
     DoStart_csSP(spd)
    end
      /// Добавились данные
   else NotifyNewState;
end;

procedure TCustomDecoder.DoRun_csUserToSP;
 var
  spd: TSPData;
begin
  TestKadrSP(spd);
  DoStart_csSP(spd);
end;

procedure TCustomDecoder.DoSetConst;
begin
  SetConst(8, 32, 8, 0, RMCorrCode, Manchester2SpCreate);
  FPorogSP := 60;
  FPorogCod := 40;
  FAmpPorogSP := 2000*128;
end;

procedure TCustomDecoder.DoStart_csCheckSP(idx: GlobIdx);
begin
  if idx <> FspData.SPIndex + KadrLen then
     raise Exception.CreateFmt('Ошибка проверки индекса СП SP+KDR %d <> %d', [FspData.SPIndex + KadrLen, idx]);
  FState := csCheckSP;
//  NotifyNewState; // т.к. длительнаня операция событие csCheckSP приходит в конце с.м. DoRun_csCheckSP
  RunAutomat;
end;

procedure TCustomDecoder.DoStart_csFindSP(idx: GlobIdx);
begin
  FState := csFindSP;
  FindSP.Reset(idx);
//  NotifyNewState;  // т.к. пустой экран
  RunAutomat;
end;

procedure TCustomDecoder.DoStart_csSP(const NewSp: TSPData);
  var
   idx, frst, last, cnt: GlobIdx;
begin
  FSPData := NewSp;
  FSPData.FazaCheck := 0;
  FSPData.DTakt := 1000;
  // FSPData.sp - локальная точка буфера FindSP.Corr !!!
  idx := FindSP.Corr.Global(FSPData.sp.idx); // глобальный индекс СП
  // создаем буфер корреляции области СП
  frst := max(idx - BitLen*2, FBuf.FirstIndex);
  last := min(idx + BitLen*2, FBuf.LastIndex);
  cnt := last-frst+1;
  if cnt > 0 then
   begin
    FSPData.Corr := CorrSP(frst, last-frst+1);
    // перенос локальной точки из FindSP.Corr в FSPData.Corr
    FSPData.sp.idx := FindSP.Corr.LocalTo(FSPData.Corr, FSPData.sp.idx);
   end;
  FState := csSP;
  NotifyNewState;
  RunAutomat;
end;

procedure TCustomDecoder.RunAutomat;
begin
   case State of
    csFindSP: DoRun_csFindSP;
    csSP:
     begin
      FCodes.Reset(FspData.SPIndex + SPLen);
      FState := csCode;
      RunAutomat;
     end;
    csCode: while FCodes.Idx <= LastIdx - CodeLen { + OversampDataLen} do
     begin
      FCodes.Add(CorrCode(FCodes.Idx));
      NotifyNewState;
      Inc(FCodes.Idx, CodeLen);
      if FCodes.Count = DataCnt then
       begin
        DoStart_csCheckSP(FCodes.Idx + NoiseLen);
        Exit;
       end
      else if FCodes.BadCodes > PorogBadCodes then
       begin
        FState := csBadCodes;
        NotifyNewState;
        RunAutomat;
        Exit;
       end;
     end;
    csCheckSP: DoRun_csCheckSP;
    csBadCodes, csUserToFindSP: DoStart_csFindSP(FCodes.Idx);
    csUserToSP: DoRun_csUserToSP;
  end;
end;
{$ENDREGION 'TCustomDecoder'}


{ TCustomDecoderFourier }

constructor TCustomDecoderFourier.Create(Collection: TCollection);
begin
  inherited;
  FourierFactory(FFourier);
end;

{ TWindowDecoder }

procedure TWindowDecoder.DoRun_csFindSP;
// var
//  spd: TSPData;
//  f, l: Integer;
begin
  if SPWindow = 0 then UpdateSPWindow(FFindSP.Corr.FirstIdx);
  inherited;
// Exit;
//  if FFindSP.LastIndex <= LastIdx - SPlen + SPDeltaBit*BitLen then
//   begin
//    f := max(FFindSP.LastIndex-SPDeltaBit*BitLen, Firstidx);
//    l := FFindSP.LastIndex + SPDeltaBit*BitLen;
//    FFindSP.Reset(f);
//    FFindSP.Add(CorrSP(f, l-f+1), BitLen);
//    NotifyNewState;
//    if TestKadrSP(spd) then DoStart_csSP(spd)
//    else DoStart_csFindSP(FFindSP.LastIndex + 1)
//   end;
end;

procedure TWindowDecoder.DoRun_csUserToSP;
 var
  l, h: GlobIdx;
begin
  l := FSPIndex - SPDeltaBit*BitLen;
  h := FSPIndex + SPDeltaBit*BitLen;
  if (firstidx <= l) and (h + SPLen <= lastidx) then
   begin
    FFindSP.Reset(l);
    FFindSP.Add(CorrSP(l, SPDeltaBit*BitLen*2), BitLen);
    inherited DoRun_csUserToSP;
   end;
end;

procedure TWindowDecoder.DoSetConst;
begin
  inherited;
  SetConst(8, 16, 6, 128+16*6, Manchester2CorrCode, Manchester2SpCreate);
  FSPDelta := 10;
end;

procedure TWindowDecoder.DoStart_csFindSP(idx: GlobIdx);
begin
  UpdateSPWindow(idx);
  inherited DoStart_csFindSP(idx);
end;

function TWindowDecoder.GetStartTime: TDateTime;
 var
  opt: IProjectOptions;
begin
  if Supports(GContainer, IProjectOptions, opt) then Result := opt.DelayStart
  else Result := 0;
end;

{function TWindowDecoder.TestKadrSP(out Res: TSPData): Boolean;
 var
  pr: Double;
  gidx: Globidx;
  function Chk: Boolean;
   var
    dl, dh, i: Integer;
  begin
    dh := KadrLen;
    for i:= -2 to 2 do
     begin
      dl := Abs(gidx - FSPIndex - KadrLen*i);
      if dl < dh then dh := dl;
     end;
    Result := dh <= SPDeltaBit*bitlen;
  end;
begin
  Result := False;
  with FFindSP do if (Max1.dat > -Min1.dat) then
   begin
    pr := ToPorogSP(Max1,  Max2);
    __SetRes(Res,  1, Max1, pr);
    gidx := Corr.Global(Max1.idx);
    Result := Chk;
    if not Result then
     begin
      __SetRes(Res,  1, Max2, pr);
      gidx := Corr.Global(Max2.idx);
      Result := Chk;
     end;
    //if (pr >= FPorogSP) or UniqeCaseSP(Max1, Max2) then Exit(True);
   end
  else
   begin
    pr := ToPorogSP(Min1, Min2);
    __SetRes(Res, -1, Min1, pr);
    gidx := Corr.Global(Min1.idx);
    Result := Chk;
    if not Result then
     begin
      __SetRes(Res,  1, Min2, pr);
      gidx := Corr.Global(Min2.idx);
      Result := Chk;
     end;
   // if (pr >= FPorogSP) or UniqeCaseSP(Min1, Min2) then Exit(True);
   end;
end;     }

procedure TWindowDecoder.UpdateSPWindow(idx: GlobIdx);
 var
  uso: IUsodata;
  dt, idxc : Integer;
  st: TDateTime;
begin
  st := SPStartTime;
  // найти число тактов усо от текущего момента до сп по модулю Кадр idx + delta
  if (st > 0) and Assigned(TryUsoData) and TryUsoData(uso) then
   begin
    dt := Round((Now-st)*24*3600*1000/uso.FufferDataPeriod) mod KadrLen;
    //Tdebug.log(' KADR = %d',[ Round((Now-st)*24*3600*1000/uso.FufferDataPeriod) div KadrLen]);
    idxc := uso.RealTimeLastIndex + KadrLen - dt  + FSPBeginBit*bitlen;
    { TODO : подобрать подходящий ближайший но не старый индех }
    if idxc > idx then
     begin
      while idxc - idx > KadrLen do dec(idxc, KadrLen);
      FSPIndex := idxc; //
     end
    else FSPIndex := idxc + KadrLen; //?????
   end;
end;

{ TDecoderManchRetr }

procedure TDecoderManchRetr.DoSetConst;
begin
  inherited;
  SetConst(8, 16, 6, 128+16*6, Manchester2CorrCode, Manchester2SpCreate);
end;

{ TDecoderFMRetr }

procedure TDecoderFMRetr.DoRun_csFindSP;
begin
  if FCmdSendFlag and (FusoIdx = 0) then  InitUsoEvent;
  inherited;
end;

procedure TDecoderFMRetr.UsoEvent(Uso: TObject);
 var
  iuso: IUsodata;
begin
  if Supports(Uso, IUsodata, iuso) then
   begin
    Inc(FusoIdx, KadrLen);
    iuso.RegEvent(FusoIdx, UsoEvent);
    iuso.Send(FCmd);
    Tdebug.log(' CMD = %d',[Fcmd]);
    FCmd := (FCmd+1) mod 12;
   end;
end;

procedure TDecoderFMRetr.DoSetConst;
begin
  inherited;
  SetConst(8, 16*2, 6, 32{(128+16*6)*2}, FmCorrCode, FmSpCreate);
  PorogSP := 40;
end;

function TDecoderFMRetr.GetStartTime: TDateTime;
 var
  opt: IProjectOptions;
begin
  if Supports(GContainer, IProjectOptions, opt) then Result :=opt.DelayStart
  else Result := 0;
end;

procedure TDecoderFMRetr.InitUsoEvent;
 var
  uso: IUsodata;
  st: TDateTime;
  dt: Integer;
begin
  st := SPStartTime;
  if (st > 0) and Assigned(TryUsoData) and TryUsoData(uso) then
   begin
    dt := Round((Now-st)*24*3600*1000/uso.FufferDataPeriod) mod KadrLen;
    // У ретранслятора в начале кадра идут шумы
    FusoIdx := uso.RealTimeLastIndex + KadrLen - dt;// - CodeLen*3;
    uso.RegEvent(FusoIdx, UsoEvent);
   end;
end;

procedure TDecoderFMRetr.SetCmdSendFlag(const Value: Boolean);
begin
  FCmdSendFlag := Value;
  if FCmdSendFlag then
   begin
    FusoIdx := 0;
    InitUsoEvent;
   end;
end;

{ TWindowDecoderFM }

procedure TWindowDecoderFM.DoSetConst;
begin
  inherited;
  SetConst(8, 16*2, 6, (128+16*6)*2, FmCorrCode, FmSpCreate);
  PorogSP := 40;
end;

{ TCustomDecoderWrap }

//class operator TCustomDecoderWrap.Implicit(d: TCustomDecoderWrap): TCustomDecoder;
//begin
//  Result := d.obj;
//end;
//
//class operator TCustomDecoderWrap.Implicit(d: TCustomDecoder): TCustomDecoderWrap;
//begin
//  Result.obj := d;
//end;

initialization
  RegisterClasses([TCustomDecoderFourier, TCustomDecoder, TWindowDecoder, TDecoderManchRetr, TWindowDecoderFM, TDecoderFMRetr]);
end.

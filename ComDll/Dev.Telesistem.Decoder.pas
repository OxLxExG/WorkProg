unit Dev.Telesistem.Decoder;

interface

uses JDtools,
     System.SysUtils,  System.Classes, System.TypInfo, System.Rtti, Fibonach, MathIntf, System.Math, Math.Telesistem,
     Actns, DeviceIntf, AbstractDev, debug_except, ExtendIntf, Container, PluginAPI, RootImpl, RootIntf, SubDevImpl, tools;
type
  TCustomDecoderDev = class(TSubDevWithForm<TTelesistemDecoder>)
  private
    FPorogCode: Real;
    FNumBadCode: Integer;
    FPorogSP: Real;
    FSPCodLen: Integer;
    FDataCnt: Integer;
    FDataCodLen: Integer;
    FBits: Integer;
    FBitFilter: Boolean;
    FDataNoiseCnt: Integer;
    procedure SetNumBadCode(const Value: Integer);
    procedure SetPorogCode(const Value: Real);
    procedure SetPorogSP(const Value: Real);
    procedure SetBits(const Value: Integer);
    procedure SetDataCnt(const Value: Integer);
    procedure SetDataCodLen(const Value: Integer);
    procedure SetSPCodLen(const Value: Integer);
    procedure SetBitFilter(const Value: Boolean);
    procedure SetDataNoiseCnt(const Value: Integer);
    procedure OnSPTakt(Sender: TTelesistemDecoder; Takt: LongWord);
  protected
    FDecoder: TTelesistemDecoder;
    procedure OnDecoder(Sender: TObject);
    function GetCategory: TSubDeviceInfo; override;
    function GetDecoderClass: TDecoderClass; virtual; abstract;
    procedure SetupNewDecoder; virtual;
  public
    procedure InputData(Data: Pointer; DataSize: integer); override; final;
    constructor Create; override;
    destructor Destroy; override;
  published
    [ShowProp('Порог СП %')]               property PorogSP    : Real   read FPorogSP     write SetPorogSP;
    [ShowProp('Порог данных %')]           property PorogCode  : Real   read FPorogCode   write SetPorogCode;
    [ShowProp('Число ошибочных данных')]   property NumBadCode : Integer read FNumBadCode write SetNumBadCode default 8;
    [ShowProp('Битовый фильтр')]           property BitFilter: Boolean  read FBitFilter   write SetBitFilter  default False;
    property Bits: Integer read FBits write SetBits default 8;
    [ShowProp('Число данных')] property DataCnt: Integer read FDataCnt write SetDataCnt default 32;
    [ShowProp('Число шумов')] property DataNoiseCnt: Integer read FDataNoiseCnt write SetDataNoiseCnt default 0;
    property DataCodLen: Integer read FDataCodLen write SetDataCodLen default 32;
    property SPCodLen: Integer read FSPCodLen write SetSPCodLen default 128;
  end;

implementation

{ TCustomDecoder }

constructor TCustomDecoderDev.Create;
begin
  PorogSP := 50;
  PorogCode := 51;
  NumBadCode := 14;
  FBits := 8;
  FDataCnt := 32;
  FDataCodLen := 32;
  FSPCodLen := 128;
  inherited;
end;

destructor TCustomDecoderDev.Destroy;
begin
  if Assigned(FDecoder) then FDecoder.Free;
  inherited;
end;

procedure TCustomDecoderDev.SetBitFilter(const Value: Boolean);
begin
  if FBitFilter <> Value then
   begin
    FBitFilter := Value;
    if Assigned(FDecoder) then FreeAndNil(FDecoder);
   end;
end;

procedure TCustomDecoderDev.SetBits(const Value: Integer);
begin
  if FBits <> Value then
   begin
    FBits := Value;
    if Assigned(FDecoder) then FreeAndNil(FDecoder);
   end;
end;

procedure TCustomDecoderDev.SetDataCnt(const Value: Integer);
begin
  if FDataCnt <> Value then
   begin
    FDataCnt := Value;
    if Assigned(FDecoder) then FreeAndNil(FDecoder);
   end;
end;

procedure TCustomDecoderDev.SetDataCodLen(const Value: Integer);
begin
  if FDataCodLen <> Value then
   begin
    FDataCodLen := Value;
    if Assigned(FDecoder) then FreeAndNil(FDecoder);
   end;
end;

procedure TCustomDecoderDev.SetDataNoiseCnt(const Value: Integer);
begin
  if FDataNoiseCnt <> Value then
   begin
    FDataNoiseCnt := Value;
    if Assigned(FDecoder) then FreeAndNil(FDecoder);
   end;
end;

procedure TCustomDecoderDev.SetSPCodLen(const Value: Integer);
begin
  if FSPCodLen <> Value then
   begin
    FSPCodLen := Value;
    if Assigned(FDecoder) then FreeAndNil(FDecoder);
   end;
end;

procedure TCustomDecoderDev.SetNumBadCode(const Value: Integer);
begin
  FNumBadCode := Value;
  if Assigned(FDecoder) then FDecoder.PorogBadCodes := Value;
end;

procedure TCustomDecoderDev.SetPorogCode(const Value: Real);
begin
  FPorogCode := Value;
  if Assigned(FDecoder) then FDecoder.PorogCod := Value;
end;

procedure TCustomDecoderDev.SetPorogSP(const Value: Real);
begin
  FPorogSP := Value;
  if Assigned(FDecoder) then FDecoder.PorogSP := Value;
end;

function TCustomDecoderDev.GetCategory: TSubDeviceInfo;
begin
  Result.Category := 'Декодер';
  Result.Typ := [sdtUniqe, sdtMastExist];
end;

procedure TCustomDecoderDev.SetupNewDecoder;
begin
  FDecoder.PorogSP := PorogSP;
  FDecoder.PorogCod := PorogCode;
  FDecoder.PorogBadCodes := NumBadCode;
  FDecoder.BitFilterOn := BitFilter;
end;

procedure TCustomDecoderDev.InputData(Data: Pointer; DataSize: integer);
begin
  if not Assigned(FDecoder) then
   begin
    FDecoder := GetDecoderClass.Create(Bits, DataCnt, DataNoiseCnt, DataCodLen, SPCodLen, OnDecoder, OnSPTakt);
    FS_Data := FDecoder;
    SetupNewDecoder;
   end;
  FDecoder.AddData(Data, DataSize, procedure (DelSize: Integer)
   var
    sd : ISubDevice;
  begin
    for sd in (Owner as IRootDevice).GetSubDevices do  TSubDev(sd).DeleteData(DelSize);
  end);
end;

procedure TCustomDecoderDev.OnDecoder(Sender: TObject);
begin
  NotifyData;
  if Assigned(FChildSubDevice) then FChildSubDevice.InputData(FDecoder, $12345678);
end;

procedure TCustomDecoderDev.OnSPTakt(Sender: TTelesistemDecoder; Takt: LongWord);
 var
  sd: ISubDevice;
  bm: ISetBookMark;
  t: LongWord;
begin
  for sd in (Owner as IRootDevice).GetSubDevices() do
   if (sd.Category.Category = 'Усо') and Supports(sd, ISetBookMark, bm) then
    begin
     t := Takt + Sender.KadrBezShumaLen;
      TDebug.Log('DECODER======== F:%d T:%d DF:%d B%d KD:%d===============',[Sender.First,
                                                               Takt,
                                                               Takt-Sender.First,
                                                               t, Sender.KadrBezShumaLen]);

     bm.SetBookMark(t);
    end;
end;

end.

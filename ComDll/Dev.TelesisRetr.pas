unit Dev.TelesisRetr;

interface

uses  System.SysUtils,  System.Classes, System.TypInfo, Xml.XMLIntf, Math.Telesistem, RootIntf, SubDevImpl, RootImpl, IndexBuffer,
      Container, DeviceIntf, Dev.Telesistem, ExtendIntf, Actns, Dev.Telesistem.Data, Dev.Telesistem.Decoder, JDtools,
      Fifo, MathIntf, debug_except, Fifo.FFT, Fifo.Decoder, Math.Telesistem.Custom, Vcl.Dialogs, Vcl.Forms,
      JvExControls, JvInspector, JvComponentBase,  JvResources,
      System.Bindings.Helper, System.IOUtils;

const
   TELESIS_STRUCURE: array[0..3] of TSubDeviceInfo = (
   (typ: [sdtUniqe, sdtMastExist]; Category: 'Усо'),
                                  (Category: 'Фильтры'),
   (typ: [sdtUniqe, sdtMastExist]; Category: 'Декодер'),
   (typ: [sdtUniqe, sdtMastExist]; Category: 'Данные')
   );

type

  TDoubleSubDev = class(TSubDevWithForm<TBookmarkFifoDouble>)
  private
//    FPainter: TObject;
    procedure SetCapacity(const Value: Integer);
    function GetCapacity: Integer;
  protected
    function ClassFifo: TBookmarkFifoDoubleClass; virtual;
//    function GetPainter: TObject;
//    procedure SetPainter(const Value: TObject);

    procedure Extract(); override;
    procedure Insert(Index: Integer); override;
//    procedure OnUserRemove;  override;
//    procedure BeforeRemove(); override;

    procedure SetChildSubDevice(const Value: TSubDev); override;
    procedure SetParentSubDevice(const Value: TSubDev); override;
  public
    destructor Destroy; override;
    property Capacity : Integer read GetCapacity write SetCapacity;
//    property Painter: TObject read GetPainter write SetPainter;
  end;

  TOpenUsoFile = type TFileName;

  TUsoRetrans = class(TDoubleSubDev, IOscDataSubDevice, IUSOData)
  private
    RecRun: TRecRun;
    FKSum: Integer;
    FFrequency: TTelesisFrequency;
    FData: array[0..63] of Double;
    FbufCount: Integer;
    FFileName: TOpenUsoFile;
    FFileStream: TFileStream;
    procedure SetFrequency(const Value: TTelesisFrequency);
    procedure SetFileName(const Value: TOpenUsoFile);
  protected
   const
      TIME_TO_USO = 24*3600/(6.144/1000);
    procedure RemoveUserForm; override;
    function GetCategory: TSubDeviceInfo; override;
    function GetCaption: string; override;

    function RealTimeLastIndex: Integer;
    function FufferDataPeriod: Double; // ms
  public
    constructor Create; override;
    procedure InputData(Data: Pointer; DataSize: integer); override;
  published
    [ShowProp('Частота прибора')] property Frequency: TTelesisFrequency read FFrequency write SetFrequency default afq10;
    [ShowProp('Файл записи данных')] property FileName: TOpenUsoFile read FFileName write SetFileName;
  end;

  TOiRetrans = class(TDoubleSubDev, IOscDataSubDevice)
   private
    Ffifo: array[0..7] of Double;
    FUnicCaption: string;
  protected
    procedure RemoveUserForm; override;
    function GetCategory: TSubDeviceInfo; override;
    function GetCaption: string; override;
  public
    constructor Create; override;
    procedure InputData(Data: Pointer; DataSize: integer); override;
  published
    [ShowProp('Имя')] property UnicCaption: string read FUnicCaption write FUnicCaption;
  end;

  TFFTRetrans = class(TDoubleSubDev)//, IOscDataSubDevice)
   private
    FFVch2: Integer;
    FFVch1: Integer;
    FFchw: Integer;
    FFNch2: Integer;
    FFNch1: Integer;
    FFch: Integer;
    FUnicCaption: string;
    procedure SetFch(const Value: Integer);
    procedure SetFchw(const Value: Integer);
    procedure SetFNch1(const Value: Integer);
    procedure SetFNch2(const Value: Integer);
    procedure SetFVch1(const Value: Integer);
    procedure SetFVch2(const Value: Integer);
    function GetFFT: TfifoFFT; inline;
  protected
    function ClassFifo: TBookmarkFifoDoubleClass; override;
    function GetCategory: TSubDeviceInfo; override;
    function GetCaption: string; override;
    procedure SetupFilter;
  public
    constructor Create; override;
    procedure InputData(Data: Pointer; DataSize: integer); override;
    [DynamicAction('Показать спектр', '<I>', 52, '0:Телесистема.<I>', 'спектр')]
    procedure DoSetup(Sender: IAction); override;
    property FFT: TfifoFFT read GetFFT;
  published
    [ShowProp('Имя')] property UnicCaption: string read FUnicCaption write FUnicCaption;
    [ShowProp('ФНЧ 1')] property FNch1: Integer read FFNch1 write SetFNch1;
    [ShowProp('ФНЧ 2')] property FNch2: Integer read FFNch2 write SetFNch2;
    [ShowProp('ФВЧ 1')] property FVch1: Integer read FFVch1 write SetFVch1;
    [ShowProp('ФВЧ 2')] property FVch2: Integer read FFVch2 write SetFVch2;
    [ShowProp('ФЧ')]    property Fch: Integer read FFch write SetFch;
    [ShowProp('ФЧ ширина')] property FVchw: Integer read FFchw write SetFchw;
  end;

  TretrData = class(TCustomTeleData)
  public
    function GetCaption: string; override;
    function GetMetaData: IXMLInfo; override;
  end;

//  TDecoderManchRetr = class(TCustomDecoderFourier)
//  protected
//    procedure DoSetConst; override;
//  end;

  TDevDecoderRetr = class(TDoubleSubDev, ITelesistem_retr)
  private
    FS_Decoder: TCustomDecoderWrap;
    function GetDecoders: TCustomDecoderCollection;
    procedure SetDecoders(const Value: TCustomDecoderCollection);
    procedure SetS_Decoder(const Value: TCustomDecoderWrap);
    procedure OnDecoder(Sender: TObject);
  protected
    procedure DefineProperties(Filer: TFiler); override;
    function ClassFifo: TBookmarkFifoDoubleClass; override;
    function GetCategory: TSubDeviceInfo; override;
    function GetCaption: string; override;
    function GetUSOData(out USOData: IUSOData): Boolean;
    procedure Loaded; override;
  public
    procedure InputData(Data: Pointer; DataSize: integer); override;
    constructor Create; override;
    [DynamicAction('Показать окно Декорера', '<I>', 55, '0:Телесистема.<I>', 'Показать окно Декорера')]
    procedure DoSetup(Sender: IAction); override;
//  published
    [ShowProp('декодеры')] property Decoders: TCustomDecoderCollection read GetDecoders write SetDecoders;
///  используем для соединения не S_Data а S_Decoder
    property S_Decoder: TCustomDecoderWrap read FS_Decoder write SetS_Decoder;
  end;

  TTelesisRetr = class(TTelesistem, INotifyAfterAdd)
  protected
    function GetService: PTypeInfo; override;
    function GetStructure: TArray<TSubDeviceInfo>; override;
    procedure AfterAdd();
  public
    [DynamicAction('Установки телесистемы', '<I>', 52, '0:Телесистема.<I>', 'Установки телесистемы')]
    procedure DoSetup(Sender: IAction); override;
    [DynamicAction('Показать окно осцилограмм', '<I>', 152, '0:Телесистема.<I>', 'Показать окно осцилограмм')]
    procedure DoShowOscForm(Sender: IAction);
  end;

implementation

uses tools;

function IsDataFifo(Obj: TObject): Boolean;
begin
  Result := obj is TSubDev<TBookmarkFifoDouble>;
end;

{$REGION 'TDoubleSubDev '}
{ TDoubleSubDev }

function TDoubleSubDev.ClassFifo: TBookmarkFifoDoubleClass;
begin
  Result := TBookmarkFifoDouble;
end;

destructor TDoubleSubDev.Destroy;
begin
  if Assigned(FS_Data) then FreeAndNil(FS_Data);
  inherited;
end;

procedure TDoubleSubDev.Extract;
begin
  FS_Data.Extract(nil);
  inherited Extract;
end;

function TDoubleSubDev.GetCapacity: Integer;
begin
  if Assigned(FS_Data) then Result := FS_Data.Capacity else Result := 0
end;

//function TDoubleSubDev.GetPainter: TObject;
//begin
//  Result := FPainter;
//end;

//procedure TDoubleSubDev.OnUserRemove;
//begin
//  inherited;
//  if Assigned(FPainter) then FreeAndNil(FPainter);
//end;

//procedure TDoubleSubDev.BeforeRemove;
//begin
//  inherited;
//  if Assigned(FPainter) then FreeAndNil(FPainter);
//end;

procedure TDoubleSubDev.Insert(Index: Integer);
begin
  inherited;
  if Index > 0 then
   begin
    if IsDataFifo(Collection.Items[Index-1]) then TSubDev<TBookmarkFifoDouble>(Collection.Items[Index-1]).FS_Data.Insert(FS_Data)
   end
  else if Collection.Count > 1 then
   begin
    if IsDataFifo(Collection.Items[1]) then TSubDev<TBookmarkFifoDouble>(Collection.Items[1]).FS_Data.Insert(FS_Data, nil, True)
   end
  else
   begin
    FS_Data.FirstIndex := 1;
    FS_Data.ChildFifo := nil;
    FS_Data.ParentFifo := nil;
   end;
end;

procedure TDoubleSubDev.SetCapacity(const Value: Integer);
begin
  if not Assigned(FS_Data) then
   begin
    FS_Data := ClassFifo.Create(self, Value);
    FS_Data.Name := Caption;
   end;
  FS_Data.Capacity := Value;
end;

procedure TDoubleSubDev.SetChildSubDevice(const Value: TSubDev);
begin
  inherited;
  if Assigned(Value) and IsDataFifo(Value) then FS_Data.ChildFifo := TSubDev<TBookmarkFifoDouble>(Value).FS_Data;
end;

//procedure TDoubleSubDev.SetPainter(const Value: TObject);
//begin
//  FPainter := Value;
//end;

procedure TDoubleSubDev.SetParentSubDevice(const Value: TSubDev);
begin
  inherited;
  if Assigned(Value) and IsDataFifo(Value) then FS_Data.ParentFifo := TSubDev<TBookmarkFifoDouble>(Value).FS_Data;
end;
{$ENDREGION 'TDoubleSubDev '}

{$REGION 'TTelesisRetr'}

{ TTelesisRetr }

procedure TTelesisRetr.AfterAdd;
begin
  AddOrReplase(typeInfo(TUsoRetrans));
//  AddOrReplase(typeInfo(TFltBPF));
  AddOrReplase(typeInfo(TDevDecoderRetr));
  AddOrReplase(typeInfo(TretrData));
  (Self as IBind).Notify('S_PublishedChanged');
end;

procedure TTelesisRetr.DoSetup(Sender: IAction);
begin
  inherited;
end;

procedure TTelesisRetr.DoShowOscForm(Sender: IAction);
 var
  m: ModelType;
  s: string;
  F: IForm;
begin
  s := 'OscForm_' + Name;
  F := (Gcontainer as IformEnum).Get(s);
  if Assigned(F) then
   begin
    F.Show;
    Exit;
   end;
  m := GContainer.GetModelType('TOscForm');
  if Assigned(m)  then
    begin
     F := TIForm.NewForm(m, s);
     (F as IControlForm).ControlName := Name;
     if Assigned(F) then (Gcontainer as IformEnum).Add(F);
     F.Show;
    end
end;

function TTelesisRetr.GetService: PTypeInfo;
begin
  Result := TypeInfo(ITelesistem_retr);
end;

function TTelesisRetr.GetStructure: TArray<TSubDeviceInfo>;
begin
  SetLength(Result, Length(TELESIS_STRUCURE));
  Move(TELESIS_STRUCURE[0], Result[0], Length(TELESIS_STRUCURE)*SizeOf(TSubDeviceInfo));
end;


{ TretrData }

function TretrData.GetCaption: string;
begin
  Result := 'test telesis RETR'
end;

function TretrData.GetMetaData: IXMLInfo;
 var
  GDoc: IXMLDocument;
begin
  FFileName := ExtractFilePath(ParamStr(0)) + 'Devices\tst_telesis2.hxml';
  GDoc := NewXDocument();
  GDoc.LoadFromFile(FileName);
  Result := GDoc.DocumentElement;
end;

{ TDecoderRetr }

function TDevDecoderRetr.ClassFifo: TBookmarkFifoDoubleClass;
begin
  Result := TFifoDecoder;
end;

constructor TDevDecoderRetr.Create;
begin
  FS_Data := ClassFifo.Create(self, 4096);
  inherited;
  if not IsLoaded then
   begin
    TDecoderManchRetr.Create(Decoders);
    TWindowDecoder.Create(Decoders);
    TWindowDecoder.Create(Decoders);
    Loaded;
   end;
  InitConst('TDecoderRETRForm', 'DecoderRETR_');
end;

procedure TDevDecoderRetr.Loaded;
  var
  i: Integer;
begin
  TCustomDecoder(Decoders.Items[0]).Text := 'декодер';
  TCustomDecoder(Decoders.Items[1]).Text := 'синхронный декодер(телесистема)';
  TCustomDecoder(Decoders.Items[2]).Text := 'синхронный декодер(ретранслятор)';

   for i := 0 to Decoders.Count-1 do
    begin
     TCustomDecoder(Decoders.Items[i]).Buf := FS_Data;
     TCustomDecoder(Decoders.Items[i]).OnState := OnDecoder;
    end;

  (Decoders.Items[1] as TWindowDecoder).GetUSOData := GetUSOData;
  (Decoders.Items[2] as TWindowDecoder).GetUSOData := GetUSOData;
  (Decoders.Items[2] as TWindowDecoder).SPBeginBit := 128+16*6; //'синхронный декодер(ретранслятор)';

//  Capacity := TCustomDecoder(Decoders.Items[0]).KadrLen*8;
end;

procedure TDevDecoderRetr.DefineProperties(Filer: TFiler);
begin
  inherited;
  Decoders.RegisterProperty(Filer, 'PrpDecoders');
end;

procedure TDevDecoderRetr.DoSetup(Sender: IAction);
begin
  inherited;
end;

function TDevDecoderRetr.GetCaption: string;
begin
  Result := 'manchster';
end;

function TDevDecoderRetr.GetCategory: TSubDeviceInfo;
begin
  Result := TELESIS_STRUCURE[2];
end;

function TDevDecoderRetr.GetDecoders: TCustomDecoderCollection;
begin
  Result := TFifoDecoder(FS_Data).Decoders;
end;

function TDevDecoderRetr.GetUSOData(out USOData: IUSOData): Boolean;
begin
  Result := Supports(Owner.SubDevices[0], IUSOData, USOData)
end;

procedure TDevDecoderRetr.InputData(Data: Pointer; DataSize: integer);
begin
  FS_Data.Write(Data, DataSize);
  TFifoDecoder(FS_Data).ExecDecoders;
end;

procedure TDevDecoderRetr.OnDecoder(Sender: TObject);
begin
  S_Decoder := Sender as TCustomDecoder;
end;

procedure TDevDecoderRetr.SetS_Decoder(const Value: TCustomDecoderWrap);
begin
  FS_Decoder := Value;
  TBindings.Notify(Self, 'S_Decoder');
end;

procedure TDevDecoderRetr.SetDecoders(const Value: TCustomDecoderCollection);
begin
  TFifoDecoder(FS_Data).Decoders := Value;
end;

{$ENDREGION 'TTelesisRetr'}

{$REGION 'USO'}

type
  TInspUcoFileRetr = class(TJvInspectorStringItem)
  public
    constructor Create(const AParent: TJvCustomInspectorItem; const AData: TJvCustomInspectorData); override;
    procedure Edit; override;
  end;

constructor TInspUcoFileRetr.Create(const AParent: TJvCustomInspectorItem; const AData: TJvCustomInspectorData);
begin
  inherited;
  Flags := Flags  + [iifEditButton];
end;

procedure TInspUcoFileRetr.Edit;
begin
  with TOpenDialog.Create(nil) do
  try
   InitialDir := Tpath.GetFullPath(ParamStr(0)) + '\Projects';
   Filter :=  'Файл бинарный (*.bin)|*.bin';
   DefaultExt := 'bin';
   Options := [ofPathMustExist,ofEnableSizing];
   if Execute(Application.Handle) then Data.AsString := FileName;
  finally
   Free;
  end;
end;
{ TUsoTetr }

constructor TUsoRetrans.Create;
begin
  inherited;
  Capacity := 2048*2;
  FFrequency := afq10;
  FKSum := 1;
end;

function TUsoRetrans.FufferDataPeriod: Double;
begin
  Result := FKSum * 6.144;
end;

function TUsoRetrans.GetCaption: string;
begin
  Result := TELESIS_STRUCURE[0].Category + ' retr' ;
end;

function TUsoRetrans.GetCategory: TSubDeviceInfo;
begin
  Result := TELESIS_STRUCURE[0];
end;

procedure TUsoRetrans.InputData(Data: Pointer; DataSize: integer);
  const
   {$J+}
     c: Integer = 0;
   {$J-}
  var
   p: PByte;
   sw: SmallInt;
begin
 p := Data;
  with RecRun do while DataSize > 0 do
   begin
    if HSync then
     begin
      Buff[Ncanal] := p^;
      Inc(Ncanal);
      if Ncanal >= 3 then
       begin
        sw := SmallInt(Swap(wrd));
        if Assigned(FFileStream) then FFileStream.WriteData(sw);
        SumDat := SumDat + sw;
        Inc(Nfq);
        if Nfq >= FKSum then
         begin
          Nfq := 0;
          FData[FbufCount] := SumDat / FKSum * 0.0625;
         { if FTestUsoData <> tudNone then
           begin
            if c >= Length(Tst_Data) then c := 0;
            if Tst_Data[c] then FData[i] := 1 else FData[i] := - 1;
            Inc(c);
           end;}
          SumDat := 0;
          inc(FbufCount);
          // синхронизация команы в низ во время паузы
         { if (FS_Data.BookMark = FS_Data.Fifo.Last + i) and FS_Data.IsBookMark then
           begin
            FS_Data.IsBookMark := False;
            Cmd := FCmd;
           end;}
          if FbufCount = Length(FData) then
           begin
            FbufCount := 0;
            FS_Data.Write(@FData[0], Length(FData));
//            TDebug.Log('ADD USO.Count  %d                 ', [FS_Data.Fifo.Count]);
            TDebug.Log('Item: %s  First: %d, Last: %d count: %d',[Iname,FS_Data.FirstIndex, FS_Data.LastIndex, FS_Data.Count]);
            try
             if Assigned(FChildSubDevice) then FChildSubDevice.InputData(@FData[0], Length(FData));
            finally
             NotifyData;
           end;
           end;
         end;
        Ncanal := 0;
        HSync := False;
        LSync := False;
       end;
     end
    else
     if LSync=False then
      begin
       if P^ = $a5 then LSync := True;
      end
     else
      begin
       if P^ = $5a then HSync := True;
      end;
    Dec(DataSize);
    Inc(p);
   end;
end;

function TUsoRetrans.RealTimeLastIndex: Integer;
begin
  Result := FS_Data.LastIndex + FbufCount;
end;

procedure TUsoRetrans.RemoveUserForm;
begin
end;

procedure TUsoRetrans.SetFileName(const Value: TOpenUsoFile);
begin
  if FFileName <> Value then
   begin
    FFileName := Value;
    if Assigned(FFileStream) then FreeAndNil(FFileStream);
    if FFileName <> '' then
     begin
      if TFile.Exists(FFileName) then
       begin
         FFileStream := TFile.OpenWrite(FFileName);
         FFileStream.seek(0, soEnd);
       end
      else 
         FFileStream := TFile.Create(FFileName);
     end;
   end;
end;

procedure TUsoRetrans.SetFrequency(const Value: TTelesisFrequency);
begin
  if FFrequency <> Value then
   begin
    FFrequency := Value;
    case FFrequency of
        afq40: FKSum := 1;
        afq20: FKSum := 1;
        afq10: FKSum := 1;
         afq5: FKSum := 2;
       afq2p5: FKSum := 4;
      afq1p25: FKSum := 8;
    end;
    Owner.PubChange;
   end;
end;
{$ENDREGION 'USO'}

{$REGION ' TOiTetr '}

{ TOiTetr }

constructor TOiRetrans.Create;
begin
  inherited;
  Capacity := 2048*8;
end;

function TOiRetrans.GetCaption: string;
begin
  if FUnicCaption <> '' then Exit(FUnicCaption);
  Result := 'Фильтр ОИ';
  if Assigned(Owner) then
   begin
    FUnicCaption := GetUniqueCaption(Result);
    Result := FUnicCaption;
    MainScreenChanged;
   end;
end;

function TOiRetrans.GetCategory: TSubDeviceInfo;
begin
  Result := TELESIS_STRUCURE[1];
end;

procedure TOiRetrans.InputData(Data: Pointer; DataSize: integer);
  const
   {$J+} j: Integer = 0; {$J-}
 var
  a: PDoubleArray;
  i, k: Integer;
  sum: Double;
begin
   a := Data;
   for i := 0 to DataSize-1 do
    begin
     Ffifo[j] := a^[i];
     j := (j+1) mod Length(Ffifo);
     sum := 0;
     for k := 0 to Length(Ffifo)-1 do sum := sum + Ffifo[k];
     FS_Data.AddData(sum / Length(Ffifo));
    end;
   TDebug.Log('Item: %s  First: %d, Last: %d count: %d',[Iname,FS_Data.FirstIndex, FS_Data.LastIndex, FS_Data.Count]);
   try
    if Assigned(FChildSubDevice) then FChildSubDevice.InputData(FS_Data.PBuf[1-DataSize], DataSize);
   finally
    NotifyData;
   end;
end;

procedure TOiRetrans.RemoveUserForm;
begin
end;

{$ENDREGION oi}

{$REGION 'FFT'}

{ TFFTRetrans }

function TFFTRetrans.ClassFifo: TBookmarkFifoDoubleClass;
begin
  Result := TfifoFFT;
end;

constructor TFFTRetrans.Create;
begin
  inherited;
  FFNch1 := 1;
  FFNch2 := 20;
  FFVch1 := 100;
  FFVch2 := 120;
  InitConst('TfftRETRForm', 'fftRETR_');
  Capacity := FFT_LEN*4;
end;

procedure TFFTRetrans.DoSetup(Sender: IAction);
begin
  inherited;
end;

function TFFTRetrans.GetCaption: string;
begin
  if FUnicCaption <> '' then Exit(FUnicCaption);
  Result := 'Фильтр Фурье';
  if Assigned(Owner) then
   begin
    FUnicCaption := GetUniqueCaption(Result);
    Result := FUnicCaption;
    MainScreenChanged;
   end;
end;

function TFFTRetrans.GetCategory: TSubDeviceInfo;
begin
  Result := TELESIS_STRUCURE[1];
end;

function TFFTRetrans.GetFFT: TfifoFFT;
begin
  Result := TfifoFFT(FS_Data);
end;

procedure TFFTRetrans.InputData(Data: Pointer; DataSize: integer);
begin
  FFT.Write(Data, DataSize);
  TDebug.Log('Item: %s  First: %d, Last: %d count: %d',[Iname, FFT.FirstIndex, FFT.LastIndex, FFT.Count]);
  FFT.ExecFFT(procedure(d: PDouble; cnt: Integer)
  begin
    try
     TDebug.Log('Item: %s  First: %d, Last: %d count: %d   FFTFirst: %d, FFTLast: %d',
     [Iname, FFT.FirstIndex, FFT.LastIndex, FFT.Count, FFT.FirstFFTIndex, FFT.LastFFTIndex]);
     if Assigned(FChildSubDevice) then FChildSubDevice.InputData(d, cnt);
    finally
     NotifyData;
    end;
  end);
end;

procedure TFFTRetrans.SetFch(const Value: Integer);
begin
  FFch := Value;
  SetupFilter;
end;

procedure TFFTRetrans.SetFchw(const Value: Integer);
begin
  FFchw := Value;
  SetupFilter;
end;

procedure TFFTRetrans.SetFNch1(const Value: Integer);
begin
  FFNch1 := Value;
  SetupFilter;
end;

procedure TFFTRetrans.SetFNch2(const Value: Integer);
begin
  FFNch2 := Value;
  SetupFilter;
end;

procedure TFFTRetrans.SetFVch1(const Value: Integer);
begin
  FFVch1 := Value;
  SetupFilter;
end;

procedure TFFTRetrans.SetFVch2(const Value: Integer);
begin
  FFVch2 := Value;
  SetupFilter;
end;

procedure TFFTRetrans.SetupFilter;
begin
  FFT.ClearFilter;
  FFT.ApplyLoFlt(FFNch1, FFNch2);
  FFT.ApplyHiFlt(FFVch1, FFVch2);
  FFT.ApplyBoundFlt(FFch, FFchw);
end;
{$ENDREGION 'FFT'}

{ TDecoderManchRetr }

//procedure TDecoderManchRetr.DoSetConst;
//begin
//  inherited;
//  SetConst(8, 16, 5, 0, Manchester2CorrCode);
//end;

initialization
  TJvCustomInspectorData.ItemRegister.Add(TJvInspectorTypeInfoRegItem.Create(TInspUcoFileRetr, TypeInfo(TOpenUsoFile)));
  RegisterClasses([TTelesisRetr, TretrData, TDevDecoderRetr, TUsoRetrans, TOiRetrans, TFFTRetrans]);
  TRegister.AddType<TTelesisRetr, IDevice>.LiveTime(ltSingletonNamed);
  TRegister.AddType<TretrData, ITelesistem_retr>.LiveTime(ltTransientNamed);
  TRegister.AddType<TUsoRetrans, ITelesistem_retr>.LiveTime(ltTransientNamed);
  TRegister.AddType<TOiRetrans, ITelesistem_retr>.LiveTime(ltTransientNamed);
  TRegister.AddType<TFFTRetrans, ITelesistem_retr>.LiveTime(ltTransientNamed);
  TRegister.AddType<TDevDecoderRetr, ITelesistem_retr>.LiveTime(ltTransientNamed);
finalization
  GContainer.RemoveModel<TOiRetrans>;
  GContainer.RemoveModel<TFFTRetrans>;
  GContainer.RemoveModel<TUsoRetrans>;
  GContainer.RemoveModel<TDevDecoderRetr>;
  GContainer.RemoveModel<TretrData>;
  GContainer.RemoveModel<TTelesisRetr>;
end.

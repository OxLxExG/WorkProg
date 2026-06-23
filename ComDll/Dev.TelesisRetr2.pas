unit Dev.TelesisRetr2;

interface

uses  tools,
      System.SysUtils,  System.Classes, System.TypInfo, Xml.XMLIntf, Math.Telesistem, RootIntf, SubDevImpl, RootImpl, IndexBuffer,
      Container, DeviceIntf, Dev.Telesistem, ExtendIntf, Actns, Dev.Telesistem.Data, Dev.Telesistem.Decoder, JDtools, Vcl.ExtCtrls,
      CFifo, MathIntf, debug_except, Fifo.FFT, Fifo.Decoder, Math.Telesistem.Custom, Vcl.Dialogs, Vcl.Forms,
      JvExControls, JvInspector, JvComponentBase,  JvResources, System.Math, AVRtypes,
      System.Bindings.Helper, System.IOUtils;

const
   TELESIS_STRUCURE: array[0..3] of TSubDeviceInfo = (
   (typ: [sdtUniqe, sdtMastExist]; Category: 'Усо'),
                                  (Category: 'Фильтры'),
   (typ: [sdtUniqe, sdtMastExist]; Category: 'Декодер'),
   (typ: [sdtUniqe, sdtMastExist]; Category: 'Данные')
   );

type

  TIndBufSubDev = class(TSubDevWithForm<TIndexBuf>)
  private
    procedure SetCapacity(const Value: Integer);
    function GetCapacity: Integer;
  protected
    function ClassFifo: TIndexBufClass; virtual;

    //    procedure Extract(); override;
//    procedure Insert(Index: Integer); override;
//    procedure OnUserRemove;  override;
//    procedure BeforeRemove(); override;

//    procedure SetChildSubDevice(const Value: TSubDev); override;
//    procedure SetParentSubDevice(const Value: TSubDev); override;
  public
    destructor Destroy; override;
    property Capacity : Integer read GetCapacity write SetCapacity;
//    property Painter: TObject read GetPainter write SetPainter;
  end;

  TOpenUsoFile = type TFileName;


  TUsoRetransCustom = class(TIndBufSubDev)
  protected
    FKSum: Integer;
    FFrequency: TTelesisFrequency;
    FFileName: TOpenUsoFile;
    FFileStream: TFileStream;
  const
     TIME_TO_USO = 24*3600/(6.144/1000);
    procedure SetFrequency(const Value: TTelesisFrequency); virtual;
    procedure SetFileName(const Value: TOpenUsoFile); virtual;
    function GetCategory: TSubDeviceInfo; override;

    function IsWork: Boolean;
  public
    constructor Create; override;
  published
    [ShowProp('Частота прибора')] property Frequency: TTelesisFrequency read FFrequency write SetFrequency default afq10;
    property FileName: TOpenUsoFile read FFileName write SetFileName;
  end;

  TUsoRetrans = class(TUsoRetransCustom, IOscDataSubDevice, IUSOData)
  private
    RecRun: TRecRun;
    FData: array[0..63] of Double;
    FbufCount: Integer;
    FRealTimeEvent: TNotifyEvent;
    FeventIndex: Integer;
    Fcmd: Byte;
  protected
    procedure Send(cmd: Byte);
    procedure RemoveUserForm; override;
    function GetCaption: string; override;
    function RealTimeLastIndex: Integer;
    function FufferDataPeriod: Double; // ms
    procedure RegEvent(index: Integer; RealTimeEvent: TNotifyEvent);
    function RunData: single; virtual;
    function KData: Double; virtual;
    function MaxCanal: Integer; virtual;
  public
    procedure InputData(Data: Pointer; DataSize: integer); override;
    [ShowProp('Послать команду')] property SendCmd: Byte read Fcmd write Send;
  published
    [ShowProp('Файл записи данных')] property FileName;
  end;

  Tuso32 =  class(TUsoRetrans)
  protected
    function GetCaption: string; override;
    function RunData: single; override;
    function MaxCanal: Integer; override;
  end;

  TUsoPleer = class(TUsoRetransCustom, IOscDataSubDevice, IPleer)
  private
    FTData: Double;
    FMaximum: Int64;
    FData: array[0..63]of double;
    FDataCnt: Integer;
    FDsum: Double;
    FDsumCnt: Integer;
    FTimer: TTimer;
    procedure OnTime(Sender: TObject);
  protected
    procedure SetPosition(const Value: Int64);
    function GetMaximum: Int64;
    function GetPosition: Int64;
    procedure SetFileName(const Value: TOpenUsoFile); override;
    function GetCaption: string; override;
    function Step(count: Cardinal): Cardinal;
    function Stream: TFileStream;
  public
    constructor Create; override;
    destructor Destroy; override;
    procedure InputData(Data: Pointer; DataSize: integer); override;
    [DynamicAction('Показать окно Плеера', '<I>', 155, '0:Телесистема.<I>', 'Показать окно Плеера')]
    procedure DoSetup(Sender: IAction); override;
    property Maximum: Int64 read GetMaximum;
    property Position: Int64 read GetPosition write SetPosition;
  published
    [ShowProp('Период дискретизации')] property TData: Double read FTData write FTData;
    [ShowProp('Файл данных')] property FileName;
  end;

  TOiRetrans = class(TIndBufSubDev, IOscDataSubDevice)
   private
    j: Integer;
    { TODO : только 8 бит сделать переменную}
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

  TFFTRetrans = class(TIndBufSubDev)//, IOscDataSubDevice)
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
    function ClassFifo: TIndexBufClass; override;
    function GetCategory: TSubDeviceInfo; override;
    function GetCaption: string; override;
    procedure SetupFilter;
    procedure Extract(); override;
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

  TOneWareData = class(TCustomTeleData)
  private
    loCod :Integer;
    loQua :Double;

    type
     CodeDat = (cdGKLo, cdGK, cdOtkLo, cdOtkl, cdZenLo, cdZen, adAziLo, adAzi);
  protected
    procedure InputData(Data: Pointer; DataSize: integer); override;
  public
    [DynamicAction('Показать окно Отклонителя', '<I>', 55, '0:Телесистема.<I>', 'Показать окно Отклонителя')]
    procedure DoSetup(Sender: IAction); override;
    function GetCaption: string; override;
    function GetMetaData: IXMLInfo; override;
  end;

//  TDecoderManchRetr = class(TCustomDecoderFourier)
//  protected
//    procedure DoSetConst; override;
//  end;

  TDevDecoderRetr = class(TIndBufSubDev, ITelesistem_retr)
  private
    FS_Decoder: TCustomDecoderWrap;
    function GetDecoders: TCustomDecoderCollection;
    procedure SetDecoders(const Value: TCustomDecoderCollection);
    procedure SetS_Decoder(const Value: TCustomDecoderWrap);
    procedure OnDecoder(Sender: TObject);
  protected
    procedure DefineProperties(Filer: TFiler); override;
    function ClassFifo: TIndexBufClass; override;
    function GetCategory: TSubDeviceInfo; override;
    function GetCaption: string; override;
    function GetUSOData(out USOData: IUSOData): Boolean;
    procedure CreateDecoders; virtual;
    procedure Loaded; override;
    function FifoDecoder: TCFifoDecoder;
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

  TDevDecoderRM = class(TDevDecoderRetr)
  protected
    function GetCaption: string; override;
    procedure Loaded; override;
    procedure CreateDecoders; override;
  public
    [DynamicAction('Показать окно Декорера', '<I>', 55, '0:Телесистема.<I>', 'Показать окно Декорера')]
    procedure DoSetup(Sender: IAction); override;
   end;


  TDevDecoderRetrFM = class(TDevDecoderRetr)
  protected
    function GetCaption: string; override;
    procedure Loaded; override;
    procedure CreateDecoders; override;
  public
    [DynamicAction('Показать окно Декорера', '<I>', 55, '0:Телесистема.<I>', 'Показать окно Декорера')]
    procedure DoSetup(Sender: IAction); override;
   end;

  TTelesisRetr = class(TTelesistem, INotifyAfterAdd)
  protected
    function IsFileUso: Boolean; override;
    function GetService: PTypeInfo; override;
    function GetStructure: TArray<TSubDeviceInfo>; override;
    procedure AfterAdd(); virtual;
    procedure BeforeRemove(); override;
  public
    [DynamicAction('Установки телесистемы', '<I>', 52, '0:Телесистема.<I>', 'Установки телесистемы')]
    procedure DoSetup(Sender: IAction); override;
    [DynamicAction('Показать окно осцилограмм', '<I>', 152, '0:Телесистема.<I>', 'Показать окно осцилограмм')]
    procedure DoShowOscForm(Sender: IAction); virtual;
  end;
  TTelesis1Ware = class(TTelesisRetr)
  protected
    procedure AfterAdd(); override;
    function GetService: PTypeInfo; override;
  public
    [DynamicAction('Установки телесистемы', '<I>', 52, '0:Телесистема.<I>', 'Установки телесистемы')]
    procedure DoSetup(Sender: IAction); override;
    [DynamicAction('Показать окно осцилограмм', '<I>', 152, '0:Телесистема.<I>', 'Показать окно осцилограмм')]
    procedure DoShowOscForm(Sender: IAction);
  end;

implementation

function IsDataFifo(Obj: TObject): Boolean;
begin
  Result := obj is TSubDev<TIndexFifoDouble>;
end;

{$REGION 'TDoubleSubDev '}
{ TDoubleSubDev }

function TIndBufSubDev.ClassFifo: TIndexBufClass;
begin
  Result := TIndexFifoDouble;
end;

destructor TIndBufSubDev.Destroy;
begin
  if Assigned(FS_Data) then FreeAndNil(FS_Data);
  inherited;
end;

//procedure TIndBufSubDev.Extract;
//begin
//  FS_Data.Extract(nil);
//  inherited Extract;
//end;

function TIndBufSubDev.GetCapacity: Integer;
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

//procedure TIndBufSubDev.Insert(Index: Integer);
//begin
//  inherited;
//  if Index > 0 then
//   begin
//    if IsDataFifo(Collection.Items[Index-1]) then TSubDev<TBookmarkFifoDouble>(Collection.Items[Index-1]).FS_Data.Insert(FS_Data)
//   end
//  else if Collection.Count > 1 then
//   begin
//    if IsDataFifo(Collection.Items[1]) then TSubDev<TBookmarkFifoDouble>(Collection.Items[1]).FS_Data.Insert(FS_Data, nil, True)
//   end
//  else
//   begin
//    FS_Data.FirstIndex := 1;
//    FS_Data.ChildFifo := nil;
//    FS_Data.ParentFifo := nil;
//   end;
//end;

procedure TIndBufSubDev.SetCapacity(const Value: Integer);
begin
  if not Assigned(FS_Data) then
   begin
    FS_Data := ClassFifo.Create(self, Value);
   // FS_Data.Name := Caption;
   end;
  FS_Data.Capacity := Value;
end;

//procedure TIndBufSubDev.SetChildSubDevice(const Value: TSubDev);
//begin
//  inherited;
//  if Assigned(Value) and IsDataFifo(Value) then FS_Data.ChildFifo := TSubDev<TBookmarkFifoDouble>(Value).FS_Data;
//end;

//procedure TDoubleSubDev.SetPainter(const Value: TObject);
//begin
//  FPainter := Value;
//end;

//procedure TIndBufSubDev.SetParentSubDevice(const Value: TSubDev);
//begin
//  inherited;
//  if Assigned(Value) and IsDataFifo(Value) then FS_Data.ParentFifo := TSubDev<TBookmarkFifoDouble>(Value).FS_Data;
//end;
{$ENDREGION 'TDoubleSubDev '}

{$REGION 'TTelesisRetr'}

{ TTelesisRetr }

procedure TTelesisRetr.AfterAdd;
begin
  AddOrReplase(typeInfo(TUsoRetransCustom));
//  AddOrReplase(typeInfo(TFltBPF));
  AddOrReplase(typeInfo(TDevDecoderRetr));
  AddOrReplase(typeInfo(TretrData));
  (Self as IBind).Notify('S_PublishedChanged');
end;

procedure TTelesisRetr.BeforeRemove;
 var
  s: string;
  F: IForm;
begin
  s := 'OscForm_' + Name;
  F := (Gcontainer as IformEnum).Get(s);
  if Assigned(F) then
   begin
    (Gcontainer as IformEnum).Remove(F);
    ((Gcontainer as IformEnum) as IStorable).Save;
   end;
  inherited;
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


function TTelesisRetr.IsFileUso: Boolean;
begin
  Result := (FSubDevs.Count>0) and (TSubDev(FSubDevs.Items[0]) is TUsoPleer);
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

function TDevDecoderRetr.ClassFifo: TIndexBufClass;
begin
  Result := TCFifoDecoder;
end;

constructor TDevDecoderRetr.Create;
begin
  FS_Data := ClassFifo.Create(self, 4096);
  inherited;
  if not IsLoaded then
   begin
    CreateDecoders;
    Loaded;
   end;
  InitConst('TDecoderRETRForm', 'DecoderRETR_');
end;

procedure TDevDecoderRetr.CreateDecoders;
begin
  TDecoderManchRetr.Create(Decoders);
  TWindowDecoder.Create(Decoders);
  TWindowDecoder.Create(Decoders);
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
     TCustomDecoder(Decoders.Items[i]).Buf := FifoDecoder;// as TIndexBufDouble;
     TCustomDecoder(Decoders.Items[i]).OnState := OnDecoder;
     TCustomDecoder(Decoders.Items[i]).GetUSOData := GetUSOData;
    end;

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

function TDevDecoderRetr.FifoDecoder: TCFifoDecoder;
begin
  Result := FS_Data as TCFifoDecoder;
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
  Result := FifoDecoder.Decoders;
end;

function TDevDecoderRetr.GetUSOData(out USOData: IUSOData): Boolean;
begin
  Result := Supports(Owner.SubDevices[0], IUSOData, USOData)
end;

procedure TDevDecoderRetr.InputData(Data: Pointer; DataSize: integer);
begin
  FS_Data.Write(Data, DataSize);
  FifoDecoder.ExecDecoders;
end;

procedure TDevDecoderRetr.OnDecoder(Sender: TObject);
 function GetIndex:Integer;
  var
   i: Integer;
 begin
   Result := -1;
   for i := 0 to Decoders.Count-1 do if Sender = Decoders.Items[i] then Exit(i);
 end;
begin
  S_Decoder := Sender as TCustomDecoder;
  if Assigned(FChildSubDevice) then FChildSubDevice.InputData(Sender, GetIndex);
end;

procedure TDevDecoderRetr.SetS_Decoder(const Value: TCustomDecoderWrap);
begin
  FS_Decoder := Value;
  TBindings.Notify(Self, 'S_Decoder');
end;

procedure TDevDecoderRetr.SetDecoders(const Value: TCustomDecoderCollection);
begin
  FifoDecoder.Decoders := Value;
end;

{ TDevDecoderRetrFM }

procedure TDevDecoderRetrFM.CreateDecoders;
begin
  TDecoderFMRetr.Create(Decoders);
  TWindowDecoderFM.Create(Decoders);
  TWindowDecoderFM.Create(Decoders);
end;

procedure TDevDecoderRetrFM.DoSetup(Sender: IAction);
begin
  inherited;
end;

function TDevDecoderRetrFM.GetCaption: string;
begin
  Result := 'ФМ'
end;

procedure TDevDecoderRetrFM.Loaded;
begin
  inherited;
  (Decoders.Items[2] as TWindowDecoder).SPBeginBit := (128+16*6)*2; //'синхронный декодер(ретранслятор)';
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

constructor TUsoRetransCustom.Create;
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

function TUsoRetransCustom.GetCategory: TSubDeviceInfo;
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
   sw: Single;
   e: TNotifyEvent;
begin
 p := Data;
  with RecRun do while DataSize > 0 do
   begin
    if HSync then
     begin
      Buff[Ncanal] := p^;
      Inc(Ncanal);
      if Ncanal >= MaxCanal then
       begin
        sw := RunData;//SmallInt(Swap(wrd));
        if Assigned(FFileStream) and IsWork then FFileStream.WriteData(sw);
        SumDat := SumDat + sw;
        Inc(Nfq);
        if Nfq >= FKSum then
         begin
          Nfq := 0;
          FData[FbufCount] := SumDat / FKSum * KData;
          SumDat := 0;
          inc(FbufCount);
          // синхронизация команы
          if Assigned(FRealTimeEvent) and (RealTimeLastIndex = FeventIndex) then
           begin
            e := FRealTimeEvent;
            FRealTimeEvent := nil;
            e(self);
           end;
          if FbufCount = Length(FData) then
           begin
            FbufCount := 0;
            FS_Data.Write(@FData[0], Length(FData));
//            TDebug.Log('ADD USO.Count  %d                 ', [FS_Data.Fifo.Count]);
           // TDebug.Log('Item: %s  First: %d, Last: %d count: %d',[Iname,FS_Data.FirstIndex, FS_Data.LastIndex, FS_Data.Count]);
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

function TUsoRetrans.KData: Double;
begin
  Result := 0.0625
end;

function TUsoRetrans.MaxCanal: Integer;
begin
  Result := 3;
end;

function TUsoRetransCustom.IsWork: Boolean;
 var
  opt: IProjectOptions;
  st: TDateTime;
begin
  Result := False;
  if Supports(GContainer, IProjectOptions, opt) then
   begin
    st := opt.DelayStart;
    if st > 0 then Result := st - Now <= 0;
    if not Result and Assigned(FFileStream) then  FFileStream.size := 0;
   end;
end;

function TUsoRetrans.RealTimeLastIndex: Integer;
begin
  Result := FS_Data.LastIndex + FbufCount;
end;

procedure TUsoRetrans.RegEvent(index: Integer; RealTimeEvent: TNotifyEvent);
begin
  FRealTimeEvent := RealTimeEvent;
  FeventIndex := index;
end;

procedure TUsoRetrans.RemoveUserForm;
begin
end;


function TUsoRetrans.RunData: single;
 var
  sw: SmallInt;
begin
  sw := SmallInt(Swap(RecRun.wrd));
  Result := sw;
end;

procedure TUsoRetrans.Send(cmd: Byte);
begin
  (TTelesistem(Owner) as ITelesisCMD).SendCmd(cmd);
  Fcmd := cmd mod 12;
end;

procedure TUsoRetransCustom.SetFileName(const Value: TOpenUsoFile);
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

procedure TUsoRetransCustom.SetFrequency(const Value: TTelesisFrequency);
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

{ TUsoPleer }

constructor TUsoPleer.Create;
begin
  inherited;
  InitConst('TPLeerRETRForm', 'PLeerRETR_');
  FTimer := TTimer.Create(nil);
  FTimer.OnTimer := OnTime;
end;

destructor TUsoPleer.Destroy;
begin
  if Assigned(FFileStream) then FFileStream.Free;
  FTimer.free;
  inherited;
end;

procedure TUsoPleer.DoSetup(Sender: IAction);
begin
  inherited;
end;

function TUsoPleer.GetCaption: string;
begin
  Result := 'File Pleer'
end;

function TUsoPleer.GetMaximum: Int64;
begin
  Result := FMaximum
end;

function TUsoPleer.GetPosition: Int64;
begin
  if Assigned(FFileStream) then Result := FFileStream.Position else Result := 0;
end;

procedure TUsoPleer.InputData(Data: Pointer; DataSize: integer);
begin

end;

procedure TUsoPleer.OnTime(Sender: TObject);
begin
  NotifyData;
end;

procedure TUsoPleer.SetPosition(const Value: Int64);
begin
  if Assigned(FFileStream) then FFileStream.Position := Value;
  FDataCnt := 0;
  FDsum := 0;
  FDsumCnt := 0;
end;

procedure TUsoPleer.SetFileName(const Value: TOpenUsoFile);
begin
  if FFileName <> Value then
   begin
    FFileName := Value;
    if Assigned(FFileStream) then FreeAndNil(FFileStream);
    if FFileName <> '' then
     begin
      if TFile.Exists(FFileName) then
       begin
        FFileStream := TFile.OpenRead(FFileName);
        FFileStream.seek(0, soBeginning);
        FMaximum := FFileStream.Size;
       end
      else raise Exception.Createfmt('нет файля %d', [FFileName]);
     end;
   end;
end;

function TUsoPleer.Step(count: Cardinal): Cardinal;
 var
  i, n, needread: Cardinal;
  a: TArray<Single>;
begin
  if not Assigned(FFileStream) then Exit(0);
  needread := count * SizeOf(Single) * Cardinal(FKsum);
  SetLength(a, needread);
  Result := FFileStream.Read(a[0], needread);
  n := Result div SizeOf(Single);
  for i := 0 to n-1 do
   begin
    FDsum := FDsum + a[i];
    inc(FDsumCnt);
    if FDsumCnt >= FKsum then
     begin
      FData[FDataCnt] := FDsum/FKsum * 0.0625;
      FDsumCnt := 0;
      FDsum := 0;
      Inc(FDataCnt);
      if FDataCnt = Length(FData) then
       try
        FDataCnt := 0;
        FS_Data.Write(@FData[0], Length(FData));
        if Assigned(FChildSubDevice) then FChildSubDevice.InputData(@FData[0], Length(FData));
       finally
        NotifyData;
      end;
     end;
   end;
end;

function TUsoPleer.Stream: TFileStream;
begin
  Result := FFileStream
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
 var
  a: PDoubleArray;
  i, k: Integer;
  sum: Double;
  Res: TIndexArray;
begin
   a := PDoubleArray(Data);
   for i := 0 to DataSize-1 do
    begin
     Ffifo[j] := a[i];
     j := (j+1) mod Length(Ffifo);
     sum := 0;
     for k := 0 to Length(Ffifo)-1 do sum := sum + Ffifo[k];
     sum := sum / Length(Ffifo);
     FS_Data.Write(@sum, 1);
    end;
   //TDebug.Log('Item: %s  First: %d, Last: %d count: %d',[Iname,FS_Data.FirstIndex, FS_Data.LastIndex, FS_Data.Count]);
   try
    if Assigned(FChildSubDevice) then
     begin
      res := TIndexBufDouble(FS_Data).Read(FS_Data.LastIndex-DataSize+1, DataSize);
      FChildSubDevice.InputData(@res.Data[0], DataSize);
     end;
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

function TFFTRetrans.ClassFifo: TIndexBufClass;
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

procedure TFFTRetrans.Extract;
 var
  leak: TIndexArray;
begin
    try
//     TDebug.Log('Item: %s  First: %d, Last: %d count: %d   FFTFirst: %d, FFTLast: %d',
//     [Iname, FFT.FirstIndex, FFT.LastIndex, FFT.Count, FFT.FirstFFTIndex, FFT.LastFFTIndex]);
     if Assigned(FChildSubDevice) then
      begin
       leak := FFT.GetLeakData;
       FChildSubDevice.InputData(@leak.Data[0], leak.Len);
      end;
    finally
     NotifyData;
    end;
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
  //TDebug.Log('Item: %s  First: %d, Last: %d count: %d',[Iname, FFT.FirstIndex, FFT.LastIndex, FFT.Count]);
  FFT.ExecFFT(procedure(d: PDouble; cnt: Integer)
  begin
    try
    // TDebug.Log('Item: %s  First: %d, Last: %d count: %d   FFTFirst: %d, FFTLast: %d',
     //[Iname, FFT.FirstIndex, FFT.LastIndex, FFT.Count, FFT.FirstFFTIndex, FFT.LastFFTIndex]);
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

{ TDevDecoderRM }

procedure TDevDecoderRM.Loaded;
begin
  TCustomDecoder(Decoders.Items[0]).Text := 'RM декодер';
  TCustomDecoder(Decoders.Items[0]).Buf := FifoDecoder;// as TIndexBufDouble;
  TCustomDecoder(Decoders.Items[0]).OnState := OnDecoder;
  TCustomDecoder(Decoders.Items[0]).GetUSOData := GetUSOData;
end;

procedure TDevDecoderRM.CreateDecoders;
begin
  TCustomDecoder.Create(Decoders);
end;

procedure TDevDecoderRM.DoSetup(Sender: IAction);
begin
  inherited;
end;

function TDevDecoderRM.GetCaption: string;
begin
  Result := 'RM'
end;


{ T1wareData }

procedure TOneWareData.DoSetup(Sender: IAction);
begin
  inherited;
end;

function TOneWareData.GetCaption: string;
begin
 Result := '1 ware test tele';
end;

function TOneWareData.GetMetaData: IXMLInfo;
 var
  GDoc: IXMLDocument;
begin
  FFileName := ExtractFilePath(ParamStr(0)) + 'Devices\tst_telesis3.hxml';
  GDoc := NewXDocument();
  GDoc.LoadFromFile(FileName);
  Result := GDoc.DocumentElement;
end;

procedure TOneWareData.InputData(Data: Pointer; DataSize: integer);
 var
  v: Variant;
  deltaOtk: Double;
  function cor360(a: Double): double;
  begin
    if a < 0 then Result := a + 360
    else if a >=360 then Result := a - 360
    else Result := a
  end;
begin
  // test for decoder
  if (DataSize <> 0) or not TryGetRoot(v,1002) then Exit;
  with TCustomDecoder(Data) do
   begin
  case State of
    csFindSP: ;
    csSP: with SPData  do
     begin
      v.СП.Уход_тактов.DEV.VALUE := 0;
      v.СП.Амплитуда.DEV.VALUE := SimpleRoundTo(sp.dat, -1);
      v.СП.Фаза.DEV.VALUE := Faza;
      v.СП.Q_СП.DEV.VALUE := Round(Quality);
     end;
    csCheckSP: with SPData do
     begin
      v.СП.Уход_тактов.DEV.VALUE := DTakt;
      v.СП.Амплитуда.DEV.VALUE := SimpleRoundTo(sp.dat, -1);
      v.СП.Фаза.DEV.VALUE := FazaCheck;
      v.СП.Q_СП.DEV.VALUE := Round(Quality);
     end;
    csCode: with Codes do
     begin
      case CodeDat(Codes.Count-1) of
        cdGK:
         begin
          v.ГК.гк.DEV.VALUE :=  Curr.Code shl 5 or loCod;
          v.ГК.Q_гк.DEV.VALUE := min(Curr.Quality, loQua);
          v.ГК.гк.CLC.VALUE := v.ГК.гк.DEV.VALUE;
          SetPrbData(dtGK, v.ГК.гк.CLC.VALUE, v.ГК.Q_гк.DEV.VALUE);
         end;
        cdOtkl:
         begin
           v.Inclin.отклонитель.DEV.VALUE := Curr.Code shl 5 or loCod;
           v.Inclin.Q_отклонитель.DEV.VALUE := min(Curr.Quality, loQua);
           v.Inclin.отклонитель.CLC.VALUE := (v.Inclin.отклонитель.DEV.VALUE+0.0025)/2.844444444444;
           SetPrbData(dtOtklonitel, v.Inclin.отклонитель.CLC.VALUE, v.Inclin.Q_отклонитель.DEV.VALUE);
         end;
        cdZen:
         begin
           v.Inclin.зенит.DEV.VALUE := Curr.Code shl 5 or loCod;
           v.Inclin.Q_зенит.DEV.VALUE := min(Curr.Quality, loQua);
           v.Inclin.зенит.CLC.VALUE := (v.Inclin.зенит.DEV.VALUE+0.0025)/3.55555555556;
           SetPrbData(dtZenit, v.Inclin.зенит.CLC.VALUE, v.Inclin.Q_зенит.DEV.VALUE);
         end;
        adAzi:
         begin
           v.Inclin.азимут.DEV.VALUE := Curr.Code shl 5 or loCod;
           v.Inclin.Q_азимут.DEV.VALUE := min(Curr.Quality, loQua);
           v.Inclin.азимут.CLC.VALUE := (v.Inclin.азимут.DEV.VALUE+0.0025)/2.844444444444;
           SetPrbData(dtAzimut, v.Inclin.азимут.CLC.VALUE, v.Inclin.Q_азимут.DEV.VALUE);
         end;
        else
         loCod := Curr.Code;
         loQua := Curr.Quality;
      end;
      TTelesistem(owner).CheckWorkData;
      TTelesistem(owner).Notify('S_WorkEventInfo');
     end;
  end;
   end;
end;

{ TTelesis1Ware }

procedure TTelesis1Ware.AfterAdd;
begin
  AddOrReplase(typeInfo(TUsoRetrans));
//  AddOrReplase(typeInfo(TFltBPF));
  AddOrReplase(typeInfo(TDevDecoderRM));
  AddOrReplase(typeInfo(TOneWareData));
  (Self as IBind).Notify('S_PublishedChanged');
end;

procedure TTelesis1Ware.DoSetup(Sender: IAction);
begin
  inherited;
end;

procedure TTelesis1Ware.DoShowOscForm(Sender: IAction);
begin
  inherited;
end;

function TTelesis1Ware.GetService: PTypeInfo;
begin
  Result := TypeInfo(ITelesistem_1ware);
end;

{ Tuso32 }

function Tuso32.GetCaption: string;
begin
  Result := TELESIS_STRUCURE[0].Category + ' USO32' ;
end;

function Tuso32.MaxCanal: Integer;
begin
  Result := 4;
end;

function Tuso32.RunData: single;
begin
  Result := RecRun.int;
end;

initialization
  TJvCustomInspectorData.ItemRegister.Add(TJvInspectorTypeInfoRegItem.Create(TInspUcoFileRetr, TypeInfo(TOpenUsoFile)));
  RegisterClasses([TTelesisRetr, TretrData, TOneWareData, TDevDecoderRetr,TDevDecoderRetrFM, TDevDecoderRM,
  TTelesis1Ware, TUsoRetrans, Tuso32, TUsoPleer, TOiRetrans, TFFTRetrans]);
  TRegister.AddType<TTelesisRetr, IDevice>.LiveTime(ltSingletonNamed);
  TRegister.AddType<TTelesis1Ware, IDevice>.LiveTime(ltSingletonNamed);
  TRegister.AddType<TretrData, ITelesistem_retr>.LiveTime(ltTransientNamed);
  TRegister.AddType<TOneWareData, ITelesistem_1ware>.LiveTime(ltTransientNamed);
  TRegister.AddType<TUsoRetrans, ITelesistem_retr, ITelesistem_1ware>.LiveTime(ltTransientNamed);
  TRegister.AddType<TUso32, ITelesistem_retr, ITelesistem_1ware>.LiveTime(ltTransientNamed);
  TRegister.AddType<TUsoPleer, ITelesistem_retr, ITelesistem_1ware>.LiveTime(ltTransientNamed);
  TRegister.AddType<TOiRetrans, ITelesistem_retr, ITelesistem_1ware>.LiveTime(ltTransientNamed);
  TRegister.AddType<TFFTRetrans, ITelesistem_retr, ITelesistem_1ware>.LiveTime(ltTransientNamed);
  TRegister.AddType<TDevDecoderRetr, ITelesistem_retr>.LiveTime(ltTransientNamed);
  TRegister.AddType<TDevDecoderRetrFM, ITelesistem_retr>.LiveTime(ltTransientNamed);
  TRegister.AddType<TDevDecoderRM, ITelesistem_retr, ITelesistem_1ware>.LiveTime(ltTransientNamed);
finalization
  GContainer.RemoveModel<TTelesis1Ware>;
  GContainer.RemoveModel<TOiRetrans>;
  GContainer.RemoveModel<TFFTRetrans>;
  GContainer.RemoveModel<TUsoRetrans>;
  GContainer.RemoveModel<TUso32>;
  GContainer.RemoveModel<TUsoPleer>;
  GContainer.RemoveModel<TDevDecoderRM>;
  GContainer.RemoveModel<TDevDecoderRetrFM>;
  GContainer.RemoveModel<TDevDecoderRetr>;
  GContainer.RemoveModel<TretrData>;
  GContainer.RemoveModel<TOneWareData>;
  GContainer.RemoveModel<TTelesisRetr>;
end.

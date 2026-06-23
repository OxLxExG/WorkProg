unit Dev.Telesistem;

interface

uses JDtools,
     System.SysUtils,  System.Classes, System.TypInfo, System.Rtti, Fibonach, MathIntf, System.Math, Dev.Telesistem.Decoder,
     Actns, DeviceIntf, AbstractDev, debug_except, ExtendIntf, Container, PluginAPI, RootImpl, RootIntf, SubDevImpl, tools,
     Math.Telesistem, System.IOUtils, Vcl.Graphics,  System.Types, Parser,   Xml.XMLIntf,
     JvExControls, JvInspector, JvComponentBase,  JvResources,
     Vcl.ExtCtrls, Vcl.Dialogs, Vcl.Forms;

const
//   TELESIS_USO: TSubDeviceInfo = (typ: [sdtUniqe, sdtMastExist]; Category: 'Усо');
//   TELESIS_FLT: TSubDeviceInfo = (Category: 'Фильтры');
//   TELESIS_DECODER: TSubDeviceInfo = (typ: [sdtUniqe, sdtMastExist]; Category: 'Декодер');

   TELESIS_STRUCURE: array[0..5] of TSubDeviceInfo = (
   (typ: [sdtUniqe, sdtMastExist]; Category: 'Усо'),
                                  (Category: 'Фильтры'),
   (typ: [sdtUniqe, sdtMastExist]; Category: 'Коррелятор'),
                                  (Category: 'Фильтры-2'),
   (typ: [sdtUniqe, sdtMastExist]; Category: 'Декодер'),
   (typ: [sdtUniqe, sdtMastExist]; Category: 'Данные')
   );

type
  TTelesistem = class;
  TProtocolTelesis = class(TAbstractProtocol)
  protected
    Ftelesis: TTelesistem;
    procedure EventRxTimeOut(Sender : TAbstractConnectIO); override;
    procedure EventRxChar(Sender : TAbstractConnectIO); override;
    procedure TxChar(Sender : TAbstractConnectIO; Data: Pointer; var Cnt: Integer; maxsend: Integer = $200); override;
  public
    constructor Create(telesis: TTelesistem);
  end;

  TTelesistem = class(TRootDevice, IDataDevice, ITelesisCMD)
  private
    procedure Start(AIConnectIO: IConnectIO);
    procedure Stop(AIConnectIO: IConnectIO);
    procedure BindPortStstus(isLost: Boolean);
  protected
    FlagLostPort: Boolean;
    function IsFileUso: Boolean; virtual;
    procedure SendCmd(Cmd: Byte);
    procedure SetConnect(AIConnectIO: IConnectIO); override;
    function GetService: PTypeInfo; override;
    function GetStructure: TArray<TSubDeviceInfo>; override;
    procedure Loaded; override;
    function CanClose: Boolean; override;
    procedure BeforeRemove(); override;

    procedure ReadWork(ev: TWorkEvent; StdOnly: Boolean = false);
  public
    procedure InitMetaData(ev: TInfoEvent);
    procedure RemoveMetaData;
    procedure ExecMetrology;
    procedure CheckWorkData;
    procedure SaveLogData;

    procedure CheckConnect(); override;
    [DynamicAction('Установки телесистемы <I> ', '<I>', 52, '0:Телесистема', 'Установки телесистемы')]
    procedure DoSetup(Sender: IAction); override;
  end;

   [EnumCaptions('данные усо, Фибоначи, рид мюллер, FSK, FibonachCorr,  FSK2, Retr TST')]
   TTestUsoData = (tudNone, tudFibonach, tudRMCod, tudFSK, tudFibonachCorr,  tudFSK2, tudRetrTST);

   [EnumCaptions('40 Гц, 20 Гц, 10 Гц, 5 Гц, 2.5 Гц, 1.25 Гц')]
   TTelesisFrequency = (afq40, afq20, afq10, afq5, afq2p5, afq1p25);
    TRecRun = record
       LSync, HSync: Boolean;
       SumDat: Double;
       NCanal: Integer;
       Nfq: Integer;
       case integer of
        0: (Buff: array[0..3] of Byte);
        1: (Wrd: Word);
        2: (int: Integer);
     end;

  const
    USO_LEN = 64;
    FFT_LEN = 1024;
    FFT_OVERSAMP = FFT_LEN div 4;

    FFT_SAMPLES = FFT_LEN - FFT_OVERSAMP*2;// FFT_LEN div 2;
    FFT_AMP_LEN = FFT_LEN div 2;

type
  TUsoRoot = class(TSubDevWithForm<TUsoData>, ITelesistem)
  private
    FFrequency: TTelesisFrequency;
    procedure SetFrequency(const Value: TTelesisFrequency);
  protected
    FFileStream: TFileStream;
    FKSum: Integer;
    FData: TArray<Double>;
    function GetCategory: TSubDeviceInfo; override;
  public
    procedure DeleteData(DataSize: integer); override;
    constructor Create; override;
    destructor Destroy; override;
  published
    [ShowProp('Частота прибора')] property Frequency: TTelesisFrequency read FFrequency write SetFrequency default afq10;
  end;

  TUso1 = class(TUsoRoot, ISetBookMark)
  private
    RecRun: TRecRun;
    Tst_Data: TArray<Boolean>;
    FTestUsoData: TTestUsoData;
    FWriteToFile: Boolean;
    FCmd: Byte;
    procedure SetTestUsoData(const Value: TTestUsoData);
    procedure SetWriteToFile(const Value: Boolean);
    procedure SetCmd(const Value: Byte);
  protected
    function GetCaption: string; override;
    procedure SetBookMark(BookMark: LongWord);
  public
    procedure InputData(Data: Pointer; DataSize: integer); override;
    [DynamicAction('Показать осцилограмму усо <I> ', '<I>', 52, '0:Телесистема.<I>', 'Показать осцилограмму усо')]
    procedure DoSetup(Sender: IAction); override;
    [ShowProp('послать команду в УСО')] property Cmd: Byte read FCmd write SetCmd;
  published
    [ShowProp('Тестовые данные')] property TestUsoData: TTestUsoData read FTestUsoData write SetTestUsoData default tudNone;
    [ShowProp('Вести запись в файл')] property WriteToFile: Boolean read FWriteToFile write SetWriteToFile default False;
  end;

  TusoFile = class(TUsoRoot)
  public
   type
//    TUsoFileName = string;
    TPosition = type Int64;
  private
    FTimer: TTimer;
    FSpeed: Integer;
    FPosition: TPosition;
    FUsoFileName: TFileName;
    FC_Pause: Boolean;
    procedure SetSpeed(const Value: Integer);
    procedure OnTimer(Sender: TObject);
    procedure SetPosition(const Value: TPosition);
    procedure SetUsoFileName(const Value: TFileName);
    procedure SetC_Pause(const Value: Boolean);
  protected
    function GetCaption: string; override;
  public
    constructor Create; override;
    destructor Destroy; override;
    procedure InputData(Data: Pointer; DataSize: integer); override;
    [DynamicAction('Показать осцилограмму усо <I> ', '<I>', 52, '0:Телесистема.<I>', 'Показать осцилограмму усо')]
    procedure DoSetup(Sender: IAction); override;
    property C_Pause: Boolean read FC_Pause write SetC_Pause;
  published
    [ShowProp('Скорость воспроизведения')] property Speed: Integer read FSpeed write SetSpeed default 100;
    [ShowProp('Позиция')] property Position: TPosition read FPosition write SetPosition default 0;
    [ShowProp('Файл')] property UsoFileName: TFileName read FUsoFileName write SetUsoFileName;
  end;

   TFltBPF = class(TSubDevWithForm<TFFTData>, ITelesistem)
   private
     FDataIn, FDataOut, FFData, FFDataFlt, FltCoeff: TArray<Double>;
     FFourier: IFourier;
     FDataCnt: Integer;
     FFVch2: Integer;
     FFVch1: Integer;
     FFNch2: Integer;
     FFNch1: Integer;
     FFchw: Integer;
     FFch: Integer;
     procedure SetFNch1(const Value: Integer);
     procedure SetFNch2(const Value: Integer);
     procedure SetFVch1(const Value: Integer);
     procedure SetFVch2(const Value: Integer);
     procedure SetupFilter;
     procedure SetFch(const Value: Integer);
     procedure SetFchw(const Value: Integer);
   protected
     procedure FPCH(fq, width: Integer);
     procedure FBCH(from, too: Integer);
     procedure FNCH(from, too: Integer);
     procedure DoOutputData(Data: Pointer; DataSize: integer); virtual;
     function GetCategory: TSubDeviceInfo; override;
     function GetCaption: string; override;
     procedure OnUserRemove; override;
   public
     procedure DeleteData(DataSize: integer); override;
     procedure InputData(Data: Pointer; DataSize: integer); override;
     constructor Create; override;
     [DynamicAction('Показать спектр <I> ', '<I>', 52, '0:Телесистема.<I>', 'спектр')]
     procedure DoSetup(Sender: IAction); override;
  published
    [ShowProp('ФНЧ 1')] property FNch1: Integer read FFNch1 write SetFNch1;
    [ShowProp('ФНЧ 2')] property FNch2: Integer read FFNch2 write SetFNch2;
    [ShowProp('ФВЧ 1')] property FVch1: Integer read FFVch1 write SetFVch1;
    [ShowProp('ФВЧ 2')] property FVch2: Integer read FFVch2 write SetFVch2;
    [ShowProp('ФЧ')]    property Fch: Integer read FFch write SetFch;
    [ShowProp('ФЧ ширина')] property FVchw: Integer read FFchw write SetFchw;
   end;

   TbitFlt = class(TSubDevWithForm<TUsoData>, ITelesistem)
   private
     Ffifo: array [0..7] of Double;
   protected
     function GetCaption: string; override;
     function GetCategory: TSubDeviceInfo; override;
   public
     procedure InputData(Data: Pointer; DataSize: integer); override;
     constructor Create; override;
     [DynamicAction('Показать осцилограмму BIT <I> ', '<I>', 53, '0:Телесистема.<I>', 'Показать осцилограмму BIT')]
     procedure DoSetup(Sender: IAction); override;
   end;

   TPalseFlt = class(TbitFlt)
   protected
     function GetCategory: TSubDeviceInfo; override;
     function GetCaption: string; override;
   public
     procedure InputData(Data: Pointer; DataSize: integer); override;
     constructor Create; override;
     [DynamicAction('Показать осцилограмму ФОИ <I> ', '<I>', 54, '0:Телесистема.<I>', 'Показать осцилограмму ФОИ')]
     procedure DoSetup(Sender: IAction); override;
   end;

   TPalseFlt2 = class(TPalseFlt)
   protected
     function GetCategory: TSubDeviceInfo; override;
     function GetCaption: string; override;
   end;

   TDecoder1 = class(TCustomDecoderDev, ITelesistem)
   protected
     function GetCaption: string; override;
     function GetDecoderClass: TDecoderClass; override;
   public
     constructor Create; override;
     [DynamicAction('Показать окно Декорера', '<I>', 55, '0:Телесистема.<I>', 'Показать окно Декорера')]
     procedure DoSetup(Sender: IAction); override;
   end;

  TDecoder2 = class(TCustomDecoderDev, ITelesistem)
  private
    FIsMul: Boolean;
    FFltZerro: Boolean;
    procedure SetIsMul(const Value: Boolean);
    procedure SetFltZerro(const Value: Boolean);
  protected
    function GetCaption: string; override;
    function GetDecoderClass: TDecoderClass; override;
    procedure SetupNewDecoder;  override;
  public
    constructor Create; override;
    [DynamicAction('Показать окно Декорера', '<I>', 55, '0:Телесистема.<I>', 'Показать окно Декорера')]
    procedure DoSetup(Sender: IAction); override;
  published
    [ShowProp('Фильтр единиц умножением')] property IsMul: Boolean read FIsMul write SetIsMul default True;
    [ShowProp('Фильтр нулей')] property FltZerro: Boolean read FFltZerro write SetFltZerro default True;
  end;

  TDecoder3 = class(TCustomDecoderDev, ITelesistem)
  protected
    function GetCaption: string; override;
    function GetDecoderClass: TDecoderClass; override;
  public
    constructor Create; override;
    [DynamicAction('Показать окно Декорера', '<I>', 55, '0:Телесистема.<I>', 'Показать окно Декорера')]
    procedure DoSetup(Sender: IAction); override;
  end;

  TDecoder4 = class(TCustomDecoderDev, ITelesistem)
  private
    FCorLen: Integer;
    procedure SetCorLen(const Value: Integer);
  protected
    procedure SetupNewDecoder;  override;
    function GetCaption: string; override;
    function GetDecoderClass: TDecoderClass; override;
  public
    constructor Create; override;
    [DynamicAction('Показать окно Декорера', '<I>', 55, '0:Телесистема.<I>', 'Показать окно Декорера')]
    procedure DoSetup(Sender: IAction); override;
  published
    [ShowProp('длина керреляции')] property CorLen: Integer read FCorLen write SetCorLen;
  end;

  TDecoder5 = class(TCustomDecoderDev, ITelesistem)
  protected
    function GetCaption: string; override;
    function GetDecoderClass: TDecoderClass; override;
  public
    constructor Create; override;
    [DynamicAction('Показать окно Декорера', '<I>', 55, '0:Телесистема.<I>', 'Показать окно Декорера')]
    procedure DoSetup(Sender: IAction); override;
  end;

  TDecoder6 = class(TCustomDecoderDev, ITelesistem)
  protected
    function GetCaption: string; override;
    function GetDecoderClass: TDecoderClass; override;
  public
    constructor Create; override;
    [DynamicAction('Показать окно Декорера', '<I>', 55, '0:Телесистема.<I>', 'Показать окно Декорера')]
    procedure DoSetup(Sender: IAction); override;
  end;

  TDecoder7 = class(TCustomDecoderDev, ITelesistem)
  protected
    function GetCaption: string; override;
    function GetDecoderClass: TDecoderClass; override;
  public
    constructor Create; override;
    [DynamicAction('Показать окно Декорера', '<I>', 55, '0:Телесистема.<I>', 'Показать окно Декорера')]
    procedure DoSetup(Sender: IAction); override;
  end;

  //   TCorrelate = class(TSubDevWithForm<TUsoData>, ITelesistem)
//   protected
//     procedure InputData(Data: Pointer; DataSize: integer); override;
//     function GetCategory: TSubDeviceInfo; override;
//     function GetCaption: string; override;
//   public
//     [DynamicAction('Показать окно корреляции', '<I>', 55, '0:Телесистема.<I>', 'Показать окно корреляции')]
//     procedure DoSetup(Sender: IAction); override;
//   end;

implementation

{$REGION ' Telesis '}

uses Dev.Telesistem.Data;
{ TProtocolTelesis }

constructor TProtocolTelesis.Create(telesis: TTelesistem);
begin
  Ftelesis := telesis;
end;

procedure TProtocolTelesis.EventRxChar(Sender: TAbstractConnectIO);
begin
  with Sender do
   begin
    FTimerRxTimeOut.Enabled := False;
    try
     if Assigned(FEventReceiveData) then FEventReceiveData(@FInput[0], FICount);
     FICount := 0;
    finally
     FTimerRxTimeOut.Enabled := True;
    end;
   end;
end;

procedure TProtocolTelesis.EventRxTimeOut(Sender: TAbstractConnectIO);
begin
  with Ftelesis do
   try
    BindPortStstus(True);
   finally
    try
     Ftelesis.Stop(Sender as IConnectIO);
    finally
     Ftelesis.Start(Sender as IConnectIO);
    end;
   end;
end;

procedure TProtocolTelesis.TxChar(Sender: TAbstractConnectIO; Data: Pointer; var Cnt: Integer; maxsend: Integer);
begin
end;

{ TTelesistem }

procedure TTelesistem.BeforeRemove;
begin
  inherited;
  try
   Stop(IConnect);
  except
   on E: Exception do TDebug.DoException(E);
  end;
end;

procedure TTelesistem.BindPortStstus(isLost: Boolean);
begin
  if FlagLostPort <> isLost then
   begin
    FlagLostPort := isLost;
    { TODO : bind start or stop connection}
   end
end;

function TTelesistem.CanClose: Boolean;
begin
  Result := True;
  try
   Stop(IConnect);
   // ессли произошла перезагрузка экрана то через 10 сек вкл прибор
   ConnectIO.FTimerRxTimeOut.Enabled := True;
  except
   on E: Exception do TDebug.DoException(E);
  end;
end;

procedure TTelesistem.CheckConnect;
begin
  inherited CheckConnect;
  if not Assigned(ConnectIO.FProtocol) or
     not (TAbstractProtocol(ConnectIO.FProtocol) is TProtocolTelesis) then ConnectIO.FProtocol := TProtocolTelesis.Create(Self);
end;

procedure TTelesistem.DoSetup(Sender: IAction);
begin
  inherited;
end;

procedure TTelesistem.ExecMetrology;
begin
  FExeMetr.Execute(T_WRK, FAddressArray[0]);
end;

function TTelesistem.GetService: PTypeInfo;
begin
  Result := TypeInfo(ITelesistem);
end;

function TTelesistem.GetStructure: TArray<TSubDeviceInfo>;
begin
  SetLength(Result, Length(TELESIS_STRUCURE));
  Move(TELESIS_STRUCURE[0], Result[0], Length(TELESIS_STRUCURE)*SizeOf(TSubDeviceInfo));
end;

procedure TTelesistem.RemoveMetaData;
begin
  FMetaDataInfo.ErrAdr := FAddressArray;
  FMetaDataInfo.Info := nil;
  FWorkEventInfo.Work := nil;
  fStatus := dsNoInit;
  Notify('S_MetaDataInfo');
end;

procedure TTelesistem.InitMetaData(ev: TInfoEvent);
 var
  ip: IProjectMetaData;
  c: TCollectionItem;
begin
  with FMetaDataInfo do
   begin
    if Length(ErrAdr) = 0 then Exit;
    if Length(FAddressArray) <> 1 then raise EBaseException.Create('Длина массива адресов устройств равна нулю');

    for c in FSubDevs do if c is TCustomTeleData then
     begin
      Info := TCustomTeleData(c).GetMetaData;
      break;
     end;
    SetLength(ErrAdr, 0);
    if not Assigned(Info) then CArray.Add<Integer>(ErrAdr, FAddressArray[0])
    else
     try
      FExeMetr.SetMetr(Info, FExeMetr, True);
      finally
       try
        if Supports(GlobalCore, IProjectMetaData, ip) then
           ip.SetMetaData(Self as IDevice, FAddressArray[0], FindDev(Info, FAddressArray[0]));

        FWorkEventInfo.DevAdr := FAddressArray[0];
        FWorkEventInfo.Work := FindWork(Info, FAddressArray[0]);

        S_Status := dsReady;
        if Assigned(ev) then ev(FMetaDataInfo);
       finally
        Notify('S_MetaDataInfo');
       end;
     end;
   end;
end;

function TTelesistem.IsFileUso: Boolean;
begin
  Result := False;
end;

procedure TTelesistem.Loaded;
begin
  inherited;
  Start(IConnect);
end;

procedure TTelesistem.ReadWork(ev: TWorkEvent; StdOnly: Boolean);
begin
  raise EBaseException.Create('ReadWork неподдерживается');
end;

procedure TTelesistem.CheckWorkData;
begin
  if not Assigned(FWorkEventInfo.Work) and Assigned(FMetaDataInfo.Info) then
   begin
    FWorkEventInfo.DevAdr := FAddressArray[0];
    FWorkEventInfo.Work := FindWork(FMetaDataInfo.Info, FAddressArray[0]);
   end;
end;

procedure TTelesistem.SaveLogData;
 var
  ip: IProjectData;
//  ix: IProjectDataFile;
begin
  CheckWorkData;
//  if Supports(GlobalCore, IProjectDataFile, ix) then ix.SaveLogData(Self as IDevice, 1000, Work, Data, n)
  //else
  if Supports(GlobalCore, IProjectData, ip) then ip.SaveLogData(Self as IDevice, FAddressArray[0], FWorkEventInfo.Work, false);
end;

procedure TTelesistem.SendCmd(Cmd: Byte);
begin
  SendROW(@Cmd, 1, procedure(Data: Pointer; DataSize: integer)
    begin
      BindPortStstus(False);
      if (FSubDevs.Count>0) then
       with TSubDev(FSubDevs.Items[0]) do
         if Category.Category = TELESIS_STRUCURE[0].Category then InputData(Data, DataSize);
    end);
end;

procedure TTelesistem.SetConnect(AIConnectIO: IConnectIO);
 var
  old: IConnectIO;
begin
  if Assigned(AIConnectIO) and not Supports(AIConnectIO, IComPortConnectIO) then
    raise EConnectIOException.CreateFmt('%s не COM соединение. Возможно только COM соединение!',[AIConnectIO.ConnectInfo]);
  old := IConnect;
  Stop(IConnect);
  inherited SetConnect(AIConnectIO);
  try
   Start(AIConnectIO);
  except
   inherited SetConnect(old);
   raise;
  end;
end;

procedure TTelesistem.Start(AIConnectIO: IConnectIO);
begin
//  TDebug.Log('start %s %s',[GetDeviceName, AIConnectIO.ConnectInfo]);
  if Assigned(AIConnectIO) and not IsFileUso then
   try
    CheckLocked();
    CheckConnect;
    AIConnectIO.ConnectInfo := AIConnectIO.ConnectInfo+ ';38400';
    ConnectOpen;
    ConnectLock;
    ConnectIO.Send(Self, -1, procedure(Data: Pointer; DataSize: integer)
    begin
      BindPortStstus(False);
      if (FSubDevs.Count>0) then
       with TSubDev(FSubDevs.Items[0]) do
         if Category.Category = TELESIS_STRUCURE[0].Category then InputData(Data, DataSize);
    end, 3000);
    S_Status := dsData;
   except
    on E: Exception do
     begin
      TDebug.DoException(E);
      ConnectIO.FTimerRxTimeOut.Enabled := True;
     end;
   end;
end;

procedure TTelesistem.Stop(AIConnectIO: IConnectIO);
begin
//  TDebug.Log('s t o p  %s %s',[GetDeviceName, AIConnectIO.ConnectInfo]);
  if Assigned(AIConnectIO) then
   begin  //для меня            .. для всех
    ConnectIO.FTimerRxTimeOut.Enabled := False;
    S_Status := dsReady;
    if not IsConnectLocked then ConnectUnLock();
    if AIConnectIO.IsOpen then IConnect.Close;
    AIConnectIO.ConnectInfo := ';';
   end;
end;

{$ENDREGION}

{$REGION ' uso '}

{ TUsoRoot }

constructor TUsoRoot.Create;
begin
  FKSum := 1;
  FFrequency :=  afq10;
  SetLength(FData, USO_LEN);
  FS_Data.Data := @Fdata[0];
  FS_Data.Size := USO_LEN;
  InitConst('TUsoOscForm', 'OscForm_');
  inherited;
end;

procedure TUsoRoot.DeleteData(DataSize: integer);
begin
  FS_Data.Fifo.Delete(DataSize);
end;

destructor TUsoRoot.Destroy;
begin
  if Assigned(FFileStream) then FreeAndNil(FFileStream);
  inherited;
end;

//procedure TUsoRoot.DoSetup(Sender: IAction);
//begin
//  inherited;
//end;

function TUsoRoot.GetCategory: TSubDeviceInfo;
begin
  Result := TELESIS_STRUCURE[0];
end;

procedure TUsoRoot.SetFrequency(const Value: TTelesisFrequency);
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

{ TUso1 }

procedure TUso1.DoSetup(Sender: IAction);
begin
  inherited;
end;

function TUso1.GetCaption: string;
begin
  Result := 'Усо телесистемы'
end;

procedure TUso1.InputData(Data: Pointer; DataSize: integer);
  const
   {$J+}
     i: Integer = 0;
     c: Integer = 0;
   {$J-}
  var
   p: PByte;
begin

 {while True do
  begin
    if FTestUsoData <> tudNone then
     begin
      if c >= Length(Tst_Data) then c := 0;
      if Tst_Data[c] then FData[i] := 1 else FData[i] := - 1;
      Inc(c);
     end;
    inc(i);
    if i = Length(FData) then
     begin
      i := 0;
      FS_Data.Fifo.Add(@FData[0], Length(FData));
      NotifyData;
      if Assigned(FSubDevice) then FSubDevice.InputData(@FData[0], Length(FData));
      Exit;
     end;
  end;}

 p := Data;
  with RecRun do while DataSize > 0 do
   begin
    if HSync then
     begin
      Buff[Ncanal] := p^;
      Inc(Ncanal);
      if Ncanal >= 3 then
       begin
        if Assigned(FFileStream) then FFileStream.WriteData(SmallInt(Swap(wrd)));
        SumDat := SumDat + SmallInt(Swap(wrd));
        Inc(Nfq);
        if Nfq >= FKSum then
         begin
          Nfq := 0;
          FData[i] := SumDat / FKSum * 0.0625;
          if FTestUsoData <> tudNone then
           begin
            if c >= Length(Tst_Data) then c := 0;
            if Tst_Data[c] then FData[i] := 1 else FData[i] := - 1;
            Inc(c);
           end;
          SumDat := 0;
          inc(i);
          // синхронизация команы в низ во время паузы
          if (FS_Data.BookMark = FS_Data.Fifo.Last + i) and FS_Data.IsBookMark then
           begin
            FS_Data.IsBookMark := False;
            Cmd := FCmd;
           end;
          if i = Length(FData) then
           begin
            i := 0;
            FS_Data.Fifo.Add(@FData[0], Length(FData));
//            TDebug.Log('ADD USO.Count  %d                 ', [FS_Data.Fifo.Count]);
            NotifyData;
            if Assigned(FChildSubDevice) then FChildSubDevice.InputData(@FData[0], Length(FData));
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

procedure TUso1.SetBookMark(BookMark: LongWord);
begin
  FS_Data.BookMark := BookMark;
  FS_Data.IsBookMark := True;
  TDebug.Log('USO========= F:%d L:%d C:%d B%d B-L:%d===============',[FS_Data.Fifo.First,
                                                               FS_Data.Fifo.Last,
                                                               FS_Data.Fifo.Count,
                                                               BookMark, BookMark - FS_Data.Fifo.Last]);
end;

procedure TUso1.SetCmd(const Value: Byte);
begin
  FCmd := Value;
  if FCmd < 5 then TTelesistem(Owner).SendCmd(Value);
end;

procedure TUso1.SetTestUsoData(const Value: TTestUsoData);
{$J+} const kadr: integer = 0; {$J-}
 var
  cb: Boolean;
  d, i: Integer;
  a: TArray<Word>;
  procedure encodeMan(d: Byte);
   var
    i: Integer;
  begin
    for I := 0 to 7 do
     begin
      if (d and $80) = 0 then Tst_Data := Tst_Data + [False,False,False,False,False,False,False,False,
                                                      True, True, True, True, True, True, True, True]
                         else Tst_Data := Tst_Data + [True, True, True, True, True, True, True, True,
                                                      False,False,False,False,False,False,False,False];
      d := d shl 1;
     end;
  end;
begin
  if FTestUsoData <> Value then
   begin
    FTestUsoData := Value;
    SetLength(Tst_Data, 0);
    cb := True;
    CreateSuncro(8, cb, Tst_Data);
    case FTestUsoData of
     tudNone: SetLength(Tst_Data, 0);
     tudFibonach:
      begin
       SetLength(a, 16);
       Decode($9249, d);
       for I := 0 to Length(a)-1 do a[i] := d;
       Encode(a, 8, cb, Tst_Data);
//       Encode([0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15], 8, cb, Tst_Data);
      end;
     tudRMCod: EncodeRM([0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15,16,17,18,19,20,21,22,23,24,25,26,27,28,29,30,31], 8, Tst_Data);
     tudFSK:
      begin
       SetLength(a, 16);
       Decode($9249, d);
       for I := 0 to Length(a)-1 do a[i] := d;
       EncodeFSK(a, 8, Tst_Data);
//       EncodeFSK([2583, 2583, 2583, 2583, 2583, 2583, 2583, 2583, 0, 0, 0, 0, 0, 0, 0, 0], 8, Tst_Data);
      end;
     tudFSK2:
      begin
       SetLength(a, 16);
       Decode($9249, d);
       for I := 0 to Length(a)-1 do a[i] := d;
       EncodeFSK2(a, 8, Tst_Data);
//       EncodeFSK([2583, 2583, 2583, 2583, 2583, 2583, 2583, 2583, 0, 0, 0, 0, 0, 0, 0, 0], 8, Tst_Data);
      end;
     tudFibonachCorr:
      begin
       SetLength(a, 16);
       Decode($9249, d);
       for I := 0 to Length(a)-1 do a[i] := d;
       Encode(a, 8, Tst_Data);
      // Encode([0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15], 8, Tst_Data);
      end;
     tudRetrTST:
     begin
      SetLength(a, 6);
      a[0] := kadr mod 4;
      PInteger(@a[1])^ := kadr;
      a[5] := a[0]+a[1]+a[2]+a[3]+a[4];
      for I := 0 to 5 do encodeMan(a[i]);
      Inc(kadr);
     end;
    end;
    Owner.PubChange;
   end;
end;

procedure TUso1.SetWriteToFile(const Value: Boolean);
 {$J+}
 const
  i: Integer = 0;
 {$J-}
  function GetFileName: string;
  begin
    Result := Format('%s\Projects\uso_%d.bin',[Tpath.GetDirectoryName(ParamStr(0)), i]);
  end;
begin
  if FWriteToFile <> Value then
   begin
    FWriteToFile := Value;
    if Assigned(FFileStream) then FreeAndNil(FFileStream);
    if Value then
     begin
      i := 0;
      while TFile.Exists(GetFileName) do Inc(i);
      FFileStream := TFileStream.Create(GetFileName, fmCreate);
     end;
   end;
end;


{ TusoFile }

type
  TInspPosition = class(TJvInspectorInt64Item)
  private
    Ftimer: TTimer;
    procedure OnTimer(Sender: TObject);
  public
    procedure DrawValue(const ACanvas: TCanvas); override;
    constructor Create(const AParent: TJvCustomInspectorItem; const AData: TJvCustomInspectorData); override;
    destructor Destroy; override;
  end;

{ TInspPosition }

constructor TInspPosition.Create(const AParent: TJvCustomInspectorItem; const AData: TJvCustomInspectorData);
begin
  inherited;
  Ftimer := TTimer.Create(nil);
  Ftimer.OnTimer := OnTimer;
  Ftimer.Enabled := True;
end;

procedure TInspPosition.OnTimer(Sender: TObject);
begin
  InvalidateItem;
end;

destructor TInspPosition.Destroy;
begin
  Ftimer.Free;
  inherited;
end;

procedure TInspPosition.DrawValue(const ACanvas: TCanvas);
 var
  f: TFileStream;
  r: TRect;
begin
  f := TusoFile(TJvInspectorPropData(Data).Instance).FFileStream;
  if Assigned(f) then
   begin
     ACanvas.Brush.Color := clBtnFace;
     r := Rects[iprValueArea];
     ACanvas.FillRect(r);
     ACanvas.Brush.Color := clBlue;
     r.Width := Round(f.Position/ f.Size * r.Width);
     ACanvas.FillRect(r);
   end;
  if Editing then DrawEditor(ACanvas);
end;

type
  TInspUcoFile = class(TJvInspectorStringItem)
  public
    constructor Create(const AParent: TJvCustomInspectorItem; const AData: TJvCustomInspectorData); override;
    procedure Edit; override;
  end;

constructor TInspUcoFile.Create(const AParent: TJvCustomInspectorItem; const AData: TJvCustomInspectorData);
begin
  inherited;
  Flags := Flags  + [iifEditButton];
end;

procedure TInspUcoFile.Edit;
begin
  with TOpenDialog.Create(nil) do
  try
   InitialDir := Tpath.GetFullPath(ParamStr(0)) + '\Projects';
   Filter :=  'Файл проекта (uso_*.bin)|uso_*.bin';
   DefaultExt := 'bin';
   Options := [ofReadOnly,ofHideReadOnly,ofPathMustExist,ofFileMustExist,ofEnableSizing];
   if Execute(Application.Handle) then Data.AsString := FileName;
  finally
   Free;
  end;
end;

constructor TusoFile.Create;
begin
  FTimer := TTimer.Create(nil);
  FTimer.OnTimer := OnTimer;
  FSpeed := 100;
  FTimer.Interval := FSpeed;
  FTimer.Enabled := True;
  InitConst('TUsoOscForm', 'OscForm_');
  inherited;
end;

destructor TusoFile.Destroy;
begin
  FTimer.Free;
  inherited;
end;

procedure TusoFile.DoSetup(Sender: IAction);
begin
  inherited;
end;

function TusoFile.GetCaption: string;
begin
  Result := 'Усо файловое';
end;

procedure TusoFile.InputData(Data: Pointer; DataSize: integer);
begin
end;

procedure TusoFile.SetC_Pause(const Value: Boolean);
begin
  FC_Pause := Value;
  FTimer.Enabled := FC_Pause;
end;

procedure TusoFile.SetPosition(const Value: TPosition);
begin
  FPosition := Value;
  if Assigned(FFileStream) then FFileStream.Position := FPosition;
end;

procedure TusoFile.SetSpeed(const Value: Integer);
begin
  FSpeed := Value;
  Ftimer.Interval := FSpeed;
end;

procedure TusoFile.SetUsoFileName(const Value: TFileName);
begin
  FUsoFileName := Value;
  if Assigned(FFileStream) then FreeAndNil(FFileStream);
  if TFile.Exists(FUsoFileName) then FFileStream := TFileStream.Create(FUsoFileName, fmOpenRead)
  else FUsoFileName := '';
  Position := 0;
end;

procedure TusoFile.OnTimer(Sender: TObject);
 const
  {$J+}
   SumDat: Integer = 0;
   Nfq: Integer = 0;
   i: Integer = 0;
  {$J-}
 var
   ar: array[0..USO_LEN-1] of SmallInt;
   a: SmallInt;
begin
  if Assigned(FFileStream) and (FFileStream.Read(ar, USO_LEN*2) = USO_LEN*2) then for a in ar do
   begin
    SumDat := SumDat + a;
    FPosition := FFileStream.Position;
    Inc(Nfq);
    if Nfq >= FKSum then
     begin
      Nfq := 0;
      FData[i] := SumDat / FKSum * 0.0625;
      SumDat := 0;
      inc(i);
      if i = Length(FData) then
       begin
        i := 0;
        FS_Data.Fifo.Add(@FData[0], Length(FData));
        NotifyData;
        if Assigned(FChildSubDevice) then FChildSubDevice.InputData(@FData[0], Length(FData));
       end;
     end;
   end;
end;


{$ENDREGION}

{$REGION 'PalseFlt, bitFlt'}

{ TfltFFT }

constructor TbitFlt.Create;
begin
  inherited;
  InitConst('TBitOscForm', 'BitForm_');
end;

procedure TbitFlt.DoSetup(Sender: IAction);
begin
  inherited;
end;

function TbitFlt.GetCaption: string;
begin
  Result := 'Фильтр BIT'
end;

function TbitFlt.GetCategory: TSubDeviceInfo;
begin
  Result := TELESIS_STRUCURE[3];
end;

procedure TbitFlt.InputData(Data: Pointer; DataSize: integer);
  const
   {$J+} j: Integer = 0; {$J-}
 var
  a: PDoubleArray;
  i: Integer;
  FData: TArray<Double>;
begin
   a := PDoubleArray(Data);
   SetLength(FData, DataSize);
   FS_Data.Data := @Fdata[0];
   FS_Data.Size := DataSize;
   for i := 0 to DataSize-1 do
    begin
     FData[i] := a[i]+Ffifo[j];
     Ffifo[j] := a[i];
     j := (j+1) mod Length(Ffifo);
    end;
   NotifyData;
   if Assigned(FChildSubDevice) then FChildSubDevice.InputData(@FData[0], DataSize);
end;

{ TPalseFlt }

constructor TPalseFlt.Create;
begin
  inherited;
  InitConst('TPalsOscForm', 'PalsForm_');
end;

procedure TPalseFlt.DoSetup(Sender: IAction);
begin
  inherited;
end;

function TPalseFlt.GetCaption: string;
begin
  Result := 'Фильтр ОИ'
end;

function TPalseFlt.GetCategory: TSubDeviceInfo;
begin
  Result := TELESIS_STRUCURE[3];
end;

procedure TPalseFlt.InputData(Data: Pointer; DataSize: integer);
  const
   {$J+} j: Integer = 0; {$J-}
 var
  a: PDoubleArray;
  i, k: Integer;
  sum: Double;
  FData: TArray<Double>;
begin
   a := PDoubleArray(Data);
   SetLength(FData, DataSize);
   FS_Data.Data := @Fdata[0];
   FS_Data.Size := DataSize;
   for i := 0 to DataSize-1 do
    begin
     Ffifo[j] := a[i];
     j := (j+1) mod Length(Ffifo);
     sum := 0;
     for k := 0 to Length(Ffifo)-1 do sum := sum + Ffifo[k];
     FData[i] := sum / Length(Ffifo);
    end;
    NotifyData;
    if Assigned(FChildSubDevice) then FChildSubDevice.InputData(@FData[0], DataSize);
end;

{ TPalseFlt2 }

function TPalseFlt2.GetCaption: string;
begin
  Result := 'Фильтр ОИ (hidden)'
end;

function TPalseFlt2.GetCategory: TSubDeviceInfo;
begin
  Result := TELESIS_STRUCURE[1];
end;

{$ENDREGION}

{$REGION 'TFltBPF'}

procedure TFltBPF.FNCH(from, too: Integer);
 var
  i: Integer;
begin
  for i := 0 to from do FltCoeff[i] := 0;
  for i := from to too do FltCoeff[i] := Sin((i-from) * PI/2 / (too-from));
end;
procedure TFltBPF.FBCH(from, too: Integer);
 var
  i: Integer;
begin
  for i := from to too do FltCoeff[i] := Cos((i-from) * PI/2 / (too-from));
  for i := too to FFT_AMP_LEN div 4 do FltCoeff[i] := 0;
end;

procedure TFltBPF.FPCH(fq, width: Integer);
 var
  i: Integer;
begin
  if width = 0 then Exit;
  FltCoeff[fq] := 0;
  for i := 0 to width do
   begin
    FltCoeff[fq+i] := Sin(i * PI/2 / (width));
    if fq-i >= 0 then FltCoeff[fq-i] := FltCoeff[fq+i];
   end;
end;

constructor TFltBPF.Create;
 var
  i: Integer;
begin
  FFNch1 := 1;
  FFNch2 := 20;
  FFVch1 := 100;
  FFVch2 := 120;

  if not Assigned(FFourier) then {FFourier := TFFourier.Create;} FourierFactory(FFourier);
  SetLength(FdataIn, FFT_LEN);
  SetLength(FDataOut, FFT_LEN);
  // особые точки 0 и максимальная гармоника n/2 не нужны приравниваем 0 при фильтровании
  //       1 == n-1 .... n/2-1 = n/2+1
  //      0 1..n/2-1 n/2 n/2+1..n-1
  SetLength(FltCoeff, FFT_AMP_LEN-1); // нет 0
  for i := 0 to FFT_AMP_LEN div 4-1  do FltCoeff[i] := 1;

//  FNCH(15, 45);
//  FBCH(Round(m-m/1.7), Round(m-m/3));

  SetLength(FFdata, FFT_AMP_LEN);
  SetLength(FFdataFlt, FFT_AMP_LEN);
  FS_Data.FF := @FFdata[0];
  FS_Data.FFFiltered := @FFdataFlt[0];
  FS_Data.FFTSize := FFT_AMP_LEN;
  FS_Data.InData := @FdataIn[FFT_OVERSAMP];
  FS_Data.SampleSize := FFT_SAMPLES;

  FDataCnt := FFT_OVERSAMP;

  InitConst('TFFTForm', 'FFTForm_');
  inherited;
end;

procedure TFltBPF.DoSetup(Sender: IAction);
begin
  inherited;
end;

function TFltBPF.GetCaption: string;
begin
  Result := 'Фильтр FFT'
end;

function TFltBPF.GetCategory: TSubDeviceInfo;
begin
  Result := TELESIS_STRUCURE[1];
end;

procedure TFltBPF.InputData(Data: Pointer; DataSize: integer);
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
    inc(ce, FFT_LEN-1); // начинаем с последней гармоники = 1 гармонике
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
  procedure CosFlt;
   var
    i: Integer;
    k: Double;
  begin
    for i := 0 to FFT_OVERSAMP-1 do
     begin
      k := Sin(i/FFT_OVERSAMP*PI/2);
      FDataOut[i] := FDataOut[i] * k;
      FDataOut[FFT_LEN-1-i] := FDataOut[FFT_LEN-1-i] * k;
     end;
  end;
  var
   c: PComplex;
begin
  Move(Data^, FDataIn[FDataCnt], DataSize*Sizeof(Double));
  Inc(FDataCnt, DataSize);
  if FDataCnt = FFT_LEN then
   begin
    Move(FDataIn[0], FDataOut[0], FFT_LEN*Sizeof(Double));

 //   CosFlt();

    CheckMath(FFourier, FFourier.fft(@FDataOut[0], FFT_LEN));
    CheckMath(FFourier, FFourier.GetLastFF(c));
    Amp(FFData, c);
    ApplyFlt(c);
    Amp(FFDataFlt, c);
    CheckMath(FFourier, FFourier.ifft(FS_Data.OutData));

    inc(FS_Data.OutData, FFT_OVERSAMP);

    DoOutputData(FS_Data.OutData, FFT_SAMPLES);


    Move(FDataIn[FFT_SAMPLES], FDataIn[0], FFT_OVERSAMP*2*Sizeof(Double));
    FDataCnt := FFT_OVERSAMP*2;

   end
  else if FDataCnt > FFT_LEN then raise EBaseException.Create('FDataCnt > FFT_LEN');
end;

procedure TFltBPF.DeleteData(DataSize: integer);
begin
  FS_Data.FifoData.Delete(DataSize);
  FS_Data.FifoFShum.Delete(DataSize);
end;

procedure TFltBPF.DoOutputData(Data: Pointer; DataSize: integer);
begin
  FS_Data.FifoData.Add(Data, FFT_SAMPLES);
  NotifyData;
  if Assigned(FChildSubDevice) then FChildSubDevice.InputData(Data, DataSize);
end;

procedure TFltBPF.OnUserRemove;
begin
  inherited;
  if Assigned(FChildSubDevice) and (FDataCnt > FFT_OVERSAMP) then FChildSubDevice.InputData(@FDataIn[FFT_OVERSAMP], FDataCnt - FFT_OVERSAMP);
end;

procedure TFltBPF.SetFch(const Value: Integer);
begin
  FFch := Value;
  SetupFilter;
end;

procedure TFltBPF.SetFchw(const Value: Integer);
begin
  FFchw := Value;
  SetupFilter;
end;

procedure TFltBPF.SetFNch1(const Value: Integer);
begin
  FFNch1 := Value;
  SetupFilter;
end;

procedure TFltBPF.SetFNch2(const Value: Integer);
begin
  FFNch2 := Value;
  SetupFilter;
end;

procedure TFltBPF.SetFVch1(const Value: Integer);
begin
  FFVch1 := Value;
  SetupFilter;
end;

procedure TFltBPF.SetFVch2(const Value: Integer);
begin
  FFVch2 := Value;
  SetupFilter;
end;

procedure TFltBPF.SetupFilter;
 var
  i: Integer;
begin
  for i := 0 to FFT_AMP_LEN div 4-1  do FltCoeff[i] := 1;
  FNCH(FFNch1, FFNch2);
  FBCH(FFVch1, FFVch2);
  FPCH(FFch, FFchw);
end;

{$ENDREGION}


{ TDecoder1}

constructor TDecoder1.Create;
begin
  inherited;
  InitConst('TDecoderECHOForm', 'DecoderECHO_');
end;

procedure TDecoder1.DoSetup(Sender: IAction);
begin
  inherited;
end;

function TDecoder1.GetCaption: string;
begin
  Result := 'Декодер-RM'
end;

function TDecoder1.GetDecoderClass: TDecoderClass;
begin
  Result := TTelesistemDecoder;
end;

{ TDecoder2 }

constructor TDecoder2.Create;
begin
  inherited;
  InitConst('TDecoderECHOForm', 'DecoderECHO_');
  DataCnt := 16;
  DataCodLen := 17;
  FIsMul := True;
  FFltZerro := True;
end;

procedure TDecoder2.DoSetup(Sender: IAction);
begin
  inherited;
end;

function TDecoder2.GetCaption: string;
begin
  Result := 'Декодер-F'
end;

function TDecoder2.GetDecoderClass: TDecoderClass;
begin
  Result := TFibonachiDecoder;
end;

procedure TDecoder2.SetFltZerro(const Value: Boolean);
begin
  FFltZerro := Value;
  if Assigned(FDecoder) then TFibonachiDecoder(FDecoder).FindZeroes := Value;
  Owner.PubChange;
end;

procedure TDecoder2.SetIsMul(const Value: Boolean);
begin
  FIsMul := Value;
  if Assigned(FDecoder) then TFibonachiDecoder(FDecoder).AlgIsMull := Value;
  Owner.PubChange;
end;

procedure TDecoder2.SetupNewDecoder;
begin
  inherited;
  TFibonachiDecoder(FDecoder).AlgIsMull := FIsMul;
  TFibonachiDecoder(FDecoder).FindZeroes := FFltZerro;
end;

{ TDecoder3 }

constructor TDecoder3.Create;
begin
  inherited;
  InitConst('TDecoderECHOForm', 'DecoderECHO_');
  DataCnt := 16;
  DataCodLen := 34;
end;

procedure TDecoder3.DoSetup(Sender: IAction);
begin
  inherited;
end;

function TDecoder3.GetCaption: string;
begin
  Result := 'Декодер-FSK'
end;

function TDecoder3.GetDecoderClass: TDecoderClass;
begin
  Result := TFSKDecoder;
end;

{ TDecoder4 }

constructor TDecoder4.Create;
begin
  inherited;
  InitConst('TDecoderECHOForm', 'DecoderECHO_');
  DataCnt := 16;
  DataCodLen := 18;
  FCorLen := 2;
end;

procedure TDecoder4.DoSetup(Sender: IAction);
begin
  inherited;
end;

function TDecoder4.GetCaption: string;
begin
  Result := 'Декодер-корр-фиб'
end;

function TDecoder4.GetDecoderClass: TDecoderClass;
begin
  Result := TCorFibonachDecoder;
end;

procedure TDecoder4.SetCorLen(const Value: Integer);
begin
  FCorLen := Value;
  if Assigned(FDecoder) then TCorFibonachDecoder(FDecoder).SimbLen := Value;
  Owner.PubChange;
end;

procedure TDecoder4.SetupNewDecoder;
begin
  inherited;
  TCorFibonachDecoder(FDecoder).SimbLen := FCorLen;
end;

{ TDecoder5 }

constructor TDecoder5.Create;
begin
  inherited;
  InitConst('TFormDEcoderFFT_FSK', 'DecoderFFT_FSK_');
  DataCnt := 16;
  DataCodLen := 34;
end;

procedure TDecoder5.DoSetup(Sender: IAction);
begin
  inherited;
end;

function TDecoder5.GetCaption: string;
begin
  Result := 'Декодер-FFT-FSK'
end;

function TDecoder5.GetDecoderClass: TDecoderClass;
begin
  Result := TFSKDecoderFFT;
end;

{ TDecoder6 }

constructor TDecoder6.Create;
begin
  inherited;
  InitConst('TDecoderECHOForm', 'DecoderECHO_');
  DataCnt := 16;
  DataCodLen := 16 * 4;
end;

procedure TDecoder6.DoSetup(Sender: IAction);
begin
  inherited;
end;

function TDecoder6.GetCaption: string;
begin
  Result := 'Декодер-FSK2'
end;

function TDecoder6.GetDecoderClass: TDecoderClass;
begin
  Result := TFSK2Decoder
end;

{ TDecoder7 }

constructor TDecoder7.Create;
begin
  inherited;
  InitConst('TDecoderECHOForm', 'DecoderECHO_');
  DataCnt := 6;
  DataCodLen := 16;
end;

procedure TDecoder7.DoSetup(Sender: IAction);
begin
  inherited;
end;

function TDecoder7.GetCaption: string;
begin
  Result := 'manchster';
end;

function TDecoder7.GetDecoderClass: TDecoderClass;
begin
  Result := TManchsterDecoder
end;

initialization
  TJvCustomInspectorData.ItemRegister.Add(TJvInspectorTypeInfoRegItem.Create(TInspUcoFile, TypeInfo(TFileName)));
  TJvCustomInspectorData.ItemRegister.Add(TJvInspectorTypeInfoRegItem.Create(TInspPosition, TypeInfo(TusoFile.TPosition)));
  RegisterClasses([TTelesistem, TUso1, TusoFile, TDecoder1, TDecoder2, TDecoder3, TDecoder4, TDecoder5, TDecoder6, TbitFlt, TFltBPF, TPalseFlt, TPalseFlt2]);
  TRegister.AddType<TTelesistem, IDevice>.LiveTime(ltSingletonNamed);
  TRegister.AddType<TUso1, ITelesistem>.LiveTime(ltTransientNamed);
  TRegister.AddType<TusoFile, ITelesistem>.LiveTime(ltTransientNamed);
//  TRegister.AddType<TUso2, ITelesistem>.LiveTime(ltTransientNamed);
  TRegister.AddType<TbitFlt, ITelesistem>.LiveTime(ltTransientNamed);
  TRegister.AddType<TFltBPF, ITelesistem>.LiveTime(ltTransientNamed);
  TRegister.AddType<TPalseFlt, ITelesistem>.LiveTime(ltTransientNamed);
  TRegister.AddType<TPalseFlt2, ITelesistem>.LiveTime(ltTransientNamed);
  TRegister.AddType<TDecoder1, ITelesistem>.LiveTime(ltTransientNamed);
  TRegister.AddType<TDecoder2, ITelesistem>.LiveTime(ltTransientNamed);
  TRegister.AddType<TDecoder3, ITelesistem>.LiveTime(ltTransientNamed);
  TRegister.AddType<TDecoder4, ITelesistem>.LiveTime(ltTransientNamed);
  TRegister.AddType<TDecoder5, ITelesistem>.LiveTime(ltTransientNamed);
  TRegister.AddType<TDecoder6, ITelesistem>.LiveTime(ltTransientNamed);
//  TRegister.AddType<TDecoderFibonach, ITelesistem>.LiveTime(ltTransientNamed);
//  TRegister.AddType<TCorrelate, ITelesistem>.LiveTime(ltTransientNamed);
finalization
  GContainer.RemoveModel<TTelesistem>;
  GContainer.RemoveModel<TusoFile>;
  GContainer.RemoveModel<TUso1>;
//  GContainer.RemoveModel<TUso2>;
  GContainer.RemoveModel<TbitFlt>;
  GContainer.RemoveModel<TPalseFlt>;
  GContainer.RemoveModel<TPalseFlt2>;
  GContainer.RemoveModel<TFltBPF>;
  GContainer.RemoveModel<TDecoder1>;
  GContainer.RemoveModel<TDecoder2>;
  GContainer.RemoveModel<TDecoder3>;
  GContainer.RemoveModel<TDecoder4>;
  GContainer.RemoveModel<TDecoder5>;
  GContainer.RemoveModel<TDecoder6>;
//  GContainer.RemoveModel<TCorrelate>;
//  GContainer.RemoveModel<TDecoderFibonach>;
end.

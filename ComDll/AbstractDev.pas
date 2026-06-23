unit AbstractDev;

interface

uses
  RootImpl, DeviceIntf, debug_except, RootIntf, ExtendIntf, tools, Parser,
  Container, DataSetIntf, XMLDataSet, FileCachImpl, Menus, Generics.Collections,
  System.SyncObjs, Math, Winapi.ActiveX, Vcl.Forms, System.Win.Registry,
  Winapi.Windows, System.SysUtils, System.Classes, CPort, CRC16, Vcl.ExtCtrls,
  System.Variants, Xml.XMLIntf, Xml.XMLDoc, System.Bindings.Outputs, RTTI;

const
  PRIORITY_ConnectIO = PRIORITY_IComponent + 10;
  PRIORITY_Device = PRIORITY_IComponent + 20;

  ZPOROG = 4096;

type

{$REGION 'AbstractConnect'}
  TDevice = class;

  EConnectIOException = class(ENoStackException);

  EAsyncConnectIOException = class(EConnectIOException);

  TAbstractConnectIO = class;

  IProtocol = interface
    ['{2674B232-B8B1-40D7-BA3F-2BCC4D310E69}']
    procedure EventRxTimeOut(Sender: TAbstractConnectIO);
    procedure EventRxChar(Sender: TAbstractConnectIO);
    procedure TxChar(Sender: TAbstractConnectIO; Data: Pointer; var Cnt: Integer; maxsend: Integer = 2000);
  end;

  TAbstractProtocol = class abstract(TIObject, IProtocol)
  protected
    procedure EventRxTimeOut(Sender: TAbstractConnectIO); virtual; abstract;
    procedure EventRxChar(Sender: TAbstractConnectIO); virtual; abstract;
    procedure TxChar(Sender: TAbstractConnectIO; Data: Pointer; var Cnt: Integer; maxsend: Integer = 2000); virtual; abstract;
  end;

  TProtocolClass = class of TAbstractProtocol;

  TAbstractConnectIO = class(TIComponent, IConnectIO, IDebugIO)
  private
    FLockUser: Pointer;
//    FIsOpen: Boolean;
    FStatus: TSetConnectIOStatus;
    procedure SetS_Status(const Value: TSetConnectIOStatus);
//    procedure SetLConnectInfo(const Value: string);
//    procedure SetLWait(const Value: Integer);
  protected
    FSData: string;
    FIndData: integer;
    FlastEvent: TReceiveDataRef;
    FIOEvent: TIOEvent;
    FConnectInfo: string;
    procedure OnTimerRxTimeOut(Sender: TObject); virtual;
    // IConnectIO
    procedure SetConnectInfo(const Value: string); virtual;
    function GetConnectInfo: string;
    procedure Open; virtual;
    procedure Close; virtual;
    procedure UpdateOpenStatus(HwOpen: boolean);
    function IsOpen: Boolean; virtual;
    procedure SetWait(Value: integer);
    function GetWait: integer;
    function Locked(const User): Boolean;
    procedure Lock(const User);
    procedure Unlock(const User);
    procedure SendROW(Data: Pointer; Cnt: Integer; Event: TReceiveDataRef = nil; WaitTime: Integer = -1);

    function GetStatus: TSetConnectIOStatus;
    procedure SetStatus(Value: TSetConnectIOStatus);


    //IDebugIO
    procedure TimoutPayload(const SData: string; IndData: integer);

    procedure SetIOEvent(const AIOEvent: TIOEvent);
    function GetIOEvent(): TIOEvent;
    procedure SetIOEventString(const AIOEvent: TIOEventString);
    function GetIOEventString(): TIOEventString;

    procedure Loaded; override;

    function LockIAm(const User): Boolean;
  public
    const
      MAX_BUF = $80000;
    var
//        _tst: integer;
//
      FIOEventString: TIOEventString;
      FComWait: Integer;
      FTimerRxTimeOut: TTimer;
      FEventReceiveData: TReceiveDataRef;
      FProtocol: IProtocol;
      FICount: integer;
      FInput: array[0..MAX_BUF] of Byte;
    constructor Create(); override;
    destructor Destroy; override;
    procedure CheckOpen; virtual;
    procedure DoEvent(ptr: Pointer; cnt: Integer);
    procedure Send(Data: Pointer; Cnt: Integer; Event: TReceiveDataRef = nil; WaitTime: Integer = -1); virtual; abstract;
    class function Enum: TArray<string>; virtual; abstract;
//    property ConnectInfo: string read GetConnectInfo write SetConnectInfo;
//    property Wait: integer read GetWait write SetWait;
//    property Status: TSetConnectIOStatus read GetStatus;
//    property IOEvent: TIOEvent read GetIOEvent write SetIOEvent;
    property S_Status: TSetConnectIOStatus read FStatus write SetS_Status;
  published
    property S_ConnectInfo: string read GetConnectInfo write SetConnectInfo;
    property S_Wait: Integer read GetWait write SetWait default 2000;
  end;
{$ENDREGION}

  TAbstractNetConnectIO = class(TAbstractConnectIO)
  protected
    class function ExtractHost(const Info: string): string; virtual;
    class function ExtractPort(const Info: string): Word; virtual;
  public
    class function Enum: TArray<string>; override;
  end;

{$REGION 'RamRead'}
  TAbstractDevice = class;
  // Класс от которого происходят все IRamReadInfo уже не абстрактный и работает для приборов PSK
//  ERamReadInfoException = class(EBaseException);
//    EAsyncRamReadInfoException = class(ERamReadInfoException);
//
//  TRamReadInfo = class(TIObject, IRamReadInfo)
//  protected
//    FAbstractDevice: TAbstractDevice;
//    function UpdateRun(r: IRAMInfo; inf: IXMLInfo): Boolean;
    //IRamReadInfo
//    function New(TimeSart: TDateTime; TimeDelay: TTime): IRAMInfo; virtual; safecall;
//    function Update(Info: IXMLInfo; UpdateTimeSyncEvent: TRamEvent = nil): IRAMInfo; virtual; safecall;
//    function Get(): IRAMInfo; virtual; safecall;
//  public
//    constructor Create(AAbstractDevice: TAbstractDevice); reintroduce; virtual;
//    function FileInfo: string;
//  end;

//  TRamReadInfoClass = class of TRamReadInfo;

  // Класс от которого происходят все считыватели памати приборов

  EReadRamException = class(ENeedDialogException);

  EAsyncReadRamException = class(EReadRamException);

  TReadRam = class(TAggObject)
  private//   type
//    TReadRamThtead = class(TThread)
//    protected
//      ptr: Pointer;
//      Owner: TReadRam;
//      procedure DoSync;
//      procedure Execute; override;
//    end;
    const
      MAX_RAM = $420000;
      BUFF_LEN = $16000;
    var    //FReadRamThtead: TReadRamThtead;
      FCreateClcFile: Boolean;
  protected    //FEvent: TEvent;
    //FLock: TCriticalSection;
//    Fifo: TFifoBuffer<Byte>;
    Fifo: TArray<Byte>; // TQueueBuffer<Byte>;
    FAbstractDevice: TAbstractDevice;
    FOldStatus: TDeviceStatus;
    // глобальные настройки при инициализации
    FFlagReadToFF: Boolean;
    FFastSpeed: Integer;

    FFromTime{, FToTime}: TDateTime;
    Fadr: Integer;
    FReadRamEvent: TReadRamEvent;

    // глобальные пользовательские настройки
    // данные по устройствам функция exec
    // текущие данные по устройству
    FStartDate, FDelayTime: TDateTime;
    FRAMInfo: IRAMInfo;
//    FFileRam: string;
    FRamSize: UInt64;
    Fgrade : Integer;
//    FStream: TStream;
    // текущие данные по устройству продолжение
    FRecSize: Integer;
    // пересчитанные адреса памяти
    FCurAdr, FFromAdr, FToAdr: Integer;
    FFromKadr, FcntKadr: Integer;
    FFromTimeAdr, FToTimeAdr: TDateTime;
    FRamXml: IXMLNode;
    FKoefTime: Double;

    FFlagTerminate: Boolean;
    FFlagEndRead: Boolean;
    FEndReason: EnumCopyAsyncRun;

    FModulID: integer;

    FPacketLen: integer;

    FBinFile: string;

//    procedure CheckCreateStream; virtual;
//    procedure FillStream(Data: Byte; Size: Integer); virtual;
//    procedure RoundKadrStream(); virtual;
//    procedure FreeStream; virtual;

    IsOldClose: Boolean;

    FBeginTime: TDateTime;

    IclcDaraSet: IDataSet;

   // ParserData: TArray<TParserData>;
//    FAcquire: Boolean;
//    procedure Acquire;
//    procedure Release;
    IsSSD: boolean;
    function GetCreateClcFile: Boolean; virtual;
    procedure SetCreateClcFile(const Value: Boolean); virtual;

    procedure WriteToBD;

    function ProcToEnd: TStatistic;
    function TestFF(P: PByte; n: Integer): Boolean;
    function CheckZerroes(p: PByte; cnt: Cardinal; out ZBegin: Cardinal): Boolean;

  // IReadDeviceRAM
//    procedure SetReadTime(FromTime, ToTime: TDateTime); virtual; safecall;
//    function GetFromTime: TDateTime; virtual; safecall;
//    function GetToTime: TDateTime; virtual; safecall;
//    procedure SetReadToFF(Flag: Boolean); virtual; safecall;
//    function GetReadToFF: Boolean; virtual; safecall;
//    procedure SetFastSpeed(Flag: Boolean); virtual; safecall;
//    function GetFastSpeed: Boolean; virtual; safecall;
    procedure DoSetData(pData: Pointer; nk: Integer); virtual;
    procedure Execute(const binFile: string; FromKadr, ToKadr: Integer; ReadToFF: Boolean; FastSpeed, Adr: Integer; evInfoRead: TReadRamEvent; ModulID: integer; PacketLen: Integer = 0; grade:Integer=1); virtual;
    procedure Terminate(Res: TResultEvent = nil); virtual;
//    procedure CheckAndInitByAdr(Adr: Integer; MaxRam: Integer = 0; DefK: Double = 0; FromToAval: Boolean = True); virtual;
    procedure EndExecute(); virtual;
    property CreateClcFile: Boolean read GetCreateClcFile write SetCreateClcFile;

  public
    constructor Create(AAbstractDevice: TAbstractDevice); reintroduce; virtual;
    destructor Destroy; override;
  end;

  TReadRamClass = class of TReadRam;
//  TReadRamClass = class of TAbstractReadRam;

  // считыватель памати приборов c диска
//  ERAMEnumeratorException = class(EBaseException);
//  TRAMEnumerator = class(TIObject, IRAMDataEnumerator)
//  private
//      Fbuf: array[0..$8000] of Byte;
//      FAdr : Byte;
//      FRoot: IRAMInfo;
//      FRAMInfo: IRAMInfo;
//      FStream: TStream;
//  protected
//      function GetRamReadInfo(): IRAMInfo; safecall;
//      function Current(): IRAMData; safecall;
//      function MoveNext(): Boolean; safecall;
//      function GotoKadr(Kadr: Integer): Boolean; safecall;
//      function CountKadr(): Integer; safecall;
//  public
//      constructor Create(adr: Integer; ARAMInfo: IRAMInfo); reintroduce;
//      destructor Destroy; override;
//  end;
//   TRAMEnumeratorClass = class of TRAMEnumerator;
{$ENDREGION}

{$REGION 'Device'}

  EDeviceException = class(ENoStackException);

  EAsyncDeviceException = class(EDeviceException);

  TDevice = class(TIComponent, ICaption, IDevice, ILowLevelDeviceIO)
  private
    FConnectIOName: string;

    procedure SetBeforeRemoveConnectIO(const Value: string);
    function GetAddressArray: string;
    procedure SetAddressArray(const Value: string);
    procedure SetLStatus(const Value: TDeviceStatus);
    procedure SetCyclePeriod(const Value: Integer);
  protected
    FCyclePeriod: Integer;
    FStatus: TDeviceStatus;
    FDName: string;
    // ILowLevelDeviceIO
    procedure SendROW(Data: Pointer; Cnt: Integer; Event: TReceiveDataRef = nil; WaitTime: Integer = -1); virtual;
    // IDevice
    function GetAddrs: TAddressArray;
    function GetConnect: IConnectIO;
    procedure SetConnect(AIConnectIO: IConnectIO); virtual;
    function GetStatus: TDeviceStatus;
    function CanClose: Boolean; virtual;
    function GetNamesArray(Index: Integer): string;
    function AddressArrayToNames(const Adrs: TAddressArray): string;
   // ICaption
    function GetDeviceName: string;
    procedure SetDeviceName(const Value: string);
    function ICaption.GetCaption = GetDeviceName;
    procedure ICaption.SetCaption = SetDeviceName;

    procedure Loaded; override;

    property CyclePeriod: Integer read FCyclePeriod write SetCyclePeriod default 2097;
  public
    FAddressArray: TAddressArray;
    FNamesArray: string;
    constructor Create(); override;
    constructor CreateWithAddr(const AddressArray: TAddressArray; const DeviceName, ModulesNames: string); virtual;
    procedure CheckConnect(); virtual;
    ///	<summary>
    ///	  возвращает значение до открытия
    ///	</summary>
    function ConnectOpen(): boolean; virtual;
    procedure ConnectClose(); virtual;
    function IsConnectLocked: boolean; inline;
    procedure ConnectUnLock; inline;
    procedure ConnectLock; inline;
    procedure CheckLocked; inline;
    procedure CheckStatus(const AvailSts: TSetDeviceStatus);
    function ConnectIO: TAbstractConnectIO; inline;

    property NamesArray[Index: Integer]: string read GetNamesArray;
    property IConnect: IConnectIO read GetConnect;

    property C_BeforeRemoveConnectIO: string read FConnectIOName write SetBeforeRemoveConnectIO;
    property S_Status: TDeviceStatus read FStatus write SetLStatus;
  published
    property AddressArray: string read GetAddressArray write SetAddressArray;
    property NamesArrayString: string read FNamesArray write FNamesArray;
    property S_ConnectIO: string read FConnectIOName write FConnectIOName;
    property S_Name: string read GetDeviceName write SetDeviceName;
  end;


//  TAbstractActionsDev = class;
//  TAbstractActionsDevClass = class of TAbstractActionsDev;
  TAbstractDevice = class(TDevice, INotifyBeforeRemove)//,
//                          IAddMenus,
//                          I N ot ifyAfteActionManagerLoad,
//                          INotifyLoadBeroreAdd,
//                          INotifyBeforeAdd)//,
//                          INotifyBeforeRemove)
  private//    FActionsDev: TAbstractActionsDev;
    procedure SetMetaDataInfo(const Value: TDeviceMetaData);
    procedure SetDelayInfo(const Value: TSetDelayRes);
    procedure SetWorkEventInfo(const Value: TWorkEventRes);
    procedure SetEepromkEventInfo(const Value: TEepromEventRes);
  protected
    FReadRam: TReadRam;
    FExeMetr: IXmlScript;
    FDelayInfo: TSetDelayRes;
    FMetaDataInfo: TDeviceMetaData;
    FWorkEventInfo: TWorkEventRes;
    FEepromEventInfo: TEepromEventRes;
//    function QueryInterface(const IID: TGUID; out Obj): HResult; override; stdcall;
//    procedure ResetMetaData();
//    function GetActionsDevClass: TAbstractActionsDevClass; virtual; abstract;
//    procedure AfteActionManagerLoad(); virtual;

    procedure LoadBeroreAdd();
    procedure BeforeRemove(); virtual;
    function PropertyReadRam: TReadRam; virtual;
    function CreateReadRam: TReadRam; virtual;
//    procedure BeforeAdd(); virtual;
//    procedure BeforeRemove(); virtual;
    procedure DoDelayEvent(rez: Boolean; SetTime: TDateTime; Delay, WorkTime: TTime; ResultEvent: TSetDelayEvent);

    procedure Loaded; override;

    procedure EndInfo;

//    property ReadRam: TReadRam read GetReadRam;
  public//    FRamDir: string;
    // IDataDevice
//    procedure InitMetaData(ev: TInfoEvent); virtual; safecall; abstract;
    function GetMetaData: TDeviceMetaData;

//    procedure ReadWork(ev: TWorkEvent; StdOnly: Boolean = false); virtual; safecall; abstract;
    // IDelayDevice
//    procedure SetDelay(Delay, WorkTime: TTime; ResultEvent: TSetDelayEvent); virtual; safecall; abstract;
    // Ram
//    procedure RamDataPath(const PathToRamDataDir: WideString); virtual; safecall;
//    function GetRamDataEnumerator(adr: Integer): IRAMDataEnumerator; virtual; safecall;
//    function GetRamReadInfo(): IRamReadInfo; virtual; safecall;
//    function GetReadDeviceRam(): IReadRamDevice; virtual; safecall;

    constructor CreateWithAddr(const AddressArray: TAddressArray; const DeviceName, ModulesNames: string); override;
    constructor Create(); override;
    destructor Destroy; override;

//    function GetRamDir: string;

    property S_MetaDataInfo: TDeviceMetaData read FMetaDataInfo write SetMetaDataInfo; //live binding
    property S_DelayInfo: TSetDelayRes read FDelayInfo write SetDelayInfo; //live binding
    property S_WorkEventInfo: TWorkEventRes read FWorkEventInfo write SetWorkEventInfo; //live binding
    property S_EepromEventInfo: TEepromEventRes read FEepromEventInfo write SetEepromkEventInfo; //live binding
//    property ActionsDev: TAbstractActionsDev read FActionsDev implements  IAddMenus;
  end;
{$ENDREGION}

 { TAbstractActionsDev = class(TAggObject, Ibind)
  private
    FBind: IBind;
  protected
    procedure AddMenus(Root: TMenuItem); virtual; abstract;
    property Bind: IBind read FBind implements IBind;
  public
    constructor Create(const Controller: IInterface); reintroduce;
    procedure CreateAddManager(); virtual; abstract;
    procedure ShowInMenu(); virtual; abstract;
    procedure NotifyRemove(); virtual; abstract;
  end;}

{$REGION 'Cycle'}

  ECycleException = class(EDeviceException);
  // для новых приборов , усо, Глубиноера

  TCycle = class(TAggObject, ICycle)
  private
    FlagNeedStop: Boolean;
    FOldStatus: TDeviceStatus;
    FTimer: TTimer;
    procedure OnTimer(Sender: TObject);
  protected
    FStdOnly: Boolean;
    procedure DoCycle; virtual;
  public
    function GetCycle: Boolean;
    procedure SetCycle(const Value: Boolean);
    function GetPeriod: Integer;
    procedure SetPeriod(const Value: Integer);
    constructor Create(const Controller: IInterface); reintroduce;
    destructor Destroy; override;
  end;
  // для новых приборов

  TCycleEx = class(TCycle, ICycle, ICycleEx)
  protected
    function GetStdOnly: Boolean;
    procedure SetStdOnly(const Value: Boolean);
  end;
{$ENDREGION}

//  TVActionsDev = class(TAbstractActionsDev)
//  protected
//    procedure AddMenus(Root: TMenuItem); override;
//  public
//    procedure CreateAddManager(); override;
//    procedure ShowInMenu(); override;
//  end;
//  TViewRamDevice = class(TAbstractDevice, IRamDevice)
//    function GetActionsDevClass: TAbstractActionsDevClass; override;
//  public
//    procedure InitMetaData(ev: TInfoEvent); override;
//    procedure ReadWork(ev: TWorkEvent; StdOnly: Boolean = false); override;
//    procedure SetDelay(Delay, WorkTime: TTime; ResultEvent: TSetDelayEvent); override;
//    procedure RamDataPath(const PathToRamDataDir: WideString); override;
//  end;

{$REGION 'ConnectIO'}
  // Реализация для ком порта

  EComConnectIOException = class(EConnectIOException);

//  [Dialog(DIALOG_SETUP_ComPortConnectIO)]
  TComConnectIO = class(TAbstractConnectIO, IComPortConnectIO)
  private
    FCom: TComPort;
//    FCloseTimer: TTimer;
    FCloseErrNessage: string;
    procedure InnerClose;
//    procedure OnComClose(Sender: TObject);
    procedure ComRxChar(Sender: TObject; Count: Integer);
    procedure ComPortCloseException(Sender: TObject; TComException: TComExceptions; ComportMessage: string; WinError: Int64; WinMessage: string);
    procedure ComPortException(Sender: TObject; TComException: TComExceptions; ComportMessage: string; WinError: Int64; WinMessage: string);
  protected
    procedure SetConnectInfo(const Value: string); override;
    procedure Open; override;
    procedure Close; override;
    function IsOpen: Boolean; override;
    function DefaultSpeed: Integer;
  public
    AsString: Boolean;
    FDefaultSpeed: Integer;
    constructor Create(); override;
    destructor Destroy; override;
    procedure CheckOpen; override;
    procedure Flash;
    procedure Send(Data: Pointer; Cnt: Integer; Event: TReceiveDataRef = nil; WaitTime: Integer = -1); override;
    class function Enum: TArray<string>; override;
    property Com: TComPort read FCom;
  end;

  // Реализация протоколов

//  TRunSerialQeRef = reference to procedure(qe: integer); //очередь
//
//  EProtocolBurException = class(EBaseException);
//
//  TProtocolBur = class(TAbstractProtocol)
//  protected
//    type
//      TQeD = record
//        Exec: Boolean;
//        data: TRunSerialQeRef;
//      end;
//
//      TQe = TThreadedQueue<TQeD>;
////      TQe = TQueue<TRunSerialQeRef>;
//    var
//      FQe: TQe;
//      FOldCount: Integer;
//      FCRC: Word;
//    procedure EventRxTimeOut(Sender: TAbstractConnectIO); override;
//    procedure EventRxChar(Sender: TAbstractConnectIO); override;
//    procedure TxChar(Sender: TAbstractConnectIO; Data: Pointer; var Cnt: Integer; maxsend: Integer = $400); override;
//  public
//    constructor Create;
//    destructor Destroy; override;
//    function Add(data: TRunSerialQeRef): Integer; // добавление в очередь и отправка
//    function IsEmpty: Boolean;             // вызываются в AsyncSend
//    procedure Next(Sender: TAbstractConnectIO);                        // вызываются в AsyncSend
//    procedure Clear;
//  end;

  TProtocolPsk = class(TAbstractProtocol)
  protected
    procedure EventRxTimeOut(Sender: TAbstractConnectIO); override;
    procedure EventRxChar(Sender: TAbstractConnectIO); override;
    procedure TxChar(Sender: TAbstractConnectIO; Data: Pointer; var Cnt: Integer; maxsend: Integer = $400); override;
  end;
{$ENDREGION}

resourcestring
  RS_SetIO = '(Lock) Невозможно сменить Порт т.к. прибор занят';
 // RS_Flow = '(Flow) Невозможно освободить Порт занятый чтением информации';
 // RS_IsCycle = '(Cycle) Порт занят';
  RS_Locked = '(Lock) Порт уже занят';
  RS_DevBusy = 'Прибор занят';
  RS_UnLock = '(Unlock) Невозможно освободить Порт занятый другим устройством';
  RS_ErrNoInfo = 'Не инициализирована информация об устройствах';
  RS_NeedClosePort = 'Необходимо закрыть порт %s';
  RS_NeedCloseNet = 'Необходимо закрыть соединение %s';
  RS_SendData = 'Нет протокола для передачи данных';
 // RS_NoDir = 'Директория %s отсутствует';
 // RS_EmptyDir = 'Директория для чтения памяти не задана';
  RS_NoConnect = 'Устройство не подключено к Порту';
 // RS_NoRamInfo = 'Информация устройства с адресом %d о структуре RAM: отсутствует,невозножно считать память';
  //RS_NoRamAttr = 'Невозможно счтать память Адрес: %d, отсутствуют атрибуты %s %s %s %s %s';
 // RS_NoRamFile = 'Невозможно счтать память Адрес: %d нет вайла %s';
//  RS_NoAdr = 'Невозможно получить адрес устройства для чтения памяти';
//  RS_NoXml = 'Невозможно получить xml информацию для чтения памяти';
//  RS_NoRamMetaTime = 'Информация устройства с адресом %d о постановке на задержку отсутствует';
  RS_NoRamMeta = 'Информация устройства с адресом %d о структуре RAM: отсутствует,невозножно считать память';
  RS_NoRamMetaRecSize = 'Информация устройства с адресом %d о структуре RAM: длина записи 0';
 // RS_NoRamMetaK = 'Информация устройства с адресом %d о поправочном коэффициенте отсутствует,невозножно считать память';
 // RS_NoRamMetaBadK = 'Информация устройства с адресом %d о структуре RAM: неверный коэффициент  %1.5f';
 // RS_BadFromToTime = 'Hевозножно считать память устройства с адресом %d время старта %s задержка %s с %s[%d] по %s[%d]';
 // RS_NoRamSize = 'Невозможно получить xml информацию для чтения памяти о размере памяти';
  //RS_NotAvalFromToTime = 'Устройство с адресом %d неподдерживает выборочное чтение памяти';
  RS_ConClosed='Соединение закрыто';


implementation

{$REGION  'TAbstractConnectIO - все процедуры и функции'}

{ TAbstractConnectIO }

procedure TAbstractConnectIO.CheckOpen;
begin
  if not (iosOpen in FStatus) then
    raise EConnectIOException.Create(RS_ConClosed);
end;

procedure TAbstractConnectIO.Close;
begin
  S_Status := FStatus - [iosOpen];
end;

constructor TAbstractConnectIO.Create();
begin
  inherited;
  FTimerRxTimeOut := TTimer.Create(nil);
  FTimerRxTimeOut.Enabled := False;
  FTimerRxTimeOut.OnTimer := OnTimerRxTimeOut;
  FTimerRxTimeOut.Interval := 2000;
  FComWait := FTimerRxTimeOut.Interval;
  Tdebug.Log('------TConnectIO.Create()-------');
end;

destructor TAbstractConnectIO.Destroy;
begin
  Tdebug.Log('-----TConnectIO.Destroy %s', [FConnectInfo]);
  FTimerRxTimeOut.Free;
  inherited;
end;

procedure TAbstractConnectIO.OnTimerRxTimeOut(Sender: TObject);
begin
  FTimerRxTimeOut.Enabled := False;
//  Pinteger(9)^ := 666;
  if Assigned(FIOEvent) then
   begin
    FIOEvent(iosTimeOut, PByteArray(Pchar(FSData)), FIndData);
    FSData := '';
    FIndData := -1;
   end;
  if Assigned(FProtocol) then
    FProtocol.EventRxTimeOut(Self);
end;

procedure TAbstractConnectIO.Open;
begin
  S_Status := FStatus - [iosError] + [iosOpen];
end;

procedure TAbstractConnectIO.DoEvent(ptr: Pointer; cnt: Integer);
begin
//  Dec(_tst);
//  if _tst < 0 then
//   begin
//    Tdebug.log('ERRR EVENT %d',[FICount]);
//   end;
//   if FICount <> $4003 then
//   begin
//    Tdebug.log('ERRR EVENT %d',[FICount]);
//   end;
  if Assigned(FEventReceiveData) then
   begin
    FlastEvent := FEventReceiveData;
    FEventReceiveData := nil;
   end;
//  Tdebug.log('E %x  %d %d', [Integer(@FlastEvent), _tst, FICount]);
  if Assigned(FlastEvent) then
    FlastEvent(ptr, cnt);
end;

procedure TAbstractConnectIO.SetWait(Value: integer);
begin
  if FComWait <> Value then
  begin
    FComWait := Value;
    Notify('S_Wait');
    PubChange;
  end;
end;

procedure TAbstractConnectIO.TimoutPayload(const SData: string; IndData: integer);
begin
  FSData := SData;
  FIndData := IndData;
end;

function TAbstractConnectIO.GetStatus: TSetConnectIOStatus;
begin
  Result := FStatus;
end;

procedure TAbstractConnectIO.Unlock(const User);
begin
  if not Assigned(FLockUser) then
    Exit;
  if FLockUser = Pointer(User) then
  begin
    FLockUser := nil;
    S_Status := FStatus - [iosLock];
  end
  else
    raise EConnectIOException.Create(RS_UnLock);
end;

procedure TAbstractConnectIO.UpdateOpenStatus(HwOpen: boolean);
begin
  if HwOpen <> (iosOpen in S_Status) then
    if HwOpen then
      S_Status := S_Status + [iosOpen] - [iosError]
    else
      S_Status := S_Status - [iosOpen]
end;

procedure TAbstractConnectIO.Loaded;
begin
  inherited Loaded;
  (GContainer as IConnectIOEnum).ItemInitialized(Self as IManagItem);
end;

procedure TAbstractConnectIO.Lock(const User);
begin
  if not Assigned(FLockUser) then
  begin
    FLockUser := Pointer(User);
    S_Status := FStatus + [iosLock];
  end
  else if FLockUser <> Pointer(User) then
    raise EConnectIOException.Create(RS_Locked);
end;

function TAbstractConnectIO.Locked(const User): Boolean;
begin
  if not Assigned(FLockUser) then
    Exit(False);
  Result := FLockUser <> Pointer(User);
end;

function TAbstractConnectIO.LockIAm(const User): Boolean;
begin
  Result := FLockUser = Pointer(User);
end;

function TAbstractConnectIO.GetWait: integer;
begin
  Result := FComWait;
end;

function TAbstractConnectIO.IsOpen: Boolean;
begin
  Result := iosOpen in FStatus;
end;

procedure TAbstractConnectIO.SetStatus(Value: TSetConnectIOStatus);
begin
  SetS_Status(Value);
end;

procedure TAbstractConnectIO.SetS_Status(const Value: TSetConnectIOStatus);
begin
  if Value <> FStatus then
  begin
    FStatus := Value;
    Notify('S_Status');
  end;
end;

procedure TAbstractConnectIO.SetIOEvent(const AIOEvent: TIOEvent);
begin
  FIOEvent := AIOEvent;
end;

procedure TAbstractConnectIO.SetIOEventString(const AIOEvent: TIOEventString);
begin
  FIOEventString := AIOEvent;
end;

{procedure TAbstractConnectIO.SetLConnectInfo(const Value: string);
begin
  if not SameText(FConnectInfo, Value) then
   begin
    if csLoading in ComponentState then Setup(Value);
    FConnectInfo := Value;
    if not (csLoading in ComponentState) then Bind.Notify('LConnectInfo');
    PubChange;
   end;
end;

procedure TAbstractConnectIO.SetLWait(const Value: Integer);
begin
  SetWait(Value);
end;}

procedure TAbstractConnectIO.SendROW(Data: Pointer; Cnt: Integer; Event: TReceiveDataRef; WaitTime: Integer);
begin
  Send(Data, Cnt, Event, WaitTime);
end;

procedure TAbstractConnectIO.SetConnectInfo(const Value: string);
begin
  if not SameText(FConnectInfo, Value) then
  begin
    FConnectInfo := Value;
    Notify('S_ConnectInfo');
    PubChange;
  end;
end;

function TAbstractConnectIO.GetConnectInfo: string;
begin
  Result := FConnectInfo;
end;

function TAbstractConnectIO.GetIOEvent: TIOEvent;
begin
  Result := FIOEvent;
end;

function TAbstractConnectIO.GetIOEventString: TIOEventString;
begin
  Result := FIOEventString;
end;

{$ENDREGION  TAbstractConnectIO}

{$REGION  'TAbstractDevice - все процедуры и функции'}

{ TDevice }

procedure TDevice.CheckLocked();
begin
  if ConnectIO.Locked(self) then
    raise EDeviceException.Create(RS_Locked);
end;

procedure TDevice.CheckStatus(const AvailSts: TSetDeviceStatus);
begin
  if not (S_Status in AvailSts) then
    if S_Status = dsNoInit then
      raise EDeviceException.Create(RS_ErrNoInfo)
    else
      raise EDeviceException.Create(RS_DevBusy);
end;

procedure TDevice.ConnectClose;
begin
//  TThread.Queue(nil, procedure   ?? забыл зачем ??
//  begin
  ConnectIO.Close;
//  end);
end;

function TDevice.ConnectIO: TAbstractConnectIO;
begin
  Result := TAbstractConnectIO(IConnect);
end;

procedure TDevice.ConnectLock;
begin
  ConnectIO.Lock(self);
end;

function TDevice.ConnectOpen: boolean;
begin
  Result := ConnectIO.IsOpen;
  if not Result then
    ConnectIO.Open;
end;

procedure TDevice.ConnectUnLock;
begin
  ConnectIO.UnLock(self);
end;

constructor TDevice.Create();
begin
  inherited;
  Bind('C_BeforeRemoveConnectIO', GContainer as IConnectIOEnum, ['S_BeforeRemove']);
end;

constructor TDevice.CreateWithAddr(const AddressArray: TAddressArray; const DeviceName, ModulesNames: string);
begin
  Create();
  FAddressArray := AddressArray;
  FDName := DeviceName;
  FNamesArray := ModulesNames;
end;

procedure TDevice.Loaded;
begin
  inherited Loaded;
  (GContainer as IDeviceEnum).ItemInitialized(Self as IManagItem);
end;

function TDevice.GetAddressArray: string;
begin
  Result := TAddressRec(FAddressArray).ToStr();
end;

function TDevice.GetAddrs: TAddressArray;
begin
  Result := FAddressArray;
end;

procedure TDevice.SendROW(Data: Pointer; Cnt: Integer; Event: TReceiveDataRef; WaitTime: Integer);
begin
  ConnectIO.Send(Data, Cnt, Event, WaitTime);
end;

function TDevice.IsConnectLocked: boolean;
begin
  Result := ConnectIO.Locked(Self);
end;

function TDevice.GetConnect: IConnectIO;
var
  i: IInterface;
begin
  Result := nil;
  if (FConnectIOName <> '') and GContainer.TryGetInstKnownServ(TypeInfo(IConnectIO), FConnectIOName, i) then
    Result := i as IConnectIO;
end;

function TDevice.GetDeviceName: string;
begin
  if FDName = '' then
    Result := AddressArrayToNames(FAddressArray)
  else
    Result := FDName;
end;

function TDevice.GetNamesArray(Index: Integer): string;
begin
  Result := FNamesArray.Split([' ',';'], TStringSplitOptions.ExcludeEmpty)[Index];
end;

procedure TDevice.SetDeviceName(const Value: string);
begin
  if Value <> FDName then
  begin
    FDName := Value;
    Notify('S_Name');
    PubChange;
  end;
end;

procedure TDevice.SetLStatus(const Value: TDeviceStatus);
begin
  if Value <> FStatus then
  begin
    FStatus := Value;
    Notify('S_Status');
  end;
end;

function TDevice.GetStatus: TDeviceStatus;
begin
  Result := FStatus;
end;

procedure TDevice.SetConnect(AIConnectIO: IConnectIO);

  function AsName: string;
  begin
    if not Assigned(AIConnectIO) then
      Result := ''
    else
      Result := AIConnectIO.IName;
  end;

begin
  if FConnectIOName <> AsName then
  begin
    if Assigned(IConnect) and ConnectIO.LockIAm(Self) then
      raise EDeviceException.Create(RS_SetIO);
    FConnectIOName := AsName;
    Notify('S_ConnectIO');
    PubChange;
  end;
end;

procedure TDevice.SetCyclePeriod(const Value: Integer);
begin
  if FCyclePeriod <> Value then
  begin
    FCyclePeriod := Value;
    PubChange;
  end;
end;

procedure TDevice.SetAddressArray(const Value: string);
begin
  FAddressArray := TAddressRec(Value);
end;

procedure TDevice.SetBeforeRemoveConnectIO(const Value: string);
begin
  if FConnectIOName = Value then
    SetConnect(nil);
end;

function TDevice.AddressArrayToNames(const Adrs: TAddressArray): string;
begin
    Result := '';
    for var e in Adrs do
     for var i := 0 to High(FAddressArray) do
      if e = FAddressArray[i] then  Result := Result + NamesArray[i] +' ';
    Result := Result.Trim;
end;

function TDevice.CanClose: Boolean;
begin
  Result := False;
end;

procedure TDevice.CheckConnect;
begin
  if not Assigned(IConnect) then
    raise EDeviceException.Create(RS_NoConnect);
end;

{ TAbstractDevice }


//procedure TAbstractDevice.AfteActionManagerLoad;
//begin
//  FActionsDev.ShowInMenu;
//end;

//procedure TAbstractDevice.ResetMetaData;
// var
//  GDoc: IXMLDocument;
//begin
//  GDoc := NewXDocument(); { TODO : нен адо создавать метаданные }
//  FMetaDataInfo.Info := GDoc.AddChild('DEVICE');
//  FMetaDataInfo.ErrAdr := FAddressArray;
//end;

//procedure TAbstractDevice.BeforeAdd;
//begin
//  ResetMetaData;
//  LStatus := dsNoInit;
//  FActionsDev.CreateAddManager;
//  FActionsDev.ShowInMenu;
//end;

//procedure TAbstractDevice.BeforeRemove;
//begin
//  FActionsDev.NotifyRemove;
//end;

procedure TAbstractDevice.LoadBeroreAdd;
var
  a: Integer;
begin
  SetLength(FMetaDataInfo.ErrAdr, 0);
  FMetaDataInfo.Info := GetIDeviceMeta((GContainer as IALLMetaDataFactory).Get().Get(), Name);
  for a in FAddressArray do
    if not Assigned(FindDev(FMetaDataInfo.Info, a)) then
      CArray.Add<Integer>(FMetaDataInfo.ErrAdr, a);
  if Length(FMetaDataInfo.ErrAdr) = 0 then
    S_Status := dsReady
  else if Length(FMetaDataInfo.ErrAdr) < Length(FAddressArray) then
    S_Status := dsPartReady
  else
    S_Status := dsNoInit;
//  FActionsDev.CreateAddManager;
  if S_Status <> dsNoInit then
  try
    FExeMetr.SetMetr(FMetaDataInfo.Info, FExeMetr, False);
  finally
    Notify('S_MetaDataInfo');
  end;
  TDebug.Log('TAbstractDevice.LoadBeroreAdd =====  ' + Name + '   ======');
end;

procedure TAbstractDevice.Loaded;
begin
  inherited Loaded;
  LoadBeroreAdd;
end;

//function TAbstractDevice.QueryInterface(const IID: TGUID; out Obj): HResult;
//begin
//  if IID = IReadRamDevice then
//   begin
//    if not Assigned(FReadRam) then FReadRam := GetReadRamClass.Create(Self);
//    Result := FReadRam.QueryInterface(IReadRamDevice, Obj)
//   end
//  else Result := inherited QueryInterface(IID, Obj)
//end;

procedure TAbstractDevice.BeforeRemove;
var
  f: TWorkDataRef;
begin
  f :=
    procedure(n: IXMLNode; adr: integer; const name: string)
    var
      i: IOwnIntfXMLNode;
    begin
      if Supports(n, IOwnIntfXMLNode, i) then
        i.Intf := nil;
    end;
  if Assigned(FMetaDataInfo.Info) then
  begin
    FindAllWorks(FMetaDataInfo.Info, f);
    FindAllRam(FMetaDataInfo.Info, f);
  end;
//  FMetaDataInfo.Info := nil;
//  FWorkEventInfo.Work := nil;
//  FEepromEventInfo.eep := nil;
end;

constructor TAbstractDevice.Create();
begin
  inherited;
//  FActionsDev := GetActionsDevClass.Create(Self);
  FExeMetr := (GContainer as IXMLScriptFactory).Get(nil);
end;

function TAbstractDevice.CreateReadRam: TReadRam;
begin
  Result := TReadRam.Create(Self);
end;

constructor TAbstractDevice.CreateWithAddr(const AddressArray: TAddressArray; const DeviceName, ModulesNames: string);
begin
  inherited;
  FMetaDataInfo.ErrAdr := FAddressArray;
  S_Status := dsNoInit;
end;

destructor TAbstractDevice.Destroy;
begin
//  FExeMetr.Free;
  if Assigned(FReadRam) then
    FReadRam.Free;
//  FActionsDev.Free;
  inherited;
  TDebug.Log('TAbstractDevice.Destroy =====  ' + S_Name + ' ' + name + '   ======');
end;

procedure TAbstractDevice.DoDelayEvent(rez: Boolean; SetTime: TDateTime; Delay, WorkTime: TTime; ResultEvent: TSetDelayEvent);
begin
  FDelayInfo.Res := rez;
  FDelayInfo.Delay := Delay;
  FDelayInfo.WorkTime := WorkTime;
  FDelayInfo.SetTime := SetTime;
  try
    if Assigned(ResultEvent) then
      ResultEvent(FDelayInfo);
  finally
    Notify('S_DelayInfo');
  end;
end;

procedure TAbstractDevice.EndInfo;
var
  ix: IProjectDataFile;
begin
  if Supports(GlobalCore, IProjectDataFile, ix) and Assigned(FMetaDataInfo.Info) then
    FindAllWorks(FMetaDataInfo.Info,
      procedure(wrk: IXMLNode; Adr: integer; const name: string)
      begin
        ix.SaveEnd(wrk);
      end);
end;

function TAbstractDevice.GetMetaData: TDeviceMetaData;
begin
  Result := FMetaDataInfo;
end;

function TAbstractDevice.PropertyReadRam: TReadRam;
begin
  if not Assigned(FReadRam) then
    FReadRam := CreateReadRam;
  Result := FReadRam;
end;

//function TAbstractDevice.GetReadRamClass: TReadRamClass;
//begin
//  Result := TReadRam;
//end;

{function TAbstractDevice.GetRamDataEnumerator(adr: Integer): IRAMDataEnumerator;
begin
  Result := TRAMEnumerator.Create(adr, GetRamReadInfo.Get);
end;

function TAbstractDevice.GetRamDir: string;
begin
  Result := FRamDir;
  if FRamDir ='' then  raise EDeviceException.Create(RS_EmptyDir);
  if not DirectoryExists(FRamDir) then raise EDeviceException.CreateFmt(RS_NoDir,[FRamDir]);
end;

function TAbstractDevice.GetRamReadInfo: IRamReadInfo;
begin
  Result := TRamReadInfo.Create(Self);
end;

function TAbstractDevice.GetReadDeviceRam: IReadRamDevice;
begin
  raise EDeviceException.Create('IReadRamDevice не реализован');
end;

procedure TAbstractDevice.RamDataPath(const PathToRamDataDir: WideString);
begin
  FRamDir := string(PathToRamDataDir);
  if not DirectoryExists(FRamDir) then raise EDeviceException.CreateFmt(RS_NoDir,[FRamDir]);
end; }

procedure TAbstractDevice.SetDelayInfo(const Value: TSetDelayRes);
begin
  raise EDeviceException.Create('TAbstractDevice.SetDelayInfo(const Value: TSetDelayRes)');
end;

procedure TAbstractDevice.SetEepromkEventInfo(const Value: TEepromEventRes);
begin
  raise EDeviceException.Create('TAbstractDevice.SetEepromkEventInfo(const Value: TEepromEventRes)');
end;

procedure TAbstractDevice.SetMetaDataInfo(const Value: TDeviceMetaData);
begin
  raise EDeviceException.Create('TAbstractDevice.SetMetaDataInfo(const Value: TInfoEventRes)');
end;

procedure TAbstractDevice.SetWorkEventInfo(const Value: TWorkEventRes);
begin
  raise EDeviceException.Create('TAbstractDevice.SetWorkEventInfo(const Value: TWorkEventRes)');
end;

{$ENDREGION  TAbstractDevice}

{ TVActionsDev }

{procedure TVActionsDev.AddMenus(Root: TMenuItem);
begin
end;
procedure TVActionsDev.CreateAddManager;
begin
end;
procedure TVActionsDev.ShowInMenu;
begin
end;
procedure TViewRamDevice.RamDataPath(const PathToRamDataDir: WideString);
begin
  inherited;
  if Length(FAddressArray) > 0 then Exit;
  FindAllWorks(GetRamReadInfo.Get(), procedure(wrk: IXMLNode; adr: Byte; const name: string)
  begin
    Carray.Add<Integer>(FAddressArray, adr);
  end);
end;
function TViewRamDevice.GetActionsDevClass: TAbstractActionsDevClass;
begin
  Result := TVActionsDev;
end;

procedure TViewRamDevice.InitMetaData(ev: TInfoEvent);
begin
end;
procedure TViewRamDevice.ReadWork(ev: TWorkEvent; StdOnly: Boolean);
begin
end;
procedure TViewRamDevice.SetDelay(Delay, WorkTime: TTime; ResultEvent: TSetDelayEvent);
begin
end;   }


{ TComConnectIO }
{$REGION  'TComConnectIO - все процедуры и функции'}
constructor TComConnectIO.Create();
begin
  inherited Create;
  FConnectInfo := 'COM1';
  FCom := TComPort.Create(nil);
  FCom.BaudRate := brCustom;
  Fcom.CustomBaudRate := 125000;
  Fcom.Buffer.InputSize := MAX_BUF;
  Fcom.Buffer.OutputSize := $200;
  Fcom.Events := [evRxChar];
  Fcom.SyncMethod := smWindowSync;// smWindowSync; // smNone;//smThreadSync;//smWindowSync;
  Fcom.TriggersOnRxChar := True;
  Fcom.OnRxChar := ComRxChar;
  Fcom.Port := FConnectInfo;
  FCom.OnException := ComPortException;
//  Fcom.Timeouts.ReadInterval := 200;
  TDebug.Log('----------TComConnectIO.Create(%s);---------------',[Name]);
end;

//var _ggg: Integer;
procedure TComConnectIO.InnerClose;
begin
 // FCom.OnRxChar := nil;
//  try
//    Flash
//  except
//    on e: Exception do
//      TDebug.DoException(e, False);
//  end;
//  InterlockedIncrement(_ggg);
//  if TThread.Current.ThreadID = System.MainThreadID then
//   TDebug.Log('TThread.Current.ThreadID = System.MainThreadID %d ',[_ggg])
//   else TDebug.Log('!!!!!!!!!!!!!!   TThread.Current.ThreadID <> System.MainThreadID  !!!!!!!!!!!!!!!');
//   if _ggg >= 2 then
//    begin
//      TDebug.Log('====================== Thread ERROR %d ==========================',[_ggg]);
//      _ggg := 0;
//      Exit;
//    end;

  if Fcom.Connected then
   begin
    FCom.OnException := ComPortCloseException;
    FCloseErrNessage := '';
    FCom.Close;
//    TDebug.Log('[1] TComConnectIO.InnerClose %s  %d',[Fcom.Port, Fcom.CustomBaudRate]);
    FCom.OnException := ComPortException;
//    TDebug.Log('[2] TComConnectIO.InnerClose %s  %d',[Fcom.Port, Fcom.CustomBaudRate]);
    inherited Close;
//    TDebug.Log('[3] TComConnectIO.InnerClose %s  %d',[Fcom.Port, Fcom.CustomBaudRate]);
   end
   else TDebug.Log('!!!!!!!!!!!!!!   DUIBLE CLOSE  !!!!!!!!!!!!!!!');
//   _ggg := 0;
end;

procedure TComConnectIO.ComPortCloseException(Sender: TObject; TComException: TComExceptions; ComportMessage: string; WinError: Int64; WinMessage: string);
begin
  FCloseErrNessage := ComportMessage + '  ' + WinMessage;
  S_Status := FStatus + [iosError];
end;

procedure TComConnectIO.ComPortException(Sender: TObject; TComException: TComExceptions; ComportMessage: string; WinError: Int64; WinMessage: string);
begin
  S_Status := FStatus + [iosError];
  raise EComConnectIOException.Create(ComportMessage + ' [' + WinError.ToString + '] ' + WinMessage);
end;

function TComConnectIO.DefaultSpeed: Integer;
begin
  Result := FDefaultSpeed;
end;

destructor TComConnectIO.Destroy;
begin
  TDebug.Log('----------TComConnectIO.Destroy;---------------');
  InnerClose();
  FCom.Free;
  inherited;
end;

class function TComConnectIO.Enum: TArray<string>;
var
  s: string;
  Ports: TStrings;
begin
  Ports := TStringList.Create;
  SetLength(Result, 0);
  try
    EnumComPorts(Ports);
    for s in Ports do
     begin
      CArray.Add<string>(Result, s.Split([#0])[0]);
     end;
  finally
    Ports.Free;
  end;
end;

procedure TComConnectIO.Flash;
begin
  FCom.AbortAllAsync;
  FCom.ClearBuffer(true, true);
end;

procedure TComConnectIO.ComRxChar(Sender: TObject; Count: Integer);
var
  a: AnsiString;
begin
  FSData := '';
  FIndData := -1;
  if (FICount + Count) > MAX_BUF then
  begin
    FICount := 0;
    TDebug.Log('ComRxChar=!!!!!!!OVERFLOW!!!!!!!!!!');
  end;
  Com.Read(FInput[FICount], Count);
  Inc(FICount, Count);
//  TThread.Current.Queue(TThread.Current, procedure ()
//  begin
  try
    if AsString and Assigned(FIOEventString) then
    begin
      SetString(a, PAnsiChar(@FInput[FICount - Count]), Count);
      FIOEventString(iosRx, string(a));
    end
    else if Assigned(FIOEvent) then
      FIOEvent(iosRx, @FInput[FICount - Count], Count)
    else
      Application.MainForm.Repaint; // чтобы небыло потерь данных ???/
  finally
    if Assigned(FProtocol) then
      FProtocol.EventRxChar(Self);
  end;
//  end);
end;

procedure TComConnectIO.SetConnectInfo(const Value: string);
var
  i: Integer;
  a: TArray<string>;
begin
  if not SameText(FConnectInfo, Value) then
  begin
    if IsOpen then
      raise EComConnectIOException.CreateFmt(RS_NeedClosePort, [Fcom.Port]);
    a := Value.Split([';']);
    for i := 0 to Length(a) - 1 do
      a[i] := a[i].Trim;
    if a[0] <> '' then
      Fcom.Port := a[0];
    if (Length(a) > 1) and (a[1] <> '') then
      Fcom.CustomBaudRate := a[1].ToInteger()
    else
      Fcom.CustomBaudRate := 125000;

    FDefaultSpeed := Fcom.CustomBaudRate;

    if (Length(a) > 2) and (a[2] <> '') then
      Fcom.Parity.Bits := TParityBits(a[2].ToInteger())
    else
      Fcom.Parity.Bits := prNone;
    if (Length(a) > 3) and (a[3] <> '') then
      Fcom.StopBits := TStopBits(a[3].ToInteger())
    else
      Fcom.StopBits := sbOneStopBit;
//    inherited SetConnectInfo(Fcom.Port);
    inherited SetConnectInfo(Value);
  end;
end;

function TComConnectIO.IsOpen: Boolean;
begin
  Result := FCom.Connected;
  UpdateOpenStatus(Result);
end;

//procedure TComConnectIO.OnComClose(Sender: TObject);
//begin
//  FreeAndNil(FCloseTimer);
//  InnerClose();
//  if FCloseErrNessage <> '' then raise EComConnectIOException.Create(FCloseErrNessage);
//end;

procedure TComConnectIO.Open;
begin
  if Fcom.Connected then
    raise EComConnectIOException.CreateFmt(RS_NeedClosePort, [Fcom.Port]);
//  try
  Fcom.Open;
//  Flash;
  inherited Open;
//  except
//   S_Status := FStatus + [iosError];
//   raise
//  end;
end;

procedure TComConnectIO.CheckOpen;
begin
  if not Fcom.Connected then
    raise EComConnectIOException.CreateFmt('Порт закрыт %s', [Fcom.Port]);
end;

procedure TComConnectIO.Close;
begin
//  if not Assigned(FCloseTimer) then
//   begin
//    FCloseTimer := TTimer.Create(nil);
//    FCloseTimer.OnTimer := OnComClose;
//    FCloseTimer.Interval := 1;
//    FCloseTimer.Enabled := True;
//   end;
//  FreeAndNil(FCloseTimer);
  InnerClose();
  //Tdebug.Log('[1] procedure TComConnectIO.Close;');
  if FCloseErrNessage <> '' then
    raise EComConnectIOException.Create(FCloseErrNessage);
end;

procedure TComConnectIO.Send(Data: Pointer; Cnt: Integer; Event: TReceiveDataRef; WaitTime: Integer);
var
  b: array[0..2000] of Byte;
  a: AnsiString;
begin
  if Assigned(FProtocol) then
  begin
    if not Assigned(Data) then
      raise EComConnectIOException.Create('Data not init');
//    _tst := 1;
//    TDebug.Log('SetE %x %d', [Integer(@Event), _tst]);
    FEventReceiveData := Event;
    if WaitTime >= 0 then
      FTimerRxTimeOut.Interval := WaitTime
    else
      FTimerRxTimeOut.Interval := FComWait;
    Move(Data^, b[0], Cnt);
    FProtocol.TxChar(Self, @b[0], Cnt);
    FTimerRxTimeOut.Enabled := True;
    CheckOpen;
    if Cnt > 0 then
      FCom.Write(b[0], Cnt);
    if AsString and Assigned(FIOEventString) then
    begin
      SetString(a, PAnsiChar(@b[0]), Cnt);
      FIOEventString(iosTx, string(a));
    end
    else if Assigned(FIOEvent) then
      FIOEvent(iosTx, @b[0], Cnt);
 //   Sleep(1);

  end
  else
    raise EComConnectIOException.Create(RS_SendData);
end;
{$ENDREGION  TComConnectIO}

{ TProtocolBur }
{$REGION  'TProtocolBur - все процедуры и функции'}

//constructor TProtocolBur.Create;
//begin
//  inherited Create;
//  FQe := TQe.Create(100,100,100);
//end;
//
//destructor TProtocolBur.Destroy;
//begin
//  FQe.Free;
//  TDebug.Log('----------TProtocolBur.Destroy;---------------');
//  inherited;
//end;
//
//function TProtocolBur.Add(data: TRunSerialQeRef): Integer;
// var
//  Qed: TQeD;
//begin
//  //FQe.Enqueue(data); //Count+1
////  if FQe.Count = 1 then
////   begin
////     TDebug.Log('add %d',[FQe.Count]);
////     data(); //Invoke TRunSerialQeRef, если первый
////   end;
// // TDebug.Log('before add %d',[FQe.QueueSize]);
//  Qed.data := data;
//  if FQe.QueueSize = 0 then
//   begin
//     Qed.Exec := True;
//     FQe.PushItem(Qed, Result);
//   //  TDebug.Log('data run add %d',[Count]);
//     //(Sender as IDebugIO).IOEventString(iosDebug, Format('before next %d',[FQe.QueueSize]));
//     data(Result); //Invoke TRunSerialQeRef, если первый
//   end
//   else
//    begin
//     Qed.Exec := False;
//     FQe.PushItem(Qed, Result);
//  //  TDebug.Log('data NOTRUN add %d',[Count]);
//    end;
//end;
//
//procedure TProtocolBur.Clear;
//begin
////  FQe.DoShutDown;
////  FreeAndNil(FQe);
////  FQe := TQe.Create;
////  FQe.Clear;
//end;

//function TProtocolBur.IsEmpty: Boolean;
//begin
////  Result := FQe.Count = 0;
//  Result := FQe.QueueSize = 0;
//end;
//
//procedure TProtocolBur.Next(Sender: TAbstractConnectIO);
// var
//  Count: Integer;
//  Qed: TQeD;
//begin
// if FQe.QueueSize > 0 then
//  begin
//  (Sender as IDebugIO).IOEventString(iosDebug, Format('1==Next== before popup-I %d',[FQe.QueueSize]));
//    var res := FQe.PopItem(Count, Qed);
//    if Qed.Exec then
//     begin
//        (Sender as IDebugIO).IOEventString(iosDebug, Format('2  ==Next== EXE %d',[Count]));
//        if Count > 0 then
//        begin
//         (Sender as IDebugIO).IOEventString(iosDebug, Format('3    ==Next== popup-II  %d',[FQe.QueueSize]));
//         res := FQe.PopItem(Count, Qed);
//         (Sender as IDebugIO).IOEventString(iosDebug, Format('4      ==Next== before Data(count) %d',[FQe.QueueSize]));
//          try
//           Qed.data(Count);
//           (Sender as IDebugIO).IOEventString(iosDebug, Format('5       ==Next== after Data(count) %d',[FQe.QueueSize]));
//          except
//            FQe.Free;
//            FQe := TQe.Create(100,100,100);
//            raise;
//      //      FQe.Clear;
//          end;
//        end;
//     end
//     else
//     begin
//        (Sender as IDebugIO).IOEventString(iosDebug, Format('6  ==Next== NOEXE before Data(count) %d',[Count]));
//        try
//         Qed.data(Count);
//        (Sender as IDebugIO).IOEventString(iosDebug, Format('7    ==Next== NOEXE after Data(count) %d',[Count]));
//        except
//          FQe.Free;
//          FQe := TQe.Create(100,100,100);
//          raise;
//    //      FQe.Clear;
//        end;
//     end;
//  end;
////  if FQe.Count > 0 then
////    FQe.Dequeue(); //Count-1
////    TDebug.Log('Next %d',[FQe.Count]);
////  if FQe.Count > 0 then
////  try
////    TDebug.Log('Peek %d',[FQe.Count]);
////    FQe.Peek()();  //Invoke TRunSerialQeRef, если есть ещё
////  except
////    Clear;
////    raise;
////  end;
//end;

//procedure TProtocolBur.TxChar(Sender: TAbstractConnectIO; Data: Pointer; var Cnt: Integer; maxsend: Integer);
//begin
//  if Cnt > maxsend then
//    raise EProtocolBurException.CreateFmt('Data count for read %d more than %d', [Cnt,maxsend]);
//  SetCRC16(Data, Cnt);
//  Sender.FICount := 0;
//  Inc(Cnt, 2);
//
//  FOldCount := 0;
//  FCRC := $FFFF;
////  Cnt := 1;
//end;
//
//procedure TProtocolBur.EventRxChar(Sender: TAbstractConnectIO);
//var
//  n, o: Integer;
//begin
//  Sender.FTimerRxTimeOut.Enabled := False;
//  n := Sender.FICount - FOldCount;
//  o := FOldCount;
//  FOldCount := Sender.FICount;
//  with Sender do
//    if CRC16_Find(@FInput[o], n, FCRC) then
//    begin
//      try
//        (Sender as IDebugIO).IOEventString(iosDebug, Format(  '1 ==EventRxChar== before DoEvent CMD %x', [FInput[0]]));
//        DoEvent(@FInput[0], FICount - 2);
//      finally
//        (Sender as IDebugIO).IOEventString(iosDebug, Format(  '2   ==EventRxChar== before NEXT CMD %x', [FInput[0]]));
//        Next(Sender); //AsyncSend далее
//        (Sender as IDebugIO).IOEventString(iosDebug, Format(  '3     ==EventRxChar== Afer Next CMD %x', [FInput[0]]));
//      end;
//    end
//    else
//      Sender.FTimerRxTimeOut.Enabled := True;
//  // else TDebug.Log('CRCBAAD %x   %d ', [FInput[0], FICount]);
//end;
//
//procedure TProtocolBur.EventRxTimeOut(Sender: TAbstractConnectIO);
//begin
//  try
//    with Sender do
//      if TestCRC16(@FInput[0], FICount) then
//        TDebug.Log('GOOD')
//      else
//        TDebug.Log('BAAD    %x %x /// %x %x   %x  ', [FInput[0], FInput[1], FInput[FICount - 2], FInput[FICount - 1], FICount]);
//    Sender.DoEvent(nil, -1);
//  finally
//    Next(Sender); //AsyncSend далее
//  end;
//end;
{$ENDREGION  TProtocolBur}

{ TProtocolPsk }
{$REGION  'TProtocolPsk - все процедуры и функции'}

procedure TProtocolPsk.EventRxChar(Sender: TAbstractConnectIO);
begin
  with Sender do
  begin
    FTimerRxTimeOut.Enabled := False;
//    TDebug.Log('FICount === %d ====', [FICount]);
    DoEvent(@FInput[0], FICount);
  end;
end;

procedure TProtocolPsk.EventRxTimeOut(Sender: TAbstractConnectIO);
begin
  Sender.DoEvent(nil, -1);
end;

procedure TProtocolPsk.TxChar(Sender: TAbstractConnectIO; Data: Pointer; var Cnt: Integer; maxsend: Integer);
begin
end;
{$ENDREGION  TProtocolPsk}

{ TRamReadInfo }
{$REGION  'TRamReadInfo - все процедуры и функции'}
{constructor TRamReadInfo.Create(AAbstractDevice: TAbstractDevice);
begin
  inherited Create();
  FAbstractDevice := AAbstractDevice;
  FAbstractDevice.GetRamDir;
end;

function TRamReadInfo.FileInfo: string;
begin
  Result := FAbstractDevice.GetRamDir + 'ram.xml';
end;

function TRamReadInfo.Get: IRAMInfo;
 var
  GDoc: IXMLDocument;
begin
  if not FileExists(FileInfo) then raise ERamReadInfoException.CreateFmt('Файл %s отсутствует',[FileInfo]);
  GDoc := NewXDocument();
  Gdoc.LoadFromFile(FileInfo);
  if not GDoc.DocumentElement.HasAttribute(AT_START_TIME) or not GDoc.DocumentElement.HasAttribute(AT_DELAY_TIME) then
    raise ERamReadInfoException.CreateFmt('Файл %s с ошибкой нет %s или %s', [FileInfo, AT_START_TIME, AT_DELAY_TIME]);
  Result := Gdoc.DocumentElement;
end;

function TRamReadInfo.New(TimeSart: TDateTime; TimeDelay: TTime): IRAMInfo;
 var
  GDoc: IXMLDocument;
begin
  GDoc := NewXDocument();
  GDoc.DocumentElement := GDoc.AddChild('RAM_READ_INFO');
  GDoc.DocumentElement.Attributes[AT_START_TIME] := TimeSart;
  GDoc.DocumentElement.Attributes[AT_DELAY_TIME] := MyTimeToStr(TimeDelay);
  GDoc.SaveToFile(FileInfo);
  Result := GDoc.DocumentElement;
end;

function TRamReadInfo.Update(Info: IXMLInfo; UpdateTimeSyncEvent: TRamEvent): IRAMInfo;
begin
  Result := Get();
  if UpdateRun(Result, Info) then Result.OwnerDocument.SaveToFile(FileInfo);
end;

function TRamReadInfo.UpdateRun(r: IRAMInfo; inf: IXMLInfo): Boolean;
 var
  i: Integer;
begin
  Result := False;
  for i := 0 to inf.ChildNodes.Count-1 do if not Assigned(r.ChildNodes.FindNode(inf.ChildNodes[i].NodeName)) then
   begin
    r.ChildNodes.Add(inf.ChildNodes[i]);
    Result := True;
   end;
end;      }
{$ENDREGION  TRamReadInfo}

{$REGION  'TReadRam - все процедуры и функции'}

{ TReadRam.TReadRamThtead }

//procedure TReadRam.TReadRamThtead.DoSync;
//begin
//  Owner.DoSetData(ptr,1);
//end;

{procedure TReadRam.TReadRamThtead.Execute;
 var
  t: Cardinal;
  procedure ResetT;
//   var
//    pdb: IProjectDBData;
  begin
   t := GetTickCount;
//   if Supports(GlobalCore, IProjectDBData, pdb) then
//    begin
//     pdb.CommitTrans;
//     pdb.BeginTrans;
//    end;
   with Owner do if FFlagEndRead and Assigned(FReadRamEvent) then FReadRamEvent(carOk, FAdr, ProcToEnd);
  end;

begin
  CoInitialize(nil);
  try
    NameThreadForDebugging('RAM_READ');
    t := GetTickCount;
    with Owner do
     repeat
      //Fevent.WaitFor();
      //Fevent.ResetEvent;
      try
       if Terminated then Exit;
//       while Length(Fifo) >= FRecSize {Fifo.pop(ptr, FRecSize)} //do
//        try
  //        Synchronize(DoSync);
//         if Terminated or FFlagTerminate then Break;
//         Acquire;
//         try
//          DoSetData(@Fifo[0],1);
{          Delete(Fifo, 0 , FRecSize);
         finally
  //        Release;
         end;
         if not FFlagEndRead and ((GetTickCount - t) > 10000) then
         Synchronize(procedure
         begin
           t := GetTickCount;
//           if {FFlagEndRead and }//Assigned(FReadRamEvent) then FReadRamEvent(carOk, FAdr, ProcToEnd);
{         end);
        except
         on E: Exception do TDebug.DoException(E, False);
        end;
       if FFlagEndRead then
        begin
         FFlagEndRead := False;
        // Synchronize(EndExecute);
        end;
      except
       on E: Exception do
        begin
         TDebug.DoException(E, False);
         Terminate;
        end;
      end;
     until Terminated;
   finally
    CoUninitialize;
   end;
end;  }

{ TReadRam }

//procedure TReadRam.Acquire;
//begin
//  while FAcquire do
//   begin
//    TThread.Yield;
//    application.HandleMessage;
//   end;
//  FAcquire := True;
//end;

constructor TReadRam.Create(AAbstractDevice: TAbstractDevice);
begin
  inherited Create(AAbstractDevice as IInterface);
//  Fifo := TFifoBuffer<Byte>.Create(BUFF_LEN);
  //Fifo := TQueueBuffer<Byte>.Create;
  FAbstractDevice := AAbstractDevice;
  FFlagReadToFF := True;
  FFastSpeed := 0;
//  FFromTime := 0;
//  FToTime:= 0;
  FFlagTerminate := True;
  //FEvent := TEvent.Create;
  //FLock := TCriticalSection.Create;
//  FReadRamThtead := TReadRamThtead.Create;
//  FReadRamThtead.Owner := Self;
end;

destructor TReadRam.Destroy;
begin
//  FReadRamThtead.Terminate;
//  FEvent.SetEvent;
//  FReadRamThtead.WaitFor;
//  FReadRamThtead.Destroy;
//  FEvent.Destroy;
  //FLock.Free;
 // Fifo.Free;
  inherited;
end;

procedure TReadRam.DoSetData(pData: Pointer; nk: Integer);
var
  ip: IProjectData;
  ix: IProjectDataFile;
  nkadr: Integer;
  clcarr: TArray<Byte>;
  pin, pout: PByte;
  I: Integer;
begin
//  FRamXml.OwnerDocument.SaveToFile(ExtractFilePath(ParamStr(0))+'RamData.xml');
  inc(FcntKadr, nk);
  nkadr := FFromKadr + FcntKadr;
  if Supports(GlobalCore, IProjectDataFile, ix) then
  begin
    ix.SaveRamData(FAbstractDevice as IDevice, FAdr, FRamXml, pData, FRecSize * nk, FRecSize * nkadr, nkadr,
                    FFromTime + (2.097152 * nkadr)/(24*3600));
    if CreateClcFile then
      with TXMLDataSet(IclcDaraSet.DataSet) do
      begin
        SetLength(clcarr, CalcDataLen * nk);
        pin := pData;
        pout := @clcarr[0];
        for I := 0 to nk - 1 do
        begin
          CalcData(pin, pout);
          inc(pin, FRecSize);
          inc(pout, CalcDataLen);
        end;
        ClcData.Write(CalcDataLen * nk, clcarr, -1, False);
      end;
  end
  else if Supports(GlobalCore, IProjectData, ip) then
  begin
    TPars.SetData(FRamXml, pData);
    FAbstractDevice.FExeMetr.Execute(T_RAM, FAdr);
    ip.SaveRamData(FAbstractDevice as IDevice, FAdr, FRamXml, FRecSize * nkadr, nkadr, FFromTime + 2.097152 * nkadr, FModulID);
  end;
end;

procedure TReadRam.EndExecute;
// var
//  pdb: IProjectDBData;
var
  ix: IProjectDataFile;
begin
//  if Supports(GlobalCore, IProjectDBData, pdb) then pdb.CommitTrans;
  if Supports(GlobalCore, IProjectDataFile, ix) then
    ix.SaveEnd(FRamXml);
  IclcDaraSet := nil;
  with FAbstractDevice do
  try
    S_Status := FOldStatus;
    ConnectUnlock;
    if IsOldClose then
      ConnectClose;
  finally
    if Assigned(FReadRamEvent) then
      FReadRamEvent(FEndReason, FAdr, ProcToEnd);
  end;
end;

procedure TReadRam.Execute(const binFile: string; FromKadr, ToKadr: Integer; ReadToFF: Boolean;
                FastSpeed, Adr: Integer; evInfoRead: TReadRamEvent; ModulID: integer; PacketLen: Integer = 0; grade:Integer=1);
// var
//  pdb: IProjectDBData;
begin
  FBeginTime := Now;
//  if not Supports(GlobalCore, IProjectDBData, pdb) then raise EReadRamException.Create('Error IProjectDBData not supports');
  with FAbstractDevice do
  begin
    CheckStatus([dsPartReady, dsReady]);
    CheckConnect;
    CheckLocked;

    FModulID := ModulID;
    FFlagTerminate := False;
    FReadRamEvent := evInfoRead;
    Fgrade := grade;
    FPacketLen := PacketLen div Fgrade;
    FAdr := Adr;
    FFromKadr := FromKadr;
    FFlagReadToFF := ReadToFF;
    FFastSpeed := FastSpeed;
    FBinFile := binFile;

    FRamXml := FindRam(FMetaDataInfo.Info, Adr);
    //ParserData := TPars.FindParserData(FRamXml);
    if CreateClcFile then
    begin
      GFileDataFactory.ConstructFileName(FRamXml);
      TXMLDataSet.CreateNew(FRamXml, IclcDaraSet);
      TXMLDataSet(IclcDaraSet.DataSet).XMLSection;
    end;

   // FRamXml.OwnerDocument.SaveToFile(ExtractFilePath(ParamStr(0))+'CalipTst1.xml');

    if not Assigned(FRamXml) or not FRamXml.HasAttribute(AT_SIZE) then
      raise EReadRamException.CreateFmt(RS_NoRamMeta, [FAdr]);
    FRecSize := FRamXml.Attributes[AT_SIZE];
    if FRecSize = 0 then
      raise EReadRamException.CreateFmt(RS_NoRamMetaRecSize, [FAdr]);
    { TODO : AT_RAMSIZE = int32
      надо сделать счет по БЛОКАМ SD КАРТ (512 байт = 0х200)
      0х42 0000 = 0x00002100 блоков 8ГБт = 0x0100 0000 блоков}
    if not FRamXml.HasAttribute(AT_RAMSIZE) then
     begin
      if FRamXml.HasAttribute(AT_SSD) then
       begin
        IsSSD := true;
        if Fgrade <> 512 then  raise EReadRamException.CreateFmt('Sector Size 512 <> %d', [Fgrade]);
        FRamSize := FRamXml.Attributes[AT_SSD]*512;
       end
       else FRamSize := MAX_RAM//     else raise EReadRamException.Create(RS_NoRamSize)
     end
    else if FRamXml.Attributes[AT_RAMSIZE] = 5 then
      FRamSize := MAX_RAM
    else
      FRamSize := FRamXml.Attributes[AT_RAMSIZE] * 1024 * 1024;

//  if not FRamXml.ParentNode.HasAttribute(AT_KOEF_TIME) then FKoefTime := 1
//   else raise EReadRamException.CreateFmt(RS_NoRamMetaK, [FAdr])
//  else FKoefTime := FRamXml.ParentNode.Attributes[AT_KOEF_TIME];
//  if FKoefTime <= 0 then raise EReadRamException.CreateFmt(RS_NoRamMetaBadK, [FAdr, FKoefTime]);
//  if (Length(RAMAddrs) < 1) then raise EReadRamException.Create(RS_NoAdr);
  { TODO : Get Ram Info from DB }
//  FRAMInfo := FAbstractDevice.GetRamReadInfo.Get();
//  if (FRAMInfo.ChildNodes.Count <= 0) or not FRAMInfo.ChildNodes[0].HasAttribute(AT_ADDR) then raise EReadRamException.Create(RS_NoXml);
//  if not FRAMInfo.HasAttribute(AT_START_TIME) or
//     not FRAMInfo.HasAttribute(AT_DELAY_TIME) then raise EReadRamException.CreateFmt(RS_NoRamMetaTime, [FAdr]);
//  FStartDate := StrToDateTime(FRAMInfo.Attributes[AT_START_TIME]);
//  FDelayTime := MyStrToTime(FRAMInfo.Attributes[AT_DELAY_TIME]);


    FFromTime := (GContainer as IProjectOptions).DelayStart;
//    FFromTime := FromTime;
//    FToTime := ToTime;
//    FFromKadr := FFromAdr div FRecSize;//, FcntKadr: Integer;
    FFromAdr := Uint64(FFromKadr) * Uint64(FRecSize) div Fgrade;
    if ToKadr = 0 then
      FToAdr := FRamSize div Fgrade
    else //3 ffff c000
     begin
      FToAdr := Uint64(ToKadr) * Uint64(FRecSize) div Fgrade;;
     end;

    FcntKadr := 0;



//    pdb.SimpleSQL('UPDATE Modul SET FromAdr=:p1, FromKadr=:p2, FromTime=:p3 WHERE id = :p4', [FFromAdr, FFromKadr, FFromTime, FModulID]);
//
//
//                                     'FromAdr INT,'+
//                                      'ToAdr INT,'+
//                                      'FromKadr INT,'+
//                                      'ToKadr INT,'+
//                                      'FromTime TIMESTAMP,'+
//                                      'ToTime TIMESTAMP,'+
//    Fifo.Reset;
    SetLength(Fifo, 0);

    FOldStatus := S_Status;
    try
      S_Status := dsReadRam;
      ConnectLock;
      IsOldClose := not ConnectOpen();
    except
      EndExecute;
      raise;
    end;
  end;
//  pdb.BeginTrans;
end;

function TReadRam.GetCreateClcFile: Boolean;
begin
  Result := FCreateClcFile;
end;

{procedure TReadRam.CheckAndInitByAdr(Adr: Integer; MaxRam: Integer = 0; DefK: Double = 0; FromToAval: Boolean = True);
begin
  // проверка xml информации по чтению памяти
  FAdr := Adr;

  FRamXml := FindRam(FRAMInfo, FAdr);

  if not Assigned(FRamXml) or not FRamXml.HasAttribute(AT_SIZE) then raise EReadRamException.CreateFmt(RS_NoRamMeta, [FAdr]);
  FRecSize := FRamXml.Attributes[AT_SIZE];
  if FRecSize = 0 then raise EReadRamException.CreateFmt(RS_NoRamMetaRecSize, [FAdr]);

  if not FRamXml.HasAttribute(AT_RAMSIZE) then
   if MaxRam > 0 then FRamSize := MaxRam
   else raise EReadRamException.Create(RS_NoRamSize)
  else FRamSize := FRamXml.Attributes[AT_RAMSIZE] * 1024 * 1024;

  if not FRamXml.ParentNode.HasAttribute(AT_KOEF_TIME) then
   if DefK > 0 then FKoefTime := DefK
   else raise EReadRamException.CreateFmt(RS_NoRamMetaK, [FAdr])
  else FKoefTime := FRamXml.ParentNode.Attributes[AT_KOEF_TIME];

  if FKoefTime <= 0 then raise EReadRamException.CreateFmt(RS_NoRamMetaBadK, [FAdr, FKoefTime]);

//  FFileRam := FAbstractDevice.GetRamDir + FRamXml.ParentNode.NodeName+'.bin';

  // конвертируем время в адреса памяти RAM
  if (FFromTime = 0) and (FToTime = 0) then
   begin
    FFromAdr := 0;
    FToAdr := FRamSize;
   end
  else if FromToAval then
   begin
    // адреса в памяти НЕ НОМЕР ЗАПИСИ !!!
    FFromAdr := TimeToAdr(FFromTime, FKoefTime, FRecSize, FStartDate, FDelayTime);
    FToAdr := TimeToAdr(FToTime, FKoefTime, FRecSize, FStartDate, FDelayTime);
    if ((FFromAdr<0) and (FToAdr <= 0)) or ((FFromAdr >= FRamSize) and (FToAdr >= FRamSize)) then
       raise EReadRamException.CreateFmt(RS_BadFromToTime,
       [FAdr, DateTimeToStr(FStartDate), MyTimeToStr(FDelayTime), DateTimeToStr(FFromTime), FFromAdr, DateTimeToStr(FToTime), FToAdr]);
    if FToAdr >= FRamSize then FToAdr := FRamSize-1;
    if FFromAdr < 0 then FFromAdr := 0;
   end
  else raise EReadRamException.CreateFmt(RS_NotAvalFromToTime, [FAdr]);

  FFromTimeAdr := AdrToTime(FFromAdr, FKoefTime, FRecSize, FStartDate, FDelayTime);
  FToTimeAdr := AdrToTime(FToAdr, FKoefTime, FRecSize, FStartDate, FDelayTime);
end;  }

function TReadRam.ProcToEnd: TStatistic;
var
  Spd: double;
  cnt: Integer;
begin
  cnt := FToAdr - FFromAdr;
  Result.NRead := FCurAdr - FFromAdr;
  Result.TimeFromBegin := Now - FBeginTime;
  if cnt > 0 then
    Result.ProcRun := Result.NRead / cnt * 100;
  // speed
  Spd := Result.NRead / Result.TimeFromBegin;
  Result.Speed := Spd * Fgrade / 1024 / 1024 / 24 / 3600; // MB/sec
  if Spd > 0 then
    Result.TimeToEnd := (cnt - Result.NRead) / Spd
  else
    Result.TimeToEnd := 0;
end;

procedure TReadRam.SetCreateClcFile(const Value: Boolean);
begin
  FCreateClcFile := Value;
end;

//procedure TReadRam.Release;
//begin
//  FAcquire := False;
//end;

function TReadRam.CheckZerroes(p: PByte; cnt: Cardinal; out ZBegin: Cardinal): Boolean;
 var
  pdw: PDword;
  n: Cardinal;
begin
  /////
  //Exit(False);
  ////
  PByte(pdw) := p + cnt;
  n := ZPOROG div 4;
  // 512 bytes test
  repeat
   Dec(pdw);
   Dec(n);
   if not ((pdw^ = 0) or (pdw^ = $FFFFFFFF)) then Exit(False);
  until n = 0;
 // find last no z
  Result := True;
  n := (cnt - ZPOROG) div 4;
  repeat
   Dec(pdw);
   Dec(n);
   if not ((pdw^ = 0) or (pdw^ = $FFFFFFFF)) then Break
//   if (pdw^ <> 0)   then Break;
  until n = 0;
  Inc(pdw); // первый нулевой указатель
  ZBegin := PByte(pdw) - p;
end;


function TReadRam.TestFF(P: PByte; n: Integer): Boolean;
var
  i: Integer;
begin
  for i := 0 to n - 1 do
    if P[i] <> $FF then
      Exit(False);
  Result := True;
end;

procedure TReadRam.WriteToBD;
  {$J+}
const
  t: Cardinal = 0;
  {$J-}
var
  cnt: Integer; // Length(Fifo) mod FRecSize * FRecSize
begin
  if FRecSize > 0 then
    while Length(Fifo) >= FRecSize {Fifo.pop(ptr, FRecSize)} do
      try
        cnt := Length(Fifo) div FRecSize;
        DoSetData(@Fifo[0], cnt); /// восстановить
        Delete(Fifo, 0, cnt * FRecSize);
        if ((GetTickCount - t) > 1000) then
        begin
          t := GetTickCount;
          if Assigned(FReadRamEvent) then
            FReadRamEvent(carOk, FAdr, ProcToEnd);
        end;
      except
        on e: Exception do
          TDebug.DoException(e, False);
      end;
  if FFlagEndRead then
  begin
    FFlagEndRead := False;
    EndExecute;
  end;
end;

procedure TReadRam.Terminate(Res: TResultEvent);
begin
  FFlagTerminate := True;
  FFlagEndRead := True;
  FEndReason := carTerminate;
  //Fevent.SetEvent;
  WriteToBD;
  if Assigned(Res) then
      Res(True);
end;

{$ENDREGION  TAbstractReadRam}

{ TRAMEnumerator }
{$REGION  'TRAMEnumerator - все процедуры и функции'}
{constructor TRAMEnumerator.Create(adr: Integer; ARAMInfo: IRAMInfo);
begin
  inherited Create;
  Fadr := adr;
  FRAMInfo := ARAMInfo;
  Froot := FindRam(ARAMInfo, Fadr);
  if not Assigned(Froot) then
     raise ERAMEnumeratorException.Createfmt(RS_NoRamInfo,[FAdr]);
  if not (Froot.HasAttribute(AT_TO_TIME) and Froot.HasAttribute(AT_FROM_TIME) and Froot.HasAttribute(AT_FROM_ADR) and Froot.HasAttribute(AT_TO_ADR) and Froot.HasAttribute(AT_RAM_FILE)) then
     raise ERAMEnumeratorException.CreateFmt(RS_NoRamAttr, [FAdr, AT_TO_TIME, AT_FROM_TIME, AT_FROM_ADR, AT_TO_ADR, AT_RAM_FILE]);
  if not FileExists(Froot.Attributes[AT_RAM_FILE]) then
     raise ERAMEnumeratorException.CreateFmt(RS_NoRamFile, [FAdr, Froot.Attributes[AT_RAM_FILE]]);
  FStream := TFileStream.Create(Froot.Attributes[AT_RAM_FILE], fmOpenRead or fmShareDenyWrite);
  FStream.Position := 0;
end;

function TRAMEnumerator.Current: IRAMData;
begin
  if (FAdr < 16) or (FAdr = 101) then TPars.SetData(Froot, @Fbuf[0])
  else TPars.SetPSK(Froot, @Fbuf[0]);
  Result := Froot;
end;

destructor TRAMEnumerator.Destroy;
begin
  if Assigned(FStream) then FreeAndNil(FStream);
  inherited;
end;

function TRAMEnumerator.GetRamReadInfo: IRAMInfo;
begin
  Result := FRoot;//FindRam(FRAMInfo, Fadr);
end;

function TRAMEnumerator.CountKadr: Integer;
begin
  Result := FStream.Size div Froot.Attributes[AT_SIZE];
end;

function TRAMEnumerator.GotoKadr(Kadr: Integer): Boolean;
begin
  FStream.Position := Froot.Attributes[AT_SIZE] * Kadr;
  Result := FStream.Read(Fbuf[0], Froot.Attributes[AT_SIZE]) = Froot.Attributes[AT_SIZE];
end;

function TRAMEnumerator.MoveNext: Boolean;
begin
  Result := FStream.Read(Fbuf[0], Froot.Attributes[AT_SIZE]) = Froot.Attributes[AT_SIZE];
end;     }
 {$ENDREGION  TRAMEnumerator}

{ TCycle }
{$REGION  'TCycle TCycleEx - все процедуры и функции'}
constructor TCycle.Create(const Controller: IInterface);
begin
  inherited Create(Controller);
  FTimer := TTimer.Create(nil);
  FTimer.OnTimer := OnTimer;
  FTimer.Enabled := False;
  TDevice(Controller).FCyclePeriod := 2097;
end;

destructor TCycle.Destroy;
begin
  FTimer.OnTimer := nil;
  FTimer.Free;
  inherited;
end;

procedure TCycle.DoCycle;
begin
  if not FlagNeedStop then
    (Controller as IDataDevice).ReadWork(nil, FStdOnly);
end;

function TCycle.GetCycle: Boolean;
begin
  Result := FTimer.Enabled;
end;

function TCycle.GetPeriod: Integer;
begin
  Result := TDevice(Controller).CyclePeriod;
end;

procedure TCycle.OnTimer(Sender: TObject);
begin
  if FlagNeedStop then
  begin
    FTimer.Enabled := False;
    TDevice(Controller).ConnectClose;
  end
  else
    DoCycle;
end;

procedure TCycle.SetCycle(const Value: Boolean);
var
  IsOldClose: Boolean;
//  ix: IProjectDataFile;
begin
  IsOldClose := False;
  if Value = FTimer.Enabled then
    Exit;
  with TDevice(Controller) do
    if Value then
    begin
      CheckStatus([dsPartReady, dsReady]);
      FOldStatus := S_Status;
      CheckConnect;
      CheckLocked;
      try
        S_Status := dsData;
        ConnectLock;
        FTimer.Interval := TDevice(Controller).CyclePeriod;
        FlagNeedStop := False;
        IsOldClose := not ConnectOpen();
        DoCycle;
        FTimer.Enabled := True;
      except
        FTimer.Enabled := False;
        S_Status := FOldStatus;
        ConnectUnlock;
        if IsOldClose then
          ConnectClose;
        raise;
      end;
    end
    else
    begin
      if (Controller is TAbstractDevice) then
        (Controller as TAbstractDevice).EndInfo;
//
//     if Supports(GlobalCore, IProjectDataFile, ix)
//        and (Controller is TAbstractDevice)
//        and Assigned((Controller as TAbstractDevice).FMetaDataInfo.Info) then
//      FindAllWorks(TAbstractDevice(Controller).FMetaDataInfo.Info, procedure(wrk: IXMLNode; Adr: Byte; const name: string)
//      begin
//        ix.SaveEnd(wrk);
//      end);
      FlagNeedStop := True;
      S_Status := FOldStatus;
      ConnectUnlock;
   /// TEST
  //    FTimer.Interval := 1;
   /// TEST
    FTimer.Enabled := False;
    TDevice(Controller).ConnectClose;
   /// TEST
    end;
end;

procedure TCycle.SetPeriod(const Value: Integer);
begin
  FTimer.Interval := Value;
  TDevice(Controller).CyclePeriod := Value;
end;

{ TCycleEx }

function TCycleEx.GetStdOnly: Boolean;
begin
  Result := FStdOnly
end;

procedure TCycleEx.SetStdOnly(const Value: Boolean);
begin
  FStdOnly := Value;
end;
{$ENDREGION}

{ TAbstractActionsDev }

{constructor TAbstractActionsDev.Create(const Controller: IInterface);
begin
  inherited Create(Controller);
  FBind := TBind.Create(Self);
end;}

{ TAbstractNetConnectIO }

class function TAbstractNetConnectIO.Enum: TArray<string>;
var
  c: IConnectIO;
begin
  for c in (GlobalCore as IConnectIOEnum) do
    if (c as IManagItem).GetComponent.ClassName = ClassName then
      CArray.Add<string>(Result, c.ConnectInfo);
end;

class function TAbstractNetConnectIO.ExtractHost(const Info: string): string;
var
  a: TArray<string>;
begin
  Result := '92.168.43.5';
  a := Info.Split([':']);
  if Length(a) = 0 then
    Exit;
  Result := a[0];
end;

class function TAbstractNetConnectIO.ExtractPort(const Info: string): Word;
var
  a: TArray<string>;
begin
  Result := 5000;
  a := Info.Split([':']);
  if Length(a) = 0 then
    Exit;
  if Length(a) >= 2 then
    Result := a[1].ToInteger()
end;

initialization
  RegisterClass(TComConnectIO);
  TRegister.AddType<TComConnectIO, IConnectIO>.LiveTime(ltSingletonNamed);

finalization
  GContainer.RemoveModel<TComConnectIO>;

end.


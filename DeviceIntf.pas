unit DeviceIntf;

interface

uses Container, tools,
     winapi.Windows, SysUtils, XMLIntf, Classes, RootIntf, System.TypInfo;//, Controls;

type
  IRAMInfo = IXMLNode;
  IRAMData = IXMLNode;
  IEEPData = IXMLNode;
  TInfoEventRes = TDeviceMetaData;
  TInfoEvent = procedure (Res: TInfoEventRes) of object;
  TCheckInfoEvent = procedure (adr: Integer; tst: IXMLNode) of object;
  // события считывания данных (режим инвормации (контроль))
  // Work: IXMLInfo - ветвь Info: IXMLInfo c заполненными полями текущих данных в режиме контроля
  TWorkEventRes = record
    DevAdr: Integer; Work: IXMLInfo;
  end;
//  TSubDevData = record
//     Data: Pointer; DataSize: integer;
//  end;
  TEepromEventRes = record
    DevAdr: Integer;
    eep: IXMLInfo;
  end;
  TWorkEvent = procedure (Res: TWorkEventRes) of object;
  TEepromEventRef = reference to procedure (Res: TEepromEventRes);
  // событие обновления XML информации RAM
  TRamEvent = procedure (DevAdr: Integer; RamInfo: IRAMInfo) of object;
  // события о состоянии считывания ОЗУ
  //                        одиночная ошибка  невозможно считать  конец    прервано      конец но есть еще устройства
                                                                                       // для чтения с другими адресами
//  EnumReadRam = (eirReadOk, eirReadErrSector,     eirCantRead,    eirEnd,  eirTerminate);//,       eirEndDev);
  // ProcToEnd - % до окончания считывания для текущего устройства
  TReadRamEvent = procedure (EnumRR: EnumCopyAsyncRun; DevAdr: Integer; Statistic: TStatistic) of object;
  // функция обратного вызова при вызове функции построения списка доступных устройств обмена а внешним миром
  TGetConnectIOCB = reference to procedure (ConnectID: Integer; const ConnectName, ConnectInfo: string);

  TResultEvent = procedure (Res: Boolean) of object;

  TResultEventRef = reference to procedure (Res: Boolean);

  // глобальный объект TDebug плугинов рассылающий зарегистрированные исключения
  // обработка не TForm исключений, системных и в событиях (таймер ком порты)
  // и исключений с отладочной информацией от JEDI
  TAsyncException = procedure (const ClassName, msg, StackTrace: WideString) of object;

{$REGION  'DevCom - все интерфейсы'}
//интерфейс устройство умеющее подключаться к IConnectIO
  IDevice = interface;
  TDeviceArray = TArray<IDevice>;
  TReceiveDataRef = reference to procedure(Data: Pointer; DataSize: integer);

  TConnectIOStatus =(iosOpen, iosError, iosLock, icAdding, icUserAdding);

  TSetConnectIOStatus = set of TConnectIOStatus;
  ///	<summary>
  ///	  интерфейс обмена данными с внешним миром. Подключение устройств: может
  ///	  быть несколько IDevice<br />
  ///	</summary>
  IConnectIO = interface(IManagItem)
  ['{8AC3328B-BF3D-44EF-9996-EE882E5DBDE2}']
    procedure SetConnectInfo(const Value: string);
    function GetConnectInfo: string;
    procedure Open;
    procedure Close;
    function IsOpen: Boolean;
    ///	<remarks>
    ///	  Время ожиданиа ответа на запрос По умолчанию - 500 мс (таймаут по
    ///	  умолчению)
    ///	</remarks>
    procedure SetWait(Value: integer);
    function GetWait: integer;
//  ситуация если на одном порту наземка в состоянии циклоопроса и СП xотят поставить на задержку
//  или в менеджере есть порты с одинаковым именем
    { TODO : видимо не нужно для ТСР }
    function Locked(const User): Boolean;
    procedure Lock(const User);
    procedure Unlock(const User);

    procedure CheckOpen;
    procedure SendROW(Data: Pointer; Cnt: Integer; Event: TReceiveDataRef = nil; WaitTime: Integer = -1);

    function GetStatus: TSetConnectIOStatus;
    procedure SetStatus(Value: TSetConnectIOStatus);

    property ConnectInfo: string read GetConnectInfo write SetConnectInfo;
    property Wait: integer read GetWait write SetWait;
    property Status: TSetConnectIOStatus read GetStatus write SetStatus;
  end;
  ///	<summary>
  ///	  реализация IConnectIO для КОМПОРТА
  ///	</summary>
  IComPortConnectIO = interface(IConnectIO)
  ['{617A30B1-F76F-4583-BAB5-80794947CEA2}']
   function DefaultSpeed: Integer;
  end;
  ///	<summary>
  ///	  реализация IConnectIO для TCP
  ///	</summary>
  INetConnectIO = interface(IConnectIO)
  ['{F7222E26-D257-4288-802C-EDAC8ED0EE9E}']
  end;
  IRestConnectIO = interface(IConnectIO)
  ['{C31C36BB-C528-496B-9DB5-FE3DFF6F2404}']
  end;
  ///	<summary>
  ///	  реализация IConnectIO для UDP
  ///	</summary>
  IUDPBinConnectIO=interface(IConnectIO)
  ['{229C0035-2B30-42C8-ADD1-E9FDB93B812C}']
  end;
  ///	<summary>
  ///	  реализация IConnectIO для чтения памяти с microSD Диска
  ///	</summary>
  ImicroSDConnectIO = interface(IConnectIO)
  ['{CF7E43AF-87A0-4F9C-8739-87FFBCB1F5E8}']
  end;
//  IFileConnectIO = interface(IConnectIO)
//  ['{B7BCD1DB-8068-426E-BCE2-80E88D943B25}']
//  end;

  TReceiveUDPRef = reference to procedure(const Data: string; status: integer);

  ///	<summary>
  ///	  реализация IConnectIO для UAKI
  ///	</summary>
  IUDPConnectIO = interface(IConnectIO)
  ['{0F0AC653-2AC1-47EB-8214-7806F7376666}']
    procedure Send(const cmd: string; ev: TReceiveUDPRef = nil; TimeOut: Integer = -1);
  end;
  ///	<summary>
  ///	  реализация IConnectIO для WiFi
  ///	</summary>
  IWlanConnectIO = interface(INetConnectIO)
  ['{C97BE14F-BD9E-4B00-A213-0D6CB2890B61}']
  end;

  TDeviceStatus = (
    ///	<summary>
    ///	  Метаданные не инициализированны
    ///	</summary>
    dsNoInit,
    ///	<summary>
    ///	  Есть готовые и не готовые модули
    ///	</summary>
    dsPartReady,
    ///	<summary>
    ///	  прибор готов
    ///	</summary>
    dsReady,
    ///	<summary>
    ///	  занят чтением (режим информации)
    ///	</summary>
    dsData,
    ///	<summary>
    ///	  постановка на задержку
    ///	</summary>
    dsDelay,
    ///	<summary>
    ///	  чтение памяти
    ///	</summary>
    dsReadRam
  );
  TSetDeviceStatus = set of TDeviceStatus;
  ///	<summary>
  ///	  интерфейс устройство умеющее подключаться к IConnectIO
  ///	</summary>
  IDevice = interface(IManagItem)
  ['{D4F8618E-42CE-4893-9EBB-75E178162038}']
    procedure SetConnect(AIConnectIO: IConnectIO);
    function GetConnect: IConnectIO;
    function GetNamesArray(Index: Integer): string;
    function AddressArrayToNames(const Addrs: TAddressArray): string;
//    function GetDeviceName: string;
//    procedure SetDeviceName(const Value: string);
//  Функция по заданным адресам пытается получить IDevice;
    function GetAddrs: TAddressArray;
    function GetStatus: TDeviceStatus;
    function CanClose: Boolean;
    // Установка интерфейса связи с прибором
    property IConnect: IConnectIO read GetConnect write SetConnect;
    property Addrs: TAddressArray read GetAddrs;
    property NamesArray[Index: Integer]: string read GetNamesArray;
    property Status: TDeviceStatus read GetStatus;
//    property Name: string read GetDeviceName write SetDeviceName;
  end;

  TSubDeviceInfo = record
    Typ: set of (
    ///	<summary>
    ///	  может быть только одно устройство
    ///	</summary>
    sdtUniqe,
    ///	<summary>
    ///	  обязательное устройство
    ///	</summary>
    sdtMastExist);
    Category: string;
  end;

//  ISubDeviceData<I, O> = interface
//  ['{A8084EB5-2EC4-48B1-B043-FB17554C7870}']
//    procedure InputData(Data: I);
//    procedure SetData(Value: O);
//  end;

  ISubDevice = interface//(IManagItem)
  ['{D9947F39-BE31-45BC-9F5F-6FAC6CB19FC8}']
    function GetCategory: TSubDeviceInfo;
    function GetCaption: string;
    function GetItemName: string;

    ///	<summary>
    ///	 обмен данными
    ///	</summary>
  //  procedure InputData(Data: Pointer; DataSize: integer);
    ///	<summary>
    ///	 обмен данными
    ///	</summary>
//    procedure SetChild(SubDevice: ISubDevice);
//    function GetAddr: Integer;
//    property Addr: Integer read GetAddr;

    property Category: TSubDeviceInfo read GetCategory;
    property Caption: string read GetCaption;

    property IName: String read GetItemName;
  end;

  ISubDevice<T> = interface(ISubDevice)
  ['{374907BE-F493-465F-B012-2F97AC9FBC7F}']
    function GetData: T;
    property Data: T read GetData;
  end;

  IRootDevice = interface
  ['{3B0C08A9-E077-4F97-AC56-3A064B443C6D}']
    function GetSubDevices: TArray<ISubDevice>;
    function Index(SubDevice: ISubDevice): Integer;
    procedure Remove(Index: Integer);
    function AddOrReplase(SubDeviceType: ModelType): ISubDevice;
    function TryMove(SubDevice: ISubDevice; UpTrueDownFalse: Boolean): Boolean;
  //private
    function GetService: PTypeInfo;
    function GetStructure: TArray<TSubDeviceInfo>;
  ///	<summary>
  ///	 например наследник ISubDevice или IRootDevice
  ///	</summary>
    property Service: PTypeInfo read GetService;
  ///	<summary>
  ///	 например наследник ISubDevice или IRootDevice
  ///	</summary>
    property Structure: TArray<TSubDeviceInfo> read GetStructure;
    property SubDevices: TArray<ISubDevice> read GetSubDevices;
  end;

  ///	<summary>
  ///	  создание устройств пользователем
  ///	</summary>
  { TODO : Register Factory interface }
  IGetDevice = interface
  ['{01465AA3-D6F2-4A6D-941E-016B27BF2AB8}']
   procedure Enum(GetDevicesCB: TGetDevicesCB);
   function  Device(const Addrs: TAddressArray; const DeviceName, ModulesNames: string): IDevice;
 end;

  IGetConnectIO = interface
  ['{A6A71F43-DFF8-4F95-A07D-D023792623F6}']
   procedure Enum(GetConnectIOCB: TGetConnectIOCB);
   function  ConnectIO(ConnectID: Integer): IConnectIO;

   function IsManualCreate(ConnectID: Integer): Boolean;
   function GetConnectInfo(ConnectID: Integer): TArray<string>;
 end;

  ///	<summary>
  ///	  Устройство может находить метаданные, читать, форматировать, данные
  ///	</summary>
  IDataDevice = interface(IDevice)
  ['{717D72A7-CF04-4AE6-9E14-BD67E9FC3949}']
    ///	<remarks>
    ///	  <para>
    ///	    чтение метаданных устройств,
    ///	  </para>
    ///	  <para>
    ///	    1. сначала из проекта БД
    ///	  </para>
    ///	  <para>
    ///	    2. затем из ВВ с обновлением БД 
    ///	  </para>
    ///	  <para>
    ///	    (устар.) нужно знать адреса устройств или выбрать все 14 возможных
    ///	    или старый формат устройств - адреса начиная сo 100 для старых
    ///	    устройств установка связи необязательна<br /> ??? если задан
    ///	    PathToDataDir и нет связи то считывание метаданных из ram.xml файла
    ///	    на диске для новых устройств ???
    ///	  </para>
    ///	</remarks>
    procedure InitMetaData(ev: TInfoEvent);
    ///	<summary>
    ///	  <para>
    ///	    из БД
    ///	  </para>
    ///	  <para>
    ///	    (устар.) результат последнего вызова  InitMetaData  
    ///	  </para>
    ///	</summary>
    function GetMetaData: TDeviceMetaData;
    ///	<remarks>
    ///	  считывание данных (контроль) StdOnly: Boolean = True - считывается
    ///	  только текущее время и состояние устройств если устройство в ждущем
    ///	  режиме то оно не выходит из него StdOnly: Boolean = false - если
    ///	  устройство в ждущем режиме ВЫХОДИТ из него Для байтового протокола
    ///	  StdOnly неиспользуется
    ///	</remarks>
    procedure ReadWork(ev: TWorkEvent; StdOnly: Boolean = false);
  end;

  IEepromDevice = interface(IDataDevice)
  ['{887C1E42-94B0-4E7C-83A0-1AF1DC43AD12}']
    ///	<remarks>
    ///	  считывание EEPROM
    ///	</remarks>
    procedure ReadEeprom(Addr: Integer; ev: TEepromEventRef);
    ///	<remarks>
    ///	  запись для одного модуля
    ///	</remarks>
    procedure WriteEeprom(Addr: Integer; ev: TResultEventRef; section: Integer = -1);
  end;

  TSetDelayRes = record
   Res: Boolean;
   Delay, WorkTime: TTime;
   SetTime: TDateTime;
  end;
//  TNullTime = ^TTime;

  TSetDelayEvent = procedure (Res: TSetDelayRes) of object;

  // Устройство может вставать на задержку

  ///	<remarks>
  ///	  постановка всех устройств на задержку<br />     TSetDelayEvent =
  ///	  procedure (Res: Boolean; Delay: TTime; SetTime: TDateTime)<br />    
  ///	  Res-true если поставлен прибор на задержку<br />     Delay возвращает
  ///	  реальное время задержки может быть отличным от входного; SetTime: время
  ///	  постановки на задержку)<br />     WorkTime-время каботы прибора может
  ///	  быть отличным от входного;
  ///	</remarks>
  IDelayDevice = interface(IDevice)
  ['{E291C1CD-4943-4D1F-B207-0ECCE8889AF9}']
    procedure SetDelay(StartTime: TDateTime; WorkTime: TTime; ResultEvent: TSetDelayEvent);
    procedure SetDelayRTC(StartTime: TDateTime; ResultEvent: TSetDelayEvent);
  end;

  // создание интерфейсов для работы с памятью
//  IRamReadInfo = interface;
//  IReadRamDevice = interface;
//  IRAMDataEnumerator = interface;
  // создание интерфейсов для работы с памятью
//  IRamDevice = interface(IDevice)
//    ['{27423E99-7C55-4BE4-A7AC-D827EA1A9687}']
    // Установка директории считвания и манипуляции данными ОЗУ, директория должна существовать
    // после установки пути имеется возможность создания IRamReadInfo
    // имеется возможность создания IReadDeviceRAM
//    procedure RamDataPath(const PathToRamDataDir: WideString);
    // чтение данных памяти устройста с диска, для обработки, отображения и т.д.
//    function GetRamDataEnumerator(adr: Integer): IRAMDataEnumerator;
    // для дочитывания данных и создания, чтения информации для считывания с диска,
//    function GetRamReadInfo(): IRamReadInfo;
    // считывание памяти из устройства на диск
//    function GetReadDeviceRam(): IReadRamDevice;
//  end;

  ///	<summary>
  ///	  для дочитывания данных и создания, чтения информации (метаданных) для
  ///	  считывания с диска,<br />время жизни - 0 для старых и до прихода
  ///	  UpdateTimeSyncEvent для новых  (ICom as IRamReadInfo)
  ///	</summary>
//  IRamReadInfo = interface
//  ['{2E5B198E-CFD5-4E08-BCA3-7B81CCDE5B87}']
    // создает новый пустой документ (сохраняется в PathToReadRamDir ram.xml) если был старый то данные о считывании будут потеряны
//    function New(TimeSart: TDateTime; TimeDelay: TTime): IRAMInfo;
    // считывает с диска IRAMInfo и
    // объединяет уже прочитанные данные с информацией о новых данных для чтения
    // читает информацию о времени из устройств находит поправки для синхронизации времени (изменения сохраняются на диск)
    // асинхронный метод
//    function Update(Info: IXMLInfo; UpdateEvent: TRamEvent = nil): IRAMInfo;
    // считывает с диска IRAMInfo
//    function Get(): IRAMInfo;
//  end;

  // считывание памяти на диск
  IReadRamDevice = interface
  ['{30BC6538-48E3-4B7F-9682-22EBB0FA5489}']
    // всякие настройки для чтения ОЗУ

    // private
//    function GetFromTime: TDateTime;
//    function GetToTime: TDateTime;
//    procedure SetReadToFF(Flag: Boolean);
//    function GetReadToFF: Boolean;
//    procedure SetFastSpeed(Flag: Boolean);
//    function GetFastSpeed: Boolean;

    function GetCreateClcFile: Boolean;
    procedure SetCreateClcFile(const Value: Boolean);
    // public
    // абсолютное время. По умолчанию - вся память (FromTime=ToTime=0)
//    procedure SetReadTime(FromTime, ToTime: TDateTime);
    // асинхронный метод читает, перечитывает и сохраняет бинарные файлы на диск
    // обновляет в процессе на диске IRAMInfo создает в PathToReadRamDir xxxxxxx.bin для каждого устройства
    procedure Execute(const binFile: string; FromKadr, ToKadr: Integer; ReadToFF: Boolean; FastSpeed, Adr: Integer; evInfoRead: TReadRamEvent; ModulID: integer; PacketLen: Integer = 0; grade:Integer=1);
    // прерывает длительный асинхронный метод Execute
    procedure Terminate(Res: TResultEvent = nil);

    // Флаг прекратить чтение если идут FF По умолчанию - да
//    property ReadToFF: Boolean read GetReadToFF write SetReadToFF;
    // Флаг скорость 0.5 МБод По умолчанию - да
//    property FastSpeed: Boolean read GetFastSpeed write SetFastSpeed;
//    property FromTime: TDateTime read GetFromTime;
    property CreateClcFile: Boolean read GetCreateClcFile write SetCreateClcFile;
  end;

  TRunEvent = reference to procedure (ProcToEnd: Double);

  IFileDialog = interface
  ['{E80BBDD8-3127-4F7B-94BD-CC89DE00EE55}']
    function GetFilters: string;
//    procedure Execute(const FileName: string; FilterIndex: Integer; event: TRunEvent);
    property Filters: string read GetFilters;
  end;
  // для памяти прибора из файла
  IRamImport = interface(IFileDialog)
  ['{C9ACE1A0-E1AA-4751-9128-99EC616DDBD2}']
    procedure Import(const FileName: string; FilterIndex: Integer;
                      FromKadr, ToKadr: Integer; ReadToFF: Boolean;
                      Adr: Integer; evInfoRead: TReadRamEvent; ModulID: integer);
    // прерывает длительный асинхронный метод Execute
//    procedure Terminate(Res: TResultEvent = nil);
  end;
  // для памяти прибора в файл
//  IExport = interface(IFileDialog)
//  ['{D56A202E-0456-409A-AAE5-2338EF22B01B}']
//  end;

  // для считывания с диска, - не нужен будут запросы в базу данных
//  IRAMDataEnumerator = interface
//  ['{AE7B33FF-FBA5-49C3-89F9-64CA847EA98A}']
//    function GetRamReadInfo(): IRAMInfo;
//    function Current(): IRAMData;
//    function MoveNext(): Boolean;
//    function GotoKadr(Kadr: Integer): Boolean;
//    function CountKadr(): Integer;
//  end;

// Вспомогательные интерфейсы

  ILowLevelDeviceIO = interface(IDevice)
  ['{3754E9DF-B976-47D0-A25A-486041E7CCDB}']
    procedure SendROW(Data: Pointer; Cnt: Integer; Event: TReceiveDataRef = nil; WaitTime: Integer = -1);
  end;


// включение повышенной скорости новые приборы
  ITurbo = interface(IDevice)
  ['{ED12F5BF-0785-4EC7-A767-08B69AB54893}']
    procedure Turbo(adr: Byte; speed: integer);
  end;

// циклопрос, (Режим информации) новые приборы + усо + глубиромер
  ICycle = interface
  ['{0745B82C-A141-451E-8F3A-F18EB201C9F0}']
    function GetCycle: Boolean;
    procedure SetCycle(const Value: Boolean);
    function GetPeriod: Integer;
    procedure SetPeriod(const Value: Integer);

    property Cycle: Boolean read GetCycle write SetCycle;
    property Period: Integer read GetPeriod write SetPeriod;
  end;
// циклопрос, новые приборы
  ICycleEx = interface(ICycle)
  ['{E62086C4-17E7-424D-9CB9-76F913180285}']
    function GetStdOnly: Boolean;
    procedure SetStdOnly(const Value: Boolean);
    property StdOnly: Boolean read GetStdOnly write SetStdOnly;
  end;

  // Выключение Для байтового протокола
  IStop = interface(IDevice)
  ['{C196F3A4-FF10-4348-98DE-75EDA8F9E175}']
  // Выключение потокового режима
    procedure StopFlow(ResultEvent: TResultEvent = nil);
  // потоковый режим ??
    function IsFlow: Boolean;
  // Выключение прибора
  // procedure PowerOff(ResultEvent: TResultEvent = nil);
  end;

  EnumIOStatus = (iosRx, iosTx, iosTimeOut, iosDebug);
  TIOEvent = procedure (IOStatus: EnumIOStatus; Data: PByteArray; DataSize: Integer) of object;
  TIOEventString = procedure (IOStatus: EnumIOStatus; const Data: string) of object;
  // перехват данных для проверки
  IDebugIO = interface
  ['{584A2F02-C26C-4468-BDDB-143CB52474E3}']
    procedure TimoutPayload(const SData: string; IndData: integer);
    procedure SetIOEvent(const AIOEvent: TIOEvent);
    function GetIOEvent(): TIOEvent;
    procedure SetIOEventString(const AIOEvent: TIOEventString);
    function GetIOEventString(): TIOEventString;
    property IOEvent: TIOEvent read GetIOEvent write SetIOEvent;
    property IOEventString: TIOEventString read GetIOEventString write SetIOEventString;
  end;
{$ENDREGION}



  // Пользовательские интерфейсы
  IConnectIOEnum = interface(IServiceManager<IConnectIO>)
  ['{C8548D8C-B5DC-4040-9090-33AE82786DA6}']
  end;

  IDeviceEnum = interface(IServiceManager<IDevice>)
  ['{5B043A5F-F374-409E-BEAD-028C8E2AF926}']
  end;


implementation

uses System.Bindings.Outputs, RTTI;

initialization
  TValueRefConverterFactory.RegisterConversion(TypeInfo(TSetConnectIOStatus), TypeInfo(string),
  TConverterDescription.Create(procedure(const I: TValue; var O: TValue)
  begin
    O := 'SetConnectIOStatus';
  end, 'SetConnectIOStatusToStr', 'SetConnectIOStatusToStr', '', True, '', nil));

  TValueRefConverterFactory.RegisterConversion(TypeInfo(TDeviceStatus), TypeInfo(string),
  TConverterDescription.Create( procedure(const I: TValue; var O: TValue)
  begin
    O := 'DeviceStatus';
  end, 'DeviceStatusToStr', 'DeviceStatusToStr', '', True, '', nil));
finalization

  TValueRefConverterFactory.UnRegisterConversion('SetConnectIOStatusToStr');
  TValueRefConverterFactory.UnRegisterConversion('DeviceStatusToStr');
end.

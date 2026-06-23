unit tools;

interface

{$INCLUDE global.inc}

uses
  debug_except, System.SyncObjs, System.Math, SysUtils, Xml.XMLIntf, Xml.XMLDoc,
  Xml.xmldom, System.Generics.Collections, System.Generics.Defaults, UITypes,
  System.Classes, Data.DB, RTTI, System.Variants, Winapi.ActiveX, Graphics;

type
  IXMLInfo = IXMLNode;
  // функция обратного вызова при вызове функции построения списка доступных устройств байтного протокола

  TGetDevicesCB = procedure(DevAdr: Integer; const DevNodeName, DevInfo: WideString);

  TAddressArray = TArray<Integer>;
  // событие считывания информаци об устройствах (создается новый XML документ Info: IXMLInfo)
  // addr: TAddressArray - считанные или нет адреса, Exception: TAddressArray- сответствующая адресу ошибка 0-считан -1 - нет

  TDeviceMetaData = record
    ErrAdr: TAddressArray;
    Info: IXMLInfo;
  end;

const
  PRG_TIP_VARIANT = 0;
  PRG_TIP_INT = 1;
  PRG_TIP_REAL = 2;
  PRG_TIP_DATE_TIME = 3;
  PRG_TIP_DATE = 4;
  PRG_TIP_TIME = 5;
  PRG_TIP_BOOL = 6;
  CMD_BOOT = 8;
  CMD_EXIT = $E;
  CMD_WRITE = $F;
  CMD_READ = $D;
  CMD_READ_EE = 5;
// запись EEPROM памяти
  CMD_WRITE_EE = 6;
  CMD_WORK = 7;
  CMD_INFO = 2;
  CMD_READ_RAM = 1;
  CMD_WRITE_RAM = 9;
  CMD_CLEAR_RAM = 10;

  // совместимость с БД для XML проекта
  AT_CAPTION = 'Имя';
  AT_PRIORITY = 'Ptiority';
  AT_OBJ = 'ObjData';
//   Атрибуты
//   Основные ветви метаданных
  T_WRK = 'WRK';
  T_RAM = 'RAM';
  T_EEPROM = 'EEP';
  T_GLU = 'GLU';
  ARR_META: array[0..3] of string = (T_WRK, T_RAM, T_GLU, T_EEPROM);
  // ветви где есть данные DataSet
  ARR_META_RECS: array[0..2] of string = (T_WRK, T_RAM, T_GLU);
  T_MTR = 'Метрология';
  ATTESTAT_ATTR: array[0..12] of string = ('DevName', 'Maker', 'UsedStol', 'Category', 'Room', 'Metrolog', 'kalibrov', 'TIME_ATT', 'NextDate', 'Ready', 'ErrZU', 'ErrAZ', 'ErrAZ5');
  ATTESTAT_CAPTION: array[0..12] of string = ('Прибор', 'Производитель', 'Оборудование', 'Категория', 'Помещение', 'Метролог', 'Калибровал', 'Время аттестации', 'Следующая аттестация', 'Готов', 'Ошибка ЗУ', 'Ошибка Азим', 'Ошибка Азим ЗУ<5');
  AT_FILE_NAME = 'FILE_NAME';
  AT_FILE_CLC = 'FILE_NAME_CLC';
//  свойства прибора
  AT_ADDR = 'ADDR';
  AT_SUB_ADDR = 'SubAdr';
  AT_CHIP = 'CHIP_INDEX';
  AT_INFO = 'INFO';
  AT_PSWD = 'PSWD';
  AT_PSK_BYTE_ADDR = 'PSK_BYTE_ADDR';
  AT_SERIAL = 'SERIAL_NO';
  AT_FROM = 'FROM';
  AT_READED = 'READED';
  AT_WRITED = 'WRITED';
  AT_SPEED = 'COMUNICATION_PROPERTY';   // BIT15:USB  BIT14:SSD BIT7:125Kbt BIT6:500Kbt
  AT_EXT_NP = 'AT_EXT_NP';      // count extra data
  AT_EXT_NP_LEN = 'AT_EXT_NP_LEN'; // len in bytes extra data
  AT_TIMEATT = 'TIME_ATT';
  AT_METROLOG = 'Metrolog';
  AT_DEVNAME = 'DevName';
  AT_DELAYDV = 'DELAY_DEVIDER';
  AT_WORKTIME = 'WORK_TIME_ENABLE';
  AT_DEV_ID = 'DEV_ID'; // для проекта

//  ветви метаданных
  AT_SIZE = 'SIZE';
// добавка по глубине
  AT_ZND = 'ZND';
//  дополнительные свойства (для метрологии, форматирования) модуля, данных
  AT_METR = 'METR';
  ME_ANGLE = 'ANGLE'; // метрология угол
  //ME_MEDIAN = 'MEDIAN'; // метрология медианна
// если массив данных
  AT_ARRAY = 'ARRAY_SIZE'; // число елементов не байт!!!

// ветвь данные
// общие атрибуты
// пока нет AT_ZND AT_METR
//  Ветви
  T_CLC = 'CLC'; //  Ветвь рассчетные данные
  T_DEV = 'DEV'; // Ветвь данных с устройства

// атрибуты
  AT_INDEX = 'INDEX'; // для DEV указатель в массиве сырых данных с устройства
// данные по типу
  AT_TIP = 'TYPE';
// данные извлеченные по AT_INDEX или рассчитанные или указатель на массив
  AT_VALUE = 'VALUE';
// данные с форматированием TRR необязательные атрибуты
//  AT_FMT   = 'VIEW_FMT'; // точность после запятой
  AT_EU = 'EU';  // единицы
  AT_TITLE = 'TITLE'; // единицы
  AT_RLO = 'RANGE_LO'; // диапазон
  AT_RHI = 'RANGE_HI'; // диапазон
  AT_DIGITS = 'DIGITS'; // длинна
  AT_AQURICY = 'AQURICY'; // тoчность
  AT_COLOR = 'COLOR'; //
  AT_WIDTH = 'WIDTH'; //
  AT_DASH = 'DASH'; //
//  AR_TRR_FMT: array [0..3] of string = (AT_FMT, AT_RLO, AT_RHI, AT_EU);

// фильтры для ветвей T_WRK T_RAM таблиц БД по времени кадрам
  AT_DB_SELECT = 'DB_SELECT';

// чтение памяти
  AT_RAMSIZE = 'RAM_SIZE';
  AT_SSD = 'SSD_SIZE';
// PSK чтение памяти
  AT_RAMLP = 'RAM_LO_SPEED_PROTOCOL';
  AT_RAMHP = 'RAM_HI_SPEED_PROTOCOL';
// PSK  протоколы
  AT_SP_HI = 'SP_HI_BYTE';
  AT_WRKP = 'FLOW_PROTOCOL';
  AT_FLOWINTERVAL = 'FLOW_TIMER_INTERVAL';

// Атрибуты считанной памяти
  AT_START_TIME = 'START_TIME';
  AT_DELAY_TIME = 'DELAY_TIME';
  AT_KOEF_TIME = 'KOEF_TIME';
  AT_FROM_TIME = 'FROM_TIME';
  AT_TO_TIME = 'TO_TIME';
  AT_END_REASON = 'AT_END_REASON';
  AT_FROM_ADR = 'FROM_ADR';
  AT_TO_ADR = 'TO_ADR';
  AT_FROM_KADR = 'FROM_KADR';
  AT_TO_KADR = 'TO_KADR';
//  AT_RAM_FILE = 'RAM_FILE';

const FramePeriodSec = 2.097152;
      SecInDay       = 86400.0;
      FrameInDays    = FramePeriodSec / SecInDay;
      DateEpoch      = 36526.0; // TDateTime для 01.01.2000

//type
//  {$IFDEF BT2}
//   TCmdADR = Word;
//  {$ELSE}
//   TCmdADR = Byte;
//  {$ENDIF}
//  PCmdADR = ^TCmdADR;
//  const CASZ = SizeOf(TCmdADR);

type
  TTestRef = reference to function(n: IXMLNode): boolean; // если да то прекратить рекурсию

  TWorkDataRef = reference to procedure(wrk: IXMLNode; adr: integer; const name: string);

  THasXtreeRef = reference to procedure(EtalonRoot, EtalonAttr, TestRoot, TestAttr: IXMLNode);

  TNotHasXtreeRef = reference to function(EtalonRoot, EtalonAttr, TestRoot, TestAttr: IXMLNode): boolean;
//  TRamDataRef = TWorkDataRef;

function TryValX(Root: IXMLNode; const Path: string; var v: Variant): Boolean;

function TryGetX(Root: IXMLNode; const Path: string; out X: IXMLNode; const AttrName: string = ''): Boolean;

function GetPathXNode(Node: IXMLNode; NoMeta: boolean = false): string;

function GetXNode(Root: IXMLNode; const Path: string; CreatePathNotExists: Boolean = False): IXMLNode;
// проверяет содержит ли Test Etalon структуру и атрибуты
// для каждого атрибута вызывается действие
// прiменяется для копирования только данных

function HasXTree(Etalon, Test: IXMLNode; Action: THasXtreeRef = nil; CheckRootAttr: Boolean = True; BadTree: TNotHasXtreeRef = nil): Boolean;

function ExecXTree(root: IXMLNode; func: TTestRef): IXMLNode; overload; //возвращает первое совпадение

procedure ExecXTree(root: IXMLNode; func: Tproc<IXMLNode>; Dec: Boolean = False); overload;

procedure FindAllWorks(root: IXMLNode; func: TWorkDataRef);

procedure FindAllRam(root: IXMLNode; func: TWorkDataRef);

procedure FindAllEeprom(root: IXMLNode; func: TWorkDataRef);

function FindDev(root: IXMLNode; adr: Integer): IXMLNode;

function FindWork(root: IXMLNode; adr: Integer): IXMLNode;

function FindRam(root: IXMLNode; adr: Integer): IXMLNode;

function FindEeprom(root: IXMLNode; adr: Integer): IXMLNode;


// Рекурсивный поиск Dev root  может быть секцией ALL_META_DATA или DEVICES (проект 3)
function FindDevs(root: IXMLNode): TArray<IXMLNode>;
// аналог FindAllWorks FindAllRam FindAllEeprom

function GetDevsSections(Devs: TArray<IXMLNode>; const Section: string): TArray<IXMLNode>;

//function MyTimeToStr(t: TTime): string;
//function MyStrToTime(s: string): TTime;
// delay- время задержки
// TimeStart - время старта задержки
// KoefTime = Tотносительное_эталон/(Tотносительное_устройство+Tdelay)
// время абсолютное эталонное
function AdrToTime(adr: Integer; KoefTime: Double; RecSize: Integer; TimeStart: TDateTime; Delay: TTime): TDateTime;
// время абсолютное эталонное
// результат - адрес RAM во время time.  при KoefTime=1 и  time=delay RAM=0
// адрес может быть отрицательный если time=delay и KoefTime<1 !!!

function TimeToAdr(time: TDateTime; KoefTime: Double; RecSize: Integer; TimeStart: TDateTime; Delay: TTime): Integer;

//function GetIActionName(ManagOwner: IInterface; Event: TIActionEvent): string;
procedure EnumDevices(GetDevicesCB: TGetDevicesCB);
//function ToAdrCmd(a, cmd: Byte): TCmdADR;

function XToVar(ANode: IXMLNode): Variant;

function QToVar(DataSet: TDataSet; AutoClearDataSet: Boolean = True): Variant;

function RenameXMLNode(Src: IXMLNode; const NewName: string): IXMLNode;

procedure RemoveXMLAttr(Node: IXMLNode; const AttrName: string);

function NewXDocument(Version: DOMString = '1.0'): IXMLDocument;

function XSupport(const Instance: IXMLNode; const IID: TGUID; out Intf): Boolean;

function FindXmlNode(root: IXMLNode; const Section, NodeName: string; var Node: IXMLNode): Boolean;
function FindInDevNode(root: IXMLNode; const Section, NodeName: string; var Node: IXMLNode): Boolean;

function DevNode(DataNode: IXMLNode): IXMLNode;

function CalcNode(DataNode: IXMLNode): IXMLNode;

/// <summary>
/// для проекта 3 или ALL_META_DATA
/// </summary>
function GetIDeviceMeta(Doc: IXMLDocument; const Iname: string): IXMLNode;

function StrIn(const Item: string; const InArr: array of string): Boolean;
//function IsData(Node: IXMLNode): Boolean;
//function IsWrkRam(Node: IXMLNode): Boolean;

type
  CNode = class
    type
      TDirType = (dtWrk, dtRam, dtEEprom);
    const
      STR_DIR_TYPE: array[TDirType] of string = (T_WRK, T_RAM, T_EEPROM);

    class function GetDev(DataNode: IXMLNode): IXMLNode; static;
    class function GetCalc(DataNode: IXMLNode): IXMLNode; static;
    class function IsData(Node: IXMLNode): Boolean; static;
    class function IsWrkRam(Node: IXMLNode): Boolean; static;
    class function DBName(Node: IXMLNode): string; static;
//    class function TryDBNode(const Name: string; MetaDataAll: IXMLNode; out Res: IXMLNode; dt: TDirType = dtWrk): boolean; static;
  end;

  CTimeNew = class
// Функции конвертации времени
    class function UInt32RTCToDateTime(AnRTC: UInt32): TDateTime; static;
    class function DateTimeToUInt32RTC(ADateTime: TDateTime): UInt32; static;
//    class function DateTimeToInt32Delay(AnRTC: UInt32; ADelayTime: TDateTime): Int32; static;
    class function Int32DelayToDateTime(ADelay: Int32): TTime; static;
  end;

  CTime = class
  const
      TIME_TO_KADR = 24 * 3600 / 2.097152;
      KADR_TO_TIME = 2.097152 / 24 / 3600;

   public

    ///	<returns>
    ///	  d hh:nn:ss строка
    ///	</returns>
    class function AsString(t: TTime): string;
    ///	<param name="s">
    ///	  d hh:nn:ss строка
    ///	</param>
    class function FromString(const s: string): TTime;

    class function FromKadr(kadr: Integer): TTime; inline;
    ///	<summary>
    ///	  округляет к кадру в будующем Ceil
    ///	</summary>
    class function ToKadr(t: TTime): Integer; inline;
    class function RoundToKadr(t: TTime): Integer; inline;
    ///	<summary>
    ///	  округляет к кадру в будующем если DeltaKadr: Integer = 0
    ///	</summary>
    class function Ceil(t: TTime; DeltaKadr: Integer = 0): TTime; inline;
    ///	<summary>
    ///	  округляет к ближайшему кадру
    ///	</summary>
    class function Round(t: TTime): TTime; inline;
    // delay- время задержки
    // TimeStart - время старта задержки
    // KoefTime = Tотносительное_эталон/(Tотносительное_устройство+Tdelay)
    // время абсолютное эталонное
//    class function AdrToTime(adr: Integer; KoefTime: Double; RecSize: Integer; TimeStart: TDateTime; Delay: TTime): TDateTime;
    // время абсолютное эталонное
    // результат - адрес RAM во время time.  при KoefTime=1 и  time=delay RAM=0
    // адрес может быть отрицательный если time=delay и KoefTime<1 !!!
//    class function TimeToAdr(time: TDateTime; KoefTime: Double; RecSize: Integer; TimeStart: TDateTime; Delay: TTime): Integer;
  private
  end;

  CArray = class
    class procedure Add<T>(var Values: TArray<T>; const Value: T);
  end;

  EFifoBuffer = class(EBaseException);

  TFifoRec<T> = record
    type
      PointerT = ^T;
    var
      First: LongWord;
      Data: TArray<T>;
    function Count: Integer; inline;
    function Last: LongWord; inline;
    procedure Add(const pData: PointerT; Len: integer);
    function Delete(Len: Integer{; From: Integer = 0}): Integer;
  end;

  PFifoDouble = ^TFifoDouble;

  TFifoDouble = TFifoRec<Double>;

  ///	<summary>
  ///	  потокобезопасный циклический ФИФО выходные (Peek) порции данных
  ///	  значительно меньше длинны буфера
  ///	</summary>
 { TFifoBuffer<T> = class
    type TArrayT = TArray<T>;
         PArrayT = ^TArrayT;
  private
    function GetItem(Index: Integer): T;
    procedure SetItem(Index: Integer; const Value: T);
    procedure SetSize(AValue: Integer);
  protected
    FCur: Integer;
    FSize: Integer;
    FCount: Integer;
    FLock: TCriticalSection;
    FOut: TArrayT;
    FData: TArrayT;
  public
    constructor Create();
    destructor Destroy; override;
    ///	<summary>
    ///	  копируются данные в массив
    ///	</summary>
    function Push(Data: Pointer; n: Integer; RemovOverload: Boolean): Boolean;
    ///	<summary>
    ///	  выдает непрерывный массив Т по возможности без копирования. Место в
    ///	  буфере не освобождается. если необходимо изменить данные то в конце вызвать RewriteCurrent
    ///	</summary>
    function Peek(var Data: Pointer; n: Integer): Boolean;//
    ///	<summary>
    ///	  Место в буфере освобождается.
    ///	</summary>
    function Next(n: Integer): Boolean;  }
    { TODO : write if need }
//    function Pop(var Data: Pointer; Size: Integer): Boolean;
//    procedure RewriteCurrent(Data: Pointer; Size: Integer); if Data <> @FData[Cur] copy else exit
  {  procedure Reset;
    property Item[Index: Integer]: T read GetItem write SetItem; default;
    property Count: Integer read FCount;
    property Size: Integer read FSize write SetSize;
  end;}

  ///	<summary>
  ///	  потокобезопасный QEUE выходные (pop) все порции данных
  ///	  меньше или равны длинны push порций данных (всех)
  ///	</summary>
{  TQueueBuffer<T> = class(TQueue<TArray<T>>)
  protected
    FLock: TCriticalSection;
    FCurData, FOut: TArray<T>;
    FCur: Integer;
  public
    constructor Create();
    destructor Destroy; override;
    procedure Push(Data: Pointer; Size: Integer);
    function Pop(var Data: Pointer; Size: Integer): Boolean;
    procedure Reset;
  end;}

  ///	<summary>
  ///	  выполнение заданий в очереди в потоке
  ///	</summary>
  TQeueThread<T> = class(TThread)
  public
    type
      TCompareTaskFunc = reference to function(ToQeTask, InQeTask: T): Boolean;
  private
//    FLockExec: TCriticalSection;
    FEvent: TEvent;
    FQe: TList<T>;
    DbgName: string;
    class var
      NoCopy: Integer;
  protected
  ///	<summary>
  ///	  обновление очереди
  ///	</summary>
    FLock: TCriticalSection;
    procedure TerminatedSet; override;
    procedure Execute; override;
    procedure Exec(data: T); virtual; abstract;
  public
    constructor Create(CreateSuspended: Boolean; const DebugName: string = '');
    destructor Destroy; override;
    procedure Enqueue(task: T; Cmpfunc: TCompareTaskFunc = nil); // добавление в очередь и отправка
//    procedure ExecNow(task: T);
  ///	<summary>
  ///	  выполнение только одного задания в данный момент для синхронного выполнения задания в основном или других потоках
  ///	</summary>
//    property LockExec: TCriticalSection read FLockExec;
  end;

{  TXMLNodeEnumerable = record
  private
    Root: IXMLNode;
  public
    function GetEnumerator: TXMLNodeEnumerator;
  end;

  TXMLNodeEnumerableDec = record
  private
    Root: IXMLNode;
  public
    function GetEnumerator: TXMLNodeEnumeratorDec;
  end;

  TXMLNodeEnumerableAttr = record
  private
    Root: IXMLNode;
  public
    function GetEnumerator: TXMLNodeEnumerator;
  end;}

  IOwnIntfXMLNode = interface
    ['{67CDEB59-A805-435B-9445-5094D12E3D15}']
    procedure SetOwnIntf(const Value: IInterface);
    function GetOwnIntf: IInterface;
    property Intf: IInterface read GetOwnIntf write SetOwnIntf;
  end;

  TOwnIntfXMLNode = class(TXMLNode, IOwnIntfXMLNode)
  private
    FOwnIntf: IInterface;
  protected
    procedure SetOwnIntf(const Value: IInterface);
    function GetOwnIntf: IInterface;
  public
    destructor Destroy; override;
  end;

  TXDocument = class(TXMLDocument)
  protected
    function GetChildNodeClass(const Node: IDOMNode): TXMLNodeClass; override;
  end;

  TAddressRec = record
  public
    type
      TDevRec = record
        Adr: Integer;
        Name, Info: string;
        constructor Create(DevAdr: Integer; const DevNodeName, DevInfo: WideString);
      end;

      TArrayDevRec = Tarray<TDevRec>;
  private
    class var
      CFDevs: TArrayDevRec;
    class var
      IsInit: Boolean;
    class procedure Init; static;
  public
    Items: TAddressArray;
    function ToStr(): string;
//    function ToNames(): string;
    class operator Implicit(const AdrArray: TAddressArray): TAddressRec;
    class operator Implicit(const AddressRec: TAddressRec): TAddressArray;
    class operator Explicit(const SetAdd: array of Integer): TAddressRec;
    class operator Explicit(const StrAdr: string): TAddressRec;
    class operator Implicit(const StrAdr: string): TAddressRec;
    class operator Explicit(const AdrArray: TAddressArray): TAddressRec;
    class function Devices: TArrayDevRec; static;
  end;

  TAngle = record
    Angle: Double;
    class function Cra(ang: Double): Double; static;
    class operator Implicit(Ang: TAngle): Double;
    class operator Implicit(Ang: Double): TAngle;
    class operator Add(a: TAngle; b: TAngle): TAngle;
    class operator Subtract(a: TAngle; b: TAngle): TAngle;
    function ToRad: Double;
    function ToString: string;
    function ToStringUAKI: string;
  end;

  // только для одной таблицы
  IHelperXMLtoDB = interface
    function FieldTypes: TArray<TFieldType>;
    function FieldTxtTypes: TArray<string>;
    function FieldValues: TArray<variant>;
    function Fields: TArray<IXMLNode>;
    function FieldNames: TArray<string>;
    function FieldNamesWithTypes: string;
    function Params: string;
  end;

{  THelperXMLtoDB = class(TInterfacedObject, IHelperXMLtoDB)
  protected
   type
}
    {TParam = record
      array_len: Integer;
      Value: IXMLNode;
      constructor Create(Root: IXMLNode; const AttrName: string);
    end;}
{  protected
    fRoot: IXMLNode;
    fCheckedOnly: Boolean;
    fParams: TArray<IXMLNode>;
//    fParams: TArray<TParam>;
    fFieldTypes: TArray<TFieldType>;
    fFieldTxtTypes: TArray<string>;
    fFieldNames: TArray<string>;
    function IsData(n: IXMLNode): Boolean;
    function IsRow(n: IXMLNode): Boolean;
    function IsTrr(n: IXMLNode): Boolean;
    //IHelperXMLtoDB
    function FieldTypes: TArray<TFieldType>;
    function FieldTxtTypes: TArray<string>;
    function FieldValues: TArray<variant>;
    function Fields: TArray<IXMLNode>;
    function FieldNames: TArray<string>;
    function FieldNamesWithTypes: string;
    function Params: string;
    procedure FieldValuesToNil;
    //
//    class function XArrayToVar(Data: IXMLNode): Variant; static;
    class function FieldTypesToTxtTypes(FieldType: TFieldType): string; static;
  public
//    class procedure UnDuplicateNames(var FieldNames: TArray<string>); static;
//    class function CreateName(Node: IXMLNode; const pre: string): string; static;
    constructor Create(Root: IXMLNode; CheckedOnly: Boolean = False);
  end;}

  TVxmlData = packed record
    VType: TVarType;
    Reserved1, Reserved2, Reserved3: Word;
    Node: IXMLNode;
    Reserved4: LongInt;
  end;

  TXMLNodeEnumerator = record
  private
    i: Integer;
    FRoot: IXMLNodeList;
    function DoGetCurrent: IXMLNode;
  public
    property Current: IXMLNode read DoGetCurrent;
    function MoveNext: Boolean;
    function GetEnumerator: TXMLNodeEnumerator;
  end;

  TXMLNodeEnumeratorDec = record
  private
    i: Integer;
    FRoot: IXMLNodeList;
    function DoGetCurrent: IXMLNode;
  public
    property Current: IXMLNode read DoGetCurrent;
    function MoveNext: Boolean;
    function GetEnumerator: TXMLNodeEnumeratorDec;
  end;

  TDataSetEnumerator = record
  private
    FDataSet: TDataSet;
    FCurrent: Variant;
    FFirst: Boolean;
  public
    property Current: Variant read FCurrent;
    function MoveNext: Boolean;
  end;

  TDataSetHelper = class helper for TDataSet
    function GetEnumerator: TDataSetEnumerator;
  end;

  TStdRec = record
    Buffer: TArray<Byte>;
    pBuf: PByte;
    adr, cmd: Byte;
    len: Integer;
    function SizeOf(): Integer;
    function SizeOfAC(): Integer;
    function Ptr(): Pointer;
    function DataPtr(): Pointer;
    function CheckAC(p: Pointer): Boolean;
    function DataAsType<T>(): T;
    procedure Assign(data: Pointer);
    procedure AssignByte(data: integer);
    procedure AssignWord(data: integer);
    procedure AssignInt(data: integer);
    procedure AssignAdvStdRead(ln: Byte; from: Word);
    procedure AssignEEPRead(from: Word; ln: Word);
    procedure AssignEEPWrite(from: Word; const AData: array of byte);
    procedure AssignEEPWriteP(from: Word; len: Integer; PData: Pointer);
    procedure AssignRamRead(RmAdr, len: integer);
    constructor Create(addr, command, DataLength: Integer); overload;
    constructor Create(buff: Pointer; Bt2: boolean; alen: Integer); overload;
  end;

function XEnumDec(ANode: IXMLNode): TXMLNodeEnumeratorDec;

function XEnum(ANode: IXMLNode): TXMLNodeEnumerator;

function XEnumAttr(ANode: IXMLNode): TXMLNodeEnumerator;

function ColorCorrect(wtColor: TColor): TColor;

var
  XMLVariantType: Word;

  CurrentThemeIsDark: boolean;

  clThBkg, clThSplit, clThBorder,
  clThWindowTextNormal, clThWindowTextDisabled,
  clThButtonDisabled, clThButtonFocused, clThButtonNormal: TColor;

implementation

function ColorCorrect(wtColor: TColor): TColor;
begin
  Result := wtColor;
  if not CurrentThemeIsDark then Exit;
  case wtColor of
   clBlue : Exit(clSkyBlue);
   TColor($8F0000): Exit($DF8080);
   TColor($008F00): Exit($60AF60);
   TColor($00008F): Exit($6060AF);
   TColor($800000): Exit($FFa0a0);
   TColor($008000): Exit($80D080);
   TColor($000080): Exit($8080D0);
   TColor($804000): Exit($D08060);
   TColor($408000): Exit($80D060);
   TColor($008040): Exit($60D080);
   TColor($004080): Exit($6080D0);
   TColor($800080): Exit($D080D0);
   TColor($404000): Exit($D0D040);
   TColor($303000): Exit($A0A080);
   TColor($404080): Exit($8080D0);
  end;
end;
//uses parser;

//  PStdRec = ^TStdRec;
//  TStdRead = packed record
//    CmdAdr: TCmdADR;
//    ln: Byte;
//    constructor Create(addr, command, ReadLength: Byte);
//  end;
//  PStdReadLong = ^TStdReadLong;
//  TStdReadLong = packed record
//    CmdAdr: TCmdADR;
//    ln: Word;
//    constructor Create(addr, command, ReadLength: Word);
//  end;
//  TAdvStdRead = packed record
//    CmdAdr: TCmdADR;
//    ln: Byte;
//    from: Word;
//    constructor Create(addr, command, ReadLength: Byte; ReadFrom: Word);
//  end;

//  TEepRead = packed record
//    CmdAdr: TCmdADR;
//    From: Word;
//    len: Byte;
//    constructor Create(addr: Byte; AFrom: Word; ReadLength: Byte);
//  end;

//  TEepWrite = packed record
//    CmdAdr: TCmdADR;
//    From: Word;
//    Data: array[0..251-CASZ] of Byte;
//    constructor Create(addr: Byte; AFrom: Word; const AData: array of byte);
//  end;
//
{ TEepWrite }

//constructor TEepWrite.Create(addr: Byte; AFrom: Word; const AData: array of byte);
//begin
//  CmdAdr := ToAdrCmd(addr, CMD_WRITE_EE);
//  From := AFrom;
//  if Length(AData) > Length(Data) then EBurException.Create('длинна данных EEPROM больще 255');
//  Move(AData, Data, Length(AData));
//end;

{ TEepRead }

//constructor TEepRead.Create(addr: Byte; AFrom: Word; ReadLength: Byte);
//begin
//  CmdAdr := ToAdrCmd(addr, CMD_READ_EE);
//  From := AFrom;
//  len := ReadLength;
//end;

{ TStdRead }

//constructor TStdRead.Create(addr, command, ReadLength: Byte);
//begin
//  CmdAdr := ToAdrCmd(addr, command);
//  ln := ReadLength;
//end;

procedure TStdRec.Assign(data: Pointer);
begin
  Move(data^, DataPtr^, len);
end;

procedure TStdRec.AssignAdvStdRead(ln: Byte; from: Word);
var
  P: PByte;
begin
  P := DataPtr;
  P^ := ln;
  inc(P);
  Pword(P)^ := from;
end;

procedure TStdRec.AssignByte(data: integer);
begin
  PByte(DataPtr)^ := data;
end;

procedure TStdRec.AssignEEPRead(from: Word; ln: Word);
var
  P: Pword;
begin
  P := DataPtr;
  P^ := from;
  inc(P);
  if ln > 252 then P^ := ln
  else Pbyte(p)^ := ln;
end;

procedure TStdRec.AssignEEPWrite(from: Word; const AData: array of byte);
var
  P: Pword;
begin
  P := DataPtr;
  P^ := from;
  inc(P);
  Move(AData, P^, Length(AData));
end;

procedure TStdRec.AssignEEPWriteP(from: Word; len: Integer; PData: Pointer);
var
  P: Pword;
begin
  P := DataPtr;
  P^ := from;
  inc(P);
  Move(PData^, P^, len);
end;

procedure TStdRec.AssignInt(data: integer);
begin
  PInteger(DataPtr)^ := data;
end;

procedure TStdRec.AssignRamRead(RmAdr, len: integer);
var
  P: Pinteger;
begin
  P := DataPtr;
  P^ := RmAdr;
  inc(P);
  P^ := len;
end;

procedure TStdRec.AssignWord(data: integer);
begin
  Pword(DataPtr)^ := data;
end;

function TStdRec.CheckAC(p: Pointer): Boolean;
begin
  if adr > 15 then
    Result := PWORD(pBuf)^ = PWORD(p)^
  else
    Result := pBuf[0] = Pbyte(p)^
end;

constructor TStdRec.Create(buff: Pointer; Bt2: boolean; alen: Integer);
begin
  len := alen;
  pBuf := buff;
  if Bt2 then
  begin
    adr := pBuf[0];
    cmd := pBuf[1];
  end
  else
  begin
    adr := pBuf[0] shr 4;
    cmd := pBuf[1] and $0F;
  end;
end;

constructor TStdRec.Create(addr, command, DataLength: Integer);
begin
  adr := addr;
  cmd := command;
  len := DataLength;
  if adr > 15 then
  begin
    SetLength(Buffer, 2 + len);
    Buffer[0] := adr;
    Buffer[1] := cmd;
  end
  else
  begin
    SetLength(Buffer, 1 + len);
    Buffer[0] := (adr shl 4) or cmd;
    ;
  end;
  pBuf := @Buffer[0];
end;

function TStdRec.DataAsType<T>: T;
var
  res: T;
begin
  res := T(DataPtr^);
  Result := res;
end;

function TStdRec.DataPtr: Pointer;
begin
  if adr > 15 then
    Result := @pBuf[2]
  else
    Result := @pBuf[1]
end;

function TStdRec.Ptr: Pointer;
begin
  Result := pBuf;
end;

function TStdRec.SizeOf: Integer;
begin
  Result := SizeOfAC + len
end;

function TStdRec.SizeOfAC: Integer;
begin
  if adr > 15 then
    Result := 2
  else
    Result := 1
end;

{ TStdReadLong }

//constructor TStdReadLong.Create(addr, command, ReadLength: Word);
//begin
//  CmdAdr := ToAdrCmd(addr, command);
//  ln := ReadLength;
//end;


{ TAdvStdRead }

//constructor TAdvStdRead.Create(addr, command, ReadLength: Byte; ReadFrom: Word);
//begin
//  CmdAdr := ToAdrCmd(addr, command);
//  ln := ReadLength;
//  from := ReadFrom;
//end;



//type
//  PRamRead =^TRamRead;
//  TRamRead = packed record
//    CmdAdr: TCmdADR;
//    Adr: DWORD;
////    Len: DWORD;
////    PH, P6LB2H, BL: Byte;
//    Length: DWord;
//    constructor Create(DevAdr: Byte; RmAdr, len: DWord);
//  end;

{ TRamRead }

//constructor TRamRead.Create(DevAdr: Byte; RmAdr, len: DWord);
//// var
////  page, base: Word;
//begin
//  CmdAdr := ToAdrCmd(DevAdr, CMD_READ_RAM);
////  page := RmAdr div 528;
////  base := RmAdr mod 528;
////  PH := Byte(page shr 6);
////  BL := Byte(base);
////  P6LB2H := Byte(page shl 2) or Byte(base shr 8);
//  Length := len;
//  Adr := RmAdr;
//end;

const
  K_DEVTIME_TO_TIME = 2.097152 / 3600 / 24;

function TFifoRec<T>.Count: Integer;
begin
  Result := Length(data);
end;

function TFifoRec<T>.Last: LongWord;
begin
  Result := First + Length(data);
end;

procedure TFifoRec<T>.Add(const pData: PointerT; Len: integer);
var
  n: Integer;
begin
  n := Length(data);
  SetLength(data, n + Len);
  Move(pData^, data[n], Len * SizeOf(T));
end;

function TFifoRec<T>.Delete(Len: Integer{; From: Integer = 0}): Integer;
// var
//  n: Integer;
begin
  if Length(data) - Len < 0 then
    Result := Length(data)
  else
    Result := Len;
  Inc(First, Result);
  System.Delete(data, 0, Result);

{  n := Length(Data) - (From + Len);
  if n > 0 then
   begin
    Inc(First, Len);
    System.Delete(Data, 0 From, Len)
   end
  else SetLength(Data, 0);}
end;

{ CNode }

class function CNode.DBName(Node: IXMLNode): string;
begin
  Result := Node.NodeName;
  Node := Node.ParentNode;
  while not IsWrkRam(Node) do
  begin
    Result := Node.NodeName + '.' + Result;
    Node := Node.ParentNode;
  end;
  Result := Node.ParentNode.NodeName + '.' + Result;
end;

class function CNode.GetCalc(DataNode: IXMLNode): IXMLNode;
begin
  Result := DataNode.ChildNodes.FindNode(T_CLC);
  if not Assigned(Result) then
    Exit(DataNode.AddChild(T_CLC));
end;

class function CNode.GetDev(DataNode: IXMLNode): IXMLNode;
begin
  Result := DataNode.ChildNodes.FindNode(T_DEV);
  if not Assigned(Result) then
    Exit(DataNode.AddChild(T_DEV));
end;

class function CNode.IsData(Node: IXMLNode): Boolean;
begin
  Result := (Node.NodeName = T_CLC) or (Node.NodeName = T_DEV);
end;

class function CNode.IsWrkRam(Node: IXMLNode): Boolean;
begin
  Result := (Node.NodeName = T_WRK) or (Node.NodeName = T_RAM);
end;

//class function CNode.TryDBNode(const Name: string; MetaDataAll: IXMLNode; out Res: IXMLNode; dt: TDirType): boolean;
// var
//  s: Integer;
//begin
//  Result := TryGetX(MetaDataAll
//
//end;

{$REGION 'CTime'}

{ CTime }

class function CTime.Round(t: TTime): TTime;
begin
  Result := RoundToKadr(t) * KADR_TO_TIME;
end;

class function CTime.RoundToKadr(t: TTime): Integer;
begin
  Result := System.Round(SimpleRoundTo(t * TIME_TO_KADR, 0));
end;

class function CTime.Ceil(t: TTime; DeltaKadr: Integer): TTime;
begin
  Result := (ToKadr(t) + DeltaKadr) * KADR_TO_TIME;
end;

class function CTimeNew.Int32DelayToDateTime(ADelay: Int32): TTime;
begin
  Result := ADelay * FrameInDays;
end;

//class function CTime.DateTimeToInt32Delay(AnRTC: UInt32; ADelayTime: TDateTime): Int32;
//begin
//  Result := System.Round((UInt32RTCToDateTime(AnRTC) - ADelayTime) / FrameInDays);
//end;

class function CTimeNew.DateTimeToUInt32RTC(ADateTime: TDateTime): UInt32;
begin
  if ADateTime <= DateEpoch then Result := 0
  else Result := System.Round((ADateTime - DateEpoch) / FrameInDays);
end;

class function CTimeNew.UInt32RTCToDateTime(AnRTC: UInt32): TDateTime;
begin
  Result := DateEpoch + (AnRTC * FrameInDays);
end;

class function CTime.FromKadr(kadr: Integer): TTime;
begin
  Result := kadr * KADR_TO_TIME;
end;

class function CTime.ToKadr(t: TTime): Integer;
begin
  Result := System.Math.Floor(t * TIME_TO_KADR);
end;

class function CTime.AsString(t: TTime): string;
begin
  if t > 365 then
    Exit('99 00:00:00');
  Result := TimeToStr(t);
  if Abs(Double(t)) >= 1 then
    Result := Format('%2d %8s', [Trunc(Abs(t)), Result])
end;

class function CTime.FromString(const s: string): TTime;
var
  a: TArray<string>;
begin
  a := Trim(s).Split([' '], TStringSplitOptions.ExcludeEmpty);
  if Length(a) = 1 then
    Result := StrToTime(a[0])
  else
    Result := a[0].ToInteger + StrToTime(a[1]);
end;

{$ENDREGION}

{$REGION 'Вспомогательные функции'}
function GetIDeviceMeta(Doc: IXMLDocument; const Iname: string): IXMLNode;
begin
  if Doc.DocumentElement.NodeName = 'PROJECT' then
    Result := Doc.DocumentElement.ChildNodes.FindNode('DEVICES').ChildNodes.FindNode(Iname)
  else
    Result := Doc.DocumentElement.ChildNodes.FindNode(Iname);
end;

function CalcNode(DataNode: IXMLNode): IXMLNode;
begin
  Result := DataNode.ChildNodes.FindNode(T_CLC);
  if not Assigned(Result) then
    Exit(DataNode.AddChild(T_CLC));
end;

function DevNode(DataNode: IXMLNode): IXMLNode;
begin
  Result := DataNode.ChildNodes.FindNode(T_DEV);
  if not Assigned(Result) then
    Exit(DataNode.AddChild(T_DEV));
end;

function NewXDocument(Version: DOMString = '1.0'): IXMLDocument;
begin
  Result := TXDocument.Create(nil);
  Result.Active := True;
  if Version <> '' then
    Result.Version := Version;
end;

function XSupport(const Instance: IXMLNode; const IID: TGUID; out Intf): Boolean;
var
  i: IOwnIntfXMLNode;
begin
  Result := Supports(Instance, IOwnIntfXMLNode, i) and Supports(i.Intf, IID, Intf);
end;

function TXDocument.GetChildNodeClass(const Node: IDOMNode): TXMLNodeClass;
begin
  Result := TOwnIntfXMLNode;
end;

destructor TOwnIntfXMLNode.Destroy;
begin
//  TDebug.Log('------  '+ Self.GetNodeName+ '      ');
  inherited;
end;

function TOwnIntfXMLNode.GetOwnIntf: IInterface;
begin
  Result := FOwnIntf;
end;

procedure TOwnIntfXMLNode.SetOwnIntf(const Value: IInterface);
begin
  FOwnIntf := Value;
end;

procedure RemoveXMLAttr(Node: IXMLNode; const AttrName: string);
var
  atr: IXMLNode;
begin
  atr := Node.AttributeNodes.FindNode(AttrName);
  if Assigned(atr) then
    Node.AttributeNodes.Remove(atr);
end;

function RenameXMLNode(Src: IXMLNode; const NewName: string): IXMLNode;
var
  NewNode, MoveNode, Parent: IXMLNode;
  i: Integer;
  s: string;
begin
  Parent := Src.ParentNode;
  NewNode := Parent.OwnerDocument.CreateNode(NewName);
  // Copy the value
  if (NewNode.NodeType <> ntElement) then
    NewNode.NodeValue := Src.NodeValue;
  // Copy Attributes
  for i := 0 to Src.AttributeNodes.Count - 1 do
  begin
    s := Src.AttributeNodes.Get(i).NodeName;
    NewNode.Attributes[s] := Src.Attributes[s];
  end;
  // Copy the Children
  while (Src.HasChildNodes) do
  begin
    MoveNode := Src.ChildNodes.First;
    Src.ChildNodes.Remove(MoveNode);
    NewNode.ChildNodes.Add(MoveNode);
  end;
  // Replace the node
  Parent.ChildNodes.ReplaceNode(Src, NewNode);
  // Set the result
  Result := NewNode;
end;

{ XEnum }
function XEnum(ANode: IXMLNode): TXMLNodeEnumerator;
begin
  Result.i := -1;
  Result.FRoot := ANode.ChildNodes;
end;

function XEnumDec(ANode: IXMLNode): TXMLNodeEnumeratorDec;
begin
  Result.i := ANode.ChildNodes.Count;
  Result.FRoot := ANode.ChildNodes;
end;

{ TXMLNodeEnumeratorDec }

function TXMLNodeEnumeratorDec.DoGetCurrent: IXMLNode;
begin
  Result := FRoot[i];
end;

function TXMLNodeEnumeratorDec.GetEnumerator: TXMLNodeEnumeratorDec;
begin
  Result := Self;
end;

function TXMLNodeEnumeratorDec.MoveNext: Boolean;
begin
  Dec(i);
  Result := i >= 0;
end;

function XEnumAttr(ANode: IXMLNode): TXMLNodeEnumerator;
begin
  Result.i := -1;
  Result.FRoot := ANode.AttributeNodes;
end;

function TXMLNodeEnumerator.DoGetCurrent: IXMLNode;
begin
  Result := FRoot[i];
end;

function TXMLNodeEnumerator.GetEnumerator: TXMLNodeEnumerator;
begin
  Result := Self;
end;

function TXMLNodeEnumerator.MoveNext: Boolean;
begin
  Inc(i);
  Result := i < FRoot.Count;
end;
{ ~XEnum }

{function GetIActionName(ManagOwner: IInterface; Event: TIActionEvent): string;
 var
   LContext: TRttiContext;
   LType: TRttiType;
   rm: TRttiMethod;
begin
  Result := (ManagOwner as IManagItem).IName + '_';
  LContext := TRttiContext.Create;
  try
   LType :=  LContext.GetType(TObject(TMethod(Event).Data).ClassType);
   for rm in LType.GetMethods do if rm.CodeAddress = TMethod(Event).Code then Exit(Result + rm.Name);
  finally
   LContext.Free;
  end;
  raise EBaseException.Create('Метод не найден');
end;}

procedure EnumDevices(GetDevicesCB: TGetDevicesCB);
var
  SearchRec: TSearchRec;
  Found: integer;
  GDoc: IXMLDocument;
  u: IXMLNode;
  s: string;
begin
  if not Assigned(GetDevicesCB) then
    Exit;
  GDoc := NewXMLDocument();
  Found := FindFirst(ExtractFilePath(ParamStr(0)) + 'Devices' + '\*.xml', faAnyFile, SearchRec);
  while Found = 0 do
  begin
    GDoc.LoadFromFile(ExtractFilePath(ParamStr(0)) + 'Devices' + '\' + SearchRec.Name);
    for u in XEnum(GDoc.DocumentElement) do
      if u.HasAttribute(AT_ADDR) then
      begin
        if u.HasAttribute(AT_INFO) then
          s := u.Attributes[AT_INFO]
        else
          s := '';
        GetDevicesCB(u.Attributes[AT_ADDR], u.NodeName, s)
      end;
    Found := FindNext(SearchRec);
  end;
end;

class procedure CArray.Add<t>(var Values: TArray<t>; const Value: t);
begin
  SetLength(Values, Length(Values) + 1);
  Values[High(Values)] := Value;
end;

function TimeToAdr(time: TDateTime; KoefTime: Double; RecSize: Integer; TimeStart: TDateTime; Delay: TTime): Integer;
begin
  Result := Round(((time - TimeStart) / KoefTime - Delay) / K_DEVTIME_TO_TIME) * RecSize;
end;

function AdrToTime(adr: Integer; KoefTime: Double; RecSize: Integer; TimeStart: TDateTime; Delay: TTime): TDateTime;
begin
  Result := (adr * K_DEVTIME_TO_TIME / RecSize + Delay) * KoefTime + TimeStart;
end;

{function MyStrToTime(s: string): TTime;
 var
  a: TArray<string>;
begin
  a := Trim(s).Split([' '], TStringSplitOptions.ExcludeEmpty);
  if Length(a) = 1 then Result := StrToTime(a[0])
  else Result := a[0].ToInteger + StrToTime(a[1]);
//
//  s := Trim(s);
//  if Pos(' ',s) = 0 then Result := StrToTime(s)
//  else Result := StrToInt(Copy(s,0,Pos(' ',s)-1)) + StrToTime(Copy(s, Pos(' ',s), Length(s)-Pos(' ',s)+1))
end;

function MyTimeToStr(t: TTime): string;
begin
  Result := TimeToStr(t);
  if Double(t) >= 1 then Result := IntToStr(Trunc(t)) + ' ' + Result;
end;  }

//function ToAdrCmd(a, cmd: Byte): TCmdADR;
//begin
//  {$IFDEF BT2}
//   Result :=Word(a) or Word(cmd) shl 8;
//  {$ELSE}
//   Result := (a shl 4) or cmd;
//  {$ENDIF}
//end;

function GetPathXNode(Node: IXMLNode; NoMeta: boolean): string;
begin
  Result := Node.NodeName;
  Node := Node.ParentNode;
  repeat
    if NoMeta and StrIn(Node.NodeName, ARR_META) then
      Exit;
    Result := Node.NodeName + '.' + Result;
    Node := Node.ParentNode;
  until not Assigned(Node);
end;

function TryValX(Root: IXMLNode; const Path: string; var v: Variant): Boolean;
var
  attr, pth: string;
  X: IXMLNode;
begin
  pth := Path.Remove(Path.LastIndexOf('.'));
  attr := Path.Remove(0, Path.LastIndexOf('.') + 1);
  Result := TryGetX(Root, pth, X, attr);
  if Result then
    v := X.NodeValue;
end;

function TryGetX(Root: IXMLNode; const Path: string; out X: IXMLNode; const AttrName: string = ''): Boolean;
var
  s: string;
begin
  Result := True;
  if not Assigned(Root) then
    Exit(False);
  for s in Path.Split(['.'], TStringSplitOptions.ExcludeEmpty) do
  begin
    if s = '/' then
      Root := Root.ParentNode
    else
      Root := Root.ChildNodes.FindNode(s);
    if not Assigned(Root) then
      Exit(False);
  end;
  if AttrName <> '' then
  begin
    X := Root.AttributeNodes.FindNode(AttrName);
    Result := Assigned(X);
  end
  else
    X := Root;
end;

function GetXNode(Root: IXMLNode; const Path: string; CreatePathNotExists: Boolean = False): IXMLNode;
var
  s: string;
begin
  if not Assigned(Root) then
    Exit(nil);
  for s in Path.Split(['.'], TStringSplitOptions.ExcludeEmpty) do
  begin
    Result := Root;
    if s = '/' then
      Root := Root.ParentNode
    else
      Root := Root.ChildNodes.FindNode(s);
    if Assigned(Root) then
      Continue;
    if not CreatePathNotExists then
      Break;
    Root := Result.AddChild(s);
  end;
  Result := Root;
end;

function ExecXTree(root: IXMLNode; func: TTestRef): IXMLNode;
var
  res: IXMLNode;

  procedure rec(r: IXMLNode);
  var
    n: IXMLNode;
  begin
    if func(r) then
      res := r
    else
      for n in XEnum(r) do
        if n.NodeType = ntElement then
          rec(n)
  end;

begin
  if not Assigned(root) then
    Exit(nil);
  res := nil;
  rec(root);
  Result := res;
end;

procedure ExecXTree(root: IXMLNode; func: Tproc<IXMLNode>; Dec: Boolean = False); overload;

  procedure rec(r: IXMLNode);
  var
    n: IXMLNode;
  begin
    func(r);
    if Dec then
      for n in XEnumDec(r) do
      begin
        if n.NodeType = ntElement then
          rec(n)
      end
    else
      for n in XEnum(r) do
        if n.NodeType = ntElement then
          rec(n)
  end;

begin
  if Assigned(root) then
    rec(root);
end;

function HasXTree(Etalon, Test: IXMLNode; Action: THasXtreeRef = nil; CheckRootAttr: Boolean = True; BadTree: TNotHasXtreeRef = nil): Boolean;

  procedure rec(e, t: IXMLNode);
  var
    ie, it: IXMLNode;
  begin
    if not CheckRootAttr then
      CheckRootAttr := True
    else
      for ie in XEnumAttr(e) do
      begin
        it := t.AttributeNodes.FindNode(ie.NodeName);
        if not Assigned(it) then
        begin
          if Assigned(BadTree) then
            Result := Result and BadTree(e, ie, t, it)
          else
            Result := False;
        //OwnerDocument.SaveToFile(ExtractFilePath(ParamStr(0))+'ie.xml');
        //  TDebug.Log(ie.NodeName);
        end
        else if Assigned(Action) then
          Action(e, ie, t, it)
      end;
    for ie in XEnum(e) do
    begin
      it := t.ChildNodes.FindNode(ie.NodeName);
      if not Assigned(it) then
      begin
        if Assigned(BadTree) then
          Result := Result and BadTree(e, ie, t, it)
        else
          Result := False;
         // TDebug.Log(ie.NodeName);
      end
      else
        rec(ie, it)
    end;
  end;

begin
  if not (Assigned(Etalon) and Assigned(Test)) then
    Exit(False);
 // Etalon.OwnerDocument.SaveToFile('C:\XE\Projects\Device2\_exe\Debug\Метрология\ГКИ\polytest\Etalon.xml');
 // Test.OwnerDocument.SaveToFile('C:\XE\Projects\Device2\_exe\Debug\Метрология\ГКИ\polytest\Test.xml');
  Result := True;
  rec(Etalon, Test);
end;

function FindDev(root: IXMLNode; adr: Integer): IXMLNode;
var
  u: IXMLNode;
begin
  Result := nil;
/// не подходит для проекта версии 3  ??? подходит если выбрать устройство !!!

  for u in XEnum(root) do
    if u.HasAttribute(AT_ADDR) and (u.Attributes[AT_ADDR] = adr) then
      Exit(u);

/// подходит для проекта версии 3
//  Result := ExecXTree(root, function(n: IXMLNode): boolean
//   begin
//    if n.HasAttribute(AT_ADDR) and (n.Attributes[AT_ADDR] = adr) then Result := True
//    else Result := False
//   end);
end;

function FindDevs(root: IXMLNode): TArray<IXMLNode>;
var
  Res: TArray<IXMLNode>;
begin
  ExecXTree(root,
    procedure(n: IXMLNode)
    begin
      if n.HasAttribute(AT_ADDR) then
        Carray.Add<IXMLNode>(Res, n);
    end);
  Result := Res;
end;

function GetDevsSections(Devs: TArray<IXMLNode>; const Section: string): TArray<IXMLNode>;
var
  n, s: IXMLNode;
begin
  for n in Devs do
  begin
    s := n.ChildNodes.FindNode(Section);
    if Assigned(s) then
      Carray.Add<IXMLNode>(Result, s);
  end;
end;

function FindWork(root: IXMLNode; adr: Integer): IXMLNode;
begin
  Result := FindDev(root, adr);
  if Assigned(Result) then
  begin
    Result := Result.ChildNodes.FindNode(T_WRK);
    if not Assigned(Result) or not Result.HasAttribute(AT_SIZE) then
      Exit(nil);
  end;
end;

function FindRam(root: IXMLNode; adr: Integer): IXMLNode;
begin
  Result := FindDev(root, adr);
  if Assigned(Result) then
  begin
    Result := Result.ChildNodes.FindNode(T_RAM);
    if not Assigned(Result) or not Result.HasAttribute(AT_SIZE) then
      Exit(nil);
  end;
end;

function FindEeprom(root: IXMLNode; adr: Integer): IXMLNode;
begin
  Result := FindDev(root, adr);
  if Assigned(Result) then
  begin
    Result := Result.ChildNodes.FindNode(T_EEPROM);
    if not Assigned(Result) or not Result.HasAttribute(AT_SIZE) then
      Exit(nil);
  end;
end;

procedure FindAllRam(root: IXMLNode; func: TWorkDataRef);
var
  u, w: IXMLNode;
begin
  for u in XEnum(root) do
    if u.HasAttribute(AT_ADDR) then
    begin
      w := u.ChildNodes.FindNode(T_RAM);
      if Assigned(w) then
        func(w, u.Attributes[AT_ADDR], u.NodeName);
    end;
end;

procedure FindAllWorks(root: IXMLNode; func: TWorkDataRef);
var
  u, w: IXMLNode;
begin
//  Root.OwnerDocument.SaveToFile(ExtractFilePath(ParamStr(0))+'FindAllWorks.xml');
//  TDebug.Log('Root: %s %d', [Root.NodeName, Root.ChildNodes.Count]);
  for u in XEnum(root) do
    if u.HasAttribute(AT_ADDR) then
    begin
//    TDebug.Log('Root__:'+u.NodeName);
      w := u.ChildNodes.FindNode(T_WRK);
      if Assigned(w) then
        func(w, u.Attributes[AT_ADDR], u.NodeName);
    end;
end;

procedure FindAllEeprom(root: IXMLNode; func: TWorkDataRef);
var
  u, w: IXMLNode;
begin
  for u in XEnum(root) do
    if u.HasAttribute(AT_ADDR) then
    begin
      w := u.ChildNodes.FindNode(T_EEPROM);
      if Assigned(w) then
        func(w, u.Attributes[AT_ADDR], u.NodeName);
    end;
end;


function FindInDevNode(root: IXMLNode; const Section, NodeName: string; var Node: IXMLNode): Boolean;
var
  w, res: IXMLNode;
begin
  res := nil;
  if root.HasAttribute(AT_ADDR) then
    begin
      w := root.ChildNodes.FindNode(Section);
      if Assigned(w) then
        ExecXTree(w,
          function(n: IXMLNode): boolean
          begin
            if n.NodeName = NodeName then
            begin
              res := n;
              Result := True;
            end
            else
              Result := False;
          end);
    end;
  Node := res;
  Result := Assigned(res);
end;

function FindXmlNode(root: IXMLNode; const Section, NodeName: string; var Node: IXMLNode): Boolean;
var
  u, w, res: IXMLNode;
begin
  res := nil;
  for u in XEnum(root) do
    if u.HasAttribute(AT_ADDR) then
    begin
      w := u.ChildNodes.FindNode(Section);
      if Assigned(w) then
        ExecXTree(w,
          function(n: IXMLNode): boolean
          begin
            if n.NodeName = NodeName then
            begin
              res := n;
              Result := True;
            end
            else
              Result := False;
          end);
      if Assigned(res) then
        Break;
    end;
  Node := res;
  Result := Assigned(res);
end;
{$ENDREGION}

{$REGION 'AddressArrayHelper'}

{ TAddressArrayHelper }

procedure DevicesCB(DevAdr: Integer; const DevNodeName, DevInfo: WideString);
begin
  CArray.Add<TAddressRec.TDevRec>(TAddressRec.CFDevs, TAddressRec.TDevRec.Create(DevAdr, DevNodeName, DevInfo));
end;

class operator TAddressRec.Explicit(const SetAdd: array of Integer): TAddressRec;
var
  i: integer;
begin
  SetLength(Result.Items, Length(SetAdd));
  for i := 0 to Length(SetAdd) - 1 do
    Result.Items[i] := SetAdd[i];
end;

class operator TAddressRec.Explicit(const StrAdr: string): TAddressRec;
var
  s: string;
begin
  SetLength(Result.Items, 0);
  for s in StrAdr.Split([';'], TStringSplitOptions.ExcludeEmpty) do
    CArray.Add<Integer>(Result.Items, s.Trim.ToInteger);
{ s := StrAdr;
while s <> '' do
   begin
    CArray.Add<Integer>(Result.Items, s.Copy  Copy(s, 1, pos(';',s)-1).Trim.ToInteger);
    Delete(s, 1, pos(';',s));
   end;}
end;

class function TAddressRec.Devices: TArrayDevRec;
begin
  Init();
  Result := CFDevs;
end;

class operator TAddressRec.Explicit(const AdrArray: TAddressArray): TAddressRec;
begin
  Result.Items := AdrArray;
end;

class operator TAddressRec.Implicit(const StrAdr: string): TAddressRec;
begin
  Result := TAddressRec(StrAdr)
end;

class procedure TAddressRec.Init;
begin
  if not IsInit then
  begin
    EnumDevices(DevicesCB);
    IsInit := True;
    TArray.Sort<TDevRec>(CFDevs, TComparer<TDevRec>.Construct(
      function(const Left, Right: TDevRec): Integer
      begin
        Result := Left.Adr - Right.Adr;
      end));
  end;
end;

class operator TAddressRec.Implicit(const AddressRec: TAddressRec): TAddressArray;
begin
  Result := AddressRec.Items;
end;

class operator TAddressRec.Implicit(const AdrArray: TAddressArray): TAddressRec;
begin
  Result.Items := AdrArray;
end;

//function TAddressRec.ToNames: string;
// var
//  a: Integer;
//  dr: TDevRec;
//  sadr: string;
//begin
//  Init();
//  Result := '';
//  for a in Items do
//   begin
//    sadr := IntToStr(a);
//    for dr in CFDevs do if a = dr.Adr then
//     begin
//      sadr := dr.Name;
//      Break;
//     end;
//    Result := Result + ' ' + sadr;
//   end;
//  Delete(Result, 1, 1);
//end;

function TAddressRec.ToStr: string;
var
  adr: Integer;
begin
  Result := '';
  for adr in Items do
    Result := Result + IntToStr(adr) + ';';
end;

constructor TAddressRec.TDevRec.Create(DevAdr: Integer; const DevNodeName, DevInfo: WideString);
begin
  adr := DevAdr;
  Name := DevNodeName;
  Info := DevInfo;
end;
{$ENDREGION}

{$REGION 'TCaseSensDispInv Variant'}

type
  TCaseSensDispInv = class(TInvokeableVariantType)
  private
//    class procedure Init(var clsInst: TCaseSensDispInv);
//    class procedure DeInit(var clsInst: TCaseSensDispInv);
  protected
    procedure DispInvoke(Dest: PVarData; [Ref] const Source: TVarData; CallDesc: PCallDesc; Params: Pointer); override;
  public
    procedure Clear(var v: TVarData); override;
    procedure Copy(var Dest: TVarData; const Source: TVarData; const Indirect: Boolean); override;
  end;

{ TCaseSensDispInv }

procedure TCaseSensDispInv.Clear(var V: TVarData);
begin
  SimplisticClear(V);
end;

procedure TCaseSensDispInv.Copy(var Dest: TVarData; const Source: TVarData; const Indirect: Boolean);
begin
  SimplisticCopy(Dest, Source, Indirect);
end;

//class procedure TCaseSensDispInv.Init(var clsInst: TCaseSensDispInv);
//begin
//  if not Assigned(clsInst) then clsInst := Create;
//end;
//
//class procedure TCaseSensDispInv.DeInit(var clsInst: TCaseSensDispInv);
//begin
//  if Assigned(clsInst) then FreeAndNil(clsInst);
//end;

procedure TCaseSensDispInv.DispInvoke(Dest: PVarData; [Ref] const Source: TVarData; CallDesc: PCallDesc; Params: Pointer);
const
  CDoMethod = $01;
  CPropertyGet = $02;
  CPropertySet = $04;
var
  LArgCount: Integer;
  LIdent: string;
  VarParams: TVarDataArray;
  Strings: TStringRefList;
  Dummi: Variant;
  PIdent: PByte;
begin
  // Grab the identifier
  LArgCount := CallDesc^.ArgCount;
  PIdent := @CallDesc^.ArgTypes[LArgCount];
  LIdent := UTF8ToString(MarshaledAString(PIdent));
  SetLength(Strings, LArgCount);
  VarParams := GetDispatchInvokeArgs(CallDesc, Params, Strings, true);

  case CallDesc^.CallType of
    CDoMethod, CPropertyGet:
      if (LArgCount <> 0) then
        RaiseDispError
      else if (Dest <> nil) then
      begin
        if not GetProperty(Dest^, Source, LIdent) then
          RaiseDispError
      end
      else if not GetProperty(TVarData(Dummi), Source, LIdent) then
        RaiseDispError;
    CPropertySet:
      if not ((Dest = nil) and (LArgCount = 1) and SetProperty(Source, LIdent, VarParams[0])) then
        RaiseDispError;
  else
    RaiseDispError;
  end;
end;
{$ENDREGION}

{$REGION 'XML Variant'}

type
  TVxml = class(TCaseSensDispInv)
  private
    class var
      This: TVxml;
  public
    function GetProperty(var Dest: TVarData; const v: TVarData; const Name: string): Boolean; override;
    function SetProperty(const v: TVarData; const Name: string; const Value: TVarData): Boolean; override;
  end;

function XToVar(ANode: IXMLNode): Variant;
begin
  VarClear(result);
  TVxmlData(result).VType := TVxml.This.VarType;
  TVxmlData(result).Node := ANode;
end;

{ TVxml }

function TVxml.GetProperty(var Dest: TVarData; const V: TVarData; const Name: string): Boolean;
var
  n, ch: IXMLNode;
begin
  n := TVxmlData(V).Node;
  if not Assigned(n) then
    Exit(False);
  Result := True;
//  TDebug.Log(n.ParentNode.ParentNode.NodeName+'.'+n.ParentNode.NodeName+'.'+n.NodeName+'  '+ Name+'  ');
  if n.HasAttribute(Name) then
    Variant(Dest) := n.Attributes[Name]
  else
  begin
    ch := n.ChildNodes.FindNode(Name);
    if Assigned(ch) then
      Variant(Dest) := XToVar(ch)
    else
      Result := False;
  end;
end;

function TVxml.SetProperty(const V: TVarData; const Name: string; const Value: TVarData): Boolean;
var
  n: IXMLNode;
begin
  n := TVxmlData(V).Node;
  if not Assigned(n) then
    Exit(False);
//  TDebug.Log(n.ParentNode.ParentNode.NodeName+'.'+n.ParentNode.NodeName+'.'+n.NodeName+'  '+ Name+'  ');
  Result := True;
  n.Attributes[Name] := Variant(Value);
end;
{$ENDREGION}

{$REGION 'SQL Variant'}

type
  TVsql = class(TCaseSensDispInv)
  private
    type
      TVsqlData = packed record
        VType: TVarType;
        Reserved1, Reserved2, Reserved3: Word;
        DataSet: TDataSet;
        Reserved4: LongInt;
      end;
    class var
      This: TVsql;
  public
    class function ToVar(DataSet: TDataSet): Variant; inline;
    function GetProperty(var Dest: TVarData; const v: TVarData; const Name: string): Boolean; override;
    function SetProperty(const v: TVarData; const Name: string; const Value: TVarData): Boolean; override;
  end;

  TVsqlAutoClear = class(TVsql)
  private
    class var
      This: TVsqlAutoClear;
  public
    procedure Clear(var v: TVarData); override;
  end;
{ TVsqlAutoClear }

procedure TVsqlAutoClear.Clear(var V: TVarData);
begin
  TVsqlData(V).DataSet.Free;
  inherited;
end;

function QToVar(DataSet: TDataSet; AutoClearDataSet: Boolean = True): Variant;
begin
  VarClear(result);
  if AutoClearDataSet then
  begin
    TVsqlAutoClear.TVsqlData(result).VType := TVsqlAutoClear.This.VarType;
    TVsqlAutoClear.TVsqlData(result).DataSet := DataSet;
  end
  else
  begin
    TVsql.TVsqlData(result).VType := TVsql.This.VarType;
    TVsql.TVsqlData(result).DataSet := DataSet;
  end;
end;
{ TVsql }

function TVsql.GetProperty(var Dest: TVarData; const V: TVarData; const Name: string): Boolean;
var
  fld: TField;
begin
  { Find a field with the property's name. If there is one, return its current value. }
  fld := TVsqlData(V).DataSet.FindField(Name.Replace('_', '.'));
  result := fld <> nil;
  if result then
    Variant(Dest) := fld.Value;
end;

function TVsql.SetProperty(const V: TVarData; const Name: string; const Value: TVarData): Boolean;
var
  fld: TField;
begin
  { Find a field with the property's name. If there is one, set its value. }
  fld := TVsqlData(V).DataSet.FindField(Name.Replace('_', '.'));
  result := fld <> nil;
  if result then
  begin
    { Well, we have to be in Edit mode to do this, don't we? }
//    TVsqlData(V).DataSet.Edit;
//    fld.AsVariant := Variant(Value);
//    TVsqlData(V).DataSet.FieldByName(Name).Value := Variant(Value);
//    fld.AsFloat := Variant(Value)
//    if fld is TNumericField then
//      TNumericField(fld).AsFloat := Variant(Value)
//    else
    fld.Value := Variant(Value);
  end;
end;

class function TVsql.ToVar(DataSet: TDataSet): Variant;
begin
  VarClear(result);
  TVsqlData(result).VType := This.VarType;
  TVsqlData(result).DataSet := DataSet;
end;

{ TDataSetHelper }

function TDataSetHelper.GetEnumerator: TDataSetEnumerator;
begin
  Result.FCurrent := TVsql.ToVar(Self);
  Result.FDataSet := Self;
  Result.FFirst := True;
  First;
end;

{ TDataSetEnumerator }

function TDataSetEnumerator.MoveNext: Boolean;
begin
  if FFirst then
    FFirst := False
  else
    FDataSet.Next;
  Result := not FDataSet.Eof;
end;
{$ENDREGION}

{$REGION 'TFifoBuffer TQeueBuffer'}

{ TFifoBuffer }

{constructor TFifoBuffer<T>.Create();
begin
  FLock := TCriticalSection.Create;
  FSize := 256;
  SetLength(FData, FSize);
end;

destructor TFifoBuffer<T>.Destroy;
begin
  FLock.Free;
  inherited;
end;

function TFifoBuffer<T>.Next(n: Integer): Boolean;
begin
  FLock.Acquire;
  try
   if n > FCount then Exit(False);
   Dec(FCount, n);
   FCur := (FCur + n) mod FSize;
   Result := True;
  finally
   FLock.Release;
  end;
end;

function TFifoBuffer<T>.Peek(var Data: Pointer; n: Integer): Boolean;
 var
  d: Integer;
begin
  FLock.Acquire;
  try
   if n > FCount then Exit(False);
   if (FCur + n) <= FSize then Data := @FData[FCur]
   else
    begin
     if Length(FOut) < n then SetLength(FOut, n);
     d := FSize - FCur;
     Move(FData[FCur], FOut[0], d*SizeOf(T));
     Move(FData[0], FOut[d], (n - d)*SizeOf(T));
     Data := @FOut[0];
    end;
   Result := True;
  finally
   FLock.Release;
  end;
end;

function TFifoBuffer<T>.Push(Data: Pointer; n: Integer; RemovOverload: Boolean): Boolean;
 var
  d, c: Integer;
begin
  FLock.Acquire;
  try
   if (n + FCount) > FSize then
    begin
     if not RemovOverload then Exit(False);
     Next(n + FCount - FSize);
    end;
   d := (FCur + FCount) mod FSize;
   if (d + n) <= FSize then Move(Data^, FData[d], n*SizeOf(T))
   else
    begin
     c := FSize - d;
     Move(Data^, FData[d], c*SizeOf(T));
     Move(TArrayT(Data)[c], FData[0], (n - c)*SizeOf(T));
    end;
   Inc(FCount, n);
   Result := True;
  finally
   FLock.Release;
  end;
end;

procedure TFifoBuffer<T>.Reset;
begin
  FLock.Acquire;
  FCur := 0;
  FCount := 0;
  FLock.Release;
end;

function TFifoBuffer<T>.GetItem(Index: Integer): T;
begin
  if (Index < 0) or (Index >= FCount) then raise EFifoBuffer.CreateFmt('Ошибка чтения циклического FIFO Index %d, Count %d',[Index, FCount]);
  Result := FData[(FCur + Index) mod FSize];
end;

procedure TFifoBuffer<T>.SetItem(Index: Integer; const Value: T);
begin
  if (Index < 0) or (Index >= FCount) then raise EFifoBuffer.CreateFmt('Ошибка записи циклического FIFO Index %d, Count %d',[Index, FCount]);
  FData[(FCur + Index) mod FSize] := Value;
end;

procedure TFifoBuffer<T>.SetSize(AValue: Integer);
begin
  if FSize = AValue then Exit;
  FLock.Acquire;
  try
   FCur := 0;
   FCount := 0;
   FSize := AValue;
   SetLength(FData, FSize);
   SetLength(FOut, 0);
  finally
   FLock.Release;
  end;
end;      }


{ TQeueBuffer<T> }

{constructor TQueueBuffer<T>.Create;
begin
  inherited Create;
  FLock := TCriticalSection.Create;
end;

destructor TQueueBuffer<T>.Destroy;
begin
  FLock.Free;
  inherited;
end;

procedure TQueueBuffer<T>.Push(Data: Pointer; Size: Integer);
 var
  d: TArray<T>;
begin
  SetLength(d, Size);
  Move(Data^, d[0], Size*SizeOf(T));
  FLock.Acquire;
  try
   Enqueue(d);
  finally
   FLock.Release;
  end;
end;

procedure TQueueBuffer<T>.Reset;
begin
  FLock.Acquire;
  try
   SetLength(FCurData, 0);
   FCur := 0;
   Clear;
  finally
   FLock.Release;
  end;
end;

function TQueueBuffer<T>.Pop(var Data: Pointer; Size: Integer): Boolean;
 var
  d, lc: Integer;
begin
  FLock.Acquire;
  try
   lc := Length(FCurData);
   d := lc - FCur;
   // Текущие данные
   if d >= Size then
    begin
     Data := @FCurData[FCur];
     Inc(FCur, Size);
     Exit(True);
    end
    // нет  данных
   else if Count = 0 then Exit(False)
   else if lc = FCur then // Length(FCurData) = 0 или Length(FCurData) = FCur
    // нет куска данных
    begin
     FCurData := Dequeue;
     Data := @FCurData[0];
     FCur := Size;
     Exit(True);
    end
   else
    // кусок данных
    begin
     SetLength(Fout, Size);
     Move(FCurData[FCur], Fout[0], d*SizeOf(T));
     FCurData := Dequeue;
     Move(FCurData[0], Fout[d], (Size-d)*SizeOf(T));
     FCur := Size-d;
     Data := @Fout[0];
     Exit(True);
    end;
   Result := False;
  finally
   FLock.Release;
  end;
end;       }

{$ENDREGION}

{$REGION 'TQeueThread'}

{ TQeueThread<T> }

constructor TQeueThread<t>.Create(CreateSuspended: Boolean; const DebugName: string);
begin
  Inc(NoCopy);
  DbgName := DebugName + '_' + NoCopy.ToString();
  FLock := TCriticalSection.Create;
//  FLockExec := TCriticalSection.Create;
  FEvent := TEvent.Create;
  FQe := TList<t>.Create;
  inherited Create(CreateSuspended);
end;

destructor TQeueThread<t>.Destroy;
begin
  FQe.Free;
  FEvent.Free;
//  FLockExec.Free;
  FLock.Free;
  inherited;
end;

procedure TQeueThread<t>.Enqueue(task: t; Cmpfunc: TCompareTaskFunc);
var
  i: integer;
begin
  if Terminated then
    Exit;
  FLock.Acquire;
  try
    if Assigned(Cmpfunc) then
      for i := FQe.Count - 1 downto 0 do
        if Cmpfunc(task, FQe[i]) then
          FQe.Delete(i);
    FQe.Add(task);
    FEvent.SetEvent;
  finally
    FLock.Release;
  end;
end;

{procedure TQeueThread<T>.ExecNow(task: T);
begin
  FLockExec.Acquire; // нельзя !!! т.к.  в Exec(d); может выть и скореевсего вудет Synchronize
  try
   Exec(task);
  finally
   FLockExec.Release;
  end;
end;}

procedure TQeueThread<t>.TerminatedSet;
begin
  inherited;
  FLock.Acquire;
  try
    Fqe.Clear;
  finally
    FLock.Release;
  end;
  FEvent.SetEvent;
end;

procedure TQeueThread<t>.Execute;
var
  d: t;
begin
  NameThreadForDebugging(DbgName);
  CoInitialize(nil);
  try
    repeat
      Fevent.WaitFor();
      Fevent.ResetEvent;
      while not Terminated do
      try
        FLock.Acquire;
        try
          if Fqe.Count = 0 then
            Break;
          d := Fqe.First;
          Fqe.Delete(0);
        finally
          FLock.Release;
        end;
     // !!!!! FLockExec.Acquire; !!!! // нельзя !!! т.к.  в Exec(d); может выть и скореевсего вудет Synchronize
                                      // Synchronize будет ждать основной поток который может быть в FLockExec.Acquire
                                      // получится deadlock
        try
          if Terminated then
            Exit;
          Exec(d);
        finally
          Finalize(d);
//      FillChar(d, SizeOf(d), 0);
     // !!!!! FLockExec.Release; !!!!!
        end;
      except
        on e: Exception do
          TDebug.DoException(e, False);
      end;
    until Terminated;
  finally
    CoUninitialize();
  end;
end;

{$ENDREGION}

{$REGION 'THelperXMLtoDB'}

{ THelperXMLtoDB.TParam }

{constructor THelperXMLtoDB.TParam.Create(Root: IXMLNode; const AttrName: string);
begin
  Value := Root.AttributeNodes.FindNode(AttrName);
  if Root.HasAttribute(AT_ARRAY) then array_len := Root.Attributes[AT_ARRAY]
  else array_len := 0;
end;}

{ THelperXMLtoDB }

{constructor THelperXMLtoDB.Create(Root: IXMLNode; CheckedOnly: Boolean);
begin
  fRoot := Root;
  fCheckedOnly := CheckedOnly;
end;

function THelperXMLtoDB.IsData(n: IXMLNode): Boolean;
begin
  Result := ((n.NodeName = T_DEV) or (n.NodeName = T_CLC)) and (not fCheckedOnly or (n.HasAttribute(AT_DB_SELECT) and Boolean(n.Attributes[AT_DB_SELECT])))
end;

function THelperXMLtoDB.IsRow(n: IXMLNode): Boolean;
begin
  Result := (n.NodeName = T_DEV) and (not fCheckedOnly or (n.HasAttribute(AT_DB_SELECT) and Boolean(n.Attributes[AT_DB_SELECT])))
end;

function THelperXMLtoDB.IsTrr(n: IXMLNode): Boolean;
begin
  Result := (n.NodeName = T_CLC) and (not fCheckedOnly or (n.HasAttribute(AT_DB_SELECT) and Boolean(n.Attributes[AT_DB_SELECT])))
end;

function THelperXMLtoDB.Params: string;
 var
  i: Integer;
begin
  if Length(FieldTypes) <= 0 then Exit('');
  Result := ':p1';
  for i := 2 to Length(FieldTypes) do Result := Format('%s,:p%d', [Result, i]);
end;    }

{class procedure THelperXMLtoDB.UnDuplicateNames(var FieldNames: TArray<string>);
 var
  i, j, ind, dup: Integer;
  sName,sNo: string;
begin
  for i := 0 to High(FieldNames)-1 do
   for j := i+1 to High(FieldNames) do
    if SameText(FieldNames[i], FieldNames[j]) then
     begin
      ind := FieldNames[j].LastIndexOf('_')+1;
      sNo := FieldNames[j].Substring(ind);
      sName := FieldNames[j].Substring(0, ind);
      dup := StrToIntDef(sNo, 0);
      if dup = 0 then FieldNames[j] := FieldNames[j]+'_1'
      else FieldNames[j] := sName + (dup+1).ToString;
     end;
end;}

{class function THelperXMLtoDB.FieldTypesToTxtTypes(FieldType: TFieldType): string;
begin
  case FieldType of
   ftString: Result := 'TEXT';
   ftFloat, ftDate, ftTime, ftDateTime: Result := 'REAL';
   ftBlob: Result := 'BLOB';
   else Result := 'INT';
  end
end;}

//class function THelperXMLtoDB.XArrayToVar(Data: IXMLNode): Variant;
// var
//  V: Variant;
//  pSource, pDest: Pointer;
//  Len: Integer;
//begin
//  Len := Data.Attributes[AT_ARRAY] * TPars.VarTypeToLength(Data.Attributes[AT_TIP]); { TODO : not need change array length }
//  V := VarArrayCreate([0, Len - 1], varByte);                                        { TODO : varAny }
//  pSource := Pointer(Integer(Data.Attributes[AT_VALUE]));
//  pDest := VarArrayLock(V);
//  try
//   Move(pSource^, pDest^, Len );
//  finally
//   VarArrayUnlock(V);
//  end;
//end;

{class function THelperXMLtoDB.CreateName(Node: IXMLNode; const pre: string): string;
begin
  if pre = '' then Exit(Node.NodeName);
  Result := Node.ParentNode.NodeName;
  if (Result = T_WRK) or (Result = T_RAM) then Result := Node.ParentNode.ParentNode.NodeName;
  Result := pre + '_' + Result + '_' + Node.NodeName;
end;}

{function THelperXMLtoDB.FieldNames: TArray<string>;
begin
  if Length(fFieldNames) = 0 then ExecXTree(fRoot, procedure(n: IXMLNode)
  begin
    if isData(n) then CArray.Add<string>(fFieldNames, CNode.DBName(n))
//    if IsRow(n) then CArray.Add<string>(fFieldNames, CreateName(n.ParentNode, 'R'))
//    else if IsTrr(n) then CArray.Add<string>(fFieldNames, CreateName(n.ParentNode, 'T'));
  end);
  Result := fFieldNames;
end;

function THelperXMLtoDB.FieldNamesWithTypes: string;
 var
  i: Integer;
begin
  if Length(FieldNames) <= 0 then Exit('');
  Result := Format('"%s" %s',[FieldNames[0] , FieldTxtTypes[0]]);
  for I := 1 to Length(FieldNames)-1 do Result := Format('%s,"%s" %s',[Result, FieldNames[i], FieldTxtTypes[i]]);
end;

function THelperXMLtoDB.FieldTxtTypes: TArray<string>;
 var
  i: integer;
begin
  if Length(fFieldTxtTypes) = 0 then
   begin
    FieldTypes();
    SetLength(fFieldTxtTypes, Length(fFieldTypes));
    for i := 0 to Length(fFieldTypes)-1 do fFieldTxtTypes[i] := FieldTypesToTxtTypes(fFieldTypes[i]);
   end;
  Result := fFieldTxtTypes;
end;

function THelperXMLtoDB.FieldTypes: TArray<TFieldType>;
begin
  if Length(fFieldTypes) = 0 then ExecXTree(fRoot, procedure(n: IXMLNode)
  begin
    try
    if IsData(n) then
     if n.ParentNode.HasAttribute(AT_ARRAY) then CArray.Add<TFieldType>(fFieldTypes, ftString)
     else CArray.Add<TFieldType>(fFieldTypes, Tpars.VarTypeToDBField(n.Attributes[AT_TIP]));
    except
     // n.OwnerDocument.SaveToFile(ExtractFilePath(ParamStr(0))+'GLU45.xml');
      raise;
    end;
  end);
  Result := fFieldTypes;
end;

function THelperXMLtoDB.Fields: TArray<IXMLNode>;
begin
  if Length(fParams) = 0 then ExecXTree(fRoot, procedure(n: IXMLNode)
  begin
    if IsData(n) then CArray.Add<IXMLNode>(fParams, n);
  end);
  Result := fParams;
end;

function THelperXMLtoDB.FieldValues: TArray<variant>;
 var
  i: integer;
begin
  SetLength(Result, Length(Fields));
  for i := 0 to Length(fParams)-1 do
//   if fParams[i].ParentNode.HasAttribute(AT_ARRAY) then Result[i] :=  XArrayToVar(fParams[i]) else
   Result[i] := fParams[i].Attributes[AT_VALUE];

//  fRoot.OwnerDocument.SaveToFile(ExtractFilePath(ParamStr(0))+'DB_GK.xml');

end;

procedure THelperXMLtoDB.FieldValuesToNil;
 var
  i: integer;
begin
  for i := 0 to High(FieldTypes) do
   case fFieldTypes[i] of
    ftString: Fields[i].Attributes[AT_VALUE] := '';
    ftInteger: Fields[i].Attributes[AT_VALUE] := 0;
    ftFloat:Fields[i].Attributes[AT_VALUE] := 0.0;
   end;
end;      }

{$ENDREGION}

{ TAngle }

class operator TAngle.Implicit(Ang: TAngle): Double;
begin
  Result := Ang.Angle;
end;

class operator TAngle.Add(a, b: TAngle): TAngle;
begin
  Result := Cra(a.Angle + b.Angle);
end;

class operator TAngle.Subtract(a, b: TAngle): TAngle;
begin
  Result := Cra(a.Angle - b.Angle);
end;

class function TAngle.Cra(ang: Double): Double;
begin
  while ang > 360 do
    ang := ang - 360;
  while ang < 0 do
    ang := ang + 360;
  Result := ang;
end;

class operator TAngle.Implicit(Ang: Double): TAngle;
begin
  Result.Angle := Ang; // Cra(Ang);
end;

function TAngle.ToRad: Double;
begin
  Result := DegToRad(Angle);
end;

function TAngle.ToString: string;
begin
  Result := FloatToStr(Angle)
end;

function TAngle.ToStringUAKI: string;
begin
  Result := Format('%1.1f', [Angle])
end;

function StrIn(const Item: string; const InArr: array of string): Boolean;
var
  s: string;
begin
  for s in InArr do
    if Item = s then
      Exit(True);
  Result := False;
end;

initialization
  TVxml.This := TVxml.Create;
  XMLVariantType := TVxml.This.VarType;
  TVsql.This := TVsql.Create;
  TVsqlAutoClear.This := TVsqlAutoClear.Create;
//  TVxml.Init(TCaseSensDispInv(TVxml.This));
//  TVsql.Init(TCaseSensDispInv(TVsql.This));
//  TVsqlAutoClear.Init(TCaseSensDispInv(TVsqlAutoClear.This));

finalization
  TVxml.This.Free;
  TVsql.This.Free;
  TVsqlAutoClear.This.Free;
//  TVxml.DeInit(TCaseSensDispInv(TVxml.This));
//  TVsql.DeInit(TCaseSensDispInv(TVsql.This));
//  TVsqlAutoClear.DeInit(TCaseSensDispInv(TVsqlAutoClear.This));

end.


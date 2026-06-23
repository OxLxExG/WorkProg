unit AbstractReadRam;

interface

uses Intf, DeviceIntf, debug_except, AbstractDev;

type
{$REGION 'RamRead'}
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
  EReadRamException = class(EBaseException);
    EAsyncReadRamException = class(EReadRamException);
  TReadRam = class(TIObject, IReadRamDevice)
  private
  protected
    // глобальные настройки при инициализации
    FAbstractDevice: TAbstractDevice;
    FStartDate, FDelayTime: TDateTime;
    // глобальные пользовательские настройки
    FFlagReadToFF, FFastSpeed: Boolean;
    FFromTime, FToTime: TDateTime;
    // данные по устройствам функция exec
    RAMAddrs: TAddressArray;
    FRAMInfo: IRAMInfo;
    FReadRamEvent: TReadRamEvent;
    // текущие данные по устройству
    Fadr: Byte;
//    FFileRam: string;
    FRamSize: Integer;
    FStream: TStream;
    // текущие данные по устройству продолжение
    FRecSize: Integer;
    FCurAdr, FFromAdr, FToAdr: Integer;
    FFromTimeAdr, FToTimeAdr: TDateTime;
    FRamXml: IXMLNode;
    FKoefTime: Double;

    FFlagTerminate: Boolean;

    procedure CheckCreateStream; virtual;
    procedure FillStream(Data: Byte; Size: Integer); virtual;
    procedure RoundKadrStream(); virtual;
    procedure FreeStream; virtual;

    function ProcToEnd: Double;
    function TestFF(P: PByte; n: Integer): Boolean;
  // IReadDeviceRAM
//    procedure SetReadTime(FromTime, ToTime: TDateTime); virtual; safecall;
//    function GetFromTime: TDateTime; virtual; safecall;
//    function GetToTime: TDateTime; virtual; safecall;
//    procedure SetReadToFF(Flag: Boolean); virtual; safecall;
//    function GetReadToFF: Boolean; virtual; safecall;
//    procedure SetFastSpeed(Flag: Boolean); virtual; safecall;
//    function GetFastSpeed: Boolean; virtual; safecall;
    procedure Execute(FromTime, ToTime: TDateTime; ReadToFF, FastSpeed: Boolean; evInfoRead: TReadRamEvent; Addrs: TAddressArray);virtual; safecall;
    procedure Terminate(Res: TResultEvent = nil); virtual; safecall;
    procedure CheckAndInitByAdr(Adr: Integer; MaxRam: Integer = 0; DefK: Double = 0; FromToAval: Boolean = True); virtual;
    procedure EndExecute(); virtual;
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

implementation

end.

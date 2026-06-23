unit UakiIntf;

interface

uses DeviceIntf, tools,
     Vcl.Graphics;

const
    ADR_AXIS_AZI  =  4;
    ADR_AXIS_ZU   =  2;
    ADR_AXIS_VIZ  = 12;
    ADR_UAKI      = 2412;
    ADR_UAKI_COM  = 2414;
    ADR_UAKI2     = 2415;
    ADR_UAKI_NET  = 2416;

type
  IAxis = interface
  // public
    procedure UpdateAngleData;
    procedure FindMarker;
    procedure TermimateMoving;
    procedure ClearDeltaAngle;
    procedure GotoAngle(Angle: TAngle; MaxSpeed: Integer = 255);

    function MotorToString: string;
    function MotorToColor: TColor;
    function ReperToString: string;
    function ReperToColor: TColor;
    function EndTumblerToString: string;
    function EndTumblerToColor: TColor;
    function ErrorToText: string;
  // private
    function GetEndTumbler: Char;
    function GetReper: Char;
    function GetMotor: Char;
    function GetError: Byte;

    function GetAdr: Integer;

    function GetCurrentAngle: TAngle;
    procedure SetCurrentAngle(Value: TAngle);

    function GetNeedAngle: TAngle;

    function GetDeltaAngle: TAngle;
    procedure SetDeltaAngle(Value: TAngle);

    function GetTOlerance: Double;
    procedure SetTolerance(const Value: Double);
  // public
    property Adr: Integer read GetAdr;

    property CurrentAngle: TAngle read GetCurrentAngle write SetCurrentAngle;
    property NeedAngle: TAngle read GetNeedAngle;
    property DeltaAngle: TAngle read GetDeltaAngle write SetDeltaAngle;

    property EndTumbler: Char read GetEndTumbler;
    property Motor     : Char read GetMotor;
    property Reper     : Char read GetReper;
    property Error     : Byte read GetError;

    property TOlerance: Double read GetTOlerance write SetTolerance;
  end;

  IAxisAZI = interface(IAxis)
   ['{0E823328-7AF5-4DBD-8C47-FEF35487E3D6}']
  end;
  IAxisZEN = interface(IAxis)
   ['{527C4B43-D75F-4E3B-B09E-6228A77DA457}']
  end;
  IAxisVIZ = interface(IAxis)
   ['{AC91E0DF-F4FE-46C5-AA3B-10D2D8A65695}']
  end;

  IUaki = interface(IDevice)
  ['{15857A2A-C3D8-48C9-845D-2837AAE10BC9}']

   function GetAzi: IAxisAZI;
   function GetZen: IAxisZEN;
   function GetViz: IAxisVIZ;

   function  GetTenPower(Index: Integer): Integer;
   procedure SetTenPower(Index, Value: Integer);
   function GetTemperature: TArray<Double>;

   function GetMagnitAmp: Double;
   procedure SetMagnitAmp(const Value: Double);

    function GetMaxTenPower: Integer;
    procedure SetMaxTenPower(const Value: Integer);

   procedure TenStop;
   procedure TenStart;
   function GetIsTenPower: Boolean;
   procedure SetIsTenPower(const Value: Boolean);
   procedure TermimateMoving;

   procedure Send(const cmd: string; ev: TReceiveUDPRef = nil; TimeOut: Integer = -1);

   property Azi: IAxisAZI read GetAzi;
   property Zen: IAxisZEN read GetZen;
   property Viz: IAxisVIZ read GetViz;

   property TenPower[Index: Integer]: Integer read GetTenPower write SetTenPower;
   property Temperature: TArray<Double> read GetTemperature;
   property IzTenPower: Boolean  read GetIsTenPower write SetIsTenPower;
   property MagnitAmp: Double  read GetMagnitAmp write SetMagnitAmp;
   property MaxTenPower: Integer  read GetMaxTenPower write SetMaxTenPower;

  end;

implementation

end.

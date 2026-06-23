unit LAS;

interface

uses System.SysUtils, JDtools;

 type
   [EnumCaptions('ANSI, DOS, UTF8')]
   LasEncoding = (lsenANSI, lsenDOS, lsenUTF8);

   LasSection = (lsVersion, lsWell, lsCurve, lsPar, lsOther, lsLog);

   PLasFormat = ^TLasFormat;
   TLasFormat = record
    Mnem, Units, Data, Description: string;
   end;

   ILasSection = interface
   ['{FB43B104-6675-41DB-8D84-D701239EF8BD}']
     function Priambula: TArray<string>; // Priambula[0] = '~Well infor...'
   end;

   IOptSection = interface(ILasSection)
   ['{38272858-4068-40A8-A3FF-BBF6C117BF8C}']
     procedure AddLine(const line: String);
   end;

   ILasFormatSection = interface(ILasSection) // vers weil ,curve, prm
   ['{36C840E5-08D9-4338-A9A8-9D06AFA3D836}']
    function GetItem(const Mnem: string): PLasFormat;
    procedure Add(const NewItem: TLasFormat);
    function Mnems: TArray<string>;
    function Formats: TArray<TLasFormat>;
    property Items[const Mnem: string]: PLasFormat read GetItem;
   end;

   ICurveSection = interface(ILasFormatSection)
   ['{BEFE1DE7-0C78-4A8B-9D33-AE9FD0B1DD06}']
    function GetDisplayFormat(const Mnem: string): string;
    procedure SetDisplayFormat(const Mnem, Value: string);
    property DisplayFormat[const Mnem: string]: string read GetDisplayFormat write SetDisplayFormat;
   end;

   ILasDataSection = interface(ILasSection)
   ['{5C20E1FA-D28F-445B-8EA3-AEF9CF43BB91}']
    function CheckData(const Data: array of Variant): Boolean;// ненужно
    procedure AddData(const Data: array of Variant);// Index: integer = -1; check: boolean = False);
    procedure Clear;
    function GetData: TArray<TArray<Variant>>;
    property Items: TArray<TArray<Variant>> read GetData;
   end;

   ILasDoc = interface
   ['{D2E9C18C-D003-45FC-A5ED-F2D14C339E5D}']
   //private
    function GetDataCount: Integer;
    function GetItem(const Mnem: string; Index: Integer): Variant;
    procedure SetItem(const Mnem: string; Index: Integer; const Value: Variant);
    function GetEncoding: LasEncoding;
    procedure SetEncoding(const Value: LasEncoding);
    function GetFileName: string;
   //public
    function Version: ILasFormatSection;
    function Well: ILasFormatSection;
    function Params: ILasFormatSection;
    function Curve: ICurveSection;
    function Data: ILasDataSection;
    function Other: IOptSection;

    procedure SaveToFile(const AFileName: String);
    procedure LoadFromFile(const AFileName: String);


    property Encoding: LasEncoding read GetEncoding write SetEncoding;

    property FileName: string read GetFileName;

    property DataCount: Integer read GetDataCount;
    property Item[const Mnem: string; Index: Integer]: Variant read GetItem write SetItem; default;
   end;

implementation

end.

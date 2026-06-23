unit MetaData2.XClasses;

interface

uses
  sysutils, Classes, TypInfo, RTTI, Generics.Collections,
  Xml.XMLIntf, Xml.XMLDoc,Xml.xmldom, debug_except;

   // ј“–»Ѕ”“џ

   // старший бит 1 - атрибут

   //1 0 -нет типа

   //  0byt 1-15 - атрибут

   //2 0x10 1 byte 32 - 47
   //3 0x20 2 byte
   //4 0x30 4 byte
   //5 0x40 8-byte
   //6 0x50 16-byte
   //7 0x60 32-byte
   //8 0x70 строки 112-127

   // TIPS
   // 0 -нет типа

   // объ€вление новых типов (структур)
   // 1,3,5-безым€нные структуры 1,2,4 bt len
   // 2,4,6-структуры с именем 1,2,4 bt len

   // 7 - об€вление переменной типа структуры без имени //-noname TDataStruct
   // 7,idx, attrs

   // 8 - об€вление переменной типа структуры с именем (//-name = dkfkfkfk) или поумолчанию —и им€ TNamedDataStruct
   // 8, idx, name attrs

   // 9 - об€вление переменной типа структуры  без имени (но именной структуры) //-structname (им€ из структуры с именем) TDataStruct
   // 9,idx, attrs
   //
   //  idx - пор€дковый номер объ€вленной структуры
   //

   /// встроенные простые типы
   //2 0x10 1 byt 16 - 31
   //  17..31- безым€нные
   //  16,18,20,22,24,..30 с именем
   // .....
   //8 0x70 64-byte
const
// LEN byte
  LEN_0 = 0;
  LEN_1 = $10;
  LEN_2 = $20;
  LEN_4 = $30;
  LEN_8 = $40;
  TP_STR = $70;
// ATTR
  ATTR = $80;
// IDX
  REC1_NAM = 2;
  REC2_NAM = 4;
  REC1_NONAM = 1;
  REC2_NONAM = 3;

  REC_DAT_NONAM = 7;
  REC_DAT_NAM = 8;
  REC_DAT_SNAM = 9;

  ATTR_WRK =     ATTR + LEN_0 + 1;
  ATTR_RAM =     ATTR + LEN_0 + 2;
  ATTR_EEP =     ATTR + LEN_0 + 3;
  ATTR_export =  ATTR + LEN_0 + 4;
//  ATTR_HideArray =  ATTR + LEN_0 + 5;
  ATTR_ShowHex =    ATTR + LEN_0 + 6;
  ATTR_ReadOnly =    ATTR + LEN_0 + 5;

  ATTR_digits  =    ATTR + LEN_1 + 3;
  ATTR_precision =  ATTR + LEN_1 + 4;

  ATTR_info =  ATTR + TP_STR + 0;
  ATTR_metr =  ATTR + TP_STR + 1;
  ATTR_eu =    ATTR + TP_STR + 2;
  ATTR_title = ATTR + TP_STR + 3;
  ATTR_hint =  ATTR + TP_STR + 4;
  ATTR_pasw =  ATTR + TP_STR + 5;

  NAM_1 = 0;
  NAM_2 = 2;
  NAM_3 = 4;
  NAM_4 = 6;
  NAM_5 = 8;
  NAM_6 = 10;
  NAM_7 = 12;
  NAM_8 = 14;
  NONAM_1 = 1;
  NONAM_2 = 3;
  NONAM_3 = 5;
  NONAM_4 = 6;
  NONAM_5 = 9;
  NONAM_6 = 11;
  NONAM_7 = 13;
  NONAM_8 = 15;
  ATTR_IDX_ARRAY = $F;
  ATTR_IDX_ARRAY_SHOW = $E;
  ATTR_IDX_RANGE_HI = $D;
  ATTR_IDX_RANGE_LO = $C;
  ATTR_IDX_DEFAULT_VALUE = $B;

{$REGION 'hide class defs'}

type

// ќЅў≈≈ ј“–»Ѕ”“џ ƒјЌЌџ≈ —“–” “”–џ

  TmetadataType = 0..255;

  TmetadataTypeHelp = record helper for TmetadataType
    function isAttr: Boolean;
    function isData: Boolean;
    function isStruct: Boolean;
    function isStrucDef: Boolean;
    function isStructData: Boolean;
    function isNamed: Boolean;
    function isString: Boolean;
    function Length: Integer;
  end;
  TCorrectType = function (t:TmetadataType; const value: string): TmetadataType;
  TXTyped = class;
  TXTypedClass = class of TXTyped;
  PTXypedArray = ^TXTypedArray;
  TXTypedArray = TArray<TXTyped>;
  TXTypedAggClass = class of TXTypedAgg;
  TXTypedAgg = class;
  TypedInfo = record
    Name: string;   //typeName
    Tip: TmetadataType;
    cls: TXTypedAggClass;
    // данные получают атрибут (если его нет) из родительской структуры
    // root Attribute
    ra: Boolean;
    // тип зависит от величины данных
    ct: TCorrectType;
  end;
  //  интерфейсы с типом от IXMLNode
  IXTyped = interface(IXMLNode)
  ['{0234623E-9DBC-43D9-BDAC-FB31236105FA}']
  //private
    function GetTip: TmetadataType;
    procedure SetTipInfo(const Value: TypedInfo);
    function GetTipInfo: TypedInfo;
  //public
    function ToBytes(): TBytes;
    function SizeOf(): Integer;

    property Tip: TmetadataType read GetTip;// write SetTip;
    property TipInfo: TypedInfo read GetTipInfo write SetTipInfo;
  end;
  IXAttr = interface(IXTyped)
  ['{8786AE85-29E2-4089-A1AF-5B4940612B1B}']
    function GetRootAttr: Boolean;
    property RootAttr: Boolean read GetRootAttr;
  end;
  IXData = interface(IXTyped)
  ['{1B0A418A-02E0-4831-A871-239241DD7C7A}']
  //private
    function GetName: string;
  //public
      // ƒл€ EEPROM пока не буду делать
//    function DataToBytes(): TBytes;
    function DataSizeOf(): Integer;
    property Name: string read GetName;
  end;
//   IStrucDef=interface(IXData)
//   ['{4BFAE895-C1BB-428F-AB79-C7443B28EE57}']
//   end;


  // атрибуты или данные могут иметь значение , реализованно ввидеTAggregatedObject
  IXValue = interface
  ['{23C184A2-8E72-494C-9616-C8402B0AF4E2}']
  //private
    function GetTval: TValue;
  //public
    procedure Assign(const SVal: string); overload;
    procedure Assign(PVal: Pointer); overload;
    function ToBytes(): TBytes;
    function SizeOf(): Integer;
    property TVal: TValue read GetTval;// write SetTval;
  end;

//  IXValue<T> = interface(IXValue)
//  ['{2855C5C0-7C48-4959-A610-82196E7C3F5D}']
//  end;

//// реализаци€ IXValue
  TXTypedAgg = class (TAggregatedObject)
   public
   class function PtrToStr(ptr: Pointer): string; virtual;
  end;

  TXTypedValue = class (TXTypedAgg, IXValue)
  protected
    function ToBytes(): TBytes; virtual;
    function SizeOf(): Integer; virtual;

    procedure Assign(const SVal: string); overload; virtual;
    procedure Assign(PVal: Pointer); overload; virtual;
    function GetTval: TValue; virtual;
  public
  property TVal: TValue read GetTval;// write SetTval;
  end;

  TStuctDefValue = class(TXTypedAgg);
  TStuctDataValue = class(TXTypedAgg);


  TXTypedValue<T> = class(TXTypedValue)//. IXValue<T>)
  protected
    procedure Assign(const SVal: string); overload; override;
    procedure Assign(PVal: Pointer); overload; override;
    function GetTval: TValue; override;
    function ToBytes(): TBytes; override;
    function SizeOf(): Integer; override;
  public
    type
      ptrT = ^T;
    var
      Value: T;
      PValue: ptrT;
    constructor CreateT(const Controller: IInterface; const Val: T);
    class function PtrToStr(ptr: Pointer): string; override;
  end;

  // 0
  TNone = class(TXTypedValue)
  end;
  // 1
  TUint8 = class(TXTypedValue<Byte>); //default
  TInt8 = class(TXTypedValue<ShortInt>);
  TChar = class(TXTypedValue<AnsiChar>);
  // 2
  TUint16 = class(TXTypedValue<Word>); //default
  TInt16 = class(TXTypedValue<SmallInt>);
  // 4
  TUInt32 = class(TXTypedValue<Cardinal>); //default
  TInt32 = class(TXTypedValue<Integer>);
  TFloat = class(TXTypedValue<Single>);
  // 8
  TUInt64 = class(TXTypedValue<UInt64>); //default
  TInt64 = class(TXTypedValue<Int64>);
  TDouble = class(TXTypedValue<Double>);
  // str
  TStr = class(TXTypedValue<string>);  //default


  // основной класс
  // заложен функционал атрибутов, данных и структур
  TXTyped = class abstract(TXMLNode, IXTyped)
  private
  protected
    FTyped: TypedInfo;
    FValue: TXTypedAgg;
    procedure SetTipInfo(const Value: TypedInfo); virtual;
    function GetTipInfo: TypedInfo;
    function GetTip: TmetadataType; virtual;
  public
    function Intf: IXMLNode;
    property Tip: TmetadataType read GetTip;
    property TipInfo: TypedInfo read GetTipInfo write SetTipInfo;
//    // metaData
    function ToBytes(): TBytes; virtual;
    function SizeOf(): Integer; virtual;
    destructor Destroy; override;
  end;


  // ******************* ј“–»Ѕ”“џ **************

  // виртуальные
  // name, noname, export -имеют 0 длину но вли€ют на метаданные
  TAttrVirtual = class abstract(TXTypedValue)
  public
    function ToBytes(): TBytes; override;
    function SizeOf(): Integer; override;
  end;
  // указывает, что это метаданные (пока может быть только одно)
 // TattrExport = class(TAttrVirtual);
  // измен€ет им€ переменной в коде C на пустое в метаданных
  TattrNoname = class(TAttrVirtual);
  // измен€ет им€ переменной  в коде C на значение атрибута в метаданных
  TattrName = class(TAttrVirtual);
  // им€ переменной = им€ именованной структуры
  TattrStructName = class(TAttrVirtual);

   TXAttr = class sealed(TXTyped, IXAttr, IXValue)
  private
    function GetRootAttr: Boolean;
    function GetValue: TXTypedValue;
  protected
  public
    function ToBytes(): TBytes; override;
    function SizeOf(): Integer; override;

     property Value: TXTypedValue read GetValue implements IXValue;
     property RootAttr: Boolean read GetRootAttr;
     // C header
     class function Factory(root: IXMLNode; attrInfo: TypedInfo; const value: string): TXAttr; overload;
     // Bin meta data
     class function Factory(root: IXMLNode; attrInfo: TypedInfo; value: Pointer): TXAttr; overload;
   end;

  // ***********ƒјЌЌџ≈******************

  TXData = class abstract(TXTyped, IXData)
  private
    function ToBytesAttr(): TBytes;
    function SizeOfAttr(): Integer;
  protected
    procedure CheckTipInfo;
    function GetTip: TmetadataType; override;
    function GetName: string; virtual;
    function AfterType: TBytes; virtual;
//    function DataToBytes(): TBytes; virtual; abstract;
    function DataSizeOf(): Integer; virtual; abstract;
    procedure SetTipInfo(const Value: TypedInfo); override;
    function CreateAttributeNode(const ADOMNode: IDOMNode): IXMLNode; override;
  public
    class var DefaultAttrClass: Boolean;
    function ToBytes(): TBytes; override;
    function SizeOf(): Integer; override;
    property Name: string read GetName;
  end;

  TXDataValue = class sealed(TXData, IXValue)
  private
    function GetValue: TXTypedValue;
  protected
//    function DataToBytes(): TBytes; override;
  public
     function DataSizeOf(): Integer; override;
     property Value: TXTypedValue read GetValue implements IXValue;
  end;

  // —“–” “”–џ
  TXStructDef = class sealed(TXData)
  private
    function ToBytesSubData(): TBytes;
    function SizeOfSubData(): Integer;
  protected
    function GetTip: TmetadataType; override;
    function AfterType: TBytes; override;
  public
    function DataSizeOf(): Integer; override;
    function ToBytes(): TBytes; override;
    function SizeOf(): Integer; override;
  end;


  TXTypedDocument = class(TXMLDocument)
  protected
    function GetChildNodeClass(const Node: IDOMNode): TXMLNodeClass; override;
  end;

{$ENDREGION}

function RangeCorrectType(t: TmetadataType; const value: string): TmetadataType;
function ArrayCorrectType(t: TmetadataType; const value: string): TmetadataType;

const
 ATR_ERR: TypedInfo = ();
 ATR_name: TypedInfo = (   Name: 'name'; Tip: ATTR; cls: TattrName );

  ATR_TYPES: array[0..39] of TypedInfo =(

   // атрибуты виртуальные  TAttrVirtual
    (   Name: 'name';           Tip: ATTR;    cls: TattrName  ),
    (    Name: 'noname';        Tip: ATTR;    cls: TattrNoname  ),
    (    Name: 'structname';    Tip: ATTR;    cls: TattrStructName  ),

   // атрибуты реальные TXAttr
   // STR
    (    Name: 'info';        Tip: ATTR_info;    cls: TStr ), //f0
    (    Name: 'metr';        Tip: ATTR_metr;    cls: TStr  ), //f1
    (    Name: 'eu';          Tip: ATTR_eu;      cls: TStr; ra:True ), //f2
    // diagram
    (    Name: 'title';       Tip: ATTR_title;   cls: TStr  ),
    (    Name: 'hint';        Tip: ATTR_hint;    cls: TStr; ra:True ),
    //безопасность
    (    Name: 'password';    Tip: ATTR_pasw;      cls: TStr ), //f5
   // len=0
    (    Name: 'WRK';         Tip: ATTR_WRK;          cls: TNone  ),//0x81
    (    Name: 'RAM';         Tip: ATTR_RAM;          cls: TNone  ),//0x82
    (    Name: 'EEP';         Tip: ATTR_EEP;          cls: TNone  ),//0x83
    (    Name: 'export';      Tip: ATTR_export;       cls: TNone  ),//0x84
    (    Name: 'ShowHex';     Tip: ATTR_ShowHex;      cls: TNone; ra:True   ), //85
    (    Name: 'readonly';     Tip: ATTR_ReadOnly;      cls: TNone; ra:True   ), //86
   // len=1
    (    Name: 'adr';             Tip: ATTR + LEN_1 + 0;    cls: TUint8 {,ct AdrCorrectTupe}), //0x90
    //TODO: adr word
    //(    Name: 'adr';             Tip: $A4;    cls: TUint16 {,ct AdrCorrectTupe} ), //0x90
    (    Name: 'chip';            Tip: ATTR + LEN_1 + 1;    cls: TUint8  ), //0x91
    (    Name: 'NoPowerDataCount';Tip: ATTR + LEN_1 + 2;    cls: TUint8  ), //0x92
    (    Name: 'digits';          Tip: ATTR_digits;    cls: TUint8; ra:True   ), //0x93
    (    Name: 'precision';       Tip: ATTR_precision;    cls: TUint8; ra:True   ),
    // diagram
    (    Name: 'style';           Tip: ATTR + LEN_1 + 5;    cls: TUint8; ra:True   ),
    // diagram
    (    Name: 'width';           Tip: ATTR + LEN_1 + 6;    cls: TUint8; ra:True   ),
    (    Name: 'SubAdr';           Tip: ATTR + LEN_1 + 7;    cls: TUint8), //0x97
   // len=2
    (    Name: 'serial';              Tip: ATTR+ LEN_2 + 0;    cls: TUint16  ), //0xA0
    (    Name: 'RamSize';             Tip: ATTR+ LEN_2 + 1;    cls: TUint16  ), //0xA1
    (    Name: 'SupportUartSpeed';    Tip: ATTR+ LEN_2 + 2;    cls: TUint16  ), //0xA2
    (    Name: 'from';                Tip: ATTR+ LEN_2 + 3;    cls: TUint16  ), //0xA3
   // len=4
    // diagram
    (    Name: 'color';               Tip: ATTR+ + LEN_4 + 0;    cls: TUint32; ra:True ),  //0xB0
    (    Name: 'SSDSize';             Tip: ATTR+ + LEN_4 + 1;    cls: TUint32  ),          //0xB1
    (    Name: 'profile';             Tip: ATTR+ + LEN_4 + 2;    cls: TUint32  ),          //0xB2
//    (    Name: 'UnixTime';            Tip: ATTR+ + LEN_4 + 2;    cls: TUint32  ),
   // array (int) avilable len 1,2
    (    Name: 'array';     Tip: ATTR+ LEN_1 + ATTR_IDX_ARRAY;    cls: TUint8;   ct: ArrayCorrectType ),// 0x9F
    (    Name: 'array';     Tip: ATTR+ LEN_2 + ATTR_IDX_ARRAY;    cls: TUint16;  ct: ArrayCorrectType ),// 0xAF
   // Show array (int) avilable len 1,2
   //    (    Name: 'HideArray';   Tip: ATTR_HideArray;    cls: TNone; ra:True   ),
//    (    Name: 'arrayShowLen'; Tip: ATTR+ LEN_0 + ATTR_IDX_ARRAY_SHOW; cls: TNone;  ra:True; ct: ArrayCorrectType ),
    (    Name: 'arrayShowLen'; Tip: ATTR+ LEN_1 + ATTR_IDX_ARRAY_SHOW; cls: TUint8;  ra:True; ct: ArrayCorrectType ),
    (    Name: 'arrayShowLen'; Tip: ATTR+ LEN_2 + ATTR_IDX_ARRAY_SHOW; cls: TUint16; ra:True; ct: ArrayCorrectType ),
    // Range
    (Name: 'RangeLo'; Tip: ATTR + LEN_1 + ATTR_IDX_RANGE_LO; cls: Tint8;  ra:True;  ct: RangeCorrectType ),
    (Name: 'RangeLo'; Tip: ATTR + LEN_2 + ATTR_IDX_RANGE_LO; cls: Tint16; ra:True;  ct: RangeCorrectType ),
    (Name: 'RangeLo'; Tip: ATTR + LEN_4 + ATTR_IDX_RANGE_LO; cls: Tfloat; ra:True;  ct: RangeCorrectType ),
    (Name: 'RangeHi'; Tip: ATTR + LEN_1 + ATTR_IDX_RANGE_HI; cls: Tint8;  ra:True;  ct: RangeCorrectType ),
    (Name: 'RangeHi'; Tip: ATTR + LEN_2 + ATTR_IDX_RANGE_HI; cls: Tint16; ra:True;  ct: RangeCorrectType ),
    (Name: 'RangeHi'; Tip: ATTR + LEN_4 + ATTR_IDX_RANGE_HI; cls: Tfloat; ra:True;  ct: RangeCorrectType )
);


  STD_TYPES: array[0..10] of TypedInfo =(
  // простые типы данных
    (    Name: 'uint8_t';    Tip: LEN_1 + NAM_1;    cls: TUint8 ), //0x10 0x11
    (    Name: 'int8_t';     Tip: LEN_1 + NAM_2;    cls: Tint8  ), //0x12 0x13
    (    Name: 'char';       Tip: LEN_1 + NAM_3;    cls: TChar  ),

    (    Name: 'uint16_t';    Tip: LEN_2 + NAM_1;    cls: TUint16  ), //0x20 0x21
    (    Name: 'int16_t';     Tip: LEN_2 + NAM_2;    cls: Tint16  ),  //0x22 0x23

    (    Name: 'uint32_t';    Tip: LEN_4 + NAM_1;    cls: TUint32  ),
    (    Name: 'int32_t';     Tip: LEN_4 + NAM_2;    cls: Tint32  ),
    (    Name: 'float';       Tip: LEN_4 + NAM_3;    cls: TFloat  ), //0x34 0x35

    (    Name: 'uint64_t';   Tip: LEN_8 + NAM_1;    cls: TUint64  ),
    (    Name: 'int64_t';    Tip: LEN_8 + NAM_2;    cls: Tint64  ),
    (    Name: 'double';     Tip: LEN_8 + NAM_3;    cls: TDouble  )
    );

  STD_TYPES_UNK: array[0..3] of TypedInfo =(
  // простые типы данных по умолчанию
    (    Name: 'uint8_t';    Tip: LEN_1 + NAM_1;    cls: TUint8 ),
    (    Name: 'uint16_t';    Tip: LEN_2 + NAM_1;    cls: TUint16  ),
    (    Name: 'uint32_t';    Tip: LEN_4 + NAM_1;    cls: TUint32  ),
    (    Name: 'uint64_t';   Tip: LEN_8 + NAM_1;    cls: TUint64  ));



    STR_struct: TypedInfo = (    Name: 'struct';      Tip: REC_DAT_NAM;    cls: TStuctDataValue);
    STR_struct_t: TypedInfo = (    Name: 'struct_t';      Tip: REC_DAT_NAM;    cls: TStuctDataValue);

    STR_TYPES_DEF: array[0..3] of TypedInfo =(

    (    Name: 'struct_t';    Tip: REC1_NONAM;    cls: TStuctDefValue),    //1  L:1 metalen
    (    Name: 'struct_t';    Tip: REC1_NAM;    cls: TStuctDefValue),      //2  L:1
    (    Name: 'struct_t';    Tip: REC2_NONAM;    cls: TStuctDefValue),    //3  L:2
    (    Name: 'struct_t';    Tip: REC2_NAM;    cls: TStuctDefValue)       //4  L:2
    );

    STR_TYPES_DAT: array[0..2] of TypedInfo =(

    (    Name: 'struct';      Tip: REC_DAT_NONAM;    cls: TStuctDataValue), //7 L:1 index
    (    Name: 'struct';      Tip: REC_DAT_NAM;    cls: TStuctDataValue),   //8 L:1 + name
    (    Name: 'struct';      Tip: REC_DAT_SNAM;    cls: TStuctDataValue)   //9 L:1
    );

    STR_TYPES: array[0..6] of TypedInfo = (

    (    Name: 'struct_t';    Tip: REC1_NONAM;    cls: TStuctDefValue),
    (    Name: 'struct_t';    Tip: REC1_NAM;    cls: TStuctDefValue),
    (    Name: 'struct_t';    Tip: REC2_NONAM;    cls: TStuctDefValue),
    (    Name: 'struct_t';    Tip: REC2_NAM;    cls: TStuctDefValue),
    (    Name: 'struct';      Tip: REC_DAT_NONAM;    cls: TStuctDataValue),
    (    Name: 'struct';      Tip: REC_DAT_NAM;    cls: TStuctDataValue),
    (    Name: 'struct';      Tip: REC_DAT_SNAM;    cls: TStuctDataValue)
    );

function StrToAnsiBytes(const val: string): TBytes;
function StrAsInt(val: string): Integer;
function StrAsInt64(val: string): Int64;
function XTypedDocument(Version: DOMString = '1.0'): IXMLDocument;

implementation


function RangeCorrectType(t:TmetadataType; const value: string): TmetadataType;
 var
  i: Integer;
  lt: Byte;
begin
  t := t and $8F;
  if TryStrToInt(value, i) then
   begin
    i := Abs(i);
    if i <= 255 then lt := LEN_1
    else if i <= $FFFF then lt := LEN_2
    else lt := LEN_4
   end
  else  lt := LEN_4;
  Result := t or lt;
end;

function ArrayCorrectType(t:TmetadataType; const value: string): TmetadataType;
 var
  l: Integer;
begin
  t := t and $8F;
  l := StrToIntDef(value, 0);
  if l>255 then Result := t + LEN_2
  else Result :=  t + LEN_1
end;


function XTypedDocument(Version: DOMString = '1.0'): IXMLDocument;
begin
  Result := TXTypedDocument.Create(nil);
//  <?xml-stylesheet type='text/xsl' href='meta.xsl'?>
  Result.Active := True;
  if Version <> '' then
    Result.Version := Version;
end;


function StrAsInt64(val: string): Int64;
begin
  // default
  if val = '' then Exit(0);
  if val.StartsWith('0x', True) then
     val := val.Replace('0x', '$', [rfIgnoreCase]);
  Result := val.ToInt64();
end;

function StrAsInt(val: string): Integer;
// var
  //c: Cardinal;
begin
  // default
  if val = '' then Exit(0);
  if val.StartsWith('0x', True) then
    val := val.Replace('0x', '$', [rfIgnoreCase]);
//  try
   Result := StrToInt(val);//.ToInteger();
  //except
//   c := StrToUInt(val);
  // Result := PInteger(@c)^;//.ToInteger();  4278190335
//  end;
end;

function StrToAnsiBytes(const val: string): TBytes;
var
  s: PAnsiChar;
  Marshall: TMarshaller;
begin
  Result := [];
  if val = '' then Exit;

  s := Marshall.AsAnsi(val).ToPointer;
                //type          //0 term
  SetLength(Result, length(s) + 1);
  Move(s^, Result[0], length(s) + 1);
end;


{$REGION 'Data'}

{$REGION 'TmetadataTypeHelp'}
{ TmetadataTypeHelp }

function TmetadataTypeHelp.isAttr: Boolean;
begin
  Result := self > $80;
end;

function TmetadataTypeHelp.isData: Boolean;
begin
  Result := (Self <= $6F) and (Self >= $10);
end;

//function TmetadataTypeHelp.isIDX(idx: Byte): Boolean;
//begin
//  Result := (Self and $F) = idx;
//end;

function TmetadataTypeHelp.isNamed: Boolean;
begin
  Result := not isAttr and ((Self and 1) = 0)
end;

function TmetadataTypeHelp.isStruct: Boolean;
begin
  Result := (Self <= 9) and (Self > 0)
end;

function TmetadataTypeHelp.isStructData: Boolean;
begin
  Result := (Self >= 7) and (Self <= 9)
end;

function TmetadataTypeHelp.isStrucDef: Boolean;
begin
  Result := (Self < 7) and (Self > 0)
end;

function TmetadataTypeHelp.isString: Boolean;
begin
  Result := (Self and $70) = $70;
end;

function TmetadataTypeHelp.Length: Integer;
var
  lenPw: Integer;
begin
  if self = 0 then
    Exit(-1)
  else if self = $80 then
    Exit(-1)
  else if isString then
    Exit(-2)
  else if isStrucDef then
  begin
    lenPw := Self;
    if isNamed then
      Dec(lenPw);
    if lenPw = 3 then exit(2)
    else exit(1);
  end
  else if isStructData then
    Exit(1)
  else
    lenPw := (Self and $70) shr 4;

  if lenPw = 0 then
    Result := 0
  else
    Result := 1 shl (lenPw - 1);
end;
{$ENDREGION}

procedure TXTypedValue<T>.Assign(PVal: Pointer);
begin
  if not Assigned(PVal) then Exit;
  PValue := PVal;
  if GetTypeKind(T) in [tkInteger, tkInt64,tkFloat] then
    Value := PValue^
  else
    PString(@Value)^ := string(PAnsiChar(PVal));
end;

procedure TXTypedValue<T>.Assign(const SVal: string);
var
  ti: PTypeInfo;
  s: Single;
  d: Double;
begin
  ti := TypeInfo(T);
  case ti.Kind of
    tkInteger:
      begin
        var i := StrAsInt(SVal);
        move(i, Value, System.SizeOf(T));
      end;
    tkInt64:
      begin
        var i := StrAsInt64(SVal);
        move(i, Value, System.SizeOf(T));
      end;
    tkFloat:
      case ti.TypeData.FloatType of
        ftSingle:
          begin
            if SVal ='' then s := 0
            else s := SVal.ToSingle;
            move(s, Value, System.SizeOf(T));
          end;
        ftDouble:
          begin
            if SVal ='' then d := 0
            else d := SVal.ToDouble;
            move(d, Value, System.SizeOf(T));
          end;
      else
        begin
       //ftExtended, ftComp, ftCurr
        end;
      end;
  else
    begin
      PString(@Value)^ := SVal;
    end;
  end;
end;

constructor TXTypedValue<T>.CreateT(const Controller: IInterface; const Val: T);
begin
  inherited Create(Controller);
  Value := Val;
end;

function TXTypedValue<T>.GetTval: TValue;
begin
  Result := TValue.From<T>(Value);
end;

function TXTypedValue<T>.SizeOf: Integer;
begin
  if GetTypeKind(T) in [tkInteger, tkInt64,tkFloat] then
     Result := System.SizeOf(T)
  else
    Result := Length(StrToAnsiBytes(Tval.AsString));
end;

function TXTypedValue<T>.ToBytes: TBytes;
begin
  if GetTypeKind(T) in [tkInteger, tkInt64,tkFloat] then
   begin
    SetLength(Result, System.SizeOf(T));
    move(Value, Result[0], System.SizeOf(T));
   end
  else
    Result := StrToAnsiBytes(Tval.AsString);
end;

class function TXTypedValue<T>.PtrToStr(ptr: Pointer): string;
begin
  if GetTypeKind(T) in [tkInteger, tkInt64,tkFloat] then
    Result := TValue.From<T>(ptrT(ptr)^).ToString
  else
    Result := string(PAnsiChar(Ptr));
end;

function TAttrVirtual.SizeOf: Integer;
begin
  Result := 0;
end;

function TAttrVirtual.ToBytes: TBytes;
begin
  Result := [];
end;

{ TXTypedAgg }

class function TXTypedAgg.PtrToStr(ptr: Pointer): string;
begin
  Result := '';
end;

{ TXTypedValue }

procedure TXTypedValue.Assign(PVal: Pointer);
begin
end;

procedure TXTypedValue.Assign(const SVal: string);
begin
end;

function TXTypedValue.GetTval: TValue;
begin
  Result := TValue.Empty;
end;

function TXTypedValue.SizeOf: Integer;
begin
  Result := 0;
end;

function TXTypedValue.ToBytes: TBytes;
begin
  Result := [];
end;

{$ENDREGION}


 { TXTyped}

destructor TXTyped.Destroy;
begin
//  TDebug.Log('TXTyped.Destroy %s, %x', [FTyped.Name, FTyped.Tip]);
  if Assigned(FValue) then FValue.Free;
  inherited;
end;

function TXTyped.SizeOf: Integer;
begin
  Result := 1;
end;

function TXTyped.GetTip: TmetadataType;
begin
  Result := FTyped.Tip;
end;

function TXTyped.GetTipInfo: TypedInfo;
begin
  Result := FTyped;
end;

procedure TXTyped.SetTipInfo(const Value: TypedInfo);
begin
  FTyped := Value;
  if Assigned(FValue) then FValue.Free;
  FValue := Value.cls.Create(self);
end;

function TXTyped.Intf: IXMLNode;
begin
  Result := Self as IXMLNode;
end;

function TXTyped.ToBytes: TBytes;
begin
  Result := [Tip];
end;


{ TXAttr }

class function TXAttr.Factory(root: IXMLNode; attrInfo: TypedInfo; value: Pointer): TXAttr;
begin
  Result := Factory(root,attrInfo, attrInfo.cls.PtrToStr(value));
end;

class function TXAttr.Factory(root: IXMLNode; attrInfo: TypedInfo; const value: string): TXAttr;
begin
  root.Attributes[attrInfo.Name] := value;
  Result := root.AttributeNodes[attrInfo.Name] as TXAttr;
end;

function TXAttr.GetRootAttr: Boolean;
begin
  Result :=  FTyped.ra;
end;

function TXAttr.GetValue: TXTypedValue;
begin
  Result := FValue as TXTypedValue;
end;

function TXAttr.SizeOf: Integer;
begin
  if FTyped.Tip.isAttr then
       Result := inherited + Value.SizeOf
  else
   Result := 0;
end;

function TXAttr.ToBytes: TBytes;
begin
  if FTyped.Tip.isAttr then
       Result := inherited + Value.ToBytes
  else
   Result := [];
end;

{ TXData }

procedure TXData.CheckTipInfo;
begin
  if FTyped.Tip = 0 then
   begin
    if not Intf.HasAttribute('tip') then raise Exception.Create('TXData not HasAttribute(tip)');
    FTyped.Tip := StrToInt('$'+Intf.Attributes['tip']);
    if Tip.isData then
     begin
      for var d in STD_TYPES do
       if d.Tip = (FTyped.Tip and $FE) then
        begin
         var dt := d;
         dt.Tip := FTyped.Tip;
         TipInfo := dt;
         Exit
        end;
       for var d in STD_TYPES_UNK do
       if d.Tip = (FTyped.Tip and $F0) then
        begin
         var dt := d;
         dt.Tip := FTyped.Tip;
         TipInfo := dt;
         Exit
        end;
     end
    else for var t in STR_TYPES do if t.Tip = FTyped.Tip then
     begin
      TipInfo := t;
      Exit;
     end;
    raise Exception.Create(Format('Error  Tip [%x] ',[FTyped.Tip]))
   end;
end;

function TXData.CreateAttributeNode(const ADOMNode: IDOMNode): IXMLNode;
begin
//  TDebug.Log('TXAttr.Create (%s), (%s)',  [ADOMNode.nodeName, ADOMNode.nodeValue]);
//  for var a in LocalAttrDatas do if a.Name = ADOMNode.nodeName then Exit(CrA(a));
 if not DefaultAttrClass then
  for var a in ATR_TYPES do if a.Name = ADOMNode.nodeName then
   begin
    var Res := TXAttr.Create(ADOMNode, nil, OwnerDocument);
    Result := Res;
    var rt := a;
    if Assigned(a.ct) then
     begin
      var t := a.ct(a.Tip, ADOMNode.nodeValue);
      for var d in ATR_TYPES do if d.Tip = t then
       begin
        rt := d;
        Break;
       end;
     end;
    Res.TipInfo := rt;
    if not rt.cls.InheritsFrom(TAttrVirtual) then
       Res.Value.Assign(ADOMNode.nodeValue);
    Exit();
   end;
//  TDebug.Log('inherited Create (%s), (%s)',  [ADOMNode.nodeName, ADOMNode.nodeValue]);
  result := inherited;
//  raise Exception.CreateFmt('TXTyped.CreateAttributeNode (%s) (%s)',[ADOMNode.nodeName, ADOMNode.nodeValue]);
end;

function TXData.AfterType: TBytes;
begin
  if Tip.isStructData then Result := [intf.Attributes['index']]
  else Result := []
end;

function TXData.GetName: string;
begin
  if intf.HasAttribute('name') then Result := intf.Attributes['name']
  else Result := '';
end;

function TXData.GetTip: TmetadataType;
begin
  CheckTipInfo;
  Result := inherited;
end;

procedure TXData.SetTipInfo(const Value: TypedInfo);
begin
  inherited;
  Intf.Attributes['tip'] :=  Byte(Value.Tip).ToHexString;
end;


function TXData.SizeOfAttr: Integer;
begin
  Result := 0;
 // TDebug.Log('NodeName %s Name %s', [Intf.NodeName, Name]);
  for var i := 0 to Intf.AttributeNodes.Count-1 do
   begin
    var a := Intf.AttributeNodes[i];
   // TDebug.Log('    AttrName %s val %s', [a.NodeName, a.NodeValue]);
    if Supports(a, IXAttr) then
     begin
      var Ta := a as TXAttr;
      Result := Result + ta.SizeOf;
     end;
   end;
end;

function TXData.ToBytesAttr: TBytes;
begin
  Result := [];
 // TDebug.Log('NodeName %s Name %s', [Intf.NodeName, Name]);
  for var i := 0 to Intf.AttributeNodes.Count-1 do
   begin
    var a := Intf.AttributeNodes[i];
  //  TDebug.Log('    AttrName %s val %s', [a.NodeName, a.NodeValue]);

    if Supports(a, IXAttr) then
     begin
      var Ta := a as TXAttr;
      Result := Result + ta.ToBytes;
     end;
   end;
end;

function TXData.SizeOf: Integer;
begin
  Result := inherited + Length(AfterType) + Length(StrToAnsiBytes(Name)) + SizeOfAttr;
end;

function TXData.ToBytes: TBytes;
begin
  Result := inherited + AfterType + StrToAnsiBytes(Name) + ToBytesAttr;
end;


{ TXDataValue }

function TXDataValue.DataSizeOf: Integer;
begin
  if tip.isData then
   begin
    Result := Value.SizeOf;
    if Intf.HasAttribute('array')then Result := Result * Intf.Attributes['array'];
   end
   else raise Exception.Create('cant find struct data len');
end;

function TXDataValue.GetValue: TXTypedValue;
begin
  CheckTipInfo;
  Result := FValue as TXTypedValue;
end;

{ TXStructDef }

function TXStructDef.AfterType: TBytes;
 var
  len: Integer;
begin
  len := 1 + 1 + Length(StrToAnsiBytes(Name)) + SizeOfAttr + SizeOfSubData;
  if len <= 255 then
    SetLength(Result,1)
  else
   begin
    Inc(len);
    SetLength(Result,2);
   end;
  move(len, Result[0], Length(Result));
end;

function TXStructDef.DataSizeOf: Integer;
begin
  Result := 0;
  for var i:= 0 to Intf.ChildNodes.Count-1 do Result := Result + (Intf.ChildNodes[i] as TXData).DataSizeOf;
end;

function TXStructDef.GetTip: TmetadataType;
 var
  len: Integer;
begin
  len := 1 + 1 + Length(StrToAnsiBytes(Name)) + SizeOfAttr + SizeOfSubData;
  if len <= 255 then Result := REC1_NONAM
  else Result := REC2_NONAM;
  if Name <> '' then Inc(Result);
  FTyped.Tip := Result;
  Intf.Attributes['tip'] :=  Byte(Result).ToHexString;
end;

function TXStructDef.SizeOf: Integer;
begin
  Result := inherited + SizeOfSubData();
end;

function TXStructDef.SizeOfSubData: Integer;
begin
  Result := 0;
  for var i:= 0 to Intf.ChildNodes.Count-1 do Result := Result + (Intf.ChildNodes[i] as TXData).SizeOf;
end;

function TXStructDef.ToBytes: TBytes;
begin
  Result := inherited + ToBytesSubData();
end;

function TXStructDef.ToBytesSubData: TBytes;
begin
  Result := [];
  for var i:= 0 to Intf.ChildNodes.Count-1 do Result := Result + (Intf.ChildNodes[i] as TXData).ToBytes;
end;

{ TXTypedDocument }

function TXTypedDocument.GetChildNodeClass(const Node: IDOMNode): TXMLNodeClass;
begin
  Result := nil;
  if Node.nodeName = 'root' then Exit;
  if Node.nodeName = 'struct_t' then Exit(TXStructDef)
  else Exit(TXDataValue);
end;

end.


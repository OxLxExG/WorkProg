unit MetaData2.Classes;

interface

uses
  sysutils, Classes, TypInfo, RTTI, Generics.Collections, Xml.XMLIntf;

   // АТРИБУТЫ

   // старший бит 1 - атрибут

   //1 0 -нет типа

   //  0byt 1-15 - атрибут

   //2 0x10 1 byt 32 - 47
   //3 0x20 2 byt
   //4 0x30 4 byt
   //5 0x40 8-byt
   //6 0x50 16-byt
   //7 0x60 32-byt
   //8 0x70 строки 112-127

   // TIPS
   // 0 -нет типа

   // обявление новых типов (структур)
   // 1,3,5-безымянные структуры 1,2,4 bt len
   // 2,4,6-структуры с именем 1,2,4 bt len

   // 7 - обявление переменной типа структуры без имени //-noname TDataStruct
   // 7,idx, attrs

   // 8 - обявление переменной типа структуры с именем (//-name = dkfkfkfk) или поумолчанию Си имя TNamedDataStruct
   // 8, idx, name attrs

   // 9 - обявление переменной типа структуры  без имени (но именной структуры) //-structname (имя из структуры с именем) TDataStruct
   // 9,idx, attrs
   //
   //  idx - порядковый номер объявленной структуры
   //

   /// встроенные простые типы
   //2 0x10 1 byt 16 - 31
   //  17..31- безымянные
   //  16,18,20,22,24,..30 с именем
   // .....
   //8 0x70 64-byt
const
// LEN
  LEN_0 = 0;
  LEN_1 = $10;
  LEN_2 = $20;
  LEN_4 = $30;
  LEN_8 = $40;
  TP_STR = $70;
// ATTR
  ATTR = $80;
// IDX
  REC1_NAM_1 = 2;
  REC2_NAM_1 = 4;
  REC1_NONAM_1 = 1;
  REC2_NONAM_1 = 3;

  REC_DAT_NONAM = 7;
  REC_DAT_NAM = 8;
  REC_DAT_SNAM = 9;

  ATTR_WRK =     ATTR + LEN_0 + 1;
  ATTR_RAM =     ATTR + LEN_0 + 2;
  ATTR_EEP =     ATTR + LEN_0 + 3;
  ATTR_export =  ATTR + LEN_0 + 4;
  ATTR_HideArray =  ATTR + LEN_0 + 5;
  ATTR_ShowHex =    ATTR + LEN_0 + 6;

  ATTR_digits  =    ATTR + LEN_1 + 3;
  ATTR_precision =  ATTR + LEN_1 + 4;

  ATTR_info =  ATTR + TP_STR + 0;
  ATTR_metr =  ATTR + TP_STR + 1;
  ATTR_eu =    ATTR + TP_STR + 2;
  ATTR_title = ATTR + TP_STR + 3;

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
  ATTR_IDX_RANGE_HI = $E;
  ATTR_IDX_RANGE_LO = $D;
  ATTR_IDX_DEFAULT_VALUE = $C;
//  ATTR_IDX_SECTION = 6;

{$REGION 'hide class defs'}

type

// ОБЩЕЕ АТРИБУТЫ ДАННЫЕ СТРУКТУРЫ

  TmetadataType = 0..255;

  TmetadataTypeHelp = record helper for TmetadataType
    function isAttr: Boolean;
//    function isIDX(idx: Byte): Boolean;
    function isData: Boolean;
    function isStruct: Boolean;
    function isStructTypedef: Boolean;
    function isStructData: Boolean;
    function isNamed: Boolean;
    function isString: Boolean;
    function Length: Integer;
  end;
  // основной класс
  // заложен функционал атрибутов, данных и структур
  TTyped = class;
  TTypedClass = class of TTyped;
  PTypedArray = ^TTypedArray;
  TTypedArray = TArray<TTyped>;
  TTyped = class
  protected
    function InerToBytes(a: TTypedArray): TBytes;
    function InerSizeOf(a: TTypedArray): Integer;
    function GetTip: TBytes; virtual;
    function GetSizeOrValue: TBytes; virtual;
    function GetName: TBytes; virtual;
    function GetTval: TValue; virtual;
    procedure SetTval(v: TValue); virtual;
  public
    Tip: TmetadataType;
    Name: string;
    TypeName: string;
    RootAttr: Boolean;
    SVal: string;
    Attr: TTypedArray;
    SubData: TTypedArray;

    // переменные для данных
    parent: TTyped;
    // смещение в WRK RAM EEP
    dataOffset: Integer;
    // смещение в родительской структуре
    localOffset: Integer;
    // длина данных в байтах
    dataSize: Integer;

    //  для быстроты дублируют стандартные атрибуты
    // атрибуты: текстовое отображение
    // при инициализации извлекаются из атрибутов
    digits, precision: Integer;// from attr
    AsHex: Boolean; // from attr ATTR_ShowHex
    // array Support
    // атрибуты:
    ArrayLength: Integer; // from attr
    // текстовое отображение
    HideArray: Boolean;   // from attr
    // hints, help
    info: string; // from attr
    // текстовый не ole заголоок
    title: string; // from attr
    // единицы измерения
    eu: string; // from attr

    property TVal: TValue read GetTval write SetTval;

    // tools

    // для данных: атрибуты массива, текстового представления(hex, digits, precision), hints, help,
    // единицы измерения
    // при инициализации извлекаются из атрибутов
    procedure InitStandartDataAttr;
    procedure InitParentDataAttr;
    function GetAttr(tst: byte; mack: byte = $FF): TTyped;
    function GetAttrAs<T>(def: T; tst: byte; mack: byte = $FF): T;
//    function IsArray: Boolean;
    function AttrContains(ATip: TmetadataType): Boolean;
    procedure Remove(item: TTyped; IsSubData: Boolean = False);
    // для данных
    procedure UpdateValue(ptr: Pointer); virtual;
    //
    function ToBytes(): TBytes; virtual;
    // metaData
    function SizeOf(): Integer; virtual;
    // для данных
    function DataSizeOf(): Integer; virtual;
    // для данных
    function ValAsStr(showEu: Boolean = True): string; virtual;
    constructor Create(aTip: TmetadataType; const StrVal: string = ''); overload; virtual;
    constructor Create(aTip: TmetadataType; const PtrVal: Pointer); overload; virtual;
    //(XML) конструктор для данных
    constructor Create(root: IXMLNode); overload; virtual;
    destructor Destroy; override;
  end;

  TTypedValue = class(TTyped);

  TTypedValue<T> = class(TTypedValue)
  protected
    function GetTval: TValue; override;
    procedure SetTval(v: TValue); override;
    function GetSizeOrValue: TBytes; override;
  public
    type
      ptrT = ^T;
    var
      Value: T;
      PValue: ptrT;

    function ValAsStr(showEu: Boolean = True): string; override;
    procedure UpdateValue(ptr: Pointer); override;
    //(Си) конструктор для атрибутов
    constructor Create(aTip: TmetadataType; const StrVal: string = ''); override;
    //(Бин) конструктор для атрибутов
    constructor Create(aTip: TmetadataType; const PtrVal: Pointer);  override;
    constructor CreateT(aTip: TmetadataType; const Val: T);
    //(XML) конструктор для данных
//    constructor CreateXML(root: IXMLNode);  override;

    class function PtrToStr(ptr: Pointer): string;
  end;

  // 0
  TNone = class(TTyped)
    constructor Create(aTip: TmetadataType; const PtrVal: Pointer); override;
  end;
  // 1
  TUint8 = class(TTypedValue<Byte>); //default
  TInt8 = class(TTypedValue<ShortInt>);
  // 2
  TUint16 = class(TTypedValue<Word>); //default
  TInt16 = class(TTypedValue<SmallInt>);
  // 4
  TUInt32 = class(TTypedValue<Cardinal>); //default
  TInt32 = class(TTypedValue<Integer>);
  TFloat = class(TTypedValue<Single>);
  // 8
  TUInt64 = class(TTypedValue<UInt64>); //default
  TInt64 = class(TTypedValue<Int64>);
  TDouble = class(TTypedValue<Double>);
  // str
  TStr = class(TTypedValue<string>)  //default
  protected
    function GetSizeOrValue: TBytes; override;
  end;

  // АТРИБУТЫ

  // виртуальные
  // name, noname, export -имеют 0 длину но влияют на метаданные
  TAttrVirtual = class abstract(TTyped)
  public
    function ToBytes(): TBytes; override;
    function SizeOf(): Integer; override;
  end;
  // указывает, что это метаданные (пока может быть только одно)
 // TattrExport = class(TAttrVirtual);
  // изменяет имя переменной в коде C на пустое в метаданных
  TattrNoname = class(TAttrVirtual);
  // изменяет имя переменной  в коде C на значение атрибута в метаданных
  TattrName = class(TAttrVirtual);
  // имя переменной = имя именованной структуры
  TattrStructName = class(TAttrVirtual);

  // ДАННЫЕ
  // СТРУКТУРЫ
  TStructTypedef = class;
  TDataStruct = class(TTyped)
  protected
   function GetSizeOrValue: TBytes; override;
   // ArraySupports
   function Clone(idx: Integer): TDataStruct;
  public
   Index: Byte;
   // Assign adata and attributes from Struct Type Define
   procedure Assign(Typed: TStructTypedef);
   // ArraySupports
   procedure ExpandArray(parent: TTyped);
  end;
  // byte tip
  // 1 ,2 byte size
  // Name if Named
  // Attributes
  // sub items;
  TStructTypedef = class(TDataStruct)
  protected
    function GetTip: TBytes; override;
    function GetSizeOrValue: TBytes; override;
  end;

  CStringToTip = record
    Name: string;
    Tip: TmetadataType;
    cls: TTypedClass;
    // данные получают атрибут (если его нет) из родительской структуры
    // root Attribute
    ra: Boolean;
  end;

{$ENDREGION}

const
  ATR_TYPES: array[0..39] of CStringToTip =(

   // атрибуты виртуальные
    (   Name: 'name';           Tip: 0;    cls: TattrName  ),
  // (Name: 'export';  Tip: 0; cls: TattrExport),///?????
    (    Name: 'noname';        Tip: 0;    cls: TattrNoname  ),
    (    Name: 'structname';    Tip: 0;    cls: TattrStructName  ),

   // атрибуты реальные
   // STR
    (    Name: 'info';        Tip: ATTR_info;    cls: TStr; ra:True ),
    (    Name: 'metr';        Tip: ATTR_metr;    cls: TStr  ),
    (    Name: 'eu';          Tip: ATTR_eu;      cls: TStr; ra:True ),
    // diagram
    (    Name: 'title';       Tip: ATTR_title;    cls: TStr  ),
   // len=0
    (    Name: 'WRK';         Tip: ATTR_WRK;          cls: TNone  ),
    (    Name: 'RAM';         Tip: ATTR_RAM;          cls: TNone  ),
    (    Name: 'EEP';         Tip: ATTR_EEP;          cls: TNone  ),
    (    Name: 'export';      Tip: ATTR_export;       cls: TNone  ),
    (    Name: 'HideArray';   Tip: ATTR_HideArray;    cls: TNone; ra:True   ),
    (    Name: 'ShowHex';     Tip: ATTR_ShowHex;      cls: TNone; ra:True   ),
   // len=1
    (    Name: 'adr';             Tip: ATTR + LEN_1 + 0;    cls: TUint8  ),
    (    Name: 'chip';            Tip: ATTR + LEN_1 + 1;    cls: TUint8  ),
    (    Name: 'NoPowerDataCount';Tip: ATTR + LEN_1 + 2;    cls: TUint8  ),
    (    Name: 'digits';          Tip: ATTR_digits;    cls: TUint8; ra:True   ),
    (    Name: 'precision';       Tip: ATTR_precision;    cls: TUint8; ra:True   ),
    // diagram
    (    Name: 'style';           Tip: ATTR + LEN_1 + 5;    cls: TUint8; ra:True   ),
    // diagram
    (    Name: 'width';           Tip: ATTR + LEN_1 + 6;    cls: TUint8; ra:True   ),
   // len=2
    (    Name: 'serial';              Tip: ATTR+ LEN_2 + 0;    cls: TUint16  ),
    (    Name: 'RamSize';             Tip: ATTR+ LEN_2 + 1;    cls: TUint16  ),
    (    Name: 'SupportUartSpeed';    Tip: ATTR+ LEN_2 + 2;    cls: TUint16  ),
    (    Name: 'from';                Tip: ATTR+ LEN_2 + 3;    cls: TUint16  ),
   // len=4
    // diagram
    (    Name: 'color';               Tip: ATTR+ + LEN_4 + 0;    cls: TUint32; ra:True   ),
    (    Name: 'SSDSize';             Tip: ATTR+ + LEN_4 + 1;    cls: TUint32  ),
   // avriable len
   // array (int)
    (    Name: 'array';     Tip: ATTR+ LEN_1 + ATTR_IDX_ARRAY;    cls: TUint8  ),
    (    Name: 'array';     Tip: ATTR+ LEN_2 + ATTR_IDX_ARRAY;    cls: TUint16  ),
     // range (int, float)
     // чтобы не усложнять программу и иметь одну константу ATR_TYPES на все
     // Bin Find By TIP
     // BIN -> TType ->XML
    (Name: 'RangeLo'; Tip: ATTR + LEN_1 + ATTR_IDX_RANGE_LO; cls: Tint8; ra:True ),
    (Name: 'RangeLo'; Tip: ATTR + LEN_2 + ATTR_IDX_RANGE_LO; cls: Tint16; ra:True ),
    (Name: 'RangeLo'; Tip: ATTR + LEN_4 + ATTR_IDX_RANGE_LO; cls: Tfloat; ra:True ),
    (Name: 'RangeHi'; Tip: ATTR + LEN_1 + ATTR_IDX_RANGE_HI; cls: Tint8; ra:True ),
    (Name: 'RangeHi'; Tip: ATTR + LEN_2 + ATTR_IDX_RANGE_HI; cls: Tint16; ra:True ),
    (Name: 'RangeHi'; Tip: ATTR + LEN_4 + ATTR_IDX_RANGE_HI; cls: Tfloat; ra:True ),
     // чтобы не усложнять программу и иметь одну константу ATR_TYPES на все
     // C header define -> BIN
    (Name: 'RangeLo1'; Tip: ATTR + LEN_1 + ATTR_IDX_RANGE_LO; cls: Tint8; ra:True ),
    (Name: 'RangeLo2'; Tip: ATTR + LEN_2 + ATTR_IDX_RANGE_LO; cls: Tint16; ra:True ),
    (Name: 'RangeLof'; Tip: ATTR + LEN_4 + ATTR_IDX_RANGE_LO; cls: Tfloat; ra:True ),
    (Name: 'RangeHi1'; Tip: ATTR + LEN_1 + ATTR_IDX_RANGE_HI; cls: Tint8; ra:True ),
    (Name: 'RangeHi2'; Tip: ATTR + LEN_2 + ATTR_IDX_RANGE_HI; cls: Tint16; ra:True ),
    (Name: 'RangeHif'; Tip: ATTR + LEN_4 + ATTR_IDX_RANGE_HI; cls: Tfloat; ra:True )
);


  STD_TYPES: array[0..9] of CStringToTip =(
  // простые типы данных
    (    Name: 'uint8_t';    Tip: LEN_1 + NAM_1;    cls: TUint8 ),
    (    Name: 'int8_t';     Tip: LEN_1 + NAM_2;    cls: Tint8  ),

    (    Name: 'uint16_t';    Tip: LEN_2 + NAM_1;    cls: TUint16  ),
    (    Name: 'int16_t';     Tip: LEN_2 + NAM_2;    cls: Tint16  ),

    (    Name: 'uint32_t';    Tip: LEN_4 + NAM_1;    cls: TUint32  ),
    (    Name: 'int32_t';     Tip: LEN_4 + NAM_2;    cls: Tint32  ),
    (    Name: 'float';       Tip: LEN_4 + NAM_3;    cls: TFloat  ),

    (    Name: 'uint64_t';   Tip: LEN_8 + NAM_1;    cls: TUint64  ),
    (    Name: 'int64_t';    Tip: LEN_8 + NAM_2;    cls: Tint64  ),
    (    Name: 'double';     Tip: LEN_8 + NAM_3;    cls: TDouble  ));

function StrToAnsiBytes(const val: string): TBytes;
function StrAsInt(val: string): Integer;
function StrAsInt64(val: string): Int64;

implementation

function StrAsInt64(val: string): Int64;
begin
  // default
  if val = '' then Exit(0);
  if val.StartsWith('0x', True) then
    val := val.Replace('0x', '$', [rfIgnoreCase]);
  Result := val.ToInt64();
end;

function StrAsInt(val: string): Integer;
begin
  // default
  if val = '' then Exit(0);
  if val.StartsWith('0x', True) then
    val := val.Replace('0x', '$', [rfIgnoreCase]);
  Result := val.ToInteger();
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

{ TmetadataTypeHelp }

function TmetadataTypeHelp.isAttr: Boolean;
begin
  Result := Boolean(self and $80);
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

function TmetadataTypeHelp.isStructTypedef: Boolean;
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
  else if isString then
    Exit(-1)
  else if isStructTypedef then
  begin
    lenPw := Self;
    if isNamed then
      Dec(lenPw);
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

 { TTYped}

constructor TTyped.Create(aTip: TmetadataType; const StrVal: string);
begin
  tip := aTip;
  SVal := StrVal;
end;

function TTyped.AttrContains(ATip: TmetadataType): Boolean;
begin
  for var a in Attr do if a.Tip = ATip then Exit(True);
  Result := False;
end;

constructor TTyped.Create(aTip: TmetadataType; const PtrVal: Pointer);
begin
  tip := aTip;
  if Assigned(PtrVal) then SVal := string(PAnsiChar(PtrVal));
end;

constructor TTyped.Create(root: IXMLNode);
begin

end;

function TTyped.DataSizeOf: Integer;
begin
  if tip.isData then
   begin
    Result := tip.Length;
    if ArrayLength > 0 then Result := Result*ArrayLength;
   end
  else if tip.isStruct then
   begin
    Result := 0;
    for var d in SubData do Result := Result + d.DataSizeOf;      
   end
  else raise Exception.Create('not data');
end;

destructor TTyped.Destroy;
begin
  for var a in attr do a.Free;
  for var a in subData do a.Free;
  inherited;
end;

procedure TTyped.SetTval(v: TValue);
begin
  SVal := v.ToString;
end;

function TTyped.SizeOf: Integer;
begin
  Result := Length(GetTip) + Length(GetSizeOrValue) + Length(GetName) + InerSizeOf(Attr) + InerSizeOf(SubData);
end;

function TTyped.GetName: TBytes;
begin
  Result := StrToAnsiBytes(Name);
end;

function TTyped.GetSizeOrValue: TBytes;
begin
  Result := []
end;

function TTyped.GetTip: TBytes;
begin
  Result := [tip]
end;

function TTyped.GetTval: TValue;
begin
  Result := SVal;
end;

function TTyped.InerSizeOf(a: TTypedArray): Integer;
begin
  Result := 0;
  for var ai in a do Inc(Result, ai.SizeOf);
end;

function TTyped.ToBytes: TBytes;
begin
  Result := GetTip + GetSizeOrValue + GetName + InerToBytes(Attr) + InerToBytes(SubData);
end;

procedure TTyped.UpdateValue(ptr: Pointer);
 var
  PtrVal: PByte;
begin
  if Assigned(Ptr) then
   begin
    PtrVal := ptr;
    Inc(PtrVal, DataOffset);
    SVal := string(PAnsiChar(PtrVal));
   end;
end;

function TTyped.ValAsStr(showEu: Boolean): string;
begin
  if showEu and (eu <> '') then Result := SVal + ' ' + eu
  else Result := SVal;
end;

function TTyped.InerToBytes(a: TTypedArray): TBytes;
begin
  SetLength(Result, 0);
  for var ai in a do Result := Result + ai.ToBytes;
end;


procedure TTyped.InitParentDataAttr;
 label Exsz;
begin
  if self.Tip.isData then
   begin
    var al := High(Attr);
    for var a in parent.Attr do if a.RootAttr then
     begin
      for var i := 0 to al do if Attr[i].Tip = a.Tip then goto Exsz;
      Attr := Attr + [a];
      Exsz:
     end;
   end;
end;

procedure TTyped.InitStandartDataAttr;
begin
  if self.Tip.isData then
   begin
    ArrayLength :=    GetAttrAs<Integer>(0, ATTR_IDX_ARRAY, $F);
    digits  :=        GetAttrAs<Integer>(0, ATTR_digits);
    precision :=      GetAttrAs<Integer>(0, ATTR_precision);
    AsHex :=     Assigned(GetAttr(ATTR_ShowHex));
    HideArray := Assigned(GetAttr(ATTR_HideArray));
    info :=           GetAttrAs<string>('',ATTR_info);
    title :=          GetAttrAs<string>('',ATTR_title);
    eu :=             GetAttrAs<string>('',ATTR_eu);
   end;
end;

//function TTyped.IsArray: Boolean;
//begin
//  Result := Assigned(GetAttr(ATTR_IDX_ARRAY,$F))
//end;

procedure TTyped.Remove(item: TTyped; IsSubData: Boolean);
 var
  a : PTypedArray;
begin
  if IsSubData then a := @SubData else a := @Attr;
  for var i := 0 to High(a^) do
   if a^[i] = item then
    begin
     Delete(a^,i,1);
     Break;
    end;
  item.Free;
end;

function TTyped.GetAttr(tst: byte; mack: byte): TTyped;
begin
  Result := nil;
  for var a in Attr do if (a.Tip and mack) = tst then Exit(a);
end;

function TTyped.GetAttrAs<T>(def: T; tst: byte; mack: byte = $FF): T;
begin
  Result := def;
  var a := GetAttr(tst, mack);
  if Assigned(a) then Result := a.TVal.AsType<T>;
end;

constructor TTypedValue<T>.Create(aTip: TmetadataType; const StrVal: string);
var
  ti: PTypeInfo;
  s: Single;
  d: Double;
begin
  inherited;
  ti := TypeInfo(T);
  case ti.Kind of
    tkInteger:
      begin
        var i := StrAsInt(StrVal);
        move(i, Value, System.SizeOf(T));
      end;
    tkInt64:
      begin
        var i := StrAsInt64(StrVal);
        move(i, Value, System.SizeOf(T));
      end;
    tkFloat:
      case ti.TypeData.FloatType of
        ftSingle:
          begin
            if StrVal ='' then s := 0
            else s := StrVal.ToSingle;
            move(s, Value, System.SizeOf(T));
          end;
        ftDouble:
          begin
            if StrVal ='' then d := 0
            else d := StrVal.ToDouble;
            move(d, Value, System.SizeOf(T));
          end;
      else
        begin
       //ftExtended, ftComp, ftCurr
        end;
      end;
  else
    begin
      PString(@Value)^ := StrVal;
    end;
  end;
end;

constructor TTypedValue<T>.Create(aTip: TmetadataType; const PtrVal: Pointer);
begin
  Tip := aTip;
  if not Assigned(PtrVal) then Exit;
  PValue := PtrVal;
  if GetTypeKind(T) in [tkInteger, tkInt64,tkFloat] then
   begin
    Value := PValue^;
    SVal := TVal.ToString;
   end
  else
   begin
    SVal := string(PAnsiChar(PtrVal));
    PString(@Value)^ := SVal;
   end;
end;

procedure TTypedValue<T>.UpdateValue(ptr: Pointer);
 var
  PtrVal: PByte;
begin
  // if not Assigned(Ptr) then Exit;
  PtrVal := ptr;
  Inc(PtrVal, DataOffset);
  PValue := ptrT(PtrVal);
  if ArrayLength > 0 then Exit;

  if GetTypeKind(T) in [tkInteger, tkInt64,tkFloat] then
   begin
    Value := PValue^;
//    SVal := TVal.ToString;
   end
  else
   begin
//    SVal := string(PAnsiChar(PtrVal));
//    PString(@Value)^ := SVal;
    PString(@Value)^ := string(PAnsiChar(PtrVal));
   end;
end;

function TTypedValue<T>.ValAsStr(showEu: Boolean): string;
begin

end;

constructor TTypedValue<T>.CreateT(aTip: TmetadataType; const Val: T);
begin
  tip := aTip;
  Value := Val;
  SVal := TVal.ToString;
end;

function TTypedValue<T>.GetSizeOrValue: TBytes;
begin
  SetLength(Result, System.SizeOf(T));
  move(Value, Result[0], System.SizeOf(T));
end;

function TTypedValue<T>.GetTval: TValue;
begin
  Result := TValue.From<T>(Value);
end;

procedure TTypedValue<T>.SetTval(v: TValue);
begin
  Value := v.AsType<T>;
  SVal := v.ToString;
end;

class function TTypedValue<T>.PtrToStr(ptr: Pointer): string;
begin
  Result := TValue.From<T>(ptrT(ptr)^).ToString;
end;



{ TStr }
function TStr.GetSizeOrValue: TBytes;
begin
 Result := StrToAnsiBytes(SVal)
end;

{ TAttrFactoryData }

function TAttrVirtual.SizeOf: Integer;
begin
  Result := 0;
end;

function TAttrVirtual.ToBytes: TBytes;
begin
  Result := [];
end;

{ TDataStruct }

procedure TDataStruct.Assign(Typed: TStructTypedef);
  label noAdd;
begin
  SubData := Copy(Typed.SubData);
  var l := High(Attr);
  for var a in Typed.Attr do
   begin
    for var i := 0 to l do
       if a.Tip = Attr[i].Tip then goto noAdd;
    Attr := Attr + [a];
    noAdd:
   end;
  if Tip = REC_DAT_SNAM then Name := Typed.Name;
  Index := Typed.Index;
end;


function TDataStruct.Clone(idx: Integer): TDataStruct;
begin
  Result          := TDataStruct.Create(tip);
  Result.Attr     := Copy(Attr);
  Result.SubData  := Copy(SubData);
  Result.Index    := Index;
  Result.Name     := Name + idx.ToString;
end;

procedure TDataStruct.ExpandArray(parent: TTyped);
begin
  var a := GetAttr(ATTR_IDX_ARRAY, $F);
  if Assigned(a) then
   begin
    var aLen := a.TVal.AsInteger;
    Remove(a);
    var sd  := parent.SubData;
    for var i := 0 to High(sd) do if sd[i] = self then
     begin
      for var j := 2 to aLen do Insert([Clone(j)], parent.SubData, i+j-1);
      Break;
     end;
    Name := Name+'1';
   end;
end;

function TDataStruct.GetSizeOrValue: TBytes;
begin
  Result := [Index];
end;

{ TStructTypedef }

function TStructTypedef.GetSizeOrValue: TBytes;
 var
  len: Integer;
begin
  len := 1 + 1 + Length(GetName) + InerSizeOf(Attr) + InerSizeOf(SubData);
  if len <= 255 then
    SetLength(Result,1)
  else
   begin
    Inc(len);
    SetLength(Result,2);
   end;
  move(len, Result[0], Length(Result));
end;

function TStructTypedef.GetTip: TBytes;
begin
  if Name = '' then  tip := (Length(GetSizeOrValue) - 1) * 2 + 1
  else Tip := Length(GetSizeOrValue) * 2;
  Result := [Tip];
end;

{ TNone }

constructor TNone.Create(aTip: TmetadataType; const PtrVal: Pointer);
begin
  Tip := aTip;
end;

{$ENDREGION}


end.


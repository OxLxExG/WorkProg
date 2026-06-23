unit Parser;

interface

uses {$IFNDEF UNUSE_debug_except}
     debug_except,
     {$ENDIF}
     SysUtils, System.Variants, Data.DB, System.Rtti, Xml.XMLIntf, Xml.XMLDoc, System.Classes,
     System.Generics.Collections;

type
  THackEvent = reference to procedure(InternalVarType: Byte; AdrVar: Pointer);
  TAsTypeFunction<T> = reference to function (var Data: Pointer): T;

  TConvert = procedure(pData: PByte; arSize: Integer; var Value: IXMLNode);
  TParserData = record
   Value: IXMLNode;
   tip: Integer;
   Index: Integer;
   ArraySize: Integer;
   Convert: TConvert;
   procedure SetData(pData: PByte; parsArray: Boolean = false); inline;
   constructor Create(n: IXMLNode; IsWord: Boolean = false);
  end;


  TPars = class
  public
   const
   //   дополнительные типы данных поддерживаемые парсером
    var_i3   = varRecord+1;
    var_ui3  = varRecord+2;
    var_info = varRecord+3;
    var_adr  = varRecord+4;
    var_i2_15b  = varRecord+5;
    var_ui2_15b  = varRecord+6;
    varRamSize  = varRecord+7;
    var_i2_10b  = varRecord+8;
    var_i2_14b  = varRecord+9;
    var_ui2_14b  = varRecord+10;
    var_ui2_kadr_psk4  = varRecord+11;
    var_ui2_kadr_all  = varRecord+12;
    var_ui2_8b  = varRecord+13;
    var_i2_14b_z_inv  = varRecord+14;
    var_i2_14b_z  = varRecord+15;
    var_inv_ui3  = varRecord+16;
    var_inv_ui3_ltr  = varRecord+17;
    var_inv_word  = varRecord+18;
    var_inv_i3  = varRecord+19;
    varChip =   varRecord+20;
    varSerial = varRecord+21; // серийный номер
    var_i2_15b_inv  = varRecord+22;
    var_array  = varRecord+23;
    var_i2_14b_GZ  = varRecord+24;
    varSSDSize  = varRecord+25; // Cardinal
    varSupportUartSpeed  = varRecord+26; // BitMask Word
    varExtNoPowerDataCount  = varRecord+27; // byte
    varDigits  = varRecord+28; // byte
    varPrecision  = varRecord+29; // byte
    varFrom  = varRecord+30; // word

   type
    TTypeDic = TDictionary<Integer, string>;
    TOutArray = array of Byte;
    class var TypeDic: TTypeDic;
    // создает из бинарных метаданных XML
    class procedure SetInfo(node: IXMLNode; Info: PByte; InfoLen: integer; hev: THackEvent = nil);
    // добавляет метрологию и рассчетные рараметры в XML
//    class procedure SetMetr(node: IXMLNode; ExeSc: IXmlScript; ExecSetup: Boolean);
    // заполняет поля root текущими бинарными данными
    class procedure SetData(root: IXMLNode; const Data: PByte; ParsArray: Boolean = True; CntStd: Integer = -1); overload; static;
    class procedure SetData(const value: TArray<TParserData>; const Data: PByte; ParsArray: Boolean = True); overload; static; inline;
    class function FindParserData(root: IXMLNode; ParsArray: Boolean = True): TArray<TParserData>; static;
    class procedure GetData(root: IXMLNode; var Data: TOutArray);
//    class procedure SetStd(root: IXMLNode; const Data: PByte);
    class procedure SetPsk(root: IXMLNode; const Data: PWord);
    class procedure SetPskToStd(root: IXMLNode; const Data: PWord);

    class procedure GetTypeStrings(var Types: TStrings; node: IXMLNode = nil);
    class function VarTypeToTxtDBField(vt: Integer): string;
    class function VarTypeToDBField(vt: Integer): TFieldType;
    class function VarTypeToLength(vt: Integer): Integer;
    class function VarTypeToType(vt: Integer): Integer;
    class function VarTypeToStr(vt: Integer): string;
    class function ArrayValToVar(PData: Pointer; Len: integer): Variant; static;
    class function ArrayStrToArray(const Data: string): TArray<Double>; static;
    class procedure Init;
    class procedure DeInit;
    class procedure FromVar(const Data: Variant; vt: Integer; pOutData: Pointer); overload;
    class procedure FromVar(const DataArr: string; vt, arr_len: Integer; pOutData: Pointer); overload;
    class function GetAsTypeFunction(vt: Integer): TAsTypeFunction<Integer>; //overload;
    class function GetAsSingleFunction(vt: Integer): TAsTypeFunction<Single>;
    class procedure LocalGetData(root: IXMLNode; var Data: TOutArray); static;
    class procedure LocalSetData(root: IXMLNode; const Data: PByte); static;
    class function ArrayToString(Data: PByte; cnt, vt: Integer): string;
    class function ArrayToFloat(Data: PByte; cnt, vt: Integer): TArray<Single>;
  private
  //  const
//     MAIN = 'MAIN_METR';
//     SIMP = 'SIMPLE_METR';
     //EXEC = 'EXEC_METR';
//     SETUP = 'SETUP_METR';
//    class
    { TODO : сделать ToValue(Data: Pointer; vt: Integer): TValue }
    class function RefAsTypeFunction<T, C>(Data: Pointer): T;
    class function ToValue(Data: Pointer; vt: Integer): TValue;
    class function ToVar(Data: Pointer; vt: Integer): Variant;
    class procedure ToPointer(Data, Res: Pointer; vt: Integer);
    class function HorizontToWord(Data: Word; vt: Integer): Word;
  end;

implementation

uses tools;

procedure ConvertByte(pData: PByte; arSize: Integer; var Value: IXMLNode);
begin
  Value.NodeValue := Pbyte(pData)^;
end;

{$REGION 'TParser'}

{ TParser }

class procedure TPars.DeInit;
begin
  if Assigned(TypeDic) then
  begin
   FreeAndNil(TypeDic);
  end;
end;


class function TPars.FindParserData(root: IXMLNode; ParsArray: Boolean = True): TArray<TParserData>;
 var
  Res: Tarray<TParserData>;
  IsWord: Boolean;
begin
   IsWord := root.HasAttribute(AT_WRKP);
   ExecXTree(root, procedure(n: IXMLNode)
   begin
     if n.HasAttribute(AT_TIP) and n.HasAttribute(AT_INDEX)  then
      begin
       if not ParsArray and n.ParentNode.HasAttribute(AT_ARRAY) then Exit;
       Res := Res +[TParserData.Create(n, IsWord)];
      end;
   end);
  Result := Res;
end;

class procedure TPars.FromVar(const DataArr: string; vt, arr_len: Integer; pOutData: Pointer);
 var
  a: TArray<string>;
  s: string;
  n: Integer;
  p: PByte;
begin
  a := DataArr.Split([' '], TStringSplitOptions.ExcludeEmpty);
  if Length(a) > arr_len then
  {$IFNDEF UNUSE_debug_except}
    raise EBaseException.Create('ошибка преобразования массива Length(a) > arr_len');
  {$ELSE}
    raise Exception.Create('ошибка преобразования массива Length(a) > arr_len');
  {$ENDIF}
  p := pOutData;
  n := VarTypeToLength(vt);
  for s in a do
   begin
    FromVar(s, vt, p);
    inc(p,n);
   end;
end;

class function TPars.VarTypeToStr(vt: Integer): string;
begin
  if not TypeDic.TryGetValue(vt, Result) then Result := IntToStr(vt)
end;

class procedure TPars.GetTypeStrings(var Types: TStrings; node: IXMLNode = nil);
 var
  p: TPair<Integer, string>;
begin
  Types.Clear;
  for p in TypeDic do Types.AddObject(p.Value, TObject(p.Key));
end;

class function TPars.ArrayToFloat(Data: PByte; cnt, vt: Integer): TArray<Single>;
 var
  i: Integer;
  func: TAsTypeFunction<Single>;
  P: Pointer;
begin
  P := Data;
  SetLength(Result, cnt);
  func := GetAsSingleFunction(vt);
  for i := 0 to cnt-1 do
    Result[i] := func(P);
end;

class function TPars.ArrayToString(Data: PByte; cnt, vt: Integer): string;
 var
  i, n: Integer;
  a: TArray<string>;
begin
  SetLength(a, cnt);
  n := VarTypeToLength(vt);
  for i := 0 to cnt-1 do
   begin
    a[i] := ToVar(Data, vt);
    Inc(Data, n);
   end;
   Result := string.Join(' ',a);
end;

class function TPars.HorizontToWord(Data: Word; vt: Integer): Word;
begin
  case vt of
   var_i2_15b  :if (Data and $4000) = 0 then Result := Data and $3FFF else Result := Data;
   var_ui2_15b :Result := Data and $7FFF;
   var_i2_10b  :if (Data and $200) = 0 then  Result := Data and $1FF  else Result := Data or $FE00;
   var_i2_14b  :if (Data and $2000) = 0 then Result := Data and $1FFF else Result := Data or $E000;
   var_ui2_14b :Result := Data and $3FFF;
   else Result := Data;
  end;
end;

class procedure TPars.Init;
begin
  if not Assigned(TypeDic) then
  begin
   TypeDic := TTypeDic.Create;
   TypeDic.Add(varSmallint, 'varSmallint');
   TypeDic.Add(varInteger,  'varInteger');
   TypeDic.Add(varSingle  , 'varSingle');
   TypeDic.Add(varCurrency, 'varCurrency');
   TypeDic.Add(varShortInt, 'varShortInt');
   TypeDic.Add(varByte    , 'varByte');
   TypeDic.Add(varWord    , 'varWord');
   TypeDic.Add(varLongWord, 'varLongWord');
   TypeDic.Add(varInt64   , 'varInt64');
   TypeDic.Add(varUInt64  , 'varUInt64');
   TypeDic.Add(var_i3     , 'var_i3');
   TypeDic.Add(var_ui3    , 'var_ui3');
   TypeDic.Add(var_i2_15b , 'var_i2_15b');
   TypeDic.Add(var_i2_15b_inv , 'var_i2_15b_inv');
   TypeDic.Add(var_i2_14b_GZ , 'var_i2_14b_GZ');
   TypeDic.Add(var_ui2_15b, 'var_ui2_15b');
   TypeDic.Add(var_i2_10b , 'var_i2_10b');
   TypeDic.Add(var_i2_14b , 'var_i2_14b');
   TypeDic.Add(var_ui2_14b, 'var_ui2_14b');
   TypeDic.Add(var_inv_ui3, 'var_inv_ui3');
   TypeDic.Add(var_inv_i3 , 'var_inv_i3');
   TypeDic.Add(var_inv_word     , 'var_inv_word');
   TypeDic.Add(var_inv_ui3_ltr  , 'var_inv_ui3_ltr');
   TypeDic.Add(var_ui2_kadr_psk4, 'var_ui2_kadr_psk4');
   TypeDic.Add(var_ui2_kadr_all , 'var_ui2_kadr_all');
   TypeDic.Add(var_ui2_8b       , 'var_ui2_8b');
   TypeDic.Add(var_i2_14b_z_inv , 'var_i2_14b_z_inv');
   TypeDic.Add(var_i2_14b_z     , 'var_i2_14b_z');
  end
end;


class function TPars.RefAsTypeFunction<T, C>(Data: Pointer): T;
 type
  PC =^C;
begin
  Result := Tvalue.From<C>(PC(Data)^).AsType<T>;
end;

class function TPars.VarTypeToTxtDBField(vt: Integer): string;
begin
  case vt of
    varOleStr  :Result := 'TEXT';
    varString  :Result := 'TEXT';
    varUString :Result := 'TEXT';
    varSmallint:Result := 'INT'; { vt_i2           2 }
    varInteger :Result := 'INT'; { vt_i4           3 }
    varSingle  :Result := 'REAL'; { vt_r4           4 }
    varDouble  :Result := 'REAL'; { vt_r8           5 }
    varCurrency:Result := 'REAL'; { vt_cy           6 }
    varDate    :Result := 'TEXT'; { vt_date         7  timestamp}
    varShortInt:Result := 'INT'; { vt_i1          16 }
    varByte    :Result := 'INT'; { vt_ui1         17 }
    varWord    :Result := 'INT'; { vt_ui2         18 }
    varLongWord:Result := 'INT'; { vt_ui4         19 }
    varInt64   :Result := 'INT'; { vt_i8          20 }
    varUInt64  :Result := 'INT'; { vt_ui8         21 }
    var_i3     :Result := 'INT';
    var_ui3    :Result := 'INT';
    var_i2_15b :Result := 'INT';
    var_i2_15b_inv :Result := 'INT';
    var_i2_14b_GZ :Result := 'INT';
    var_ui2_15b:Result := 'INT';
    var_i2_10b :Result := 'INT';
    var_i2_14b :Result := 'INT';
    var_ui2_14b:Result := 'INT';
    var_inv_ui3:Result := 'INT';
    var_inv_i3 :Result := 'INT';
    var_inv_word:Result := 'INT';
    var_inv_ui3_ltr:Result := 'INT';
    var_ui2_kadr_psk4 :Result := 'INT';
    var_ui2_kadr_all  :Result := 'INT';
    var_ui2_8b:Result := 'INT';
    var_i2_14b_z_inv:Result := 'INT';
    var_i2_14b_z:Result := 'INT';
  else raise Exception.Create('НЕВОЗМОЖНО ОПРЕДЕЛИТЬ ТИП DB ДАННЫХ ПО ТИПУ!!!');
  end;
end;

class function TPars.VarTypeToType(vt: Integer): Integer;
begin
  Result := vt;
  case vt of
    varOleStr  :Result := varOleStr;
    varString  :Result := varString;
    varUString :Result := varUString;
    varSmallint:Result := varSmallint; { vt_i2           2 }
    varInteger :Result := varInteger; { vt_i4           3 }
    varSingle  :Result := varSingle; { vt_r4           4 }
    varDouble  :Result := varDouble; { vt_r8           5 }
    varCurrency:Result := varCurrency; { vt_cy           6 }
    varDate    :Result := varDate; { vt_date         7  timestamp}
    varShortInt:Result := varShortInt; { vt_i1          16 }
    varByte    :Result := varByte; { vt_ui1         17 }
    varWord    :Result := varWord; { vt_ui2         18 }
    varLongWord:Result := varLongWord; { vt_ui4         19 }
    varInt64   :Result := varInt64; { vt_i8          20 }
    varUInt64  :Result := varUInt64; { vt_ui8         21 }
    var_i3     :Result := varSmallint;//ftInteger;
    var_ui3    :Result := varWord;//ftInteger;
    var_i2_15b :Result := varSmallint;
    var_i2_15b_inv :Result := varSmallint;
    var_i2_14b_GZ :Result := varSmallint;
    var_ui2_15b:Result := varWord;
    var_i2_10b :Result := varSmallint;
    var_i2_14b :Result := varSmallint;
    var_ui2_14b:Result := varWord;
    var_inv_ui3:Result := varWord;//ftInteger;
    var_inv_i3 :Result := varSmallint;//ftInteger;
    var_inv_word:Result := varWord;
    var_inv_ui3_ltr:Result := varWord;//ftInteger;
    var_ui2_kadr_psk4 :Result := varWord;
    var_ui2_kadr_all  :Result := varWord;
    var_ui2_8b:Result := varWord;
    var_i2_14b_z_inv:Result := varSmallint;
    var_i2_14b_z:Result := varSmallint;
  else raise Exception.Create('НЕВОЗМОЖНО ОПРЕДЕЛИТЬ ТИП DB ДАННЫХ ПО ТИПУ!!!');
  end;
end;

class function TPars.VarTypeToDBField(vt: Integer): TFieldType;
begin
  case vt of
    varOleStr  :Result := ftFixedChar;
    varString  :Result := ftString;
    varUString :Result := ftString;
    varSmallint:Result := ftSmallint; { vt_i2           2 }
    varInteger :Result := ftInteger; { vt_i4           3 }
    varSingle  :Result := ftSingle; { vt_r4           4 }
    varDouble  :Result := ftFloat; { vt_r8           5 }
    varCurrency:Result := ftCurrency; { vt_cy           6 }
    varDate    :Result := ftFloat; { vt_date         7  timestamp}
    varShortInt:Result := ftShortint; { vt_i1          16 }
    varByte    :Result := ftByte; { vt_ui1         17 }
    varWord    :Result := ftWord; { vt_ui2         18 }
    varLongWord:Result := ftLongWord; { vt_ui4         19 }
    varInt64   :Result := ftInteger; { vt_i8          20 }
    varUInt64  :Result := ftLongWord; { vt_ui8         21 }
    var_i3     :Result := ftSmallint;//ftInteger;
    var_ui3    :Result := ftWord;//ftInteger;
    var_i2_15b :Result := ftSmallint;
    var_i2_15b_inv :Result := ftSmallint;
    var_i2_14b_GZ :Result := ftSmallint;
    var_ui2_15b:Result := ftWord;
    var_i2_10b :Result := ftSmallint;
    var_i2_14b :Result := ftSmallint;
    var_ui2_14b:Result := ftWord;
    var_inv_ui3:Result := ftWord;//ftInteger;
    var_inv_i3 :Result := ftSmallint;//ftInteger;
    var_inv_word:Result := ftWord;
    var_inv_ui3_ltr:Result := ftWord;//ftInteger;
    var_ui2_kadr_psk4 :Result := ftWord;
    var_ui2_kadr_all  :Result := ftWord;
    var_ui2_8b:Result := ftWord;
    var_i2_14b_z_inv:Result := ftSmallint;
    var_i2_14b_z:Result := ftSmallint;
  else raise Exception.Create('НЕВОЗМОЖНО ОПРЕДЕЛИТЬ ТИП DB ДАННЫХ ПО ТИПУ!!!');
  end;
end;

class function TPars.VarTypeToLength(vt: Integer): Integer;
 const
   MAX_STRING: string = 'Выключен [контроль] [ошибка]';
begin
  case vt of
    varSmallint:Result := SizeOf(Smallint); { vt_i2           2 }
    varInteger :Result := SizeOf(Integer); { vt_i4           3 }
    varSingle  :Result := SizeOf(Single); { vt_r4           4 }
    varDouble  :Result := SizeOf(Double); { vt_r8           5 }
    varCurrency:Result := SizeOf(Currency); { vt_cy           6 }
    varDate    :Result := SizeOf(TDateTime); { vt_date         7 }
    varShortInt:Result := SizeOf(ShortInt); { vt_i1          16 }
    varOleStr  :  Result := SizeOf(Byte); { vt_ui1         17 }
    varByte    :Result := SizeOf(Byte); { vt_ui1         17 }
    varWord    :Result := SizeOf(Word); { vt_ui2         18 }
    varLongWord:Result := SizeOf(LongWord); { vt_ui4         19 }
    varInt64   :Result := SizeOf(Int64); { vt_i8          20 }
    varUInt64  :Result := SizeOf(UInt64); { vt_ui8         21 }
    varString: Result :=  MAX_STRING.Length*2; // 20 ; // !!! TstringField - размер по-умолчанию
    var_i3     :Result := 3;
    var_ui3    :Result := 3;
    var_i2_15b :Result := 2;
    var_i2_15b_inv :Result := 2;
    var_i2_14b_GZ :Result := 2;
    var_ui2_15b:Result := 2;
    var_i2_10b :Result := 2;
    var_i2_14b :Result := 2;
    var_ui2_14b:Result := 2;
    var_inv_ui3:Result := 3;
    var_inv_i3 :Result := 3;
    var_inv_word:Result := 2;
    var_inv_ui3_ltr:Result := 3;
    var_ui2_kadr_psk4 :Result := 4;
    var_ui2_kadr_all  :Result := 4;
    var_ui2_8b:Result := 2;
    var_i2_14b_z_inv:Result := 2;
    var_i2_14b_z:Result := 2;
  else raise Exception.Create('НЕВОЗМОЖНО ОПРЕДЕЛИТЬ ДЛИНУ ДАННЫХ ПО ТИПУ!!!');
  end;
end;


class function TPars.ArrayStrToArray(const Data: string): TArray<Double>;
 var
  a: TArray<string>;
  i: Integer;
begin
  a := data.Split([' '], TStringSplitOptions.ExcludeEmpty);
  SetLength(Result, Length(a));
  for i := 0 to Length(a)-1 do Result[i] := a[i].ToDouble;
end;

class function TPars.ArrayValToVar(PData: Pointer; Len: integer): Variant;
var
  V: Variant;
  pDest: Pointer;
begin
  V := VarArrayCreate([0, Len - 1], varByte);
  pDest := VarArrayLock(V);
  try
    Move(PData^, pDest^, Len);
  finally
    VarArrayUnlock(V);
  end;
end;


class procedure TPars.FromVar(const Data: Variant; vt: Integer; pOutData: Pointer);
 var
  b: TBytes;
  d: Double;
begin                                   // Data - Ole string XML only string;
  case vt of
    varByte        : PByte(pOutData)^ := Byte(Data);
    varOleStr      : PAnsiChar(pOutData)^ := AnsiString(string(Data))[1];
    varShortInt    : PByte(pOutData)^ := Byte(Data);
    varWord        : PWord(pOutData)^ := Word(Data);
    varSmallint    : PSmallint(pOutData)^ := Smallint(Data);
    varDouble      : PDouble(pOutData)^ := Double(Data);
    varSingle      : PSingle(pOutData)^ := Single(Data);
    varInteger     : Pinteger(pOutData)^ := integer(Data);
    varUInt32:
      begin
        if not UInt32.TryParse(VarToStr(Data), PUint32(pOutData)^) then
          PUint32(pOutData)^ := 0; // Значение по умолчанию при ошибке парсинга
      end;
    varInt64       : Pint64(pOutData)^ := int64(Data);
    varUInt64      : PUint64(pOutData)^ := Uint64(Data);
    varDate        :
     begin
      if TryStrToFloat(Data, d) then PDouble(pOutData)^ := d
      else PDouble(pOutData)^ := StrToDateTime(Data);
     end;
    varString      :
     begin
      b := TEncoding.Default.GetBytes(string(Data));
      Move((@b[0])^, pOutData^, Length(b));
     end
    else  raise Exception.Createfmt('НЕВОЗМОЖНО ПРЕОБРАЗОВАТЬ %d %s ВАРИАНТ В БАЙТЫ !!!',[vt, VarToStr(Data)]);
  end
end;

class function TPars.GetAsSingleFunction(vt: Integer): TAsTypeFunction<Single>;
begin
  case vt of
    varDouble  : Result := function (var Data: Pointer): Single begin Result := PDouble(Data)^; Inc(Pbyte(Data), SizeOf(Double)) end;
    varSingle  : Result := function (var Data: Pointer): Single begin Result := PSingle(Data)^; Inc(Pbyte(Data), SizeOf(Single)) end;
    varSmallint: Result := function (var Data: Pointer): Single begin Result := PSmallint(Data)^; Inc(Pbyte(Data), SizeOf(Smallint)) end;
    varInteger : Result := function (var Data: Pointer): Single begin Result := PInteger(Data)^; Inc(Pbyte(Data), SizeOf(Integer)) end;
    varShortInt: Result := function (var Data: Pointer): Single begin Result := PShortInt(Data)^; Inc(Pbyte(Data), SizeOf(ShortInt)) end;
    varByte    : Result := function (var Data: Pointer): Single begin Result := PByte(Data)^; Inc(Pbyte(Data), SizeOf(Byte)) end;
    varWord    : Result := function (var Data: Pointer): Single begin Result := PWord(Data)^; Inc(Pbyte(Data), SizeOf(Word)) end;
    varLongWord: Result := function (var Data: Pointer): Single begin Result := PLongWord(Data)^; Inc(Pbyte(Data), SizeOf(LongWord)) end;
    varInt64   : Result := function (var Data: Pointer): Single begin Result := PInt64(Data)^; Inc(Pbyte(Data), SizeOf(Int64)) end;
    varUInt64  : Result := function (var Data: Pointer): Single begin Result := PUInt64(Data)^; Inc(Pbyte(Data), SizeOf(UInt64)) end;
    else  raise Exception.Create('НЕВОЗМОЖНО ПРЕОБРАЗОВАТЬ В AsTypeFunction<integer>');
  end;
end;

class function TPars.GetAsTypeFunction(vt: Integer): TAsTypeFunction<integer>;
begin
  case vt of
    varSmallint: Result := function (var Data: Pointer): integer begin Result := PSmallint(Data)^; Inc(Pbyte(Data), SizeOf(Smallint)) end;
    varInteger : Result := function (var Data: Pointer): integer begin Result := PInteger(Data)^; Inc(Pbyte(Data), SizeOf(Integer)) end;
    varShortInt: Result := function (var Data: Pointer): integer begin Result := PShortInt(Data)^; Inc(Pbyte(Data), SizeOf(ShortInt)) end;
    varByte    : Result := function (var Data: Pointer): integer begin Result := PByte(Data)^; Inc(Pbyte(Data), SizeOf(Byte)) end;
    varWord    : Result := function (var Data: Pointer): integer begin Result := PWord(Data)^; Inc(Pbyte(Data), SizeOf(Word)) end;
    varLongWord: Result := function (var Data: Pointer): integer begin Result := PLongWord(Data)^; Inc(Pbyte(Data), SizeOf(LongWord)) end;
    varInt64   : Result := function (var Data: Pointer): integer begin Result := PInt64(Data)^; Inc(Pbyte(Data), SizeOf(Int64)) end;
    varUInt64  : Result := function (var Data: Pointer): integer begin Result := PUInt64(Data)^; Inc(Pbyte(Data), SizeOf(UInt64)) end;
    else  raise Exception.Create('НЕВОЗМОЖНО ПРЕОБРАЗОВАТЬ В AsTypeFunction<integer>');
  end;
end;

class procedure TPars.ToPointer(Data, Res: Pointer; vt: Integer);
 var
  w: PWord;
  l,h,m: Byte;
  b: PByte;
  sn: Single;
  procedure Move3(d3: Integer);
  begin
    PByte(Res)^ := d3;
    (PByte(Res)+1)^ := d3 shr 8;
    (PByte(Res)+2)^ := d3 shr 16;
  end;
begin
  case vt of
    varSmallint:PSmallint(Res)^ := PSmallint(Data)^; { vt_i2           2 }
    varInteger :PInteger(Res)^ := PInteger(Data)^; { vt_i4           3 }
    varSingle  :
     begin
      sn := PSingle(Data)^;//^/0; { vt_r4           4 }
      if sn.SpecialType in [fsInf, fsNInf, fsNaN] then PSingle(Res)^ := 0
      else PSingle(Res)^ := sn;
     end;
    varDouble  :PDouble(Res)^ := PDouble(Data)^; { vt_r8           5 }
    varCurrency:PCurrency(Res)^ := PCurrency(Data)^; { vt_cy           6 }
   // varDate    :Result := SizeOf(TDateTime); { vt_date         7 }
    varShortInt:PShortInt(Res)^ := PShortInt(Data)^; { vt_i1          16 }
    varByte    :PByte(Res)^ := PByte(Data)^; { vt_ui1         17 }
    varWord    :PWord(Res)^ := PWord(Data)^; { vt_ui2         18 }
    varLongWord:PLongWord(Res)^ := PLongWord(Data)^; { vt_ui4         19 }
    varInt64   :PInt64(Res)^ := PInt64(Data)^; { vt_i8          20 }
    varUInt64  :PUInt64(Res)^ := PUInt64(Data)^; { vt_ui8         21 }
    var_i3     :Move3(Integer(PLongWord(Data)^ shl 8) div $100);
    var_ui3    :Move3(LongWord(PLongWord(Data)^ and $00FFFFFF));
    var_i2_15b :if (PWord(Data)^ and $4000) = 0 then PSmallint(Res)^ := PSmallint(Data)^ and $3FFF
                else PSmallint(Res)^ := PSmallint(Data)^;
    var_i2_15b_inv :if (PWord(Data)^ and $4000) = 0 then PSmallint(Res)^ := -(PSmallint(Data)^ and $3FFF)
                else PSmallint(Res)^ := -(PSmallint(Data)^);
    var_ui2_15b:PWord(Res)^ := PWord(Data)^ and $7FFF;
    var_i2_10b  :if (PWord(Data)^ and $200) = 0 then PSmallint(Res)^ := PSmallint(Data)^ and $1FF
                else PSmallint(Res)^ := Smallint(PWord(Data)^ or $FE00);
    var_i2_14b  :if (PWord(Data)^ and $2000) = 0 then PSmallint(Res)^ := PSmallint(Data)^ and $1FFF
                else PSmallint(Res)^ := Smallint(PWord(Data)^ or $E000);
    var_ui2_14b :PWord(Res)^ := Word(PWord(Data)^ and $3FFF);
    var_inv_word:
     begin
      b := Data;
      h := b^; Inc(b);
      l := b^;
      PWord(Res)^ := word((word(h) shl 8) or l);
     end;
    var_i2_14b_GZ:
     begin
      w := Data;
      PWord(Res)^ := (w^ shr 8) and $7F;
      Dec(w);
      PWord(Res)^ := PWord(Res)^ or ((w^ and $7F00) shr 1);
      if (PWord(Res)^ and $2000) <> 0 then PSmallint(Res)^ := Smallint(PWord(Data)^ or $E000);
     end;
    var_ui2_kadr_psk4:
     begin
      w := Data;
      PWord(Res)^ := (w^ shl 8);
      Dec(w);
      Dec(w);
      PWord(Res)^ := (PWord(Res)^ or (w^ and $00FF));
     end;
    var_inv_ui3_ltr:
     begin
      b := Data;
      h := b^; Inc(b);
      m := b^; Inc(b);
      l := b^;
      Move3(LongWord(LongWord(h)*2000 + LongWord(m)*$100 + l));
     end;
    var_inv_i3:
    begin
      b := Data;
      h := b^; Inc(b);
      m := b^; Inc(b);
      l := b^;
      if h and $80 <> 0 then Move3(Integer($FF000000 + LongWord(h)*$10000 + LongWord(m)*$100 + l))
      else Move3(Integer(LongWord(h)*$10000 + LongWord(m)*$100 + l));
    end;
    var_inv_ui3:
     begin
      b := Data;
      h := b^; Inc(b);
      m := b^; Inc(b);
      l := b^;
      Move3(LongWord(LongWord(h)*$10000 + LongWord(m)*$100 + l));
     end;
    var_ui2_kadr_all:
     begin
      w := Data;
      PWord(Res)^ := (w^ shl 8);
      Dec(w);
      PWord(Res)^ := (PWord(Res)^ or (w^ and $00FF));
     end;
    var_ui2_8b:
     begin
      w := Data;
      PWord(Res)^ := Byte(w^ and $00FF);
     end;
    var_i2_14b_z_inv:
     begin
      if (PWord(Data)^ and $2000) = 0 then PSmallint(Res)^ := -(PSmallint(Data)^ and $1FFF)
                else PSmallint(Res)^ := Smallint(PWord(Data)^ and $1FFF);
     end;
    var_i2_14b_z:
     begin
      if (PWord(Data)^ and $2000) = 1 then PSmallint(Res)^ := -(PSmallint(Data)^ and $1FFF)
                else PSmallint(Res)^ := Smallint(PWord(Data)^ and $1FFF);
     end
  else  raise Exception.Create('НЕВОЗМОЖНО ПРЕОБРАЗОВАТЬ УКАЗАТЕЛЬ В ВАРИАНТ!!!');
  end;
end;

class function TPars.ToValue(Data: Pointer; vt: Integer): TValue;
 var
  w: PWord;
  l,h,m: Byte;
  b: PByte;
  sn: Single;
  wr: word;
  int: Integer;
  lw: LongWord;
  si: Smallint;
begin
  case vt of
    varSmallint: Tvalue.Make(Data, TypeInfo(SmallInt), Result); { vt_i2           2 }
    varInteger : Tvalue.Make(Data, TypeInfo(Integer), Result); { vt_i4           3 }
    varSingle  : Tvalue.Make(Data, TypeInfo(Single), Result);
    varDouble  : Tvalue.Make(Data, TypeInfo(Double), Result); { vt_r8           5 }
    varCurrency: Tvalue.Make(Data, TypeInfo(Currency), Result); { vt_cy           6 }
    varDate    : Tvalue.Make(Data, TypeInfo(TDate), Result); { vt_date         7 }
    varShortInt: Tvalue.Make(Data, TypeInfo(ShortInt), Result); { vt_i1          16 }
    varByte    : Tvalue.Make(Data, TypeInfo(Byte), Result); { vt_ui1         17 }
    varWord    : Tvalue.Make(Data, TypeInfo(Word), Result); { vt_ui2         18 }
    varLongWord: Tvalue.Make(Data, TypeInfo(LongWord), Result); { vt_ui4         19 }
    varInt64   : Tvalue.Make(Data, TypeInfo(Int64), Result); { vt_i8          20 }
    varUInt64  : Tvalue.Make(Data, TypeInfo(UInt64), Result); { vt_ui8         21 }

    var_i3     :
                begin
                 int := Integer(PLongWord(Data)^ shl 8) div $100;
                 Tvalue.Make(@int, TypeInfo(Integer), Result);
                end;
    var_ui3    :
                begin
                 lw := LongWord(PLongWord(Data)^ and $00FFFFFF);
                 Tvalue.Make(@lw, TypeInfo(LongWord), Result);
                end;
    var_i2_15b :
                begin
                 if (PWord(Data)^ and $4000) = 0 then si := PSmallint(Data)^ and $3FFF
                 else si := PSmallint(Data)^;
                 Tvalue.Make(si, TypeInfo(SmallInt), Result)
                end;
    var_i2_15b_inv :
               begin
                if (PWord(Data)^ and $4000) = 0 then si := -(PSmallint(Data)^ and $3FFF)
                else si := -(PSmallint(Data)^);
                Tvalue.Make(si, TypeInfo(SmallInt), Result)
               end;
    var_ui2_15b: { TODO : недоделал надоело}
                begin
                 wr := PWord(Data)^ and $7FFF;
                end;
    var_i2_10b  :
                begin
                 if (PWord(Data)^ and $200) = 0 then si := PSmallint(Data)^ and $1FF
                 else si := Smallint(PWord(Data)^ or $FE00);
                 Tvalue.Make(si, TypeInfo(SmallInt), Result)
                end;
    var_i2_14b  :
                begin
                 if (PWord(Data)^ and $2000) = 0 then si := PSmallint(Data)^ and $1FFF
                 else si := Smallint(PWord(Data)^ or $E000);
                 Tvalue.Make(si, TypeInfo(SmallInt), Result)
                end;
    var_ui2_14b :
                 begin
                  wr := Word(PWord(Data)^ and $3FFF);
                 end;
    var_inv_word:
     begin
      b := Data;
      h := b^; Inc(b);
      l := b^;
      wr := word((word(h) shl 8) or l);
     end;
    var_i2_14b_GZ:
     begin
      w := Data;
      wr := (w^ shr 8) and $7F;
      Dec(w);
      wr := wr or ((w^ and $7F00) shr 1);
      if (wr and $2000) <> 0 then wr := Smallint(PWord(Data)^ or $E000);
     end;
    var_ui2_kadr_psk4:
     begin
      w := Data;
      wr := word(w^ shl 8);
      Dec(w);
      Dec(w);
      wr := word(wr or (w^ and $00FF));
     end;
    var_inv_ui3_ltr:
     begin
      b := Data;
      h := b^; Inc(b);
      m := b^; Inc(b);
      l := b^;
      wr := LongWord(LongWord(h)*2000 + LongWord(m)*$100 + l);
     end;
    var_inv_i3:
    begin
      b := Data;
      h := b^; Inc(b);
      m := b^; Inc(b);
      l := b^;
      if h and $80 <> 0 then int := Integer($FF000000 + LongWord(h)*$10000 + LongWord(m)*$100 + l)
      else int := Integer(LongWord(h)*$10000 + LongWord(m)*$100 + l);
    end;
    var_inv_ui3:
     begin
      b := Data;
      h := b^; Inc(b);
      m := b^; Inc(b);
      l := b^;
      lw := LongWord(LongWord(h)*$10000 + LongWord(m)*$100 + l);
     end;
    var_ui2_kadr_all:
     begin
      w := Data;
      wr := word(w^ shl 8);
      Dec(w);
      wr := Word(wr or (w^ and $00FF));
     end;
    var_ui2_8b:
     begin
      w := Data;
      l := Byte(w^ and $00FF);
     end;
    var_i2_14b_z_inv:
     begin
      if (PWord(Data)^ and $2000) = 0 then si := -(PSmallint(Data)^ and $1FFF)
                else si := Smallint(PWord(Data)^ and $1FFF);
      Tvalue.Make(si, TypeInfo(SmallInt), Result)
     end;
    var_i2_14b_z:
     begin
      if (PWord(Data)^ and $2000) = 1 then si := -(PSmallint(Data)^ and $1FFF)
                else si := Smallint(PWord(Data)^ and $1FFF);
      Tvalue.Make(si, TypeInfo(SmallInt), Result)
     end
  end;
end;

class function TPars.ToVar(Data: Pointer; vt: Integer): Variant;
 var
  w: PWord;
  l,h,m: Byte;
  b: PByte;
  sn: Single;
begin
  case vt of
    varSmallint:Result := PSmallint(Data)^; { vt_i2           2 }
    varInteger :Result := PInteger(Data)^; { vt_i4           3 }
    varSingle  :
     begin
      sn := PSingle(Data)^;//^/0; { vt_r4           4 }
      if sn.SpecialType in [fsInf, fsNInf, fsNaN] then Result := 0
      else Result := sn;
     end;
    varOleStr:  Result := PAnsiChar(Data)^;
    varDouble  :Result := PDouble(Data)^; { vt_r8           5 }
    varCurrency:Result := PCurrency(Data)^; { vt_cy           6 }
   // varDate    :Result := SizeOf(TDateTime); { vt_date         7 }
    varShortInt:Result := PShortInt(Data)^; { vt_i1          16 }
    varByte    :Result := PByte(Data)^; { vt_ui1         17 }
    varWord    :Result := PWord(Data)^; { vt_ui2         18 }
    varLongWord:Result := PLongWord(Data)^; { vt_ui4         19 }
    varInt64   :Result := PInt64(Data)^; { vt_i8          20 }
    varUInt64  :Result := PUInt64(Data)^; { vt_ui8         21 }
    var_i3     :Result := Integer(PLongWord(Data)^ shl 8) div $100;
    var_ui3    :Result := LongWord(PLongWord(Data)^ and $00FFFFFF);
    var_i2_15b :if (PWord(Data)^ and $4000) = 0 then Result := PSmallint(Data)^ and $3FFF
                else Result := PSmallint(Data)^;
    var_i2_15b_inv :if (PWord(Data)^ and $4000) = 0 then Result := -(PSmallint(Data)^ and $3FFF)
                else Result := -(PSmallint(Data)^);
    var_ui2_15b:Result := PWord(Data)^ and $7FFF;
    var_i2_10b  :if (PWord(Data)^ and $200) = 0 then Result := PSmallint(Data)^ and $1FF
                else Result := Smallint(PWord(Data)^ or $FE00);
    var_i2_14b  :if (PWord(Data)^ and $2000) = 0 then Result := PSmallint(Data)^ and $1FFF
                else Result := Smallint(PWord(Data)^ or $E000);
    var_ui2_14b :Result := Word(PWord(Data)^ and $3FFF);
    var_inv_word:
     begin
      b := Data;
      h := b^; Inc(b);
      l := b^;
      Result := word((word(h) shl 8) or l);
     end;
    var_i2_14b_GZ:
     begin
      w := Data;
      Result := (w^ shr 8) and $7F;
      Dec(w);
      Result := Result or ((w^ and $7F00) shr 1);
      if (Result and $2000) <> 0 then Result := Smallint(PWord(Data)^ or $E000);
     end;
    var_ui2_kadr_psk4:
     begin
      w := Data;
      Result := word(w^ shl 8);
      Dec(w);
      Dec(w);
      Result := word(Result or (w^ and $00FF));
     end;
    var_inv_ui3_ltr:
     begin
      b := Data;
      h := b^; Inc(b);
      m := b^; Inc(b);
      l := b^;
      Result := LongWord(LongWord(h)*2000 + LongWord(m)*$100 + l);
     end;
    var_inv_i3:
    begin
      b := Data;
      h := b^; Inc(b);
      m := b^; Inc(b);
      l := b^;
      if h and $80 <> 0 then Result := Integer($FF000000 + LongWord(h)*$10000 + LongWord(m)*$100 + l)
      else Result := Integer(LongWord(h)*$10000 + LongWord(m)*$100 + l);
    end;
    var_inv_ui3:
     begin
      b := Data;
      h := b^; Inc(b);
      m := b^; Inc(b);
      l := b^;
      Result := LongWord(LongWord(h)*$10000 + LongWord(m)*$100 + l);
     end;
    var_ui2_kadr_all:
     begin
      w := Data;
      Result := word(w^ shl 8);
      Dec(w);
      Result := Word(Result or (w^ and $00FF));
     end;
    var_ui2_8b:
     begin
      w := Data;
      Result := Byte(w^ and $00FF);
     end;
    var_i2_14b_z_inv:
     begin
      if (PWord(Data)^ and $2000) = 0 then Result := -(PSmallint(Data)^ and $1FFF)
                else Result := Smallint(PWord(Data)^ and $1FFF);
     end;
    var_i2_14b_z:
     begin
      if (PWord(Data)^ and $2000) = 1 then Result := -(PSmallint(Data)^ and $1FFF)
                else Result := Smallint(PWord(Data)^ and $1FFF);
     end
  else  raise Exception.Create('НЕВОЗМОЖНО ПРЕОБРАЗОВАТЬ УКАЗАТЕЛЬ В ВАРИАНТ!!!');
  end;
end;

class procedure TPars.SetData(const value: TArray<TParserData>; const Data: PByte; ParsArray: Boolean);
 var
  v: TParserData;
begin
  for v in value do v.SetData(Data);
end;

class procedure TPars.SetInfo(node: IXMLNode; Info: PByte; InfoLen: integer; hev: THackEvent = nil);
type
  TDataAttr=record
   AttrName: string;
   value: Variant;
  end;
 var
  CurIndex: Integer;
  DataAttr: TArray<TDataAttr>;
  NoPowerCnt, NoPowerLen: Integer;
  NoPowerNode: IXMLNode;
  procedure AddDataAttr(AttrName: string; value: Variant);
   var
    da: TDataAttr;
  begin
    da.AttrName := AttrName;
    da.value := value;
    DataAttr := DataAttr + [da]
  end;
  function PStr(var sp: PByte; var sn: integer): string;
  begin
    Result := string(PAnsiChar(sp));
    Dec(sn, Length(Result)+1); Inc(sp, Length(Result)+1); // parse name
  end;
  function Add(u: IXMLNode; var sp: PByte; sn: integer): integer; // возвращает размер реальной структуры
   var
    tp, arr_len, slen, savelen: integer;
    function AddMetr(const s: string): IXMLNode;
     var
      a: TArray<string>;
    begin
      a := s.Split(['|'], TStringSplitOptions.ExcludeEmpty);
      Result := u.AddChild(a[0]);
      if Length(a)>1 then Result.Attributes[AT_METR] := a[1];
    end;
    function AddXRec(const s: string): IXMLNode;
    begin
      Result := AddMetr(s);
      for var a in DataAttr do Result.Attributes[a.AttrName] := a.value;
      SetLength(DataAttr,0);
      if (Result.NodeName = T_WRK) or (Result.NodeName = T_RAM) or (Result.NodeName = T_EEPROM) then CurIndex := 0;
    end;
    function AddXDat(const s: string; arr: Integer = 1): Integer;
     var
      ch, r: IXMLNode;
    begin
      r := AddMetr(s);
      if arr > 1 then r.Attributes[AT_ARRAY] := arr;
      ch := r.AddChild(T_DEV);
      ch.Attributes[AT_TIP] := tp;
      Result := VarTypeToLength(tp) * arr;
      if NoPowerCnt > 0 then
       begin
        Inc(NoPowerLen, Result);
        Dec(NoPowerCnt);
        if NoPowerCnt = 0 then
         begin
          NoPowerNode.Attributes[AT_EXT_NP_LEN] := NoPowerLen;
         end;
       end;
      ch.Attributes[AT_INDEX] := CurIndex;
      for var a in DataAttr do ch.Attributes[a.AttrName] := a.value;
      Inc(CurIndex, Result);
      SetLength(DataAttr,0);
    end;
  begin
    Result := 0;
    while sn > 0 do
     begin
      case sp^ of
        varRecord:
        begin
          slen := PWord(@sp[1])^;
          savelen := slen;
          Inc(sp,3); Dec(slen,3); // parse length, tip
          Inc(Result, Add(AddXRec(PStr(sp, slen)), sp, slen)); // parse name  // рекурсия на ветвях
          Dec(sn, savelen); // parse record length from root
        end;
        var_info:
        begin
          if Assigned(hev) then hev(sp^, sp + 1);
          Inc(sp); Dec(sn);   // parse tip
          u.Attributes[AT_INFO] := PStr(sp, sn); // parse info
        end;
        var_adr:
        begin
          if Assigned(hev) then hev(sp^, sp + 1);
          u.Attributes[AT_ADDR] := sp[1]; // parse addr
          Inc(sp, 2); Dec(sn, 2);   // parse tip, addr
        end;
        varRamSize:
        begin
          if Assigned(hev) then hev(sp^, sp + 1);
          u.Attributes[AT_RAMSIZE] := PWord(@sp[1])^; // parse ram_size
          Inc(sp, 3); Dec(sn, 3);   // parse tip, ram_size
        end;
        varSSDSize:
        begin
          if Assigned(hev) then hev(sp^, sp + 1);
          u.Attributes[AT_SSD] := PCardinal(@sp[1])^; // parse ram_size
          Inc(sp, 5); Dec(sn, 5);   // parse tip, ram_size
        end;
        varChip:
        begin
          if Assigned(hev) then hev(sp^, sp + 1);
          u.Attributes[AT_CHIP] := sp[1]; // parse chip_index
          Inc(sp, 2); Dec(sn, 2);   // parse tip, chip_index
        end;
        varSerial:
        begin
          if Assigned(hev) then hev(sp^, sp + 1);
          u.Attributes[AT_SERIAL] := PWord(@sp[1])^; // parse serial
          Inc(sp, 3); Dec(sn, 3);   // parse tip, serial
        end;
        varFrom:
        begin
          if Assigned(hev) then hev(sp^, sp + 1);
          AddDataAttr(AT_FROM, PWord(@sp[1])^);
//          u.Attributes[AT_FROM] := PWord(@sp[1])^; // parse from addr
          Inc(sp, 3); Dec(sn, 3);   // parse tip, from Addr
        end;
        varSupportUartSpeed:
        begin
          if Assigned(hev) then hev(sp^, sp + 1);
          u.Attributes[AT_SPEED] := PWord(@sp[1])^;
          Inc(sp, 3); Dec(sn, 3);   // parse tip, serial
        end;
        varExtNoPowerDataCount:
        begin
          if Assigned(hev) then hev(sp^, sp + 1);
          u.Attributes[AT_EXT_NP] := sp[1]; // parse Ext no power count
          NoPowerCnt := sp[1];
          NoPowerLen := 0;
          NoPowerNode := u;
          Inc(sp, 2); Dec(sn, 2);   // parse Ext no power count
        end;
        varDigits:
        begin
          if Assigned(hev) then hev(sp^, sp + 1);
          AddDataAttr(AT_DIGITS, sp[1]);
          Inc(sp, 2); Dec(sn, 2);   // parse Ext no power count
        end;
        varPrecision:
        begin
          if Assigned(hev) then hev(sp^, sp + 1);
          AddDataAttr(AT_AQURICY, sp[1]);
          Inc(sp, 2); Dec(sn, 2);   // parse Ext no power count
        end;
        var_array:
         begin
          arr_len := PWord(@sp[1])^; // parse array size
          Inc(sp, 3); Dec(sn, 3);   // parse tip, array size
          tp := sp^; //сохраним тип
          Inc(sp); Dec(sn);   // parse tip
          Inc(Result, AddXDat(PStr(sp, sn), arr_len)); // parse name
         end
        else
         begin
          tp := sp^; //сохраним тип
          Inc(sp); Dec(sn);   // parse tip
          Inc(Result, AddXDat(PStr(sp, sn))); // parse name
         end;
      end;
      if sn < 0 then
       begin
      //  node.OwnerDocument.SaveToFile(ExtractFilePath(ParamStr(0))+'Prof.xml');
        raise Exception.Create('ОШИБКА ИЗВЛЕЧЕНИЯ ИНФОРМАЦИИ О ДАННЫХ!!!');
       end;
     end;
     u.Attributes[AT_SIZE] := Result;
  end;
// var
//  test: TArray<Byte>;
begin
//  SetLength(test, InfoLen);
//  move(Info^,test[0],InfoLen);

    NoPowerCnt := 0;
    NoPowerLen := 0;
  CurIndex := 0;
//  Dec(InfoLen, CASZ); Inc(Info, CASZ); // parse cmdadr
  Add(node, Info, InfoLen); // указывает на тип - структуру
end;
                      //   указывает на device
{class procedure TPars.SetMetr(node: IXMLNode; ExeSc: IXmlScript; ExecSetup: Boolean);
 const
  SF = 'SIMPLE_FORMAT';
  MD = 'MODEL';
 var
  sd: IXmlScript;
  adr: Integer;
  mtr: IXMLNode;
//  ExecSetup: Boolean;
  procedure AddAll(dev: IXMLNode; const ExePath: string);
   var
    r: IXMLNode;
  begin
    r := dev.ChildNodes.FindNode(ExePath);
    if not Assigned(r) then Exit;
    ExecXTree(r, procedure(n: IXMLNode)
     var
      s: string;
      sr, mc: IXMLNode;
     procedure AddXML(TrRoot, Script: IXMLNode; const RootPrefix: string = '');
     begin
        if ExecSetup then sd.AddXML(adr, ExePath, TrRoot, n, Script, SETUP, RootPrefix);
       ExeSc.AddXml(adr, ExePath, TrRoot, n, Script, EXEC, RootPrefix);
     end;
    begin
      s := n.NodeName;
      sr := XMLScript.ChildNodes.FindNode(s);
      if Assigned(sr) then
       begin
        mc := mtr.ChildNodes.FindNode(s);
        if not Assigned(mc) then
         begin
          mc := mtr.AddChild(s);
          if n.HasAttribute(AT_METR) then mc.Attributes[AT_METR] := n.Attributes[AT_METR];
         end;
        AddXML(mc, sr);
        if n.HasAttribute(AT_METR) then AddXML(mc, sr.ChildNodes[MD].ChildNodes[n.Attributes[AT_METR]], s);
       end
      else if n.HasAttribute(AT_METR) then AddXML(mtr, XMLScript.ChildNodes[SF].ChildNodes[MD].ChildNodes[n.Attributes[AT_METR]], SF);
    end);
  end;
 var
  d: IXMLNode;
begin
//  ExecSetup := True;
  ExeSc.ClearLines;
  if ExecSetup then sd := (GContainer as IXMLScriptFactory).Get(nil);
  try
   { TODO : Впроекте V3 работать не будет !!!! будет при правильном node}
{   for d in XEnum(node) do if d.HasAttribute(AT_ADDR) then
    begin
     adr := d.Attributes[AT_ADDR];
     mtr := d.ChildNodes.FindNode(T_MTR);
     if not Assigned(mtr) then mtr := d.AddChild(T_MTR);
     AddAll(d, T_WRK);
     AddAll(d, T_RAM);
    end;
   if ExecSetup then
    begin
     sd.Lines.Add('begin');
     sd.Lines.Add('end.');

     if not sd.Compile then MessageDlg('Ошибка компиляции установок-'+sd.ErrorMsg+':'+sd.ErrorPos, TMsgDlgType.mtError, [mbOK], 0);
     sd.Execute; { TODO 5 -cОШИВКА!!! : ОШИБКА заполняется метрология (если есть) значениями по умолчанию!!! }

     //sd.Lines.SaveToFile(ExtractFilePath(ParamStr(0))+'GKScriptSetup.txt');
{    end;
//    node.OwnerDocument.SaveToFile(ExtractFilePath(ParamStr(0))+'RP45.xml');

    ExeSc.Lines.Add('begin');
    ExeSc.Lines.Add('end.');

//    ExeSc.Lines.SaveToFile(ExtractFilePath(ParamStr(0))+'~tst\ExeSc.txt');

    if not ExeSc.Compile then MessageDlg('Ошибка компиляции выполнения-'+ExeSc.ErrorMsg+':'+ExeSc.ErrorPos, TMsgDlgType.mtError, [mbOK], 0);

   // node.OwnerDocument.SaveToFile(ExtractFilePath(ParamStr(0))+'PSKafter.xml');

  finally
   if ExecSetup then sd := nil;
  end;
end;}

class procedure TPars.LocalGetData(root: IXMLNode; var Data: TOutArray);
 var
  d: TOutArray;
  offset:Integer;
begin
   SetLength(d, Integer(root.Attributes[AT_SIZE]));
   offset := root.Attributes['offset'];
   ExecXTree(root, procedure(n: IXMLNode)
   begin
     if n.HasAttribute(AT_TIP) and n.HasAttribute(AT_INDEX) and n.HasAttribute(AT_VALUE)
       and (n.NodeName = T_DEV) then
      if n.ParentNode.HasAttribute(AT_ARRAY) then
           FromVar(n.Attributes[AT_VALUE],
           Integer(n.Attributes[AT_TIP]),
           n.ParentNode.Attributes[AT_ARRAY],
           @d[Integer(n.Attributes[AT_INDEX])-offset])
      else FromVar(n.Attributes[AT_VALUE], Integer(n.Attributes[AT_TIP]),
           @d[Integer(n.Attributes[AT_INDEX])-offset]);
   end);
   Data := d;
end;

class procedure TPars.GetData(root: IXMLNode; var Data: TOutArray);
 var
  d: TOutArray;
begin
   SetLength(d, Integer(root.Attributes[AT_SIZE]));
   ExecXTree(root, procedure(n: IXMLNode)
   begin
     if n.HasAttribute(AT_TIP) and n.HasAttribute(AT_INDEX) and n.HasAttribute(AT_VALUE)
       and (n.NodeName = T_DEV) then
      if n.ParentNode.HasAttribute(AT_ARRAY) then
           FromVar(n.Attributes[AT_VALUE], Integer(n.Attributes[AT_TIP]), n.ParentNode.Attributes[AT_ARRAY], @d[Integer(n.Attributes[AT_INDEX])])
      else FromVar(n.Attributes[AT_VALUE], Integer(n.Attributes[AT_TIP]), @d[Integer(n.Attributes[AT_INDEX])]);
   end);
   Data := d;
end;

class procedure TPars.LocalSetData(root: IXMLNode; const Data: PByte);
 var
  offset:Integer;
begin
   offset := root.Attributes['offset'];
   ExecXTree(root, function(n: IXMLNode): boolean
   begin
     if n.HasAttribute(AT_TIP) and n.HasAttribute(AT_INDEX) then
      begin
       var dind := Integer(n.Attributes[AT_INDEX])-offset;
      if n.ParentNode.HasAttribute(AT_ARRAY) then
        n.Attributes[AT_VALUE] := ArrayToString(Data + dind, n.ParentNode.Attributes[AT_ARRAY], n.Attributes[AT_TIP])
      else
        n.Attributes[AT_VALUE] := ToVar(Data + dind, n.Attributes[AT_TIP]);
      end;
   end);
end;

class procedure TPars.SetData(root: IXMLNode; const Data: PByte; ParsArray: Boolean = True; CntStd: Integer = -1);
begin
//  if not Assigned(root.ChildNodes.FindNode('автомат')) then raise ENoStackException.Create('Метаданные "автомат" ненайдены');
//  if not Assigned(root.ChildNodes.FindNode('время')) then raise ENoStackException.Create('Метаданные "время" ненайдены');

   ExecXTree(root, function(n: IXMLNode): boolean
   begin
     if n.HasAttribute(AT_TIP) and n.HasAttribute(AT_INDEX) then
      begin
      if n.ParentNode.HasAttribute(AT_ARRAY) and ParsArray then
        n.Attributes[AT_VALUE] := ArrayToString(Data + Integer(n.Attributes[AT_INDEX]), n.ParentNode.Attributes[AT_ARRAY], n.Attributes[AT_TIP])
      else
        n.Attributes[AT_VALUE] := ToVar(Data + Integer(n.Attributes[AT_INDEX]), n.Attributes[AT_TIP]);
        if CntStd > 0 then dec(CntStd);
      end;
     Result := CntStd = 0;
   end);
end;

//class procedure TPars.SetStd(root: IXMLNode; const Data: PByte);
// var
//  Nopower
//begin
//
//end;

//class procedure TPars.SetStd(root: IXMLNode; const Data: PByte);
// var
//  u: IXMLNode;
//begin
////  if not Assigned(root.ChildNodes.FindNode('автомат')) then raise ENoStackException.Create('Метаданные "автомат" ненайдены');
////  if not Assigned(root.ChildNodes.FindNode('время')) then raise ENoStackException.Create('Метаданные "время" ненайдены');
//
//  u := root.ChildNodes.FindNode('автомат').ChildNodes.FindNode(T_DEV);
//
//  if Assigned(u) and u.HasAttribute(AT_TIP) and u.HasAttribute(AT_INDEX) then
//     u.Attributes[AT_VALUE] := ToVar(Data + Integer(u.Attributes[AT_INDEX]), u.Attributes[AT_TIP]);
//
//  u := root.ChildNodes.FindNode('время').ChildNodes.FindNode(T_DEV);
//
//  if Assigned(u) and u.HasAttribute(AT_TIP) and u.HasAttribute(AT_INDEX) then
//     u.Attributes[AT_VALUE] := ToVar(Data + Integer(u.Attributes[AT_INDEX]), u.Attributes[AT_TIP]);
//end;

{ TODO : ПСК AT_INDEX в словах и данные PWord надо переделать в байты и сделать единую функцию SetData}
class procedure TPars.SetPsk(root: IXMLNode; const Data: PWord);
begin
  if root.ParentNode.HasAttribute(AT_PSK_BYTE_ADDR) then  SetData(root, Pbyte(Data))
  else ExecXTree(root, procedure(n: IXMLNode)
    var
     di: PWord;
   begin
     if n.HasAttribute(AT_TIP) and n.HasAttribute(AT_INDEX) then
      begin
       di := Data;
       Inc(di, Integer(n.Attributes[AT_INDEX]));
       if n.ParentNode.HasAttribute(AT_ARRAY) then
            n.Attributes[AT_VALUE] := ArrayToString(PByte(di), n.ParentNode.Attributes[AT_ARRAY], n.Attributes[AT_TIP])
       else n.Attributes[AT_VALUE] := ToVar(di, n.Attributes[AT_TIP]);
      end;
   end);
end;

class procedure TPars.SetPskToStd(root: IXMLNode; const Data: PWord);
begin
  ExecXTree(root, procedure(n: IXMLNode)
    var
     di: PWord;
   begin
     if n.HasAttribute(AT_TIP) and n.HasAttribute(AT_INDEX) then
      begin
       di := Data;
       Inc(di, Integer(n.Attributes[AT_INDEX]));
       if n.ParentNode.HasAttribute(AT_ARRAY) then
        begin
         // n.Attributes[AT_VALUE] := ArrayToString(PByte(di), n.ParentNode.Attributes[AT_ARRAY], n.Attributes[AT_TIP])
        end
       else  ToPointer(di, di, n.Attributes[AT_TIP]);
      end;
   end);
end;

{$ENDREGION}

{ TPrserData }

constructor TParserData.Create(n: IXMLNode; IsWord: Boolean = false);
begin
  tip := TPars.VarTypeToType(n.Attributes[AT_TIP]);
  index := n.Attributes[AT_INDEX];
  if IsWord then index := index *2;
  if n.ParentNode.HasAttribute(AT_ARRAY) then ArraySize := n.ParentNode.Attributes[AT_ARRAY];
  Value := n.AttributeNodes[AT_VALUE];
end;

procedure TParserData.SetData(pData: PByte; parsArray: Boolean = false);
begin
//  Convert(pData + Index, ArraySize, Value);
  if parsArray and (ArraySize > 0) then Value.NodeValue := TPars.ArrayToString(pData + Index, ArraySize, tip)
  else Value.NodeValue := TPars.ToVar(pData + Index, tip);
end;

initialization
//  CoInitialize(nil); { TODO : Easy interface требует CoInitialize}
  TPars.Init;
finalization
  TPars.DeInit;
end.

unit MetaData;

interface

uses sysutils, Classes,
     System.Generics.Collections;
 type
   TMetaData = class
     class var Len_count: Integer;
     class function Generate(const SS: TStrings): TArray<Byte>;
   end;

implementation

uses Parser;

type
   TMetaType = class;
   TMetaTypeClass = class of TMetaType;
   TMetaValue = record
     tip: TMetaType;
     value: string;
     ArrayLength: Integer;
     function Meta: TBytes;
     function Size: Integer;
   end;
   TMetaType = class(TInterfacedObject)
   private
     FVarType: Integer;
     FItems: TArray<TMetaValue>;
     class var FRegItem: TDictionary<string, TMetaType>;
     class var FDefines: TDictionary<string, string>;
     class procedure Reg(const typ: string; vart: Integer; cls: TMetaTypeClass); overload;
     class procedure Reg(const typ: string; Item: TMetaType); overload;
     class constructor Create;
     class destructor Destroy;
     class function ExtractUserData(var s: string): string;
     class function ExtractUserDataAttributes(var s: string): TArray<TMetaValue>;
     class function GetValue(const s: string): string;
   protected
     function Size(const Value: string; ArrayLength: Integer): Integer; virtual;
     function Meta(const Value: string; ArrayLength: Integer): TArray<Byte>; virtual;
   public
     constructor Create(VarType: Integer); virtual;
     function Add(data: TMetaValue): TMetaValue;
     procedure AddArray(data: TArray<TMetaValue>);
     class function ParseSimpleString(const line: string): TArray<TMetaValue>;
   end;

   TMetaUserByte = class(TMetaType)
   protected
     function Size(const Value: string; ArrayLength: Integer): Integer; override;
     function Meta(const Value: string; ArrayLength: Integer): TArray<Byte>; override;
   end;
   TMetaUserWord = class(TMetaType)
   protected
     function Size(const Value: string; ArrayLength: Integer): Integer; override;
     function Meta(const Value: string; ArrayLength: Integer): TArray<Byte>; override;
   end;
   TMetaUserDWord = class(TMetaType)
   protected
     function Size(const Value: string; ArrayLength: Integer): Integer; override;
     function Meta(const Value: string; ArrayLength: Integer): TArray<Byte>; override;
   end;

   TMetaRecItem = class(TMetaType)
   protected
     function Size(const Value: string; ArrayLength: Integer): Integer; override;
     function Meta(const Value: string; ArrayLength: Integer): TArray<Byte>; override;
   end;

{ TMetaValue }

function TMetaValue.Meta: TBytes;
begin
  Result := tip.Meta(value, ArrayLength)
end;

function TMetaValue.Size: Integer;
begin
  Result := tip.Size(value, ArrayLength)
end;


{ TMetaItem }

class constructor TMetaType.Create;
begin
  FDefines := TDictionary<string, string>.Create();
  FRegItem := TDictionary<string, TMetaType>.Create();
  Reg('int8_t', varShortInt, TMetaType);
  Reg('uint8_t', varByte, TMetaType);
  Reg('int16_t', varSmallint, TMetaType);
  Reg('uint16_t', varWord, TMetaType);
  Reg('int32_t', varInteger, TMetaType);
  Reg('uint32_t', varLongWord, TMetaType);
  Reg('int64_t', varInt64, TMetaType);
  Reg('uint64_t', varUInt64, TMetaType);
  Reg('double', varDouble, TMetaType);
  Reg('float', varSingle, TMetaType);
  Reg('var_info', TPars.var_info, TMetaType);
  Reg('var_adr', TPars.var_adr, TMetaUserByte);
  Reg('varChip', TPars.varChip, TMetaUserByte);
  Reg('varSerial', TPars.varSerial, TMetaUserWord);
  Reg('varRamSize', TPars.varRamSize, TMetaUserWord);
  Reg('varSSDSize', TPars.varSSDSize, TMetaUserDWord);
  Reg('varSupportUartSpeed', TPars.varSupportUartSpeed, TMetaUserWord);
  Reg('varExtNoPowerDataCount', TPars.varExtNoPowerDataCount, TMetaUserByte);
  Reg('varDigits', TPars.varDigits, TMetaUserByte);
  Reg('varPrecision', TPars.varPrecision, TMetaUserByte);
  Reg('varFrom', TPars.varFrom, TMetaUserWord);
end;

class procedure TMetaType.Reg(const typ: string; vart: Integer; cls: TMetaTypeClass);
begin
  FRegItem.AddOrSetValue(typ, cls.Create(vart));
end;
class procedure TMetaType.Reg(const typ: string; Item: TMetaType);
begin
  FRegItem.AddOrSetValue(typ, Item);
end;

constructor TMetaType.Create(VarType: Integer);
begin
  FVarType := VarType;
end;

class destructor TMetaType.Destroy;
begin
  FRegItem.Free;
  FDefines.Free;
end;

function TMetaType.Add(data: TMetaValue): TMetaValue;
begin
  Result := data;
  FItems := FItems + [Result];
end;

procedure TMetaType.AddArray(data: TArray<TMetaValue>);
begin
  FItems := FItems + Data;
end;

function TMetaType.Size(const Value: string; ArrayLength: Integer): Integer;
begin                          //0
  Result := 1 + Length(Value) + 1;
  if ArrayLength > 0 then inc(Result, 3);
end;

function TMetaType.Meta(const Value: string; ArrayLength: Integer): TArray<Byte>;
 var
  s: PAnsiChar;
  Marshall: TMarshaller;
begin
  s := Marshall.AsAnsi(Value).ToPointer;
                //type          //0 term
  SetLength(Result, 1 + length(s)+1);
  Result[0] := FVarType;
  Move(s^, Result[1], length(s)+1);
  if ArrayLength > 0 then
   Insert([TPars.var_array, ArrayLength, ArrayLength shr 8], Result, 0);
end;

class function TMetaType.ExtractUserData(var s: string): string;
 var
  i: Integer;
begin
  s := s.Trim;
  i := s.IndexOf('///');
  if i >= 0 then
   begin
    Result := s.Substring(i+3).Trim;
    s := s.Substring(0, i).Trim;
   end
  else Result := '';
end;

class function TMetaType.ExtractUserDataAttributes(var s: string): TArray<TMetaValue>;
 var
  i,j: Integer;
  a,ti: TArray<string>;
  ai,v: string;
  m: TMetaValue;
begin
  SetLength(Result, 0);
  s := s.Trim;
  i := s.IndexOf('[');
  j := s.IndexOf(']');
  if (i*j < 0) then raise Exception.CreateFmt('[%d,%d] Error user attr [ ]', [TMetaData.Len_count+1, i]);
  if i >= 0 then
   begin
    if i > j then raise Exception.CreateFmt('[%d,%d] Error Message ] [ ', [TMetaData.Len_count+1, i]);
    a := s.Substring(i+1, j-i-1).Split([';'], TStringSplitOptions.ExcludeEmpty);
    for ai in a do
     begin
      ti := ai.Split(['='], TStringSplitOptions.ExcludeEmpty);
      v := ti[0].Replace(#9,'').Trim;
      m.value := ti[1].Replace(#9,'').Trim;
      if FRegItem.TryGetValue(v, m.tip) then Result := Result + [m];
     end;
    s := s.Substring(0, i).Trim;
   end;
end;

class function TMetaType.GetValue(const s: string): string;
begin
  if not FDefines.TryGetValue(s, Result) then Exit(s);
end;

class function TMetaType.ParseSimpleString(const line: string): TArray<TMetaValue>;
 var
  a: TArray<string>;
  userData, s, value, es: string;
  i, j: Integer;
  Res: TMetaValue;
begin
  s := line.Trim;
  userData := ExtractUserData(s);
  Result := ExtractUserDataAttributes(userData);
  // ползовательские атрибуты
  if s.Chars[0] = '#' then
   begin
    if s.Contains('define') then
     begin
      if userData = '' then raise Exception.CreateFmt('[%d,%d] Error #define userData = "" ', [TMetaData.Len_count+1, 0]);
      s := s.Replace(#9,' ');
      i := s.IndexOf('define');
      s := s.Substring(i+6).Trim;
      value := s.Substring(s.IndexOf(' ')).Trim.Replace('"','').Trim;
      if value.Contains('__DATE__') then value := value.Replace('__DATE__', DateToStr(Now));
      Res.value := value;
      if FRegItem.TryGetValue(userData, Res.tip) then Exit(Result + [Res]);
     end;
   end
  else
   begin
  // стандартные типы
    i := s.IndexOf(';');
    if i <= 0 then
     begin
      if line = '{' then  es := 'начало структукуры { должно быть с новой строки' else es := '';
      raise Exception.CreateFmt('[%d,%d] Error none ";" line ['+ line +'] %s', [TMetaData.Len_count+1, i, es]);
     end;
    s := s.Replace(';','').Trim;
    // ползовательские атрибуты

    // array
    Res.ArrayLength := 0;
    i := s.IndexOf('[');
    j := s.IndexOf(']');
    if (i*j < 0) then raise Exception.CreateFmt('[%d,%d] Error array [ ]', [TMetaData.Len_count+1, i]);
    if i > 0 then
     begin
      if i > j then raise Exception.CreateFmt('[%d,%d] Error Message ] [ ', [TMetaData.Len_count+1, i]);
      Res.ArrayLength := GetValue(s.Substring(i+1,j-i-1).Trim).ToInteger;
      s := s.Remove(i, j-i+1)
     end;
    // end array
    a := s.Split([' ',#$9], TStringSplitOptions.ExcludeEmpty);
    if userData <> '' then Res.value := userData
    else Res.value := a[1].Trim;
    if FRegItem.TryGetValue(a[0].Trim, Res.tip) then  Exit(Result + [Res]);
   end;
   raise Exception.CreateFmt('[%d,%d] Error ParseSimpleString %s', [TMetaData.Len_count+1, i, s]);
end;

{ TMetaRecItem }

function TMetaRecItem.Size(const Value: string; ArrayLength: Integer): Integer;
 var
  m: TMetaValue;
begin
  Result := inherited + 2;
  for m in FItems do Inc(Result, m.Size);
end;

function TMetaRecItem.Meta(const Value: string; ArrayLength: Integer): TArray<Byte>;
 var
  m: TMetaValue;
  sz: Word;
begin
  Result := inherited;
  sz := Size(Value, ArrayLength);
  Insert([sz, sz shr 8], Result, 1);
  for m in FItems do Result := Result + m.Meta;
end;


{ TMetaUserByte }

function TMetaUserByte.Meta(const Value: string; ArrayLength: Integer): TArray<Byte>;
begin
  SetLength(Result, 2);
  Result[0] := FVarType;
  Result[1] := StrToInt(Value);
end;

function TMetaUserByte.Size(const Value: string; ArrayLength: Integer): Integer;
begin
  Result := 2;
end;

{ TMetaUserWord }

function TMetaUserWord.Meta(const Value: string; ArrayLength: Integer): TArray<Byte>;
begin
  SetLength(Result, 3);
  Result[0] := FVarType;
  PWord(@Result[1])^ := StrToInt(Value);
end;

function TMetaUserWord.Size(const Value: string; ArrayLength: Integer): Integer;
begin
  Result := 3;
end;

{ TMetaUserDWord }

function TMetaUserDWord.Meta(const Value: string; ArrayLength: Integer): TArray<Byte>;
begin
  SetLength(Result, 5);
  Result[0] := FVarType;
  PInteger(@Result[1])^ := StrToInt(Value);
end;

function TMetaUserDWord.Size(const Value: string; ArrayLength: Integer): Integer;
begin
  Result := 5;
end;



{ TMetaData }

class function TMetaData.Generate(const SS: TStrings): TArray<Byte>;
 var
  s, recvalue, rectype: string;
  v: TMetaRecItem;

  procedure BeginRec;
  begin
   if s.Contains('{') then  // если rec {
    begin
     s := s.Substring(s.IndexOf('{'));
     Exit;
    end;
   repeat
    inc(Len_count);
    if Len_count >= SS.Count then raise Exception.CreateFmt('[%d,%d] none {', [TMetaData.Len_count+1, 0]);
    s := ss[Len_count].Trim;
    if s = '' then Continue;
    if s.Chars[0] = '{' then
     begin
      s := s.Substring(1).Trim;  // если ( sss = sdsd;
      Exit;
     end
    else raise Exception.CreateFmt('[%d,%d] none {', [TMetaData.Len_count+1, 0]);
   until false;
  end;

  function EndRec: Boolean;
  begin
    Result := False;
    repeat
     inc(Len_count);
     if Len_count >= SS.Count then raise Exception.CreateFmt('[%d,%d] none }', [TMetaData.Len_count+1, 0]);
     s := ss[Len_count].Trim;
    until s <> '';
    if s.Contains('}') then
     begin
      if s.Chars[0] = '}' then
       begin
        s := s.Replace('}','').Replace(';','').Trim;
        recvalue := TMetaType.ExtractUserData(s);
        rectype := s.Split([' ',#$9], TStringSplitOptions.ExcludeEmpty)[0];
        inc(Len_count);
       end
      else raise Exception.CreateFmt('[%d,%d] окончание структукуры }; должно быть с новой строки', [TMetaData.Len_count+1, 0]);
      Result := True;
     end;
  end;
  procedure AddDefine(const line: string);
   var
    a: TArray<string>;
    i: Integer;
  begin
    s := s.Replace(#9,' ');
    i := s.IndexOf('define');
    s := s.Substring(i+6).Trim;
    a := s.Split([' '], TStringSplitOptions.ExcludeEmpty);
    TMetaType.FDefines.Add(a[0], a[1]);
  end;
begin
  Len_count := 0;
  // поиск структур
  while Len_count < ss.Count do
   begin
    s := ss[Len_count].Trim;
    // в файле только структуры !!!
    if s.Contains('typedef') then
     begin
      if s.Contains('struct') then
       begin
        v := TMetaRecItem.Create(varRecord);
        BeginRec();
        repeat
         if s.Trim <> '' then v.AddArray(TMetaType.ParseSimpleString(s));
        until EndRec();
        TMetaType.Reg(rectype, v);
        // один экземпл€р основной структуры  AllDataStruct_t
        if rectype = 'AllDataStruct_t' then Exit (v.Meta(recvalue, 0));
       end
       else raise Exception.CreateFmt('[%d,%d] typedef only struct', [Len_count+1, 0]);
     end
    else if (s <> '') and (s.Chars[0] = '#') and s.Contains('define') then
     begin
      if s.Contains('/') then Exception.CreateFmt('[%d,%d] не должно быть // /*', [TMetaData.Len_count+1, s.IndexOf('/')]);
      AddDefine(s);
      inc(Len_count);
     end
    else inc(Len_count);
   end;
end;

end.

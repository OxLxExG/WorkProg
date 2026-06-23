unit MetaData2.CParser;

interface


uses sysutils, Classes,  System.TypInfo, MetaData2.Classes,
     System.Generics.Collections;

 type
  TheaderFileParser = class
  private
   class var row, col: integer;
   class var token: string;
   class var FlagStruct: Boolean;
   class var TokRow: TArray<string>;
   class var CurTok: array[0..100] of string;

   class var Index: Byte;
   class var FDefines: TDictionary<string, string>;
   class var FStructTypes: TDictionary<string, TStructTypedef>;
   class var tokens: TArray<TArray<string>>;
   class constructor Create;
   class destructor Destroy;
   // factorys
   class function AttrFactory(const tocs: array of string): TTyped;
   class function DataTypeFactory(attr: TTypedArray; Tip: TmetadataType; const tocs: Tarray<string>): TTyped;
   class function DataStructFactory(attr: TTypedArray; const tip :TStructTypedef; const tocs: Tarray<string>): TDataStruct;
   class function StructFactory(attr: TTypedArray; const data: TTypedArray): TStructTypedef;
   // tools
   class function AttrArrContains(attr: TTypedArray; item: TTypedClass): Boolean;
   class function AttrArrGet(attr: TTypedArray; item: TTypedClass): TTyped;
    // если не структура!!!
   // not TattrNoname and TattrName
   class function IsNamed(attr: TTypedArray; var CName: string): Boolean;
   // TattrName
   class function IsNamedStruct(attr: TTypedArray; var CName: string): Boolean;
   // TattrNoname
   class function IsNoNamed(attr: TTypedArray): Boolean;
   // TattrStructName
   class function IsStructName(attr: TTypedArray): Boolean;
   class function AddAttrArray(const tocs: Tarray<string>; var arrs: TTypedArray): Boolean;
   // check defines
   class function GetValue(const s: string): string; static;
   class procedure RaiseException(const message: string);
  public
   class procedure Parse(const ss: TStrings);
   class function GetMetaData: TBytes;
  end;




implementation

{ TheaderFileParser }

class constructor TheaderFileParser.Create;
begin
  Index := 0;
  FDefines := TDictionary<string, string>.Create();
  FStructTypes := TDictionary<string, TStructTypedef>.Create();
end;

class destructor TheaderFileParser.Destroy;
begin
  FDefines.Free;
  FStructTypes.Free;
end;

class function TheaderFileParser.AttrArrContains(attr: TTypedArray; item: TTypedClass): Boolean;
begin
  Result := False;
  for var a in attr do if a.ClassType = item then Exit(True);
end;

class function TheaderFileParser.AttrArrGet(attr: TTypedArray; item: TTypedClass): TTyped;
begin
  Result := nil;
  for var a in attr do if a.ClassType = item then Exit(a);
end;

class function TheaderFileParser.IsNamed(attr: TTypedArray; var CName: string): Boolean;
begin
  Result := not AttrArrContains(attr, TattrNoname);
  if Result and AttrArrContains(attr, TattrName) then CName := TattrName(AttrArrGet(attr, TattrName)).SVal;
end;

class function TheaderFileParser.IsNamedStruct(attr: TTypedArray; var CName: string): Boolean;
begin
  Result := AttrArrContains(attr, TattrName);
  if Result then CName := TattrName(AttrArrGet(attr, TattrName)).SVal;
end;

class function TheaderFileParser.IsNoNamed(attr: TTypedArray): Boolean;
begin
  Result := AttrArrContains(attr, TattrNoname);
end;

class function TheaderFileParser.IsStructName(attr: TTypedArray): Boolean;
begin
  Result := AttrArrContains(attr, TattrStructName);
end;

class function TheaderFileParser.GetValue(const s: string): string;
 var
  v: string;
begin
  Result := s;
  while FDefines.TryGetValue(Result, v) do
   begin
    Result := v;
   end;
end;

class function TheaderFileParser.AddAttrArray(const tocs: Tarray<string>; var arrs: TTypedArray): Boolean;
begin
  Result := False;
  if (Length(tocs) >=4) and (tocs[1] ='[') and  (tocs[3] =']') then
   begin
     var l := StrAsInt(GetValue(tocs[2]));
     var a: TTyped;
     if l <= 255 then
       a := TUint8.CreateT(ATTR+LEN_1+ATTR_IDX_ARRAY, l)
     else
       a := TUint16.CreateT(ATTR+LEN_2+ATTR_IDX_ARRAY, l);
    arrs := arrs + [a];
    Result := True;
   end;
end;

class function TheaderFileParser.AttrFactory(const tocs: array of string): TTyped;
begin
   for var a in ATR_TYPES do if a.Name = tocs[0] then
   begin
    Result := a.cls.Create(a.Tip, GetValue(tocs[2]));
    Exit;
   end;
  RaiseException(Format('атрибут с именем(%s) не найден', [tocs[0]]));
end;

class function TheaderFileParser.DataTypeFactory(attr: TArray<TTyped>; Tip: TmetadataType;
  const tocs: Tarray<string>): TTyped;
begin
  Result := TTyped.Create(Tip);
  Result.attr := attr;
  AddAttrArray(tocs, Result.attr);
  if not IsNoNamed(attr) then
   begin
    Result.Name := tocs[0];
    IsNamed(attr, Result.Name);
   end;
end;

class function TheaderFileParser.DataStructFactory(attr: TTypedArray; const tip: TStructTypedef;
  const tocs: Tarray<string>): TDataStruct;
begin
  if IsNoNamed(attr) then Result := TDataStruct.Create(7)
  else if IsStructName(attr) then Result := TDataStruct.Create(9)
  else
   begin
    Result := TDataStruct.Create(8);
    Result.Name := tocs[0];
    // не структура а переменная
    IsNamed(attr, Result.Name);
   end;
  Result.attr := attr;
  Result.Index := tip.Index;
  AddAttrArray(tocs, Result.attr);
end;

class function TheaderFileParser.StructFactory(attr: TTypedArray; const data: TTypedArray): TStructTypedef;
   var nam: string;
begin
  Result := TStructTypedef.Create(1);
  Result.Attr := attr;
  Result.SubData := data;
  Result.Index := Index;
  Inc(Index);
  if IsNamedStruct(attr, nam) then Result.Name := nam;
end;


class procedure TheaderFileParser.Parse(const ss: TStrings);
 var
  CurrenAttrs: TTypedArray;
  CurrenStrucAttrs: TTypedArray;
  CurrenStructItems: TTypedArray;
  function CheckIncCol: boolean;
  begin
    inc(col);
    Result := col < Length(TokRow);
  end;
  function CheckIncRow: boolean;
  begin
    inc(Row);
    Result := Row < Length(tokens);
    if Result then
     begin
      TokRow := tokens[row];
      col := -1;
     end;
  end;
  function GetTokens(n: integer = 100; rowonly: boolean = true): boolean;
  begin
    Result := True;
    for var j := 0 to n-1 do
     begin
      if not CheckIncCol then
       if rowonly then exit(false)
       else if CheckIncRow then exit(false);
      CurTok[j] := TokRow[col];
     end;
  end;
 function ExtractTokens(const ToTocken: string): TArray<string>;
  begin
   Result := [];
   repeat
    while CheckIncCol do
     if TokRow[col] = '/*' then ExtractTokens('*/')
     else if TokRow[col] = ToTocken then Exit
     else Result := Result + [TokRow[col]];
//    Result := Result + [#$D#$A];
   until not CheckIncRow;
  end;
begin
  SetLength(tokens, 0);
  for var s in ss do
   begin
     var sc := s;
     var sub := '';
     // remove comments
     var ci := sc.IndexOf('//');
     if (ci >=0) and not sc.Contains('//-') then
      begin
       sc := sc.Remove(ci);
      end;
     // save string
     if sc.Contains('"') then
      begin
       var si := sc.IndexOf('"');
       var li := sc.LastIndexOf('"');
       sub := sc.Substring(si,li-si+1);
       sc := sc.Replace(sub, '_SUB1_');
       sub := sub.Replace('"','');
       if sub.Contains('__DATE__') then sub := sub.Replace('__DATE__', DateToStr(Now));
       if sub.Contains('__TIME__') then sub := sub.Replace('__TIME__', TimeToStr(Now));
      end;

     sc := sc.Replace('#', ' # ')
                .Replace(';', ' ; ')
                .Replace('//-', ' //- ')
                .Replace('/*', ' /* ')
                .Replace('*/', ' */ ')
                .Replace('=', ' = ')
                .Replace('[', ' [ ')
                .Replace(']', ' ] ');
     var a := sc.Split([' ', #9],TStringSplitOptions.ExcludeEmpty);

     //restore string
     if sub <>'' then for var i := 0 to High(a) do if a[i] = '_SUB1_' then
      begin
       a[i] := sub;
      end;
     tokens := tokens + [a];
   end;

   FlagStruct := False;
   row := -1;
   while row < Length(tokens) do
    begin
     if not CheckIncRow then Exit;
     while col < Length(TokRow) do
      begin
       if not CheckIncCol then break;
       token := TokRow[col];
       // поддерживаем  простые дефайны 10,16чные числа
       if token = '#' then
        begin
         if not GetTokens(3) then break;
         if CurTok[0] = 'define' then FDefines.AddOrSetValue(CurTok[1], CurTok[2]);
         Break;
        end
       // поддерживаем  многострочные коментарии
       else if token = '/*' then  ExtractTokens('*/')
       // добавляем атрибуты
       else if token = '//-' then
        begin
         GetTokens();
         CurrenAttrs := CurrenAttrs + [AttrFactory(CurTok)];
         Break;
        end
       // добавляем данные структуры
       else if FlagStruct then
        begin
         var dt: TTyped;
         dt := nil;
       // создаем данные стандартного типа...
         for var a in STD_TYPES do if a.Name = token then
          begin
            dt := DataTypeFactory(CurrenAttrs, a.Tip, ExtractTokens(';'));
            break;
          end;
         var dct: TStructTypedef;
       // ...или создаем данные структурного типа
         if not Assigned(dt) and FStructTypes.TryGetValue(token, dct) then
          begin
            dt := DataStructFactory(CurrenAttrs, dct, ExtractTokens(';'));
          end;
       // добавляем данные структуры....
         if Assigned(dt) then
          begin
           CurrenStructItems := CurrenStructItems + [dt];
           CurrenAttrs := [];
          end
       // ...или проверяем окончание структуры....
         else if token = '}' then
          begin
           GetTokens(1);

           FStructTypes.Add(CurTok[0], StructFactory(CurrenStrucAttrs, CurrenStructItems));
           CurrenStrucAttrs:= [];
           CurrenStructItems:= [];
           CurrenAttrs := [];
           FlagStruct := False;
          end
          else
       // ...или ошибка структуры
          begin
            RaiseException('ошибка структуры');
          end;
        end
       // начинаем добавлять структурy
       else if token = 'typedef' then
        begin
         if not GetTokens(1) then break;
         if (CurTok[0] = 'struct') then
          begin
           ExtractTokens('{');
           CurrenStrucAttrs := CurrenAttrs;
           CurrenAttrs := [];
           FlagStruct := True;
          end;
        end
      end;
    end;
end;


class procedure TheaderFileParser.RaiseException(const message: string);
begin
  raise Exception.Createfmt('%s'+#$D#$A+'tok:%d row:%d toc: %s %s %s %s %s %s', [message,col,row,
  token, CurTok[0], CurTok[1], CurTok[2], CurTok[3], CurTok[4]]);
end;

class function TheaderFileParser.GetMetaData: TBytes;
 var
  len : Integer;
begin
  Result := [0,0];
  len := 0;
  for var I := 0 to FStructTypes.Count-1 do
  for var s in FStructTypes.Values do if s.Index = i then
   begin
     Result := Result + s.ToBytes;
     Inc(len,s.SizeOf);
     Break;
   end;
   PWord(Result)^ := len+2;
end;


end.

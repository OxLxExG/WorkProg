unit MetaData2.XCParser;

interface


uses sysutils, Classes,  System.TypInfo, MetaData2.XClasses, Xml.XMLIntf, Xml.XMLDoc,Xml.xmldom,
     System.Generics.Collections, debug_except;

 type
  TAttrVal = record
   atr: TypedInfo;
   val: string;
   constructor Create(atr: TypedInfo; const val: string);
  end;
  TAttrValArray=TArray<TAttrVal>;

  TheaderFileXParser = class
  private
   class var Root: IXMLNode;
   class var row, col: integer;
   class var token: string;
   class var TokRow: TArray<string>;
   class var CurTok: array[0..100] of string;

   class var Index: Byte;
   class var FDefines: TDictionary<string, string>;
   class var FStructTypes: TDictionary<string, TXStructDef>;
   class var tokens: TArray<TArray<string>>;
   class constructor Create;
   class destructor Destroy;
   // factorys
   class function AttrFactory(const tocs: array of string): TAttrVal;
   class function DataTypeFactory(root: IXMLNode; attr: TAttrValArray; d: TypedInfo; const tocs: Tarray<string>): TXDataValue;
   class function DataStructFactory(root: IXMLNode; attr: TAttrValArray; d: TypedInfo; ds: TXStructDef; const tocs: Tarray<string>): TXDataValue;
   class function StructFactory([Ref] attr: TAttrValArray; s: TypedInfo): TXStructDef;
   // tools
   class function indexOf(const attr: TAttrValArray; const AttrName: string): Integer;
   class function AddAttrArray(const tocs: Tarray<string>; var arrs: TAttrValArray): Boolean;
   // check defines
   class function GetValue(const s: string): string; static;
   //exceptions
   class procedure RaiseException(const message: string);
  public
   class var XDoc: IXMLDocument;
   class procedure Parse(const ss: TStrings);
   class function GetMetaData: TBytes;
  end;




implementation

{ TAttrVal }

constructor TAttrVal.Create(atr: TypedInfo; const val: string);
begin
  Self.atr := atr;
  Self.val := val;
end;

{ TheaderFileParser }

class constructor TheaderFileXParser.Create;
begin
  Index := 0;
  XDoc := XTypedDocument();
  Root := XDoc.AddChild('root');
  FDefines := TDictionary<string, string>.Create();
  FStructTypes := TDictionary<string,TXStructDef>.Create();
end;

class destructor TheaderFileXParser.Destroy;
begin
  FDefines.Free;
  FStructTypes.Free;
end;

class function TheaderFileXParser.DataStructFactory(root: IXMLNode; attr: TAttrValArray; d: TypedInfo; ds: TXStructDef;
  const tocs: Tarray<string>): TXDataValue;
begin

  if indexOf(attr, 'noname') > -1 then d.Tip := REC_DAT_NONAM
  else if indexOf(attr, 'structname') > -1 then
   begin
    d.Tip := REC_DAT_SNAM;
    if not ds.Intf.HasAttribute('name') then
     RaiseException(
      Format('ƒанные [%1:s %0:s] c атрибутом <//-structname> , A ” структуры [%1:s] нет имени',[tocs[0],ds.Intf.Attributes['tname']]));
   end
  else d.Tip := REC_DAT_NAM;

  Result := DataTypeFactory(root, attr, d, tocs);
  Result.Intf.Attributes['index'] := ds.Intf.Attributes['index'];
  Result.Intf.Attributes['tname'] := ds.Intf.Attributes['tname'];
end;

class function TheaderFileXParser.DataTypeFactory(root: IXMLNode; attr: TAttrValArray; d: TypedInfo;
  const tocs: Tarray<string>): TXDataValue;
 var
  node: IXMLNode;
begin
  AddAttrArray(tocs, attr);
  node := root.AddChild(d.Name);
  Result := node as TXDataValue;
  if (indexOf(attr, 'noname') = -1) then
   begin
    if (indexOf(attr, 'structname') = -1) then
     if indexOf(attr, 'name') = -1 then attr := attr + [TAttrVal.Create(ATR_name, tocs[0])];
   end
  else if d.Tip.isData then Inc(d.Tip);
 Result.TipInfo := d;
 for var a in attr do TXAttr.Factory(node, a.atr, a.val);
end;

class function TheaderFileXParser.StructFactory( [Ref] attr: TAttrValArray; s: TypedInfo): TXStructDef;
 var
  node: IXMLNode;
begin
  node := Root.AddChild(s.Name);
  Result := node as TXStructDef;
  Result.TipInfo := s;
  node.Attributes['index'] := Index;
  Inc(Index);
  for var a in attr do TXAttr.Factory(node, a.atr, GetValue(a.val));
end;

class function TheaderFileXParser.indexOf(const attr: TAttrValArray; const AttrName: string): Integer;
begin
  for var i := 0 to High(attr) do if attr[i].atr.Name = AttrName then Exit(i);
  Result:= -1;
end;

class function TheaderFileXParser.GetValue(const s: string): string;
 var
  v: string;
begin
  Result := s;
  while FDefines.TryGetValue(Result, v) do Result := v;
end;

class function TheaderFileXParser.AddAttrArray(const tocs: Tarray<string>; var arrs: TAttrValArray): Boolean;
begin
  Result := False;
  if (Length(tocs) >=4) and (tocs[1] ='[') and  (tocs[3] =']') then
   begin
     for var a in ATR_TYPES do if a.Name = 'array' then
      begin
       arrs := arrs + [TAttrVal.Create(a, GetValue(tocs[2]))];
       Exit(True);
      end;
   end;
end;

class function TheaderFileXParser.AttrFactory(const tocs: array of string): TAttrVal;
begin
   for var a in ATR_TYPES do if a.Name = tocs[0] then
   begin
    Result.atr := a;
//    if (a.cls = TNone) or (a.cls = TattrNoname) or (a.cls = TattrStructName) then Result.val := ''
//    else
    Result.val := GetValue(tocs[2]);
    Exit;
   end;
  RaiseException(Format('атрибут с именем(%s) не найден', [tocs[0]]));
end;

class procedure TheaderFileXParser.Parse(const ss: TStrings);
 var
  CurrenAttrs: TArray<TAttrVal>;
  CurrentStruct: TXStructDef;
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

   CurrentStruct := nil;
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
       // добавл€ем атрибуты
       else if token = '//-' then
        begin
         GetTokens();
         CurrenAttrs := CurrenAttrs + [AttrFactory(CurTok)];
         Break;
        end
       // добавл€ем данные структуры
       else if Assigned(CurrentStruct) then
        begin
         var dt: IXMLNode;
         dt := nil;
       // создаем данные стандартного типа...
         for var d in STD_TYPES do if d.Name = token then
           dt := DataTypeFactory(CurrentStruct, CurrenAttrs, d, ExtractTokens(';'));
       // ...или создаем данные структурного типа
         var sd: TXStructDef;
         if not Assigned(dt) and FStructTypes.TryGetValue(token, sd) then
          begin
           dt := DataStructFactory(CurrentStruct, CurrenAttrs, STR_struct,  sd, ExtractTokens(';'));
          end;
       // добавл€ем данные структуры (сбрасываем атрибуты)....
         if Assigned(dt) then
          begin
           CurrenAttrs := [];
          end
       // ...или провер€ем окончание структуры....
         else if token = '}' then
          begin
           GetTokens(1);
           CurrentStruct.Intf.Attributes['tname'] := CurTok[0];
           FStructTypes.Add(CurTok[0], CurrentStruct);
           CurrenAttrs := [];
           CurrentStruct := nil;
          end
          else
       // ...или ошибка структуры
          begin
            RaiseException('ошибка структуры');
          end;
        end
       // начинаем добавл€ть структурy
       else if token = 'typedef' then
        begin
         if not GetTokens(1) then break;
         if (CurTok[0] = 'struct') then
          begin
           ExtractTokens('{');
           CurrentStruct := StructFactory(CurrenAttrs, STR_struct_t);
           CurrenAttrs := [];
          end;
        end
      end;
    end;
end;


class procedure TheaderFileXParser.RaiseException(const message: string);
begin
  raise Exception.Createfmt('%s'+#$D#$A+'tok:%d row:%d toc: %s %s %s %s %s %s', [message,col,row,
  token, CurTok[0], CurTok[1], CurTok[2], CurTok[3], CurTok[4]]);
end;

class function TheaderFileXParser.GetMetaData: TBytes;
 var
  len : Integer;
begin
  Result := [0,0];
  len := 0;
  for var I := 0 to Root.ChildNodes.Count-1 do
   begin
     var xt := Root.ChildNodes[i] as TXTyped;
     Result := Result + xt.ToBytes;
     Inc(len, xt.SizeOf);
   end;
   len := len+2;
   if Byte(len) = 36 then raise Exception.Create('length mact not eq <> 0x??24');
   PWord(Result)^ := len;
end;


end.

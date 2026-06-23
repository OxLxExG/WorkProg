unit ExportMetaData;

interface

uses System.SysUtils, Xml.XMLIntf ,System.Classes, tools, Xml.XMLDoc, FileDataSet, XMLDataSet, DataSetIntf;

procedure ExportMetaDataToTxt(const fileName: string; root: IXMLNode; TimeStart: TDateTime);

implementation


///
///  потдерживаемые типы данных
///
type ConvType = record
 Name: string;
 tip: Integer;
end;
const ConvTypes: array [0..11] of ConvType = (
 (    Name: 'uint8_t';    Tip: varByte ),
 (    Name: 'int8_t';     Tip: varShortInt ),
 (    Name: 'char';     Tip: varOleStr ),

 (    Name: 'uint16_t';    Tip: varWord ),
 (    Name: 'int16_t';     Tip: varSmallint ),

 (    Name: 'uint32_t';    Tip: varUInt32 ),
 (    Name: 'int32_t';     Tip: varInteger ),
 (    Name: 'float';       Tip: varSingle ),

 (    Name: 'uint64_t';   Tip: varUInt64 ),
 (    Name: 'int64_t';    Tip: varInt64 ),
 (    Name: 'double';     Tip: varDouble ),

 (    Name: 'string';     Tip:  varString)
);

function GetTip(inp: Integer): string;
begin
  for var stdt in ConvTypes do if stdt.tip = inp then Exit(stdt.Name);
  raise Exception.CreateFmt(' function GetTip(inp: Integer): string; Error type %d', [inp]);
end;

function getMnem(devNode, root: IXMLNode): string;
begin
  var n := devNode.ParentNode;
  Result := n.NodeName;
  n := n.ParentNode;
  while Assigned(n) and (root <> n) do
   begin
    Result := n.NodeName +'_' + Result;
    n := n.ParentNode;
   end;
end;

//function getMnemCLC(devNode, root: IXMLNode): string;
//begin
//  var n := devNode.ParentNode;
//  Result := n.NodeName;
//  n := n.ParentNode;
//  while Assigned(n) and (root <> n) do
//   begin
//    Result := n.NodeName +'_' + Result;
//    n := n.ParentNode;
//   end;
//end;

function isMnem(DevNode, mnem: IXMLNode): Boolean;
begin
  var apath := string(mnem.NodeValue).Split(['.']);
  var n := DevNode.ParentNode;
  for var i := High(apath) downto 0 do
   begin
    if n.NodeName <> apath[i] then Exit(False);
    n := n.ParentNode;
   end;
  Result := True;
end;

function AddMd(devNode:IXMLNode; const mnem: string; Offset: Integer = -1): string;
 var
  Res: array [0..12] of string;
begin
// формат метаданных: mnem,type,ofset,array_size,uom,title,digits,presi,Rlo,Rhi,color,width,dash
  Res[0] := mnem;
  Res[1] := GetTip(Integer(devNode.Attributes[AT_TIP]));
  if Offset >= 0 then Res[2] := Offset.ToString
  else Res[2] := devNode.Attributes[AT_INDEX];
  if devNode.ParentNode.HasAttribute(AT_ARRAY) then
                                      Res[3] := devNode.ParentNode.Attributes[AT_ARRAY];
  if devNode.HasAttribute(AT_EU) then Res[4] := devNode.Attributes[AT_EU];
  if devNode.HasAttribute(AT_TITLE) then Res[5] := devNode.Attributes[AT_TITLE];
  if devNode.HasAttribute(AT_DIGITS) then Res[6] := devNode.Attributes[AT_DIGITS];
  if devNode.HasAttribute(AT_AQURICY) then Res[7] := devNode.Attributes[AT_AQURICY];
  if devNode.HasAttribute(AT_RLO) then Res[8] := devNode.Attributes[AT_RLO];
  if devNode.HasAttribute(AT_RHI) then Res[9] := devNode.Attributes[AT_RHI];
  if devNode.HasAttribute(AT_COLOR) then Res[10] := IntToHex(Cardinal(devNode.Attributes[AT_COLOR]));
  if devNode.HasAttribute(AT_WIDTH) then Res[11] := devNode.Attributes[AT_WIDTH];
  if devNode.HasAttribute(AT_DASH) then Res[12] := devNode.Attributes[AT_DASH];
  Result := string.Join(';', Res);
end;

procedure ExportMetaDataToTxt(const fileName: string; root: IXMLNode; TimeStart: TDateTime);
 var
  xd: TXMLDataSet;
  FIDataSet: IDataSet;
begin
  if FileExists(fileName) then Exit;
  with TstringList.Create do
  try
   for var a in XEnumAttr(root.ParentNode) do if a.NodeName <> AT_SIZE then Add(a.NodeName + '=' + a.NodeValue);
   Add('TIME_START='+ DateTimeToStr(TimeStart));
   Add('### DEV');
   var xdoc := NewXMLDocument();
   xdoc.LoadFromFile(ExtractFilePath(ParamStr(0))+'Devices\ExpMetaData.xml');

   ExecXTree(root, procedure (n: IXMLNode)
   begin
    if n.HasAttribute(AT_TIP) and n.HasAttribute(AT_INDEX) then
     begin
      for var mnem in Xenum(xdoc.DocumentElement) do if (mnem.NodeType = ntElement) and isMnem(n,mnem) then
       begin
        Add(AddMd(n, mnem.NodeName));
        Exit;
       end;
       Add(AddMd(n, getMnem(n, root)));
     end;
   end);

   Add('### CLC');
   try
     TXMLDataSet.Get(root, FIDataSet);
     var xs := TXMLDataSet(FIDataSet.DataSet).XMLSection;
     xd := TXMLDataSet(FIDataSet.DataSet);
     for var i := 0 to xd.FieldDefList.Count-1 do
       begin
        var f := TFileFieldDef(xd.FieldDefList[i]);
        if f.CalcField then
         begin
          var n: IxmlNode := nil;
          if xd.TryGetX(f.GetPath, n) then
           begin
             Add(AddMd(n, getMnem(n, xs), f.DataOffset));
           end;
         end;
       end;
   finally
     SaveToFile(fileName);
   end;
  finally
   Free;
  end;
end;

end.

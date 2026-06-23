unit MetaData2.XBParser;

interface

uses
  sysutils, Classes, Rtti, MetaData2.XClasses, Xml.XMLIntf, Xml.XMLDoc,
  Xml.xmldom, debug_except, tools, System.Variants;

type
// ThackAttr = record
//  atr: TypedInfo;
//  pdata: Pointer;
// end;
//
  TBinaryXParser = class
  private
    class var
      Index: Byte;
    class var
      IndexUnk: Integer;
  //   Глобальные указатель и счетчик
    class var
      Gptr: PByte;
    class var
      Availlen: Integer;
    class var
      StructLen: Integer;
    class var
      locallen: Integer;
    class var
      localcnt: Integer;
    class var
      localOffset: Integer;
    class constructor Create;
    class function ParseStr: string;
    class procedure ParseAttrs(r: IXMLNode);
    class procedure ParseData(r: IXMLNode);
    class function CreateUnknown(t: TmetadataType): TypedInfo;
    class procedure Next(n: Integer = 1);
    class procedure CheckAddRootAttr(node, root: IXMLNode);
    class function FactoryStruct(t: TmetadataType): TXStructDef;
    class function FactoryData(t: TmetadataType; r: IXMLNode): TXDataValue;
    class procedure FactoryStructData(t: TmetadataType; r: IXMLNode);
    class function FindStructDef(Index: Integer): TXStructDef;
  public
  // HackAttr = 'serial' HackAdr для устновки серийного номера в метадата прибора
    class var
      HackAttr: string;
    class var
      HackAdr: Pointer;
    class var
      Root: IXMLNode;
    class var
      XDoc: IXMLDocument;
    class procedure Parse(ptr: Pointer);
    class procedure Save(const FileName: string);
    class function ExportTo(root: IXMLNode): IXMLNode;
  end;

implementation

uses
  MetaData2.to1;

{ TBinaryToXMLParser }

class function TBinaryXParser.ParseStr: string;
begin
  Result := string(PAnsiChar(Gptr));
  locallen := Length(Result) + 1;
  Next(locallen);
end;

class function TBinaryXParser.ExportTo(root: IXMLNode): IXMLNode;
var
  d: IXData;
  globalOffset: Integer;
begin
  for var i := 0 to XDoc.DocumentElement.ChildNodes.Count - 1 do
  begin
    var nr := XDoc.DocumentElement.ChildNodes[i];
    if nr.HasAttribute('export') then
    begin
      var idx := root.ChildNodes.Add(nr.CloneNode(true));
      Result := root.ChildNodes[idx];
      Result.AttributeNodes.Delete('export');
      Result.AttributeNodes.Delete('size');
      globalOffset := -1;
      ExecXTree(Result,
        procedure(n: IXMLNode)
        begin
          if n.NodeName = 'struct_t' then
          begin
            n.AttributeNodes.Delete('index');
            n.AttributeNodes.Delete('tip');
            if n.HasAttribute('WRK') or n.HasAttribute('RAM') or n.HasAttribute('EEP') or n.HasAttribute('profile')  then
              globalOffset := 0;
            if n.HasAttribute('size') then
              n.Attributes['global'] := globalOffset;
         // expand struct ra attributtes
            for var i := 0 to n.AttributeNodes.Count - 1 do
            begin
              var at := n.AttributeNodes[i];
              for var a in ATR_TYPES do
                if a.ra and (at.NodeName = a.Name) then
                  for var j := 0 to n.ChildNodes.Count - 1 do
                  begin
                    var dev := n.ChildNodes[j];
                    if dev.HasAttribute(at.NodeName) then
                      Continue;

                    if at.NodeValue = System.Variants.Null then
                      dev.Attributes[at.NodeName] := True
                    else
                      dev.Attributes[at.NodeName] := at.NodeValue;
                  end;
            end;
          end
          else if Supports(n, IXData, d) then
          begin
            d.Attributes['global'] := globalOffset;
            inc(globalOffset, d.DataSizeOf);
          end;
        end);

      Exit;
    end;
  end;
end;

class procedure TBinaryXParser.Save(const FileName: string);
var
  xd: IXMLDocument;
  d: IXData;
  globalOffset: Integer;
begin
   // XDoc.DocumentElement.AddChild('я,я');
  for var i := 0 to XDoc.DocumentElement.ChildNodes.Count - 1 do
  begin
    var n := XDoc.DocumentElement.ChildNodes[i];
    if n.HasAttribute('export') then
    begin
      xd := XTypedDocument();
      var ss := xd.CreateNode('xml-stylesheet', ntProcessingInstr, 'type="text/xsl" href="meta.xsl"');
      xd.Node.ChildNodes.Add(ss);

      xd.DocumentElement := n.CloneNode(true);
      xd.DocumentElement.AttributeNodes.Delete('export');
      xd.DocumentElement.AttributeNodes.Delete('size');
      globalOffset := -1;
      ExecXTree(xd.DocumentElement,
        procedure(n: IXMLNode)
        begin
          if n.NodeName = 'struct_t' then
          begin
            n.AttributeNodes.Delete('index');
            n.AttributeNodes.Delete('tip');
            if n.HasAttribute('WRK') or n.HasAttribute('RAM') or n.HasAttribute('EEP') or n.HasAttribute('profile') then
              globalOffset := 0;
            if n.HasAttribute('size') then
              n.Attributes['global'] := globalOffset;
          end
          else if Supports(n, IXData, d) then
          begin
            d.Attributes['global'] := globalOffset;
            inc(globalOffset, d.DataSizeOf);
          end;
        end);
      xd.SaveToFile(FileName);
      //////
//      var xdt := NewXMLDocument();
//      var outp := xdt.AddChild('PROJECT').AddChild('DEVICES');
//      MetaData2To1(xd.DocumentElement,outp);
//      xdt.SaveToFile('C:\XE\Projects\Device2\CreateMetaData\MetaDataPstd.xml');
     ////
      Exit;
    end;
  end;
end;

class procedure TBinaryXParser.ParseAttrs(r: IXMLNode);
var
  t: TmetadataType;
  ta: TXAttr;
begin
  ta := nil;
  while StructLen > 0 do
  begin
    t := Gptr^;
    if not t.isAttr then
      Break;
    Next;
    for var a in ATR_TYPES do
      if a.Tip = t then
      begin
        if a.Name = HackAttr then
          HackAdr := Gptr;
        ta := TXAttr.Factory(r, a, Gptr);
        Break;
      end;
    if not Assigned(ta) then
      ta := TXAttr.Factory(r, CreateUnknown(t), Gptr);
    locallen := ta.SizeOf;
    Next(locallen - 1);
  end;
end;

class procedure TBinaryXParser.ParseData(r: IXMLNode);
var
  t: TmetadataType;
begin
  while StructLen > 0 do
  begin
    t := Gptr^;
    if t.isStructData then
      FactoryStructData(t, r)
    else if t.isData then
      FactoryData(t, r)
    else
      raise Exception.Create('Error ParseData');
  end;
end;

class function TBinaryXParser.CreateUnknown(t: TmetadataType): TypedInfo;
begin
  Result.Name := 'unk' + IndexUnk.ToString;
  Inc(IndexUnk);
  Result.Tip := t;
  case t.Length of
    -2:
      Result.cls := TStr;
    0:
      Result.cls := TNone;
    1:
      Result.cls := TUint8;
    2:
      Result.cls := TUint16;
    4:
      Result.cls := TUint32;
    8:
      Result.cls := TUint64;
  end;
end;

class procedure TBinaryXParser.CheckAddRootAttr(node, root: IXMLNode);
var
  a: IXAttr;
begin
  for var i := 0 to root.AttributeNodes.Count - 1 do
    if Supports(root.AttributeNodes[i], IXAttr, a) then
      if a.TipInfo.ra and not node.HasAttribute(a.NodeName) then
        node.Attributes[a.NodeName] := a.NodeValue;
end;

class constructor TBinaryXParser.Create;
begin
  HackAttr := 'serial';
end;

class function TBinaryXParser.FactoryData(t: TmetadataType; r: IXMLNode): TXDataValue;
var
  node: IXMLNode;

  function CreDv(d: TypedInfo): TXDataValue;
  begin
    node := r.AddChild(d.Name);
    node.NodeValue := '0';
    Result := node as TXDataValue;
    d.Tip := t;
    Result.TipInfo := d;
//    (Result as IXValue).Assign('0');
  end;

begin
  Result := nil;
  for var d in STD_TYPES do
    if d.Tip = (t and $FE) then
    begin
      Result := CreDv(d);
      Break;
    end;
  if not Assigned(Result) then
    Result := CreDv(CreateUnknown(t));
  Next;
  if t.isNamed then
    node.Attributes['name'] := ParseStr;
  ParseAttrs(node);
  CheckAddRootAttr(node, r);
  node.Attributes['offset'] := localOffset;
  Inc(localOffset, Result.DataSizeOf);
end;

class procedure TBinaryXParser.FactoryStructData(t: TmetadataType; r: IXMLNode);
var
  node: IXData;
begin
  Next;
  //поиск по индексу реальной структуры
  var sd := FindStructDef(Gptr^);
  node := sd.Intf.CloneNode(True) as IXData;
  node.TipInfo := sd.TipInfo;
  Next;
  if t.isNamed then
    node.Attributes['name'] := ParseStr;
  ParseAttrs(node);
//  CheckAddRootAttr(node, sd.Intf);
  CheckAddRootAttr(node, r);
  if (t = REC_DAT_NONAM) and node.HasAttribute('name') then
    node.AttributeNodes.Delete('name');
  if node.HasAttribute('WRK') or node.HasAttribute('RAM') or node.HasAttribute('EEP') or node.HasAttribute('profile')   then
    localOffset := 0;

  {$REGION 'expand struct data arrays'}
  //если массив структур то просто клонируем структуры добавляем атрибут 'arrayIdx' начинаем с 1
  if node.HasAttribute('array') then
  begin
    var l := Integer(node.Attributes['array']);
    node.AttributeNodes.Delete('array');
    for var i := 1 to l do
    begin
      var cn := node.CloneNode(True);
      (cn as IXData).TipInfo := sd.TipInfo;
      r.ChildNodes.Insert(r.ChildNodes.Count, cn);
      cn.Attributes['arrayIdx'] := i;
      cn.Attributes['offset'] := localOffset;
      Inc(localOffset, Integer(cn.Attributes['size']));
    end;
  end
  {$ENDREGION}
  else
  begin
    node.Attributes['offset'] := localOffset;
    Inc(localOffset, Integer(node.Attributes['size']));
    r.ChildNodes.Add(node);
  end;
end;

class function TBinaryXParser.FindStructDef(Index: Integer): TXStructDef;
begin
  for var i := 0 to root.ChildNodes.Count - 1 do
    if root.ChildNodes[i].Attributes['index'] = Index then
      Exit(root.ChildNodes[i] as TXStructDef);
  Result := nil;
end;

class procedure TBinaryXParser.Next(n: Integer);
begin
  Inc(gptr, n);
  Dec(Availlen, n);
  Dec(StructLen, n);
  inc(localcnt, n);
  if (availLen < 0) or (StructLen < 0) then
    raise Exception.Create('availLen <> 0 Error Message');
end;

class function TBinaryXParser.FactoryStruct(t: TmetadataType): TXStructDef;
var
  node: IXMLNode;
begin
  Result := nil;
  for var s in STR_TYPES do
    if s.Tip = t then
    begin
      node := root.AddChild(s.Name);
      Result := node as TXStructDef;
      Result.TipInfo := s;
      node.Attributes['index'] := Index;
      Inc(Index);
      localcnt := 0;
      localOffset := 0;
      StructLen := 1;
      Next();
      StructLen := 0;
      Move(gptr^, StructLen, t.Length);
      Dec(StructLen);
      Next(t.Length);
      if t.isNamed then
        node.Attributes['name'] := ParseStr;
      ParseAttrs(node);
      ParseData(node);
      node.Attributes['size'] := Result.DataSizeOf;
      Exit;
    end;
end;

class procedure TBinaryXParser.Parse(ptr: Pointer);
var
  t: TmetadataType;
begin
  Index := 0;
  XDoc := XTypedDocument();
  root := XDoc.AddChild('root');
  Gptr := ptr;
  Availlen := Pword(Gptr)^;
  Inc(Gptr, 2);
  Dec(Availlen, 2);
  while Availlen > 0 do
  begin
    t := Gptr^;
    if t.isStrucDef then
      FactoryStruct(t)
    else
      raise Exception.Create('Error Parse');
  end;
end;

end.


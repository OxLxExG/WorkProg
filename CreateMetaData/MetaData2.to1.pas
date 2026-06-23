unit MetaData2.to1;

interface

uses sysutils, Variants, Classes, MetaData2.XClasses, Xml.XMLIntf, Xml.XMLDoc, debug_except, tools;

function MetaData2To1(inp, outp: IXMLNode):IXMLNode;

type TnewPars =class
 public
    class function SetInfo(node: IXMLNode; Info: PByte; InfoLen: integer): IXMLNode;
    class function PatchProfile(node: IXMLNode; idx: Integer): IXMLNode;
end;


implementation

uses MetaData2.XBParser;

type ConvAttr = record
 new: string;
 old: string;
end;

const ConvAttrs: array [0..23] of ConvAttr = (
(new:  'adr';               old: AT_ADDR),
(new:  'chip';              old: AT_CHIP),
(new:  'from';              old: AT_FROM),
(new:  'info';              old: AT_INFO),
(new:  'password';          old: AT_PSWD),
(new:  'serial';            old: AT_SERIAL),
(new:  'SupportUartSpeed';  old: AT_SPEED),
(new:  'NoPowerDataCount';  old: AT_EXT_NP),
(new:  'size';              old: AT_SIZE),
(new:  'array';             old: AT_ARRAY),
(new:  'metr';              old: AT_METR),
(new:  'global';            old: AT_INDEX),
(new:  'tip';               old: AT_TIP),
(new:  'eu';                old: AT_EU),
(new:  'RangeLo';           old: AT_RLO),
(new:  'RangeHi';           old: AT_RHI),
(new:  'digits';            old: AT_DIGITS),
(new:  'precision';         old: AT_AQURICY),
(new:  'color';             old: AT_COLOR),
(new:  'width';             old: AT_WIDTH),
(new:  'style';             old: AT_DASH),
(new:  'title';             old: AT_TITLE),
(new:  'RamSize';           old: AT_RAMSIZE),
(new:  'SSDSize';           old: AT_SSD)
);

type ConvType = record
 Name: string;
 tip: Integer;
end;
const ConvTypes: array [0..10] of ConvType = (
 (    Name: 'uint8_t';    Tip: varByte ),
 (    Name: 'char';       Tip: varOleStr ),
 (    Name: 'int8_t';     Tip: varShortInt ),

 (    Name: 'uint16_t';    Tip: varWord ),
 (    Name: 'int16_t';     Tip: varSmallint ),

 (    Name: 'uint32_t';    Tip: varUInt32 ),
 (    Name: 'int32_t';     Tip: varInteger ),
 (    Name: 'float';       Tip: varSingle ),

 (    Name: 'uint64_t';   Tip: varUInt64 ),
 (    Name: 'int64_t';    Tip: varInt64 ),
 (    Name: 'double';     Tip: varDouble )
);

 function GetTip(const inp: string{; tip: TmetadataType}): Integer;
 begin
   for var stdt in ConvTypes do if stdt.Name = inp then Exit(stdt.tip);
   { TODO : decode from tip as default type}
   raise Exception.CreateFmt(' function GetTip(inp: IXMLNode): Integer Error type %s',[inp]);
 end;

 function GetAttrName(inp: IXMLNode): string;
 begin
   for var stdn in ConvAttrs do if stdn.new = inp.NodeName then Exit(stdn.old);
   Result := inp.NodeName;
 end;

var
 nonamecount: Integer = 1;
 function GetNodeName(inp: IXMLNode): string;
 begin
   if inp.HasAttribute('name') then
    begin
     Result := inp.Attributes['name'];
     if inp.HasAttribute('arrayIdx') then  Result := Result + inp.Attributes['arrayIdx'];
     { TODO : generate ole name }
    end
   else if inp.HasAttribute('WRK') then Result := 'WRK'
   else if inp.HasAttribute('RAM') then Result := 'RAM'
   else if inp.HasAttribute('EEP') then Result := 'EEP'
   else
    begin
     Result := 'noname'+nonamecount.ToString;
     Inc(nonamecount);
    end;
 end;

procedure ExecX(inp, outp: IXMLNode; proc: TFunc<IXMLNode,IXMLNode,IXMLNode>);
  procedure rec(r,parent: IXMLNode);
  begin
    var orn := proc(r, parent);
    for var n in XEnum(r) do if n.NodeType = ntElement then rec(n,orn)
  end;
begin
  rec(inp, outp);
end;


function MetaData2To1(inp, outp: IXMLNode):IXMLNode;
 var
  ExtNpDataCount: Integer;
  ExtNpDataLen: Integer;
  rootNode: IXMLNode;
begin
  ExtNpDataCount := 0;
  ExtNpDataLen := 0;

  ExecX(inp, outp, function (ip, op: IXMLNode): IXMLNode
   var
    node: IXMLNode;
   procedure MoveAttr(root, dev: IXMLNode; const name: string);
   begin
     if dev.HasAttribute(name) then
      begin
       root.Attributes[name] := dev.Attributes[name];
       dev.AttributeNodes.Delete(name);
      end;
   end;
   var
   sname: string;
  begin
     sname := GetNodeName(ip);
    try
     Result := op.AddChild(sname);
    except
     raise Exception.Createfmt('Error GetNodeName [%s, %s]', [sname, ip.NodeName]);
    end;
    if ip.HasAttribute('tip') then node := Result.AddChild(T_DEV)
    else node := Result;
    for var i := 0 to ip.AttributeNodes.Count-1 do
     begin
      var at := ip.AttributeNodes[i];
      if (at.NodeName <> 'WRK')and(at.NodeName <> 'RAM')and(at.NodeName <> 'EEP')and(at.NodeName <> 'name') then
       begin
        var an := GetAttrName(at);
        if VarIsNull(at.NodeValue) then
           node.Attributes[an] := True
        else
           node.Attributes[an] := at.NodeValue;
        if an = AT_EXT_NP then
         begin
           ExtNpDataCount := at.NodeValue;
           rootNode := node;
         end;
       end;
     end;
    if node.HasAttribute(AT_SIZE) then Result.AttributeNodes.Delete(AT_INDEX);
    if node.HasAttribute(AT_INDEX) then
     begin
      MoveAttr(Result,node, 'name');
      MoveAttr(Result,node, AT_METR);
      MoveAttr(Result,node, AT_ARRAY);
      MoveAttr(Result,node, 'arrayShowLen');
      var t := GetTip(ip.NodeName);
      node.Attributes[AT_TIP] := t;
      if ExtNpDataCount > 0 then
      begin
        // array not sypport
        if t in [varByte,varOleStr, varShortInt] then Inc(ExtNpDataLen)
        else if t in [varWord,varSmallint] then Inc(ExtNpDataLen,2)
        else if t in [varUInt32,varInteger,varSingle] then Inc(ExtNpDataLen,4)
        else if t in [varUInt64,varInt64,varDouble] then Inc(ExtNpDataLen,8);
        Dec(ExtNpDataCount);
        if ExtNpDataCount = 0 then
        begin
         rootNode.Attributes[AT_EXT_NP_LEN] := ExtNpDataLen;
        end;
      end;
     end;
  end);
  Result := outp.ChildNodes.FindNode(GetNodeName(inp));
end;

{ TnewPars }


class function TnewPars.PatchProfile(node: IXMLNode; idx: Integer): IXMLNode;
begin
  result := RenameXMLNode(node, node.ChildNodes[idx].NodeName);
  var activeProfile := result.ChildNodes[idx];
  var mtr := result.ChildNodes.FindNode(T_MTR);
  result.ChildNodes.Clear;
  for var I := 0 to activeProfile.ChildNodes.Count-1 do result.ChildNodes.Add(activeProfile.ChildNodes[i]);
  if Assigned(mtr) then result.ChildNodes.Add(mtr);
end;

class function TnewPars.SetInfo(node: IXMLNode; Info: PByte; InfoLen: integer): IXMLNode;//; adr: integer = 0; ProfilesPach: TProc<integer, IXMLNode> = nil): IXMLNode;
begin
       TBinaryXParser.Parse(Info);

       var xd := XTypedDocument();
//       var ssd := xd.CreateNode('xml-stylesheet', ntProcessingInstr, 'type="text/xsl" href="meta.xsl"');
//       xd.Node.ChildNodes.Add(ssd);
       var root := xd.AddChild('PROJECT').AddChild('DEVICES');
       var rez := TBinaryXParser.ExportTo(root);
      // xd.SaveToFile('C:\Projects\MPLab\Cart.X\_I\xd.xml');
     // if Assigned(ProfilesPach) and (rez.Attributes['name'] = 'Profiles') then ProfilesPach(adr, rez);
      
    Result := MetaData2To1(rez,node);
     // node.OwnerDocument.SaveToFile('C:\Projects\MPLab\Cart.X\_I\node.xml');
end;

end.

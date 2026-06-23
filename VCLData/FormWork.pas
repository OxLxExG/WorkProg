unit FormWork;

interface


{$INCLUDE global.inc}


uses DeviceIntf, PluginAPI, ExtendIntf, RootImpl, debug_except, DockIForm, RootIntf, Container, Actns, VirtualTrees.Types,
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics, System.Bindings.Expression, Xml.XMLIntf,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, VirtualTrees, Vcl.Menus, Vcl.PlatformDefaultStyleActnCtrls, Vcl.ActnPopup, Vcl.ImgList,
  ActnCtrls, VirtualTrees.BaseAncestorVCL, VirtualTrees.BaseTree,
  VirtualTrees.AncestorVCL;

{$IFDEF ENG_VERSION}
  const
   C_CaptWorkForm ='New tree';
   C_MenuView ='Visualization windows';
   C_Memu_Show='Show';
{$ELSE}
  const
   C_CaptWorkForm ='Новое дерево';
   C_MenuView ='Окна визуализации';
   C_Memu_Show='Показать';
{$ENDIF}


type
  TNodeKind = (xkData, xkRoot, xkArray);

  PNodeExData = ^TNodeExData;
  TNodeExData = record
    XMNode: IXMLNode;
  end;

  TFormWrok = class(TCustomFontIForm, ISetDevice)
    TreeBad: TVirtualStringTree;
    ppM: TPopupActionBar;
    NShow: TMenuItem;
    Tree: TVirtualStringTree;
    procedure TreeBadGetText(Sender: TBaseVirtualTree; Node: PVirtualNode; Column: TColumnIndex; TextType: TVSTTextType; var CellText: string);
    procedure TreeGetImageIndex(Sender: TBaseVirtualTree; Node: PVirtualNode; Kind: TVTImageKind; Column: TColumnIndex; var Ghosted: Boolean; var ImageIndex: Integer);
    procedure ppMPopup(Sender: TObject);
    procedure NShowClick(Sender: TObject);
    procedure TreeBadPaintText(Sender: TBaseVirtualTree; const TargetCanvas: TCanvas; Node: PVirtualNode;
      Column: TColumnIndex; TextType: TVSTTextType);
  private
    FDataDevice: string;
    FMetaDataInfo: TInfoEventRes;
    FBindWorkRes: TWorkEventRes;
    NConnect: TMenuItem;
    FEditData: PNodeExData;
    FEditNode: PVirtualNode;
    procedure ClearTree;
    procedure SetBindWorkRes(const Value: TWorkEventRes);
    procedure SetDataDevice(const Value: string);
    function GetDataDevice: string;
    procedure NConnectClick(Sender: TObject);
    procedure SetRemoveDevice(const Value: string);
    procedure SetMetaDataInfo(const Value: TInfoEventRes);
    //Автоматический выбор
    procedure ConnectToAllDevices;
    function TryConnectFromForkData(const wd: TWorkEventRes): Boolean;
  protected
   const
    NICON = 113;
   // AUTO_DEV = 'Автоматический выбор';
    procedure DoSetFont(const AFont: TFont); override;
    procedure NCPopup(Sender: TObject); override;
    class function ClassIcon: Integer; override;
    procedure Loaded; override;
  public
    //Capt, Categ: string; AImageIndex: Integer; APaths: string; AHint: string; AAutoCheck AChecked AGroupIndex AEnabled
    [StaticAction(C_CaptWorkForm, C_MenuView, NICON, '0:'+C_Memu_Show+'.'+C_MenuView)]
    class procedure DoCreateForm(Sender: IAction); override;

    destructor Destroy; override;

    property C_BindWorkRes: TWorkEventRes read FBindWorkRes write SetBindWorkRes;
    property C_MetaDataInfo: TInfoEventRes read FMetaDataInfo write SetMetaDataInfo; //live binding
    property C_RemoveDevice: string read FDataDevice write SetRemoveDevice;
  published
    property DataDevice: string read GetDataDevice write SetDataDevice;
  end;

  resourcestring
   RS_connDEv='Подключить к устройству';
   RS_NoConn='Устройство не подключено';

implementation

{$R *.dfm}

uses AbstractPlugin, tools, VCLFormShowArray;


{ TFormWork }

class function TFormWrok.ClassIcon: Integer;
begin
  Result := NICON;
end;

procedure TFormWrok.Loaded;
 var
  ip: IImagProvider;
  d: IDevice;
  de: IDeviceEnum;
begin
  inherited;
  Tree.NodeDataSize := SizeOf(TNodeExData);
  if Supports(GlobalCore, IImagProvider, ip) then Tree.Images := ip.GetImagList;
  NConnect := AddToNCMenu(RS_connDEv);
  if Supports(GlobalCore, IDeviceEnum, de) then
   begin
    Bind('C_RemoveDevice', de, ['S_BeforeRemove']);// (de as IBind).CreateManagedBinding(Self, 'LRemoveDevice', ['S_BeforeRemove']);
    d := de.Get(FDataDevice);
    if Assigned(d) and Supports(d, IDataDevice) then C_MetaDataInfo := (d as IDataDevice).GetMetaData()
    else if FDataDevice = '' then ConnectToAllDevices
   end;
end;

procedure TFormWrok.ClearTree;
 var
  pv: PVirtualNode;
begin
  for pv in Tree.Nodes do PNodeExData(Tree.GetNodeData(pv)).XMNode := nil;
  Tree.Clear;
end;

function TFormWrok.TryConnectFromForkData(const wd: TWorkEventRes): Boolean;
begin
  DataDevice := wd.Work.ParentNode.ParentNode.NodeName;
  Result := DataDevice <> '';
end;

procedure TFormWrok.ConnectToAllDevices;
 var
  d: IDevice;
  de: IDeviceEnum;
begin
  FDataDevice := '';
  if Supports(GlobalCore, IDeviceEnum, de) then
    for d in de.Enum do
      if Supports(d, IDataDevice) then Bind('C_BindWorkRes',d, ['S_WorkEventInfo']);
end;

procedure TFormWrok.SetDataDevice(const Value: string);
 var
  d: IDevice;
  de: IDeviceEnum;
begin
  if FDataDevice = Value then Exit;
  TBindHelper.RemoveControlExpressions(Self, ['C_MetaDataInfo', 'C_BindWorkRes']);//  Bind.RemoveManagedBinding(['MetaDataInfo', 'BindWorkRes']);
  FDataDevice := Value;
  if FDataDevice <> '' then
   begin
    if Supports(GlobalCore, IDeviceEnum, de) then d := de.Get(FDataDevice);
    if Supports(d, IDataDevice) then
     begin
      Caption := (d as ICaption).Text;
      Bind('C_MetaDataInfo', d, ['S_MetaDataInfo']);// (d as IBind).CreateManagedBinding(Self, 'MetaDataInfo', ['MetaDataInfo']);
      Bind('C_BindWorkRes',d, ['S_WorkEventInfo']); //(d as IBind).CreateManagedBinding(Self, 'BindWorkRes', ['WorkEventInfo']);
      if not (csLoading in ComponentState) then C_MetaDataInfo := (d as IDataDevice).GetMetaData();
      Exit;
     end
    else FDataDevice := '';
   end
  else ConnectToAllDevices;
  Caption := RS_NoConn;
end;

procedure TFormWrok.SetRemoveDevice(const Value: string);
begin
  if DataDevice = Value then
   begin
    ClearTree;
    DataDevice := '';
   end;
end;

destructor TFormWrok.Destroy;
begin
  ClearTree;
  inherited;
end;

procedure TFormWrok.NConnectClick(Sender: TObject);
begin
  DataDevice := TMenuItem(Sender).Name;
end;

procedure TFormWrok.NCPopup(Sender: TObject);
 var
  d: IDevice;
  Item: TMenuItem;
  de: IDeviceEnum;
begin
  inherited;
  NConnect.Clear;
  if Supports(GlobalCore, IDeviceEnum, de) then for d in de.Enum do if Supports(d, IDataDevice) then
   begin
    Item := TMenuItem.Create(NConnect);
    Item.Name := (d as ImanagItem).IName;
    Item.Caption := (d as ICaption).Text;
    Item.OnClick := NConnectClick;
    if SameText(Item.Name, DataDevice) then Item.Checked := True;
    NConnect.Add(Item);
   end;
  NConnect.Visible := NConnect.Count <> 0;
end;

procedure TFormWrok.ppMPopup(Sender: TObject);
 var
  i: Integer;
  FRoot,Fvis: Boolean;
begin
  FEditNode := nil;
  FEditData := nil;
  for i := 0 to  ppM.Items.Count-1  do ppM.Items[i].Visible := False;
  if not Assigned(Tree.HotNode) then Exit;
  FEditNode := Tree.HotNode;
  FEditData := Tree.GetNodeData(FEditNode);
  TDebug.Log(FEditData.XMNode.NodeName);
  ExecXTree(FEditData.XMNode, procedure (n: IXMLNode)
  begin
    if (n.NodeName = T_WRK)or (n.NodeName = T_RAM) then FRoot := True;
    if  n.HasAttribute(AT_ARRAY) then Fvis := True;
  end);
  if Fvis and not FRoot then for i := 0 to ppM.Items.Count-1 do ppM.Items[i].Visible := True;
end;

procedure TFormWrok.NShowClick(Sender: TObject);
begin
  var n := FEditData.XMNode;
  while not n.HasAttribute(AT_ADDR) do  n := n.ParentNode;

  TFormShowArray.Execute(n.Attributes[AT_ADDR], DataDevice, GetPathXNode(FEditData.XMNode, true));
end;

class procedure TFormWrok.DoCreateForm(Sender: IAction);
begin
  inherited;
end;

procedure TFormWrok.DoSetFont(const AFont: TFont);
 var
  pv: PVirtualNode;
begin
  inherited;
  Tree.DefaultNodeHeight := Abs(Font.Height) + Tree.TextMargin*2;
  Tree.Header.Height := Tree.DefaultNodeHeight;
  for pv in Tree.Nodes do Tree.NodeHeight[pv] := Tree.DefaultNodeHeight;
end;

function TFormWrok.GetDataDevice: string;
begin
  Result := FDataDevice;
end;

procedure TFormWrok.SetMetaDataInfo(const Value: TInfoEventRes);
begin
  if (csLoading in ComponentState) then Exit;
  ClearTree;
  FMetaDataInfo := Value;
  if not Assigned(FMetaDataInfo.Info) then Exit;
  Tree.BeginUpdate;
  try
   FindAllWorks(FMetaDataInfo.Info, procedure(wrk: IXMLNode; Adr: Integer; const name: string)
     procedure Add(Parent :PVirtualNode; u: IXMLNode);
      var
       chn: PVirtualNode;
       xd: PNodeExData;
       i: Integer;
     begin
       if u.HasAttribute('HIDDEN') and (u.Attributes['HIDDEN'] = True) then Exit;
       chn := Tree.AddChild(Parent);
       Include(chn.States, vsExpanded);
       xd := Tree.GetNodeData(chn);
       xd.XMNode := u;
       if u.HasAttribute(AT_SIZE) then for I := 0 to u.ChildNodes.Count-1 do Add(chn, u.ChildNodes[i])
     end;
    var
     chnr: PVirtualNode;
     i: Integer;
   begin
     chnr := Tree.AddChild(nil);
     Include(chnr.States, vsExpanded);
     PNodeExData(Tree.GetNodeData(chnr)).XMNode := (wrk.ParentNode);
     for i:= 0 to wrk.ChildNodes.Count-1 do Add(chnr, wrk.ChildNodes[i]);
   end);
  finally
   Tree.EndUpdate;
  end;
end;

procedure TFormWrok.SetBindWorkRes(const Value: TWorkEventRes);
 var
  Enum: TVTVirtualNodeEnumerator;
begin
  FBindWorkRes := Value;
  if not Assigned(FBindWorkRes.Work) then Exit;
  if not Assigned(FMetaDataInfo.Info) then
    if not TryConnectFromForkData(FBindWorkRes) then Exit;
  Tree.Repaint; //ЧТО БЫСТРЕЕ ???
//  Enum := Tree.Nodes.GetEnumerator;// .VisibleNodes().GetEnumerator;
//  ExecXTree(FBindWorkRes.Work, function(n: IXMLNode): boolean
//  begin
//    Result := False;
//    if n.HasAttribute(AT_TIP) {or n.HasAttribute(T_TRR)}{т.к. типа может и не быть} then
//     begin
//      while Enum.MoveNext do if PNodeExData(Tree.GetNodeData(Enum.Current)).XMNode = n then
//       begin
//        Tree.InvalidateNode(Enum.Current);
//        Exit;
//       end;
//      Result := True;
//     end;
//  end);
end;

procedure TFormWrok.TreeGetImageIndex(Sender: TBaseVirtualTree; Node: PVirtualNode; Kind: TVTImageKind; Column: TColumnIndex; var Ghosted: Boolean; var ImageIndex: Integer);
 var
  xd: PNodeExData;
  n: IXMLNode;
begin
  xd := Sender.GetNodeData(Node);
  if not Assigned(xd.XMNode) then Exit;
  if (Column = 0) and (Kind in [TVTImageKind.ikNormal, ikSelected]) then
   if xd.XMNode.HasAttribute(AT_SIZE) then ImageIndex := 144
   else
    begin
     n := xd.XMNode.ChildNodes.FindNode(T_DEV);
     if not Assigned(n) then n := xd.XMNode.ChildNodes.FindNode(T_CLC);
     if Assigned(n) and n.ParentNode.HasAttribute(AT_ARRAY) then ImageIndex := 285
     else ImageIndex := 203;
    end;
end;

procedure TFormWrok.TreeBadGetText(Sender: TBaseVirtualTree; Node: PVirtualNode; Column: TColumnIndex; TextType: TVSTTextType; var CellText: string);
 var
  p: PNodeExData;
  procedure SetData(n: IXMLNode);
   var
    V: Variant;
  begin
    if not Assigned(n) then Exit;
    if n.HasAttribute(AT_VALUE) then V := n.Attributes[AT_VALUE];
    if not VarIsNull(V) then
     if n.HasAttribute(AT_DIGITS) then
     begin
       if n.ParentNode.HasAttribute(AT_ARRAY) then
       begin
        var a := string(V).Split([' '], TStringSplitOptions.ExcludeEmpty);
        var s: TArray<string>;
        SetLength(s, Length(a));
        for var I := 0 to High(a) do
         begin
          s[i] := FloatToStrF(StrToFloat(a[i]), ffFixed, n.Attributes[AT_DIGITS], n.Attributes[AT_AQURICY])
         end;
        CellText := string.Join(' ', s);
       end
       else CellText := FloatToStrF(Double(V), ffFixed, n.Attributes[AT_DIGITS], n.Attributes[AT_AQURICY])
     end
     else
       CellText := V;
     if n.HasAttribute(AT_EU) then CellText := CellText+' '+ n.Attributes[AT_EU];
  end;
  procedure SetEU(n: IXMLNode);
  begin
    if not Assigned(n) then Exit;
    if n.HasAttribute(AT_EU) then CellText := n.Attributes[AT_EU];
  end;
begin
  p := Sender.GetNodeData(Node);
  CellText := '';
  if not Assigned(p.XMNode) then Exit;
  if TextType = ttNormal then
   case Column of
    0: CellText := p.XMNode.NodeName;
    1: SetData(p.XMNode.ChildNodes.FindNode(T_DEV));
    2: SetData(p.XMNode.ChildNodes.FindNode(T_CLC));
   end
//  else
//   case Column of
//    1: SetEU(p.XMNode.ChildNodes.FindNode(T_DEV));
//    2: SetEU(p.XMNode.ChildNodes.FindNode(T_CLC));
//   end
end;

procedure TFormWrok.TreeBadPaintText(Sender: TBaseVirtualTree; const TargetCanvas: TCanvas; Node: PVirtualNode;
  Column: TColumnIndex; TextType: TVSTTextType);
 var
  p: PNodeExData;
  procedure SetData(n: IXMLNode);
   var
    V: Variant;
  begin
    if not Assigned(n) then Exit;
    if n.HasAttribute(AT_COLOR) then
     begin
      TargetCanvas.Font.Color := ColorCorrect(n.Attributes[AT_COLOR] and $00FFFFFF);
     end
   // else TargetCanvas.Font.Color := clWindowText;
  end;
begin
  p := Sender.GetNodeData(Node);
  if not Assigned(p.XMNode) then Exit;
  if TextType = ttNormal then
   case Column of
    0: SetData(p.XMNode);
    1: SetData(p.XMNode.ChildNodes.FindNode(T_DEV));
    2: SetData(p.XMNode.ChildNodes.FindNode(T_CLC));
   end
end;

{ TFormWrokUser }


initialization
  RegisterClass(TFormWrok);
  TRegister.AddType<TFormWrok, IForm, ISetDevice>.LiveTime(ltSingletonNamed);
finalization
  GContainer.RemoveModel<TFormWrok>;
end.

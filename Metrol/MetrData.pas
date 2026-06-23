unit MetrData;

interface

uses DeviceIntf, PluginAPI, ExtendIntf, Intf, Manager, debug_except, DockIForm,
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics, Xml.XMLIntf, JvDockControlForm,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, VirtualTrees, Math;

type
  PNodeExData = ^TNodeExData;
  TNodeExData = record   
   Item, x, y, z, d4: string;
  end;
  TFormMetrData = class(TDockIForm)
    Tree: TVirtualStringTree;
    procedure TreeGetText(Sender: TBaseVirtualTree; Node: PVirtualNode; Column: TColumnIndex; TextType: TVSTTextType; var CellText: string);
  private
  protected
    procedure InitializeNewForm; override;
  public
    procedure Loaded; override;
    procedure UpdateTree(Root: IXMLNode; const DevName: string);
    class procedure Execute(Root: IXMLNode; var Item: TFormMetrData; const DevName: string);
  end;

implementation

uses tools;

{$R *.dfm}

{ TFormMetrData }

class procedure TFormMetrData.Execute(Root: IXMLNode; var Item: TFormMetrData; const DevName: string);
begin
  if not Assigned(Item) then
   begin
    Item := TFormMetrData.Create(nil);
    (Globalmanager as IFormEnum).Add(Item as IForm);
   end;
  ShowDockForm(Item);
  (GlobalCore as ITabFormProvider).SetActiveTab(Item as IForm);
  Item.UpdateTree(Root, DevName);
end;

procedure TFormMetrData.InitializeNewForm;
begin
  inherited;
  FPriority := PRIORITY_IForm-1; // вначале создается дочернее окно
end;

procedure TFormMetrData.Loaded;
begin
  inherited;
  Icon := 80;
  Tree.NodeDataSize := SizeOf(TNodeExData);
  PNodeExData(Tree.GetNodeData(Tree.AddChild(nil))).Item := 'X';
  PNodeExData(Tree.GetNodeData(Tree.AddChild(nil))).Item := 'Y';
  PNodeExData(Tree.GetNodeData(Tree.AddChild(nil))).Item := 'Z';
end;

procedure TFormMetrData.TreeGetText(Sender: TBaseVirtualTree; Node: PVirtualNode; Column: TColumnIndex; TextType: TVSTTextType; var CellText: string);
 var
  p: PNodeExData;
begin
  p := PNodeExData(Tree.GetNodeData(Node));
  case Column of
   0: CellText := p.Item; 
   1: CellText := p.x; 
   2: CellText := p.y; 
   3: CellText := p.z; 
   4: CellText := p.d4; 
  end;
end;

procedure TFormMetrData.UpdateTree(Root: IXMLNode; const DevName: string);
  procedure UpdRow(pv: PVirtualNode);
   var
    p: PNodeExData;
    sx,sy,sz,sd4: string;
  begin 
    sx := Format('m%d1', [pv.Index+1]);
    sy := Format('m%d2', [pv.Index+1]);
    sz := Format('m%d3', [pv.Index+1]);
    sd4 := Format('m%d4', [pv.Index+1]);
    p := PNodeExData(Tree.GetNodeData(pv));
    p.x := ' ';
    p.y := ' ';
    p.z := ' ';
    p.d4 := ' ';
    if not Assigned(Root) then Exit;
    if Root.HasAttribute(sx) then p.x := Format('%1.5f', [RadToDeg(Root.Attributes[sx])]);
    if Root.HasAttribute(sx) then p.y := Format('%1.5f', [RadToDeg(Root.Attributes[sy])]);
    if Root.HasAttribute(sx) then p.z := Format('%1.5f', [RadToDeg(Root.Attributes[sz])]);
    if Root.HasAttribute(sx) then p.d4 := Format('%1.5f', [Root.Attributes[sd4]]);
  end;
  var
   v: PVirtualNode;
begin
   if not Assigned(Root) then Caption := DevName + '-поправки не инициализированны' 
   else if Root.NodeName = 'accel' then Caption := DevName + '-Акселерометр'
   else if Root.NodeName = 'magnit' then Caption := DevName + '-Магнитометр'
   else Caption := DevName + '-поправки не найдены';     
   for v in Tree.Nodes do UpdRow(v); 
end;

initialization
  RegisterClass(TFormMetrData);
end.

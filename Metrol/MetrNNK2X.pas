unit MetrNNK2X;

interface

uses system.UITypes,
  DeviceIntf, PluginAPI, ExtendIntf, RootIntf, Container, Actns, debug_except, DockIForm, MetrForm, tools, XMLLua.Math,
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics, Xml.XMLIntf,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, TeEngine, Series, TeeProcs, Chart, VirtualTrees,
  Vcl.StdCtrls, Vcl.ExtCtrls, Vcl.Menus,  VirtualTrees.Types,
  Vcl.PlatformDefaultStyleActnCtrls, Vcl.ActnPopup, ActnCtrls,
  VirtualTrees.BaseAncestorVCL, VirtualTrees.BaseTree, VirtualTrees.AncestorVCL;

type
  TFormNNK2X = class(TFormMetrolog, INotifyBeforeSave, INotifyAfteSave)
    PanelM: TPanel;
    lbInfo: TLabel;
    Tree: TVirtualStringTree;
    procedure TreeAddToSelection(Sender: TBaseVirtualTree; Node: PVirtualNode);
    procedure TreeGetText(Sender: TBaseVirtualTree; Node: PVirtualNode; Column: TColumnIndex; TextType: TVSTTextType; var CellText: string);
  private
    Series: TFastLineSeries;
  protected
    procedure Loaded; override;
    procedure DoStopAtt(AttNode: IXMLNode); override;
    procedure DoUpdateData(NewFileData: Boolean = False); override;
    procedure TreeUpdate; override;
    procedure TreeGetImageIndex(Sender: TBaseVirtualTree; Node: PVirtualNode; Kind: TVTImageKind; Column: TColumnIndex; var Ghosted: Boolean; var ImageIndex: TImageIndex); override;
    procedure TreePaintText(Sender: TBaseVirtualTree; const TargetCanvas: TCanvas; Node: PVirtualNode; Column: TColumnIndex; TextType: TVSTTextType); override;
   const
    NICON = 94;
    class function ClassIcon: Integer; override;
    procedure BeforeSave();
    procedure AfteSave();
  public
    [StaticAction('Новая калибровка ННК2X', 'Метрология', NICON, '0:Метрология.ННК:-1')]
    class procedure DoCreateForm(Sender: IAction); override;
    class function MetrolMame: string; override;
    class function MetrolType: string; override;
  end;

implementation

{$R *.dfm}

{ TFormNNK }

class function TFormNNK2X.ClassIcon: Integer;
begin
  Result := NICON
end;

class function TFormNNK2X.MetrolMame: string;
begin
  Result := 'NNK2X'
end;

class function TFormNNK2X.MetrolType: string;
begin
  Result := 'TNNK2X'
end;

procedure TFormNNK2X.Loaded;
begin
  SetupStepTree(Tree);
  inherited;
  AttestatPanel.Align := alBottom;
end;

class procedure TFormNNK2X.DoCreateForm(Sender: IAction);
begin
  inherited;
end;

procedure TFormNNK2X.DoStopAtt(AttNode: IXMLNode);
begin
  inherited;
end;

procedure TFormNNK2X.DoUpdateData(NewFileData: Boolean = False);
begin
  if mstLockUpdate in State then Exit;
  inherited;
end;

procedure TFormNNK2X.AfteSave;
begin
  DoUpdateData;
end;

procedure TFormNNK2X.BeforeSave;
begin
end;

procedure TFormNNK2X.TreeAddToSelection(Sender: TBaseVirtualTree; Node: PVirtualNode);
begin
  lbInfo.Caption := PNodeExData(Tree.GetNodeData(Node)).XMNode.Attributes['INFO'];
  AttestatLabel.Caption := 'Аттестация';
end;

procedure TFormNNK2X.TreeGetImageIndex(Sender: TBaseVirtualTree; Node: PVirtualNode; Kind: TVTImageKind; Column: TColumnIndex; var Ghosted: Boolean; var ImageIndex: TImageIndex);
begin
  if Sender.GetNodeLevel(Node) = 0 then Exit;
  inherited;
end;

procedure TFormNNK2X.TreePaintText(Sender: TBaseVirtualTree; const TargetCanvas: TCanvas; Node: PVirtualNode; Column: TColumnIndex; TextType: TVSTTextType);
begin
  if Sender.GetNodeLevel(Node) = 0 then TargetCanvas.Font.Color := clBlue
  else inherited;
end;

procedure TFormNNK2X.TreeUpdate;
 var
  alg, n: IXMLNode;
  pv: PVirtualNode;
  d, old: Double;
begin
  Tree.BeginUpdate;
  try
   TreeClear;
   alg := GetMetr([MetrolType], FileData);
   if not Assigned(alg) then Exit;
   old := -1;
   pv := nil;
   for n in XEnum(alg) do
    begin
     d := n.Attributes['D'];
     if old <> d then
      begin
       pv := Tree.AddChild(nil);
       Include(pv.States, vsExpanded);
       PNodeExData(Tree.GetNodeData(pv)).XMNode := n;
       old := d;
      end;
     PNodeExData(Tree.GetNodeData(Tree.AddChild(pv))).XMNode := n;
    end;
  finally
   Tree.EndUpdate;
  end;
end;

procedure TFormNNK2X.TreeGetText(Sender: TBaseVirtualTree; Node: PVirtualNode; Column: TColumnIndex; TextType: TVSTTextType; var CellText: string);
 const
  fmtData = '%1.0f';
  fmtDataW = '%1.3f';
 var
  p: PNodeExData;
  procedure SetData(const path, atr: string; const fmt: string = '');
   var
    V: Variant;
    r: IXMLNode;
  begin
    if path = '' then r := p.XMNode
    else r := GetXNode(p.XMNode, Path);
    if not Assigned(r) then Exit;
    if r.HasAttribute(atr) then V := r.Attributes[atr];
    if not VarIsNull(V) then
     if (fmt <> '') then CellText := Format(fmt,[Double(V)])
     else CellText := V;
  end;
begin
  CellText := '';
  p := Sender.GetNodeData(Node);
  if not Assigned(p.XMNode) then Exit;
  if Tree.GetNodeLevel(Node) = 0 then
   begin
    if Column = 0 then CellText := p.XMNode.Attributes['D'];
   end
  else
   case Column of
    0: SetData('', 'STEP');
    1: CellText := p.XMNode.Attributes['KP'];
    2: CellText := p.XMNode.Attributes['LR'];
    3: SetData('BL.DEV', AT_VALUE, fmtData);
    4: SetData('BR.DEV', AT_VALUE, fmtData);
    5: SetData('DL.DEV', AT_VALUE, fmtData);
    6: SetData('DR.DEV', AT_VALUE, fmtData);
   end;
end;

initialization
  RegisterClass(TFormNNK2X);
  TRegister.AddType<TFormNNK2X, IForm>.LiveTime(ltSingletonNamed);
finalization
  GContainer.RemoveModel<TFormNNK2X>;
end.

unit MetrGGKP;

interface

uses system.UITypes,
  DeviceIntf, PluginAPI, ExtendIntf, RootIntf, Container, Actns, debug_except, DockIForm, MetrForm, tools, XMLLua.Math,
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics, Xml.XMLIntf,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, TeEngine, Series, TeeProcs, Chart, VirtualTrees, VirtualTrees.Types,
  Vcl.StdCtrls, Vcl.ExtCtrls, Vcl.Menus,
  Vcl.PlatformDefaultStyleActnCtrls, Vcl.ActnPopup,
  VirtualTrees.BaseAncestorVCL, VirtualTrees.BaseTree, VirtualTrees.AncestorVCL;

type
  TFormGGKP = class(TFormMetrolog{, INotifyBeforeSave, INotifyAfteSave})
    PanelM: TPanel;
    Splitter: TSplitter;
    lbInfo: TLabel;
    Tree: TVirtualStringTree;
    Chart: TChart;
    Series1: TLineSeries;
    Series2: TLineSeries;
    Series3: TLineSeries;
    procedure TreeAddToSelection(Sender: TBaseVirtualTree; Node: PVirtualNode);
    procedure TreeGetText(Sender: TBaseVirtualTree; Node: PVirtualNode; Column: TColumnIndex; TextType: TVSTTextType; var CellText: string);
  private
    procedure DoUpdateChart();
  protected
    Fsch1,Fsch2: string;
    procedure Loaded; override;
    procedure DoStopAtt(AttNode: IXMLNode); override;
    procedure DoUpdateData(NewFileData: Boolean = False); override;
    procedure TreeUpdate; override;
    procedure TreeGetImageIndex(Sender: TBaseVirtualTree; Node: PVirtualNode; Kind: TVTImageKind; Column: TColumnIndex; var Ghosted: Boolean; var ImageIndex: TImageIndex); override;
    procedure TreePaintText(Sender: TBaseVirtualTree; const TargetCanvas: TCanvas; Node: PVirtualNode; Column: TColumnIndex; TextType: TVSTTextType); override;
   const
    NICON = 334;
    class function ClassIcon: Integer; override;
  public
    [StaticAction('Новая калибровка ГГКП', 'Метрология', NICON, '0:Метрология.ГГКП:-1')]
    class procedure DoCreateForm(Sender: IAction); override;
    class function MetrolMame: string; override;
    class function MetrolType: string; override;
  end;
  TFormGGKP128 = class(TFormGGKP)
  protected
    procedure Loaded; override;
  public
   const
    NICON = 334;
    [StaticAction('Новая калибровка ГГКП 128', 'Метрология', NICON, '0:Метрология.ГГКП:-1')]
    class procedure DoCreateForm(Sender: IAction); override;
    class function MetrolType: string; override;
  end;

//var
//  FormGGKP: TFormGGKP;

implementation

uses PatchCart;

{$R *.dfm}

{ TFormNNK }

class function TFormGGKP.ClassIcon: Integer;
begin
  Result := NICON
end;

class function TFormGGKP.MetrolMame: string;
begin
  Result := 'ГГКП'
end;

class function TFormGGKP.MetrolType: string;
begin
  Result := 'TGGKP1'
end;

procedure TFormGGKP.Loaded;
begin
  SetupStepTree(Tree);
  inherited;
  AttestatPanel.Align := alBottom;
  Fsch1 := 'гк1.DEV';
  Fsch2 := 'гк2.DEV';
  PatchTeeCart(chart);
end;

class procedure TFormGGKP.DoCreateForm(Sender: IAction);
begin
  inherited;
end;

procedure TFormGGKP.DoStopAtt(AttNode: IXMLNode);
begin
  inherited;
  DoUpdateChart;
end;

procedure TFormGGKP.DoUpdateData(NewFileData: Boolean = False);
begin
  if mstLockUpdate in State then Exit;
  inherited;
  DoUpdateChart;
end;

procedure TFormGGKP.TreeAddToSelection(Sender: TBaseVirtualTree; Node: PVirtualNode);
begin
  lbInfo.Caption := PNodeExData(Tree.GetNodeData(Node)).XMNode.Attributes['INFO'];
  AttestatLabel.Caption := 'Аттестация';
end;

procedure TFormGGKP.TreeGetImageIndex(Sender: TBaseVirtualTree; Node: PVirtualNode; Kind: TVTImageKind; Column: TColumnIndex; var Ghosted: Boolean; var ImageIndex: TImageIndex);
begin
  if Sender.GetNodeLevel(Node) = 0 then Exit;
  inherited;
end;

procedure TFormGGKP.TreePaintText(Sender: TBaseVirtualTree; const TargetCanvas: TCanvas; Node: PVirtualNode; Column: TColumnIndex; TextType: TVSTTextType);
begin
  if Sender.GetNodeLevel(Node) = 0 then TargetCanvas.Font.Color := clBlue
  else inherited;
end;

procedure TFormGGKP.DoUpdateChart;
 var
  alg: IXMLNode;
  procedure PrintSeries(s: TLineSeries; const astp: TArray<Integer>);
   var
    i: Integer;
    n: IXMLNode;
  begin
    s.Clear;
    for i := 0 to High(astp) do
     begin
      n := alg.ChildNodes.FindNode('STEP'+astp[i].ToString);
      s.AddXY(Double(n.Attributes['A1']), Double(n.Attributes['PLOTN']))
     end;
  end;
  function CheckExecuted: Boolean;
   var
    n: IXMLNode;
  begin
    Result := True;
    for n in XEnum(alg) do Result := Result and  Boolean(n.Attributes['EXECUTED']);
  end;
begin
  alg := GetMetr([MetrolType], FileData);
  if not Assigned(alg) then Exit;
  if CheckExecuted then
   begin
    PrintSeries(Series1, [2,3,4]);
    PrintSeries(Series2, [5,6,7]);
    PrintSeries(Series3, [8,9,10]);
   end;
end;

procedure TFormGGKP.TreeUpdate;
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

procedure TFormGGKP.TreeGetText(Sender: TBaseVirtualTree; Node: PVirtualNode; Column: TColumnIndex; TextType: TVSTTextType; var CellText: string);
 const
  fmtData0 = '%1.0f';
  fmtData2 = '%1.2f';
  fmtData3 = '%1.3f';
  fmtData4 = '%1.4f';
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
    1: CellText := p.XMNode.Attributes['PLOTN'];
    2: SetData(Fsch1, AT_VALUE, fmtData0);
    3: SetData(Fsch2, AT_VALUE, fmtData0);
    4: SetData('','A1', fmtData4);
    5: SetData('','PlA1', fmtData3);
    6: SetData('','Err', fmtData2);
   end;
end;

{ TFormGGKP128 }

class procedure TFormGGKP128.DoCreateForm(Sender: IAction);
begin
  inherited;

end;

procedure TFormGGKP128.Loaded;
begin
  inherited;
  Fsch1 := 'мз.DEV';
  Fsch2 := 'бз.DEV'
end;

class function TFormGGKP128.MetrolType: string;
begin
  Result := 'TGGKP128'
end;

initialization
  RegisterClass(TFormGGKP);
  TRegister.AddType<TFormGGKP, IForm>.LiveTime(ltSingletonNamed);
  RegisterClass(TFormGGKP128);
  TRegister.AddType<TFormGGKP128, IForm>.LiveTime(ltSingletonNamed);
finalization
  GContainer.RemoveModel<TFormGGKP>;
  GContainer.RemoveModel<TFormGGKP128>;
end.

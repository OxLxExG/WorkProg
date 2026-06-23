unit MetrNNK;

interface

uses system.UITypes,
  DeviceIntf, PluginAPI, ExtendIntf, RootIntf, Container, Actns, debug_except, DockIForm, MetrForm, tools, XMLLua.Math,
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics, Xml.XMLIntf,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, TeEngine, Series, TeeProcs, Chart, VirtualTrees,
  Vcl.StdCtrls, Vcl.ExtCtrls, Vcl.Menus,   VirtualTrees.Types,
  Vcl.PlatformDefaultStyleActnCtrls, Vcl.ActnPopup, ActnCtrls,
  VirtualTrees.BaseAncestorVCL, VirtualTrees.BaseTree, VirtualTrees.AncestorVCL;

type
  TFormNNK = class(TFormMetrolog, INotifyBeforeSave, INotifyAfteSave)
    PanelM: TPanel;
    Splitter: TSplitter;
    lbInfo: TLabel;
    Tree: TVirtualStringTree;
    Chart: TChart;
    ppM: TPopupActionBar;
    NShowLegend: TMenuItem;
    NWater: TMenuItem;
    Edit1: TEdit;
    procedure TreeAddToSelection(Sender: TBaseVirtualTree; Node: PVirtualNode);
    procedure TreeGetText(Sender: TBaseVirtualTree; Node: PVirtualNode; Column: TColumnIndex; TextType: TVSTTextType; var CellText: string);
    procedure NShowLegendClick(Sender: TObject);
    procedure NWaterClick(Sender: TObject);
    procedure Edit1KeyPress(Sender: TObject; var Key: Char);
  private
    Series: TFastLineSeries;
    procedure DoUpdateChart();safecall;
//    procedure NSetupInclClick(Sender: TObject);
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
    [StaticAction('Новая калибровка ННК', 'Метрология', NICON, '0:Метрология.ННК:-1')]
    class procedure DoCreateForm(Sender: IAction); override;
    class function MetrolMame: string; override;
    class function MetrolType: string; override;
  end;

//var
//  FormNNK: TFormNNK;

implementation

uses PatchCart;
{$R *.dfm}

{ TFormNNK }

class function TFormNNK.ClassIcon: Integer;
begin
  Result := NICON
end;

class function TFormNNK.MetrolMame: string;
begin
  Result := 'ННК'
end;

class function TFormNNK.MetrolType: string;
begin
  Result := 'TNNK'
end;

{procedure TFormNNK.NSetupInclClick(Sender: TObject);
 var
  ist: string;
  m: IXMLNode;
begin
  if not Assigned(FileData) then Exit;
   m := GetMetr([], FileData).ParentNode.ParentNode;

  if not m.HasAttribute('ISTOCHNIK') then ist := 'Pu-Be №9'
  else ist := m.Attributes['ISTOCHNIK'];
  m.Attributes['ISTOCHNIK'] := InputBox('Источник', 'Источник', ist);
end;}

procedure TFormNNK.NShowLegendClick(Sender: TObject);
begin
  Chart.Legend.Visible := NShowLegend.Checked;
end;

procedure TFormNNK.Loaded;
begin
  SetupStepTree(Tree);
  inherited;
  AttestatPanel.Align := alBottom;
//  AddToNCMenu('-');
//  AddToNCMenu('Источник...', NSetupInclClick);
  PatchTeeCart(chart);
end;

class procedure TFormNNK.DoCreateForm(Sender: IAction);
begin
  inherited;
end;

procedure TFormNNK.DoStopAtt(AttNode: IXMLNode);
begin
  inherited;
  DoUpdateChart;
end;

procedure TFormNNK.DoUpdateData(NewFileData: Boolean = False);
begin
  if mstLockUpdate in State then Exit;
  inherited;
  DoUpdateChart;
end;

procedure TFormNNK.Edit1KeyPress(Sender: TObject; var Key: Char);
 var
  n: Variant;
  i: Integer;
  d, p: Double;
begin
  if Key = #$D then
   begin
    d := StrToFloat(Edit1.Text)/200;
    Edit1.Text := (StrToint(Edit1.Text)-1).ToString;
    n := XToVar(GetMetr([], GetFileOrDevData));
    Series.Clear;
    if Chart.SeriesGroups[0].Active = gaYes then
     for i := 14 to 70 do
      begin
       p := i/100;
       Series.AddXY(TXmlScriptmath.RbfInterp(n.Rbf.A, d, p), p);
      end
    else if Chart.SeriesGroups[1].Active = gaYes then
     for i := 450 downto 92 do
      begin
       p := n.KW1/(i*10);
       Series.AddXY(TXmlScriptmath.RbfInterp(n.Rbf.K1, d, p), p);
      end
    else if Chart.SeriesGroups[2].Active = gaYes then
     for i := 220 downto 20 do
      begin
       p := n.KW2/(i*10);
       Series.AddXY(TXmlScriptmath.RbfInterp(n.Rbf.K2, d, p), p);
      end
    else for i := 120 downto 10 do
     begin
      p := n.KWG/(i*10);
      Series.AddXY(TXmlScriptmath.RbfInterp(n.Rbf.G, d, p), p);
     end;
    Key := #0
   end;
end;

procedure TFormNNK.AfteSave;
begin
  DoUpdateData;
end;

procedure TFormNNK.BeforeSave;
begin
  Chart.SeriesList.Clear;
  Chart.SeriesGroups.Clear;
end;

procedure TFormNNK.NWaterClick(Sender: TObject);
begin
  DoUpdateChart;
end;

procedure TFormNNK.TreeAddToSelection(Sender: TBaseVirtualTree; Node: PVirtualNode);
begin
  lbInfo.Caption := PNodeExData(Tree.GetNodeData(Node)).XMNode.Attributes['INFO'];
  AttestatLabel.Caption := 'Аттестация';
end;

procedure TFormNNK.TreeGetImageIndex(Sender: TBaseVirtualTree; Node: PVirtualNode; Kind: TVTImageKind; Column: TColumnIndex; var Ghosted: Boolean; var ImageIndex: TImageIndex);
begin
  if Sender.GetNodeLevel(Node) = 0 then Exit;
  inherited;
end;

procedure TFormNNK.TreePaintText(Sender: TBaseVirtualTree; const TargetCanvas: TCanvas; Node: PVirtualNode; Column: TColumnIndex; TextType: TVSTTextType);
begin
  if Sender.GetNodeLevel(Node) = 0 then TargetCanvas.Font.Color := clBlue
  else inherited;
end;

procedure TFormNNK.DoUpdateChart;
 var
  alg, n: IXMLNode;
  d, old: Double;
  seind: Integer;
  s,s1,s2,sg: TChartSeries;
begin
  alg := GetMetr([MetrolType], FileData);
  if not Assigned(alg) then Exit;
  old := -1;
  seind := -1;
  s := Chart.SeriesGroups[0].Series[0];
  s1 := Chart.SeriesGroups[1].Series[0];
  s2 := Chart.SeriesGroups[2].Series[0];
  sg := Chart.SeriesGroups[3].Series[0];
  for n in XEnum(alg) do
   begin
    d := Double(n.Attributes['D']);
    if old <> d then
     begin
      Inc(seind, 1);
      s := Chart.SeriesGroups[0].Series[seind];
      s1 := Chart.SeriesGroups[1].Series[seind];
      s2 := Chart.SeriesGroups[2].Series[seind];
      sg := Chart.SeriesGroups[3].Series[seind];
      s.Clear;
      s1.Clear;
      s2.Clear;
      sg.Clear;
      old := d;
     end;
    if Boolean(n.Attributes['EXECUTED']) then
     if SameText(n.Attributes['KP'], 'Вода') then
      begin
       if NWater.Checked then
        begin
         if n.HasAttribute('nkw') then s.AddXY(100, Double(n.Attributes['nkw']));
         if n.HasAttribute('nkw1') then s1.AddXY(100, Double(n.Attributes['nkw1']));
         if n.HasAttribute('nkw1') then s2.AddXY(100, Double(n.Attributes['nkw2']));
         if n.HasAttribute('nkwg') then sg.AddXY(100, Double(n.Attributes['nkwg']));
        end;
      end
     else
      begin
       if n.HasAttribute('nkw') then s.AddXY(Double(n.Attributes['KP']), Double(n.Attributes['nkw']));
       if n.HasAttribute('nkw1') then s1.AddXY(Double(n.Attributes['KP']), Double(n.Attributes['nkw1']));
       if n.HasAttribute('nkw1') then s2.AddXY(Double(n.Attributes['KP']), Double(n.Attributes['nkw2']));
       if n.HasAttribute('nkwg') then sg.AddXY(Double(n.Attributes['KP']), Double(n.Attributes['nkwg']));
      end;
   end;
end;

procedure TFormNNK.TreeUpdate;
 var
  alg, n: IXMLNode;
  pv: PVirtualNode;
  d, old: Double;
  procedure AddSeries(group: Integer; const nme: string; vs: Boolean = False);
   var
    s: TLineSeries;
  begin
    s := CreateUnLoad<TLineSeries>;
    Chart.AddSeries(s);
    Chart.SeriesGroups[group].Add(s);
    s.Visible := vs;
    s.LinePen.Width := 3;
    s.Pointer.Visible := True;
    s.Title := Format('Диам-%1.0f %s',[d, nme]);
  end;
begin
  Tree.BeginUpdate;
  try
   TreeClear;
   Chart.SeriesList.Clear;
   Chart.SeriesGroups.Clear;
   Chart.SeriesGroups.Add;
   Chart.SeriesGroups.Add;
   Chart.SeriesGroups.Add;
   Chart.SeriesGroups.Add;
   Chart.SeriesGroups[0].Name := 'Мз/Бз';
   Chart.SeriesGroups[1].Name := 'Мз';
   Chart.SeriesGroups[2].Name := 'Бз';
   Chart.SeriesGroups[3].Name := 'НГ';

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
       AddSeries(0,'Мз/Бз', True);
       AddSeries(1,'Мз');
       AddSeries(2,'Бз');
       AddSeries(3,'НГ');
       old := d;
      end;
     PNodeExData(Tree.GetNodeData(Tree.AddChild(pv))).XMNode := n;
    end;
    Series := TFastLineSeries.Create(Self);
    Chart.AddSeries(Series);
  finally

   Tree.EndUpdate;
  end;
end;

procedure TFormNNK.TreeGetText(Sender: TBaseVirtualTree; Node: PVirtualNode; Column: TColumnIndex; TextType: TVSTTextType; var CellText: string);
 const
  fmtData = '%1.3f';
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
    2: SetData('нк1.DEV', AT_VALUE, fmtData);
    3: SetData('нк2.DEV', AT_VALUE, fmtData);
    4: SetData('нгк.DEV', AT_VALUE, fmtData);
    5: SetData('','nkw', fmtDataW);
    6: SetData('','nkw1', fmtDataW);
    7: SetData('','nkw2', fmtDataW);
    8: SetData('','nkwg', fmtDataW);
   end;
end;

initialization
  RegisterClass(TFormNNK);
  TRegister.AddType<TFormNNK, IForm>.LiveTime(ltSingletonNamed);
finalization
  GContainer.RemoveModel<TFormNNK>;
end.

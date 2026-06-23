unit MetrAGK;

interface

 {$M+}

uses
  DeviceIntf, PluginAPI, ExtendIntf, RootIntf, debug_except, DockIForm, MetrForm,
  Container, Actns, ExcelImpl, XMLLua, VerySimple.Lua.Lib, Winapi.Windows,
  Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Xml.XMLIntf, Vcl.Controls, Vcl.Forms, Vcl.Dialogs, VirtualTrees, Vcl.StdCtrls,
  Vcl.ExtCtrls, Winapi.ActiveX, TeEngine, Series, TeeProcs, VirtualTrees.Types,
  Chart, Vcl.Menus, Vcl.PlatformDefaultStyleActnCtrls, Vcl.ActnPopup,
  AutoMetr.GK, VirtualTrees.BaseAncestorVCL, VirtualTrees.BaseTree,
  VirtualTrees.AncestorVCL;

type
  TFormAGK = class(TFormMetrolog, IAutomatMetrology)
    PanelM: TPanel;
    lbInfo: TLabel;
    Tree: TVirtualStringTree;
    Chart: TChart;
    Splitter: TSplitter;
    lbAlpha: TLabel;
    ls1: TLineSeries;
    ls2: TLineSeries;
    ls3: TLineSeries;
    ls4: TLineSeries;
    fs1: TFastLineSeries;
    fs2: TFastLineSeries;
    fs3: TFastLineSeries;
    fs4: TFastLineSeries;
    procedure TreeAddToSelection(Sender: TBaseVirtualTree; Node: PVirtualNode);
    procedure TreeGetText(Sender: TBaseVirtualTree; Node: PVirtualNode; Column: TColumnIndex; TextType: TVSTTextType; var CellText: string);
  private
    FAutomatMetrology: TGKAuto;
  protected
    procedure Loaded; override;
    procedure DoStopAtt(AttNode: IXMLNode); override;
    procedure DoUpdateData(NewFileData: Boolean = False); override;
    const
      NICON = 97;
    class function ClassIcon: Integer; override;
    procedure DoUpdateAlpha();
    procedure DoUpdateChart();
    property AutomatMetrology: TGKAuto read FAutomatMetrology implements IAutomatMetrology;
  public
    destructor Destroy; override;
    [StaticAction('Новая калибровка АГК', 'Метрология', NICON, '0:Метрология.ГК')]
    class procedure DoCreateForm(Sender: IAction); override;
    class function MetrolMame: string; override;
    class function MetrolType: string; override;
  end;

implementation

{$R *.dfm}

uses tools, PatchCart;

{$REGION 'TFormAGK'}
class function TFormAGK.MetrolMame: string;
begin
  Result := 'АГК';
end;

class function TFormAGK.MetrolType: string;
begin
  Result := 'TAGK'
end;

class function TFormAGK.ClassIcon: Integer;
begin
  Result := NICON
end;

procedure TFormAGK.DoUpdateChart;
var
  r,root, st: IXMLNode;
  a, b: Double;
  i,stp,j: Integer;
   Fs: TFastLineSeries;
   Ls: TLineSeries;
begin
  root := GetMetr([MetrolType], FileData);
  if Assigned(root) then for j := 1 to 4 do
   begin
    fs := TFastLineSeries(FindComponent('fs'+j.ToString));
    ls := TLineSeries(FindComponent('ls'+j.ToString));
    Fs.Clear;
    Ls.Clear;
    stp := 1;
    for i := 1 to 10 do
     begin
      st := root.ChildNodes['STEP'+stp.ToString];
      inc(stp);
      if Boolean(st.Attributes['EXECUTED']) then
         ls.AddXY(st.Attributes['RT'], st.ChildNodes['GR'+j.ToString].ChildNodes[T_DEV].Attributes[AT_VALUE]);
     end;
    r := GetMetr([], GetFileOrDevData);
    if not Assigned(r) then Continue;
    b := Double(r.Attributes['kGK'+ j.ToString]);
    if r.HasAttribute('DELTA') then
       a := r.Attributes['DELTA']
    else
      a := 0;
    fs.AddXY(0, a);
    fs.AddXY(200, 200 / b + a);
   end;
end;

procedure TFormAGK.DoUpdateAlpha;
const
  ALPHA_FORMAT = 'α%d= %1.6f ';
var
  r: IXMLNode;
  i: Integer;
begin
  r := GetMetr([], GetFileOrDevData);
  lbAlpha.Caption := '   ';
  if Assigned(r) then for i := 1 to 4 do
   begin
    lbAlpha.Caption := lbAlpha.Caption + Format(ALPHA_FORMAT, [i, Double(r.Attributes['kGK'+ i.ToString])]);
   end;
   lbAlpha.Caption := lbAlpha.Caption + ' мкр/ч/имп';
end;

destructor TFormAGK.Destroy;
begin
  FAutomatMetrology.Free;
  inherited;
end;

class procedure TFormAGK.DoCreateForm(Sender: IAction);
begin
  inherited;
end;

procedure TFormAGK.DoStopAtt(AttNode: IXMLNode);
begin
  inherited;
  DoUpdateAlpha;
  DoUpdateChart;
end;

procedure TFormAGK.DoUpdateData(NewFileData: Boolean = False);
begin
  inherited;
  DoUpdateAlpha;
  DoUpdateChart;
end;

procedure TFormAGK.Loaded;
begin

  SetupStepTree(Tree);
  inherited;
  AttestatPanel.Align := alBottom;
  FAutomatMetrology := TGKAuto.Create(Self);
  FAutomatMetrology.Report := AutoReport;
  PatchTeeCart(chart);
end;

procedure TFormAGK.TreeAddToSelection(Sender: TBaseVirtualTree; Node: PVirtualNode);
begin
  lbInfo.Caption := PNodeExData(Tree.GetNodeData(Node)).XMNode.Attributes['INFO'];
  AttestatLabel.Caption := 'Аттестация';
end;

procedure TFormAGK.TreeGetText(Sender: TBaseVirtualTree; Node: PVirtualNode; Column: TColumnIndex; TextType: TVSTTextType; var CellText: string);
var
  p: PNodeExData;

  procedure SetData(const path, atr: string; const fmt: string = '');
  var
    V: Variant;
    r: IXMLNode;
  begin
    if path = '' then
      r := p.XMNode
    else
      r := GetXNode(p.XMNode, path);
    if not Assigned(r) then
      Exit;
    if r.HasAttribute(atr) then
      V := r.Attributes[atr];
    if not VarIsNull(V) then
      if (fmt <> '') then
        CellText := Format(fmt, [Double(V)])
      else
        CellText := V;
  end;

begin
  CellText := '';
  p := Sender.GetNodeData(Node);
  if not Assigned(p.XMNode) then
    Exit;
  case Column of
    0:
      SetData('', 'STEP');
    1:
      SetData('', 'CHANEL');
    2:
      SetData('', 'RT');
    3:
      SetData('', 'DELTA', '%1.2f');
    4:
      SetData('GR1.DEV', AT_VALUE, '%1.0f');
    5:
      SetData('GR2.DEV', AT_VALUE, '%1.0f');
    6:
      SetData('GR3.DEV', AT_VALUE, '%1.0f');
    7:
      SetData('GR4.DEV', AT_VALUE, '%1.0f');
    8:
      SetData('GR1.CLC', AT_VALUE, '%1.2f');
    9:
      SetData('GR2.CLC', AT_VALUE, '%1.2f');
    10:
      SetData('GR3.CLC', AT_VALUE, '%1.2f');
    11:
      SetData('GR4.CLC', AT_VALUE, '%1.2f');
  end;
end;
{$ENDREGION}

initialization
  RegisterClass(TFormAGK);
  TRegister.AddType<TFormAGK, IForm>.LiveTime(ltSingletonNamed);

finalization
  GContainer.RemoveModel<TFormAGK>;

end.


unit MetrInclin;

interface

uses DeviceIntf, PluginAPI, ExtendIntf, RootIntf, Container, Actns, debug_except, DockIForm, math,
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics, System.Bindings.Expression, Xml.XMLIntf,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, VirtualTrees, Vcl.Menus, Vcl.PlatformDefaultStyleActnCtrls, Vcl.ActnPopup, Vcl.ImgList, Vcl.ExtCtrls, Vcl.StdCtrls,
  MetrForm, Vcl.ComCtrls, AutoMetr.Inclin, RootImpl;

type
  PNodeTData = ^TNodeTData;
  TNodeTData = record
   Item, x, y, z, d4: string;
  end;

  TFormInclin = class(TFormMetrolog, IAutomatMetrology)
    PanelM: TPanel;
    lbInfo: TLabel;
    Tree: TVirtualStringTree;
    PanelP: TPanel;
    Splitter: TSplitter;
    TreeA: TVirtualStringTree;
    Splitter2: TSplitter;
    TreeH: TVirtualStringTree;
    pc: TCPageControl;
    procedure TreeGetText(Sender: TBaseVirtualTree; Node: PVirtualNode; Column: TColumnIndex; TextType: TVSTTextType; var CellText: string);
    procedure TreeAddToSelection(Sender: TBaseVirtualTree; Node: PVirtualNode);
    procedure TreeAHGetText(Sender: TBaseVirtualTree; Node: PVirtualNode; Column: TColumnIndex; TextType: TVSTTextType; var CellText: string);
  private
    FfmtData: string;
    FfmtDz: string;
    FfmtDiag: string;
    FfmtOve: string;
    FAutomatMetrology: TinclAuto;
    procedure NSetupInclClick(Sender: TObject);
  protected
    procedure Loaded; override;
    procedure DoSetFont(const AFont: TFont); override;
    procedure DoStopAtt(AttNode: IXMLNode); override;
    procedure DoUpdateData(NewFileData: Boolean = False); override;
   const
    NICON = 111;
    class function ClassIcon: Integer; override;
  public
    destructor Destroy; override;
    [StaticAction('Новая калибровка Т21', 'Метрология', NICON, '0:Метрология.Инклинометры:-1')]
    class procedure DoCreateForm(Sender: IAction); override;
    class function MetrolMame: string; override;
    class function MetrolType: string; override;
    class procedure UpdateAH(T: TVirtualStringTree; Root: IXMLNode; const AfmtDiag, AfmtDz, AfmtOve: string);
    class procedure InitT(T: TVirtualStringTree); static;
    property AutomatMetrology: TinclAuto read FAutomatMetrology implements IAutomatMetrology;
  published
    property fmtData: string read FfmtData write FfmtData;
    property fmtDiag: string read FfmtDiag write FfmtDiag;
    property fmtDz: string read FfmtDz write FfmtDz;
    property fmtOve: string read FfmtOve write FfmtOve;
  end;

implementation

{$R *.dfm}

uses tools, MetrInclinSetup;

{ TFormWork }

class function TFormInclin.ClassIcon: Integer;
begin
  Result := NICON;
end;

destructor TFormInclin.Destroy;
begin
  FAutomatMetrology.Free;
  inherited;
end;

class procedure TFormInclin.DoCreateForm(Sender: IAction);
begin
  inherited;
end;

class function TFormInclin.MetrolMame: string;
begin
  Result := 'Inclin'
end;

class function TFormInclin.MetrolType: string;
begin
  Result := 'T21'
end;

class procedure TFormInclin.InitT(T: TVirtualStringTree);
begin
 T.NodeDataSize := SizeOf(TNodeTData);
 PNodeTData(T.GetNodeData(T.AddChild(nil))).Item := 'X';
 PNodeTData(T.GetNodeData(T.AddChild(nil))).Item := 'Y';
 PNodeTData(T.GetNodeData(T.AddChild(nil))).Item := 'Z';
end;

procedure TFormInclin.Loaded;
begin
  // сначала инит Tree
  SetupStepTree(Tree);
  InitT(TreeA);
  InitT(TreeH);
  // и только потом заполняем данными Tree
  inherited;
//  NIsMedian.Visible := True;
  AttestatPanel.Align := alBottom;
  AddToNCMenu('-');
  AddToNCMenu('Установки Инклинометрии...', NSetupInclClick);
  FAutomatMetrology := TinclAuto.Create(Self, AutoReport);
end;

procedure TFormInclin.DoSetFont(const AFont: TFont);
begin
  inherited;
  TreeSetFont(TreeH);
  TreeSetFont(TreeA);
end;

procedure TFormInclin.DoStopAtt(AttNode: IXMLNode);
begin
  inherited;
  UpdateAH(TreeA, GetMetr(['accel','m3x4'], GetFileOrDevData), fmtDiag, fmtDz, fmtOve);
  UpdateAH(TreeH, GetMetr(['magnit','m3x4'], GetFileOrDevData), fmtDiag, fmtDz, fmtOve);
end;

procedure TFormInclin.DoUpdateData(NewFileData: Boolean = False);
begin
  inherited;
  UpdateAH(TreeA, GetMetr(['accel','m3x4'], GetFileOrDevData), fmtDiag, fmtDz, fmtOve);
  UpdateAH(TreeH, GetMetr(['magnit','m3x4'], GetFileOrDevData), fmtDiag, fmtDz, fmtOve);
end;

procedure TFormInclin.NSetupInclClick(Sender: TObject);
begin
 if TFormInclSetup.Execute(FfmtData, FfmtDiag, FfmtDz, FfmtOve) then
  begin
   Tree.Repaint;
   UpdateAH(TreeA, GetMetr(['accel','m3x4'], GetFileOrDevData), fmtDiag, fmtDz, fmtOve);
   UpdateAH(TreeH, GetMetr(['magnit','m3x4'], GetFileOrDevData), fmtDiag, fmtDz, fmtOve);
  end;
end;

class procedure TFormInclin.UpdateAH(T: TVirtualStringTree; Root: IXMLNode; const AfmtDiag, AfmtDz, AfmtOve: string);
  procedure UpdRow(pv: PVirtualNode);
   var
    p: PNodeTData;
    sx,sy,sz,sd4: string;
    function getFmt(const f: string): string;
    begin
     if (f = 'm11') or (f = 'm22') or (f = 'm33') then Result := AfmtDiag
     else Result := AfmtOve;
     if Result = '' then Result := '%g'
    end;
  begin
    sx := Format('m%d1', [pv.Index+1]);
    sy := Format('m%d2', [pv.Index+1]);
    sz := Format('m%d3', [pv.Index+1]);
    sd4 := Format('m%d4', [pv.Index+1]);
    p := T.GetNodeData(pv);
    p.x := ''; p.y := ''; p.z := ''; p.d4 := '';
    if not Assigned(Root) then Exit;
    if Root.HasAttribute(sx) then p.x := Format(getFmt(sx), [Double(Root.Attributes[sx])]);
    if Root.HasAttribute(sy) then p.y := Format(getFmt(sy), [Double(Root.Attributes[sy])]);
    if Root.HasAttribute(sz) then p.z := Format(getFmt(sz), [Double(Root.Attributes[sz])]);
    if Root.HasAttribute(sd4) then if AfmtDz = '' then p.d4 := Root.Attributes[sd4]
    else p.d4 := Format(AfmtDz, [Double(Root.Attributes[sd4])]);
    T.InvalidateNode(pv);
  end;
  var
   v: PVirtualNode;
begin
  for v in T.Nodes do UpdRow(v);
end;

procedure TFormInclin.TreeAHGetText(Sender: TBaseVirtualTree; Node: PVirtualNode; Column: TColumnIndex; TextType: TVSTTextType; var CellText: string);
 var
  p: PNodeTData;
begin
  p := Sender.GetNodeData(Node);
  case Column of
   0: CellText := p.Item;
   1: CellText := p.x;
   2: CellText := p.y;
   3: CellText := p.z;
   4: CellText := p.d4;
  end;
end;

procedure TFormInclin.TreeAddToSelection(Sender: TBaseVirtualTree; Node: PVirtualNode);
begin
  lbInfo.Caption := PNodeExData(Tree.GetNodeData(Node)).XMNode.Attributes['INFO'];
  AttestatLabel.Caption := 'Аттестация';
end;

procedure TFormInclin.TreeGetText(Sender: TBaseVirtualTree; Node: PVirtualNode; Column: TColumnIndex; TextType: TVSTTextType; var CellText: string);
 var
  p: PNodeExData;
  procedure SetData(const path: string; const fmt: string = '');
   var
    V: Variant;
    r: IXMLNode;
  begin
    if path = '' then
     begin
      r := p.XMNode;
      if r.HasAttribute(fmt) then CellText := r.Attributes[fmt]
      else CellText := fmt;
      Exit;
     end
    else r := GetXNode(p.XMNode, Path);
    if not Assigned(r) then Exit;
    if r.HasAttribute(AT_VALUE) then V := r.Attributes[AT_VALUE];
    if not VarIsNull(V) then
     if (fmt <> '') then CellText := Format(fmt,[Double(V)])
     else CellText := V;
  end;
begin
  CellText := '';
  p := Sender.GetNodeData(Node);
  if not Assigned(p.XMNode) then Exit;
   case Column of
    0: SetData('', 'STEP');
    1: SetData('accel.X.CLC', fmtData);
    2: SetData('accel.Y.CLC', fmtData);
    3: SetData('accel.Z.CLC', fmtData);
    4: SetData('magnit.X.CLC', fmtData);
    5: SetData('magnit.Y.CLC', fmtData);
    6: SetData('magnit.Z.CLC', fmtData);
    7: SetData('accel.X.DEV', fmtData);
    8: SetData('accel.Y.DEV', fmtData);
    9: SetData('accel.Z.DEV', fmtData);
   10: SetData('magnit.X.DEV', fmtData);
   11: SetData('magnit.Y.DEV', fmtData);
   12: SetData('magnit.Z.DEV', fmtData);
   end;
end;

initialization
  RegisterClass(TSaveDialog);
  RegisterClass(TFormInclin);
 // TRegister.AddType<TFormInclin, IForm>.LiveTime(ltSingletonNamed);
finalization
//  GContainer.RemoveModel<TFormInclin>;
end.

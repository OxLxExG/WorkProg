unit MetrGK;

interface

 {$M+}

uses DeviceIntf, PluginAPI, ExtendIntf, RootIntf, debug_except, DockIForm, MetrForm, Container, Actns, ExcelImpl, XMLLua, VerySimple.Lua.Lib,
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics, Xml.XMLIntf,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, VirtualTrees, Vcl.StdCtrls, Vcl.ExtCtrls, Winapi.ActiveX,
  TeEngine, Series, TeeProcs, Chart, Vcl.Menus, VirtualTrees.Types,
  Vcl.PlatformDefaultStyleActnCtrls, Vcl.ActnPopup, AutoMetr.GK,
  VirtualTrees.BaseAncestorVCL, VirtualTrees.BaseTree, VirtualTrees.AncestorVCL;

type
  TFormGK = class(TFormMetrolog, IAutomatMetrology)
    PanelM: TPanel;
    lbInfo: TLabel;
    Tree: TVirtualStringTree;
    Chart: TChart;
    Series: TLineSeries;
    Splitter: TSplitter;
    lbAlpha: TLabel;
    SeriesLS: TFastLineSeries;
    procedure TreeAddToSelection(Sender: TBaseVirtualTree; Node: PVirtualNode);
    procedure TreeGetText(Sender: TBaseVirtualTree; Node: PVirtualNode; Column: TColumnIndex; TextType: TVSTTextType; var CellText: string);
  private
    FAutomatMetrology: TGKAuto;
//    procedure NParamClick(Sender: TObject);
    class constructor Create;
    class destructor Destroy;
//    class function CallMeth(Instance: TObject; ClassType: TClass; const MethodName: String; var Params: Variant): Variant;
    class procedure ExportGKToCalc(const TrrFile: string; NewTrr: IXMLNode; const GkNgk: string); overload; static;
  protected
    procedure Loaded; override;
    procedure DoStopAtt(AttNode: IXMLNode); override;
    procedure DoUpdateData(NewFileData: Boolean = False); override;
   const
    NICON = 93;
    class function ClassIcon: Integer; override;
    procedure DoUpdateAlpha();
    procedure DoUpdateChart();
    class function RootNodeName: string; virtual;
    class function TrrAttributeName: string; virtual;
    property AutomatMetrology: TGKAuto read FAutomatMetrology implements IAutomatMetrology;
  public
    destructor Destroy; override;
    [StaticAction('Новая калибровка ГК', 'Метрология', NICON, '0:Метрология.ГК')]
    class procedure DoCreateForm(Sender: IAction); override;
    class function MetrolMame: string; override;
    class function MetrolType: string; override;
  published
    class function ExportGKToCalc(L: lua_State): Integer; overload; cdecl; static;
  end;

  TFormGK_LS = class(TFormGK)
  protected
   const
    NICON = 94;
  public
    [StaticAction('Новая калибровка ГК (нмк)', 'Метрология', NICON, '0:Метрология.ГК:-1')]
    class procedure DoCreateForm(Sender: IAction); override;
    class function MetrolType: string; override;
  end;

  TFormNGK = class(TFormGK)
  protected
    procedure DoUpdateEtalonData(EtlNode: IXMLNode); override;
    class function ClassIcon: Integer; override;
    class function RootNodeName: string; override;
    class function TrrAttributeName: string; override;
   const
    NICON = 93;
  public
    [StaticAction('Новая калибровка НГК', 'Метрология', NICON, '0:Метрология.ННК:-1')]
    class procedure DoCreateForm(Sender: IAction); override;
    class function MetrolMame: string; override;
    class function MetrolType: string; override;
  end;

  TFormNGK_LS = class(TFormNGK)
  protected
   const
    NICON = 94;
  public
    [StaticAction('Новая калибровка НГК (нмк)', 'Метрология', NICON, '0:Метрология.ННК:-1')]
    class procedure DoCreateForm(Sender: IAction); override;
    class function MetrolType: string; override;
  end;
implementation

{$R *.dfm}

uses {MetrGK.CheckFormSetup,} tools, PatchCart;

{$REGION 'TFormGK'}
class constructor TFormGK.Create;
begin
//  TXmlScriptInner.RegisterMethods([
//  'procedure ExportGKToCalc(const TrrFile: string; NewTrr: variant; const GkNgk: string)'
//  ], CallMeth);
end;

class destructor TFormGK.Destroy;
begin
//  TXmlScriptInner.UnRegisterMethods(CallMeth);
end;

class function TFormGK.MetrolMame: string;
begin
  Result := 'ГК';
end;

class function TFormGK.MetrolType: string;
begin
  Result := 'TGK'
end;

//procedure TFormGK.NParamClick(Sender: TObject);
//begin
//  if TFormGKCheckSetup.Execute(GetMetr([MetrolType], FileData)) then
//     if TrrFile <> '' then FileData.OwnerDocument.SaveToFile(TrrFile)
//end;

//class function TFormGK.CallMeth(Instance: TObject; ClassType: TClass; const MethodName: String; var Params: Variant): Variant;
//begin
//  if MethodName = 'EXPORTGKTOCALC' then  ExportGKToCalc(Params[0], Params[1], Params[2])
//end;

class procedure TFormGK.ExportGKToCalc(const TrrFile: string; NewTrr: IXMLNode; const GkNgk: string);
 var
  root: variant;
begin
  if GkNgk = 'NGK' then  root := NewTrr.ChildNodes['TNGK'] else root := NewTrr.ChildNodes['TGK'];
  if not root.HasAttribute('DevName') or
     not NewTrr.ParentNode.ParentNode.HasAttribute(AT_SERIAL) then
     raise EBaseException.Create('Параметры метрологии не установлены');
  TThread.CreateAnonymousThread(procedure
   var
    v, st: Variant;
    i, n: Integer;
    r: IReport;
    Sheet, Range: Variant;
    procedure SetCell(const cel: string; data: string);
    begin
      Sheet.getCellRangeByName(cel).getCellByPosition(0,0).SetString(data);
    end;
  begin
    try
      CoInitialize(nil);
      r := GlobalCore as IReport;
      r.OpenDocument(ExtractFilePath(ParamStr(0))+'Devices\ReportGK1.ods');
      v := VarArrayCreate([0,9, 0,0], varVariant);
      Sheet := r.Document.GetSheets.getByName('Метрология ГК');
      for i := 1 to 10 do if GkNgk = 'NGK' then
       begin
        st := XToVar(GetXNode(NewTrr, 'TNGK.STEP'+i.ToString));
         v[i-1, 0] := Double(st.нгк.DEV.VALUE);
       end
      else
       begin
        st := XToVar(GetXNode(NewTrr, 'TGK.STEP'+i.ToString));
         v[i-1, 0] := Double(st.гк.DEV.VALUE);
       end;
      Range := Sheet.getCellRangeByName('B12:K12');
      Range.setDataArray(v);

      SetCell('E5', root.DevName);
      SetCell('G5', NewTrr.ParentNode.ParentNode.Attributes[AT_SERIAL]);
      SetCell('B5', root.TIME_ATT);
      SetCell('I34', root.Metrolog);

      if Boolean(root.Ready) then SetCell('G32', 'Прибор к эксплуатации годен')
      else SetCell('G32', 'Прибор к эксплуатации НЕ годен!!!');

      r.SaveAs(TrrFile);
      CoUnInitialize();
    except
     on E: Exception do TDebug.DoException(E);
    end;
  end).Start;
end;

class function TFormGK.ClassIcon: Integer;
begin
  Result := NICON
end;

class function TFormGK.RootNodeName: string;
begin
  Result := 'гк';
end;

class function TFormGK.TrrAttributeName: string;
begin
  Result := 'kGK';
end;

procedure TFormGK.DoUpdateChart;
 var
  pv: PVirtualNode;
  p: IXMLNode;
  r: IXMLNode;
  a,b: Double;
begin
  r := GetMetr([], GetFileOrDevData);
  Series.Clear;
  for pv in Tree.Nodes do
   begin
    p := PNodeExData(Tree.GetNodeData(pv)).XMNode;
    if Boolean(p.Attributes['EXECUTED']) then Series.AddXY(p.Attributes['RT'], p.ChildNodes[RootNodeName].ChildNodes[T_DEV].Attributes[AT_VALUE]);
   end;
  r := GetMetr([], GetFileOrDevData);
  SeriesLS.Clear;
  if not Assigned(r) then Exit;
  b := Double(r.Attributes[TrrAttributeName]);
  if r.HasAttribute('Delta') then a := r.Attributes['Delta'] else a := 0;
  SeriesLS.AddXY(0, a);
  SeriesLS.AddXY(200, 200/b+a);
end;

procedure TFormGK.DoUpdateAlpha;
 const
  ALPHA_FORMAT ='  α= %1.6f мкр/ч/имп';
 var
  r: IXMLNode;
begin
  r := GetMetr([], GetFileOrDevData);
  if Assigned(r) then lbAlpha.Caption := Format(ALPHA_FORMAT, [Double(r.Attributes[TrrAttributeName])])
  else lbAlpha.Caption := '';
end;

destructor TFormGK.Destroy;
begin
  FAutomatMetrology.Free;
  inherited;
end;

class procedure TFormGK.DoCreateForm(Sender: IAction);
begin
  inherited;
end;

procedure TFormGK.DoStopAtt(AttNode: IXMLNode);
begin
  inherited;
  DoUpdateAlpha;
  DoUpdateChart;
end;

procedure TFormGK.DoUpdateData(NewFileData: Boolean = False);
begin
  inherited;
  DoUpdateAlpha;
  DoUpdateChart;
end;

class function TFormGK.ExportGKToCalc(L: lua_State): Integer;
begin
  //const TrrFile: string; NewTrr: IXMLNode; const GkNgk: string);
  ExportGKToCalc(string(lua_tostring(L,1)), TXMLLua.XNode(L,2), string(lua_tostring(L,3)));
  Result := 0;
end;

procedure TFormGK.Loaded;
begin
  SetupStepTree(Tree);
  inherited;
  AttestatPanel.Align := alBottom;
//  AddToNCMenu('-');
//  AddToNCMenu('Параметры метрологии...', NParamClick);
  FAutomatMetrology := TGKAuto.Create(Self);
  FAutomatMetrology.Report := AutoReport;
  PatchTeeCart(chart);
end;

procedure TFormGK.TreeAddToSelection(Sender: TBaseVirtualTree; Node: PVirtualNode);
begin
  lbInfo.Caption := PNodeExData(Tree.GetNodeData(Node)).XMNode.Attributes['INFO'];
  AttestatLabel.Caption := 'Аттестация';
end;

procedure TFormGK.TreeGetText(Sender: TBaseVirtualTree; Node: PVirtualNode; Column: TColumnIndex; TextType: TVSTTextType; var CellText: string);
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
   case Column of
    0: SetData('', 'STEP');
    1: SetData('', 'DISTANCE');
    2: SetData('', 'RT');
    3: SetData(RootNodeName+'.DEV', AT_VALUE, '%1.0f');
    4: SetData(RootNodeName+'.CLC', AT_VALUE, '%1.2f');
    5: SetData('', 'DELTA', '%1.2f');
   end;
end;
{$ENDREGION}

{ TFormNGK }

class function TFormNGK.ClassIcon: Integer;
begin
  Result := NICON
end;

class function TFormNGK.MetrolMame: string;
begin
  Result := 'ННК'
end;

class function TFormNGK.MetrolType: string;
begin
  Result := 'TNGK'
end;

class function TFormNGK.RootNodeName: string;
begin
  Result := 'нгк';
end;

class function TFormNGK.TrrAttributeName: string;
begin
  Result := 'kNGK';
end;

class procedure TFormNGK.DoCreateForm(Sender: IAction);
begin
  inherited;
end;

procedure TFormNGK.DoUpdateEtalonData(EtlNode: IXMLNode);
 var
  n: IXMLNode;
begin
  n := EtlNode.AttributeNodes.FindNode('kNK1');
  if Assigned(n) then EtlNode.AttributeNodes.Remove(n);
  n := EtlNode.AttributeNodes.FindNode('kNK2');
  if Assigned(n) then EtlNode.AttributeNodes.Remove(n);
end;

{ TFormGK_LS }

class procedure TFormGK_LS.DoCreateForm(Sender: IAction);
begin
  inherited;
end;

class function TFormGK_LS.MetrolType: string;
begin
  Result := 'TGK_LS'
end;

{ TFormNGK_LS }

class procedure TFormNGK_LS.DoCreateForm(Sender: IAction);
begin
  inherited;
end;

class function TFormNGK_LS.MetrolType: string;
begin
  Result := 'TNGK_LS'
end;

initialization
  RegisterClass(TFormNGK);
  TRegister.AddType<TFormNGK, IForm>.LiveTime(ltSingletonNamed);
  RegisterClass(TFormGK);
  TRegister.AddType<TFormGK, IForm>.LiveTime(ltSingletonNamed);
  RegisterClass(TFormGK_LS);
  TRegister.AddType<TFormGK_LS, IForm>.LiveTime(ltSingletonNamed);
  RegisterClass(TFormNGK_LS);
  TRegister.AddType<TFormNGK_LS, IForm>.LiveTime(ltSingletonNamed);
finalization
  GContainer.RemoveModel<TFormNGK>;
  GContainer.RemoveModel<TFormGK>;
  GContainer.RemoveModel<TFormGK_LS>;
  GContainer.RemoveModel<TFormNGK_LS>;
end.

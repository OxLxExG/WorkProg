unit MetrCreateForm;

interface

{$I Script.inc}

uses RootIntf, PluginAPI, ExtendIntf, DockIForm, DeviceIntf, debug_except, Container, Actns,   VirtualTrees.Types,
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.ExtCtrls,
  VirtualTrees, Vcl.StdCtrls, Vcl.Menus, Vcl.PlatformDefaultStyleActnCtrls, Vcl.ActnPopup, Vcl.ComCtrls, Xml.XMLDoc, Xml.XMLIntf,
  {$IFDEF USE_LUA_SCRIPT}
    ScinLua, XMLLua,
  {$ELSE}
    JvExControls, JvEditorCommon, JvEditor, JvHLEditor,
  {$ENDIF}
   RootImpl, VirtualTrees.BaseAncestorVCL, VirtualTrees.BaseTree,
  VirtualTrees.AncestorVCL;

type
  PNodeExData = ^TNodeExData;
  TNodeExData = record
    XMNode: IXMLNode;
    IsSimple: Boolean;
    IsRoot: Boolean;
  end;

  TFormMetr = class(TDockIForm)
    ppM: TPopupActionBar;
    N3: TMenuItem;
    NOpen: TMenuItem;
    NSave: TMenuItem;
    N2: TMenuItem;
    NCopy: TMenuItem;
    NCat: TMenuItem;
    N7: TMenuItem;
    Splitter1: TSplitter;
    NEdit: TMenuItem;
    ppTab: TPopupActionBar;
    Nexp: TMenuItem;
    MenuItem4: TMenuItem;
    NDel: TMenuItem;
    NImp: TMenuItem;
    NSetup: TMenuItem;
    SaveDialog: TSaveDialog;
    OpenDialog: TOpenDialog;
    NApply: TMenuItem;
    Nexe: TMenuItem;
    Tree: TVirtualStringTree;
    pc: TCPageControl;
    NRename: TMenuItem;
    N1: TMenuItem;
    NCompile: TMenuItem;
    procedure NOpenClick(Sender: TObject);
    procedure NSaveClick(Sender: TObject);
    procedure NCopyClick(Sender: TObject);
    procedure NCatClick(Sender: TObject);
    procedure NEditClick(Sender: TObject);
    procedure NexpClick(Sender: TObject);
    procedure NImpClick(Sender: TObject);
    procedure NSetupClick(Sender: TObject);
    procedure NDelClick(Sender: TObject);
    procedure TreeGetText(Sender: TBaseVirtualTree; Node: PVirtualNode; Column: TColumnIndex; TextType: TVSTTextType; var CellText: string);
    procedure NApplyClick(Sender: TObject);
    procedure edMetrChange(Sender: TObject);
    procedure NexeClick(Sender: TObject);
    procedure TreeCompareNodes(Sender: TBaseVirtualTree; Node1, Node2: PVirtualNode; Column: TColumnIndex; var Result: Integer);
    procedure TreeFindEnter(Sender: TObject);
    procedure NRenameClick(Sender: TObject);
    procedure pcContextPopup(Sender: TObject; MousePos: TPoint; var Handled: Boolean);
    procedure ppTabPopup(Sender: TObject);
    procedure ppMPopup(Sender: TObject);
    procedure NCompileClick(Sender: TObject);
  private
    FFileMet: string;
    Ftrr, Edited: IXMLNode;
    FPvEdited: PVirtualNode;

    procedure smChange(Sender: TObject);
    procedure ClearTree;
    procedure ClearEdit;
    procedure Changed(Flag: Boolean);
    function AddPage(const PName, PCapt, SmInfo: string): TTabSheet;
    function Memo(Tab: TTabSheet): TStrings;
    function StatusBar(Tab: TTabSheet): TMemo;
    procedure LoadMet(const FileName: string);
    procedure UpdateTree;
    procedure Apply();
  protected
    class function ClassIcon: Integer; override;
    procedure Loaded; override;
   const
    NICON = 249;
  public
    [StaticAction('Редактор метрологии приборов', 'Отладочные', NICON, '0:Показать.Отладочные:0')]
    class procedure DoCreateForm(Sender: IAction); override;
    destructor Destroy; override;
  end;

//var
//  FormMetr: TFormMetr;

implementation

{$R *.dfm}

uses tools;

const
 NL = #$D#$A;

   {$IFDEF USE_LUA_SCRIPT}
   CFILEMET = 'Devices\TRRLua.xml';
   SMI_SETUP =
              '--alg, t - псевдо таблицы' + NL +
              'function TrrSetup (alg, t)' + NL +
              '' + NL +
              '   print("^access to TrrSetup ");' + NL +
              '' + NL +
              '  local m = AddMetrology(alg.a.b.c["Олег"], alg, "AY", "G");' + NL +
              '' + NL +
              '  print(m.TITLE, m.EU, m.TYPE);' + NL +
              '' + NL +
              ' -- ANSI !!!!!' + NL +
              '  alg.a.b.c["Олег"].AT_VALUE = 12.1;' + NL +
              ' -- alg.a.b.c["Вася"].AT_VALUE = 12.1;' + NL +
              '' + NL +
              '  local st = alg.a.b.c["Олег"];' + NL +
              '' + NL +
              '' + NL +
              '  print(st.AT_VALUE);' + NL +
              '' + NL +
              '  t.a.b.c["Метрология"].AT_VALUE = "ывапрролпрлгьегнэ"' + NL +
              '' + NL +
              '    st = t.a.b.c["Метрология"];' + NL +
              '' + NL +
              '  print(st.AT_VALUE);' + NL +
              'end';
  {$ELSE}
  CFILEMET = 'Devices\Trr.xml';
  SMI_SETUP = '{ procedure (v: variant);' + NL +
             '  v - корневой элемент метрологии модуля или данных модуля (режим информации)' + NL +
             '  например Inclin, Dtr - корневой элемент редактируемого модуля }' + NL +
             'begin' + NL +
             'end;';
  {$ENDIF}

 SMI_INFO =  '%s';

 MT_EXE = 'EXEC_METR';
 MT_STP = 'SETUP_METR';
 SMPF   = 'SIMPLE_FORMAT';
 IMPT   = 'IMPORT';
 EXPT   = 'EXPORT';

{ TFormMetr }

procedure TFormMetr.Changed(Flag: Boolean);
begin
  NApply.Enabled := Flag;
end;

class function TFormMetr.ClassIcon: Integer;
begin
  Result := NICON;
end;

procedure TFormMetr.ClearEdit;
 var
  i: Integer;
begin
  if NApply.Enabled and (MessageDlg('(Метрологии Редактор) Сохранить изменения?', mtWarning, [mbYes, mbNo], 0)  = mrYes) then NApplyClick(Self);
  Edited := nil;
  FPvEdited := nil;
  for i := pc.PageCount-1 downto 0 do pc.Pages[i].Free;
  Changed(False);
end;

procedure TFormMetr.ClearTree;
 var
  pv: PVirtualNode;
begin
  for pv in Tree.Nodes do PNodeExData(Tree.GetNodeData(pv)).XMNode := nil;
  Tree.Clear;
end;

destructor TFormMetr.Destroy;
begin
  ClearEdit;
  ClearTree;
  inherited;
end;

class procedure TFormMetr.DoCreateForm(Sender: IAction);
begin
  GetUniqueForm('GlobalCreateMetrologyForm');
end;

procedure TFormMetr.edMetrChange(Sender: TObject);
begin
  if Assigned(Edited) then Changed(True);
end;

procedure TFormMetr.Loaded;
begin
  inherited;
  Tree.NodeDataSize := SizeOf(TNodeExData);
  FFileMet := ExtractFilePath(ParamStr(0))+CFILEMET;
  LoadMet(FFileMet);
//  AddToNCMenu('Откомпилировать экран', NCompileClick, 0);
//  AddToNCMenu('-', nil, 1);
end;

procedure TFormMetr.UpdateTree;
 var
  n,t: IXMLNode;
  rt,md,trr: PVirtualNode;
  edr, ed: PNodeExData;
begin
  Tree.BeginUpdate;
  try
   ClearTree;
   for n in XEnum(Ftrr) do
    begin
     rt := Tree.AddChild(nil);
     Include(rt.States, vsExpanded);
     edr := Tree.GetNodeData(rt);
     edr.XMNode := n;
     edr.IsRoot := True;
     edr.IsSimple := n.NodeName = SMPF;

     md := Tree.AddChild(rt);
     Include(md.States, vsExpanded);
     edr := Tree.GetNodeData(md);
     edr.XMNode := n.ChildNodes['MODEL'];
     edr.IsRoot := True;
     edr.IsSimple := True;

     for t in XEnum(n.ChildNodes['MODEL']) do
      begin
       ed := Tree.GetNodeData(Tree.AddChild(md));
       ed.XMNode := t;
       ed.IsSimple := False;
       ed.IsRoot := False;
      end;

     trr := Tree.AddChild(rt);
     Include(trr.States, vsExpanded);
     edr := Tree.GetNodeData(trr);
     edr.XMNode := n.ChildNodes['TRR_MODEL'];
     edr.IsRoot := True;
     edr.IsSimple := True;

     for t in XEnum(n.ChildNodes['TRR_MODEL']) do
      begin
       ed := Tree.GetNodeData(Tree.AddChild(trr));
       ed.XMNode := t;
       ed.IsSimple := False;
       ed.IsRoot := False;
      end;
    end;
   Tree.SortTree(0, sdAscending);
  finally
   Tree.EndUpdate;
  end;
end;

procedure TFormMetr.LoadMet(const FileName: string);
 var
  GDoc: IXMLDocument;
begin
  if FFileMet = '' then Exit;
  GDoc := NewXMLDocument();
  GDoc.LoadFromFile(FileName);
  FTrr := GDoc.DocumentElement;
  ClearEdit;
  UpdateTree;
end;

function TFormMetr.Memo(Tab: TTabSheet): TStrings;
begin
  {$IFDEF USE_LUA_SCRIPT}
  Result := TScinLua(Tab.FindChildControl('SyntaxMemo')).Lines;
  {$ELSE}
  Result := TJvHLEditor(Tab.FindChildControl('SyntaxMemo')).Lines;
  {$ENDIF}
end;

procedure TFormMetr.Apply;
 var
  t: TTabSheet;
  ed: PNodeExData;
  i: Integer;
begin
  if not Assigned(Edited) then Exit;
  ed := Tree.GetNodeData(FPvEdited);
  Edited.AttributeNodes.Clear;
  if not ed.IsSimple then
   begin
    Edited.ChildNodes[IMPT].AttributeNodes.Clear;
    Edited.ChildNodes[EXPT].AttributeNodes.Clear;
   end;
  for i := 1 to pc.PageCount-1 do
   begin
    t := pc.Pages[i];
    if Pos(IMPT, t.Name) > 0 then
      Edited.ChildNodes[IMPT].Attributes[IMPT + Edited.ChildNodes[IMPT].AttributeNodes.Count.ToString] := Memo(t).Text
    else if Pos(EXPT, t.Name) > 0 then
      Edited.ChildNodes[EXPT].Attributes[EXPT + Edited.ChildNodes[EXPT].AttributeNodes.Count.ToString] := Memo(t).Text
    else Edited.Attributes[t.Name] := Memo(t).Text;
   end;
end;

procedure TFormMetr.NEditClick(Sender: TObject);
 var
  pv: PVirtualNode;
  n: IXMLNode;
  ed: PNodeExData;
  i: Integer;
begin
  for pv in Tree.SelectedNodes do
   begin
    n := PNodeExData(Tree.GetNodeData(pv)).XMNode;
    if (n <> Edited) and NApply.Enabled then
    case MessageDlg('Сохранить изменения?', mtWarning, [mbYes, mbNo, mbCancel], 0) of
     mrYes: NApplyClick(Self);
     mrCancel: Exit;
    end;
    ClearEdit;
    Edited := n;
    FPvEdited := pv;
    ed := Tree.GetNodeData(FPvEdited);
    AddPage('info', 'Информация', Format(SMI_INFO ,[Edited.NodeName]));
    if n.HasAttribute(MT_EXE) then AddPage(MT_EXE, 'Выполнение', n.Attributes[MT_EXE]);
    if n.HasAttribute(MT_STP) then AddPage(MT_STP, 'Установки', n.Attributes[MT_STP]);
    if not ed.IsSimple then for i := 0 to n.ChildNodes[IMPT].AttributeNodes.Count-1 do
        AddPage(n.ChildNodes[IMPT].AttributeNodes[i].NodeName, 'Импорт' + (i+1).ToString, n.ChildNodes[IMPT].AttributeNodes[i].NodeValue);
    if not ed.IsSimple then for i := 0 to n.ChildNodes[EXPT].AttributeNodes.Count-1 do
       AddPage(n.ChildNodes[EXPT].AttributeNodes[i].NodeName, 'Экспорт' + (i+1).ToString, n.ChildNodes[EXPT].AttributeNodes[i].NodeValue);
    Changed(False);
   end;
end;

procedure TFormMetr.NApplyClick(Sender: TObject);
begin
  Apply;
  FTrr.OwnerDocument.SaveToFile(FFileMet);
  Changed(False);
end;

procedure TFormMetr.NCatClick(Sender: TObject);
 var
  p: IXMLNode;
  pv: PVirtualNode;
  n: PNodeExData;
begin
  for pv in Tree.SelectedNodes do if MessageDlg('Удалить?', mtWarning, [mbYes, mbNo], 0) = mrYes then
   begin
    n := PNodeExData(Tree.GetNodeData(pv));
    if n.XMNode = Edited then ClearEdit;
    p := n.XMNode.ParentNode;
    p.ChildNodes.Remove(n.XMNode);
    UpdateTree;
    Changed(True);
   end;
end;

procedure TFormMetr.NRenameClick(Sender: TObject);
 var
  c: IXMLNode;
  pv: PVirtualNode;
begin
  for pv in Tree.SelectedNodes do
   begin
    c := PNodeExData(Tree.GetNodeData(pv)).XMNode;
    RenameXMLNode(c, InputBox('Переименование', 'Новое имя', c.NodeName));
    UpdateTree;
    Changed(True);
   end;
end;


procedure TFormMetr.NCompileClick(Sender: TObject);
 var
  s: IXMLScript;
begin
  {$IFDEF USE_LUA_SCRIPT}
   TScinLua(pc.ActivePage.FindChildControl('SyntaxMemo')).IndicatorClear;
   {$ENDIF}
  s := (GlobalCore as IXMLScriptFactory).Get(nil);
  s.Lines.Text := 'function _CompileTmp(v,t)'+  #$D#$A+ Memo(pc.ActivePage).Text + #$D#$A + 'end' + #$D#$A + #$D#$A;
  if s.Compile then StatusBar(pc.ActivePage).Lines.Text := 'Compile OK'
  else
    begin
     StatusBar(pc.ActivePage).Lines.Text := s.ErrorMsg;
     {$IFDEF USE_LUA_SCRIPT}
      TScinLua(pc.ActivePage.FindChildControl('SyntaxMemo')).ErrorShow(s.ErrorPos);
     {$ENDIF}
    end;
end;

procedure TFormMetr.NCopyClick(Sender: TObject);
 var
  c,n, p: IXMLNode;
  i: Integer;
  pv: PVirtualNode;
begin
  for pv in Tree.SelectedNodes do
   begin
    c := PNodeExData(Tree.GetNodeData(pv)).XMNode;
    p := c.ParentNode;
    i := p.ChildNodes.IndexOf(c);
    n := c.CloneNode(True);
    p.ChildNodes.Insert(i, n);
    UpdateTree;
    Changed(True);
   end;
end;

procedure TFormMetr.NOpenClick(Sender: TObject);
begin
  if NApply.Enabled then
   case MessageDlg('Сохранить изменения?', mtWarning, [mbYes, mbNo, mbCancel], 0) of
    mrYes: NApplyClick(Self);
    mrCancel: Exit;
   end;
  OpenDialog.InitialDir := ExtractFilePath(ParamStr(0))+'Devices\';
  if OpenDialog.Execute(Handle) then
   begin
    FFileMet := OpenDialog.FileName;
    LoadMet(FFileMet);
    Changed(False);
   end;
end;

procedure TFormMetr.NSaveClick(Sender: TObject);
begin
  SaveDialog.InitialDir := ExtractFilePath(ParamStr(0))+'Devices\';
  if SaveDialog.Execute(Handle) then
   begin
    FFileMet := SaveDialog.FileName;
    Apply;
    FTrr.OwnerDocument.SaveToFile(FFileMet);
    Changed(False);
   end;
end;

procedure TFormMetr.NexeClick(Sender: TObject);
 var
  t: TTabSheet;
begin
  t := TTabSheet(pc.FindChildControl(MT_EXE));
  if Assigned(t) then pc.ActivePage := t
  else AddPage(MT_EXE, 'Выполнение', SMI_SETUP);
end;

procedure TFormMetr.NSetupClick(Sender: TObject);
 var
  t: TTabSheet;
begin
  t := TTabSheet(pc.FindChildControl(MT_STP));
  if Assigned(t) then pc.ActivePage := t
  else AddPage(MT_STP, 'Установки', SMI_SETUP);
end;

procedure TFormMetr.NexpClick(Sender: TObject);
 var
  n: Integer;
begin
  n := 0;
  while Assigned(pc.FindChildControl(EXPT + n.ToString)) do Inc(n);
  AddPage(EXPT + n.ToString, 'Экспорт'+ (n+1).ToString, SMI_SETUP);
end;

procedure TFormMetr.NImpClick(Sender: TObject);
 var
  n: Integer;
begin
  n := 0;
  while Assigned(pc.FindChildControl(IMPT + n.ToString)) do Inc(n);
  AddPage(IMPT + n.ToString, 'Импорт'+ (n+1).ToString, SMI_SETUP);
end;

procedure TFormMetr.NDelClick(Sender: TObject);
begin
  pc.ActivePage.Free;
  Changed(True);
end;

function TFormMetr.AddPage(const PName, PCapt, SmInfo: string): TTabSheet;
 var
  {$IFDEF USE_LUA_SCRIPT}
    sm: TScinLua;
  {$ELSE}
    sm: TJvHLEditor;
  {$ENDIF}
begin
  Result := TTabSheet.Create(pc);
  Result.Tag := $12345678;
  Result.PageControl := pc;
  Result.Name := PName;
  Result.Caption := PCapt;
  with TMemo.Create(Result) do
   begin
    Name := 'StatusBar';
    Parent := Result;
    Align := alBottom;
    ReadOnly := True;
    Text := '';
   end;
  with TSplitter.Create(Result) do
  begin
    Parent := Result;
    Align := alBottom;
  end;
  {$IFDEF USE_LUA_SCRIPT}
    sm := TScinLua.Create(Result);
    sm.Parent := Result;
    sm.SetKeyWords(1, TXMLLua.GetRegisteredLuaMethodsNames);
  {$ELSE}
    sm := TJvHLEditor.Create(Result);
    sm.Parent := Result;
  {$ENDIF}
  sm.Name := 'SyntaxMemo';
  sm.Align := alClient;
//  sm.CommentAttr.Color := clRed;
//  sm.KeywordAttr.Color := clNavy;
   sm.OnChange := smChange;
   sm.Lines.Text:= SmInfo;
  Changed(True);
end;

procedure TFormMetr.pcContextPopup(Sender: TObject; MousePos: TPoint; var Handled: Boolean);
 var
  i: integer;
begin
  with Sender as TPageControl do
   begin
    if [htOnItem] * GetHitTestInfoAt(MousePos.X, MousePos.Y) <> [] then
     begin
      i := IndexOfTabAt(MousePos.X, MousePos.Y);
      if i >= 0 then
       begin
        ActivePage := Pages[i];
        NDel.Enabled := i > 0;
        NCompile.Enabled := i > 0;
       end;
      PopupMenu := ppTab;
     end
    else PopupMenu := nil;
   end;
end;

procedure TFormMetr.ppMPopup(Sender: TObject);
 var
  pv: PVirtualNode;
  procedure seten(f: Boolean);
  begin
    NEdit.Enabled := F;
    NCat.Enabled := F;
    NRename.Enabled := F;
    NCopy.Enabled := F;
  end;
begin
  for pv in Tree.SelectedNodes do seten(not PNodeExData(Tree.GetNodeData(pv)).IsSimple)
end;

procedure TFormMetr.ppTabPopup(Sender: TObject);
  var
   ed: PNodeExData;
begin
  ed := Tree.GetNodeData(FPvEdited);
  Nexp.Enabled := not ed.IsSimple;
  NImp.Enabled := not ed.IsSimple;
end;

procedure TFormMetr.smChange(Sender: TObject);
begin
  Changed(True);
end;

function TFormMetr.StatusBar(Tab: TTabSheet): TMemo;
begin
  Result := TMemo(Tab.FindChildControl('StatusBar'));
end;

procedure TFormMetr.TreeCompareNodes(Sender: TBaseVirtualTree; Node1, Node2: PVirtualNode; Column: TColumnIndex; var Result: Integer);
 var
  n1, n2: IXMLNode;
  function Tostr(n: IXMLNode; const atr: string): string;
  begin
    if n.HasAttribute(atr) then Result := n.Attributes[atr]
    else Result := '';
  end;
begin
  n1 := PNodeExData(Sender.GetNodeData(Node1)).XMNode;
  n2 := PNodeExData(Sender.GetNodeData(Node2)).XMNode;
  if not Assigned(n1) or not Assigned(n2) then Exit;
  Result := CompareStr(Tostr(n1, 'NODE_NAME'), Tostr(n2, 'NODE_NAME'));
  if Result = 0 then Result := CompareStr(Tostr(n1, 'NODE_METR'), Tostr(n2, 'NODE_METR'));
end;

procedure TFormMetr.TreeFindEnter(Sender: TObject);
begin
  TDebug.Log(Sender.ClassName);
end;

procedure TFormMetr.TreeGetText(Sender: TBaseVirtualTree; Node: PVirtualNode; Column: TColumnIndex; TextType: TVSTTextType; var CellText: string);
 var
  n: IXMLNode;
begin
  CellText := '';
  n := PNodeExData(Sender.GetNodeData(Node)).XMNode;
  if not Assigned(n) then Exit;
  CellText := n.NodeName;
end;

initialization
  RegisterClass(TFormMetr);
  TRegister.AddType<TFormMetr, IForm>.LiveTime(ltSingletonNamed);
finalization
  GContainer.RemoveModel<TFormMetr>;
end.

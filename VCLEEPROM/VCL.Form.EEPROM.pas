unit VCL.Form.EEPROM;

interface

uses Container, tools, XMLLua.EEPROM,  Xml.XMLDoc,  Math, Parser, system.IOUtils,   VirtualTrees.Types,
  RootIntf, DeviceIntf, PluginAPI, DockIForm, ExtendIntf, RootImpl, debug_except, FileCachImpl, VirtualTrees.Colors,
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics, Xml.XMLIntf, System.TypInfo,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls, Vcl.ComCtrls, VirtualTrees, Vcl.Menus,
  VirtualTrees.BaseAncestorVCL, VirtualTrees.BaseTree, VirtualTrees.AncestorVCL,
  Vcl.ExtCtrls;

type
  PFromNodeData = ^TFromNodeData;
  TFromNodeData = record
    FromNode: IXMLNode;
    userPsw: string;
  end;

  PNodeExData = ^TNodeExData;
  TNodeExData = record
   // ParamType:
   // ParamName: string;
   ///   eeprom                 eeprom                   Метрология
   /// [xmlnode(path.Node); attr(path.Node.DEV.VALUE); attr(path.Node) ]
    ColumnValue: TArray<IInterface>;
    ColumnNode: TArray<IInterface>;
    FEdited: Boolean;
    function AsText(Col: Integer): string;
    function AsColor(Col: Integer): TColor;
    function Editable(Col: Integer): boolean;
    procedure FromText(Col: Integer; const NewData: string);
  end;

  EFrmDlgEeprom = class(EBaseException);
  TFormDlgEeprom = class(TDialogIForm, IDialog, IDialog<IXMLNode, TDialogResult>)
    btRead: TButton;
    btWrite: TButton;
    btExit: TButton;
    st: TStatusBar;
    ppm: TPopupMenu;
    EEPROM1: TMenuItem;
    File1: TMenuItem;
    Load1: TMenuItem;
    nPasw: TMenuItem;
    Tree: TVirtualStringTree;
    Panel1: TPanel;
    procedure btReadClick(Sender: TObject);
    procedure btWriteClick(Sender: TObject);
    procedure TreeGetText(Sender: TBaseVirtualTree; Node: PVirtualNode; Column: TColumnIndex; TextType: TVSTTextType; var CellText: string);
    procedure TreeCreateEditor(Sender: TBaseVirtualTree; Node: PVirtualNode; Column: TColumnIndex; out EditLink: IVTEditLink);
    procedure TreeEditing(Sender: TBaseVirtualTree; Node: PVirtualNode; Column: TColumnIndex; var Allowed: Boolean);
    procedure TreePaintText(Sender: TBaseVirtualTree; const TargetCanvas: TCanvas; Node: PVirtualNode; Column: TColumnIndex;
      TextType: TVSTTextType);
    procedure TreeGetNodeDataSize(Sender: TBaseVirtualTree; var NodeDataSize: Integer);
    procedure ppmPopup(Sender: TObject);
    procedure EEPROM1Click(Sender: TObject);
    procedure File1Click(Sender: TObject);
    procedure Load1Click(Sender: TObject);
    procedure nPaswClick(Sender: TObject);
    procedure btExitClick(Sender: TObject);
  private
    FFromNodeDatas:TArray<TFromNodeData>;
    FEditData: PNodeExData;
    FEditNode: PVirtualNode;
    FRes: TDialogResult;
    FModul, Feep, Fmetr: IXMLNode;
    FAddr: Integer;
    FC_MetrologyChange: string;
    FC_MetaDataOK: boolean;
    function PaswChecked(fromNode: IXMLNode): Boolean;
    function PaswAllChecked: Boolean;
    procedure PaswSet(fromNode: IXMLNode; const psw: string);
    function GetDevice: IEepromDevice;
    procedure ClearTree;
    procedure InitTree;
    function GetMetrNode(eepNode: IXMLNode): IXMLNode;
    procedure NCopyMetrClick(Sender: TObject);
//    procedure NCmpMetrClick(Sender: TObject);
    procedure SetC_MetrologyChange(const Value: string);
    procedure SetC_MetaDataOK(const Value: boolean);
    procedure SaveEEprom(FrootEEP: IXMLNode);
  protected
    function GetInfo: PTypeInfo; override;
    function Execute(Eep: IXMLNode; Res: TDialogResult): Boolean;
    procedure Loaded; override;
    property Dev: IEepromDevice read GetDevice;
  public
    { Public declarations }
    property C_MetrologyChange: string read FC_MetrologyChange write SetC_MetrologyChange;
    property C_MetaDataOK: boolean read FC_MetaDataOK write SetC_MetaDataOK;
  end;


implementation

{$R *.dfm}

{$REGION 'TEditor'}

type
  TEditor = class(TIObject, IVTEditLink)
  private
    FEdit: TWinControl;        // One of the property editor classes.
    FTree: TVirtualStringTree; // A back reference to the tree calling.
    FNode: PVirtualNode;       // The node being edited.
    FData: PNodeExData;
    FColumn: Integer;          // The column of the node being edited.
    procedure EditKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure EditKeyUp(Sender: TObject; var Key: Word; Shift: TShiftState);
  protected
    function BeginEdit: Boolean; stdcall;
    function CancelEdit: Boolean; stdcall;
    function EndEdit: Boolean; stdcall;
    function GetBounds: TRect; stdcall;
    function PrepareEdit(Tree: TBaseVirtualTree; Node: PVirtualNode; Column: TColumnIndex): Boolean; stdcall;
    procedure ProcessMessage(var Message: TMessage); stdcall;
    procedure SetBounds(R: TRect); stdcall;
  public
    destructor Destroy; override;
  end;

destructor TEditor.Destroy;
begin
  //FEdit.Free; casues issue #357. Fix:
  if FEdit.HandleAllocated then PostMessage(FEdit.Handle, CM_RELEASE, 0, 0);
  inherited;
end;

procedure TEditor.EditKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
var
  CanAdvance: Boolean;
begin
  CanAdvance := true;
  case Key of
    VK_ESCAPE:
      begin
        Key := 0;//ESC will be handled in EditKeyUp()
      end;
    VK_RETURN:
      if CanAdvance then
      begin
        FTree.EndEditNode;
        Key := 0;
      end;
    VK_UP,
    VK_DOWN:
      begin
        // Consider special cases before finishing edit mode.
        CanAdvance := Shift = [];
{        if FEdit is TComboBox then
          CanAdvance := CanAdvance and not TComboBox(FEdit).DroppedDown;
        if FEdit is TDateTimePicker then
          CanAdvance :=  CanAdvance and not TDateTimePicker(FEdit).DroppedDown;
}
        if CanAdvance then
        begin
          // Forward the keypress to the tree. It will asynchronously change the focused node.
          PostMessage(FTree.Handle, WM_KEYDOWN, Key, 0);
          Key := 0;
        end;
      end;
  end;
end;

procedure TEditor.EditKeyUp(Sender: TObject; var Key: Word; Shift: TShiftState);
begin
  case Key of
    VK_ESCAPE:
      begin
        FTree.CancelEditNode;
        Key := 0;
      end;//VK_ESCAPE
  end;//case
end;

function TEditor.BeginEdit: Boolean;
begin
  Result := True;
  FEdit.Show;
  FEdit.SetFocus;
end;

function TEditor.CancelEdit: Boolean;
begin
  Result := True;
  FEdit.Hide;
end;

function TEditor.EndEdit: Boolean;
begin
  Result := True;
  FData.FromText(FColumn, TEdit(FEdit).Text);
  FEdit.Hide;
  FTree.SetFocus;
end;

function TEditor.GetBounds: TRect;
begin
  Result := FEdit.BoundsRect;
end;

function TEditor.PrepareEdit(Tree: TBaseVirtualTree; Node: PVirtualNode; Column: TColumnIndex): Boolean;
begin
  Result := True;
  FTree := Tree as TVirtualStringTree;
  FNode := Node;
  FColumn := Column;
  FData := FTree.GetNodeData(FNode);
  // determine what edit type actually is needed
  FEdit.Free;
  FEdit := nil;
  FEdit := TEdit.Create(nil);
  with FEdit as TEdit do
  begin
    Visible := False;
    Parent := Tree;
    Text := FData.AsText(FColumn);
    OnKeyDown := EditKeyDown;
    OnKeyUp := EditKeyUp;
  end;
end;

procedure TEditor.ProcessMessage(var Message: TMessage);
begin
  FEdit.WindowProc(Message);
end;

procedure TEditor.SetBounds(R: TRect);
var
  Dummy: Integer;
begin
  // Since we don't want to activate grid extensions in the tree (this would influence how the selection is drawn)
  // we have to set the edit's width explicitly to the width of the column.
  FTree.Header.Columns.GetColumnBounds(FColumn, Dummy, R.Right);
  FEdit.BoundsRect := R;
end;
{$ENDREGION}


{ TNodeExData }
var
  FReadedFlag: Boolean;

function TNodeExData.AsColor(Col: Integer): TColor;
 var
  e, m: IXMLNode;
begin
  Result := clThWindowTextNormal;
  if (col = 0) and Supports(ColumnValue[0], IXMLNode, e) then
   begin
    if e.HasAttribute(AT_FROM) then Exit(ColorCorrect(clBlue));
   end;
  if (Length(ColumnValue) < 4) and (col <> 1) then Exit;
  if not FReadedFlag then Result := clThWindowTextDisabled;
  if FEdited then Result := clWebBrown;

  if Supports(ColumnValue[1], IXMLNode, e) and Supports(ColumnValue[3], IXMLNode, m) then
   begin
    if (Trim(e.NodeValue) <>'') and (Trim(m.NodeValue) <>'') then
     begin
      var ae := string(e.NodeValue).Split([' '], TStringSplitOptions.ExcludeEmpty);
      var am := string(m.NodeValue).Split([' '], TStringSplitOptions.ExcludeEmpty);
      if Length(ae) <> Length(am) then Result := clRed
      else
       for var i := 0 to High(am) do
        begin
         var se := ae[i].ToSingle;
         var sm := am[i].ToSingle;
         if not SameValue(Single(se),Single(sm)) then
          begin
           Result := clRed;
           Break;
          end;
        end;
//     if not SameValue(Single(e.NodeValue),Single(m.NodeValue)) then Result := clRed
//     except
//     if not SameText(e.NodeValue, m.NodeValue) then Result := clRed
     end;
   end;
  if ((Result = clThWindowTextDisabled) or (Result = clThWindowTextNormal))
  and Supports(ColumnNode[col], IXMLNode, e) and e.HasAttribute(AT_COLOR) then
   begin
     Result := ColorCorrect(Integer(e.Attributes[AT_COLOR]));
   end;
end;

function TNodeExData.AsText(Col: Integer): string;
 var
  n,r: IXMLNode;
  function Trim0(const a: string):string;
  begin
    Result := IntToHex(StrToUInt(a)).TrimLeft(['0']);
    if Result = '' then Result := '0';    
  end;
begin
  Result := '';
  if Col >= Length(ColumnValue) then Exit;
  if Col >= Length(ColumnNode) then Exit;
  if Supports(ColumnValue[Col], IXMLNode, n) then
   begin
    if (n.NodeType = ntAttribute) and not VarIsNull(n.NodeValue) then
     begin
      Result := n.NodeValue;
      Result := Result.Trim;
      if (Result <> '') and (n.NodeName = AT_VALUE) and Supports(ColumnNode[Col], IXMLNode, r) then
       if r.HasAttribute(AT_DIGITS) and r.HasAttribute(AT_AQURICY) then
        begin
         Result := FloatToStrF(StrToFloatDef(Result,0), ffFixed, r.Attributes[AT_DIGITS], r.Attributes[AT_AQURICY])
        end
       else if r.HasAttribute('ShowHex') then
        begin
         if r.ParentNode.HasAttribute(AT_ARRAY) then
          begin
           var a := Result.Split([' ']);
           for var i := 0 to  High(a) do
            a[i] := Trim0(a[i]);
           Result := string.Join(' ', a);
          end
         else Result := Trim0(Result);
        end;
     end
    else
      begin
       Result := n.NodeName;
       if n.HasAttribute(AT_FROM) then Result := Result + '['+n.Attributes[AT_FROM]+']';
      end;
   end
end;

function TNodeExData.Editable(Col: Integer): boolean;
 var
  n: IXMLNode;
  readonly: Boolean;
begin
  Result := False;
  readonly := False;
  if Col >= Length(ColumnValue) then Exit;
  if Supports(ColumnNode[Col], IXMLNode, n) then
     readonly := n.HasAttribute('readonly');
  if Supports(ColumnValue[Col], IXMLNode, n) then
   begin
    if (n.NodeType = ntAttribute) and FReadedFlag and not readonly then Result := true;
   end
end;

procedure TNodeExData.FromText(Col: Integer; const NewData: string);
 var
  n: IXMLNode;
begin
  if Col >= Length(ColumnValue) then Exit;
  if Supports(ColumnValue[Col], IXMLNode, n) then
   begin
    if n.NodeType = ntAttribute then
     begin
      n.NodeValue := NewData;
      FEdited := True;
     end;
   end
end;

{ TFormDlgEeprom }


function TFormDlgEeprom.Execute(Eep: IXMLNode; Res: TDialogResult): Boolean;
begin
  Result := True;
  FRes := Res;
  Feep := Eep;
  for var i := 0 to eep.ChildNodes.Count-1 do
    begin
     var sec := eep.ChildNodes[i];
     if sec.HasAttribute(AT_FROM) then
      begin
       var d : TFromNodeData;
       d.FromNode := sec;
       d.userPsw := 'неверный пароль';
       FFromNodeDatas := FFromNodeDatas + [d];
      end;
    end;
  FModul := Eep.ParentNode;
  Fmetr := FModul.ChildNodes.FindNode(T_MTR);
  FAddr := FModul.Attributes[AT_ADDR];
  Caption := '[' + FModul.nodeName +'.'+Feep.nodeName +'] Редактор EEPROM';
  IShow;
  InitTree;
end;

procedure TFormDlgEeprom.Load1Click(Sender: TObject);
 var
  e: IXMLNode;
  f: TFileStream;
  a: array [0..4095]of Byte;
begin
  if Supports(FEditData.ColumnValue[0], IXMLNode, e) and e.HasAttribute(AT_FROM) then
  with TOpenDialog.Create(nil) do
  try
   InitialDir := ExtractFilePath(ParamStr(0));
   Options := Options + [ofPathMustExist, ofFileMustExist];
   DefaultExt := 'bin';
   Filter := ' bin (*.bin)|*.bin';
   if Execute(Handle) then
    begin
     f := TFileStream.Create(FileName, fmOpenRead);
     f.Read(a[0], Length(a));
     f.Free;
     TPars.LocalSetData(e, @a[0]);
    end;
  finally
    Free;
  end;
end;

procedure TFormDlgEeprom.File1Click(Sender: TObject);
 var
  e: IXMLNode;
 // section: Integer;
  a: TPars.TOutArray;
  s : TStream;
begin
  if Supports(FEditData.ColumnValue[0], IXMLNode, e) and e.HasAttribute(AT_FROM) then
   begin
   // section := e.ParentNode.ChildNodes.IndexOf(e);
    if FReadedFlag then
      with TSaveDialog.Create(nil) do
      try
       InitialDir := ExtractFilePath(ParamStr(0));
       DefaultExt := 'bin';
       Options := Options + [ofOverwritePrompt, ofPathMustExist];
       Filter := 'File (*.bin)|*.bin';
       if Execute(Handle) then
        begin
          TPars.LocalGetData(e, a);
          s := TFileStream.Create(FileName, fmCreate);
          s.Write(a[0], Length(a));
          s.Free;
        end;
      finally
       Free;
      end;
    end
  //  else MessageDlg('Память EEPROM не считана предыдущие данные будут удалены!!!', mtError, [mbYes, mbCancel], 0)
end;

function TFormDlgEeprom.GetDevice: IEepromDevice;
 var
  d: IDevice;
begin
  Result := nil;
  d := (GlobalCore as IDeviceEnum).Get(FModul.ParentNode.NodeName);
  if not Assigned(d) then raise EFrmDlgEeprom.CreateFmt('Устройство %s не найдено', [Fmodul.NodeName]);
  if not Supports(d, IEepromDevice, Result) then raise EFrmDlgEeprom.CreateFmt('Устройство %s без EEPROM', [Fmodul.NodeName]);
end;

function TFormDlgEeprom.GetInfo: PTypeInfo;
begin
  Result := TypeInfo(Dialog_Eep);
end;

procedure TFormDlgEeprom.SaveEEprom(FrootEEP: IXMLNode);
 var
  m: IMainScreen;
  a: TPars.TOutArray;
  s : TStream;
begin
  if not Supports(GContainer, IMainScreen, m) then Exit;
  var pfile := m.StatusBarText[1];
  var dir := Tpath.GetDirectoryName(pfile);
  var fail := Tpath.Combine(dir, 'eeprom.xml');
  var d := NewXMLDocument();
  d.DocumentElement := FrootEEP.CloneNode(true);
  st.Panels[1].Text := fail;
  d.SaveToFile(fail);
  // save sections
  for var e in XEnum(FrootEEP) do if e.HasAttribute(AT_FROM) then
   begin
    TPars.LocalGetData(e, a);
    var binf := Tpath.Combine(dir, e.LocalName + '.bin');
    s := TFileStream.Create(binf, fmCreate);
    try
     s.Write(a[0], Length(a));
    finally
     s.Free;
    end;
   end;
end;

procedure TFormDlgEeprom.btExitClick(Sender: TObject);
begin
  RegisterDialog.UnInitialize(GetInfo);
end;

procedure TFormDlgEeprom.btReadClick(Sender: TObject);
begin
  FReadedFlag := False;
  st.Panels[0].Text := 'Read BAD';
  Dev.ReadEeprom(FAddr, procedure (Res: TEepromEventRes)
  begin
    if Res.DevAdr <> FAddr then Exit;
    st.Panels[0].Text := 'Read GOOD';
    FReadedFlag := True;
    btWrite.Enabled := PaswAllChecked and FReadedFlag;
    for var pv in Tree.Nodes do PNodeExData(Tree.GetNodeData(pv)).FEdited := False;
    Tree.Repaint;
    SaveEEprom(Feep);
  end);
end;

procedure TFormDlgEeprom.btWriteClick(Sender: TObject);
begin
  if FReadedFlag then
  Dev.WriteEeprom(FAddr, procedure (Res: Boolean)
  begin
    if Res then
     begin
      st.Panels[0].Text := 'write GOOD';
      for var pv in Tree.Nodes do PNodeExData(Tree.GetNodeData(pv)).FEdited := False;
      Tree.Repaint;
     end
    else st.Panels[0].Text := 'write BAD'
  end)
  else MessageDlg('Память EEPROM не считана предыдущие данные будут удалены!!!', mtError, [mbYes, mbCancel], 0)
end;

procedure TFormDlgEeprom.ClearTree;
 var
  pv: PVirtualNode;
begin
  for pv in Tree.Nodes do
   begin
    SetLength(PNodeExData(Tree.GetNodeData(pv)).ColumnValue, 0);
    SetLength(PNodeExData(Tree.GetNodeData(pv)).ColumnNode, 0);
   end;
  Tree.Clear;
end;

procedure TFormDlgEeprom.InitTree;
   procedure Add(Parent :PVirtualNode; u: IXMLNode);
    var
     chn: PVirtualNode;
     xd: PNodeExData;
     i: Integer;
     nd, nc, an, ac, mtr, eu: IXMLNode;
   begin
     if u.HasAttribute('HIDDEN') and (u.Attributes['HIDDEN'] = True) then Exit;
     chn := Tree.AddChild(Parent);
     Include(chn.States, vsExpanded);
     xd := Tree.GetNodeData(chn);
     xd.ColumnValue := xd.ColumnValue + [u];
     xd.ColumnNode := xd.ColumnNode + [u];
     if u.HasAttribute(AT_SIZE) then
       for I := 0 to u.ChildNodes.Count-1 do Add(chn, u.ChildNodes[i])
     else
       begin
        nd := u.ChildNodes.FindNode(T_DEV);
        nc := u.ChildNodes.FindNode(T_CLC);
        mtr := GetMetrNode(u);
        if Assigned(nd) then
         begin
          if not nd.HasAttribute(AT_VALUE) then nd.Attributes[AT_VALUE] := ' ';
          an := nd.AttributeNodes.FindNode(AT_VALUE);
          eu := nd.AttributeNodes.FindNode(AT_EU);
         end;
        if Assigned(nc) then
         begin
          if not nc.HasAttribute(AT_VALUE) then nc.Attributes[AT_VALUE] := ' ';
          ac := nc.AttributeNodes.FindNode(AT_VALUE);
          eu := nc.AttributeNodes.FindNode(AT_EU);
         end;
        xd.ColumnValue := xd.ColumnValue + [an, ac, mtr, eu];
        xd.ColumnNode  :=  xd.ColumnNode + [nd, nc, nil, nil];
       end;
   end;
var
  i: Integer;
begin
  ClearTree;
  FReadedFlag := False;
  for i:= 0 to Feep.ChildNodes.Count-1 do Add(nil, Feep.ChildNodes[i]);
end;

procedure TFormDlgEeprom.Loaded;
//var
//  m: IMainScreen;
begin

  Tree.BeginUpdate;
  inherited;
  Tree.Colors := TVTColors.Create(Tree);
  Tree.EndUpdate;
  Bind('C_MetrologyChange', GlobalCore as IManager, ['S_MetrologyChange']);
  Bind('C_MetaDataOK', GlobalCore as IManager, ['S_MetaDataOK']);
  AddToNCMenu('-', nil, 0);
  AddToNCMenu('Копировать Метрологию в буфер EEPROM', NCopyMetrClick, 0);
//  AddToNCMenu('Сравнить Метрологию и буфер EEPROM', NCopyMetrClick, 0);
//  if Supports(GContainer, IMainScreen, m) then StyleName := m.ThemeName;
end;

function CheckPath(tst, etalon: IXMLNode; const rootTst, rootEtalon: string): boolean;
begin
  while Assigned(tst) and Assigned(etalon) do
   begin
    if tst.NodeName <> etalon.NodeName then Exit(False);
    tst := tst.ParentNode;
    etalon := etalon.ParentNode;
    if Assigned(tst) and Assigned(etalon) and (etalon.NodeName = rootEtalon) and
    ((tst.NodeName = rootTst) or (tst.HasAttribute(AT_FROM))) then Exit(True);
   end;
  Result := False;
end;

function TFormDlgEeprom.GetMetrNode(eepNode: IXMLNode): IXMLNode;
 var
  Res: IXMLNode;
begin
  Res := nil;
  ExecXTree(Fmetr, function (n: IXMLNode): boolean
  begin
    if n.HasAttribute(eepNode.NodeName) and CheckPath(eepNode.ParentNode, n, T_EEPROM, T_MTR) then
     begin
      res := n.AttributeNodes.FindNode(eepNode.NodeName);
      Result := True;
     end
    else Result := False;
  end);
  Result := res;
end;

//procedure TFormDlgEeprom.NCmpMetrClick(Sender: TObject);
// var
//  e, m: IXMLNode;
//  pv: PVirtualNode;
//begin
//  for pv in Tree.Nodes do with PNodeExData(Tree.GetNodeData(pv))^ do
//    if (Length(ColumnValue) > 2) and Supports(ColumnValue[1], IXMLNode, e) and (e.NodeType = ntAttribute)
//    and Supports(ColumnValue[2], IXMLNode, m) and (m.NodeType = ntAttribute) then 
//     begin
//       if SameValue(Single(e.NodeValue), Single(m.NodeValue)) then
//       
//       e.NodeValue := m.NodeValue;
//       
//     end;
//  Tree.Repaint;
//end;

procedure TFormDlgEeprom.NCopyMetrClick(Sender: TObject);
 var
  e, m: IXMLNode;
  pv: PVirtualNode;
begin
  for pv in Tree.Nodes do with PNodeExData(Tree.GetNodeData(pv))^ do
    if (Length(ColumnValue) > 2) and Supports(ColumnValue[1], IXMLNode, e) and (e.NodeType = ntAttribute)
    and Supports(ColumnValue[3], IXMLNode, m) and (m.NodeType = ntAttribute) then e.NodeValue := m.NodeValue;
  Tree.Repaint;
end;

procedure TFormDlgEeprom.nPaswClick(Sender: TObject);
 var
  e: IXMLNode;
  InputString: string;
begin
  if Supports(FEditData.ColumnValue[0], IXMLNode, e) and e.HasAttribute(AT_FROM) then
  begin
    PaswSet(e,InputBox('Диалог ввода пароля секции EEPROM', 'Пароль', '?????'));
  end;
end;

function TFormDlgEeprom.PaswAllChecked: Boolean;
begin
  for var fnd in FFromNodeDatas do
   if fnd.FromNode.HasAttribute(AT_PSWD) then
    if fnd.FromNode.Attributes[AT_PSWD] <> fnd.userPsw then exit(false);
  Result := True;
end;

function TFormDlgEeprom.PaswChecked(fromNode: IXMLNode): Boolean;
begin
  Result := False;
  if fromNode.HasAttribute(AT_PSWD) then
   begin
    for var fnd in FFromNodeDatas do
     if (fnd.FromNode = fromNode)
        and (fromNode.Attributes[AT_PSWD] = fnd.userPsw)
       then exit(true);
   end
   else exit(true);
end;

procedure TFormDlgEeprom.PaswSet(fromNode: IXMLNode; const psw: string);
begin
  for var i := 0 to Length(FFromNodeDatas)-1 do
   if FFromNodeDatas[i].FromNode = fromNode then
    begin
     FFromNodeDatas[i].userPsw := psw;
     Break;
    end;
  btWrite.Enabled := PaswAllChecked and FReadedFlag;
end;

procedure TFormDlgEeprom.ppmPopup(Sender: TObject);
 var
  e: IXMLNode;
begin
  FEditData := nil;
  FEditNode := nil;
  EEPROM1.Visible := False;
  nPasw.Visible := False;
  EEPROM1.Enabled := True;
  if not Assigned(Tree.HotNode) then Exit;
  FEditNode := Tree.HotNode;
  FEditData := Tree.GetNodeData(FEditNode);
  if Supports(FEditData.ColumnValue[0], IXMLNode, e) and e.HasAttribute(AT_FROM) then
   begin
    EEPROM1.Visible := True;
    if e.HasAttribute(AT_PSWD) then
    begin
      if not PaswChecked(e) then
       begin
        nPasw.Visible := True;
        EEPROM1.Enabled := False;
       end;
    end;
   end;
end;

procedure TFormDlgEeprom.EEPROM1Click(Sender: TObject);
 var
  e: IXMLNode;
  section: Integer;
begin
  if Supports(FEditData.ColumnValue[0], IXMLNode, e) and e.HasAttribute(AT_FROM) then
   begin
    section := e.ParentNode.ChildNodes.IndexOf(e);
    if FReadedFlag then
    Dev.WriteEeprom(FAddr, procedure (Res: Boolean)
    begin
      if Res then
       begin
        st.Panels[0].Text := 'write GOOD';
        for var pv in Tree.ChildNodes(FEditNode) do PNodeExData(Tree.GetNodeData(pv)).FEdited := False;
        Tree.Repaint;
       end
      else st.Panels[0].Text := 'write BAD'
    end, section)
    else MessageDlg('Память EEPROM не считана предыдущие данные будут удалены!!!', mtError, [mbYes, mbCancel], 0)
   end;
end;


procedure TFormDlgEeprom.SetC_MetaDataOK(const Value: boolean);
begin
  FC_MetaDataOK := Value;
end;

procedure TFormDlgEeprom.SetC_MetrologyChange(const Value: string);
begin
  FC_MetrologyChange := Value;
  if Assigned(Fmetr.ChildNodes.FindNode(FC_MetrologyChange)) then
   begin
    InitTree;
   end;
end;

procedure TFormDlgEeprom.TreeCreateEditor(Sender: TBaseVirtualTree; Node: PVirtualNode; Column: TColumnIndex; out EditLink: IVTEditLink);
begin
  EditLink := TEditor.Create;
end;

procedure TFormDlgEeprom.TreeEditing(Sender: TBaseVirtualTree; Node: PVirtualNode; Column: TColumnIndex; var Allowed: Boolean);
begin
  Allowed := PNodeExData(Tree.GetNodeData(Node)).Editable(Column);
end;

procedure TFormDlgEeprom.TreeGetNodeDataSize(Sender: TBaseVirtualTree; var NodeDataSize: Integer);
begin
  NodeDataSize := SizeOf(TNodeExData);
end;

procedure TFormDlgEeprom.TreeGetText(Sender: TBaseVirtualTree; Node: PVirtualNode; Column: TColumnIndex; TextType: TVSTTextType;
  var CellText: string);
begin
  CellText := '';
  if Column < 0 then Exit;
  CellText := PNodeExData(Sender.GetNodeData(Node)).AsText(Column);
end;

procedure TFormDlgEeprom.TreePaintText(Sender: TBaseVirtualTree; const TargetCanvas: TCanvas; Node: PVirtualNode; Column: TColumnIndex;
  TextType: TVSTTextType);
begin
  if Column < 0 then Exit;
  TargetCanvas.Font.Color := PNodeExData(Sender.GetNodeData(Node)).AsColor(Column);// and $00FFFFFF;
end;

initialization
  RegisterDialog.Add<TFormDlgEeprom, Dialog_Eep>;
finalization
  RegisterDialog.Remove<TFormDlgEeprom>;
end.

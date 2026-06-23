unit PskCreateForm;

interface

uses
    RootIntf, PluginAPI, ExtendIntf, DockIForm, DeviceIntf, debug_except, Parser, Container, Actns, tools, VirtualTrees.Types,
  XMLDoc, Xml.XMLIntf,  System.Generics.Collections, Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.ExtCtrls, Vcl.StdCtrls, Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.Menus, Vcl.PlatformDefaultStyleActnCtrls, Vcl.ActnPopup, VirtualTrees, Vcl.ImgList,
  ActnCtrls, VirtualTrees.BaseAncestorVCL, VirtualTrees.BaseTree,
  VirtualTrees.AncestorVCL;

const
  // Helper message to decouple node change handling from edit handling.
  WM_STARTEDITING = WM_USER + 778;
  WM_ENDEDITING = WM_USER + 779;
type
  TFormPsk = class(TDockIForm,  IVTEditLink, INotifyBeforeRemove, INotifyBeforeClean)
    ppM: TPopupActionBar;
    N1: TMenuItem;
    NTest: TMenuItem;
    Panel1: TPanel;
    Label1: TLabel;
    edDEv: TEdit;
    Label2: TLabel;
    edInfo: TEdit;
    Label3: TLabel;
    edAdr: TEdit;
    Bevel1: TBevel;
    Label4: TLabel;
    edDevider: TEdit;
    cbWorkTime: TCheckBox;
    Bevel2: TBevel;
    Label5: TLabel;
    cbRam: TCheckBox;
    NOpen: TMenuItem;
    NSave: TMenuItem;
    Splitter1: TSplitter;
    Panel2: TPanel;
    Memo: TMemo;
    Tree: TVirtualStringTree;
    Splitter2: TSplitter;
    PanelRam: TPanel;
    edRamSize: TEdit;
    cbHiprotHbFirst: TCheckBox;
    cbHbFirst: TCheckBox;
    edRamTimeout: TEdit;
    edRamSP: TEdit;
    cbRamProt: TComboBox;
    cbHiRamProt: TComboBox;
    edRamKadr: TEdit;
    Label15: TLabel;
    Label14: TLabel;
    Label13: TLabel;
    Label12: TLabel;
    Label11: TLabel;
    Label7: TLabel;
    cbbWrkProt: TComboBox;
    edWrkTimeout: TEdit;
    Label8: TLabel;
    edWrkSP: TEdit;
    Label10: TLabel;
    OpenDialog: TOpenDialog;
    edWrkKadr: TEdit;
    N2: TMenuItem;
    NDel: TMenuItem;
    NAdd: TMenuItem;
    NAddTree: TMenuItem;
    NAddData: TMenuItem;
    N3: TMenuItem;
    NCopy: TMenuItem;
    NCat: TMenuItem;
    NPast: TMenuItem;
    N7: TMenuItem;
    NPastAdd: TMenuItem;
    SaveDialog: TSaveDialog;
    upd: TMenuItem;
    cbByteAddress: TCheckBox;
    N4: TMenuItem;
    NewAddr: TMenuItem;
    procedure NOpenClick(Sender: TObject);
    procedure NSaveClick(Sender: TObject);
    procedure NTestClick(Sender: TObject);
    procedure cbRamClick(Sender: TObject);
    procedure cbRamProtChange(Sender: TObject);
    procedure cbbWrkProtChange(Sender: TObject);
    procedure TreeGetImageIndex(Sender: TBaseVirtualTree; Node: PVirtualNode; Kind: TVTImageKind; Column: TColumnIndex; var Ghosted: Boolean; var ImageIndex: Integer);
    procedure TreeGetText(Sender: TBaseVirtualTree; Node: PVirtualNode; Column: TColumnIndex; TextType: TVSTTextType; var CellText: string);
    procedure TreeEditing(Sender: TBaseVirtualTree; Node: PVirtualNode; Column: TColumnIndex; var Allowed: Boolean);
    procedure TreeCreateEditor(Sender: TBaseVirtualTree; Node: PVirtualNode; Column: TColumnIndex; out EditLink: IVTEditLink);
    procedure TreeFocusChanged(Sender: TBaseVirtualTree; Node: PVirtualNode; Column: TColumnIndex);
    procedure NDelClick(Sender: TObject);
    procedure ppMPopup(Sender: TObject);
    procedure NAddTreeClick(Sender: TObject);
    procedure NAddDataClick(Sender: TObject);
    procedure NCopyClick(Sender: TObject);
    procedure NCatClick(Sender: TObject);
    procedure NPastClick(Sender: TObject);
    procedure NPastAddClick(Sender: TObject);
    procedure updClick(Sender: TObject);
    procedure NewAddrClick(Sender: TObject);
  private
    FXMLInfo: IXMLInfo;
    FScript: IXMLScript;

    FEdit: TWinControl;
    FEditColumn: TColumnIndex;
    FEditNode: PVirtualNode;
    FlagClipboard: Boolean;
    FFileDev: string;

    procedure ClearTree;
    procedure ClearNodeSelections;
    procedure LoadDev(const FileName: string);
    procedure UpdateTree;
    procedure WMStartEditing(var Message: TMessage); message WM_STARTEDITING;
    procedure WMEndEditing(var Message: TMessage); message WM_ENDEDITING;
    procedure EditKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure EditKeyUp(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure RemoveNode(Node: IXMLNode; NeedUpdateTree: Boolean = False);
    procedure PastateNode(const Sel: IXMLNode; Past: array of IXMLNode; NeedUpdateTree: Boolean = False);overload;
    procedure PastateNode(const Sel, Past: IXMLNode; FlagAdd: Boolean = False; NeedUpdateTree: Boolean = False); overload;
    procedure AddDirNode( Sel: IXMLNode; const Name: string; NeedUpdateTree: Boolean = False);
    procedure AddTypeNode(Sel: IXMLNode; const Name: string; NeedUpdateTree: Boolean = False);
    function RenameNode(Src: IXMLNode; const NewName: string; NeedUpdateTree: Boolean = False): IXMLNode;
    procedure GetMetrStrings(var Values: TStrings; node: IXMLNode = nil);
  protected
   const
    NICON = 44;
//  IVTEditLink
   function BeginEdit: Boolean; stdcall;
   function CancelEdit: Boolean; stdcall;
   function EndEdit: Boolean; stdcall;
   function GetBounds: TRect; stdcall;
   function PrepareEdit(Tree: TBaseVirtualTree; Node: PVirtualNode; Column: TColumnIndex): Boolean; stdcall;
   procedure ProcessMessage(var Message: TMessage); stdcall;
   procedure IVTEditLink.SetBounds = SetBounds2; procedure SetBounds2(R: TRect); stdcall;
   procedure Loaded; override;
   class function ClassIcon: Integer; override;
   procedure BeforeClean(var CanClean: Boolean);
   procedure BeforeRemove();
  public
    [StaticAction('Новый Редактор приборов ПСК', 'Отладочные', NICON, '0:Показать.Отладочные:0')]
    class procedure DoCreateForm(Sender: IAction); override;
   destructor Destroy; override;
  published
    property FileDev: string read FFileDev write FFileDev;
  end;

implementation

{$R *.dfm}

uses AbstractPlugin;

type
  PNodeExData = ^TNodeExData;
  TNodeExData = record
    XMNode: IXMLNode;
    FlagSelect: Boolean;
    FlagDelete: Boolean;
    procedure Init(Node: IXMLNode);
  end;
procedure TNodeExData.Init(Node: IXMLNode);
begin
  XMNode := Node;
  FlagSelect := False;
  FlagDelete := False;
end;


{ TFormPsk }

class function TFormPsk.ClassIcon: Integer;
begin
  Result := NICON;
end;

class procedure TFormPsk.DoCreateForm(Sender: IAction);
begin
  inherited;
end;

procedure TFormPsk.Loaded;
 var
  ip: IImagProvider;
begin
  inherited;
  Tree.NodeDataSize := SizeOf(TNodeExData);
  if Supports(GlobalCore, IImagProvider, ip) then Tree.Images := ip.GetImagList;
  Memo.Clear;
  FScript := (GLobalCore as IXMLScriptFactory).Get(nil);
  LoadDev(FFileDev);
end;

procedure TFormPsk.BeforeClean(var CanClean: Boolean);
begin
  Tree.CancelEditNode;
//  inherited;
end;

procedure TFormPsk.BeforeRemove;
begin
  Tree.CancelEditNode;
//  inherited;
end;

procedure TFormPsk.NTestClick(Sender: TObject);
 var
  d, w, r: IXMLNode;
  tmp: Integer;
  procedure RemoveAtr(n: IXMLNode; const atr: string);
   var
    a: IXMLNode;
  begin
    a := n.AttributeNodes.FindNode(Atr);
    if Assigned(a) then n.AttributeNodes.Remove(a);
  end;
  procedure Compile(root: IXMLNode);
   const
    ERR_LEN = 'ERR: У элемента %s индекс с длинной данных(%d + %d) больше длинны кадра %d (байты)';
    ERR_IND = 'ERR: У элемента %s индекс %d (байты) по смещению %d используется другим элементом';
    ERR_ZER = 'Пустые данные с %d по %d кол-во %d (байты) с %d по %d (слова)';
   var
    kadr, fr, c: Integer;
    a: array of Byte;
  begin
    kadr := root.Attributes[AT_SIZE];
    SetLength(a, kadr);
    inc(a[0]); //SP
    inc(a[1]); //SP
    ExecXTree(root, function(n: IXMLNode): boolean
     var
      ind, len, i: Integer;
    begin
      Result := False;
      if n.NodeName <> T_DEV then Exit;
      if not n.HasAttribute(AT_TIP) or not n.HasAttribute(AT_INDEX) then
          memo.Lines.Add(Format('ERR: У элемента %s нет важных атрибутов', [n.ParentNode.NodeName]))
       else
      begin
       if cbByteAddress.Checked then ind := n.Attributes[AT_INDEX]
       else ind := n.Attributes[AT_INDEX]*2;
       try
        if n.ParentNode.HasAttribute(AT_ARRAY) then
         if cbByteAddress.Checked then len := n.ParentNode.Attributes[AT_ARRAY]*TPars.VarTypeToLength(n.Attributes[AT_TIP])
         else len := n.ParentNode.Attributes[AT_ARRAY]*2 // all word data device
        else len := TPars.VarTypeToLength(n.Attributes[AT_TIP]);
       except
        on E: Exception do memo.Lines.Add(e.Message);
       end;
       if (n.Attributes[AT_TIP] = TPars.var_ui2_kadr_psk4)  then
        begin
         Inc(a[ind-4]);
         Inc(a[ind-3]);
         Inc(a[ind]);
         Inc(a[ind+1]);
        end
       else if n.Attributes[AT_TIP] = TPars.var_ui2_kadr_all then
        begin
         Inc(a[ind-2]);
         Inc(a[ind-1]);
         Inc(a[ind]);
         Inc(a[ind+1]);
        end
       else if (kadr < (ind+len)) and (ind >= 2) then memo.Lines.Add(Format(ERR_LEN, [n.ParentNode.NodeName, ind, len, kadr]))
       else
        begin
         for i := ind to ind+len-1 do
          begin
           Inc(a[i]);
           if a[i] <> 1 then
            begin
             memo.Lines.Add(Format(ERR_IND, [n.ParentNode.NodeName, ind, i]));
             Break;
            end;
          end;
        end;
      end;
    end);
    c := 0;
    while C < kadr do
     begin
      if a[c] = 0  then
       begin
        fr := c;
        while (C < kadr) and (a[c] = 0) do Inc(c);
        memo.Lines.Add(Format(ERR_ZER, [fr, c-1, c-fr, fr div 2, (c-1) div 2]));
       end
       else inc(c);
     end;
  end;
begin
  Memo.Clear;
  NSave.Enabled := True;
  RenameNode(FXMLInfo.ChildNodes[0], edDEv.Text);
  d := FXMLInfo.ChildNodes[0];
  // device
  d.Attributes[AT_INFO] := edInfo.Text;
  d.Attributes[AT_ADDR] := edAdr.Text;
  tmp := StrToInt(edDevider.Text);
  if tmp = 128 then RemoveAtr(d, AT_DELAYDV)
  else d.Attributes[AT_DELAYDV] := tmp;

  if cbByteAddress.Checked then d.Attributes[AT_PSK_BYTE_ADDR] := 1
  else RemoveAtr(d, AT_PSK_BYTE_ADDR);

  if cbWorkTime.Checked then d.Attributes[AT_WORKTIME] := 1
  else RemoveAtr(d, AT_WORKTIME);

  // work
  w := FindWork(FXMLInfo, d.Attributes[AT_ADDR]);
  if Assigned(w) then
   begin
    tmp := StrToInt(edWrkKadr.Text);
    w.Attributes[AT_SIZE] := tmp;
    w.Attributes[AT_WRKP] := cbbWrkProt.ItemIndex+1;
    if cbbWrkProt.ItemIndex = 0 then
     begin
      w.Attributes[AT_FLOWINTERVAL] := StrToInt(edWrkTimeout.Text);
      w.Attributes[AT_SP_HI] := StrToInt(edWrkSP.Text);
     end
    else
     begin
      RemoveAtr(w, AT_FLOWINTERVAL);
      RemoveAtr(w, AT_SP_HI);
     end;
    Memo.Lines.Add('========= Режим информации  ===============');
    Compile(w);
   end;
  // ram
  r := FindRam(FXMLInfo, d.Attributes[AT_ADDR]);
  if Assigned(r) then
   begin
    r.Attributes[AT_RAMSIZE] := StrToInt(edRamSize.Text);
    tmp := StrToInt(edRamKadr.Text);
    r.Attributes[AT_SIZE] := tmp;
    r.Attributes[AT_RAMLP] := cbRamProt.ItemIndex+1;
    if cbHbFirst.Checked then r.Attributes[AT_RAMLP] := r.Attributes[AT_RAMLP] or $80;

    if cbRamProt.ItemIndex = 2 then
     begin
      RemoveAtr(r, AT_FLOWINTERVAL);
      RemoveAtr(r, AT_SP_HI);
      RemoveAtr(r, AT_WRKP);
     end
    else
     begin
      r.Attributes[AT_WRKP] := 1;
      r.Attributes[AT_FLOWINTERVAL] := StrToInt(edRamTimeout.Text);
      r.Attributes[AT_SP_HI] := StrToInt(edRamSP.Text);
     end;

    if cbHiRamProt.ItemIndex = 0 then RemoveAtr(r, AT_RAMHP)
    else
     begin
      r.Attributes[AT_RAMHP] := cbHiRamProt.ItemIndex;
      if cbHiprotHbFirst.Checked then r.Attributes[AT_RAMHP] := r.Attributes[AT_RAMHP] or $80;
     end;

    Memo.Lines.Add('========= Память прибора  ===============');
    Compile(r);
   end;
end;

procedure TFormPsk.LoadDev(const FileName: string);
 var
  GDoc: IXMLDocument;
  d,r,w: IXMLNode;
begin
  if (FFileDev = '') or not FileExists(FFileDev) then Exit;
  GDoc := NewXMLDocument();
  GDoc.LoadFromFile(FileName);
  FXMLInfo := GDoc.DocumentElement;
  d := FXMLInfo.ChildNodes[0];
  // device
  edDEv.Text := d.NodeName;
  Caption := edDEv.Text;
  edInfo.Text := d.Attributes[AT_INFO];
  edAdr.Text := d.Attributes[AT_ADDR];
  if d.HasAttribute(AT_DELAYDV) then edDevider.Text := d.Attributes[AT_DELAYDV]
  else edDevider.Text := '128';

  if d.HasAttribute(AT_PSK_BYTE_ADDR) and (d.Attributes[AT_PSK_BYTE_ADDR] = 1) then cbByteAddress.Checked := True
  else cbByteAddress.Checked := False;

  if d.HasAttribute(AT_WORKTIME) and (d.Attributes[AT_WORKTIME] = 1) then cbWorkTime.Checked := True
  else cbWorkTime.Checked := False;
  // work
  w := FindWork(FXMLInfo, d.Attributes[AT_ADDR]);
  if Assigned(w) then
   begin
    edWrkKadr.Text := w.Attributes[AT_SIZE];
    cbbWrkProt.ItemIndex := w.Attributes[AT_WRKP]-1;
    cbbWrkProtChange(Self);
    if cbbWrkProt.ItemIndex = 0 then
     begin
      edWrkTimeout.Text := w.Attributes[AT_FLOWINTERVAL];
      edWrkSP.Text := w.Attributes[AT_SP_HI];
     end;
   end;
  // ram
  r := FindRam(FXMLInfo, d.Attributes[AT_ADDR]);
  if Assigned(r) then
   begin
    cbRam.Checked := True;
    edRamKadr.Text := r.Attributes[AT_SIZE];
    if r.HasAttribute(AT_RAMSIZE) then edRamSize.Text := r.Attributes[AT_RAMSIZE]
    else edRamSize.Text := '8';
    cbRamProt.ItemIndex := (r.Attributes[AT_RAMLP] and $7F)-1;
    cbHbFirst.Checked := (r.Attributes[AT_RAMLP] and $80) <> 0;
    cbRamProtChange(Self);
    if cbRamProt.ItemIndex <> 2 then
     begin
      edRamTimeout.Text := r.Attributes[AT_FLOWINTERVAL];
      edRamSP.Text := r.Attributes[AT_SP_HI];
     end;
    if r.HasAttribute(AT_RAMHP) then
     begin
      cbHiRamProt.ItemIndex := (r.Attributes[AT_RAMHP] and $7F);
      cbHiprotHbFirst.Checked := (r.Attributes[AT_RAMHP] and $80) <> 0;
     end
    else
     begin
      cbHiRamProt.ItemIndex := 0;
      cbHiprotHbFirst.Checked := False;
     end;
   end
  else
   begin
    cbRam.Checked := False;
   end;
  cbRamClick(Self);
  Memo.Lines.Add(FFileDev);
end;

function TFormPsk.RenameNode(Src : IXMLNode; const NewName : string; NeedUpdateTree: Boolean) : IXMLNode;
begin
  Result:= RenameXMLNode(Src, NewName);

  if NeedUpdateTree then UpdateTree()
end;

procedure TFormPsk.cbbWrkProtChange(Sender: TObject);
begin
  Label8.Enabled := cbbWrkProt.ItemIndex = 0;
  edWrkTimeout.Enabled := Label8.Enabled;
  edWrkSP.Enabled := edWrkTimeout.Enabled;
  Label10.Enabled := edWrkTimeout.Enabled;
end;

procedure TFormPsk.cbRamClick(Sender: TObject);
 var
  r: IXMLNode;
begin
  PanelRam.Visible := cbRam.Checked;
  r := FindRam(FXMLInfo, FXMLInfo.ChildNodes[0].Attributes[AT_ADDR]);
  if not cbRam.Checked  then
   begin
    if Assigned(r) then FXMLInfo.ChildNodes[0].ChildNodes.Remove(r);
   end
  else
   begin
    if not Assigned(r) then r := FXMLInfo.ChildNodes[0].AddChild(T_RAM);
    r.Attributes[AT_SIZE] := StrToInt(edRamKadr.Text);
   end;
  UpdateTree;
end;

procedure TFormPsk.cbRamProtChange(Sender: TObject);
begin
  edRamTimeout.Enabled := cbRamProt.ItemIndex <> 2;
  Label14.Enabled := edRamTimeout.Enabled;
  edRamSP.Enabled := edRamTimeout.Enabled;
  Label13.Enabled := edRamTimeout.Enabled;
  cbHbFirst.Visible := edRamTimeout.Enabled;
end;

procedure TFormPsk.ClearTree;
 var
  pv: PVirtualNode;
begin
  for pv in Tree.Nodes do PNodeExData(Tree.GetNodeData(pv)).XMNode := nil;
  Tree.Clear;
end;

destructor TFormPsk.Destroy;
begin
  Tree.CancelEditNode;
  if Assigned(FEdit) then FreeAndNil(FEdit);
  ClearTree;
  inherited;
end;

procedure TFormPsk.RemoveNode(Node: IXMLNode; NeedUpdateTree: Boolean);
begin
  if (Node.NodeName = T_RAM) or (Node.NodeName = T_WRK) then Exit;
  Node.ParentNode.ChildNodes.Remove(Node);
  if NeedUpdateTree then UpdateTree()
end;

procedure TFormPsk.PastateNode(const Sel, Past: IXMLNode; FlagAdd: Boolean = False; NeedUpdateTree: Boolean = False);
begin
  if Sel.HasAttribute(AT_SIZE) then
   if FlagAdd then Sel.ChildNodes.Add(Past.CloneNode(True))
   else Sel.ChildNodes.Insert(0, Past.CloneNode(True))
  else
   if FlagAdd then Sel.ParentNode.ChildNodes.Add(Past.CloneNode(True))
   else Sel.ParentNode.ChildNodes.Insert(Sel.ParentNode.ChildNodes.IndexOf(Sel), Past.CloneNode(True));
  if NeedUpdateTree then UpdateTree()
end;

procedure TFormPsk.PastateNode(const Sel: IXMLNode; Past: array of IXMLNode; NeedUpdateTree: Boolean);
 var
  p: IXMLNode;
begin
  if Sel.HasAttribute(AT_SIZE) then for p in Past do Sel.ChildNodes.Add(p.CloneNode(True))
  else for p in Past do Sel.ParentNode.ChildNodes.Insert(Sel.ParentNode.ChildNodes.IndexOf(Sel), p.CloneNode(True));
  if NeedUpdateTree then UpdateTree()
end;

procedure TFormPsk.ppMPopup(Sender: TObject);
 var
  pv: PVirtualNode;
  ex: PNodeExData;
begin
  NDel.Enabled := False;
  NCopy.Enabled := False;
  NCat.Enabled := False;
  NPast.Enabled := False;
  NPastAdd.Enabled := False;
  NAdd.Visible := False;
  NewAddr.Enabled := False;
  if Tree.SelectedCount > 0 then
   begin
    if Tree.SelectedCount = 1 then
     begin
      NAdd.Visible := True;
      NPast.Enabled := FlagClipboard;
      NPastAdd.Enabled := FlagClipboard;
      NewAddr.Enabled := PNodeExData(Tree.GetNodeData(Tree.GetFirstSelected())).XMNode.ChildNodes.Count > 0;
     end;
    for pv in Tree.SelectedNodes do
     begin
      ex := Tree.GetNodeData(pv);
      if ex.XMNode.HasAttribute(AT_SIZE) and (Tree.SelectedCount > 1) then Exit;
      if (ex.XMNode.NodeName = T_WRK) or (ex.XMNode.NodeName = T_RAM) then Exit;
     end;
    NDel.Enabled := True;
    NCopy.Enabled := True;
    NCat.Enabled := True;
   end;
end;

procedure TFormPsk.AddDirNode(Sel: IXMLNode; const Name: string; NeedUpdateTree: Boolean);
 var
  i: integer;
  n: IXMLNode;
begin
  if Sel.HasAttribute(AT_SIZE) then n := Sel.AddChild(Name)
  else
   begin
    i := Sel.ParentNode.ChildNodes.IndexOf(Sel);
    n := Sel.ParentNode.AddChild(Name, i);
   end;
  n.Attributes[AT_SIZE] := 0;
  if NeedUpdateTree then UpdateTree()
end;

procedure TFormPsk.AddTypeNode(Sel: IXMLNode; const Name: string; NeedUpdateTree: Boolean);
 var
  i: integer;
  n: IXMLNode;
begin
  if Sel.HasAttribute(AT_SIZE) then n := Sel.AddChild(Name)
  else
   begin
    i := Sel.ParentNode.ChildNodes.IndexOf(Sel);
    n := Sel.ParentNode.AddChild(Name, i);
   end;
  n := n.AddChild(T_DEV);
  n.Attributes[AT_TIP] := 2;
  n.Attributes[AT_INDEX] := 0;
  if NeedUpdateTree then UpdateTree()
end;

procedure TFormPsk.NAddDataClick(Sender: TObject);
 var
  pv: PVirtualNode;
  ex: PNodeExData;
begin
  for pv in Tree.SelectedNodes do
   begin
    ex := Tree.GetNodeData(pv);
    AddTypeNode(Ex.XMNode, 'новый_элемент', True);
   end;
end;

procedure TFormPsk.NAddTreeClick(Sender: TObject);
 var
  pv: PVirtualNode;
  ex: PNodeExData;
begin
  for pv in Tree.SelectedNodes do
   begin
    ex := Tree.GetNodeData(pv);
    AddDirNode(Ex.XMNode, 'новая_ветвь', True);
   end;
end;

procedure TFormPsk.NCatClick(Sender: TObject);
 var
  pv: PVirtualNode;
  ex: PNodeExData;
begin
  ClearNodeSelections;
  FlagClipboard := False;
  for pv in Tree.SelectedNodes do
   begin
    ex := Tree.GetNodeData(pv);
    ex.FlagSelect := True;
    ex.FlagDelete := True;
    FlagClipboard := True;
    Tree.InvalidateNode(pv);
   end;
end;

procedure TFormPsk.ClearNodeSelections;
 var
  pv: PVirtualNode;
  ex: PNodeExData;
begin
  FlagClipboard := False;
  for pv in Tree.Nodes do
   begin
    ex := Tree.GetNodeData(pv);
    if ex.FlagSelect or ex.FlagDelete then
     begin
      ex.FlagSelect := False;
      ex.FlagDelete := False;
      Tree.InvalidateNode(pv);
     end;
   end;
end;

procedure TFormPsk.NCopyClick(Sender: TObject);
 var
  pv: PVirtualNode;
  ex: PNodeExData;
begin
  ClearNodeSelections;
  for pv in Tree.SelectedNodes do
   begin
    ex := Tree.GetNodeData(pv);
    ex.FlagSelect := True;
    FlagClipboard := True;
    Tree.InvalidateNode(pv);
   end;
end;

procedure TFormPsk.NDelClick(Sender: TObject);
 var
  pv: PVirtualNode;
  ex: PNodeExData;
begin
  ClearNodeSelections;
  for pv in Tree.SelectedNodes do
   begin
    ex := Tree.GetNodeData(pv);
    RemoveNode(Ex.XMNode);
    Ex.XMNode := nil;
   end;
  UpdateTree;
end;

procedure TFormPsk.NewAddrClick(Sender: TObject);
 var
  pv: PVirtualNode;
  ex: PNodeExData;
  sel: IXMLNode;
  adr: Integer;
begin
  if Tree.SelectedCount <> 1 then Exit;
  sel := PNodeExData(Tree.GetNodeData(Tree.GetFirstSelected())).XMNode;
  if sel.ChildNodes.Count = 0 then Exit;

  adr := InputBox('Aдрес первого элемента', 'Введите адрес', '0').ToInteger();
  ExecXTree(sel, procedure (n: IXMLNode)
  begin
    if n.HasAttribute(AT_INDEX) and n.HasAttribute(AT_TIP) then
     begin
      n.Attributes[AT_INDEX] := adr;
      if n.ParentNode.HasAttribute(AT_ARRAY) then
           inc(adr, TPars.VarTypeToLength(n.Attributes[AT_TIP]) * Integer(n.ParentNode.Attributes[AT_ARRAY]))
      else inc(adr, TPars.VarTypeToLength(n.Attributes[AT_TIP]));
     end;
  end);
end;

procedure TFormPsk.NOpenClick(Sender: TObject);
begin
  OpenDialog.InitialDir := ExtractFilePath(ParamStr(0))+'Devices\';
  if OpenDialog.Execute(Handle) then
   begin
    FFileDev := OpenDialog.FileName;
    LoadDev(FFileDev);
   end;
end;

procedure TFormPsk.NSaveClick(Sender: TObject);
begin
  SaveDialog.InitialDir := ExtractFilePath(ParamStr(0))+'Devices\';
  if SaveDialog.Execute(Handle) then
   begin
    FFileDev := SaveDialog.FileName;
    FXMLInfo.OwnerDocument.SaveToFile(FFileDev);
   end;
end;

procedure TFormPsk.NPastAddClick(Sender: TObject);
 var
  pv: PVirtualNode;
  ex: PNodeExData;
  sel: IXMLNode;
begin
  if Tree.SelectedCount <> 1 then Exit;
  sel := PNodeExData(Tree.GetNodeData(Tree.GetFirstSelected())).XMNode;
  for pv in Tree.Nodes do
   begin
    ex := Tree.GetNodeData(pv);
    if ex.FlagSelect then PastateNode(sel, Ex.XMNode, True);
    if ex.FlagDelete then RemoveNode(Ex.XMNode);
    Ex.XMNode := nil;
   end;
  ClearNodeSelections;
  UpdateTree;
end;

procedure TFormPsk.NPastClick(Sender: TObject);
 var
  pv: PVirtualNode;
  ex: PNodeExData;
  sel: IXMLNode;
begin
  if Tree.SelectedCount <> 1 then Exit;
  sel := PNodeExData(Tree.GetNodeData(Tree.GetFirstSelected())).XMNode;
  for pv in Tree.Nodes do
   begin
    ex := Tree.GetNodeData(pv);
    if ex.FlagSelect then PastateNode(sel, Ex.XMNode);
    if ex.FlagDelete then RemoveNode(Ex.XMNode);
    Ex.XMNode := nil;
   end;
  ClearNodeSelections;
  UpdateTree;
end;

procedure TFormPsk.TreeCreateEditor(Sender: TBaseVirtualTree; Node: PVirtualNode; Column: TColumnIndex; out EditLink: IVTEditLink);
begin
  EditLink := Self as IVTEditLink;
end;

procedure TFormPsk.TreeEditing(Sender: TBaseVirtualTree; Node: PVirtualNode; Column: TColumnIndex; var Allowed: Boolean);
 var
  d: IXMLNode;
begin
  d := PNodeExData(Tree.GetNodeData(Node)).XMNode;
  if (d.NodeName = T_WRK) or (d.NodeName = T_RAM) then Allowed := False
  else if d.HasAttribute(AT_SIZE) and (Column in [1,2,3]) then Allowed := False
end;

procedure TFormPsk.TreeFocusChanged(Sender: TBaseVirtualTree; Node: PVirtualNode; Column: TColumnIndex);
begin
  with Sender do
  begin
    // Start immediate editing as soon as another node gets focused.
    if Assigned(Node) and (Node.Parent <> RootNode) and not (tsIncrementalSearching in TreeStates) then
    begin
      // We want to start editing the currently selected node. However it might well happen that this change event
      // here is caused by the node editor if another node is currently being edited. It causes trouble
      // to start a new edit operation if the last one is still in progress. So we post us a special message and
      // in the message handler we then can start editing the new node. This works because the posted message
      // is first executed *after* this event and the message, which triggered it is finished.
      PostMessage(Self.Handle, WM_STARTEDITING, WPARAM(Node), Column);
    end;
  end;
end;

procedure TFormPsk.TreeGetImageIndex(Sender: TBaseVirtualTree; Node: PVirtualNode; Kind: TVTImageKind; Column: TColumnIndex; var Ghosted: Boolean; var ImageIndex: Integer);
 var
  xd: PNodeExData;
begin
  xd := Sender.GetNodeData(Node);
  if not Assigned(xd.XMNode) then Exit;
  if (Column = 0) and (Kind in [TVTImageKind.ikNormal, ikSelected]) then
   if xd.FlagDelete then ImageIndex := 305
   else if xd.FlagSelect then ImageIndex := 304
   else if xd.XMNode.HasAttribute(AT_SIZE) then ImageIndex := 144
   else if xd.XMNode.HasAttribute(AT_ARRAY) then ImageIndex := 285
   else ImageIndex := 203;
end;

procedure TFormPsk.TreeGetText(Sender: TBaseVirtualTree; Node: PVirtualNode; Column: TColumnIndex; TextType: TVSTTextType; var CellText: string);
  procedure SetData(n: IXMLNode; atr: string);
   var
    V: Variant;
  begin
    if Assigned(n) and n.HasAttribute(atr) then
     begin
      V := n.Attributes[atr];
      if VarIsNull(V) then CellText := ' '
      else CellText := V;
     end
     else CellText := ' ';
  end;
  procedure SetDataTip(n: IXMLNode);
   var
    V: Variant;
  begin
    CellText := ' ';
    if Assigned(n) and n.HasAttribute(AT_TIP) then
     begin
      V := n.Attributes[AT_TIP];
      if not VarIsNull(V) then TPars.TypeDic.TryGetValue(Integer(V), CellText);
     end
  end;
 var
  p: PNodeExData;
begin
  p := Sender.GetNodeData(Node);
  if not Assigned(p.XMNode) then Exit;
  case Column of
   0: CellText := p.XMNode.NodeName;
   1: if p.XMNode.HasAttribute(AT_SIZE) then CellText := ' '
      else SetDataTip(p.XMNode.ChildNodes.FindNode(T_DEV));
   2: SetData(p.XMNode.ChildNodes.FindNode(T_DEV), AT_INDEX);
   3: SetData(p.XMNode, AT_ARRAY);
   4: SetData(p.XMNode, AT_ZND);
   5: SetData(p.XMNode, AT_METR);
  end
end;

procedure TFormPsk.updClick(Sender: TObject);
begin
  UpdateTree
end;

procedure TFormPsk.UpdateTree;
 var
  n: IXMLNode;
  procedure Add(Parent :PVirtualNode; u: IXMLNode);
   var
    pv: PVirtualNode;
    i: Integer;
  begin
    pv := Tree.AddChild(Parent);
    Include(pv.States, vsExpanded);
    PNodeExData(Tree.GetNodeData(pv)).Init(u);
    if u.HasAttribute(AT_SIZE) then for I := 0 to u.ChildNodes.Count-1 do Add(pv, u.ChildNodes[i])
  end;
begin
  Tree.BeginUpdate;
  try
   ClearTree;
   n := FindWork(FXMLInfo, FXMLInfo.ChildNodes[0].Attributes[AT_ADDR]);
   if Assigned(n) then Add(nil, n);
   n := FindRam(FXMLInfo, FXMLInfo.ChildNodes[0].Attributes[AT_ADDR]);
   if Assigned(n) then Add(nil, n);
   NSave.Enabled := False;
  finally
   Tree.EndUpdate;
  end;
end;

procedure TFormPsk.WMEndEditing(var Message: TMessage);
begin
  Tree.EndEditNode;
end;

procedure TFormPsk.WMStartEditing(var Message: TMessage);
var
  Node: PVirtualNode;
begin
  Node := Pointer(Message.WParam);
  // Note: the test whether a node can really be edited is done in the OnEditing event.
  if Message.LParam > 0 then Tree.EditNode(Node, Message.LParam);
end;

function TFormPsk.BeginEdit: Boolean;
begin
  Result := True;
  FEdit.Show;
  FEdit.SetFocus;
end;

function TFormPsk.CancelEdit: Boolean;
begin
  Result := True;
  if Assigned(FEdit) then FreeAndNil(FEdit);
end;

procedure TFormPsk.EditKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
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
        PostMessage(Self.Handle, WM_ENDEDITING, 0, 0);
        Key := 0;
      end;

    VK_UP,
    VK_DOWN:
      begin
        // Consider special cases before finishing edit mode.
        CanAdvance := Shift = [];
        if FEdit is TComboBox then
          CanAdvance := CanAdvance and not TComboBox(FEdit).DroppedDown;
//        if FEdit is TDateTimePicker then
//          CanAdvance :=  CanAdvance and not TDateTimePicker(FEdit).DroppedDown;

        if CanAdvance then
        begin
          // Forward the keypress to the tree. It will asynchronously change the focused node.
          PostMessage(Tree.Handle, WM_KEYDOWN, Key, 0);
          Key := 0;
        end;
      end;
  end;
end;

procedure TFormPsk.EditKeyUp(Sender: TObject; var Key: Word; Shift: TShiftState);
 var
  d: IXMLNode;
  old: Integer;
begin
  case Key of
    VK_SPACE:
     begin
      if FEditColumn = 2 then if FEdit is TEdit then
       begin
        old := 0;
        ExecXTree(FindWork(FXMLInfo, FXMLInfo.ChildNodes[0].Attributes[AT_ADDR]), procedure(n: IXMLNode)
        begin
          if n.HasAttribute(AT_INDEX) and n.HasAttribute(AT_TIP) and (n.Attributes[AT_INDEX] > old) then
           begin
            old := n.Attributes[AT_INDEX];
            d := n;
           end;
        end);
        TEdit(FEdit).Text := (old + TPars.VarTypeToLength(d.Attributes[AT_TIP])).ToString;
       end;
      Key := 0;
     end;
    VK_ESCAPE:
      begin
        Tree.CancelEditNode;
        Key := 0;
      end;//VK_ESCAPE
  end;//case
end;

function TFormPsk.EndEdit: Boolean;
 var
  s: string;
  function StrToType: Integer;
   var
    p: TPair<Integer, string>;
  begin
    Result := 2;
    for p in TPars.TypeDic do if SameText(s, p.Value) then Exit(p.Key)
  end;
  procedure SetAttr(root: IXMLNode; const AttrName: string);
   var
    a: IXMLNode;
  begin
    if Trim(s) = '' then
     begin
      a := root.AttributeNodes.FindNode(AttrName);
      if Assigned(a) then root.AttributeNodes.Remove(a);
     end
    else root.Attributes[AttrName] := s;
  end;
 var
  n, d: IXMLNode;
begin
  n := PnodeExData(Tree.GetNodeData(FEditNode)).XMNode;
  Result := True;
  Tree.SetFocus;
  if FEdit is TComboBox then S := TComboBox(FEdit).Text
  else if FEdit is TEdit then S := TEdit(FEdit).Text
  else s := '';
  FreeAndNil(Fedit);
  if not Assigned(n) then Exit;
  d := n.ChildNodes.FindNode(T_DEV);
  if n.HasAttribute(AT_SIZE) then
   case FEditColumn of
    0: RenameNode(n, S, True);
    4: SetAttr(n,AT_ZND);
    5: SetAttr(n,AT_METR);
   end
  else if Assigned(d) and d.HasAttribute(AT_TIP) then
   case FEditColumn of
    0: RenameNode(n, S, True);
    1: d.Attributes[AT_TIP] := StrToType();
    2: SetAttr(d, AT_INDEX);
    3: SetAttr(n, AT_ARRAY);
    4: SetAttr(n, AT_ZND);
    5: SetAttr(n, AT_METR);
   end;
end;

function TFormPsk.GetBounds: TRect;
begin
  Result := FEdit.BoundsRect;
end;

procedure TFormPsk.GetMetrStrings(var Values: TStrings; node: IXMLNode = nil);
begin
  FScript.GetMetrStrings(Values, node);
end;

function TFormPsk.PrepareEdit(Tree: TBaseVirtualTree; Node: PVirtualNode; Column: TColumnIndex): Boolean;
 type
   TGetItems = procedure(var Items: TStrings; node: IXMLNode = nil) of object;
  procedure CreateEdit(root: IXMLNode; const NodeAttr: string; IsText: Boolean = False);
  begin
    FEdit := TEdit.Create(nil);
    with FEdit as TEdit do
     begin
      Visible := False;
      Parent := Tree;
      if IsText then Text := NodeAttr
      else if root.HasAttribute(NodeAttr) then Text := root.Attributes[NodeAttr];
      OnKeyDown := EditKeyDown;
      OnKeyUp := EditKeyUp;
     end;
  end;
  procedure CreateComboBox(root: IXMLNode; const NodeAttr: string; FunItems: TGetItems; const UserText: string);
   var
    s: TStrings;
  begin
    FEdit := TComboBox.Create(nil);
    try
     s := TStringList.Create;
     FunItems(s, root);
     TStringList(s).Sort;
     with FEdit as TComboBox do
      begin
       Visible := False;
       Parent := Tree;
       if UserText <> '' then Text := UserText
       else if root.HasAttribute(NodeAttr) then Text := root.Attributes[NodeAttr];
       Items := s;
       OnKeyDown := EditKeyDown;
       OnKeyUp := EditKeyUp;
      end;
     finally
      s.Free;
     end;
  end;
 var
  n, d: IXMLNode;
  s: string;
begin
  Result := False;
  FEditColumn := Column;
  FEditNode := Node;
  if Assigned(FEdit) then FreeAndNil(FEdit);
  n := PnodeExData(Tree.GetNodeData(Node)).XMNode;
  if not Assigned(n) then Exit;
  if (n.NodeName = T_RAM) or (n.NodeName = T_WRK) then Exit;
  d := n.ChildNodes.FindNode(T_DEV);
  if n.HasAttribute(AT_SIZE) then
   begin
    case Column of
     0: CreateEdit(n, n.NodeName, True);
     1,2,3: Exit;
     4: CreateEdit(n, AT_ZND);
     5: CreateComboBox(n, AT_METR, GetMetrStrings, '');
    end;
   end
  else if Assigned(d) and d.HasAttribute(AT_TIP) then
   begin
    case Column of
     0: CreateEdit(n, n.NodeName, True);
     1: begin
         s := '';
         TPars.TypeDic.TryGetValue(Integer(d.Attributes[AT_TIP]), s);
         CreateComboBox(d, AT_TIP, TPars.GetTypeStrings, s);
        end;
     2: CreateEdit(d, AT_INDEX);
     3: CreateEdit(n, AT_ARRAY);
     4: CreateEdit(n, AT_ZND);
     5: CreateComboBox(n, AT_METR, GetMetrStrings, '');
    end;
   end
  else Exit;
  Result := True;
end;

procedure TFormPsk.ProcessMessage(var Message: TMessage);
begin
  FEdit.WindowProc(Message);
end;

procedure TFormPsk.SetBounds2(R: TRect);
 var
  Dummy: Integer;
begin
  // Since we don't want to activate grid extensions in the tree (this would influence how the selection is drawn)
  // we have to set the edit's width explicitly to the width of the column.
  Tree.Header.Columns.GetColumnBounds(FEditColumn, Dummy, R.Right);
  FEdit.BoundsRect := R;
end;

initialization
  RegisterClass(TFormPsk);
  TRegister.AddType<TFormPsk, IForm>.LiveTime(ltSingletonNamed);
finalization
  GContainer.RemoveModel<TFormPsk>;
end.

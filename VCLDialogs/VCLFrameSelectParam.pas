unit VCLFrameSelectParam;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Data.DB, VirtualTrees.Types,
  Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.Menus, Vcl.PlatformDefaultStyleActnCtrls, Vcl.ActnPopup, VirtualTrees,
  ActnCtrls, VirtualTrees.BaseAncestorVCL, VirtualTrees.BaseTree,
  VirtualTrees.AncestorVCL;

type

  PNodeExData = ^TNodeExData;
  TNodeExData = record
    Caption: string;
    //ADTField: TADTField;
    DEVField: TField;
    DEVChecked: Boolean;
    CLCField: TField;
    CLCChecked: Boolean;
  end;

  TFrameSelectParam = class(TFrame)
    Tree: TVirtualStringTree;
    ppM: TPopupActionBar;
    NSet: TMenuItem;
    NSetAll: TMenuItem;
    NSetRow: TMenuItem;
    NSetTrr: TMenuItem;
    NDel: TMenuItem;
    NClrAll: TMenuItem;
    NClrRow: TMenuItem;
    NClrTrr: TMenuItem;
    N1: TMenuItem;
    NSetChild: TMenuItem;
    NSetChildALL: TMenuItem;
    NSetChildRow: TMenuItem;
    NSetChildTRR: TMenuItem;
    NClrChild: TMenuItem;
    NClrChildALL: TMenuItem;
    NClrChildRow: TMenuItem;
    NClrChildTrr: TMenuItem;
    procedure TreeGetNodeDataSize(Sender: TBaseVirtualTree; var NodeDataSize: Integer);
    procedure TreeGetText(Sender: TBaseVirtualTree; Node: PVirtualNode; Column: TColumnIndex; TextType: TVSTTextType; var CellText: string);
    procedure TreeAfterCellPaint(Sender: TBaseVirtualTree; TargetCanvas: TCanvas; Node: PVirtualNode; Column: TColumnIndex;
      CellRect: TRect);
    procedure TreeMouseDown(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
    procedure ppMPopup(Sender: TObject);
    procedure ppClick(Sender: TObject);
  private
    RootHot: PVirtualNode;
    type TSelType = (stDEV, stCLC, stALL);
    procedure SelectData(root: PVirtualNode; selFlag: Boolean; itemType: TSelType);
    procedure InnerInitTree(BD: TDataSet);
    procedure DrawCheckBox(const Canvas: TCanvas; const Rect: TRect; const Checked: Boolean);
  public
    function GetSelected: TArray<TField>;
    procedure InitTree(BD: TDataSet); overload;
    procedure InitTree(datas: TArray<TDataSet>); overload;
  end;

implementation

uses Themes, Winapi.UxTheme, Types, tools;

{$R *.dfm}

{ TFrameSelectParam }

procedure TFrameSelectParam.DrawCheckBox(const Canvas: TCanvas; const Rect: TRect; const Checked: Boolean);
 var
  Details: TThemedElementDetails;
  X, Y: Integer;
  R: TRect;
  NonThemedCheckBoxState: Cardinal;
 const
  CHECKBOX_SIZE = 13;
begin
  X := Rect.Left + (Rect.Right - Rect.Left - CHECKBOX_SIZE) div 2;
  Y := Rect.Top + (Rect.Bottom - Rect.Top - CHECKBOX_SIZE) div 2;
  R := Types.Rect(X, Y, X + CHECKBOX_SIZE, Y + CHECKBOX_SIZE);
  if StyleServices.Enabled then // If it is not themed, but the OS is themed, you can check it like this
   begin
    if Checked then Details := StyleServices.GetElementDetails(tbCheckBoxCheckedNormal)
    else Details := StyleServices.GetElementDetails(tbCheckBoxUncheckedNormal);
    StyleServices.DrawElement(Canvas.Handle, Details, R);
   end
  else
   begin
    // Fill the background
    Canvas.FillRect(Rect);
    NonThemedCheckBoxState := DFCS_BUTTONCHECK;
    if Checked then  NonThemedCheckBoxState := NonThemedCheckBoxState or DFCS_CHECKED;
    DrawFrameControl(Canvas.Handle, R, DFC_BUTTON, NonThemedCheckBoxState);
   end;
end;

function TFrameSelectParam.GetSelected: TArray<TField>;
 var
  pv : PVirtualNode;
begin
  for pv in Tree.Nodes do with PNodeExData(Tree.GetNodeData(pv))^ do
   begin
    if DEVChecked then CArray.Add<TField>(Result, DEVField);
    DEVChecked := False;
    if CLCChecked then CArray.Add<TField>(Result, CLCField);
    CLCChecked := False;
   end;
  Tree.Repaint;
end;

procedure TFrameSelectParam.InitTree(BD: TDataSet);
begin
  Tree.Clear;
  InnerInitTree(BD);
end;

procedure TFrameSelectParam.InitTree(datas: TArray<TDataSet>);
 var
  ds: TDataSet;
begin
  Tree.Clear;
  for ds in datas do InnerInitTree(ds);
end;

procedure TFrameSelectParam.InnerInitTree(BD: TDataSet);
  procedure RecurObjectView(r: TFields; p: PVirtualNode);
   var
    i: Integer;
    chn: PVirtualNode;
    xd: PNodeExData;
  begin
    for i := 0 to r.Count-1 do
     begin
      chn := Tree.AddChild(P);
      Include(chn.States, vsExpanded);
      xd := Tree.GetNodeData(chn);
      xd.Caption := r[i].FieldName;
      if r[i] is TADTField then with TADTField(r[i]) do
       begin
        /// стандартное поле или ветвь
        xd.DEVField := Fields.FindField(T_DEV);
        xd.CLCField := Fields.FindField(T_CLC);
        /// проверка на ветвь и рекурсия
        if not Assigned(xd.DEVField) and not Assigned(xd.CLCField) then RecurObjectView(Fields, chn);
       end
        /// пользовательское поле например ID
      else xd.DEVField := r[i];
     end;
  end;
  var
   i: Integer;
   procedure AddField(f: TField; path: TArray<string>);
    var
     d,c: Boolean;
     last: string;
     s: string;
     root, pv: PVirtualNode;
    label
      Labe1;
   begin
     last := path[High(path)];
     d := last = T_DEV;
     c := last = T_CLC;
     if c or d then Delete(path, High(path), 1);
     root := nil;
     for s in path do
      begin
       for pv in Tree.ChildNodes(root) do if s = PNodeExData(Tree.GetNodeData(pv)).Caption then
        begin
         root := pv;
         goto Labe1;
        end;
        root := Tree.AddChild(root);
        Include(root.States, vsExpanded);
        PNodeExData(Tree.GetNodeData(root)).Caption := s;
       Labe1:
      end;
     with PNodeExData(Tree.GetNodeData(root))^ do if c then CLCField := f  else DEVField := f
   end;
begin
  BD.Open;
  if BD.ObjectView then RecurObjectView(BD.Fields, nil)
  else for i := 0 to BD.FieldList.Count-1 do AddField(BD.FieldList[i], BD.FieldList[i].FullName.Split(['.']));
end;

procedure TFrameSelectParam.ppClick(Sender: TObject);
 var
  Flg: Boolean;
  m : TMenuItem;
  t: TSelType;
begin
  m := TMenuItem(Sender);
  Flg := (m.Parent = NSet) or (m.Parent = NSetChild);
  SelectData(RootHot, Flg, TSelType(m.Tag))
end;

procedure TFrameSelectParam.ppMPopup(Sender: TObject);
begin
  NClrChild.Visible := False;
  NSetChild.Visible := False;
  if Assigned(Tree.HotNode) then
   begin
    RootHot := Tree.HotNode;
    NClrChild.Visible := True;
    NSetChild.Visible := True;
   end
  else RootHot := nil;
end;

procedure TFrameSelectParam.SelectData(root: PVirtualNode; selFlag: Boolean; itemType: TSelType);
  procedure Chek(n: PVirtualNode);
  begin
    with PNodeExData(Tree.GetNodeData(n))^ do
     begin
      if Assigned(DEVField) and (itemType in [stALL, stDEV]) then DEVChecked := selFlag;
      if Assigned(CLCField) and (itemType in [stALL, stCLC]) then CLCChecked := selFlag;
     end;
  end;
  procedure chldChek(rt: PVirtualNode);
   var
    n: PVirtualNode;
  begin
    for n in Tree.ChildNodes(rt) do
     begin
      Chek(n);
      if n.ChildCount > 0 then chldChek(n);
     end
  end;
 var
  n: PVirtualNode;
begin
  if not Assigned(root) then
    for n in Tree.Nodes() do Chek(n)
  else
    chldChek(root);
  Tree.Repaint;
end;

procedure TFrameSelectParam.TreeGetNodeDataSize(Sender: TBaseVirtualTree; var NodeDataSize: Integer);
begin
  NodeDataSize := SizeOf(TNodeExData);
end;

procedure TFrameSelectParam.TreeGetText(Sender: TBaseVirtualTree; Node: PVirtualNode; Column: TColumnIndex; TextType: TVSTTextType; var CellText: string);
 var
  p: PNodeExData;
begin
  p := Sender.GetNodeData(Node);
  CellText := '   ';
  if Column <> 2 then Exit;
  CellText := p.Caption;
end;

procedure TFrameSelectParam.TreeMouseDown(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
 var
  Info: THitInfo;
  xd: PNodeExData;
begin
  if Button = mbLeft then
  begin
    Tree.GetHitTestInfoAt(X,Y,true,Info);
    if (Info.HitColumn < 2) and Assigned(Info.HitNode) then
     begin
      xd := Tree.GetNodeData(Info.HitNode);
      if (Info.HitColumn = 0) and Assigned(xd.DEVField) then xd.DEVChecked := not xd.DEVChecked
      else if (Info.HitColumn = 1) and Assigned(xd.CLCField) then xd.CLCChecked := not xd.CLCChecked;
      Tree.InvalidateNode(Info.HitNode);
     end;
  end;
end;

procedure TFrameSelectParam.TreeAfterCellPaint(Sender: TBaseVirtualTree; TargetCanvas: TCanvas; Node: PVirtualNode; Column: TColumnIndex; CellRect: TRect);
 var
  xd: PNodeExData;
begin
  xd := Tree.GetNodeData(Node);
  if (Column = 0) and Assigned(xd.DEVField) then DrawCheckBox(TargetCanvas, CellRect, xd.DEVChecked)
  else if (Column = 1) and Assigned(xd.CLCField) then DrawCheckBox(TargetCanvas, CellRect, xd.CLCChecked)
end;

end.

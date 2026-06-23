unit AbstractDlgParams;

interface

uses DockIForm, tools,    VirtualTrees.Types,
  Xml.XMLIntf, Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics, System.IOUtils,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls, VirtualTrees, Vcl.Menus, Vcl.PlatformDefaultStyleActnCtrls, Vcl.ActnPopup,
  VirtualTrees.BaseAncestorVCL, VirtualTrees.BaseTree, VirtualTrees.AncestorVCL;

const
 USER_PARAM = '__USER_PARAM__';
 VIEW_DB = '__VIEW__';

type
  TypeDataShow = (hdtLog, hdtRam, hdtGlu);

  PNodeExData = ^TNodeExData;
  TNodeExData = record
    XMNode: IXMLNode;
  end;
  TFormParamsAbstract = class(TDialogIForm)
    Tree: TVirtualStringTree;
    btExit: TButton;
    btApply: TButton;
    ppM: TPopupActionBar;
    NSet: TMenuItem;
    NDel: TMenuItem;
    NSetAll: TMenuItem;
    NSetRow: TMenuItem;
    SetTrr: TMenuItem;
    NClrAll: TMenuItem;
    NClrRow: TMenuItem;
    NClrTrr: TMenuItem;
    NSetChild: TMenuItem;
    NClrChild: TMenuItem;
    N1: TMenuItem;
    N2: TMenuItem;
    N3: TMenuItem;
    N4: TMenuItem;
    N5: TMenuItem;
    N6: TMenuItem;
    N7: TMenuItem;
    procedure btExitClick(Sender: TObject);
    procedure btApplyClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure ClickAllMenu(Sender: TObject);
    procedure ClickAllChild(Sender: TObject);
    procedure ppMPopup(Sender: TObject);
    procedure TreeGetText(Sender: TBaseVirtualTree; Node: PVirtualNode; Column: TColumnIndex; TextType: TVSTTextType; var CellText: string);
    procedure TreeAfterCellPaint(Sender: TBaseVirtualTree; TargetCanvas: TCanvas; Node: PVirtualNode; Column: TColumnIndex; CellRect: TRect);
    procedure TreeMouseDown(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
  private
    RootHot: IXMLNode;
    function Checked(Colomn: Integer; node: IXMLNode): Boolean;
    procedure SetChecked(Colomn: Integer; node: IXMLNode; Flag: Boolean);
    procedure SetCheckedAll(Root: IXMLNode; Colomn: Integer; Flag: Boolean);
  protected
   const
    CL_TYPE: array [TypeDataShow] of string = (T_WRK, T_RAM, 'GLU');
   var
    Doc: IXMLDocument;
    TypeData: TypeDataShow;
    CheckName: string;
    procedure ClearTree;
    procedure UpdateTree;
    procedure DoApply; virtual; abstract;
    procedure DoExitClick; virtual; abstract;
  end;

implementation

uses  Themes, Winapi.UxTheme, Types;

{$R *.dfm}

procedure DrawCheckBox(Sender: TVirtualStringTree; const Canvas: TCanvas; const Rect: TRect; const Checked: Boolean);
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

{ TFormShowParams }

procedure TFormParamsAbstract.FormCreate(Sender: TObject);
begin
  Tree.NodeDataSize := SizeOf(TNodeExData);
end;

procedure TFormParamsAbstract.btApplyClick(Sender: TObject);
begin
  btApply.Enabled := False;
  DoApply;
end;

procedure TFormParamsAbstract.btExitClick(Sender: TObject);
begin
  DoExitClick;
end;

function TFormParamsAbstract.Checked(Colomn: Integer; node: IXMLNode): Boolean;
 var
  n: IXMLNode;
begin
  if Colomn = 0 then n := node.ChildNodes.FindNode(T_DEV) else n := node.ChildNodes.FindNode(T_CLC);
   Result := Assigned(n) and n.HasAttribute(CheckName) and Boolean(n.Attributes[CheckName]);
end;

procedure TFormParamsAbstract.ClickAllMenu(Sender: TObject);
 var
  n, m, root: IXMLNode;
  function testN: Boolean;
  begin
    if not n.HasAttribute(AT_ADDR) then Exit(False);
    root := n.ChildNodes.FindNode(CL_TYPE[TypeData]);
    Result := Assigned(root);
  end;
begin
  for m in XEnum(Doc.DocumentElement) do
   for n in XEnum(m) do
    if testN then SetCheckedAll(root, TMenuItem(Sender).Tag, TMenuItem(Sender).Parent = NSet);
end;

procedure TFormParamsAbstract.ClickAllChild(Sender: TObject);
begin
  SetCheckedAll(RootHot, TMenuItem(Sender).Tag, TMenuItem(Sender).Parent = NSetChild);
end;

procedure TFormParamsAbstract.SetChecked(Colomn: Integer; node: IXMLNode; Flag: Boolean);
 var
  n: IXMLNode;
begin
  if Colomn = 0 then n := node.ChildNodes.FindNode(T_DEV) else n := node.ChildNodes.FindNode(T_CLC);
  if Assigned(n) and n.HasAttribute(CheckName) then n.Attributes[CheckName] := Flag;
end;

procedure TFormParamsAbstract.SetCheckedAll(Root: IXMLNode; Colomn: Integer; Flag: Boolean);
begin
  case Colomn of
   0,1: ExecXTree(Root, procedure(n: IXMLNode)
        begin
          SetChecked(Colomn, n, Flag);
        end);
   else ExecXTree(Root, procedure(n: IXMLNode)
        begin
          SetChecked(0, n, Flag);
          SetChecked(1, n, Flag);
        end);
  end;
  Tree.Repaint;
  btApply.Enabled := True;
end;

procedure TFormParamsAbstract.ClearTree;
 var
  pv: PVirtualNode;
begin
  for pv in Tree.Nodes do PNodeExData(Tree.GetNodeData(pv)).XMNode := nil;
  Tree.Clear;
end;

procedure TFormParamsAbstract.FormDestroy(Sender: TObject);
begin
  ClearTree;
end;

procedure TFormParamsAbstract.ppMPopup(Sender: TObject);
begin
  NClrChild.Visible := False;
  NSetChild.Visible := False;
  if Assigned(Tree.HotNode) then
   begin
    RootHot := PNodeExData(Tree.GetNodeData(Tree.HotNode)).XMNode;
    NClrChild.Visible := True;
    NSetChild.Visible := True;
   end;
end;

procedure TFormParamsAbstract.TreeAfterCellPaint(Sender: TBaseVirtualTree; TargetCanvas: TCanvas; Node: PVirtualNode; Column: TColumnIndex; CellRect: TRect);
 var
  xd: PNodeExData;
  n: IXMLNode;
begin
  if Column < 2 then
   begin
    xd := Tree.GetNodeData(Node);
    if Column = 0 then n := xd.XMNode.ChildNodes.FindNode(T_DEV) else n := xd.XMNode.ChildNodes.FindNode(T_CLC);
    if Assigned(n) and n.HasAttribute(CheckName) then DrawCheckBox(Sender as TVirtualStringTree, TargetCanvas, CellRect, Checked(Column,  xd.XMNode));
   end;
end;

procedure TFormParamsAbstract.TreeGetText(Sender: TBaseVirtualTree; Node: PVirtualNode; Column: TColumnIndex; TextType: TVSTTextType; var CellText: string);
 var
  p: PNodeExData;
begin
  p := Sender.GetNodeData(Node);
  CellText := '   ';
  if not Assigned(p.XMNode) then Exit;
  if Column = 2 then CellText := p.XMNode.NodeName;
end;

procedure TFormParamsAbstract.TreeMouseDown(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
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
      SetChecked(Info.HitColumn, xd.XMNode, not Checked(Info.HitColumn, xd.XMNode));
      Tree.InvalidateNode(Info.HitNode);
      btApply.Enabled := True;
     end;
  end;
end;

procedure TFormParamsAbstract.UpdateTree;
  function CreatePV(Parent :PVirtualNode; u: IXMLNode): PVirtualNode;
  begin
    Result := Tree.AddChild(Parent);
    Include(Result.States, vsExpanded);
    Result.CheckType := ctCheckBox;
    PNodeExData(Tree.GetNodeData(Result)).XMNode := u;
  end;
  procedure AddPV(Parent :PVirtualNode; u: IXMLNode);
   var
    n: IXMLNode;
    pv: PVirtualNode;
  begin
    pv := CreatePV(Parent, u);
    if PNodeExData(Tree.GetNodeData(pv)).XMNode.HasAttribute(AT_SIZE) then for n in XEnum(u) do AddPV(pv, n)
  end;
 var
  r, n, prm, i: IXMLNode;
  pv: PVirtualNode;
begin
  Tree.BeginUpdate;
  try
   ClearTree;
   for r in XEnum(Doc.DocumentElement) do for n in XEnum(r) do
    begin
     prm := n.ChildNodes.FindNode(CL_TYPE[TypeData]);
     if Assigned(prm) then
      begin
       pv := CreatePV(nil, n);
       for i in XEnum(prm) do AddPV(pv, i);
      end;
    end;
  finally
   Tree.EndUpdate;
  end;
end;

end.

unit DlgFilterParams;

interface

uses RootImpl, ExtendIntf, DockIForm, debug_except, DeviceIntf, PluginAPI, Data.DB,  TypInfo, Xml.XMLIntf, RootIntf, Container,
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics, tools,  System.IOUtils,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls, VirtualTrees, Vcl.Menus, Vcl.PlatformDefaultStyleActnCtrls, Vcl.ActnPopup,
  System.Generics.Collections,
  System.Bindings.Expression,
  System.Bindings.Helper,
  System.Bindings.Graph, RTTI;

type
  EFormFilterParams = class(EBaseException);
  TypeDataShow = (hdtLog, hdtRam, hdtGlu);

//  TUpdateNotify = TProc;

  TFilterParams = record
  private
    DataBase: string;
    TypeData: TypeDataShow;
  public
    constructor Create(const ADataBase: string; ATypeData: TypeDataShow);
  end;

  PNodeExData = ^TNodeExData;
  TNodeExData = record
    XMNode: IXMLNode;
  end;
  TFormFilterParams = class(TDialogIForm, IDialog, IDialog<TFilterParams>)
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
    procedure FormDestroy(Sender: TObject);
    procedure TreeGetText(Sender: TBaseVirtualTree; Node: PVirtualNode; Column: TColumnIndex; TextType: TVSTTextType; var CellText: string);
    procedure TreeAfterCellPaint(Sender: TBaseVirtualTree; TargetCanvas: TCanvas; Node: PVirtualNode; Column: TColumnIndex; CellRect: TRect);
    procedure TreeMouseDown(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
    procedure ClickAllMenu(Sender: TObject);
    procedure ppMPopup(Sender: TObject);
    procedure ClickAllChild(Sender: TObject);
    procedure FormCreate(Sender: TObject);
  private
//    procedure SetUpdateParams(const Value: IXMLNode);
//    function GetUpdateParams: IXMLNode;
//    FShowParams: TShowParams;
    RootHot: IXMLNode;
    FS_TableUpdate: string;
    FDoc: IALLMetaData;
    FData: TFilterParams;
    procedure ClearTree;
    procedure UpdateTree;
    function Checked(Colomn: Integer; node: IXMLNode): Boolean;
    procedure SetChecked(Colomn: Integer; node: IXMLNode; Flag: Boolean);
    procedure SetCheckedAll(Root: IXMLNode; Colomn: Integer; Flag: Boolean);
    const
     CL_NAME: array [0..1] of string = ('ROW_CHEK', 'TRR_CHEK');
     CL_TYPE: array [TypeDataShow] of string = (AT_WRK, AT_RAM, 'GLU');
     ROW_CHEK = 'ROW_CHEK';
     TRR_CHEK = 'TRR_CHEK';
  protected
    function GetInfo: PTypeInfo;
    procedure Execute(Data: TFilterParams);
  public
    property S_TableUpdate: string read FS_TableUpdate write FS_TableUpdate;
  end;

implementation

uses  Themes, UxTheme, Types;

{$R *.dfm}

{ TFilterParams }

constructor TFilterParams.Create(const ADataBase: string; ATypeData: TypeDataShow);
begin
  DataBase := ADataBase;
  TypeData := ATypeData;
end;

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
  if (toThemeAware in TVirtualStringTree(Sender).TreeOptions.PaintOptions) or StyleServices.Enabled then // If it is not themed, but the OS is themed, you can check it like this
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

procedure TFormFilterParams.btApplyClick(Sender: TObject);
begin
  btApply.Enabled := False;
  FDoc.Save;
  TBindings.Notify(Self, 'S_TableUpdate');
//  FShowParams.UpdateNotify();
end;

procedure TFormFilterParams.btExitClick(Sender: TObject);
begin
  RegisterDialog.UnInitialize<Dialog_FilterParameters>;
end;

function TFormFilterParams.Checked(Colomn: Integer; node: IXMLNode): Boolean;
begin
  Result :=  node.HasAttribute(CL_NAME[Colomn]) and node.Attributes[CL_NAME[Colomn]]
end;

procedure TFormFilterParams.SetChecked(Colomn: Integer; node: IXMLNode; Flag: Boolean);
begin
  if node.HasAttribute(CL_NAME[Colomn]) then node.Attributes[CL_NAME[Colomn]] := Flag;
end;

procedure TFormFilterParams.ClickAllMenu(Sender: TObject);
begin
  SetCheckedAll(FDoc.Get.DocumentElement, TMenuItem(Sender).Tag, TMenuItem(Sender).Parent = NSet);
end;

procedure TFormFilterParams.ClickAllChild(Sender: TObject);
begin
  SetCheckedAll(RootHot, TMenuItem(Sender).Tag, TMenuItem(Sender).Parent = NSetChild);
end;

procedure TFormFilterParams.SetCheckedAll(Root: IXMLNode; Colomn: Integer; Flag: Boolean);
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

{procedure TFormShowParams.SetUpdateParams(const Value: IXMLNode);
begin
  FShowParams.Data := Value;
  UpdateTree;
end;

function TFormShowParams.GetUpdateParams: IXMLNode;
begin
  Result := FShowParams.Data;
end;}

procedure TFormFilterParams.ClearTree;
 var
  pv: PVirtualNode;
begin
  for pv in Tree.Nodes do PNodeExData(Tree.GetNodeData(pv)).XMNode := nil;
  Tree.Clear;
end;

procedure TFormFilterParams.Execute(Data: TFilterParams);
 const
  TXTDT: array [TypeDataShow] of string = ('LOG', 'RAM', 'GLU');
// var
//  le: TList<TBindingExpression>;
//  e: TBindingExpression;
begin
  TBindHelper.RemoveExpressions(Self);
  FS_TableUpdate := 'Modul';
  FData := Data;
  FDoc := (GContainer as IALLMetaDataFactory).CreateNew(Data.DataBase);
  ExecXtree(FDoc.Get.DocumentElement, procedure(n: IXMLNode)
  begin
    if (n.HasAttribute(AT_ROW) or n.HasAttribute(AT_INDEX)) and not n.HasAttribute(ROW_CHEK) then n.Attributes[ROW_CHEK] := False;
    if n.HasAttribute(AT_TRR) and not n.HasAttribute(TRR_CHEK) then n.Attributes[TRR_CHEK] := False;
  end);
  Bind((GContainer as IManager), 'C_TableUpdate', ['S_TableUpdate']);
//  Bind.CreateManagedBinding(((GContainer as IManager) as ImanagItem).GetComponent, 'C_TableUpdate', ['S_TableUpdate']);
  UpdateTree;
  Caption := Format('%s[%s]', [Tpath.GetFileNameWithoutExtension(Data.DataBase), TXTDT[Data.TypeData]]);

//  le := TBindingGraph.GetDependentExprs(Self,'',nil);
//   for e in le do
//    begin
//      Tdebug.log(e.Source);
//    end;
//  le.Free;
//
//  le := TBindingGraph.GetDependentExprs(((GContainer as IManager) as ImanagItem).GetComponent,'',nil);
//   for e in le do
//    begin
//      Tdebug.log(e.Source);
//    end;
//  le.Free;

  IShow;
//  FDoc.Get.SaveToFile(ExtractFilePath(ParamStr(0))+'ALLMeta.xml');
end;

procedure TFormFilterParams.FormCreate(Sender: TObject);
begin
  Tree.NodeDataSize := SizeOf(TNodeExData);
end;

procedure TFormFilterParams.FormDestroy(Sender: TObject);
begin
//  ((GContainer as IManager) as IBind).RemoveManagedBinding(Self);
  ClearTree;
end;

function TFormFilterParams.GetInfo: PTypeInfo;
begin
  Result := TypeInfo(Dialog_FilterParameters);
end;

procedure TFormFilterParams.ppMPopup(Sender: TObject);
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

procedure TFormFilterParams.TreeAfterCellPaint(Sender: TBaseVirtualTree; TargetCanvas: TCanvas; Node: PVirtualNode; Column: TColumnIndex; CellRect: TRect);
 var
  xd: PNodeExData;
begin
  if Column < 2 then
   begin
    xd := Tree.GetNodeData(Node);
    if xd.XMNode.HasAttribute(CL_NAME[Column]) then DrawCheckBox(Sender as TVirtualStringTree, TargetCanvas, CellRect, Checked(Column,  xd.XMNode));
   end;
end;

procedure TFormFilterParams.TreeGetText(Sender: TBaseVirtualTree; Node: PVirtualNode; Column: TColumnIndex; TextType: TVSTTextType; var CellText: string);
 var
  p: PNodeExData;
begin
  p := Sender.GetNodeData(Node);
  CellText := '   ';
  if not Assigned(p.XMNode) then Exit;
  if Column = 2 then CellText := p.XMNode.NodeName;
end;

procedure TFormFilterParams.TreeMouseDown(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
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

procedure TFormFilterParams.UpdateTree;
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
    for n in XEnum(u) do AddPV(pv, n)
  end;
 var
  n, prm, i: IXMLNode;
  pv: PVirtualNode;
begin
  Tree.BeginUpdate;
  try
   ClearTree;
   for n in XEnum(FDoc.Get.DocumentElement) do
    begin
     prm := n.ChildNodes.FindNode(CL_TYPE[FData.TypeData]);
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

initialization
  RegisterDialog.Add<TFormFilterParams, Dialog_FilterParameters>;
finalization
  RegisterDialog.Remove<TFormFilterParams>;
end.

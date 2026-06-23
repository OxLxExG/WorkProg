unit FormDlgSyncClock;

interface

uses DeviceIntf, DockIForm, debug_except, ExtendIntf, RootImpl, PluginAPI, RootIntf, DBIntf, DBImpl, Data.DB, Xml.XMLIntf, Container,
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics, System.TypInfo, System.DateUtils,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls, Vcl.ExtCtrls, VirtualTrees;

type
  PNodeXData = ^TNodeXData;
  TNodeXData = record
    Name: string;
    tdev: TTime;
    tpc: TTime;
    Dkadr: Integer;
    Koeff: Double;
    BDKoeff: Double;
  end;

  TDialogSyncDelay = class(TDialogIForm, IDialog, IDialog<IDevice>)
    pnShow: TPanel;
    btClose: TButton;
    btCorrect: TButton;
    Tree: TVirtualStringTree;
    procedure btCloseClick(Sender: TObject);
    procedure btCorrectClick(Sender: TObject);
    procedure TreeGetNodeDataSize(Sender: TBaseVirtualTree; var NodeDataSize: Integer);
    procedure TreeGetText(Sender: TBaseVirtualTree; Node: PVirtualNode; Column: TColumnIndex; TextType: TVSTTextType; var CellText: string);
  private
    Device: IDevice;
    DeviceID: Integer;
    FWorkRes: TWorkEventRes;
    FDBTimeSetDelay, FDBTimeStart: TDateTime;
    procedure UpdateTree;
    procedure SetWorkRes(const Value: TWorkEventRes);
  protected
    function GetInfo: PTypeInfo; override;
    function Execute(InputData: IDevice): Boolean;
    class function ClassIcon: Integer; override;
  public
    property C_BindWorkRes: TWorkEventRes read FWorkRes write SetWorkRes;
  end;


implementation

{$R *.dfm}

uses tools;

{ TDialogSyncDelay }

class function TDialogSyncDelay.ClassIcon: Integer;
begin
  Result := Dialog_SyncDelay_ICON;
end;

function TDialogSyncDelay.GetInfo: PTypeInfo;
begin
  Result :=TypeInfo(Dialog_SyncDelay);
end;

procedure TDialogSyncDelay.SetWorkRes(const Value: TWorkEventRes);
 var
  kadr, Devicekadr: Integer;
  v: Variant;
  pv: PVirtualNode;
  ModulName: string;
begin
  try
    FWorkRes := Value;
    btCorrect.Enabled := True;
    ModulName := FWorkRes.Work.ParentNode.NodeName;
    for pv in Tree.Nodes do with PNodeXData(Tree.GetNodeData(pv))^ do if Name = ModulName then
     begin
      v := XToVar(FWorkRes.Work);
      Devicekadr := v.время.DEV.VALUE;
      tdev := CTime.FromKadr(Devicekadr);
      kadr := CTime.RoundToKadr(Now - FDBTimeStart);
      tpc := CTime.FromKadr(kadr);
      Dkadr := kadr - Devicekadr;
      Koeff := 1+Dkadr/(kadr);
      Tree.InvalidateNode(pv);
      Break;
     end;
  except
    on E: Exception do TDebug.DoException(E);
  end;
end;

procedure TDialogSyncDelay.btCloseClick(Sender: TObject);
begin
  RegisterDialog.UnInitialize<Dialog_SyncDelay>;
end;

procedure TDialogSyncDelay.TreeGetNodeDataSize(Sender: TBaseVirtualTree; var NodeDataSize: Integer);
begin
  NodeDataSize := SizeOf(TNodeXData);
end;

procedure TDialogSyncDelay.TreeGetText(Sender: TBaseVirtualTree; Node: PVirtualNode; Column: TColumnIndex; TextType: TVSTTextType; var CellText: string);
 var
  p: PNodeXData;
begin
  p := Sender.GetNodeData(Node);
  case Column of
   0: CellText := p.Name;
   1: CellText := Ctime.AsString(p.tdev);
   2: CellText := Ctime.AsString(p.tpc);
   3: CellText := p.Dkadr.ToString;
   4: CellText := Format('%1.7f', [p.Koeff]);
   5: CellText := Format('%1.7f', [p.BDKoeff]);
  end;
end;

procedure TDialogSyncDelay.UpdateTree;
 var
  v: Variant;
  px: PNodeXData;
  pv: PVirtualNode;
begin
  Tree.BeginUpdate;
  Tree.Clear;
  ConnectionsPool.Query.Acquire;
  try
   ConnectionsPool.Query.Open('SELECT Модуль, TimeKoeff FROM Modul WHERE (Модуль NOT NULL)');
   for v in ConnectionsPool.Query do
    begin
     pv := Tree.AddChild(nil);
     pv.CheckType := ctCheckBox;
     px := Tree.GetNodeData(pv);
     px.Name := v.Модуль;
     px.BDKoeff := v.TimeKoeff;
    end;
   ConnectionsPool.Query.Close;
  finally
   ConnectionsPool.Query.Release;
   Tree.EndUpdate;
  end;
end;

function TDialogSyncDelay.Execute(InputData: IDevice): Boolean;
  function CheckInform: Boolean;
   var
    c: ICycle;
    s: IStop;
  begin
    Result := True;
    if Supports(Device, ICycle, c) then Exit(c.Cycle);
    if Supports(Device, IStop, s) then Exit(s.IsFlow);
  end;
begin
  Result := True;
  TBindHelper.RemoveExpressions(Self);
  Device := InputData;
  Caption := Format('[%s] Синхронизация часов',[(Device as ICaption).Text]);
  try
   FDBTimeStart := (GContainer as IProjectOptions).Option['TIME_START'];
  except
   FDBTimeStart := StrToDateTime((GContainer as IProjectOptions).Option['TIME_START']);
  end;
  ConnectionsPool.Query.Acquire;
  try
   ConnectionsPool.Query.Open('SELECT id, TimeSetupDelay FROM Device WHERE IName = :P1', [(Device as IManagItem).IName], [ftString]);
   DeviceID := ConnectionsPool.Query.FieldByName('id').AsInteger;
   FDBTimeSetDelay := ConnectionsPool.Query.FieldByName('TimeSetupDelay').AsDateTime; //??? или FireDAC сам переделает ???
  finally
    ConnectionsPool.Query.Release;
  end;
  if not CheckInform then MessageDlg('Необходимо перевести прибор в режим чтения информации !!!', mtWarning, [mbOK], 0);
  Bind('C_BindWorkRes',Device, ['S_WorkEventInfo']);
  UpdateTree();
  IShow;
end;

procedure TDialogSyncDelay.btCorrectClick(Sender: TObject);
 var
  pv: PVirtualNode;
begin
  ConnectionsPool.Query.Acquire;
  try
   for pv in Tree.Nodes do
    if pv.CheckState = csCheckedNormal then
     with PNodeXData(Tree.GetNodeData(pv))^ do
      ConnectionsPool.Query.ExecSQL('UPDATE Modul SET TimeKoeff = :P1 WHERE (Модуль = :P2) AND (fk = :P3)',
                                    [Koeff, Name, DeviceID],
                                    [ftFloat, ftString, ftInteger]);
  finally
    ConnectionsPool.Query.Release;
  end;
  UpdateTree();
end;

initialization
  RegisterDialog.Add<TDialogSyncDelay, Dialog_SyncDelay>;
finalization
  RegisterDialog.Remove<TDialogSyncDelay>;
end.

unit VCLDlgRootDevice;

interface

uses RootIntf, DeviceIntf, debug_except, ExtendIntf, DockIForm, PluginAPI, RootImpl, Container, JDtools, VirtualTrees.Types,
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics, System.TypInfo,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls, Vcl.ComCtrls, Vcl.ExtCtrls, VirtualTrees, Vcl.Menus,
  Vcl.PlatformDefaultStyleActnCtrls, Vcl.ActnPopup, JvComponentBase, JvInspector, JvExControls,
  VirtualTrees.BaseAncestorVCL, VirtualTrees.BaseTree, VirtualTrees.AncestorVCL;

type
  TSubDevaModelData = record
    Model: ModelType;
    DevInfo: TSubDeviceInfo;
    Caption: string;
  end;
  PNodeExData = ^TNodeExData;
  TNodeExData = record
    IsRoot: Boolean;
    DevInfo: TSubDeviceInfo;
    SubDevice: ISubDevice;
   // Model: ModelType;
   // Caption: string;
  end;

  TFormSetupRootDevice = class(TDialogIForm, IDialog, IDialog<IRootDevice>{, INotifyCanClose})
    Splitter: TSplitter;
    PanelRoot: TPanel;
    PanelBoot: TPanel;
    btClose: TButton;
    Tree: TVirtualStringTree;
    ppM: TPopupActionBar;
    NRemove: TMenuItem;
    NConnect: TMenuItem;
    N1: TMenuItem;
    N2: TMenuItem;
    NUp: TMenuItem;
    NDown: TMenuItem;
    insp: TJvInspector;
    InspectorBorlandPainter: TJvInspectorBorlandPainter;
    Timer1: TTimer;
    btUpdate: TButton;
    procedure FormCreate(Sender: TObject);
    procedure TreeGetText(Sender: TBaseVirtualTree; Node: PVirtualNode; Column: TColumnIndex; TextType: TVSTTextType; var CellText: string);
    procedure ppMPopup(Sender: TObject);
    procedure NRemoveClick(Sender: TObject);
    procedure NUpClick(Sender: TObject);
    procedure NDownClick(Sender: TObject);
    procedure TreeAddToSelection(Sender: TBaseVirtualTree; Node: PVirtualNode);
    procedure inspDataValueChanged(Sender: TObject; Data: TJvCustomInspectorData);
    procedure Timer1Timer(Sender: TObject);
    procedure inspEditorKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure btUpdateClick(Sender: TObject);
    procedure btCloseClick(Sender: TObject);
  protected
//    procedure CanClose(var CanClose: Boolean);
    function GetInfo: PTypeInfo; override;
    function Execute(InputData: IRootDevice): Boolean;
    class function ClassIcon: Integer; override;
  private
    FEditData: PNodeExData;
    FEditNode: PVirtualNode;
    FDev: IRootDevice;
    FModels: TArray<TSubDevaModelData>;
    procedure ConnectClick(Sender: TObject);
    procedure UpdateTree;
    procedure ClearTree;
  public
    { Public declarations }
  end;

implementation

{$R *.dfm}

uses tools;

{ TFormSetupRootDevice }

//procedure TFormSetupRootDevice.CanClose(var CanClose: Boolean);
//begin
//  FDev := nil;
//  ClearTree;
//end;

procedure TFormSetupRootDevice.btCloseClick(Sender: TObject);
begin
  RegisterDialog.UnInitialize<Dialog_SetupRootDevice>;
end;

procedure TFormSetupRootDevice.btUpdateClick(Sender: TObject);
begin
  Timer1.Enabled := True;
end;

class function TFormSetupRootDevice.ClassIcon: Integer;
begin
  Result := 114;
end;

procedure TFormSetupRootDevice.ClearTree;
// var
//  pv: PVirtualNode;
begin
//  for pv in Tree.Nodes do PNodeExData(Tree.GetNodeData(pv)).SubDevice := nil;
  Tree.Clear;
end;

function TFormSetupRootDevice.GetInfo: PTypeInfo;
begin
  Result := TypeInfo(Dialog_SetupRootDevice);
end;

procedure TFormSetupRootDevice.inspDataValueChanged(Sender: TObject; Data: TJvCustomInspectorData);
begin
  (FDev as IBind).Notify('S_PublishedChanged');
end;

procedure TFormSetupRootDevice.inspEditorKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
begin
  Timer1.Enabled := False;
end;

procedure TFormSetupRootDevice.ConnectClick(Sender: TObject);
begin
  FDev.AddOrReplase(PTypeInfo(TMenuItem(Sender).Tag));
  UpdateTree;
  (FDev as IBind).Notify('S_PublishedChanged');
end;

procedure TFormSetupRootDevice.NUpClick(Sender: TObject);
begin
  if Assigned(FEditData.SubDevice) then
   begin
    FDev.TryMove(FEditData.SubDevice, True);
    UpdateTree;
    (FDev as IBind).Notify('S_PublishedChanged');
   end;
end;

procedure TFormSetupRootDevice.NDownClick(Sender: TObject);
begin
  if Assigned(FEditData.SubDevice) then
   begin
    FDev.TryMove(FEditData.SubDevice, False);
    UpdateTree;
    (FDev as IBind).Notify('S_PublishedChanged');
   end;
end;

procedure TFormSetupRootDevice.NRemoveClick(Sender: TObject);
 var
  i: Integer;
begin
  if Assigned(FEditData.SubDevice) then
   begin
    i := FDev.Index(FEditData.SubDevice);
    FEditData.SubDevice := nil;
    FDev.Remove(i);
    UpdateTree;
    (FDev as IBind).Notify('S_PublishedChanged');
   end;
end;

procedure TFormSetupRootDevice.ppMPopup(Sender: TObject);
 var
  md: TSubDevaModelData;
  m: TMenuItem;
begin
  NConnect.Clear;
  NRemove.Enabled := False;
  FEditData := nil;
  FEditNode := nil;
  if not Assigned(Tree.HotNode) then Exit;
  FEditNode := Tree.HotNode;
  FEditData := Tree.GetNodeData(FEditNode);
  for md in FModels do if md.DevInfo.Category = FEditData.DevInfo.Category then
   begin
    m := TMenuItem.Create(NConnect);
    m.Caption := md.Caption;
    m.Tag := Integer(MD.Model);
    m.OnClick := ConnectClick;
    NConnect.Add(m);
   end;
  if {not (sdtMastExist in FEditData.DevInfo.Typ) and} not FEditData.IsRoot then NRemove.Enabled := True;
end;

procedure TFormSetupRootDevice.Timer1Timer(Sender: TObject);
begin
  insp.RefreshValues;
end;

procedure TFormSetupRootDevice.TreeAddToSelection(Sender: TBaseVirtualTree; Node: PVirtualNode);
 var
  pe: PNodeExData;
begin
  pe := Tree.GetNodeData(Node);
  if pe.IsRoot then Exit();
  ShowPropAttribute.Apply(TObject(pe.SubDevice), Insp);
end;

procedure TFormSetupRootDevice.TreeGetText(Sender: TBaseVirtualTree; Node: PVirtualNode; Column: TColumnIndex; TextType: TVSTTextType;  var CellText: string);
 var
  p: PNodeExData;
begin
  p := Sender.GetNodeData(Node);
  CellText := '   ';
  if p.IsRoot then CellText := p.DevInfo.Category
  else CellText := p.SubDevice.Caption;
end;

procedure TFormSetupRootDevice.UpdateTree;
 var
  subdevs: TArray<ISubDevice>;
  sdi: TSubDeviceInfo;
  sd: ISubDevice;
  pv,pm: PVirtualNode;
begin
  subdevs := FDev.GetSubDevices;
  Tree.BeginUpdate;
  try
   ClearTree;
   for sdi in FDev.Structure do
    begin
      pv := Tree.AddChild(nil);
      Include(pv.States, vsExpanded);
      PNodeExData(Tree.GetNodeData(pv)).DevInfo := sdi;
      PNodeExData(Tree.GetNodeData(pv)).IsRoot := True;
      for sd in subdevs do if SameText(sd.Category.Category, sdi.Category) then
       begin
        pm := Tree.AddChild(pv);
        PNodeExData(Tree.GetNodeData(pm)).SubDevice := sd;
        PNodeExData(Tree.GetNodeData(pm)).IsRoot := False;
       end;
    end;
  finally
   Tree.EndUpdate;
  end;
end;

function TFormSetupRootDevice.Execute(InputData: IRootDevice): Boolean;
  procedure UpdateFModels(d: TArray<ModelType>);
   var
    m: ModelType;
    sd: ISubDevice;
    i: IInterface;
    smd: TSubDevaModelData;
  begin
    SetLength(FModels, 0);
    for m in d do
     begin
    //  TRegistration.Create(m).AddInstance('tmp', '');
      if GContainer.TryGetInstance(m, i) and Supports(i, ISubDevice, sd) then
       begin
        smd.Model := m;
        smd.DevInfo := sd.Category;
        smd.Caption := sd.Caption;
        CArray.Add<TSubDevaModelData>(FModels, smd);
      //  GContainer.RemoveInstance(m, 'tmp');
       end;
     end;
  end;
begin
  Result := True;
  FDev := InputData;
  Insp.Root.SortKind := iskNone;
  UpdateFModels(GContainer.ModelsAsArray(FDev.Service));
  UpdateTree;
  Caption := 'Device setup ' + (FDev as ICaption).Text;
  IShow;
end;

procedure TFormSetupRootDevice.FormCreate(Sender: TObject);
begin
  Tree.NodeDataSize := SizeOf(TNodeExData);
end;

initialization
  RegisterDialog.Add<TFormSetupRootDevice, Dialog_SetupRootDevice>;
finalization
  RegisterDialog.Remove<TFormSetupRootDevice>;
end.

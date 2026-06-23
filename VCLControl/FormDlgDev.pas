unit FormDlgDev;

interface

uses  RootIntf, debug_except,ExtendIntf, DeviceIntf, Container, Tools, RootImpl,
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics, math,
  JvDockControlForm,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls, VirtualTrees, Vcl.Menus, Vcl.PlatformDefaultStyleActnCtrls, Vcl.ActnPopup, CPortCtl,
  VirtualTrees.BaseAncestorVCL, VirtualTrees.BaseTree, VirtualTrees.AncestorVCL;

type
  TFormCreateDev = class(TForm)
    ButtonOK: TButton;
    Button1: TButton;
    Tree: TVirtualStringTree;
    Label1: TLabel;
    edCaption: TEdit;
    Label3: TLabel;
    cbTree: TCheckBox;
    btConnection: TButton;
    ppConnection: TPopupMenu;
    procedure FormShow(Sender: TObject);
    procedure TreeGetText(Sender: TBaseVirtualTree; Node: PVirtualNode; Column: TColumnIndex; TextType: TVSTTextType; var CellText: string);
    procedure ButtonOKClick(Sender: TObject);
    procedure TreeChecking(Sender: TBaseVirtualTree; Node: PVirtualNode; var NewState: TCheckState; var Allowed: Boolean);
    procedure TreeChecked(Sender: TBaseVirtualTree; Node: PVirtualNode);
    procedure btConnectionClick(Sender: TObject);
  private
   var
    FSelectIO: IConnectIO;
    FDevice: IDevice;
    FNamesArray: string;
   type
    ChekDevs = (cdNone, cdBur, cdPSK);
    function CheckState: ChekDevs;
    function Selected: TAddressArray;
   protected
    procedure Loaded; override;
  public
    class function Execute(out d: IDevice): TModalResult;
    class procedure AddDevises(Sel: TAddressArray; Title, Names: string; SelectIO: IConnectIO; crWin: boolean;  out dev: IDevice);
  end;
  resourcestring
    RS_Dev_Connect= 'Подключить';
    RS_Dev_Not_Celect='Не выбраны устройства';

implementation

{$R *.dfm}

uses AbstractPlugin,  ConnectDeviceHelper;

function TFormCreateDev.CheckState: ChekDevs;
 var
  pv: PVirtualNode;
begin
  Result := cdNone;
  for pv in Tree.LevelNodes(0) do
   if pv.CheckState = csCheckedNormal then
    if TAddressRec.Devices[pv.Index].Adr <= 250 then Exit(cdBur) else Exit(cdPSK)
end;

class function TFormCreateDev.Execute(out d: IDevice): TModalResult;
begin
  with TFormCreateDev.Create(nil) do
   try
    Result := ShowModal();
    d := FDevice;
   finally
    Free;
   end;
end;

procedure TFormCreateDev.btConnectionClick(Sender: TObject);
begin
  btConnection.Caption := RS_Dev_Connect;
  FSelectIO := nil;
  TMenuConnectIO.Apply(ppConnection.Items,
    procedure(c: IConnectIO)
    begin
      FselectIO := c;
      btConnection.Caption := c.ConnectInfo;
      (GlobalCore as IconnectIOEnum).Add(c);
    end,
    procedure(c: IConnectIO)
    begin
      FselectIO := c;
      btConnection.Caption := c.ConnectInfo;
    end);
  ppConnection.Popup(btConnection.ClientOrigin.X, btConnection.ClientOrigin.Y+btConnection.Height)
end;


class procedure TFormCreateDev.AddDevises(Sel: TAddressArray; Title,Names: string; SelectIO: IConnectIO; crWin: boolean; out dev: IDevice);
 var
  g: IGetDevice;
  de: IDeviceEnum;
  pv: PVirtualNode;
  wf: IForm;
  function SetToEmptyWorkWindow: Boolean;
   var
    isd: ISetDevice;
  begin
    for isd in GContainer.Enum<ISetDevice> do if isd.DataDevice = '' then
     begin
       isd.DataDevice := Dev.IName;
       Exit(True);
     end;
    Result := False;
  end;
begin
  if Supports(GlobalCore, IGetDevice, g) and Supports(GlobalCore, IDeviceEnum, de) then
   begin
    Dev := g.Device(Sel, Title, Names);
    Dev.IConnect := SelectIO;
    de.Add(Dev);
    MainScreenChanged;
    if crWin and not SetToEmptyWorkWindow then
     begin
      wf := GContainer.CreateValuedInstance<string>('TFormWrok', 'CreateUser', '') as IForm;
      (GContainer as IFormEnum).Add(wf);
      (wf as ISetDevice).SetDataDevice(Dev.IName);
      (GContainer as ITabFormProvider).Dock(wf, 0);
      TForm(wf.GetComponent).Visible:= False; //      HIdeDockForm(TForm(wf.GetComponent));
      ShowDockForm(TForm(wf.GetComponent));
     end;
    (GlobalCore as IActionProvider).SaveActionManager;
    ((GlobalCore as IActionEnum) as IStorable).Save;
   end;
end;

procedure TFormCreateDev.ButtonOKClick(Sender: TObject);
 var
  g: IGetDevice;
  de: IDeviceEnum;
  pv: PVirtualNode;
  wf: IForm;
  function SetToEmptyWorkWindow: Boolean;
   var
    isd: ISetDevice;
  begin
    for isd in GContainer.Enum<ISetDevice> do if isd.DataDevice = '' then
     begin
       isd.DataDevice := FDevice.IName;
       Exit(True);
     end;
    Result := False;
  end;
begin
  if CheckState = cdNone then
  begin
   ModalResult := mrAbort;
   raise EBaseException.Create(RS_Dev_Not_Celect);
  end;
  AddDevises(Selected, edCaption.Text, FNamesArray, FSelectIO, cbTree.Checked, FDevice);
  for pv in Tree.LevelNodes(0) do pv.CheckState := csUnCheckedNormal;

//  if Supports(GlobalCore, IGetDevice, g) and Supports(GlobalCore, IDeviceEnum, de) then
//   begin
//    FDevice := g.Device(Selected, edCaption.Text, FNamesArray);
//    FDevice.IConnect := FSelectIO;
//    de.Add(FDevice);
//    MainScreenChanged;
//    for pv in Tree.LevelNodes(0) do pv.CheckState := csUnCheckedNormal;
//    if cbTree.Checked and not SetToEmptyWorkWindow then
//     begin
//      wf := GContainer.CreateValuedInstance<string>('TFormWrok', 'CreateUser', '') as IForm;
//      (GContainer as IFormEnum).Add(wf);
//      (wf as ISetDevice).SetDataDevice(FDevice.IName);
//      (GContainer as ITabFormProvider).Dock(wf, 0);
//      TForm(wf.GetComponent).Visible:= False; //      HIdeDockForm(TForm(wf.GetComponent));
//      ShowDockForm(TForm(wf.GetComponent));
//     end;
//    (GlobalCore as IActionProvider).SaveActionManager;
//    ((GlobalCore as IActionEnum) as IStorable).Save;
//   end;
end;

procedure TFormCreateDev.FormShow(Sender: TObject);
 var
  pv: PVirtualNode;
begin
  Tree.Clear;
  Tree.RootNodeCount := Length(TAddressRec.Devices);
  for pv in Tree.LevelNodes(0) do
   begin
    pv.CheckType := ctCheckBox;
   end;
end;

procedure TFormCreateDev.Loaded;
//var
//  m: IMainScreen;
begin
  inherited;
//  if Supports(GContainer, IMainScreen, m) then StyleName := m.ThemeName;
end;

function TFormCreateDev.Selected: TAddressArray;
 var
  pv: PVirtualNode;
begin
  for pv in Tree.LevelNodes(0) do
   if pv.CheckState = csCheckedNormal then CArray.Add<Integer>(Result, TAddressRec.Devices[pv.Index].Adr);
end;

procedure TFormCreateDev.TreeChecked(Sender: TBaseVirtualTree; Node: PVirtualNode);
 var
  pv: PVirtualNode;
begin
  FNamesArray := '';
  for pv in Tree.LevelNodes(0) do
    if pv.CheckState = csCheckedNormal then FNamesArray := FNamesArray + ' ' + TAddressRec.Devices[pv.Index].Name;
  FNamesArray := FNamesArray.Trim;
  edCaption.Text := FNamesArray;
end;

procedure TFormCreateDev.TreeChecking(Sender: TBaseVirtualTree; Node: PVirtualNode; var NewState: TCheckState; var Allowed: Boolean);
begin
  if NewState = csCheckedNormal then
   if (CheckState = cdPSK) or ((CheckState = cdBur) and (TAddressRec.Devices[Node.Index].Adr >= 1100)) then Allowed := False

end;

procedure TFormCreateDev.TreeGetText(Sender: TBaseVirtualTree; Node: PVirtualNode; Column: TColumnIndex; TextType: TVSTTextType; var CellText: string);
begin
  case Column of
   0: CellText := TAddressRec.Devices[node.Index].Name;
   1: CellText := TAddressRec.Devices[node.Index].Info;
   2: CellText := TAddressRec.Devices[node.Index].Adr.ToString;
  end;
end;

end.

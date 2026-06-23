unit ControForm3;

interface

{$INCLUDE global.inc}


uses RootImpl, ExtendIntf, DockIForm, debug_except, DeviceIntf, PluginAPI, RootIntf, Container, Actns,
  VirtualTrees.Colors,
  Winapi.Windows, Winapi.Messages, Xml.XMLIntf, System.UITypes,  System.IOUtils,VirtualTrees.Types,
  System.SysUtils, Vcl.Graphics, VirtualTrees, System.Bindings.Expression, Vcl.Forms, Vcl.Dialogs, JvDockControlForm,
  Vcl.ImgList, Vcl.Controls, Vcl.Menus, Vcl.PlatformDefaultStyleActnCtrls, Vcl.ActnPopup, System.Classes, Vcl.StdCtrls,
  ActnCtrls, VirtualTrees.BaseAncestorVCL, VirtualTrees.BaseTree,
  VirtualTrees.AncestorVCL;

{$IFDEF ENG_VERSION}
  const
   C_CaptComtrolForm ='Device management window';
   C_Memu_Show='Show';
{$ELSE}
  const
   C_CaptComtrolForm ='Окно управления устройствами';
   C_Memu_Show='Показать';
{$ENDIF}

type
  PNodeExData = ^TNodeExData;
  TUpdateTextFunc = procedure (xd: PNodeExData; Column: Integer) of object;
  TNodeExData = record
    Item: IInterface;
    UpdateTextFunc: TUpdateTextFunc;
    ImagIndex: Integer;
    Color: TColor;
    Data: array[0..2]of string; // texsts colons
    ReadOnly: array[0..2]of Boolean; // readonly texsts colons
  end;

  EFormControlException = class(EBaseException);


  TFormControl = class(TDockIForm)
    ppM: TPopupActionBar;
    NUpdate: TMenuItem;
    NSepConn: TMenuItem;
    NRemove: TMenuItem;
    NSetup: TMenuItem;
    NAddDev: TMenuItem;
    NSetupDev: TMenuItem;
    NSepDEv: TMenuItem;
    NConnect: TMenuItem;
    NControl: TMenuItem;
    N2: TMenuItem;
    N1: TMenuItem;
    NReadRam: TMenuItem;
    NInfo: TMenuItem;
    NGlu: TMenuItem;
    NeepCmp: TMenuItem;
    NMetrolImport: TMenuItem;
    NClc: TMenuItem;
    NeepEdit: TMenuItem;
    NMetrolExport: TMenuItem;
    NRamSize: TMenuItem;
    Tree: TVirtualStringTree;
    NRep: TMenuItem;
    procedure TreeGetText(Sender: TBaseVirtualTree; Node: PVirtualNode; Column: TColumnIndex; TextType: TVSTTextType; var CellText: string);
    procedure NUpdateClick(Sender: TObject);
    procedure ppMPopup(Sender: TObject);
    procedure NRemoveClick(Sender: TObject);
    procedure NSetupClick(Sender: TObject);
    procedure NAddDevClick(Sender: TObject);
    procedure TreeGetImageIndex(Sender: TBaseVirtualTree; Node: PVirtualNode; Kind: TVTImageKind; Column: TColumnIndex; var Ghosted: Boolean; var ImageIndex: TImageIndex);
    procedure TreePaintText(Sender: TBaseVirtualTree; const TargetCanvas: TCanvas; Node: PVirtualNode; Column: TColumnIndex; TextType: TVSTTextType);
    procedure NSetupDevClick(Sender: TObject);
    procedure TreeCreateEditor(Sender: TBaseVirtualTree; Node: PVirtualNode; Column: TColumnIndex; out EditLink: IVTEditLink);
    procedure TreeEditing(Sender: TBaseVirtualTree; Node: PVirtualNode; Column: TColumnIndex; var Allowed: Boolean);
    procedure NReadRamClick(Sender: TObject);
    procedure NClcClick(Sender: TObject);
    procedure NeepEditClick(Sender: TObject);
    procedure NeepCmpClick(Sender: TObject);
    procedure NMetrolTestClick(Sender: TObject);
    procedure NMetrolImportClick(Sender: TObject);
    procedure NRamSizeClick(Sender: TObject);
    procedure NRepClick(Sender: TObject);
  private
    FEditData: PNodeExData;
    FEditNode: PVirtualNode;
//    FKadrLen: Integer;

    FDummi: string;
    FProject: string;

    FNotUpdate: Boolean;

    FAddCon: string;
    FAddDev: string;
    FC_TableUpdate: string;
    FC_MetaDataOK: boolean;

    procedure TreeClear;
    procedure TreeUpdate;

    class procedure InitMenuConnectIO(RootControl: TMenuItem; ClickEvent, AddNewClick: TNotifyEvent); static;
    procedure SetReadOnly(pd: PNodeExData; r0: Boolean = True; r1: Boolean = True; r2: Boolean = True);
    procedure SetData(pd: PNodeExData; const d0: string = ''; const d1: string = ''; const d2: string = '');

    procedure ShowModulMenus(Flag: Boolean; node: IXMLnode = nil);
    procedure ShowDevMenus(Flag: Boolean; dev: IDevice = nil);
    procedure ShowConMenus(Flag: Boolean);
    procedure ConnectClick(Sender: TObject);
    procedure AddNewClick(Sender: TObject);
    procedure IOChange(const Value: string);
    procedure SetDeviceChange(const Value: string);
    procedure SetProjectChange(const Value: string);
    procedure AddMetaData(d: IDataDevice; Rt: PVirtualNode);
    procedure AddDevice(d: IDevice; Rt: PVirtualNode);
    function AddControl(c: IConnectIO; PVDev: PVirtualNode): PVirtualNode;
    function GetControl(c: IConnectIO): PVirtualNode;
    procedure DeleteUnUsed;
    procedure SetAddCon(const Value: string);
    procedure SetAddDev(const Value: string);
    procedure ViewRamData(Root: PVirtualNode; node: IXMLNode);
    procedure ViewWrkData(Root: PVirtualNode; node: IXMLNode);
    procedure ViewMetrData(Root: PVirtualNode; node: IXMLNode);
    procedure UpdateTextFunc_SetRamSize(xd: PNodeExData; Column: Integer);
    procedure UpdateTextFunc_Metr_File(xd: PNodeExData; Column: Integer);
    procedure UpdateTextFunc_Metr_MetrData(xd: PNodeExData; Column: Integer);
    procedure SetC_TableUpdate(const Value: string);
    procedure SetC_MetaDataOK(const Value: boolean);
 protected
    type
     TRunViewSectionFunc = procedure(Root: PVirtualNode; node: IXMLNode) of object;
   const
    NICON = 269;
   var
    AVAIL_T_Func: array[0..4] of TRunViewSectionFunc;// = (TFormControl.ViewWrkData, TFormControl.ViewRamData, nil, nil, TFormControl.ViewMetrData);
    function Priority: Integer; override;
    class function ClassIcon: Integer; override;
    procedure Loaded; override;
    procedure DoShow; override;

  public

    //Capt, Categ: string; AImageIndex: Integer; APaths: string; AHint: string; AAutoCheck AChecked AGroupIndex AEnabled
    [StaticAction(C_CaptComtrolForm, C_Memu_Show, NICON, '0:'+C_Memu_Show+':2')]
    class procedure DoCreateForm(Sender: IAction); override;
    destructor Destroy; override;
    property C_ConnectIO: string read FDummi write IOChange;
    property C_Device: string read FDummi write SetDeviceChange;
    property C_Project: string read FProject write SetProjectChange;
    property C_AddDev: string read FAddDev write SetAddDev;
    property C_AddCon: string read FAddCon write SetAddCon;
    property C_TableUpdate: string read FC_TableUpdate write SetC_TableUpdate;
    property C_MetaDataOK: boolean read FC_MetaDataOK write SetC_MetaDataOK;
  end;
  resourcestring
   RS_ADR = 'Адрес';
   RS_Info='Инфо';
   RS_SerialNo='Серийный номер';
   RS_Chip= 'Чип';
   Rs_SerialMask= 'Маска скорости порта';
   MAX_T = 'Макс.Вр.Раб.(Сут)';
   RS_Mode_Info='Режим информации';
   RS_Mode_Ram='Чтение памяти';
   RS_Mode_Glu='Данные по глубине';
   RS_Mode_Metr='Метрология';
   RS_NOReady='не инициализирован';
   RS_PartReaty= 'готов частично';
   RS_Reaty='готов';
   RS_Mode_Delay ='постановка на задержку';
   RS_Busy ='занят';
   RS_Error ='ошибка';
   RS_IB_NewTDays='Новое время заполнения памяти модуля в сутках';
   RS_Msg_TrrNEeep='Текущие файлы тарировки прибора НЕ совпадают с EEPROM'#$D#$A;
   RS_Msg_TrrEQeep='Текущие файлы тарировки прибора совпадают с EEPROM';
   RS_Fltrr='Файл тарировки';
   RS_Fl='Файл';
   RS_Err_DataEx='Необходимо завершить операцию обмена данными';
   RS_NewCon='Новое соединение...';
   Rs_Attest='Аттестовал';
   Rs_FromF='с кадра';
   Rs_toF='по кадр';
   Rs_FromT='со времени';
   Rs_ToT='до времени';
   Rs_FromAdr='с адреса';
   Rs_Toadr='по адрес';
   Rs_End='окончено';


implementation

{$R *.dfm}

uses AbstractPlugin, tools, FormDlgDev;

const
  AVAIL_ATTR: array[0..4] of string = (AT_ADDR, AT_INFO, AT_SERIAL, AT_CHIP, AT_SPEED);//, AT_RAMSIZE);
  AVAIL_ATTR_Caption: array[0..4] of string = (RS_ADR, RS_Info, RS_SerialNo, RS_Chip, Rs_SerialMask);//, 'Память Мб');
  AVAIL_T: array[0..4] of string = (T_WRK, T_RAM, T_EEPROM, T_GLU, T_MTR);
  AVAIL_T_Caption: array[0..4] of string = (RS_Mode_Info, RS_Mode_Ram, 'EEPROM', RS_Mode_Glu, RS_Mode_Metr);
  //AVAIL_T_Func: array[0..4] of TRunMetrFunc = (TFormControl.ViewWrkData, TFormControl.ViewRamData, nil, nil, TFormControl.ViewMetrData);
  IMG_ATTR = 306;
  CLR_ATTR = TColors.Brown;

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
    class function GetTextNode(xd: PNodeExData; Column: Integer): string;
    class procedure SetTextNode(xd: PNodeExData; Column: Integer; const text: string);
  end;


class procedure TEditor.SetTextNode(xd: PNodeExData; Column: Integer; const text: string);
 var
  d: IDevice;
  c: IConnectIO;
  n: IXMLNode;
  cy: ICycle;
begin
  if Column < 0 then Exit;
  if not Assigned(xd.Item) then xd.Data[Column] := text
  else if Supports(xd.Item, IXMLNode, n) then
    case Column of
     1: if n.NodeType = ntAttribute then n.NodeValue := text
    end
  else if Supports(xd.Item, IDevice, d) then
    case Column of
     0: (d as ICaption).Text := text;
     2: if Supports(d, ICycle, cy) then cy.Period := Text.ToInteger()
    end
  else if Supports(xd.Item, IConnectIO, c) then
    case Column of
     2: c.Wait := Text.ToInteger();
    end
end;

class function TEditor.GetTextNode(xd: PNodeExData; Column: Integer): string;
 const
  DSTA_TO_STR: array [Low(TDeviceStatus)..High(TDeviceStatus)] of string =
                     (RS_NOReady,RS_PartReaty, RS_Reaty, RS_Mode_Info, RS_Mode_Delay, RS_Mode_Ram);
 var
  d: IDevice;
  c: IConnectIO;
  n: IXMLNode;
  cy: ICycle;
begin
  Result := '';
  if Column < 0 then Exit;
  if not Assigned(xd.Item) then Result := xd.Data[Column]
  else if Supports(xd.Item, IXMLNode, n) then
   begin
    if Assigned(xd.UpdateTextFunc) then xd.UpdateTextFunc(xd, Column);
    case Column of
     0: if xd.Data[0] <> '' then Result := xd.Data[0]
        else Result := n.NodeName;
     1: if (n.NodeType = ntAttribute) and not Assigned(xd.UpdateTextFunc) then Result := n.NodeValue
        else Result := xd.Data[1];
     2: Result := xd.Data[2];
    end
   end
  else if Supports(xd.Item, IDevice, d) then
    case Column of
     0: Result := (d as ICaption).Text;
     1: Result := DSTA_TO_STR[d.Status];
     2: if Supports(d, ICycle, cy) then Result := cy.Period.ToString
        else Result := '';
    end
  else if Supports(xd.Item, IConnectIO, c) then
    case Column of
     0: Result := c.ConnectInfo;
     1: if iosLock in c.Status then Result := RS_Busy
        else if iosError in c.Status then Result := RS_Error
        else Result := '';
     2: Result := c.Wait.ToString;
    end
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
  SetTextNode(FData, FColumn, TEdit(FEdit).Text);
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
    Text := TEditor.GetTextNode(FData, FColumn);
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


{$REGION 'TFormControl'}
function TFormControl.GetControl(c: IConnectIO): PVirtualNode;
 var
  pv: PVirtualNode;
  c1: IConnectIO;
begin
  for pv in Tree.LevelNodes(0) do if Supports(PNodeExData(Tree.GetNodeData(pv)).Item, IConnectIO, c1) and (c = c1) then Exit(pv);
  Result := nil;
end;

class function TFormControl.ClassIcon: Integer;
begin
  Result := NICON;
end;

class procedure TFormControl.DoCreateForm(Sender: IAction);
begin
  GetUniqueForm('GlobalControlForm');
end;

procedure TFormControl.DoShow;
begin
  inherited;
  Tree.UpdateScrollBars(true);
end;

procedure TFormControl.DeleteUnUsed;
 var
  ArrToDelete: TArray<PVirtualNode>;
begin
  ArrToDelete := [];
  for var pv in Tree.LevelNodes(0) do if pv.ChildCount = 0 then ArrToDelete := ArrToDelete +[pv];
  for var i := 0 to Length(ArrToDelete)-1 do Tree.DeleteNode(ArrToDelete[i]);
end;

destructor TFormControl.Destroy;
begin
  TreeClear;
  inherited;
end;

procedure TFormControl.Loaded;
 var
  ip: IImagProvider;
begin
  AVAIL_T_Func[0] := ViewWrkData;
  AVAIL_T_Func[1] := ViewRamData;
  AVAIL_T_Func[4] := ViewMetrData;
  inherited;
  Tree.NodeDataSize := SizeOf(TNodeExData);
  if Supports(GlobalCore, IImagProvider, ip) then
   begin
    Tree.Images := ip.GetImagList;
    ppM.Images := ip.GetImagList;
   end;
  TreeUpdate();
  Bind('C_MetaDataOK', GlobalCore as IManager, ['S_MetaDataOK']);
  Bind('C_TableUpdate', GlobalCore as IManager, ['S_TableUpdate']);
  Bind('C_Project', GlobalCore as IManager, ['S_ProjectChange']);
  Bind('C_AddDev', GlobalCore as IDeviceEnum, ['S_AfterAdd']);
  Bind('C_AddCon', GlobalCore as IConnectIOEnum, ['S_AfterAdd']);
  FC_MetaDataOK := True;
end;

procedure TFormControl.NRamSizeClick(Sender: TObject);
  var
   n: IXMLNode;
   c: Integer;
   s: string;
begin
  n := FEditData.Item as IXMLNode;
  c := n.ParentNode.ChildNodes.FindNode(T_WRK).Attributes[AT_SIZE];
  s := InputBox(RS_IB_NewTDays, MAX_T, '10');
  n.Attributes[AT_RAMSIZE] := Round(Int64(CTime.ToKadr(s.ToDouble))*c/1024/1024);
  TreeUpdate;
end;

procedure TFormControl.NReadRamClick(Sender: TObject);
 var
  d: Idialog;
  dr: IDialog<IXMLNode, TDialogResult>;
begin
  if RegisterDialog.TryGet<Dialog_RamRead>(d) then IDialog<IXMLNode, TDialogResult>(d).Execute(FEditData.Item as IXMLNode,
  procedure(Sender: IDialog; Res: TModalResult)
  begin

  end);
end;

procedure TFormControl.NAddDevClick(Sender: TObject);
 var
  d: IDevice;
  pvc: PVirtualNode;
begin
  FNotUpdate := True;
  try
   if TFormCreateDev.Execute(d) = mrOk then
    begin
     if Assigned(d.IConnect) then
      begin
       pvc := GetControl(d.IConnect);
       if not Assigned(pvc) then pvc := AddControl(d.IConnect, nil);
       AddDevice(d, pvc);
       end
     else AddDevice(d, nil);
    end;
  finally
   FNotUpdate := False;
  end;
end;

procedure TFormControl.NClcClick(Sender: TObject);
 var
  d: Idialog;
  dr: IDialog<IXMLNode, TDialogResult>;
begin
  if (FEditData.Item as IXMLNode).NodeType = ntAttribute then
   begin
    FEditNode := FEditNode.Parent;
    FEditData := Tree.GetNodeData(FEditNode);
   end;
   if RegisterDialog.TryGet<Dialog_ClcWrite>(d) then IDialog<IXMLNode, TDialogResult>(d).Execute(FEditData.Item as IXMLNode,
   procedure(Sender: IDialog; Res: TModalResult)
   begin

   end);
end;

procedure TFormControl.NeepCmpClick(Sender: TObject);
 var
  dev: PNodeExData;
  eep: IXMLNode;
  addr: Integer;
begin
  EBaseException.NeedShowDialog();
  eep := (FEditData.Item as IXMLNode);
  addr := eep.ParentNode.Attributes[AT_ADDR];
  dev := Tree.GetNodeData(FEditNode.Parent.Parent);
  (dev.Item as IEepromDevice).ReadEeprom(addr, procedure (Res: TEepromEventRes)
   var
    ErrList: TEEPerrors;
    e: EepErr;
    s: string;
  begin
    //TDebug.Log(eep.NodeName);
    if addr = Res.DevAdr then
     begin
      if not (GlobalCore as IMetrology).TestEeprom(eep, ErrList) then
      begin
       s := '';
       for e in ErrList do s := s + Format('%s = [%1.4f, %1.4f]'#$D#$A, [e.name, e.ValEep, e.ValMetr]);
       MessageDlg(RS_Msg_TrrNEeep+s, TMsgDlgType.mtError, [mbOK], 0)
       end
      else MessageDlg(Format(RS_Msg_TrrEQeep,['','' ]), TMsgDlgType.mtConfirmation, [mbOK], 0)
     end;
  end);
end;

procedure TFormControl.NeepEditClick(Sender: TObject);
 var
  d: Idialog;
  dr: IDialog<IXMLNode, TDialogResult>;
begin
  if RegisterDialog.TryGet<Dialog_Eep>(d) then IDialog<IXMLNode, TDialogResult>(d).Execute(FEditData.Item as IXMLNode,
  procedure(Sender: IDialog; Res: TModalResult)
  begin

  end);
end;

procedure TFormControl.NMetrolTestClick(Sender: TObject);
 var
  x, mtr: IXMLNode;
begin
  with TOpenDialog.Create(nil) do
  try
   InitialDir := ExtractFilePath(ParamStr(0)) + T_MTR;
   Options := Options + [ofPathMustExist, ofFileMustExist];
   DefaultExt := 'XMLMtr';
   Filter := RS_Fltrr+' (*.XMLMtr)|*.XMLMtr|'+RS_Fl+' xml (*.xml)|*.xml';
   if Execute(Handle) and Supports(FEditData.Item, IXMLNode, x) then
     (GlobalCore as IMetrology).Check(x, filename,[AT_METR,AT_FILE_NAME, AT_TIMEATT, AT_METROLOG], mtr);
  finally
    Free;
  end;
end;

procedure TFormControl.NMetrolImportClick(Sender: TObject);
 var
  x, mtr, m: IXMLNode;
  devnm: string;
begin
  with TOpenDialog.Create(nil) do
  try
   InitialDir := ExtractFilePath(ParamStr(0)) + T_MTR;
   Options := Options + [ofPathMustExist, ofFileMustExist];
   DefaultExt := 'XMLMtr';
   Filter := RS_Fltrr+' (*.XMLMtr)|*.XMLMtr|'+RS_Fl+' xml (*.xml)|*.xml';;
   if Execute(Handle) and Supports(FEditData.Item, IXMLNode, x) then
    begin
     (GlobalCore as IMetrology).Setup(x, filename,[AT_METR,AT_FILE_NAME, AT_TIMEATT, AT_METROLOG], mtr);
     x.Attributes[AT_FILE_NAME] := FileName;
     devnm := x.ParentNode.ParentNode.NodeName + '.' + x.NodeName;
     for m in XEnum(mtr) do if m.HasAttribute(AT_DEVNAME) and (m.Attributes[AT_DEVNAME] = devnm) then
      begin
       if m.HasAttribute(AT_TIMEATT) then x.Attributes[AT_TIMEATT] := m.Attributes[AT_TIMEATT];
       if m.HasAttribute(AT_METROLOG) then x.Attributes[AT_METROLOG] := m.Attributes[AT_METROLOG];
      end;
     (GContainer as IALLMetaDataFactory).Get.Save;
     TreeUpdate;
    end;
  finally
    Free;
  end;
end;

procedure TFormControl.NRemoveClick(Sender: TObject);
begin
  if not ((FEditData.Item as IDevice).Status in [dsNoInit, dsPartReady, dsReady]) then
    if not (FEditData.Item as IDevice).CanClose then
    raise EFormControlException.Create(RS_Err_DataEx);
  try
     if not Supports(FEditData.Item, IDataDevice) then
      begin
        var de: IDeviceEnum;
        if Supports(GlobalCore, IDeviceEnum, de) then de.Remove(FEditData.Item as IDevice);
      end
     else (GlobalCore as IProjectDataFile).DeviceDataDelete(FEditData.Item as IDevice); // уже есть de.Remove(d as IDevice);
  finally
   FEditData.Item := nil;
   (GlobalCore as IActionProvider).HideUnusedMenus;
   (GlobalCore as IActionProvider).UpdateWidthBars;
   (GlobalCore as IActionProvider).SaveActionManager;
   Tree.DeleteNode(FEditNode);
   DeleteUnUsed;
   Tree.Repaint;
   ((GlobalCore as IActionEnum) as IStorable).Save;
  end;
end;

procedure TFormControl.NRepClick(Sender: TObject);
 var
  d: Idialog;
  dr: IDialog<IXMLNode, TDialogResult>;
begin
  if RegisterDialog.TryGet<Dialog_Logg>(d) then IDialog<IXMLNode, TDialogResult>(d).Execute(FEditData.Item as IXMLNode,
  procedure(Sender: IDialog; Res: TModalResult)
  begin

  end);
end;

procedure TFormControl.NSetupClick(Sender: TObject);
 var
  d: Idialog;
begin
  if RegisterDialog.TryGet<Dialog_SetupConnectIO>(d) then (d as IDialog<IConnectIO>).Execute(FEditData.Item as IConnectIO);
end;

procedure TFormControl.NSetupDevClick(Sender: TObject);
 var
  d: Idialog;
begin
  if RegisterDialog.TryGet<Dialog_SetupDevice>(d) then (d as IDialog<IDevice>).Execute(FEditData.Item as IDevice);
  Tree.InvalidateNode(FEditNode);
end;

procedure TFormControl.NUpdateClick(Sender: TObject);
begin
  TreeUpdate;
end;

class procedure TFormControl.InitMenuConnectIO(RootControl: TMenuItem; ClickEvent, AddNewClick: TNotifyEvent);
 var
  gc: IGetConnectIO;
begin
  RootControl.Clear;
  if Supports(GlobalCore, IGetConnectIO, gc) then gc.Enum(procedure(ConnectID: Integer; const ConnectName, ConnectInfo: string)
    function AddMenu(root: TMenuItem; const Capt: string; ev: TNotifyEvent): TMenuItem;
    begin
      Result := TMenuItem.Create(Root);
      Result.Caption := Capt;
      Result.Tag := ConnectID;
      Result.OnClick := ev;
      root.Add(Result);
    end;
    procedure AddAvail(root: TMenuItem);
     var
      s: string;
    begin
      for s in gc.GetConnectInfo(ConnectID) do AddMenu(root, s, ClickEvent);
    end;
    procedure AddCreateNew(root: TMenuItem);
    begin
      AddMenu(root, RS_NewCon, AddNewClick);
      AddMenu(root, '-', nil);
    end;
   var
    Item: TMenuItem;
  begin
    Item := AddMenu(RootControl, ConnectInfo, nil);
    if gc.IsManualCreate(ConnectID) then AddCreateNew(Item);
    AddAvail(Item);
  end);
end;

procedure TFormControl.AddNewClick(Sender: TObject);
 var
  c: IConnectIO;
  gc: IGetConnectIO;
  ce: IConnectIOEnum;
  d: Idialog;
  dv: IDevice;
begin
  if Supports(GlobalCore, IGetConnectIO, gc) then
   begin
    c := gc.ConnectIO(TMenuItem(Sender).Tag);
    if RegisterDialog.TryGet<Dialog_SetupConnectIO>(d) and (d as IDialog<IConnectIO>).Execute(c) then
      begin
       dv := FEditData.Item as IDevice;
       FNotUpdate := True;
       if Supports(GlobalCore, IConnectIOEnum, ce) then ce.Add(c);
       dv.IConnect := c;
       AddControl(c, FEditNode);
       Tree.Repaint;
       FNotUpdate := False;
      end;
   end;
end;

procedure TFormControl.ConnectClick(Sender: TObject);
 var
  c: IConnectIO;
  gc: IGetConnectIO;
  ce: IConnectIOEnum;
  dv: IDevice;
begin
  GlobalCore.QueryInterface(IConnectIOEnum, ce);
  dv := FEditData.Item as IDevice;
  if Supports(GlobalCore, IConnectIOEnum, ce) then for c in ce do if SameText(c.ConnectInfo, TMenuItem(Sender).Caption) then
   begin
    dv.IConnect := c;
    Tree.MoveTo(FEditNode, GetControl(c), amAddChildLast, False);
    DeleteUnUsed;
    Tree.Repaint;
    Exit;
   end;
  if Supports(GlobalCore, IGetConnectIO, gc) then
   begin
    c := gc.ConnectIO(TMenuItem(Sender).Tag);
    c.ConnectInfo := TMenuItem(Sender).Caption;
    FNotUpdate := True;
    if Assigned(ce) then ce.Add(c);
    dv.IConnect := c;
    AddControl(c, FEditNode);
    Tree.Repaint;
    FNotUpdate := False;
   end;
end;

procedure TFormControl.ppMPopup(Sender: TObject);
 var
  d: IDevice;
  c: IConnectIO;
  x: IXMLNode;
//  am: IAddMenus;
begin
  FEditData := nil;
  FEditNode := nil;
  ShowConMenus(False);
  ShowDevMenus(False);
  ShowModulMenus(False);
  if not Assigned(Tree.HotNode) then Exit;
  FEditNode := Tree.HotNode;
  FEditData := Tree.GetNodeData(FEditNode);
  if Supports(FEditData.Item, IDevice, d) then
   begin
    ShowDevMenus(True, d);
    InitMenuConnectIO(NConnect, ConnectClick, AddNewClick);
//    if Supports(FEditData.Item, IAddMenus, am) then am.AddMenus(NControl);
   end
  else if Supports(FEditData.Item, IConnectIO, c) then
   begin
    ShowConMenus(True);
   end
  else if Supports(FEditData.Item, IXMLNode, x) then
   begin
    ShowModulMenus(True, x);
   end
  else ShowModulMenus(True);
end;

function TFormControl.Priority: Integer;
begin
  Result := PRIORITY_IForm - 100;
end;

procedure TFormControl.IOChange(const Value: string);
 var
  pv: PVirtualNode;
begin
  for pv in Tree.LevelNodes(0) do Tree.InvalidateNode(pv);
end;

procedure TFormControl.SetAddCon(const Value: string);
begin
  FAddCon := Value;
  TreeUpdate;
end;

procedure TFormControl.SetAddDev(const Value: string);
begin
  FAddDev := Value;
  TreeUpdate;
end;

procedure TFormControl.SetC_MetaDataOK(const Value: boolean);
begin
  FC_MetaDataOK := True;
end;

procedure TFormControl.SetC_TableUpdate(const Value: string);
begin
  FC_TableUpdate := Value;
  TreeUpdate;
end;

procedure TFormControl.SetData(pd: PNodeExData; const d0, d1, d2: string);
begin
  pd.ImagIndex := IMG_ATTR;
  pd.Color := CLR_ATTR;
  pd.Data[0] := d0;
  pd.Data[1] := d1;
  pd.Data[2] := d2;
end;

procedure TFormControl.SetDeviceChange(const Value: string);
 var
  pv: PVirtualNode;
begin
  for pv in Tree.LevelNodes(1) do Tree.InvalidateNode(pv)
end;

procedure TFormControl.SetProjectChange(const Value: string);
begin
  if Value = '' then TreeClear
  else TreeUpdate;
end;

procedure TFormControl.SetReadOnly(pd: PNodeExData; r0, r1, r2: Boolean);
begin
  pd.ReadOnly[0] := r0;
  pd.ReadOnly[1] := r1;
  pd.ReadOnly[2] := r2;
end;

procedure TFormControl.ShowConMenus(Flag: Boolean);
begin
  NSetup.Visible := Flag;
  NSepConn.Visible := Flag;
end;

procedure TFormControl.ShowDevMenus(Flag: Boolean; dev: IDevice);
 var
  ga: IGetActions;
  a: IAction;
  m: TMenuItem;
begin
  NRemove.Visible := Flag;
  NConnect.Visible := Flag;
  NControl.Clear;
  NControl.Visible := Flag;
  NSetupDev.Visible := Flag;
  NSepDEv.Visible := Flag;
  if flag and Supports(dev, IGetActions, ga) then for a in ga.GetActions do
   begin
    m := TMenuItem.Create(NControl);
    m.Action := TBasicAction(a.GetComponent);
    NControl.Add(m);
   end;
end;

procedure TFormControl.ShowModulMenus(Flag: Boolean; node: IXMLnode);
  function Chld(const Attr: string): Boolean;
  begin
    Result := Assigned(node) and Assigned(node.ChildNodes.FindNode(Attr))
  end;
  function Cur(const Attr: string): Boolean;
  begin
    Result := Assigned(node) and (node.NodeName = Attr)
  end;
  function Atr(const Attr: string): Boolean;
  begin
    Result := Assigned(node) and (node.NodeType = ntAttribute) and (node.NodeName = Attr)
  end;
  function prnt(const t_atr: string): Boolean;
  begin
    Result := Assigned(node) and Assigned(node.ParentNode) and (node.ParentNode.NodeName = t_atr)
  end;
  function rtc(): Boolean;
  begin
    Result := Assigned(node)
    and (node.NodeType = ntElement)
    and node.HasAttribute(AT_INFO)
    and string(node.Attributes[AT_INFO]).Contains('RTC')
  end;
begin
  Nclc.Visible := Flag and (Cur(T_RAM) or Cur(T_WRK)) and not (FEditData.Data[0] = MAX_T);
  NRamSize.Visible := Flag and (FEditData.Data[0] = MAX_T);
  NReadRam.Visible := Flag and Chld(T_RAM);
  NInfo.Visible := False;// Flag and Chld(T_WRK);
  NGlu.Visible := Flag and Chld(T_GLU);
  NeepEdit.Visible := RegisterDialog.Support<Dialog_Eep> and  Flag and Cur(T_EEPROM) and FC_MetaDataOK;
  NeepCmp.Visible := Flag and Cur(T_EEPROM) and FC_MetaDataOK;
  NMetrolExport.Visible := Flag and prnt(T_MTR);
  NMetrolImport.Visible := Flag and prnt(T_MTR);
  NRep.Visible := Flag and rtc();
end;

procedure TFormControl.TreeClear;
 var
  pv: PVirtualNode;
begin
  for pv in Tree.Nodes do PNodeExData(Tree.GetNodeData(pv)).Item := nil;
  Tree.Clear;
end;

procedure TFormControl.TreeCreateEditor(Sender: TBaseVirtualTree; Node: PVirtualNode; Column: TColumnIndex; out EditLink: IVTEditLink);
begin
  EditLink := TEditor.Create;
end;

procedure TFormControl.TreeEditing(Sender: TBaseVirtualTree; Node: PVirtualNode; Column: TColumnIndex; var Allowed: Boolean);
begin
  Allowed := not PNodeExData(Tree.GetNodeData(Node)).ReadOnly[Column];
end;

function TFormControl.AddControl(c: IConnectIO; PVDev: PVirtualNode): PVirtualNode;
begin
  Result := Tree.AddChild(nil);
  Include(Result.States, vsExpanded);
  PNodeExData(Tree.GetNodeData(Result)).Item := c;
  SetReadOnly(PNodeExData(Tree.GetNodeData(Result)), True, True, False);
  if Assigned(PVDev) then Tree.MoveTo(PVDev, Result, amAddChildLast, False);
  Bind('C_ConnectIO', c, ['S_Status', 'S_PublishedChanged']);
end;

procedure TFormControl.AddDevice(d: IDevice; Rt: PVirtualNode);
 var
  dd: IDataDevice;
  pv: PVirtualNode;
begin
  pv := Tree.AddChild(rt);
  Include(pv.States, vsExpanded);
  PNodeExData(Tree.GetNodeData(pv)).Item := d;
  SetReadOnly(PNodeExData(Tree.GetNodeData(pv)), False, True, not Supports(d, ICycle));
  if Supports(d, IDataDevice, dd) then AddMetaData(dd, pv);
  Bind('C_Device', d, ['S_Status']);
end;

procedure TFormControl.AddMetaData(d: IDataDevice; Rt: PVirtualNode);
 var
  m: TDeviceMetaData;
  v, sv, ssv: PVirtualNode;
  e: PNodeExData;
  i: Integer;
  n, a, s: Ixmlnode;
  function SData(root: PVirtualNode; item: IXMLNode; const Caption, col1: string): PVirtualNode;
  begin
    Result := Tree.AddChild(Root);
    Include(Result.States, vsExpanded);
    e := PNodeExData(Tree.GetNodeData(Result));
    e.Item := item;
    SetData(e, Caption, col1);
    SetReadOnly(e);
    e.UpdateTextFunc := nil;
  end;
begin
  m := d.GetMetaData;
  ///  Ошибки инициализации
  if Length(m.ErrAdr) > 0 then
   begin
    v := SData(Rt, nil, RS_NOReady, d.AddressArrayToNames(m.ErrAdr));
   end;
  if Assigned(m.Info) then for n in XEnum(m.Info) do
   begin
    ///  модуль
    v := SData(Rt, n, '', '');
    e.Color := TColors.Blueviolet;
    e.ImagIndex := 322;
    ///  модуль атрибуты метаданных
    for i := 0 to High(AVAIL_ATTR) do
     begin
      a := n.AttributeNodes.FindNode(AVAIL_ATTR[i]);
      if Assigned(a) then sv := SData(v, a, AVAIL_ATTR_Caption[i], '');
     end;
    ///  модуль режим информации лог памяти EEPROM  glu  метрология
    for i := 0 to High(AVAIL_T) do
     begin
      a := n.ChildNodes.FindNode(AVAIL_T[i]);
      if Assigned(a) then
       begin
        sv := SData(v, a, AVAIL_T_Caption[i], '');
        e.Color := TColors.Blueviolet;
        e.ImagIndex := 315;
        if Assigned(AVAIL_T_Func[i]) then AVAIL_T_Func[i](sv, a);
       end;
     end;
    ///  модуль RTC log
//    if string(n.Attributes[AT_INFO]).Contains('RTC') then
//    begin
//      sv := SData(v, n, 'журнал наработки', '');
//      e.Color := TColors.Blueviolet;
//      e.ImagIndex := 315;
////      if Assigned(AVAIL_T_Func[i]) then AVAIL_T_Func[i](sv, a);
//    end;
   end;
end;

procedure TFormControl.UpdateTextFunc_Metr_File(xd: PNodeExData; Column: Integer);
 var
  fp: string;
begin
  fp := IXMLNode(xd.Item).NodeValue;
  if not TFile.Exists(fp) then xd.Color := clRed;
  xd.Data[1] := TPath.GetFileName(fp);
  xd.Data[2] := TPath.GetDirectoryName(fp);
end;

procedure TFormControl.UpdateTextFunc_Metr_MetrData(xd: PNodeExData; Column: Integer);
  var
   n: IXMLNode;
begin
  n := IXMLNode(xd.Item);
  if n.HasAttribute(AT_METROLOG) then xd.Data[1] := n.Attributes[AT_METROLOG];
  if n.HasAttribute(AT_TIMEATT) then xd.Data[2] := n.Attributes[AT_TIMEATT];
end;

procedure TFormControl.UpdateTextFunc_SetRamSize(xd: PNodeExData; Column: Integer);
  var
   n: IXMLNode;
   c: Integer;
begin
  n := IXMLNode(xd.Item);
  c := n.ParentNode.ChildNodes.FindNode(T_WRK).Attributes[AT_SIZE];
  xd.Data[1] := CTime.AsString(Round(CTime.FromKadr(n.Attributes[AT_RAMSIZE]*1024*1024/c))).Split([' '],TStringSplitOptions.ExcludeEmpty)[0]
end;

procedure TFormControl.ViewMetrData(Root: PVirtualNode; node: IXMLNode);
 var
  n, a: IXMLNode;
  e: PNodeExData;
  v, sv, ssv: PVirtualNode;
  function SData(Rt: PVirtualNode; item: IXMLNode; const Caption, col1, col2: string; f: TUpdateTextFunc): PVirtualNode;
  begin
    Result := Tree.AddChild(Rt);
    Include(Result.States, vsExpanded);
    e := PNodeExData(Tree.GetNodeData(Result));
    e.Item := item;
    SetData(e, Caption, col1, col2);
    SetReadOnly(e);
    e.UpdateTextFunc := f;
  end;
begin
  for n in XEnum(node) do if n.HasAttribute(AT_METR) then
   begin
    v := SData(root, n, n.NodeName, n.Attributes[AT_METR], '', nil);
    e.Color := TColors.Seagreen;
    e.ImagIndex := 315;
    if n.HasAttribute(AT_FILE_NAME) then
     begin
      a := n.AttributeNodes.FindNode(AT_FILE_NAME);
      SData(v, a, RS_Fl,'', '', UpdateTextFunc_Metr_File);
     end;
    if n.HasAttribute(AT_TIMEATT)or n.HasAttribute(AT_METROLOG) then
     begin
      SData(v, n, Rs_Attest,'', '', UpdateTextFunc_Metr_MetrData);
     end;
   end;
end;

procedure TFormControl.ViewRamData(Root: PVirtualNode; node: IXMLNode);
  function SData(const Caption, AttrName: string; cl:TColor = CLR_ATTR): PNodeExData;
   var
    v: PVirtualNode;
  begin
    if node.HasAttribute(AttrName) then
     begin
      v := Tree.AddChild(Root);
      Include(v.States, vsExpanded);
      Result := PNodeExData(Tree.GetNodeData(v));
      Result.Item := node.AttributeNodes.FindNode(AttrName);
      Result.UpdateTextFunc := nil;
      SetData(Result, Caption, node.Attributes[AttrName]);
      Result.Color := cl;
      SetReadOnly(Result);
     end;
  end;
  var
   e: PNodeExData;
begin
  if node.HasAttribute(AT_RAMSIZE) then
   begin
     e := SData(MAX_T, AT_RAMSIZE, TColors.Seagreen);
     e.UpdateTextFunc := UpdateTextFunc_SetRamSize;
     e.Item := node;
   end;

  SData(RS_Fl, AT_FILE_NAME);
  SData(Rs_FromF, AT_FROM_KADR);
  SData(Rs_toF, AT_TO_KADR);
  SData(Rs_FromT, AT_FROM_TIME);
  SData(Rs_ToT, AT_TO_TIME);
  SData(Rs_FromAdr, AT_FROM_ADR);
  SData(Rs_Toadr, AT_TO_ADR);
  SData(Rs_End, AT_END_REASON);
end;

procedure TFormControl.ViewWrkData(Root: PVirtualNode; node: IXMLNode);
  procedure SData(const Caption, AttrName: string);
   var
    v: PVirtualNode;
    e: PNodeExData;
  begin
    if node.HasAttribute(AttrName) then
     begin
      v := Tree.AddChild(Root);
      Include(v.States, vsExpanded);
      e := PNodeExData(Tree.GetNodeData(v));
      e.Item := node.AttributeNodes.FindNode(AttrName);
      e.UpdateTextFunc := nil;
      SetData(e, Caption, node.Attributes[AttrName]);
      SetReadOnly(e);
     end;
  end;
begin
  SData(RS_Fl, AT_FILE_NAME);
end;


procedure TFormControl.TreeUpdate;
 var
  c: IConnectIO;
  de: IDeviceEnum;
  ce: IConnectIOEnum;
  function testuseddev(): PVirtualNode;
   var
    d: IDevice;
  begin
    Result := nil;
    if (icAdding in c.Status) then Exit;
    if (icUserAdding in c.Status) then Exit;
    for d in de.Enum do
     if d.IConnect = c then
      begin
       Exit(AddControl(c, nil));
      end;
    if Assigned(ce) then ce.Remove(c);
  end;
 var
  d: IDevice;
  pv: PVirtualNode;
begin
  if FNotUpdate or not (Supports(GlobalCore, IDeviceEnum, de) and Supports(GlobalCore, IConnectIOEnum, ce)) then Exit;
  TBindHelper.RemoveControlExpressions(Self, ['C_ConnectIO', 'C_Device']);
  Tree.BeginUpdate;
  try
   TreeClear;
   for c in ce.Enum do testuseddev();
   for d in de.Enum do
    begin
     pv := nil;
     if Assigned(d.IConnect) then for pv in Tree.LevelNodes(0) do if PNodeExData(Tree.GetNodeData(pv)).Item = d.IConnect then Break;
     AddDevice(d, pv);
    end;
  finally
   Tree.EndUpdate;
  end;
end;

procedure TFormControl.TreeGetImageIndex(Sender: TBaseVirtualTree; Node: PVirtualNode; Kind: TVTImageKind; Column: TColumnIndex; var Ghosted: Boolean; var ImageIndex: TImageIndex);
 var
  xd: PNodeExData;
  d: IDevice;
  c: IConnectIO;
begin                                  // - 306
  xd := Sender.GetNodeData(Node);
  ImageIndex := -1;
  if (Column = 0) and (Kind in [TVTImageKind.ikNormal, ikSelected]) then
   if Supports(xd.Item, IDevice, d) then ImageIndex := 242
   else if Supports(xd.Item, IConnectIO, c) then
    begin
     if iosLock in c.Status then Ghosted := True;
     if iosError in c.Status then ImageIndex := 277
     else if iosOpen in c.Status then ImageIndex := 241
     else ImageIndex := 315;
    end
   else ImageIndex := xd.ImagIndex;
end;

procedure TFormControl.TreeGetText(Sender: TBaseVirtualTree; Node: PVirtualNode; Column: TColumnIndex; TextType: TVSTTextType; var CellText: string);
begin
  if Column < 0 then Exit;
  CellText := TEditor.GetTextNode(Sender.GetNodeData(Node), Column);
end;

procedure TFormControl.TreePaintText(Sender: TBaseVirtualTree; const TargetCanvas: TCanvas; Node: PVirtualNode; Column: TColumnIndex; TextType: TVSTTextType);
 var
  xd: PNodeExData;
  d: IDevice;
  c: IConnectIO;
begin
  xd := Sender.GetNodeData(Node);
  if Supports(xd.Item, IDevice, d) then TargetCanvas.Font.Color := if CurrentThemeIsDark then clSkyBlue else clBlue
  else if Supports(xd.Item, IConnectIO, c) then TargetCanvas.Font.Color := clRed
  else
   begin
//    TargetCanvas.Font.Color := xd.Color;
   end;
end;
{$ENDREGION}

initialization
  RegisterClass(TFormControl);
  TRegister.AddType<TFormControl, IForm>.LiveTime(ltSingletonNamed);
finalization
  GContainer.RemoveModel<TFormControl>;
end.

unit DockIForm;

interface

{$INCLUDE global.inc}

uses System.SysUtils, Vcl.Controls, debug_except, Winapi.Windows, Vcl.Graphics, Container, Actns, System.TypInfo, Vcl.Forms,
     DeviceIntf, ExtendIntf, RootImpl,JvDockGlobals, JvDockControlForm, JvDockVSNetStyle, Vcl.ActnPopup, Vcl.Menus, System.Classes,
      Vcl.Dialogs, Vcl.ComCtrls, JvDockVIDStyle;

const
 {$IFDEF ENG_VERSION}
      RS_DocformClose	='Close window';
      RS_DocformTab	='Tab';
      RS_DocformZak	='Docked';
      RS_Hiddenwindows	='Hidden windows';
      RS_MSG_Close	='close window ';
      RS_MSG_hide	=' ? (No - close)';
      RS_celectFont	='Select font';
 {$ELSE}
      RS_DocformClose='Закрыть Окно';
      RS_DocformTab='Вкладка';
      RS_DocformZak='Закрепляемое';
      RS_Hiddenwindows='Скрытые окна';
      RS_MSG_Close='Закрыть окно ';
      RS_MSG_hide=' ? (No - скрыть)';
      RS_celectFont='Выбрать шрифт';
 {$ENDIF}

type
  ShowNCMenu = set of (sncClose, sncTab, sncDock);

  IDockClient = interface
  ['{978365AC-9C3B-461A-8668-E668D2CCFE96}']
    function GetDockClient: TJvDockClient;
    property DockClient: TJvDockClient read GetDockClient;
    procedure SetNCMenusVisible(const snc: ShowNCMenu);
  end;

  TDockIFormClass = class of TDockIForm;

  TDockIForm = class(TIForm, IDockClient)//.NotifyBeforeRemove, INotifyBeforeClean)
  private
//    FShowAction: IAction;
//    FDockVSNetStyle: TJvDockVSNetStyle;
    FCaption: string;
    procedure Tab_ItemClick(Sender: TObject);
    procedure Dock_ItemClick(Sender: TObject);
    function IsAutoHidden: Boolean;
    function IsTabbedDocument: Boolean;
    procedure OnFormHide(Sender: TObject);
    procedure OnFormShow(Sender: TObject);
    procedure SetCaption(const Value: string);
  protected
   const
    AUTO_CHECK: array[Boolean]of Integer = (0,1);
   var
    FDockClient: TJvDockClient;
    FEnableCloseDialog: Boolean;
    NCanClose: Boolean;
    NClose, NTab, NDock: TMenuItem;
    procedure RemoveSelfFromDock;
    procedure DoShow;  override;
    procedure InitializeNewForm; override;
    procedure IShow; override;
    class function ClassIcon: Integer; virtual;
    procedure Close_ItemClick(Sender: TObject); virtual;
    procedure NCPopup(Sender: TObject); virtual;
    function AddToNCMenu(const ACaption: string; AClick: TNotifyEvent = nil; Index: Integer = -1; Autocheck: Integer = -1; Root: TMenuItem = nil): TMenuItem;
    class function GetUniqueForm(const FormName: string): IForm;
    class procedure DoCreateForm(Sender: IAction); virtual;
  public
    destructor Destroy; override;
    procedure SetNCMenusVisible(const snc: ShowNCMenu);
    function GetDockClient: TJvDockClient;
    procedure OnShowAction(Sender: IAction);
  published
    property Caption: string read FCaption write SetCaption;
  end;

  TDialogIForm = class(TDockIForm)
  protected
    function GetInfo: PTypeInfo; virtual; abstract;
    procedure Close_ItemClick(Sender: TObject); override;
    function Priority: Integer; override;
  public
    constructor Create; override;
  end;

  TCustomFontIForm = class(TDockIForm)
  private
    procedure NFontClick(Sender: TObject);
  protected
    NFont: TMenuItem;
    procedure DoSetFont(const AFont: TFont); virtual;
    procedure InitializeNewForm; override;
  end;

implementation

{$REGION ' TDockIForm '}

{ TDockIForm }

function TDockIForm.GetDockClient: TJvDockClient;
begin
  Result := FDockClient;
end;

function TDockIForm.IsAutoHidden: Boolean;
var
  ds: TWinControl;
begin
  ds := HostDockSite;
  while (ds <> nil) and (ds.Parent <> nil) and (ds.Parent.HostDockSite <> nil) do ds := ds.Parent.HostDockSite;
  Result := ds is TJvDockVSPopupPanel;
end;

procedure TDockIForm.IShow;
begin
  ShowDockForm(Self);
end;

function TDockIForm.IsTabbedDocument: Boolean;
 var
  t: ITabFormProvider;
begin
  Result := False;
  if Supports(GlobalCore, ITabFormProvider, t) then Result := t.IsTab(Self as IForm);
end;

procedure TDockIForm.InitializeNewForm;
 var
  m : IMainScreen;
begin
  inherited;
  FDockClient := CreateUnLoad<TJvDockClient>;
//  FDockVSNetStyle := CreateUnLoad<TJvDockVSNetStyle>;
//  TJvDockVIDConjoinServerOption(FDockVSNetStyle.ConjoinServerOption).SystemInfo := True;
  Supports(GlobalCore, IMainScreen, m);
  FDockClient.DockStyle := TJvDockVSNetStyle(m.DockStyle);// FDockVSNetStyle;
  FDockClient.OnFormShow := OnFormShow;
  FDockClient.OnFormHide := OnFormHide;
  FDockClient.NCPopupMenu := CreateUnLoad<TPopupActionBar>;
  FDockClient.NCPopupMenu.OnPopup := NCPopup;
  NClose := AddToNCMenu(RS_DocformClose, Close_ItemClick);
  AddToNCMenu('-');
  NTab := AddToNCMenu(RS_DocformTab, Tab_ItemClick);
  NDock := AddToNCMenu(RS_DocformZak, Dock_ItemClick);
  AddToNCMenu('-');
  Icon := ClassIcon;
  NCanClose := True;
end;


procedure TDockIForm.NCPopup(Sender: TObject);
begin
  with FDockClient.NCPopupMenu do if (PopupComponent = Self) or (PopupComponent is TPageControl) then
   begin
    Nclose.Enabled := NCanClose and not (HostDockSite is TJvDockTabPageControl);
    Ntab.Enabled := not IsAutoHidden;
    NDock.Enabled := not (IsAutoHidden or IsTabbedDocument);
    Ntab.Checked := IsTabbedDocument;
    NDock.Checked := FDockClient.EnableDock;
   end
  else
   begin
    Nclose.Enabled := False;
    Ntab.Enabled := False;
    NDock.Enabled := False;
   end;
end;

procedure TDockIForm.OnFormShow(Sender: TObject);
 var
  da: TIDynamicAction;
  s: string;
begin
  s:= Format('%s_%s',[Name, 'OnShowAction']);
  GContainer.RemoveInstance(TypeInfo(TIDynamicAction), s);
end;

procedure TDockIForm.OnFormHide(Sender: TObject);
 var
  da: TIDynamicAction;
  s: string;
begin
  ///
  if FEnableCloseDialog and not (HostDockSite is TJvDockTabPageControl)
     and (MessageDlg(RS_MSG_Close+Caption+RS_MSG_hide, mtWarning, [mbYes, mbNo], 0) = mrYes) then
    Close_ItemClick(Sender)
  ///
  else
   begin
    s:= Format('%s_%s',[Name, 'OnShowAction']);
    GContainer.RemoveInstance(TypeInfo(TIDynamicAction), s);
    da := TIDynamicAction.CreateUser(Caption, RS_Hiddenwindows, Icon);
    da.Name := s;
    da.InstanceName := Name;
    da.ActionComponentClass := ClassName;
    da.ActionMethodNameExec := 'OnShowAction';
  //  da.AddToActionManager('Окна', Caption, ClassIcon, 0);
    TRegister.AddType<TIDynamicAction>.AddInstance(s, da as IInterface);
    (GlobalCore as IActionProvider).RegisterAction(da);
    (GlobalCore as IActionProvider).ShowInBar(0, RS_Hiddenwindows, da as IAction);
  //  AfteActionManagerLoad;
   end;
end;

procedure TDockIForm.OnShowAction(Sender: IAction);
begin
  ShowDockForm(Self);
end;

procedure TDockIForm.RemoveSelfFromDock;
 var
  vs: TJvDockVSNETPanel;
  ppp: TJvDockPosition;
  s: TJvDockServer;
  p: TJvDockPanel;

  Channel: TJvDockVSChannel;

begin
  FDockClient.OnFormShow := nil;
  FDockClient.OnFormHide := nil;

  HideDockForm(Self); // не удалять!!!! скрытие формы из экрана и док-системы

  //вручную удаляю все ссылки  на блоки нашел в DoFolatForm
  Channel := RetrieveChannel(HostDockSite);
  if Assigned(Channel) then Channel.RemoveDockControl(self);
  //вручную удаляю все ссылки на зоны
  if JvGlobalDockManager.DockServerCount > 0 then
   begin
    s := JvGlobalDockManager.DockServer[0];
    for ppp := dpLeft to dpCustom do
      if Assigned(s.DockPanel[ppp]) and Assigned(s.DockPanel[ppp].JvDockManager) then
       begin
        s.DockPanel[ppp].JvDockManager.RemoveControl(self);
        if s.DockPanel[ppp] is TJvDockVSNETPanel then
         begin
          vs := TJvDockVSNETPanel(s.DockPanel[ppp]);
          vs.VSChannel.VSPopupPanel.JvDockManager.RemoveControl(self);
         end;
       end;
   end;
end;

procedure TDockIForm.SetCaption(const Value: string);
begin
  FCaption := Value;
  inherited Caption := FCaption;
end;

procedure TDockIForm.SetNCMenusVisible(const snc: ShowNCMenu);
begin
  NClose.Visible := sncClose in snc;
  NTab.Visible := sncTab in snc;
  NDock.Visible := sncDock in snc;
end;

function TDockIForm.AddToNCMenu(const ACaption: string; AClick: TNotifyEvent; Index, Autocheck: Integer; Root: TMenuItem): TMenuItem;
begin
  Result := TMenuItem.Create(FDockClient.NCPopupMenu);
  Result.Caption := ACaption;
  Result.OnClick := AClick;
  if Assigned(Root) then Root.Add(Result)
  else FDockClient.NCPopupMenu.Items.Add(Result);
  if Index <> -1 then Result.MenuIndex := Index;
  if Autocheck <> -1 then
   begin
    Result.AutoCheck := True;
    Result.Checked := Autocheck = 1;
   end;
end;

class function TDockIForm.ClassIcon: Integer;
begin
  Result := 305;
end;

procedure TDockIForm.Close_ItemClick(Sender: TObject);
 var
  fe: IFormEnum;
begin
  if Supports(GlobalCore, IFormEnum, fe) then
   begin
    fe.Remove(Self as IForm);
    MainScreenChanged;
   end;
end;

destructor TDockIForm.Destroy;
begin
//  TDebug.Log('TDockIForm.Destroy    '+ Name+ '    ' + caption+ '    ' );
  RemoveSelfFromDock;
  GContainer.RemoveInstance(TypeInfo(TIDynamicAction), Format('%s_%s',[Name, 'OnShowAction']));
  inherited;
end;

procedure TDockIForm.Dock_ItemClick(Sender: TObject);
begin
  if not IsAutoHidden then FDockClient.EnableDock := not FDockClient.EnableDock
end;

class function TDockIForm.GetUniqueForm(const FormName: string): IForm;
 var
  fe: IFormEnum;
begin
  if Supports(GlobalCore, IFormEnum, fe) then Result := fe.Get(FormName)
  else Result := nil;
  if Assigned(Result) then
   begin
    ShowDockForm(TDockIForm(Result));
    (GlobalCore as ITabFormProvider).SetActiveTab(Result);
   end
  else
   begin
    Result := CreateUser(FormName) as IForm;
    if Assigned(fe) then fe.Add(Result);
    Result.Show;
    MainScreenChanged;
   end;
end;

class procedure TDockIForm.DoCreateForm(Sender: IAction);
 var
  f: IForm;
  fe: IFormEnum;
begin
  f := CreateUser() as IForm;
  if Supports(GlobalCore, IFormEnum, fe) then fe.Add(f);
  f.Show;
  MainScreenChanged;
end;

procedure TDockIForm.DoShow;
begin
  inherited;
  FEnableCloseDialog := True;
end;

procedure TDockIForm.Tab_ItemClick(Sender: TObject);
 var
  t: ITabFormProvider;
begin
  if Supports(GlobalCore, ITabFormProvider, t) then
   begin
    if t.IsTab(Self as IForm) then t.UnTab(Self as IForm)
    else t.Tab(Self as IForm)
   end;
end;
{$ENDREGION}

{ TDialogIForm }

procedure TDialogIForm.Close_ItemClick(Sender: TObject);
begin
  inherited;
  RegisterDialog.UnInitialize(GetInfo);
end;

constructor TDialogIForm.Create;
begin
  CreateUser('Dialog_' + ClassName);
  FDockClient.EnableDock := False;
end;

function TDialogIForm.Priority: Integer;
begin
  Result := PRIORITY_NoStore;
end;

{ TCustomFontIForm }

procedure TCustomFontIForm.InitializeNewForm;
begin
  inherited;
  NFont := AddToNCMenu(RS_celectFont, NFontClick);
end;

procedure TCustomFontIForm.DoSetFont(const AFont: TFont);
begin
  Font := AFont;
end;

procedure TCustomFontIForm.NFontClick(Sender: TObject);
 var
  fd: TFontDialog;
begin
  fd := TFontDialog.Create(nil);
  try
   fd.Font := Font;
   if fd.Execute(Handle) then DoSetFont(fd.Font);
  finally
   fd.Free;
  end;
end;

end.

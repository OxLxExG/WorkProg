unit MainForm;

interface

{$I Script.inc}

uses DeviceIntf, ExtendIntf, RootIntf, IndexBuffer, Container, JvDockGlobals,  AbstractPlugin, System.Threading,
  Winapi.Messages, System.Variants, Vcl.HtmlHelpViewer,  Vcl.Themes, tools,
  System.SysUtils, PluginAPI, Vcl.Dialogs, Vcl.ImgList, Vcl.Controls, Vcl.StdActns, Vcl.BandActn, System.Classes, Vcl.ActnList, Vcl.ActnMan,
  Vcl.ActnCtrls, Vcl.ActnMenus, Vcl.ComCtrls, Vcl.Forms, Vcl.Graphics, Winapi.Windows, JvAppStorage, JvAppRegistryStorage, JvDockControlForm,
  Vcl.AppEvnts, Vcl.ExtCtrls, JvFormPlacement, JvDockVIDStyle, JvComponentBase, System.Actions,
  System.Generics.Collections,
  System.Generics.Defaults,  JvDockSupportControl,
  JvDockVSNetStyle, JvDockTree, Vcl.ToolWin, Vcl.PlatformDefaultStyleActnCtrls, System.ImageList, JvAppXMLStorage,
  JvDockDelphiStyle, JvDockVCStyle, JvDockVIDVCStyle;

resourcestring
  RS_DevWork='Прибор [%s] в работе. Необходимо завершить операцию обмена данными';
  RS_delayInt='Интервал задержки: %s';
  RS_InWprk='Работает: %s, кадр %d';
  RS_idle='Не поставлен на задержку';
const
  DEF_SCREEN = 'ScreenDefault13';
  REG_PATH = 'Software\AMKGorizont\WorkProg13';

  MENU_UPDATE_MESSAGE = WM_APP + 1;
  SHOW_IN_BAR_MESSAGE1 = WM_APP + 2;
  SHOW_IN_BAR_MESSAGE2 = WM_APP + 3;

type
  TFormMain = class(TForm, IImagProvider, IActionProvider, IRegistry, ITabFormProvider, IMainScreen, IProject)
    ActionManager: TActionManager;
    CustomizeActionBars: TCustomizeActionBars;
    ActionUpdate: TAction;
    ActionExit: TAction;
    ActionSaveDesktop: TAction;
    ActionLoadDesktop: TAction;
    ActionPluginSetup: TAction;
    ImageList: TImageList;
    rini: TJvAppRegistryStorage;
    ControlBar: TControlBar;
    MainMenu: TActionMainMenuBar;
    ToolBar1: TActionToolBar;
    ToolBar2: TActionToolBar;
    sb: TStatusBar;
    ActionExceptForm: TAction;
    FormStorage: TJvFormStorage;
    ApplicationEvents: TApplicationEvents;
    pc: TPageControl;
    JvDockServer: TJvDockServer;
    xini: TJvAppXMLFileStorage;
    TimerDelay: TTimer;
    ThemeDark: TAction;
    JvDockVSNetStyle: TJvDockVSNetStyle;
    procedure FormCreate(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure ActionExitExecute(Sender: TObject);
    procedure ActionPluginSetupExecute(Sender: TObject);
    procedure FormCloseQuery(Sender: TObject; var CanClose: Boolean);
    procedure FormDestroy(Sender: TObject);
    procedure SaveScreenClick(Sender: TObject);
    procedure Debug_ReloadClick(Sender: TObject);
    procedure ActionUpdateExecute(Sender: TObject);
    procedure ControlBarBandPaint(Sender: TObject; Control: TControl; Canvas: TCanvas; var ARect: TRect; var Options: TBandPaintOptions);
//    procedure TimerTimer(Sender: TObject);
    procedure ActionExceptFormExecute(Sender: TObject);
    procedure pc1ContextPopup(Sender: TObject; MousePos: TPoint; var Handled: Boolean);
    procedure ApplicationEventsException(Sender: TObject; E: Exception);
    procedure CustomizeActionBarsCustomizeDlgClose(Sender: TObject);
    procedure TimerDelayTimer(Sender: TObject);
    procedure ThemeDarkExecute(Sender: TObject);
//    procedure PrjNewAccept(Sender: TObject);
//    procedure PrjOpenAccept(Sender: TObject);
//    procedure PrjCloseExecute(Sender: TObject);
//    procedure SetupProjectExecute(Sender: TObject);
  protected
    // IImagProvider
    procedure GetIcon(Index: integer; Image: TIcon);
    function GetImagList: TImageList;
    // IActionProvider
//    function IActionProvider.Create = CreateAction;
//    function CreateAction(const ACategory, ACaption, AName: WideString; Event: TIActionEvent; ImagIndex: Integer = -1; GroupIndex: Integer = -1): IAction;
    procedure ShowInBar(BarID: Integer; const path: string; Action: IAction; Index: Integer = -1); overload;
    procedure ShowInBar(BarID: Integer; const path: TArray<TMenuPath>; Action: IAction; ActionIndex: Integer = -1); overload;

//    procedure ShowInBar(BarID: Integer; const path: WideString; Action: IAction; Index: Integer = -1);
    procedure HideInBar(BarID: Integer; Action: IAction);
    procedure SetIndexInBar(BarID: Integer; const ACaption: string; Index: Integer);
    procedure RegisterAction(Action: IAction);
    procedure UpdateWidthBars;
    function HideUnusedMenus: boolean;
    procedure SaveActionManager();
    procedure ResetActions(isNew: Boolean =false);
    procedure UpdateMenus;
    // IRegistry
    procedure SaveString(const Name, Value: String; Registry: Boolean = False);
    function LoadString(const Name, DefValue: String; Registry: Boolean = False): String;
    procedure SaveArrayString(const Root: String; const Value: TArray<string>; Registry: Boolean = False);
    procedure LoadArrayString(const Root: String; var Value: TArray<string>; Registry: Boolean = False);
    //  ITabFormProvider (зависит от версии компилятора т.к. использ TDockIForm, TJvDockClient
    function IsTab(const Form: IForm): Boolean;
    procedure Tab(const Form: IForm);
    procedure UnTab(const Form: IForm);
    procedure SetActiveTab(const Form: IForm);
    procedure ITabFormProvider.Dock = ITabFormProviderDock;
    procedure ITabFormProviderDock(const Form: IForm; Corner: Integer);
    //IMainScreen
    procedure IMainScreen.Changed = MainScreenChanged;
    procedure MainScreenChanged;

    function GetStatusBar(index: Integer): string;
    procedure SetStatusBar(index: Integer; const Value: string);
    function GetThemeName: string;
    procedure SetThemeName(const Value: string);

    function GetDockStyle: TObject;

    procedure Lock;
    procedure UnLock;

    //IProject = interface
    function IProject.New = IProjectNew;
    function IProjectNew(out ProjectName: string): Boolean;
    function IProject.Load = IProjectLoad;
    function IProjectLoad(out ProjectName: string): Boolean;
    function IProject.Setup =IProjectSetup;
    function IProjectSetup: Boolean;
    procedure IProject.Close = IProjectClose;
    procedure IProjectClose;
    procedure IProjectInnerLoad(const PrjName: string; isNew: Boolean);
    function GetDecimalSeparator: Char;

  private
    FDecimalSeparator: Char;
    FMainScreenChange: Boolean;
    procedure InjectDependDevs;
    procedure SaveScreeDialog;
    function ChildFormsBusy: boolean;
    function DeviceBusy: boolean;
    procedure debug_log_dock;
    procedure clear_dock_zones;
    procedure SetColorsDockStyle(DarkTheme: Boolean);
    procedure ClearProjectForms;
    procedure MenuUpdateMessage(var Msg: TMessage); message MENU_UPDATE_MESSAGE;
//    procedure ShowInBarMessage1(var Msg: TMessage); message SHOW_IN_BAR_MESSAGE1;
//    procedure ShowInBarMessage2(var Msg: TMessage); message SHOW_IN_BAR_MESSAGE2;
//    procedure AfterLoadScreen;
//    procedure SetProjectFile(const Value: WideString);
//    procedure SowPrg(sho: Boolean);
//    procedure WMSync(var Message: TMessage); message WM_SYNC;
  public
    FCurrentScreen: string;
    procedure RegisterProviders;
    procedure LoadNotify;
    procedure LoadScreen(LoadProject: Boolean = False);
    procedure LoadActionManager;
    procedure SaveTabForms();
    procedure LoadTabForms();
    property StatusBar[index: Integer]: string read GetStatusBar write SetStatusBar;
  end;


var
  FormMain: TFormMain;

//type
// MyTJvDockTree = class(TJvDockVSNETTree);

implementation

{$R *.dfm}


uses GR32, {WinAPI.GDIPObj, WinAPI.GDIPApi,} RootImpl, {VCLTee.TeEngine,} DataImportImpl,
  {$IFDEF USE_LUA_SCRIPT}
    XMLLua, XMLLua.Math, XMLLua.IKN, XMLLua.Report,
  {$ELSE}
    XMLScript, XMLScript.Math, XMLScript.IKN, XMLScript.Report,
  {$ENDIF}
    PluginManager, PluginSetupForm, ExceptionForm, DockIForm, debug_except, ActionBarHelper, FirstForm;//, Hock_Exept;


function GetVclAppVersion: string;
var
  V: TVersion;
begin
  if TAbstractPlugin.GetModuleVersion(V, HInstance) then
   Result := Format('%d.%d.%d.%d', [V.Major,V.Minor,V.Release,V.Build])
  else Result := '0.0.0.0';
end;

{$REGION  '*********** Create Destroy ****************'}
procedure TFormMain.FormCreate(Sender: TObject);
begin
  TThread.NameThreadForDebugging('__M_A_I_N__');
  Application.HelpFile := ExtractFilePath(ParamStr(0)) + 'help.chm';
  Caption := 'Горизонт бурение ' + GetVclAppVersion;
//  GDIPlus.Start;

  FDecimalSeparator := FormatSettings.DecimalSeparator;
  FormatSettings.DecimalSeparator := '.';
  FormatSettings.DateSeparator := '.';
  FormatSettings.TimeSeparator := ':';
  FormatSettings.ShortDateFormat := 'dd.MM.yyyy';
  FormatSettings.LongTimeFormat := 'h:mm:ss';

  SetErrorMode(SetErrorMode(0) or SEM_NOOPENFILEERRORBOX or SEM_FAILCRITICALERRORS);
  ///Plugins.SetVersion(VERS1000);

//  StatusBar[1] := 'Проект не создан';//ExtractFilePath(ParamStr(0)) + 'Default.xml';

  //  *******************************************8
  //     Регистрация провайдеров сервисов ядра
  //  *******************************************8
  TRegister.AddType<TFormMain, IImagProvider, IActionProvider, IRegistry, ITabFormProvider, IMainScreen, IProject>.LiveTime(ltSingleton).AddInstance(Self as IInterface);

  TFormExceptions.Init();
  TFormExceptions.This.Icon := 257;

  rini.Root := REG_PATH;
   { TODO : создание разных рабочих столов }
  FCurrentScreen := rini.ReadString('screen', DEF_SCREEN);
  rini.Root := REG_PATH + '\' + FCurrentScreen;

  if not rini.ValueStored('isdark') then
   begin
    rini.Root := 'SOFTWARE\Microsoft\Windows\CurrentVersion\Themes\Personalize';
    var izLight := rini.ReadInteger('AppsUseLightTheme', 1);
    rini.Root := REG_PATH + '\' + FCurrentScreen;
    rini.WriteBoolean('isdark', not boolean(izLight));
   end;

  ThemeDark.Checked := rini.ReadBoolean('isdark');
  if not ThemeDark.Checked then
   begin
    TStyleManager.TrySetStyle('Windows11 Polar Light');
   end;
  SetColorsDockStyle(ThemeDark.Checked);
end;

procedure TFormMain.RegisterProviders;
begin
  TRegister.AddType<TFormMain>.AddInstance(Self as IInterface);
end;

procedure TFormMain.FormShow(Sender: TObject);
// var
//  a: TICustRTTIAction;
begin
  try
//   PrjNew.Dialog.InitialDir := ExtractFilePath(ParamStr(0)) + 'Projects';
    //  *******************************************
    // загрузка плагинов с событием LoadNotify после загрузки осгновной формы !!!
    //  *******************************************
   TFormPluginSetup.LoadPlugins(rini.Root, nil, True);

    // LoadNotify функция вызывается после загрузки плугинов и перед событием LoadNotify
    // регистрируем провайдеры которым нужны для регистрации плугины но желательно до
    // события LoadNotify (LoadNotify провайдеров происходит после пругинов)
  finally
  // if Assigned(FormSplash) then FreeAndNil(FormSplash);
   TFormExceptions.This.NShowDebug.Checked := FormStorage.StoredValue['ErrorInfo'];
   TFormExceptions.This.NDialog.Checked := FormStorage.StoredValue['ErrorDialog'];
  end;

  OutputDebugString(PChar('==================  НАЧАЛО РАБОТЫ ПРОГРАММЫ  ================================='));

//  GContainer.Enum<IPlugin>(True);

//  a := TICustRTTIAction.Create;
   // FormGraphLog13109997256: TFormGraphLog
//  a.ActionComponentClass := 'TFormGraphLog';
//  a.ActionMethodName := 'DoCreateForm';
//  a.AddToActionManager('Окна','TEST',123,0);
//  a.Execute;
end;
procedure TFormMain.LoadNotify; // call LoadPlugins
begin
  if (ParamCount >= 1) and (Trim(ParamStr(1)) = '-nl') then ResetActions(True)
  else
   begin
    LoadScreen(True);
    InjectDependDevs; // чтобы устранить ошибку пропадания меню приборов
    TActionBarHelper.VisibleContainedToIAction(ActionManager);
//    UpdateWidthBars;
   end;
end;


procedure TFormMain.FormCloseQuery(Sender: TObject; var CanClose: Boolean);
  procedure ClrItems; // m должен быть локальн.
   var
    m: IManager;
  begin
    if Supports(Plugins, IManager, m) then m.ClearItems;
  end;
begin
  SaveScreeDialog;
  CanClose := not (ChildFormsBusy or DeviceBusy);
  if not CanClose then Exit;
  OutputDebugString(PChar('==================  ЗАКРЫТИЕ ПРОГРАММЫ  ================================='));
  TIForm.DoDestroyApp := True;
  LockWindowUpdate(Handle);
  try
   ClrItems;
   Plugins.UnloadAll;
   TFormExceptions.DeInit();
  finally
   LockWindowUpdate(0);
  end;
//  ini.Root := REG_PATH;
//  ini.WriteString('screen', FCurrentScreen);
end;
procedure TFormMain.FormDestroy(Sender: TObject);
begin
  OutputDebugString(PChar('***************   ВСЕ ИНТЕРФЕЙСЫ И МОДУЛИ ДОЛЖНЫ УЖЕ БЫТЬ ЗАКРЫТЫ  ******************* '));
//  GDIPlus.Stop;
end;
{$ENDREGION  '*********** Create Dectroy ****************'}


{$REGION  '*********** SAVE LOAD ****************'}
procedure TFormMain.Debug_ReloadClick(Sender: TObject);
 var
  m: IManager;
begin
  SaveScreeDialog;
  if Supports(Plugins, IManager, m) and not ChildFormsBusy and not DeviceBusy then
   begin
    (GlobalCore as IFormEnum).Clear;
    LoadScreen();
   end;
end;

procedure TFormMain.SaveTabForms();
 var
  ss: TStrings;
  i : Integer;
begin
  ss := TStringList.Create;
  try
   for i:=0 to pc.PageCount-1 do ss.Add(TForm(pc.Pages[i].Tag).Name);
   xini.WriteStringList('Tabs', ss);
   xini.WriteInteger('Tabs\ActiveTab', pc.ActivePageIndex);
  finally
   ss.Free;
  end;
end;

procedure TFormMain.LoadTabForms();
 var
  d: IFormEnum;
  f: IForm;
  ss: TStrings;
  i: Integer;
begin
 if Supports(Plugins, IFormEnum, d) then
  begin
   ss := TStringList.Create;
   try
    xini.ReadStringList('Tabs', ss);
    for i := 0 to SS.Count-1 do
     for f in d do
      if SameText((f as IManagItem).IName, ss[i]) then
     begin
      Tab(f);
      Break;
     end;
   finally
    ss.Free;
   end;
   i := xini.ReadInteger('Tabs\ActiveTab', 0);
   if (i >= 0) and (i < pc.PageCount) then  pc.ActivePageIndex := i;
  end;
end;

procedure TFormMain.SaveActionManager;
// var
//  S: TMemoryStream;
 var
  ss: TStringStream;
  ms: TMemoryStream;
begin
  ss := TStringStream.Create;
  ms := TMemoryStream.Create;
  try
   ActionManager.SaveToStream(ms);
   ms.Position := 0;
   ObjectBinaryToText(ms, ss);
   //(GContainer as IProjectOptions).Option['ActionManager'] := ss.DataString;
   xini.WriteString('ActionManager\ObjectText', ss.DataString);
//   ss.SaveToFile('c:\XE\Projects\Device2\_exe\ActionManager.txt');
  finally
   ss.Free;
   ms.Free;
  end;
//  s := TMemoryStream.Create;
//  try
//   ActionManager.SaveToStream(S);
//   ini.WriteBinary('ActionManager\data', S.Memory, S.Size);
//   ini.WriteInteger('ActionManager\size', S.Size);
//  finally
//   S.Free;
//  end;
end;

procedure TFormMain.SaveScreenClick(Sender: TObject);
 var
  m: IManager;
  i: Integer;
begin
  FMainScreenChange := False;
  FormStorage.StoredValue['ErrorInfo'] := TFormExceptions.This.NShowDebug.Checked;
  FormStorage.StoredValue['ErrorDialog'] := TFormExceptions.This.NDialog.Checked;
  if Supports(Plugins, IManager, m) then m.SaveScreen();                // формы  обьекты
  try
   SaveDockTreeToAppStorage(xini, 'DockTree'); // Dock manager (зависит от версии компилятора т.к. использ TForm, TJvDockClient)
  except
   on E: Exception do TDebug.DoException(E, False);
  end;
  SaveTabForms();                         // Tab forms (зависит от версии компилятора т.к. использ TForm, TJvDockClient)
  SaveActionManager;                 // Action manager основной формы
  FormStorage.SaveFormPlacement;      // сохранение cool bar основной формы
  //FormPlacement.SaveFormPlacement;      // сохранение cool bar основной формы
  //xini.Flush; // !!!
  (GContainer as IProjectOptions).Option['CurrentScreen'] := xini.AsString;
  rini.Flush;
end;

//procedure TFormMain.AfterLoadScreen;
// var
//  aaml: INo tifyAf teActionManagerLoad;
//  m: IManager;
//  FlagSave: Boolean;
//  p: IPlugin;
//begin
{  for p in GContainer.Enum<IPlugin> do// .CreateAndExecService<IPluginNotify>(procedure(p: IPluginNotify)
//  GContainer.ExecExistsService<IPlugin>(procedure(p: IPlugin)
  begin
   if Supports(p, INoti fyAfteA ctionManagerLoad, aaml) then aaml.AfteActionManagerLoad();
  end;}
//  if Supports(GlobalCore, IManager, m) then m.NotifyAfteActionManagerLoad;
//  SowPrg((Plugins.IndexOf(FORM_Control) >= 0) and (Plugins.IndexOf(PLUGIN_ComDev) >= 0));{ TODO : восстановить }
//end;

procedure Test(c: TComponent);
 var
  ss: TStringStream;
  ms: TMemoryStream;
begin
  ss := TStringStream.Create;
  ms := TMemoryStream.Create;
  try
   ms.WriteComponent(c);
   ms.Position := 0;
   ObjectBinaryToText(ms, ss);
   ss.SaveToFile('C:\XE\Projects\Device2\_exe\'+c.Name+'.txt');
  finally
   ss.Free;
   ms.Free;
  end;
end;

procedure TFormMain.LoadActionManager;
 var
  ss: TStringStream;
  ms: TMemoryStream;
begin
  if  xini.ValueStored('ActionManager\ObjectText') then
//  if  not VarIsNull((GContainer as IProjectOptions).Option['ActionManager']) then
   begin
    ss := TStringStream.Create;
    ms := TMemoryStream.Create;
    try
     ss.WriteString(xini.ReadString('ActionManager\ObjectText', ''));
     //ss.WriteString((GContainer as IProjectOptions).Option['ActionManager']);
     ss.Position := 0;
     ObjectTextToBinary(ss, ms);
     ms.Position := 0;
     ActionManager.LoadFromStream(ms);
    finally
     ss.Free;
     ms.Free;
    end;
   end;
end;

procedure TFormMain.ResetActions(isNew: Boolean =false);
 var
  a: IAction;
  ar: TArray<IAction>;
begin
  ar := GContainer.InstancesAsArray<IAction>(True);
  Tarray.Sort<IAction>(ar, TComparer<IAction>.Construct(function(const Left, Right: IAction): Integer
  begin
    Result := string.Compare(Left.GetPath, Right.GetPath);
  end));
  if isNew then
   begin
    ActionManager.ResetActionBar(0);
    ActionManager.ResetActionBar(1);
    ActionManager.ResetActionBar(2);
   end
  else LoadActionManager; // скрывает часть { TODO : проблемма с - и логикой действий}
  for a in ar do
   begin
    if not a.OwnerExists then
     begin
      GContainer.RemoveInstance(a.Model, a.IName);
     end
    else if not Assigned(ActionManager.FindItemByAction(TCustomAction(a.GetComponent))) or isNew then
     begin
      a.DefaultShow;
     end;
   end;
  if HideUnusedMenus then
   begin
    UpdateWidthBars;
    SaveActionManager;
   end;
end;

procedure TFormMain.LoadScreen(LoadProject: Boolean = False);
// var
//  m: IManager;
begin
  StatusBar[1] := rini.ReadString('CurrentProject');
  IProjectInnerLoad(StatusBar[1], False);
 { BeginDockLoading;
  try
    //xini.Reload; // !!!
    StatusBar[1] := rini.ReadString('CurrentProject');
    if Supports(Plugins, IManager, m) then
     begin
      if LoadProject and (StatusBar[1] <> '') then m.LoadProject(StatusBar[1]);
      (GContainer as IProjectOptions).AddOrIgnore('CurrentScreen', 'Screen');

      if not VarIsNull((GContainer as IProjectOptions).Option['CurrentScreen']) then
         xini.AsString := (GContainer as IProjectOptions).Option['CurrentScreen'];

      m.LoadScreen();                 //  загрузка текстов обьектов - форм actions
     end;

    // create actions
    ResetActions;     // показывает все

    // create forms
    GContainer.InstancesAsArray<IForm>(True);


    LoadDockTreeFromAppStorage(xini, 'DockTree');
    LoadTabForms();

    FormStorage.RestoreFormPlacement;
//    AfterLoadScreen;
  finally
    EndDockLoading;
  end; }
end;

{procedure TFormMain.PrjCloseExecute(Sender: TObject);
 var
  m: IManager;
begin
  LockWindowUpdate(Handle);
  try
   if not Supports(Plugins, IManager, m) then Exit;
   StatusBar[1] := '';
   m.LoadProject(StatusBar[1]);
   ini.WriteString('CurrentProject', StatusBar[1]);
   ResetActions;
  finally
   LockWindowUpdate(0);
  end;
end;

procedure TFormMain.PrjNewAccept(Sender: TObject);
 var
  m: IManager;
begin
  LockWindowUpdate(Handle);
  try
   if not Supports(Plugins, IManager, m) then Exit;
   StatusBar[1] := PrjNew.Dialog.FileName;
   m.NewProject(StatusBar[1]);
   ini.WriteString('CurrentProject', StatusBar[1]);
   ResetActions;
  finally
   LockWindowUpdate(0);
  end;
end;

procedure TFormMain.PrjOpenAccept(Sender: TObject);
 var
  m: IManager;
begin
  LockWindowUpdate(Handle);
  try
   if not Supports(Plugins, IManager, m) then Exit;
   StatusBar[1] := PrjOpen.Dialog.FileName;
   m.LoadProject(StatusBar[1]);
   ini.WriteString('CurrentProject', StatusBar[1]);
   ResetActions;
  finally
   LockWindowUpdate(0);
  end;
end;    }
{$ENDREGION  *********** SAVE LOAD ****************}


{$REGION  '*********** Providers ****************'}
// IRegistry
procedure TFormMain.SaveArrayString(const Root: String; const Value: TArray<string>; Registry: Boolean = False);
 var
  i: Integer;
  s: TJvCustomAppStorage;
begin
  if Registry then s := rini else s := xini;
  s.DeleteSubTree(Root);
  s.WriteInteger(Root+ '\ItemCount', Length(Value));
  for i := 0 to Length(Value)-1 do s.WriteString(Root+ '\Item'+i.ToString, Value[i]);
end;

procedure TFormMain.LoadArrayString(const Root: String; var Value: TArray<string>; Registry: Boolean = False);
 var
  i: Integer;
  s: TJvCustomAppStorage;
begin
  if Registry then s := rini else s := xini;
  SetLength(Value, s.ReadInteger(Root+ '\ItemCount',0));
  for i := 0 to Length(Value)-1 do Value[i] := s.ReadString(Root+ '\Item'+i.ToString, '');
end;

function TFormMain.LoadString(const Name, DefValue: String; Registry: Boolean = False): String;
 var
  s: TJvCustomAppStorage;
begin
  if Registry then s := rini else s := xini;
  Result := s.ReadString(Name, DefValue);
end;

procedure TFormMain.SaveString(const Name, Value: String; Registry: Boolean = False);
 var
  s: TJvCustomAppStorage;
begin
  if Registry then s := rini else s := xini;
  s.WriteString(Name, Value);
end;

//ITabFormProvider
procedure TFormMain.pc1ContextPopup(Sender: TObject; MousePos: TPoint; var Handled: Boolean);
 var
  i: integer;
begin
  with Sender as TPageControl do
   begin
    if [htOnItem] * GetHitTestInfoAt(MousePos.X, MousePos.Y) <> [] then
     begin
      i := IndexOfTabAt(MousePos.X, MousePos.Y);
      if i >= 0 then ActivePage := Pages[i];
      PopupMenu :=  TDockIForm(ActivePage.tag).GetDockClient.NCPopupMenu;
     end
    else PopupMenu := nil;
   end;
end;

function TFormMain.IsTab(const Form: IForm): Boolean;
 var
  i: Integer;
begin
  Result := False;
  for i := 0 to pc.PageCount-1 do if (TDockIForm(pc.Pages[i].tag) as IForm) = Form then Exit(True)
end;

procedure TFormMain.UnTab(const Form: IForm);
 var
  i: Integer;
  f: TDockIForm;
begin
  BeginDockLoading;
  try
  for i := 0 to pc.PageCount-1 do if (TDockIForm(pc.Pages[i].tag) as IForm) = Form then
   begin
    f := TDockIForm(pc.Pages[i].tag);
    DoFloat(pc, f);
    f.GetDockClient.EnableDock := Boolean(f.Tag);
    Exit;
   end;
  finally
   EndDockLoading;
  end;
end;

procedure TFormMain.MenuUpdateMessage(var Msg: TMessage);
begin
  ActionUpdateExecute(nil);
end;


procedure TFormMain.UpdateMenus;
begin
  PostMessage(Self.Handle, MENU_UPDATE_MESSAGE, 100, 0);
end;

procedure TFormMain.UpdateWidthBars;
  procedure SetBar(b: TCustomActionDockBar);
   var
    i: Integer;
  begin
    for I := 0 to b.ActionClient.Items.Count-1 do b.ActionClient.Items[i].Visible := True;
    b.ClientWidth := b.CalcDockedWidth;
  end;
begin
  HideUnusedMenus;

//  Application.HandleMessage;
//  SetBar(MainMenu);
//  SetBar(ToolBar1);
//  SetBar(ToolBar2);
//  Application.HandleMessage;

  SetBar(MainMenu);
  SetBar(ToolBar1);
  SetBar(ToolBar2);
end;

//procedure TFormMain.WMSync(var Message: TMessage);
// var
//  i: Integer;
//begin
//  for i := 0 to  Plugins.Count-1 do Plugins[i].CheckSynchronize;
//  CheckSynchronize;
//end;

procedure TFormMain.Tab(const Form: IForm);
 var
  i: Integer;
  f: TDockIForm;
begin
  BeginDockLoading;
  try
   for i := 0 to pc.PageCount-1 do if (TDockIForm(pc.Pages[i].tag) as IForm) = Form then Exit;
   f := TDockIForm((Form as IInterfaceComponentReference).GetComponent);
   if F.ManualDock(pc) then
    begin
     f.Parent.Tag := Integer(f);
     TTabSheet(f.Parent).ImageIndex := f.Icon;
     f.Tag := Integer(f.GetDockClient.EnableDock);
     f.GetDockClient.EnableDock := False;
     f.Show;
    end;
  finally
   EndDockLoading;
  end;
end;

procedure TFormMain.SetColorsDockStyle(DarkTheme: Boolean);
var
  ActStyle: TCustomStyleServices;
  cs: TJvDockVSNETConjoinServerOption;
  ts: TJvDockVSNETTabServerOption;
  hs: TJvDockVSNETChannelOption;
begin
  CurrentThmemeIsDarkTheme := DarkTheme;
  CurrentThemeIsDark := DarkTheme;
  cs := TJvDockVSNETConjoinServerOption(JvDockVSNetStyle.ConjoinServerOption);
  ts := TJvDockVSNETTabServerOption(JvDockVSNetStyle.TabServerOption);
  hs := TJvDockVSNETChannelOption(JvDockVSNetStyle.ChannelOption);
  ActStyle := TStyleManager.ActiveStyle;
  if Assigned(ActStyle) and ActStyle.Enabled then
  begin
    clThBkg := ActStyle.GetStyleColor(scGenericBackground);
    clThSplit := ActStyle.GetStyleColor(scSplitter);
    clThBorder := ActStyle.GetStyleColor(scBorder);
    clThWindowTextNormal := ActStyle.GetStyleFontColor(sfWindowTextNormal);
    clThWindowTextDisabled := ActStyle.GetStyleFontColor(sfWindowTextDisabled);
    clThButtonDisabled  := ActStyle.GetStyleColor(scButtonDisabled);
    clThButtonFocused := ActStyle.GetStyleColor(scButtonFocused);
    clThButtonNormal := ActStyle.GetStyleColor(scButtonNormal);

    cs.ActiveFont.Color := clThWindowTextNormal;
    cs.ActiveTitleStartColor  := clThButtonFocused;
    cs.InactiveFont.Color := clThWindowTextNormal;
    cs.InactiveTitleStartColor := clThButtonDisabled;

    cs.ActiveTitleEndColor := cs.ActiveTitleStartColor;
    cs.InactiveTitleEndColor := cs.InactiveTitleStartColor;


    var lp := TJvDockVSNETPanel(JvDockServer.LeftDockPanel);
    var rp := TJvDockVSNETPanel(JvDockServer.RightDockPanel);
    var bp := TJvDockVSNETPanel(JvDockServer.BottomDockPanel);

    lp.Color := clThBkg;
    rp.Color := clThBkg;
    bp.Color := clThBkg;
    lp.VSChannel.Color := clThBkg;
    rp.VSChannel.Color := clThBkg;
    bp.VSChannel.Color := clThBkg;

    if Assigned(lp.VSChannel.VSPopupPanel) then
     begin
      lp.VSChannel.VSPopupPanel.Color := clThBkg;
      lp.VSChannel.VSPopupPanelSplitter.Color:= clThSplit;
     end;
    if Assigned(rp.VSChannel.VSPopupPanel) then
     begin
      rp.VSChannel.VSPopupPanel.Color := clThBkg;
      rp.VSChannel.VSPopupPanelSplitter.Color:= clThSplit;
     end;
    if Assigned(bp.VSChannel.VSPopupPanel) then
     begin
      bp.VSChannel.VSPopupPanel.Color := clThBkg;
      bp.VSChannel.VSPopupPanelSplitter.Color:= clThSplit;
     end;

    hs.TabFrameColor :=  clThBorder;
    hs.TabColor := clThButtonNormal;

    ts.InactiveSheetColor := clThBkg;
    ts.ActiveSheetColor := clThBkg;
    ts.ActiveFont.Color := clThWindowTextNormal;

    JvDockServer.LeftSplitter.Color := clThSplit;
    JvDockServer.RightSplitter.Color := clThSplit;
    JvDockServer.TopSplitter.Color := clThSplit;
    JvDockServer.BottomSplitter.Color := clThSplit;
  end;
end;

procedure TFormMain.ClearProjectForms;
 var
  m: IManager;
begin
  if ChildFormsBusy or DeviceBusy then Exit;
  BeginDockLoading;
  try
    (GlobalCore as IFormEnum).Clear;
    ResetActions(True);
  finally
    EndDockLoading;
  end;
end;

procedure TFormMain.ThemeDarkExecute(Sender: TObject);
begin
   ClearProjectForms;
  TIForm.DoDestroyApp := True;
  try
    LockWindowUpdate(Handle);
    try
      if ThemeDark.Checked then
       begin
        TStyleManager.TrySetStyle('Windows11 Polar Dark');
       end
      else
       begin
        TStyleManager.TrySetStyle('Windows');
       end;
      rini.WriteBoolean('isdark', ThemeDark.Checked);
      SetColorsDockStyle(ThemeDark.Checked);
    finally
      LockWindowUpdate(0);
    end;
  finally
    TIForm.DoDestroyApp := False;
  end;
end;

procedure TFormMain.TimerDelayTimer(Sender: TObject);
 var
  opt: IProjectOptions;
  FDBTimeStart, FDBIntervalWork: TDateTime;
  iDelay: TTime;
begin
  if Supports(GContainer, IProjectOptions, opt) and (opt.Option['TIME_START'] <> null) then
   begin
    FDBTimeStart := opt.DelayStart;
    FDBIntervalWork := opt.IntervalWork;
    if FDBTimeStart > 0 then
     begin
      iDelay := Ctime.Round(FDBTimeStart - Now);
      if iDelay > 0 then
         sb.Panels[0].Text := Format(RS_delayInt, [Ctime.AsString(iDelay)])
      else
         sb.Panels[0].Text := Format(RS_InWprk, [Ctime.AsString(-iDelay), Ctime.RoundToKadr(-iDelay)]);
     end
    else sb.Panels[0].Text := RS_idle
   end
   else  sb.Panels[0].Text := RS_idle
end;

procedure TFormMain.SetActiveTab(const Form: IForm);
 var
  i: Integer;
begin
  for i := 0 to pc.PageCount-1 do if (TDockIForm(pc.Pages[i].tag) as IForm) = Form then
   begin
    pc.ActivePage := pc.Pages[i];
    Exit;
   end;
end;

// IImagProvider
function TFormMain.GetDecimalSeparator: Char;
begin
  Result := FDecimalSeparator;
end;

function TFormMain.GetDockStyle: TObject;
begin
  Result := JvDockVSNetStyle;
end;

procedure TFormMain.GetIcon(Index: integer; Image: TIcon);
begin
  ImageList.GetIcon(Index, Image);
end;

function TFormMain.GetImagList: TImageList;
begin
  Result := ImageList;
end;

// IActionProvider
//function TFormMain.CreateAction(const ACategory, ACaption, AName: WideString; Event: TIActionEvent; ImagIndex: Integer = -1; GroupIndex: Integer = -1): IAction;
//begin
//  Result := TIAction.CreateAction(ActionManager, ACategory, ACaption, AName, Event, ImagIndex, GroupIndex);
//end;
procedure TFormMain.SetIndexInBar(BarID: Integer; const ACaption: string; Index: Integer);
begin
  TActionBarHelper.Index(ActionManager.ActionBars[BarID], ACaption, Index);
end;
procedure TFormMain.ShowInBar(BarID: Integer; const path: TArray<TMenuPath>; Action: IAction; ActionIndex: Integer);
begin
  TActionBarHelper.ShowArr(ActionManager.ActionBars[BarID], path, Action, ActionIndex);
end;
procedure TFormMain.ShowInBar(BarID: Integer; const path: string; Action: IAction; Index: Integer = -1);
begin
  TActionBarHelper.Show(ActionManager.ActionBars[BarID], path, Action, Index);
end;
procedure TFormMain.HideInBar(BarID: Integer; Action: IAction);
begin
  TActionBarHelper.hide(ActionManager.ActionBars[BarID], Action);
end;
function TFormMain.HideUnusedMenus: boolean;
begin
  Result := False;
  while TActionBarHelper.HideUnusedMenus(ActionManager) do Result := True;
end;
procedure TFormMain.RegisterAction(Action: IAction);
begin
  TCustomAction(Action.GetComponent).ActionList := ActionManager;
end;
 // IScreen
procedure TFormMain.MainScreenChanged;
begin
  FMainScreenChange := True;
end;
procedure TFormMain.Lock;
begin
  LockWindowUpdate(Handle);
end;
procedure TFormMain.UnLock;
begin
  LockWindowUpdate(0);
end;
function TFormMain.GetStatusBar(index: Integer): string;
begin
 Result := sb.Panels[index].Text;
end;
function TFormMain.GetThemeName: string;
begin
  Result := StyleName;
end;

procedure TFormMain.SetStatusBar(index: Integer; const Value: string);
begin
  sb.Panels[index].Text := Value;
end;

procedure TFormMain.SetThemeName(const Value: string);
begin
  StyleName := Value;
end;

/// IProject
procedure TFormMain.IProjectInnerLoad(const PrjName: string; isNew: Boolean);
 var
  m: IManager;
  AfterCreateProject: Tproc;
begin
  AfterCreateProject := procedure
   var
    sa: TArray<IStorable>;
    s: IStorable;
  begin
    (GContainer as IProjectOptions).AddOrIgnore('CurrentScreen', 'Screen');

    if not VarIsNull((GContainer as IProjectOptions).Option['CurrentScreen']) then
       xini.AsString := (GContainer as IProjectOptions).Option['CurrentScreen'];

    // m.LoadScreen();                 //  загрузка текстов!!! обьектов - форм actions

    if not isNew then
     begin
      sa := GContainer.InstancesAsArray<IStorable>(true);
      TArray.Sort<IStorable>(sa, TManagItemComparer<IStorable>.Create);
      for s in sa do s.Load;
     end;
  end;
    //xini.Reload; // !!!
    BeginDockLoading;
    try
      if Supports(Plugins, IManager, m) then
       if isNew then m.NewProject(PrjName, AfterCreateProject)
       else m.LoadProject(PrjName, AfterCreateProject);
    finally
      try
        ResetActions(isNew);     // показывает все { TODO : проблемма с - и логикой действий}

        // create forms
      if not isNew then
       begin
        GContainer.InstancesAsArray<IForm>(True);

        LoadDockTreeFromAppStorage(xini, 'DockTree');
        LoadTabForms();

        try
         FormStorage.RestoreFormPlacement;
        except
         on E: Exception do TDebug.DoException(E);
        end;
       end
      else HideAllPopupPanel(nil);
        //FormPlacement.RestoreFormPlacement;
      finally
        EndDockLoading;
      end;
    end;
end;


function TFormMain.IProjectNew(out ProjectName: string): Boolean;
 var
  me: IManagerEx;
  m: IManager;
  s: string;
  wf: IForm;
  fd: IForm;
  CanClose: Boolean;
begin
  SaveScreeDialog;
  CanClose := not (ChildFormsBusy or DeviceBusy);
  if not CanClose then Exit(False);
  with TSaveDialog.Create(nil) do
  try
   if Supports(GContainer, IManagerEx, me) then
    begin
     DefaultExt := me.GetProjectDefaultExt;
     Filter :=  me.GetProjectFilter;
     InitialDir := me.GetProjectDirectory;
    end
   else
    begin
     DefaultExt := 'db';
     Filter := 'Файл проекта (*.db)|*.db';
     InitialDir := ExtractFilePath(ParamStr(0))+ '\Projects';
    end;
   Options := [ofOverwritePrompt,ofHideReadOnly,ofEnableSizing];
   if not Execute() then Exit(False);
   try
    IProjectInnerLoad(FileName, True);
    begin // создание форм по умолчанию
      TFormExceptions.DeInit;
      TFormExceptions.Init;
      DoFloatForm(TFormExceptions.This);
      wf := GContainer.CreateValuedInstance<string>('TFormControl', 'CreateUser', 'GlobalControlForm') as IForm;
//      fd := GContainer.CreateValuedInstance<string>('TFormFindDev', 'CreateUser', 'GlobalFormFindDev') as IForm;
//      if Assigned(fd) then
//       begin
//        (GContainer as IFormEnum).Add(fd);
//        DoFloatForm(TForm(fd.GetComponent));
////       (GContainer as ITabFormProvider).Dock(fd, 1);
//        ShowDockForm(TForm(fd.GetComponent));
//       end;//}
      if Assigned(wf) then
       begin
        (GContainer as IFormEnum).Add(wf);
        DoFloatForm(TForm(wf.GetComponent));
        (GContainer as ITabFormProvider).Dock(wf, 1);
        ShowDockForm(TForm(wf.GetComponent));
//        if Assigned(fd) then TForm(fd.GetComponent).ManualDock(TForm(wf.GetComponent), nil, alClient);
       end;//}
      ShowDockForm(TFormExceptions.This);
      (GContainer as ITabFormProvider).Dock(TFormExceptions.This as IForm, 3);
      FMainScreenChange := True;
    end;

   finally
     if Supports(GContainer, IManager, m) then
      begin
       s := m.ProjectName;
       rini.WriteString('CurrentProject', s);
       ProjectName := s;
       StatusBar[1] := s;
      end;
   end;
  finally
   Free;
  end;
end;

procedure TFormMain.InjectDependDevs;
 var
  de: IDeviceEnum;
  d: IDevice;
begin
  if Supports(GlobalCore, IDeviceEnum, de) then for d in de.Enum() do GContainer.InjectDependences(d.IName);
end;

procedure TFormMain.IProjectClose;
 var
  m: IManager;
  CanClose: Boolean;
begin
  SaveScreeDialog;
  CanClose := not (ChildFormsBusy or DeviceBusy);
  if not CanClose then Exit;
  BeginDockLoading;
  try
    (GlobalCore as IFormEnum).Clear;
    //xini.Reload; // !!!
    if Supports(Plugins, IManager, m) then m.LoadProject('');

    // create actions
    ResetActions(True);     // показывает все { TODO : проблемма с - и логикой действий}
    rini.WriteString('CurrentProject', '');
    StatusBar[1] := '';
  finally
    EndDockLoading;
  end;
end;

function TFormMain.IProjectLoad(out ProjectName: string): Boolean;
 var
  me: IManagerEx;
  s: string;
  CanClose: Boolean;
begin
  SaveScreeDialog;
  CanClose := not (ChildFormsBusy or DeviceBusy);
  if not CanClose then Exit(False);
  Result := True;
  with TOpenDialog.Create(nil) do
  try
   if Supports(GContainer, IManagerEx, me) then
    begin
     DefaultExt := me.GetProjectDefaultExt;
     Filter :=  me.GetProjectFilter;
     InitialDir := me.GetProjectDirectory;
    end
   else
    begin
     DefaultExt := 'db';
     Filter := 'Project file (*.db)|*.db';
     InitialDir := ExtractFilePath(ParamStr(0))+ '\Projects';
    end;
   Options := [ofReadOnly,ofHideReadOnly,ofPathMustExist,ofFileMustExist,ofEnableSizing];
   if not Execute() then Exit(False);
   IProjectInnerLoad(FileName, False);
   s := (GContainer as IManager).ProjectName;
   rini.WriteString('CurrentProject', s);
   ProjectName := s;
   StatusBar[1] := s;
  finally
   Free;
  end;
  InjectDependDevs;
  TActionBarHelper.VisibleContainedToIAction(ActionManager); // процедура бестолковая т.к. ResetActions делает видимыми все меню
                                                             // т.к. выключено сохранение IActions
//  TActionBarHelper.ShowHidenActions(ActionManager);  // процедура бестолковая
  UpdateWidthBars;
end;

function TFormMain.IProjectSetup: Boolean;
 var
  d: Idialog;
  dp: IDialog<Pointer>;
begin
  Result := (StatusBar[1] <> '') and RegisterDialog.TryGet<Dialog_SetupProject>(d) and Supports(d, IDialog<Pointer>, dp);
  if Result then dp.Execute(nil);
end;


{$ENDREGION  '*********** Providers ****************'}


{$REGION 'trach'}
//procedure TFormMain.SetProjectFile(const Value: WideString);
//begin
//  StatusBar[1] := Value;
//  sb.Panels[1].Text := FProjectFile;
//end;

{procedure TFormMain.SetupProjectExecute(Sender: TObject);
 var
  d: Idialog;
  dp: IDialog<Pointer>;
begin
  if StatusBar[1] = '' then Exit;
  if RegisterDialog.TryGet<Dialog_SetupProject>(d) then
   if Supports(d, IDialog<Pointer>, dp ) then dp.Execute(nil);
end;}

function TFormMain.ChildFormsBusy: boolean;
 var
  f: IForm;
  fe: IFormEnum;
  cc: INotifyCanClose;
  cclz: Boolean;
begin
  Result := False;
  if Supports(Plugins, IFormEnum, fe) then
   for f in fe do
    if Supports(f, INotifyCanClose, cc) then
     begin
      cclz := True;
      cc.CanClose(cclz);
      if not cclz then Exit(True);
     end;
end;

procedure TFormMain.clear_dock_zones;
 var
  i: integer;
   o: TJvDockVSNETTree;
  function DoPrune(Zone: TJvDockZone): boolean;
  begin
    Result := False;
    if Zone.NextSibling <> nil then
      if DoPrune(Zone.NextSibling) then ;//Zone.NextSibling := nil;
    if Zone.ChildZones <> nil then
      if DoPrune(Zone.ChildZones) then ;//Zone.ChildZones := nil;
    if Assigned(Zone.ChildControl) then
     begin
       Zone.ChildControl := nil;
     // Zone.Free;
      Result := True;
     end;
  end;
begin
//  JvDockServer.EnableDock := False;
//  JvDockServer.EnableDock := True;
  HideAllPopupPanel(nil);
  JvDockServer.DockStyle := nil;
  JvDockServer.DockStyle := JvDockVSNetStyle;
  Exit;
  for I := 0 to 4 do if Assigned(JvDockServer.DockPanel[TJvDockPosition(i)]) then
   begin
    SetDockSite(JvDockServer.DockPanel[TJvDockPosition(i)], False);
     SetDockSite(JvDockServer.DockPanel[TJvDockPosition(i)], False);

    SetDockSite(TJvDockVSNETPanel(JvDockServer.DockPanel[TJvDockPosition(i)]).VSChannel.VSPopupPanel, False);
    SetDockSite(TJvDockVSNETPanel(JvDockServer.DockPanel[TJvDockPosition(i)]).VSChannel.VSPopupPanel, True);
{     if (JvDockServer.DockPanel[TJvDockPosition(i)].jvDockManager is TJvDockVSNETTree) then
      begin
       o := JvDockServer.DockPanel[TJvDockPosition(i)].jvDockManager as TJvDockVSNETTree;
       MyTJvDockTree(o).PruneZone((JvDockServer.DockPanel[TJvDockPosition(i)].jvDockManager as TJvDockTree).TopZone);
      end;}
    //DoPrune((JvDockServer.DockPanel[TJvDockPosition(i)].jvDockManager as TJvDockTree).TopZone);
   // (JvDockServer.DockPanel[TJvDockPosition(i)].jvDockManager as TJvDockTree).TopZone.ResetChildren(nil);
  //  (JvDockServer.DockPanel[TJvDockPosition(i)].jvDockManager as TJvDockTree).TopZone := nil;
   end;
end;

procedure TFormMain.SaveScreeDialog;
begin
  {if FMainScreenChange and (MessageDlg('Сохранить экран ?', mtWarning, [mbYes, mbNo], 0) = mrYes) then} SaveScreenClick(nil);
end;

function TFormMain.DeviceBusy: boolean;
 var
  d: IDevice;
  de: IDeviceEnum;
begin
  Result := False;
  if Supports(Plugins, IDeviceEnum, de) then
   for d in de do
    if not (d.Status in [dsNoInit, dsPartReady, dsReady]) and not d.CanClose then
   begin
    MessageDlg(Format(RS_DevWork, [(d as ICaption).Text]),
               mtWarning, [mbOk], 0);
    Exit(True);
   end;
end;

procedure TFormMain.ITabFormProviderDock(const Form: IForm; Corner: Integer);
 var
//  Source: TJvDockDragDockObject;
  f: TForm;
begin
  f := TForm(Form.GetComponent);
  JvDockServer.DockPanel[TJvDockPosition(Corner)].Width := f.Width;
  F.ManualDock(JvDockServer.DockPanel[TJvDockPosition(Corner)] , nil, JvDockServer.DockPanel[TJvDockPosition(Corner)].Align);
  JvDockServer.DockPanel[TJvDockPosition(Corner)].ShowDockPanel(True, F);
end;


//procedure TFormMain.SowPrg(sho: Boolean);
//begin
//  ActionManager.FindItemByCaption('Проект').Visible := Sho;
//  ActionManager.FindItemByCaption('Новый проект...').Visible := Sho;
//  ActionManager.FindItemByCaption('Открыть проект...').Visible := Sho;
//  ActionManager.FindItemByCaption('Закрыть проект').Visible := Sho;
//  ActionManager.FindItemByCaption('Свойства проекта').Visible := Sho;
//  if not sho and (ProjectFile <> '') then PrjCloseExecute(nil);
//end;

procedure TFormMain.ActionExitExecute(Sender: TObject);
begin
  Close;
end;

procedure TFormMain.ActionPluginSetupExecute(Sender: TObject);
begin
  TFormPluginSetup.Execute(REG_PATH + '\'+ FCurrentScreen);
end;

procedure TFormMain.ActionExceptFormExecute(Sender: TObject);
begin
  ShowDockForm(TFormExceptions.This);
  SetActiveTab(TFormExceptions.This as IForm);
end;

procedure TFormMain.ActionUpdateExecute(Sender: TObject);
begin
  ActionManager.ResetActionBar(0);
  ActionManager.ResetActionBar(1);
  ActionManager.ResetActionBar(2);
  InjectDependDevs;
  TActionBarHelper.ShowHidenActions(ActionManager);
  UpdateWidthBars;
end;

procedure TFormMain.ApplicationEventsException(Sender: TObject; E: Exception);
const
  {$J+}
    IsShow: Boolean = False;
  {$J-}
begin
  if not TDebug.DoException(E) then
    if not IsShow then
   begin
    IsShow := True;
    Application.ShowException(e);
    IsShow := False;
   end;
end;

procedure TFormMain.ControlBarBandPaint(Sender: TObject; Control: TControl; Canvas: TCanvas; var ARect: TRect; var Options: TBandPaintOptions);
begin
  if ARect.Contains(MainMenu.BoundsRect) then Options := []
  else Options := [bpoGrabber];
end;

procedure TFormMain.CustomizeActionBarsCustomizeDlgClose(Sender: TObject);
begin
  UpdateWidthBars;
end;

function o2i(obj: Tobject): Integer;inline;
begin
  Result := Integer(Pointer(obj))
end;

procedure TFormMain.debug_log_dock;
 var
  lst:TList;
  i,j:integer;
  tz: TJvDockZone;
  procedure recurTZ(z: TJvDockZone; level: integer);
  begin
    if Assigned(z.ChildControl) then
     begin
      try
       Tdebug.Log('---[%x]tree[%x]zone: %d class: %s  control[%x]:%s, name "%s"',
       [o2i(z.tree), o2i(z), level, z.ClassName, o2i(z.ChildControl), z.ChildControl.ClassName, z.ChildControl.Name]);
      except
        Tdebug.Log('---[%x]tree[%x]zone: %d class: %s  control[%x]:%s, name "%s"',
        [o2i(z.tree), o2i(z), level, z.ClassName, o2i(z.ChildControl), 'z.ChildControl.ClassName ERROR', 'error_destroyed_control']);
      end;
      //z.ChildControl := nil;
     end
    else Tdebug.Log('---[%x]tree[%x]zone: %d class: %s',[o2i(z.tree), o2i(z), level, z.ClassName]);
    if Assigned(z.ChildZones) then  recurTZ(z.ChildZones, level+1);
    if Assigned(z.NextSibling) then  recurTZ(z.NextSibling, level+100);

  end;
begin
    lst:= TList.Create;
    if JvGlobalDockManager.DockServer[0] <> JvDockServer then Tdebug.Log('!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!JVSERVER|||||||||||||||||||||');

    for I := 0 to 4 do if Assigned(JvDockServer.DockPanel[TJvDockPosition(i)]) then
     begin
      Tdebug.Log('=================[%x] Panel:%d name "%s" class: "%s"',[Integer(Pointer(JvDockServer.DockPanel[TJvDockPosition(i)])), i,
              JvDockServer.DockPanel[TJvDockPosition(i)].Name,
              JvDockServer.DockPanel[TJvDockPosition(i)].ClassName]);

      if Assigned(JvDockServer.DockPanel[TJvDockPosition(i)].jvDockManager)
         and Assigned((JvDockServer.DockPanel[TJvDockPosition(i)].jvDockManager as TJvDockVSNETTree).TopZone) then
          recurTZ((JvDockServer.DockPanel[TJvDockPosition(i)].jvDockManager as TJvDockVSNETTree).TopZone, 0);
      if Assigned(TJvDockVSNETPanel(JvDockServer.DockPanel[TJvDockPosition(i)]).VSChannel.VSPopupPanel.JvDockManager) then
          recurTZ((TJvDockVSNETPanel(JvDockServer.DockPanel[TJvDockPosition(i)]).VSChannel.VSPopupPanel.JvDockManager as TJvDockVSNETTree).TopZone, 1000);



      JvDockServer.DockPanel[TJvDockPosition(i)].GetDockedControls(lst);
      for J := 0 to LST.Count-1 do
        Tdebug.Log('Panel:%d contr:%d class: %s',[i, j, TWinControl(lst[j]).ClassName]);
     end;
    lst.Free;
end;

//procedure TFormMain.ToolBarCanResize(Sender: TObject; var NewWidth, NewHeight: Integer; var Resize: Boolean);
//begin
 // if NewHeight > 24 then NewHeight := 24;
//end;

//procedure TFormMain.TimerTimer(Sender: TObject);
// var
//  tn: TTime;
//  Fts: Variant;
//  Ftd: Variant;
//  Ftw: Variant;
//  s: string;
//  ds: DelayStatus;
//  dm: IDelayManager;
//begin
{  if Supports(Plugins, IDelayManager, dm) then with dm do
   begin
    GetDelay(Fts,Ftd,Ftw, ds);
    case ds of
     dsNone: if FProjectFile = '' then
                  sb.Panels[0].Text := 'Нет открытого проекта'
             else sb.Panels[0].Text := 'Не поставлен на задержку';
     dsSetDelay:
      begin
        tn := Double(Ftd) - (Now - Double(Fts));
        if tn < 0 then
         begin
          s := 'время работы прибора ';
          tn := -tn;
          if not VarisNull(Ftw) and (tn > Double(Ftw)) then s := 'время после окончания работы прибора ';
         end
        else s := 'осталось времени до включения прибора ';
        sb.Panels[0].Text := s + MyTimeToStr(tn);
      end;
     dsEndDelay: sb.Panels[0].Text := 'Задержка остановлена';
    end;
   end;}
//end;

{$ENDREGION}

// *****************************************************************************
// **************         Тестовые функции          ****************************
// *****************************************************************************


//initialization
// ReportMemoryLeaksOnShutdown := True;
end.

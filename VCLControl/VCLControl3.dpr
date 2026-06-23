// JCL_DEBUG_EXPERT_DELETEMAPFILE OFF
// JCL_DEBUG_EXPERT_GENERATEJDBG OFF
{$IFDEF RELEASE}
// JCL_DEBUG_EXPERT_INSERTJDBG OFF
{$ELSE}
// JCL_DEBUG_EXPERT_INSERTJDBG ON
{$ENDIF}
library VCLControl3;

{$INCLUDE global.inc}

uses
  System.TypInfo,
  System.SysUtils,
  System.Classes,
  Winapi.ShellAPI,
  RootImpl,
  Actns,
  DeviceIntf,
  Vcl.Dialogs,
  DockIForm,
  AbstractPlugin,
  PluginAPI,
  ExtendIntf,
  Container,
  ControForm3 in 'ControForm3.pas' {FormControl},
  FormDlgDev in 'FormDlgDev.pas' {FormCreateDev},
  FormDelay2 in 'FormDelay2.pas' {DialogDelay},
  VCLDlgRam in 'VCLDlgRam.pas' {FormDlgRam},
  ConnectDeviceHelper in 'ConnectDeviceHelper.pas',
  DlgSetupDate in 'DlgSetupDate.pas' {FormCalendar},
  ExportToPSK6_V3 in 'ExportToPSK6_V3.pas' {FormExportToPSK6_V3},
  VCLDlgExportAcoustics in 'VCLDlgExportAcoustics.pas' {FormDlgExportAcoustics},
  VCLDlgClc in 'VCLDlgClc.pas' {FormDlgClc},
  VCLFrameRangeSelect in 'VCLFrameRangeSelect.pas' {FrameRangeSelect: TFrame},
  VCLDlgExportLAS in 'VCLDlgExportLAS.pas' {FormExportLASP3},
  FormDlgSetupProject in 'FormDlgSetupProject.pas' {FormSetupProject},
  FindDevices in 'FindDevices.pas' {FormFindDev},
  FrameFindDevs2 in 'FrameFindDevs2.pas' {FrameFindDev: TFrame},
  FrameDelayDev in 'FrameDelayDev.pas' {FrameDelayInfo: TFrame},
  SelectPath in 'SelectPath.pas' {SelectPathFrm: TFrame},
  VCLDlgExportCaliper in 'VCLDlgExportCaliper.pas' {FormDlgExportCaliper};

{$R *.res}

{$IFDEF ENG_VERSION}
  const
   C_Proj ='Project';
   C_file ='File';
   C_Desctop= 'Desktop';
   C_Show =  'Show';
   C_New_Proj ='New project...';
   C_Prop_Proj ='-Project properties...';
   C_Proj_Dir ='-Открыть папку проекта...';
   C_Open_Proj ='Open project...';
   C_exp= 'Export';

{$ELSE}
  const
   C_Proj ='Проект';
   C_file ='Файл';
   C_exp= 'Экспорт';
   C_Desctop= 'Рабочий стол';
   C_Show =  'Показать';
   C_New_Proj ='Новый проект...';
   C_Prop_Proj ='-Свойства проекта...';
   C_Proj_Dir ='-Открыть папку проекта...';
   C_Open_Proj ='Открыть проект...';
{$ENDIF}


type
 TVCLControl = class(TAbstractPlugin)
 private
//  class procedure InnerProject(const PrjName: string; isNew: Boolean);
 protected
   class function GetHInstance: THandle; override;
 public
   class function PluginName: string; override;
//    [StaticAction('Новая таблица', 'Окна визуализации', NICON, '0:Показать.Окна визуализации','',False,False,0,True, True)]
   [StaticAction(C_Proj, C_file, -1, '0:'+C_file+'|1:0','',False,False,0,True, True)]
    class procedure DoUpdate(Sender: IAction);
   [StaticAction(C_exp, C_file, -1, '0:'+C_file+'|1:1','',False,False,0,True, True)]
    class procedure DoUpdateExp(Sender: IAction);
   [StaticAction(C_Desctop, C_file, -1, '0:'+C_file,'',False,False,0,True, True)]
    class procedure DoUpdateWrk(Sender: IAction);
   [StaticAction(C_Show, '', -1, '0','',False,False,0,True, True)]
    class procedure DoUpdateShow(Sender: IAction);
  //Capt, Categ: string; AImageIndex: Integer; APaths: string; AHint: string; AAutoCheck AChecked AGroupIndex AEnabled
   [StaticAction(C_New_Proj, C_Proj, 16, '0:'+C_file+'.'+C_Proj+'|1:0')]
   class procedure DoNewProject(Sender: IAction);
   [StaticAction(C_Prop_Proj, C_Proj, 238, '0:'+C_file+'.'+C_Proj+'|1:4')]
   class procedure DoZPropertyProject(Sender: IAction);
   [StaticAction(C_Proj_Dir, C_Proj, 239, '0:'+C_file+'.'+C_Proj+'|1:5')]
   class procedure DoProjectDir(Sender: IAction);
   [StaticAction(C_Open_Proj, C_Proj, 329, '0:'+C_file+'.'+C_Proj+'|1:1')]
   class procedure DoOpenProject(Sender: IAction);
//   [StaticAction('-Закрыть проект', 'Проект', 226, '0:Файл.Проект|1:2')]
   class procedure DoSloseProject(Sender: IAction);
 end;

function Init(): PTypeInfo;
begin
//  FFDGUIxSilentMode  := True;
  TRegister.AddType<TVCLControl, IPlugin>.LiveTime(ltSingleton);
  Result := TypeInfo(TVCLControl);
end;

procedure Done;
begin
  GContainer.RemoveModel<TVCLControl>;
//  FDTerminate;
end;

exports
  Init name SPluginInitFuncName,
  Done name SPluginDoneFuncName;

class function TVCLControl.PluginName: string;
begin
  Result := 'Управление проектом 3';
end;

class function TVCLControl.GetHInstance: THandle;
begin
  Result := HInstance;
end;

class procedure TVCLControl.DoNewProject(Sender: IAction);
 var
  s: string;
begin
  (GContainer as IProject).New(s);
end;

class procedure TVCLControl.DoOpenProject(Sender: IAction);
 var
  s: string;
begin
  (GContainer as IProject).Load(s);
end;

class procedure TVCLControl.DoProjectDir(Sender: IAction);
 var
  m: IManager;
begin
  if Supports(GContainer, IManager, m) and (m.ProjectName <> '') then
   begin
    ShellExecute(0, 'open', Pchar(ExtractFilePath(m.ProjectName)), nil, nil, 1);
   end;
end;

class procedure TVCLControl.DoSloseProject(Sender: IAction);
begin
  (GContainer as IProject).Close;
end;

class procedure TVCLControl.DoUpdate(Sender: IAction);
begin
  Sender.Visible := Supports(GContainer, IManager);
end;

class procedure TVCLControl.DoUpdateExp(Sender: IAction);
 var
  m: IManager;
begin
  Sender.Visible := Supports(GContainer, IManager, m) and (m.ProjectName <> '');
end;

class procedure TVCLControl.DoUpdateShow(Sender: IAction);
 var
  m: IManager;
  v: Boolean;
  a: IAction;
begin
  v := Supports(GContainer, IManager, m) and (m.ProjectName <> '');
  a := (GlobalCore as IActionEnum).Get('TFormControl_DoCreateForm', False);
  a.Visible := v;
  a := (GlobalCore as IActionEnum).Get('TFormWrok_DoCreateForm', False);
  a.Visible := v;
end;

class procedure TVCLControl.DoUpdateWrk(Sender: IAction);
 var
  m: IManager;
begin
  Sender.Visible := Supports(GContainer, IManager, m) and (m.ProjectName <> '');
end;

class procedure TVCLControl.DoZPropertyProject(Sender: IAction);
begin
  (GContainer as IProject).Setup;
end;

begin
end.

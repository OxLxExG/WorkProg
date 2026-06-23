// JCL_DEBUG_EXPERT_DELETEMAPFILE OFF
// JCL_DEBUG_EXPERT_GENERATEJDBG OFF
{$IFDEF RELEASE}
// JCL_DEBUG_EXPERT_INSERTJDBG ON
{$ELSE}
// JCL_DEBUG_EXPERT_INSERTJDBG ON
{$ENDIF}
library CreatePSK;

uses
  System.SysUtils,
  PluginAPI,
  DockIForm,
  ExtendIntf,
  AbstractPlugin,
  System.Classes,
  PskCreateForm in 'PskCreateForm.pas' {FormPsk},
  MetrCreateForm in 'MetrCreateForm.pas' {FormMetr},
  OptionsProject in 'OptionsProject.pas' {Form2};

{$R *.res}

type
 TPlugin = class(TAbstractPlugin, INotifyAfteActionManagerLoad)
 protected
   FPskMenu, FMetrMenu: TStaticMenu;
   procedure LoadNotify; override; safecall;
   procedure DestroyNotify; override; safecall;
   procedure AfteActionManagerLoad(); safecall;
 end;

function Init(const ACore: ICore): IPlugin; safecall;
begin
  Result := TPlugin.Create(HInstance, ACore, 'Редактор приборов ПСК и метрологии', PLUGIN_CreatePSK);
end;

exports
  Init name SPluginInitFuncName;

{ TPlugin }

procedure TPlugin.LoadNotify;
begin
  FPskMenu := TStaticMenu.InitMenu('Новый Редактор приборов ПСК', 'Отладочные', TFormPSK);
  FMetrMenu := TStaticMenu.InitMenu('Редактор метрологии приборов', 'Отладочные', TFormMetr);
end;

procedure TPlugin.AfteActionManagerLoad;
begin
  FPskMenu.ShowInMainMenu('Показать.Отладочные');
  FMetrMenu.ShowInMainMenu('Показать.Отладочные')
end;

procedure TPlugin.DestroyNotify;
begin
  FPskMenu.Free;
  FMetrMenu.Free;
end;

begin
end.

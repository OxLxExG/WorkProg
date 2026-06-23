// JCL_DEBUG_EXPERT_DELETEMAPFILE OFF
// JCL_DEBUG_EXPERT_GENERATEJDBG OFF
{$IFDEF RELEASE}
// JCL_DEBUG_EXPERT_INSERTJDBG OFF
{$ELSE}
// JCL_DEBUG_EXPERT_INSERTJDBG ON
{$ENDIF}
library bootLoader;

uses
  System.SysUtils,
  System.TypInfo,
  PluginAPI,
  AbstractPlugin,
  Container,
  System.Classes,
  BootForm in 'BootForm.pas' {FormBoot},
  DlgSetupForm in 'DlgSetupForm.pas' {DlgSetupAdr},
  TestRAMForm in 'TestRAMForm.pas' {FormRamTest},
  VCL.Dlg.Error in 'VCL.Dlg.Error.pas' {FormError};

{$R *.res}

type
 TBootLoader = class(TAbstractPlugin)
 protected
   class function GetHInstance: THandle; override;
 public
   class function PluginName: string; override;
 end;

function Init(): PTypeInfo;
begin
  TRegister.AddType<TBootLoader, IPlugin>.LiveTime(ltSingleton);
  Result := TypeInfo(TBootLoader);
end;

procedure Done;
begin
  GContainer.RemoveModel<TBootLoader>;
end;

exports
  Init name SPluginInitFuncName,
  Done name SPluginDoneFuncName;

class function TBootLoader.PluginName: string;
begin
  Result := 'Загрузчик';
end;

class function TBootLoader.GetHInstance: THandle;
begin
  Result := HInstance;
end;


begin
end.

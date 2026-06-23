// JCL_DEBUG_EXPERT_DELETEMAPFILE OFF
// JCL_DEBUG_EXPERT_GENERATEJDBG OFF
{$IFDEF RELEASE}
// JCL_DEBUG_EXPERT_INSERTJDBG OFF
{$ELSE}
// JCL_DEBUG_EXPERT_INSERTJDBG ON
{$ENDIF}
library Monitor;

uses
  System.TypInfo,
  System.SysUtils,
  PluginAPI,
  DockIForm,
  Container,
  ExtendIntf,
  AbstractPlugin,
  System.Classes,
  IOForm in 'IOForm.pas' {FormIO};

{$R *.res}

type
 TDebugMonitorIO = class(TAbstractPlugin)
 protected
   class function GetHInstance: THandle; override;
 public
   class function PluginName: string; override;
 end;


function Init(): PTypeInfo;
begin
  TRegister.AddType<TDebugMonitorIO, IPlugin>.LiveTime(ltSingleton);
  Result := TypeInfo(TDebugMonitorIO);
end;

procedure Done;
begin
  GContainer.RemoveModel<TDebugMonitorIO>;
end;

exports
  Init name SPluginInitFuncName,
  Done name SPluginDoneFuncName;

class function TDebugMonitorIO.PluginName: string;
begin
  Result := 'Монитор ввода-вывода';
end;

class function TDebugMonitorIO.GetHInstance: THandle;
begin
  Result := HInstance;
end;

begin
end.

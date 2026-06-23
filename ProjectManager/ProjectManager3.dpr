// JCL_DEBUG_EXPERT_DELETEMAPFILE OFF
// JCL_DEBUG_EXPERT_GENERATEJDBG OFF
{$IFDEF RELEASE}
// JCL_DEBUG_EXPERT_INSERTJDBG ON
{$ELSE}
// JCL_DEBUG_EXPERT_INSERTJDBG OFF
{$ENDIF}
library ProjectManager3;

uses
  System.SysUtils,
  System.TypInfo,
  PluginAPI,
  DockIForm,
  Container,
  ExtendIntf,
  AbstractPlugin,
  System.Classes,
  manager3 in 'manager3.pas',
  XMLEnumers in 'XMLEnumers.pas';

{$R *.res}

function Init(): PTypeInfo;
begin
  Result := TypeInfo(TManager);
  TRegister.AddType<TManager, IPlugin, IManager, IManagerEx, IProjectDataFile, IProjectMetaData,
  IMetrology, IProjectOptions, IALLMetaDataFactory, IGlobalMemory>.LiveTime(ltSingleton);
  TManager.ProjectDir;
end;

procedure Done;
begin
  GContainer.RemoveModel<TManager>;
end;

exports
  Init name SPluginInitFuncName,
  Done name SPluginDoneFuncName;

begin
end.

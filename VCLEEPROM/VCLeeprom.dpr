// JCL_DEBUG_EXPERT_DELETEMAPFILE OFF
// JCL_DEBUG_EXPERT_GENERATEJDBG OFF
{$IFDEF RELEASE}
// JCL_DEBUG_EXPERT_INSERTJDBG OFF
{$ELSE}
// JCL_DEBUG_EXPERT_INSERTJDBG ON
{$ENDIF}
library VCLeeprom;

uses
  System.SysUtils,
  System.TypInfo,
  PluginAPI,
  AbstractPlugin,
  Container,
  System.Classes,
  VCL.Form.EEPROM in 'VCL.Form.EEPROM.pas' {FormDlgEeprom};

{$R *.res}

type
 Teeprom = class(TAbstractPlugin)
 protected
   class function GetHInstance: THandle; override;
 public
   class function PluginName: string; override;
 end;

function Init(): PTypeInfo;
begin
  TRegister.AddType<Teeprom, IPlugin>.LiveTime(ltSingleton);
  Result := TypeInfo(Teeprom);
end;

procedure Done;
begin
  GContainer.RemoveModel<Teeprom>;
end;

exports
  Init name SPluginInitFuncName,
  Done name SPluginDoneFuncName;

class function Teeprom.PluginName: string;
begin
  Result := 'Редактор EEPROM';
end;

class function Teeprom.GetHInstance: THandle;
begin
  Result := HInstance;
end;

begin
end.

// JCL_DEBUG_EXPERT_DELETEMAPFILE OFF
// JCL_DEBUG_EXPERT_GENERATEJDBG OFF
{$IFDEF RELEASE}
// JCL_DEBUG_EXPERT_INSERTJDBG OFF
{$ELSE}
// JCL_DEBUG_EXPERT_INSERTJDBG ON
{$ENDIF}
library VCLData;

uses
  System.TypInfo,
  System.SysUtils,
  System.Classes,
  RootImpl,
  tools,
  Xml.XMLIntf,
  DeviceIntf,
  DockIForm,
  AbstractPlugin,
  PluginAPI,
  ExtendIntf,
  Container,
  FormWork in 'FormWork.pas' {FormWrok},
  AbstractDlgParams in 'AbstractDlgParams.pas' {FormParamsAbstract},
  DlgFltParam in 'DlgFltParam.pas',
  DlgViewParam in 'DlgViewParam.pas',
  DialogOpenLas in 'DialogOpenLas.pas' {DlgOpenLAS},
  VCLFormShowArray in 'VCLFormShowArray.pas' {FormShowArray},
  VCL.CustomDataForm in 'VCL.CustomDataForm.pas',
  VCLTableDataForm in 'VCLTableDataForm.pas' {TableDataForm},
  DlgEditParam in 'DlgEditParam.pas' {FormEditParam},
  VCLFormShowArrayTable in 'VCLFormShowArrayTable.pas' {FormTableGraph},
  VCLGraphCartForm in 'VCLGraphCartForm.pas' {GraphCartForm},
  VCLGraphDataForm in 'VCLGraphDataForm.pas' {GraphDataForm};

{$R *.res}

type
 TVCLData = class(TAbstractPlugin)
 protected
   class function GetHInstance: THandle; override;
 public
   class function PluginName: string; override;
 end;

function Init(): PTypeInfo;
begin
  TRegister.AddType<TVCLData, IPlugin>.LiveTime(ltSingleton);
  Result := TypeInfo(TVCLData);
end;

procedure Done;
begin
  GContainer.RemoveModel<TVCLData>;
end;

exports
  Init name SPluginInitFuncName,
  Done name SPluginDoneFuncName;

class function TVCLData.PluginName: string;
begin
  Result := 'Основные формы';
end;

class function TVCLData.GetHInstance: THandle;
begin
  Result := HInstance;
end;

begin
end.

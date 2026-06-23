// JCL_DEBUG_EXPERT_DELETEMAPFILE OFF
// JCL_DEBUG_EXPERT_GENERATEJDBG OFF
{$IFDEF RELEASE}
// JCL_DEBUG_EXPERT_INSERTJDBG OFF
{$ELSE}
// JCL_DEBUG_EXPERT_INSERTJDBG ON
{$ENDIF}
library VCLDialogs;

uses
  System.SysUtils,
  System.TypInfo,
  PluginAPI,
  AbstractPlugin,
  Container,
  System.Classes,
  VCLDlgConnectIO in 'VCLDlgConnectIO.pas' {FormSetupConnect},
  VCLDlgConnectIOCOM in 'VCLDlgConnectIOCOM.pas' {FormSetupCom},
  InitDialogs in 'InitDialogs.pas',
  VCLDlgConnectIONET in 'VCLDlgConnectIONET.pas' {FormSetupNet},
  VCLDlgConnectIOWLAN in 'VCLDlgConnectIOWLAN.pas' {FormSetupWlan},
  VCLDlgDevice in 'VCLDlgDevice.pas' {DlgSetupDev},
  VCLDlgRootDevice in 'VCLDlgRootDevice.pas' {FormSetupRootDevice},
  VCLDlgOptionSetup in 'VCLDlgOptionSetup.pas' {FormOptionSetup},
  VCLDlgOpenLas in 'VCLDlgOpenLas.pas' {DlgOpenLASDataSet},
  VCLFrameSelectParam in 'VCLFrameSelectParam.pas' {FrameSelectParam: TFrame},
  VCLDlgOpenP3XML in 'VCLDlgOpenP3XML.pas' {DlgOpenP3DataSet},
  VCLFrameSelectPath in 'VCLFrameSelectPath.pas' {FrameSelectPath: TFrame},
  VCLFrameTGamma in 'VCLFrameTGamma.pas' {FrameGamma: TFrame},
  VCL.JDType.Form in 'VCL.JDType.Form.pas',
  VCLJDTypeTGamma in 'VCLJDTypeTGamma.pas' {JDTypeFormGamma},
  VCLJDtypeClolor in 'VCLJDtypeClolor.pas' {FormSetColor},
  VCLJDtypeAlphaClolor in 'VCLJDtypeAlphaClolor.pas' {FormSetAlphaColor},
  VCL.Dlg.SelectProfile in 'VCL.Dlg.SelectProfile.pas' {DialogSelectProfile},
  VCLDlgLoggDevice in 'VCLDlgLoggDevice.pas' {FormLogg};

{$R *.res}

type
 TVCLDialogs = class(TAbstractPlugin)
 protected
   class function GetHInstance: THandle; override;
 public
   class function PluginName: string; override;
 end;

function Init(): PTypeInfo;
begin
  TRegister.AddType<TVCLDialogs, IPlugin>.LiveTime(ltSingleton);
  Result := TypeInfo(TVCLDialogs);
end;

procedure Done;
begin
  GContainer.RemoveModel<TVCLDialogs>;
end;

exports
  Init name SPluginInitFuncName,
  Done name SPluginDoneFuncName;

class function TVCLDialogs.PluginName: string;
begin
  Result := 'Диалоги';
end;

class function TVCLDialogs.GetHInstance: THandle;
begin
  Result := HInstance;
end;

begin
end.

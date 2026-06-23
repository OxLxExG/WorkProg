// JCL_DEBUG_EXPERT_DELETEMAPFILE OFF
// JCL_DEBUG_EXPERT_GENERATEJDBG OFF
{$IFDEF RELEASE}
// JCL_DEBUG_EXPERT_INSERTJDBG OFF
{$ELSE}
// JCL_DEBUG_EXPERT_INSERTJDBG ON
{$ENDIF}
library Metrol;

{$R 'SndMetrol.res' 'SndMetrol.rc'}

uses
  SysUtils,
  System.TypInfo,
  PluginAPI,
  AbstractPlugin,
  Container,
  System.Classes,
  MetrInclin in 'MetrInclin.pas' {FormInclin},
  MetrForm in 'MetrForm.pas',
  MetrInclinSetup in 'MetrInclinSetup.pas' {FormInclSetup},
  MetrGGKP in 'MetrGGKP.pas' {FormGGKP},
  MetrUAKI in 'MetrUAKI.pas' {FormUAKI},
  UakiUI in 'UakiUI.pas' {FrameUakiUI: TFrame},
  AutoMetr.Inclin in 'AutoMetr.Inclin.pas',
  MetrInclinGraph in 'MetrInclinGraph.pas',
  FrameInclinGraph in 'FrameInclinGraph.pas' {FrmInclinGraph: TFrame},
  LuaInclin.Math in 'LuaInclin.Math.pas',
  MetrUAKI.ToleranceForm in 'MetrUAKI.ToleranceForm.pas' {FormUAKItolerance},
  MetrAccel.CheckForm in 'MetrAccel.CheckForm.pas' {FormAccelCheck},
  MetrInclin.TrrAndP2 in 'MetrInclin.TrrAndP2.pas',
  MetrInclin.TrrAndP4 in 'MetrInclin.TrrAndP4.pas',
  AutoMetr.GK in 'AutoMetr.GK.pas',
  StolGKUI in 'StolGKUI.pas' {FormStolGK},
  UakiUI.Ten in 'UakiUI.Ten.pas' {FrameUakiTEN: TFrame},
  MetrInclin.T12 in 'MetrInclin.T12.pas',
  MetrInclin.Math2 in 'MetrInclin.Math2.pas',
  MetrInclin.TrrAndP3 in 'MetrInclin.TrrAndP3.pas',
  MetrAGK in 'MetrAGK.pas' {FormAGK},
  MetrInclin4.Temp.Form in 'MetrInclin4.Temp.Form.pas' {FormMetrInclin4T},
  MetrInclin.CheckForm in 'MetrInclin.CheckForm.pas' {FormInclinCheck},
  MetrGK in 'MetrGK.pas' {FormGK},
  MetrInd in 'MetrInd.pas' {FormInd},
  MetrNNK2X in 'MetrNNK2X.pas' {FormNNK2X},
  MetrNNK128 in 'MetrNNK128.pas' {FormNNK128},
  MetrBKS in 'MetrBKS.pas' {FormBKS},
  MetrInclin.Temp.FormPoly in 'MetrInclin.Temp.FormPoly.pas' {FormMetrInclinTP},
  PID in 'PID.pas',
  Metr.UAKI.Ten.PID in 'Metr.UAKI.Ten.PID.pas' {FormPIDsetup},
  MetrRes in 'MetrRes.pas' {FormRes},
  MetrNNK in 'MetrNNK.pas' {FormNNK},
  MetrBKZ3 in 'MetrBKZ3.pas' {FormBKZ3},
  AutoMetr.Inclin.ChekH in 'AutoMetr.Inclin.ChekH.pas',
  MetrInclin.Temp.MathPoly in 'MetrInclin.Temp.MathPoly.pas',
  MetrInclin.Temp.DialogPoly in 'MetrInclin.Temp.DialogPoly.pas' {DialogPoly},
  LuaInclin.Temp.Poly in 'LuaInclin.Temp.Poly.pas',
  MetrInclin.Temp.Form in 'MetrInclin.Temp.Form.pas' {FormMetrInclinT},
  MetrInclin.Temp.Stat in 'MetrInclin.Temp.Stat.pas',
  PatchCart in 'PatchCart.pas';

{$R *.res}

//type
// TPlugin = class(TAbstractPlugin, INotifyAfteActionManagerLoad)
// protected
//   FormTreeIncl: TStaticMenu;
//   FormGk: TStaticMenu;
//   FormNGk: TStaticMenu;
//   FormNNk: TStaticMenu;
//   procedure LoadNotify; override;
//   procedure DestroyNotify; override;
//   procedure AfteActionManagerLoad(); safecall;
// end;
//
//function Init(const ACore: ICore): IPlugin; safecall;
// const
//  GMT: TGUID ='{B2DB1392-6B4E-4906-ACC8-2F2B80D4D11C}';
//begin
//  Result := TPlugin.Create(HInstance, ACore, 'Метрология', GMT);
//end;
//
//exports
//  Init name SPluginInitFuncName;
//
//{ TPlugin }
//
//procedure TPlugin.LoadNotify;
//begin
//  FormTreeIncl := TStaticMenu.InitMenu('Новая калибровка Т21', 'Инклинометры', TFormInclin);
//  FormGk := TStaticMenu.InitMenu('Новая калибровка ГК', 'ГК', TFormGK);
//  FormNGk := TStaticMenu.InitMenu('Новая калибровка НГК', 'ННК', TFormNGK);
//  FormNNk := TStaticMenu.InitMenu('Новая калибровка ННК', 'ННК', TFormNNK);
//end;
//
//procedure TPlugin.AfteActionManagerLoad;
//begin
//  FormTreeIncl.ShowInMainMenu('Метрология.Инклинометры');
//  FormGk.ShowInMainMenu('Метрология.ГК');
//  FormNGk.ShowInMainMenu('Метрология.ННК');
//  FormNNk.ShowInMainMenu('Метрология.ННК');
//end;
//
//procedure TPlugin.DestroyNotify;
//begin
//  FormTreeIncl.Free;
//  FormGk.Free;
//  FormNGk.Free;
//  FormNNk.Free;
//end;

type
 TMetrology = class(TAbstractPlugin)
 protected
   class function GetHInstance: THandle; override;
 public
   class function PluginName: string; override;
 end;

function Init(): PTypeInfo;
begin
  TRegister.AddType<TMetrology, IPlugin>.LiveTime(ltSingleton);
  Result := TypeInfo(TMetrology);
end;

procedure Done;
begin
  GContainer.RemoveModel<TMetrology>;
end;

exports
  Init name SPluginInitFuncName,
  Done name SPluginDoneFuncName;

class function TMetrology.PluginName: string;
begin
  Result := 'Метрология';
end;

class function TMetrology.GetHInstance: THandle;
begin
  Result := HInstance;
end;

begin
end.

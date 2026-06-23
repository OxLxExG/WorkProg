// JCL_DEBUG_EXPERT_DELETEMAPFILE OFF
// JCL_DEBUG_EXPERT_GENERATEJDBG OFF
{$IFDEF RELEASE}
// JCL_DEBUG_EXPERT_INSERTJDBG OFF
{$ELSE}
// JCL_DEBUG_EXPERT_INSERTJDBG ON
{$ENDIF}
program WorkProg;

uses
  SysUtils,
  Container,
  RootImpl,
  Vcl.Forms,
  MainForm in 'MainForm.pas' {FormMain},
  PluginSetupForm in 'PluginSetupForm.pas' {FormPluginSetup},
  ExceptionForm in 'ExceptionForm.pas' {FormExceptions},
  ActionBarHelper in 'ActionBarHelper.pas',
  FirstForm in 'FirstForm.pas' {FormSplash},
  PluginManager in 'PluginManager.pas',
  Vcl.Themes,
  Vcl.Styles;

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  TStyleManager.TrySetStyle('Windows11 Polar Dark');
  Application.CreateForm(TFormMain, FormMain);
  //  {$IFDEF DEBUG}
//  Application.CreateForm(TFormSplash, FormSplash);
//  FormSplash.Show;
//{$ENDIF}
  Application.Run;
end.

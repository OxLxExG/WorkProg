unit VCLDlgConnectIOWLAN;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls, Vcl.ComCtrls, VCLDlgConnectIONET;

type
  TFormSetupWlan = class(TFormSetupNet)
    Label4: TLabel;
    edSSID: TEdit;
  private
   // 'AMKGorizontWiFiUSO'
  public
    procedure ApplyInfo(const inf: string); override;
    function CreateConnectInfo: string; override;
  end;

implementation

{$R *.dfm}

procedure TFormSetupWlan.ApplyInfo(const inf: string);
 var
  a: TArray<string>;
begin
  a := inf.Split([' '], TStringSplitOptions.ExcludeEmpty);
  if Length(a) = 0 then Exit;
  if a[0] <> '' then edSSID.Text := a[0];
  if Length(a) >= 2 then inherited ApplyInfo(a[1])
end;

function TFormSetupWlan.CreateConnectInfo: string;
begin
  Result := Format('%s %s:%s', [edSSID.Text, edHost.Text, edPort.Text]);
end;

end.

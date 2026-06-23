unit VCLDlgConnectIOCOM;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, VCLDlgConnectIO, Vcl.StdCtrls, Vcl.ComCtrls, CPortCtl;

type
  TFormSetupCom = class(TFormSetupConnect)
    Label1: TLabel;
    cbCom: TComComboBox;
    cb9600: TCheckBox;
    cb256k: TCheckBox;
    procedure FormShow(Sender: TObject);
  public
    params: TArray<string>;
    function CreateConnectInfo: string; override;
  end;

implementation

{$R *.dfm}

function TFormSetupCom.CreateConnectInfo: string;
begin
  if cb9600.Checked then
   begin
    SetLength(params, 2);
    params[1] := '9600';
   end
  else if cb256k.Checked then
   begin
    SetLength(params, 2);
    params[1] := '256000';
   end
  else SetLength(params, 1);

  params[0] := cbCom.Text.Trim;
  Result := string.join(';',params);
end;

procedure TFormSetupCom.FormShow(Sender: TObject);
begin
  params := Item.ConnectInfo.Split([';']);
  cbCom.Text := params[0].Trim;
  cb9600.Checked := (Length(params) = 2) and (params[1] = '9600');
  inherited;
end;

end.

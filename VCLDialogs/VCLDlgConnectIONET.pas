unit VCLDlgConnectIONET;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, VCLDlgConnectIO, Vcl.StdCtrls, Vcl.ComCtrls;

type
  TFormSetupNet = class(TFormSetupConnect)
    Label1: TLabel;
    edHost: TEdit;
    Label3: TLabel;
    edPort: TEdit;
    procedure FormShow(Sender: TObject);
  private
    { Private declarations }
  public
    procedure ApplyInfo(const inf: string);virtual;
    function CreateConnectInfo: string; override;
  end;

implementation

{$R *.dfm}

procedure TFormSetupNet.ApplyInfo(const inf: string);
 var
  a: TArray<string>;
begin
  a := inf.Split([':']);
  if Length(a)=0 then Exit;
  if a[0]<> '' then edHost.Text := a[0];
  if Length(a) >= 2 then edPort.Text := a[1];
end;

function TFormSetupNet.CreateConnectInfo: string;
begin
  Result := Format('%s:%s', [edHost.Text, edPort.Text]);
end;

procedure TFormSetupNet.FormShow(Sender: TObject);
begin
  ApplyInfo(Item.ConnectInfo);
  inherited;
end;

end.

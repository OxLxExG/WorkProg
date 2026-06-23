unit VCL.Dlg.ConnectIO.Comm;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, VCL.Dlg.ConnectIO, Vcl.StdCtrls, Vcl.ComCtrls, CPortCtl;

type
  TFormSetupCom = class(TFormSetupConnect)
    Label1: TLabel;
    cbCom: TComComboBox;
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  FormSetupCom: TFormSetupCom;

implementation

{$R *.dfm}

end.

unit MetrInclinSetup;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls;

type
  TFormInclSetup = class(TForm)
    btOk: TButton;
    btCansel: TButton;
    edData: TEdit;
    Label1: TLabel;
    Label2: TLabel;
    edD: TEdit;
    Label3: TLabel;
    edNN: TEdit;
    Label4: TLabel;
    edAver: TEdit;
  public
    class function Execute(var fmtData, fmtDiag, fmtDz, fmtaver: string): Boolean;
  end;

implementation

{$R *.dfm}

{ TFormInclSetup }

class function TFormInclSetup.Execute(var fmtData, fmtDiag, fmtDz, fmtaver: string): Boolean;
begin
  with TFormInclSetup.Create(nil) do
   try
    edData.Text := fmtData;
    edNN.Text := fmtDiag;
    edD.Text := fmtDz;
    edAver.Text := fmtaver;
    Result := ShowModal = mrOk;
    if Result then
     begin
      fmtData := edData.Text;
      fmtDiag := edNN.Text;
      fmtDz := edD.Text;
      fmtaver := edAver.Text;
     end;
   finally
    Free;
   end;
end;

end.

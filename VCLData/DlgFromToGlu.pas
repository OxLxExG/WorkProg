unit DlgFromToGlu;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls, Vcl.Mask;

type
  TFormDlgGluFilter = class(TForm)
    medFrom: TMaskEdit;
    medTo: TMaskEdit;
    lbWork: TLabel;
    Label1: TLabel;
    btApply: TButton;
    btClose: TButton;
    procedure btApplyClick(Sender: TObject);
  private
    FMemQ: IMemQuery;
  public
    class procedure Execute(MemQ: IMemQuery);
  end;

var
  FormDlgGluFilter: TFormDlgGluFilter;

implementation

{$R *.dfm}

procedure TFormDlgGluFilter.btApplyClick(Sender: TObject);
 var
  f,t: Integer;
begin
  f := string(medFrom.Text).ToInteger;
  t := string(medTo.Text).ToInteger;
  if f < t then
   begin
    FMemQ.FromData := f;
    FMemQ.ToData := t;
    FMemQ.Update;
   end;
end;

class procedure TFormDlgGluFilter.Execute(MemQ: IMemQuery);
begin
  with TFormDlgGluFilter.Create(nil) do
   try
    FMemQ := MemQ;
    ShowModal();
   finally
    Free;
   end;
end;

end.

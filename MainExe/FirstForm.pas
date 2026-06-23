unit FirstForm;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls, Container;

type
  TFormSplash = class(TForm)
    Memo: TMemo;
    Button: TButton;
    procedure ButtonClick(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  FormSplash: TFormSplash;

implementation

{$R *.dfm}

procedure TFormSplash.ButtonClick(Sender: TObject);
begin
  Memo.Lines.BeginUpdate;
  try
   GContainer.UpdateDebugData(Memo.Lines);
  finally
   Memo.Lines.EndUpdate;
  end;
end;

end.

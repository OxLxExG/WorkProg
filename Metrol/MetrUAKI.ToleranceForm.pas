unit MetrUAKI.ToleranceForm;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls, UakiIntf;

type
  TFormUAKItolerance = class(TForm)
    edTole: TEdit;
    btGet: TButton;
    btSet: TButton;
    btExit: TButton;
    procedure btGetClick(Sender: TObject);
    procedure btSetClick(Sender: TObject);
  private
    { Private declarations }
  public
    Axis: IAxis;
    class procedure Execute(a: IAxis);
  end;

var
  FormUAKItolerance: TFormUAKItolerance;

implementation

{$R *.dfm}

procedure TFormUAKItolerance.btGetClick(Sender: TObject);
begin
  edTole.Text := Axis.TOlerance.ToString;
end;

procedure TFormUAKItolerance.btSetClick(Sender: TObject);
begin
  Axis.TOlerance := StrToFloat(edTole.Text);
end;

class procedure TFormUAKItolerance.Execute(a: IAxis);
begin
  with Create(nil) do
   try
    Axis := a;
    a.GetTOlerance();
    case a.Adr of
     ADR_AXIS_AZI: Caption := 'Установка точности Азимута';
     ADR_AXIS_ZU:  Caption := 'Установка точности Зенита';
     ADR_AXIS_VIZ: Caption := 'Установка точности Отклонителя';
    end;
    edTole.Text := a.TOlerance.ToString;
    ShowModal();
   finally
    Free;
   end;
end;

end.

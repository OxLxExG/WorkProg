unit ExportLas;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, AbstractDlgParams, Vcl.StdCtrls, Vcl.Menus, Vcl.PlatformDefaultStyleActnCtrls,
  Vcl.ActnPopup, VirtualTrees;

type
  TFormParamsAbstract3 = class(TFormParamsAbstract)
    Label1: TLabel;
    Label2: TLabel;
    Edit1: TEdit;
    Edit2: TEdit;
    procedure btApplyClick(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  FormParamsAbstract3: TFormParamsAbstract3;

implementation

{$R *.dfm}

procedure TFormParamsAbstract3.btApplyClick(Sender: TObject);
begin
  inherited;
//
end;

end.

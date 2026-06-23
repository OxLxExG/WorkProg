unit VCLDlgDevice;

interface

uses DeviceIntf, RootImpl, RootIntf, ExtendIntf,
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls;

type
  TDlgSetupDev = class(TForm)
    btApply: TButton;
    Button1: TButton;
    ButtonOK: TButton;
    edName: TEdit;
    Label1: TLabel;
    lbPeriod: TLabel;
    edPeriod: TEdit;
    procedure btApplyClick(Sender: TObject);
    procedure ButtonOKClick(Sender: TObject);
  private
    FDevice :IDevice;
  public
    class function Execute(Device: IDevice): TModalResult;
  end;

implementation

uses tools, Container;
{$R *.dfm}

{ TDlgSetupDev }

procedure TDlgSetupDev.btApplyClick(Sender: TObject);
 var
  cy: ICycle;
begin
  (FDevice as ICaption).Text := edName.Text;
  if Supports(FDevice, ICycle, cy) then cy.Period := StrToInt(edPeriod.Text);
end;

procedure TDlgSetupDev.ButtonOKClick(Sender: TObject);
begin
  btApplyClick(Sender);
end;

class function TDlgSetupDev.Execute(Device: IDevice): TModalResult;
 var
  cy: ICycle;
begin
  with TDlgSetupDev.Create(nil) do
  try
   FDevice := Device;
   edName.Text := (FDevice as ICaption).Text;
   if Supports(FDevice, ICycle, cy) then
    begin
     lbPeriod.Visible := True;
     edPeriod.Visible := True;
     edPeriod.Text := cy.Period.ToString;
    end;
   Result := ShowModal;
  finally
   Free;
  end;
end;

end.

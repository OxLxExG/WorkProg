unit MetrGK.CheckFormSetup;

interface

uses RootImpl,  debug_except,  CheckFormSetup,
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics, Xml.XMLIntf,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls, JvComponentBase, JvInspector, JvExControls;

type
  TFormGKCheckSetup = class(TFormCheckSetup)
  private
  protected
    procedure DoBeforeShow; override;
  public
  end;

implementation

uses tools, math;

{ TFormGKCheckSetup }

procedure TFormGKCheckSetup.DoBeforeShow;
begin
  inherited;
  UsedStol := getp(FRoot, 'UsedStol', 'Стол-ГК');
  Room :=     getp(FRoot, 'Room', 'Производственное помещение');
end;

end.

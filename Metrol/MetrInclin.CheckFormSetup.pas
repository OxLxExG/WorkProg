unit MetrInclin.CheckFormSetup;

interface

uses RootImpl,  debug_except,  CheckFormSetup, JDtools,
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics, Xml.XMLIntf,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls, JvComponentBase, JvInspector, JvExControls;

type
  TFormInclinCheckSetup = class(TFormCheckSetup)
  private
    FErrZU: Double;
    FErrAZ5: Double;
    FErrAZ: Double;
  protected
    procedure DoBeforeShow; override;
  public
    [ShowProp('Погрешность ЗУº', True)]                  property ErrZU: Double read FErrZU write FErrZU;
    [ShowProp('Погрешность АЗº (30º-120º ЗУ)', True)]    property ErrAZ: Double read FErrAZ write FErrAZ;
    [ShowProp('Погрешность АЗº (5º-10º ЗУ)', True)]      property ErrAZ5: Double read FErrAZ5 write FErrAZ5;
  end;

implementation

uses tools, math;

{ TFormInclinCheckSetup }

procedure TFormInclinCheckSetup.DoBeforeShow;
begin
  inherited;
//  DevName :=  getp(FRoot, 'DevName', ' Инклинометр');
  UsedStol := getp(FRoot, 'UsedStol', 'Уси-2');
  Room :=     getp(FRoot, 'Room', 'Производственное помещение ОМ');
  ErrZU :=    RoundTo(getp(FRoot, 'ErrZU', 0), -2);
  ErrAZ :=    RoundTo(getp(FRoot, 'ErrAZ', 0), -2);
  ErrAZ5 :=   RoundTo(getp(FRoot, 'ErrAZ5', 0), -2);
end;

end.

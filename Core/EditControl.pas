unit EditControl;

interface

uses Winapi.Windows, System.Classes, Vcl.StdCtrls, Vcl.ExtCtrls, Vcl.Controls, Winapi.Messages, System.SysUtils,
  Vcl.Forms, Vcl.Graphics, Vcl.Menus, Vcl.Buttons;
type
  TDataExchangeEdit = class(TButtonedEdit)
  protected
    procedure Loaded; override;
  end;

implementation

uses Container, ExtendIntf;

{ TDataExchangeEdit }

procedure TDataExchangeEdit.Loaded;
 var
  ip: IImagProvider;
begin
  inherited;
  if Supports(GContainer, IImagProvider,ip) then Images := ip.GetImagList;
  RightButton.Visible := True;
  RightButton.ImageIndex := 339;
  RightButton.PressedImageIndex := 339;
  RightButton.HotImageIndex := 339;
  DoubleBuffered := True;
end;

end.

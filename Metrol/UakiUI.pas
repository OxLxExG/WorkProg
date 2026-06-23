unit UakiUI;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, DockIForm, RootImpl,
  Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls, UakiIntf, Vcl.Menus;

type
  TFrameUakiUI = class(TFrame)
    lbName: TLabel;
    lbCurAng: TLabel;
    lbReper: TLabel;
    LbMotor: TLabel;
    lbTumb: TLabel;
    lbErr: TLabel;
    btGo: TButton;
    edNeed: TEdit;
    pp: TPopupMenu;
    NTolerance: TMenuItem;
    NCurrentSet: TMenuItem;
  private
    { Private declarations }
  public
    Adr: Integer;
    procedure UpdateScreen(Axis: IAxis);
//    class function Init(ParentForm: TIForm; Parent: TWinControl; const Caption: string; Addr: Integer): TFrameUakiUI;
  end;

implementation

{$R *.dfm}

{uses MetrUAKI;

class function TFrameUakiUI.Init(ParentForm: TIForm; Parent: TWinControl; const Caption: string; Addr: Integer): TFrameUakiUI;
begin
   Result := TFrameUakiUI.Create(ParentForm);
//   Result.Name := 'FrameUakiUI'+addr.Tostring;
   Result.Parent := Parent;
   Result.btGo.OnClick := TFormUAKI(ParentForm).btGoClick;
   Result.lbReper.OnClick := TFormUAKI(ParentForm).btReperClick;
   Result.lbName.Caption := Caption;
   Result.Adr := addr;
   Result.Show;
end;}

procedure TFrameUakiUI.UpdateScreen(Axis: IAxis);
begin
  lbReper.Caption := Axis.Reper;
  lbReper.Hint := Axis.ReperToString;
  lbReper.Color := Axis.ReperToColor;

  lbMotor.Caption := Axis.Motor;
  lbMotor.Hint := Axis.MotorToString;
  lbMotor.Color := Axis.MotorToColor;

  lbTumb.Caption := Axis.EndTumbler;
  lbTumb.Hint := Axis.EndTumblerToString;
  lbTumb.Color := Axis.EndTumblerToColor;

  lbErr.Caption := Axis.Error.ToHexString;
  lbErr.Hint := Axis.ErrorToText;

  lbCurAng.Caption := Axis.CurrentAngle.ToString();
end;

initialization
  RegisterClass(TFrameUakiUI);
finalization
end.

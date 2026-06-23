unit UakiUI.Ten;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, UakiIntf,
  Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls, Vcl.ExtCtrls;

type
  TFuncUaki = function: IUaki of object;
  TFrameUakiTEN = class(TFrame)
    lb1: TLabel;
    ed1: TEdit;
    ed2: TEdit;
    lb2: TLabel;
    ed3: TEdit;
    lb3: TLabel;
    lbT: TLabel;
    Label1: TLabel;
    btStop: TButton;
    edOff: TEdit;
    cbauto: TCheckBox;
    btSart: TButton;
    edOn: TEdit;
    Timer: TTimer;
    procedure edKeyPress(Sender: TObject; var Key: Char);
    procedure btStopClick(Sender: TObject);
    procedure btSartClick(Sender: TObject);
    procedure TimerTimer(Sender: TObject);
  private
    { Private declarations }
  public
    FuncUaki: TFuncUaki;
    procedure UpdateScreen(TenLen: Integer; uaki: IUaki);
  end;

implementation

{$R *.dfm}

{ TFrameUakiTEN }

procedure TFrameUakiTEN.btSartClick(Sender: TObject);
begin
  FuncUaki.TenStart;
end;

procedure TFrameUakiTEN.btStopClick(Sender: TObject);
begin
  FuncUaki.TenStop;
end;

procedure TFrameUakiTEN.edKeyPress(Sender: TObject; var Key: Char);
begin
  if Key = #$D then
   begin
    FuncUaki.TenPower[TEdit(Sender).Tag] := StrToInt(TEdit(Sender).Text);
    Key := #0;
   end;
end;

procedure TFrameUakiTEN.TimerTimer(Sender: TObject);
begin
   lbT.Color := RGB(255,192,192);
end;

procedure TFrameUakiTEN.UpdateScreen(TenLen: Integer; uaki: IUaki);
 var
  a, amax: Double;
begin
  Timer.Enabled := False;
  Timer.Enabled := True;
  lb1.Caption := uaki.TenPower[0].ToString;
  lb2.Caption := uaki.TenPower[1].ToString;
  lb3.Caption := uaki.TenPower[2].ToString;
  lbT.Color := clWhite;
  lbT.Caption := '';
  amax := 0;
  for a in uaki.Temperature do
   begin
    lbT.Caption := lbT.Caption + Format('%6.2f ',[a]);
    if a > amax then amax := a;
   end;
  if amax >= StrToFloat(edOff.Text) then
      uaki.TenStop
  else if cbauto.Checked and (amax < StrToFloat(edOn.Text)) then
      uaki.TenStart;
end;

end.

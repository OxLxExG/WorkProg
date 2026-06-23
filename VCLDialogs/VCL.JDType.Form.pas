unit VCL.JDType.Form;

interface

uses System.SysUtils, System.Types, System.Classes, Vcl.ExtCtrls, Vcl.Forms, Vcl.Controls;

type
  TJDTypeForm<T> = class(TForm)
  private
    FTimer: TTimer;
    FSetData: Boolean;
    procedure SetEditData(const Value: T);
  type
   TInnerControl = class(TControl);
    procedure FormMouseLeave(Sender: TObject);
    procedure TimerTimer(Sender: TObject);
    procedure FormMouseEnter(Sender: TObject);
  protected
    FResult: TProc<T>;
    FEditData: T;
    FCanClose: Boolean;
    procedure AfteSetData; virtual;
    procedure DoDataChanged; virtual;
    procedure loaded; override;
    property Timer: TTimer read FTimer;
    property SetData: Boolean read FSetData;
    property EditData: T read FEditData write SetEditData;
  public
    class procedure Execute(ALeftTop: TPoint; AEditData: T; FuncResult: Tproc<T>);
  end;


implementation

{ TJDTypeForm }

procedure TJDTypeForm<T>.AfteSetData;
begin
end;

procedure TJDTypeForm<T>.DoDataChanged;
begin
  if Assigned(FResult) and not SetData then FResult(FEditData);
end;

class procedure TJDTypeForm<T>.Execute(ALeftTop: TPoint; AEditData: T; FuncResult: Tproc<T>);
begin
  with Create(nil) do
   begin
    Left := ALeftTop.X;
    Top := ALeftTop.Y;
    FEditData := AEditData;
    FResult := FuncResult;
    FSetData := True;
    AfteSetData;
    FSetData := False;
    FCanClose := True;
    Show;
    SetFocus;
   end;
end;

procedure TJDTypeForm<T>.FormMouseEnter(Sender: TObject);
begin
  FTimer.Enabled := False;
end;

procedure TJDTypeForm<T>.FormMouseLeave(Sender: TObject);
begin
  if FCanClose then FTimer.Enabled := True;
end;
procedure TJDTypeForm<T>.loaded;
 var
  i: Integer;
begin
  inherited;
  FTimer := TTimer.Create(Self);
  FTimer.Enabled := False;
  FTimer.Interval := 100;
  FTimer.OnTimer := TimerTimer;
  Self.OnMouseEnter := FormMouseEnter;
  Self.OnMouseLeave := FormMouseLeave;
  Self.BorderStyle := bsNone;
  for i := 0 to ControlCount-1 do
   begin
    TInnerControl(Controls[i]).OnMouseEnter := FormMouseEnter;
    TInnerControl(Controls[i]).OnMouseLeave := FormMouseLeave;
   end;
end;

procedure TJDTypeForm<T>.SetEditData(const Value: T);
begin
  if SetData then Exit;
  FEditData := Value;
  DoDataChanged;
end;

procedure TJDTypeForm<T>.TimerTimer(Sender: TObject);
begin
  if FCanClose then Free;
end;

end.

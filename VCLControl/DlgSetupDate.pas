unit DlgSetupDate;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.ComCtrls, Vcl.StdCtrls, Vcl.ExtCtrls;

type
  TFormCalendar = class(TForm)
    MonthCalendar: TMonthCalendar;
    Timer1: TTimer;
    procedure Timer1Timer(Sender: TObject);
    procedure FormMouseEnter(Sender: TObject);
    procedure FormMouseLeave(Sender: TObject);
    procedure MonthCalendarClick(Sender: TObject);
  private
    FRes: Tproc<TDate>;
  public
    class procedure Execute(ALeftTop: TPoint; d: TDate; func: Tproc<TDate>);
  end;

implementation

{$R *.dfm}

uses JvInspector;

{ TInspDateItem }

type
  TInspDateItem = class(TJvInspectorDateItem)
  protected
  public
    constructor Create(const AParent: TJvCustomInspectorItem; const AData: TJvCustomInspectorData); override;
    procedure Edit; override;
  end;

constructor TInspDateItem.Create(const AParent: TJvCustomInspectorItem; const AData: TJvCustomInspectorData);
begin
  inherited;
  Flags := Flags  + [iifEditButton];
end;

procedure TInspDateItem.Edit;
begin
  TFormCalendar.execute(Tcontrol(Inspector.Owner).ClientToScreen(Rects[iprEditButton].TopLeft), Data.AsFloat,
  procedure (c: TDate)
  begin
    Data.AsFloat := c;
    EditCtrl.Text := GetDisplayValue;
  end);
end;

{ TFormCalendar }

class procedure TFormCalendar.Execute(ALeftTop: TPoint; d: TDate; func: Tproc<TDate>);
begin
  with TFormCalendar.Create(nil) do
   begin
    MonthCalendar.Date := d;
    Left := ALeftTop.X;
    Top := ALeftTop.Y;
    FRes := func;
    Show;
   end;
end;

procedure TFormCalendar.FormMouseEnter(Sender: TObject);
begin
  Timer1.Enabled := False;
end;

procedure TFormCalendar.FormMouseLeave(Sender: TObject);
begin
  Timer1.Enabled := True;
end;

procedure TFormCalendar.MonthCalendarClick(Sender: TObject);
begin
  FRes(MonthCalendar.Date);
end;

procedure TFormCalendar.Timer1Timer(Sender: TObject);
begin
  Free;
end;

initialization
  TJvCustomInspectorData.ItemRegister.Add(TJvInspectorTypeInfoRegItem.Create(TInspDateItem,TypeInfo(TDate)));
  TJvCustomInspectorData.ItemRegister.Add(TJvInspectorTypeInfoRegItem.Create(TInspDateItem,TypeInfo(TDateTime)));
  TJvCustomInspectorData.ItemRegister.Add(TJvInspectorTypeInfoRegItem.Create(TInspDateItem,TypeInfo(TTime)));
end.

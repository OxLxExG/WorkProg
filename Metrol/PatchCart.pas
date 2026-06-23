unit PatchCart;

interface

uses tools, TeEngine, Series, TeeProcs, Chart;

procedure PatchTeeCart(c: TChart);

implementation

procedure PatchTeeCart(c: TChart);
 procedure Axcolor(a: TChartAxis);
 begin
    a.Axis.Color := clThWindowTextDisabled;          // Цвет самой линии оси
    a.Ticks.Color := clThWindowTextDisabled;         // Цвет основных делений
    a.LabelsFont.Color := clThWindowTextDisabled;   // Цвет текста подписей
    a.Title.Font.Color := clThWindowTextDisabled;//    Painter.BackgroundColor := clThBkg;
    a.Grid.Color := clThBorder;
 end;
begin
  if CurrentThemeIsDark then
   begin
    C.Color := clThBkg;
    Axcolor(C.Axes.Bottom);
    Axcolor(C.Axes.Left);
    C.Legend.Color := clThBorder;
    C.Legend.Font.Color := clThWindowTextNormal;
    C.Legend.Frame.Color := clThWindowTextDisabled;
    C.Legend.Gradient.Visible := False;
   end;
end;

end.

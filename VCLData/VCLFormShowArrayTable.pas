unit VCLFormShowArrayTable;

interface

uses  DockIForm,  RootImpl, ExtendIntf, math, tools,
  Winapi.Windows, Winapi.Messages, system.TypInfo, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, JvExControls, JvChart;

type
  TFormTableGraph = class(TDialogIForm, Idialog, IDialog<string, Tarray<Single>>)
    Chart: TJvChart;
  protected
    function GetInfo: PTypeInfo; override;
    function Execute(Name: string; Data: Tarray<Single>): boolean;
  private
    { Private declarations }
  public
    { Public declarations }
  end;

  Dialog_TableGraph = interface
  ['{1008EDB1-20C6-46F6-8CD4-DFCDE8C8B30C}']
  end;

implementation

{$R *.dfm}

{ TFormTableGraph }

function TFormTableGraph.Execute(Name: string; Data: Tarray<Single>): boolean;
begin
  Caption := Name;
  Chart.Data.ValueCount := Length(Data); // Указываем количество точек

  Chart.Options.PaperColor := clThBkg;
  Chart.Options.AxisLineColor := clThWindowTextDisabled;
  Chart.Options.AxisFont.Color := clThWindowTextNormal;

  var MinVal := MinValue(Data);
  var MaxVal := MaxValue(Data);

  // 2. Устанавливаем границы для оси Y
  // (Добавляем небольшой отступ в 5-10%, чтобы график не прилипал к краям)
  Chart.Options.PrimaryYAxis.YMin := MinVal - (Abs(MinVal) * 0.1);
  Chart.Options.PrimaryYAxis.YMax := MaxVal + (Abs(MaxVal) * 0.1);
  // 2. Заполнение данными
  for var i := 0 to High(Data) do
  begin
    // Индексы: [НомерПера, НомерТочки]
    Chart.Data.Value[0, i] := Data[i];
  end;
 Chart.PlotGraph;
 IShow;
end;

function TFormTableGraph.GetInfo: PTypeInfo;
begin
  Result := TypeInfo(Dialog_TableGraph);
end;

initialization
  RegisterDialog.Add<TFormTableGraph, Dialog_TableGraph>;
finalization
  RegisterDialog.Remove<TFormTableGraph>;
end.

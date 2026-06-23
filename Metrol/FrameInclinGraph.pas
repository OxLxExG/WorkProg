unit FrameInclinGraph;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes,
  Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.ComCtrls, TeEngine, Series, Vcl.ExtCtrls, TeeProcs,
  Chart;

type
  TFrmInclinGraph = class(TFrame)
    sb: TStatusBar;
    cht: TChart;
    srData: TLineSeries;
    srIst: TLineSeries;
    srErrSin: TLineSeries;
    srErr: TLineSeries;
  end;

implementation

{$R *.dfm}

end.

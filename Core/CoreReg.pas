unit CoreReg;

interface

uses System.Classes, RootImpl, EditControl, OtklonitelPaintClass,
CustomPlot,
DataImportImpl, LasDataSet, RangeSelector;//, DBGrid;

procedure Register;

implementation

procedure Register;
begin
  RegisterComponents('Горизонт', [TCPageControl, TDataExchangeEdit, TOtklonitelPaint, TGraph, TCNavigator, TRangeSelector]);
end;

end.

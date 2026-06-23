unit TeeTools;

interface

uses  SysUtils, System.Generics.Collections,
      VCLTee.TeEngine, VCLTee.Series, Vcl.ExtCtrls, VCLTee.TeeProcs, VCLTee.Chart;
type
 TZSeries = class(TList<TFastLineSeries>)
  private
    FChart: TChart;
    FRootSeries: TFastLineSeries;
    function GetZOrderCount: Integer;
    procedure SetZOrderCount(const Value: Integer);
    procedure UpdateZorder(CountZ: Integer);
    const DZ=1;
  protected
    procedure Notify(const Value: TFastLineSeries; Action: TCollectionNotification); override;
    property Count;
  public
   constructor Create(Chart: TChart; RootSeries: TFastLineSeries);
   function AddArray(const AArray: array of Double): integer;
   property ZOrderCount: Integer read GetZOrderCount write SetZOrderCount;
 end;

implementation

{ TZSeries }

function TZSeries.AddArray(const AArray: array of Double): integer;
 var
  f: TFastLineSeries;
begin
  Result := 0;
  for f in self do f.BeginUpdate;
  try
   UpdateZorder(1);
   for f in self do if f.ZOrder = 0 then
    begin
     f.Clear;
     Result := f.AddArray(AArray);
     Break;
    end;
  finally
   for f in self do f.EndUpdate;
  end;
end;

function TZSeries.GetZOrderCount: Integer;
begin
  Result := Count;
end;

procedure TZSeries.Notify(const Value: TFastLineSeries; Action: TCollectionNotification);
begin
  inherited;
  if (Value <> FRootSeries) and (Action = cnRemoved) then Value.DisposeOf;
end;

procedure TZSeries.SetZOrderCount(const Value: Integer);
 var
  i, n: Integer;
  f: TFastLineSeries;
begin
   n := Count;
  if n < Value then
   for I := n-1 to Value-1 do
    begin
     f := TFastLineSeries(FChart.AddSeries(TFastLineSeries));
     f.Assign(FRootSeries);
     f.ShowInLegend := False;
     Add(f);
    end
   else Count := Value;
  UpdateZorder(0);
end;

procedure TZSeries.UpdateZorder(CountZ: Integer);
 var
  z: Integer;
  f: TFastLineSeries;
begin
  z := (First.ZOrder+ CountZ*DZ) mod (Count*DZ);
  for f in self do f.BeginUpdate;
  try
   for f in self do
    begin
     f.ZOrder := z;
     z := (z+1*DZ) mod (Count*DZ);
    end;
  finally
   for f in self do f.EndUpdate;
  end;
end;

{ TZSeries }

constructor TZSeries.Create(Chart: TChart; RootSeries: TFastLineSeries);
begin
  inherited Create;
  FRootSeries := RootSeries;
  FChart := Chart;
  Add(FRootSeries);
end;

end.

unit PlotDB;

interface

uses SysUtils, Classes, Plot, DB, RootImpl, debug_except, DBintf;

type
  TGraphParamDB = class(TGraphParam)
  private
    FXFied: TField;
    FYFied: TField;
    FXFiedName: string;
    procedure SetXFiedName(const Value: string);
    function GetDataSet: TCustomAsyncMemTable;
    function GetYFiedName: string;
  protected
    procedure UpdateFields; // internal RecalcScale UpdateMinMaxY
    procedure UpdateMinMaxY(var MinY, MaxY: Double); override; // internal TCustomPlotDB
    function RecordCount: Integer; override; // internal RecalcScale
    function CheckEOFandGetXY(var X,Y: Double; GoToFirst: Boolean = false): Boolean; override; // internal RecalcScale
    procedure RecalcScale(); override; // защита AsyncADQuery
    property YFiedName: string read GetYFiedName;
  public
    property DataSet: TCustomAsyncMemTable read GetDataSet;// write SetDataSet;
  published
    [ShowProp('Источник данных', True)] property XFiedName: string read FXFiedName write SetXFiedName;
  end;

  TCustomPlotDB = class(TCustomPlot)
  private
    FFiedName: string;
    FDataSet: TCustomAsyncMemTable;
  public
    procedure UpdateMinMaxY(ForceScale: boolean = False); override; // защита AsyncADQuery
    property DataSet: TCustomAsyncMemTable read FDataSet write FDataSet;
  published
    property FiedName: string read FFiedName write FFiedName;
  end;

  TPlotDB = class(TCustomPlotDB)
  public
    property OnMouseUp;
  published
    property Align;
    property ParentFont;
    property Font;
    property OnScaleChanged;
    property ParentColor;
    property Color;
    property OnContextPopup;
  end;


implementation

uses Math;

{ TGraphParamDB }

function TGraphParamDB.CheckEOFandGetXY(var X, Y: Double; GoToFirst: Boolean): Boolean;
begin
  UpdateFields;
  if Plot.Mirror = 1 then
   begin
    if GoToFirst then
     begin
      DataSet.First;
      if DataSet.Eof then Exit(False);
      Y := FYFied.AsFloat;
      if FXFied.IsNull then X := NULL_VALL
      else X := FXFied.AsFloat;
      Exit(True);
     end;
    if FXFied.IsNull then X := NULL_VALL
    else X := FXFied.AsFloat;
    Y := FYFied.AsFloat;
    DataSet.Next;
    Result := DataSet.Eof;
   end
  else
   begin
    if GoToFirst then
     begin
      DataSet.Last;
      if DataSet.Bof then Exit(False);
      Y := FYFied.AsFloat;
      if FXFied.IsNull then X := NULL_VALL
      else X := FXFied.AsFloat;
      Exit(True);
     end;
    if FXFied.IsNull then X := NULL_VALL
    else X := FXFied.AsFloat;
    Y := FYFied.AsFloat;
    DataSet.MoveBy(-1);
    Result := DataSet.Bof;
   end;
end;

function TGraphParamDB.GetDataSet: TCustomAsyncMemTable;
begin
  Result := TPlotDB(Plot).DataSet;
end;

function TGraphParamDB.GetYFiedName: string;
begin
  Result := TPlotDB(Plot).FiedName;
end;

procedure TGraphParamDB.RecalcScale;
begin
  DataSet.Acquire;
  try
   inherited;
  finally
    DataSet.Release;
  end;
end;

function TGraphParamDB.RecordCount: Integer;
begin
  if Assigned(DataSet) then Result := DataSet.RecordCount
  else Result := 0;
end;

procedure TGraphParamDB.SetXFiedName(const Value: string);
begin
  FXFiedName := Value;
  if Title = '' then Title := FXFiedName;
end;

procedure TGraphParamDB.UpdateFields;
begin
  FXFied := nil;
  FYFied := nil;
  if Assigned(DataSet) then
   begin
    if FXFiedName <>'' then FXFied := DataSet.FieldByName(FXFiedName);
    if YFiedName <>'' then FYFied := DataSet.FieldByName(YFiedName);
   end;
end;

procedure TGraphParamDB.UpdateMinMaxY(var MinY, MaxY: Double);
begin
  UpdateFields;
  if not Assigned(FYFied) then Exit;
  if Plot.Mirror = 1 then  DataSet.First else DataSet.Last;
  MinY := Min(MinY, FYFied.AsFloat);
  if Plot.Mirror = 1 then  DataSet.Last else DataSet.First;
  MaxY := Max(MaxY, FYFied.AsFloat);
end;

{ TGraphColumnDB }

procedure TCustomPlotDB.UpdateMinMaxY(ForceScale: boolean);
begin
  FDataSet.Acquire;
  try
   inherited;
  finally
    FDataSet.Release;
  end;
end;

initialization
  RegisterClasses([TGraphParamDB, TCustomPlotDB, TPlotDB]);
end.

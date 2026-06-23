unit PlotLas;

interface

uses SysUtils, Classes, Plot, RootImpl, debug_except, LAS, LasImpl, Container, System.Variants;

type
  TGraphParamLAS = class(TGraphParam)
  private
    FRecordCount, FXIndex: Integer;
    FMinY, FMaxY: Double;
    FFileName: string;
    FXName: string;
    FYName: string;
//    function GetYFiedName: string;
    procedure UpdateFields;
  protected
    procedure UpdateMinMaxY(var MinY, MaxY: Double); override; // internal TCustomPlotDB
    function RecordCount: Integer; override; // internal RecalcScale
    function CheckEOFandGetXY(var X,Y: Double; GoToFirst: Boolean = false): Boolean; override; // internal RecalcScale
  public
    [ShowProp('Источник данных Y', True)] property YFiedName: string read FYName;
  published
   [ShowProp('LAS файл', True)] property FileName: string read FFileName write FFileName;
   [ShowProp('Источник данных X', True)] property XName: string read FXName write FXName;
  end;

implementation

uses Math;

{ TGraphParamLAS }

procedure TGraphParamLAS.UpdateFields;
 var
  ld: ILasDoc;
  Mnm: TArray<string>;
  i: Integer;
begin
  if FRecordCount > 0 then Exit;
  ld := GetLasDoc(FileName);
  FRecordCount := Length(ld.Data.Items);
  FMinY := ld.Data.Items[0, 0];
  FMaxY := ld.Data.Items[FRecordCount-1, 0];
  Mnm := ld.Curve.Mnems;
  FYName := Mnm[0];
  Title := ld.Curve.Items[FXName].Description;
  if Title ='' then Title := FXName;
  EUnit := ld.Curve.Items[FXName].Units;
  for i := 0 to Length(Mnm)-1 do if Mnm[i] = FXName then
   begin
    FXIndex := i;
    Break;
   end;
end;

function TGraphParamLAS.RecordCount: Integer;
begin
  UpdateFields;
  Result := FRecordCount;
end;

procedure TGraphParamLAS.UpdateMinMaxY(var MinY, MaxY: Double);
begin
  UpdateFields;
  MinY := Min(MinY, FMinY);
  MaxY := Max(MaxY, FMaxY);
end;

function TGraphParamLAS.CheckEOFandGetXY(var X, Y: Double; GoToFirst: Boolean): Boolean;
  {$J+}
 const
  I: Integer=0;
  D: TArray<TArray<Variant>> = nil;
 {$J-}
  procedure ApplyData;
  begin
    if VarisNull(D[i, FXIndex]) then X := NULL_VALL
    else X := D[i, FXIndex];
    Y := D[i, 0];
  end;
begin
  UpdateFields;
  if Plot.Mirror = 1 then
   begin
    if GoToFirst then
     begin
      I := 0;
      D := GetLasDoc(FFileName).Data.Items;
      if Length(d) = 0 then Exit(False);
      ApplyData;
      Inc(i);
      if Length(d) = i then Exit(False);
      Exit(True);
     end;
    ApplyData;
    Inc(i);
    Result := I>=Length(D);
   end
  else
   begin
    if GoToFirst then
     begin
      I := FRecordCount;
      D := GetLasDoc(FFileName).Data.Items;
      if Length(d) = 0 then Exit(False);
      ApplyData;
      Dec(i);
      if Length(d) = i then Exit(False);
      Exit(True);
     end;
    ApplyData;
    Dec(i);
    Result := I<0;
   end;
  if Result then D := nil;
end;

initialization
  RegisterClasses([TGraphParamLAS]);
end.

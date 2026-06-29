unit Plot.GR32.Tools;

interface

uses CustomPlot.DataLink,
  System.SysUtils, System.Classes, System.Types, System.UITypes, ExtendIntf, Vcl.Forms,
  Plot.DtLink, Vcl.Graphics, Vcl.Themes, Winapi.Windows, Winapi.Messages,
  System.Math, GR32_Math, GR32, GR32_Image, GR32_RangeBars, GR32_Blend, Controls,
  GR32_Polygons, GR32_Resamplers, GR32_VectorUtils, GR32_Geometry, RootImpl,
  Container, tools, JDtools, debug_except, CustomPlot;

resourcestring
 RS_Grath= 'Graphic column';// '√рафическа€ колонка';

const
  CHECKBOX_SIZE = 10;

type
  TGR32GraphicCollumn = class(TGraphColmn, ICaption)
  protected
    function GetCaption: string;
    procedure SetCaption(const Value: string);
    procedure DoVisibleChanged; override;
    procedure ColumnCollectionChanged(ColumnCollection: TGraphCollection); override;
    procedure ColumnCollectionItemChanged(const Item: TColumnCollectionItem); override;
  end;

  TGR32LegendRow = class(TCustomGraphLegendRow)
  protected
    procedure DoVisibleChanged; override;
  end;

  TGR32Region = class(TGraphRegion)
  protected
    procedure SetVisible(Visible: Boolean); virtual;
    procedure ParamCollectionChanged; virtual; abstract;
    procedure ParamPropChanged; virtual; abstract;
  end;

function Bm32ThemeGreate: TBitmap32;
function RandomColor: TAlphaColor;
function ScaleFloatPoint(L: TFloat; R: TFloatPoint): TFloatPoint;
function DistanceFromPointToSegment(v, w, p: TFloatPoint): TFloat;
function DistanceFromPointToCurve(p: TFloatPoint; const Curve: TArrayOfFloatPoint): TFloat;
procedure DrawCheckBox(Bitmap: TBitmap32; Y: Integer; const Checked: Boolean; nX: Integer = 0);
procedure DrawLineParametr(Bitmap: TBitmap32; Color: TColor; const points: TArrayOfFloatPoint;
          Width: Integer = 1; DashStyle: TLineDashStyle = ldsSolid; offset: TFloat = 0); overload;
procedure DrawLineParametr(Bitmap: TBitmap32; P: TXScalableParam; const points: TArrayOfFloatPoint; offset: TFloat = 0); overload;


implementation

{$REGION 't o o l s'}

function Bm32ThemeGreate: TBitmap32;
begin
 var r := TBitmap32.Create();
//  r.Canvas.Brush.Color := StyleServices.GetStyleColor(scWindow);
//  r.Canvas.Font.Color := StyleServices.GetStyleFontColor(sfWindowTextNormal);
//  r.Clear(Color32(StyleServices.GetStyleColor(scWindow)));
 result := r;
end;

function RandomColor: TAlphaColor;
begin
//  Result := TColor(HSVtoRGB(Random(360), 1, 0.5));
  Result := TAlphaColor(Color32(Random(256), Random(256), Random(256), $E0));
end;

function ScaleFloatPoint(L: TFloat; R: TFloatPoint): TFloatPoint;
begin
  Result.X := R.X * L;
  Result.Y := R.Y * L;
end;

/// <summary>
/// рассто€ние от точки p до отрезка vw
/// </summary>
/// <remarks>
/// вз€л с интернета
/// </remarks>
/// <example>
/// <code>
/// float minimum_distance(vec2 v, vec2 w, vec2 p)
/// {
///  // Return minimum distance between line segment vw and point p
///  const float l2 = length_squared(v, w);  // i.e. |w-v|^2 -  avoid a sqrt
///   if (l2 == 0.0) return distance(p, v);   // v == w case
///   // Consider the line extending the segment, parameterized as v + t (w - v).
///   // We find projection of point p onto the line.
///   // It falls where t = [(p-v) . (w-v)] / |w-v|^2
///   // We clamp t from [0,1] to handle points outside the segment vw.
///   const float t = max(0, min(1, dot(p - v, w - v) / l2));
///   const vec2 projection = v + t * (w - v);  // Projection falls on the segment
///   return distance(p, projection);
/// }
/// </code>
/// </example>
function DistanceFromPointToSegment(v, w, p: TFloatPoint): TFloat;
var
  t, l2: Single;
begin
  /// i.e. |w-v|^2 -  avoid a sqrt
  if v.X.IsNaN or w.X.IsNaN then
    Exit(Single.MaxValue);
  l2 := SqrDistance(v, w);
  /// v == w case
  if (l2 = 0.0) then
    Exit(Distance(p, v));
  /// Consider the line extending the segment, parameterized as v + t (w - v).
  /// We find projection of point p onto the line.
  /// It falls where t = [(p-v) . (w-v)] / |w-v|^2
  /// We clamp t from [0,1] to handle points outside the segment vw.
  t := max(0, min(1, dot(p - v, w - v) / l2));
//  const vec2 projection = v + t * (w - v);  // Projection falls on the segment
  Result := Distance(p, v + ScaleFloatPoint(t, w - v));
end;

/// <summary>
/// рассто€ние от точки p до кривой
/// </summary>
function DistanceFromPointToCurve(p: TFloatPoint; const Curve: TArrayOfFloatPoint): TFloat;
var
  n, L, i: Integer;
begin
  Result := Single.MaxValue;
  L := Length(Curve);
  if L = 1 then
    Exit(Distance(p, Curve[0]));
  n := 0;
  // “ак как  планируетс€ что Y ¬сегда монотонно растет находим Curve[n-1].Y < p.Y <= Curve[n].Y
  while (n < L) and (p.Y > Curve[n].Y) do
    Inc(n);
  //  в районе n находим рассто€ние до кривой
  for i := Max(0, n - 3) to Min(L - 2, n + 3) do
    Result := Min(Result, DistanceFromPointToSegment(Curve[i], Curve[i + 1], p));
end;
procedure DrawCheckBox(Bitmap: TBitmap32; Y: Integer; const Checked: Boolean; nX: Integer = 0);
const
  DA: array[Boolean] of TThemedButton = (tbCheckBoxUncheckedNormal, tbCheckBoxCheckedNormal);
var
  B: Vcl.Graphics.TBitmap;
  NonThemedCheckBoxState: Cardinal;
  R: TRect;
begin
  B := Vcl.Graphics.TBitmap.Create;
  try
    B.SetSize(CHECKBOX_SIZE, CHECKBOX_SIZE);
    R := Rect(0, 0, CHECKBOX_SIZE, CHECKBOX_SIZE);
    if StyleServices.Enabled then
      StyleServices.DrawElement(B.Canvas.Handle, StyleServices.GetElementDetails(DA[Checked]), R)
    else
    begin
      B.Canvas.FillRect(R);
      NonThemedCheckBoxState := DFCS_BUTTONCHECK;
      if Checked then
        NonThemedCheckBoxState := NonThemedCheckBoxState or DFCS_CHECKED;
      DrawFrameControl(B.Canvas.Handle, R, DFC_BUTTON, NonThemedCheckBoxState);
    end;
    Bitmap.Draw(TRect.Create(TPoint.Create(nX * (CHECKBOX_SIZE + 1) + CHECKBOX_SIZE div 2, Y - CHECKBOX_SIZE div 2), CHECKBOX_SIZE, CHECKBOX_SIZE), R, B.Canvas.Handle);
  finally
    B.Free;
  end;
end;

procedure DrawLineParametr(Bitmap: TBitmap32; Color: TColor; const points: TArrayOfFloatPoint;
          Width: Integer = 1; DashStyle: TLineDashStyle = ldsSolid; offset: TFloat = 0); overload;

  function GetDashes: TArrayOfFloat;
  var
    i: Integer;
  begin
    case DashStyle of
      ldsDot:
        Result := [1, 2];
      ldsDash:
        Result := [8, 2];
      ldsDashDot:
        Result := [8, 2, 1, 2];
      ldsDashDotDot:
        Result := [8, 2, 1, 2, 1, 2];
    end;
    for i := 0 to High(Result) do
      Result[i] := Result[i] {* FixedOne}   * Width;
  end;

var
  MultiPoly: TArrayOfArrayOfFloatPoint;
  offs: TFloat;
begin
  if DashStyle = ldsSolid then
    PolylineFS(Bitmap, points, Color, False, Width{ * FixedOne})
  else
   begin
    MultiPoly := GR32_VectorUtils.BuildDashedLine(Points, GetDashes, offset, False);
    PolyPolylineFS(Bitmap, MultiPoly, Color, False, Width);
    //DashLineFS(Bitmap, points, GetDashes, Color, False, Width{ * FixedOne});
   end;
end;

procedure DrawLineParametr(Bitmap: TBitmap32; P: TXScalableParam; const points: TArrayOfFloatPoint; offset: TFloat = 0); overload;

//  function GetDashes: TArrayOfFloat;
//  var
//    i: Integer;
//  begin
//    case P.DashStyle of
//      ldsDot:
//        Result := [1, 2];
//      ldsDash:
//        Result := [8, 2];
//      ldsDashDot:
//        Result := [8, 2, 1, 2];
//      ldsDashDotDot:
//        Result := [8, 2, 1, 2, 1, 2];
//    end;
//    for i := 0 to High(Result) do
//      Result[i] := Result[i] {* FixedOne}   * P.Width;
//  end;

begin
  DrawLineParametr(Bitmap, p.Color, points, p.Width, p.DashStyle, offset);
//  if P.DashStyle = ldsSolid then
//    PolylineFS(Bitmap, points, P.Color, False, P.Width{ * FixedOne})
//  else
//    DashLineFS(Bitmap, points, GetDashes, P.Color, False, P.Width{ * FixedOne});
end;

{$ENDREGION}

procedure TGR32LegendRow.DoVisibleChanged;
var
  i: Integer;
begin
  inherited DoVisibleChanged;
  for i := 0 to RegionsCount - 1 do
    if Regions[i] is TGR32Region then
      TGR32Region(Regions[i]).SetVisible(Visible);
end;

{ TGR32Region }

procedure TGR32Region.SetVisible(Visible: Boolean);
begin
end;

{ TGR32GraphicCollumn }

procedure TGR32GraphicCollumn.ColumnCollectionChanged(ColumnCollection: TGraphCollection);
var
  r: TGraphRegion;
begin
  if ColumnCollection is TGraphParams then
    for r in Regions do
      if r is TGR32Region then
        TGR32Region(r).ParamCollectionChanged;
end;

procedure TGR32GraphicCollumn.ColumnCollectionItemChanged(const Item: TColumnCollectionItem);
var
  r: TGraphRegion;
begin
  if Item is TGraphPar then
    for r in Regions do
      if r is TGR32Region then
        TGR32Region(r).ParamPropChanged;
end;

procedure TGR32GraphicCollumn.DoVisibleChanged;
var
  i: Integer;
begin
  inherited DoVisibleChanged;
  for i := 0 to RegionsCount - 1 do
    if Regions[i] is TGR32Region then
      TGR32Region(Regions[i]).SetVisible(Visible);
end;

function TGR32GraphicCollumn.GetCaption: string;
begin
  Result := RS_Grath+' GR32'
end;

procedure TGR32GraphicCollumn.SetCaption(const Value: string);
begin

end;

initialization
  TGR32GraphicCollumn.ColClsRegister(TGR32GraphicCollumn, RS_Grath);
    RegisterClasses([TGR32GraphicCollumn, TGR32LegendRow]);

end.

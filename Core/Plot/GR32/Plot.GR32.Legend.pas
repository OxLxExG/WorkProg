unit Plot.GR32.Legend;

interface

uses CustomPlot.DataLink, Plot.GR32.Tools,
  System.SysUtils, System.Classes, System.Types, System.UITypes, ExtendIntf, Vcl.Forms,
  Plot.DtLink, Vcl.Graphics, Vcl.Themes, Winapi.Windows, Winapi.Messages,
  System.Math, GR32_Math, GR32, GR32_Image, GR32_RangeBars, GR32_Blend, Controls,
  GR32_Polygons, GR32_Resamplers, GR32_VectorUtils, GR32_Geometry, RootImpl,
  Container, tools, JDtools, debug_except, CustomPlot;

{$REGION 'Отрисовка легенды'}
  type
  TThemedRangeBar = class(TCustomRangeBar);

  TGR32GraphicLegend = class(TGR32Region, ICaption)
  private
    FCanvasShowRect: TRect;
    FbitmapShowRect: TRect;
    FRangeBar: TThemedRangeBar;
    FRange: Integer;
    FBitmap: TBitmap32;
    procedure UpdateShowRect;
    procedure UpdateRange;
    procedure UpdateBitmapBaund;
    procedure OnScroll(Sender: TObject);
    procedure Render;
    function GetPatamHeight(p: TGraphPar): Integer;
    procedure RenderXscalePatam(Y: Integer; p: TXScalableParam);
    procedure RenderStringPatam(Y: Integer; p: TStringParam);
    function GetCheckBoxRect(Par: TXScalableParam; nX: Integer = 0): TRect;
  protected
    function GetCaption: string;
    procedure SetCaption(const Value: string);
    procedure SetVisible(Visible: Boolean); override;
    procedure ParamCollectionChanged; override;
    procedure ParamPropChanged; override;
    procedure ParentFontChanged; override;
    procedure Paint; override;
    procedure SetClientRect(const Value: TRect); override;
    procedure MouseDown(Button: TMouseButton; Shift: TShiftState; X, Y: Integer); override;
    procedure MouseWheel(var Message: TCMMouseWheel); override;

  public
    constructor Create(Collection: TCollection); override;
//    property pp2mm: Double read Fpp2mm;
    destructor Destroy; override;
    function TryHitParametr(pos: TPoint; out Par: TGraphPar; Button: TMouseButton = TMouseButton.mbLeft; Shift: TShiftState = []): Boolean; override;
  end;
{$ENDREGION 'Отрисовка легенды'}

implementation

{$REGION 'TGR32GraphicLegend'}

{ TGR32GraphicLegend }

constructor TGR32GraphicLegend.Create(Collection: TCollection);
begin
  inherited;
  СaptureMouseWell := True;
  FRangeBar := TThemedRangeBar.Create(nil);
  FRangeBar.Kind := TScrollBarKind.sbVertical;
  FRangeBar.Color :=  StyleServices.GetStyleColor(scWindow);
  FRangeBar.HandleColor := StyleServices.GetStyleColor(scWindow);
  FRangeBar.ButtonColor := StyleServices.GetStyleColor(scBorder);
  FRangeBar.HighLightColor := StyleServices.GetStyleColor(scWindow);
  FRangeBar.ShadowColor := StyleServices.GetStyleColor(scWindow);
  FRangeBar.BorderColor := StyleServices.GetStyleColor(scBorder);
  FRangeBar.Style := rbsMac;
  FRangeBar.Width := 8;
  FRangeBar.BorderStyle := bsNone;
  FRangeBar.ShowArrows := False;
  FRangeBar.OnChange := OnScroll;
  FBitmap := Bm32ThemeGreate;
end;

destructor TGR32GraphicLegend.Destroy;
begin
  FBitmap.Free;
  FRangeBar.Free;
  inherited;
end;

function TGR32GraphicLegend.GetCaption: string;
begin
{$IFDEF ENG_VERSION}
  Result := 'Legend GR32'
{$ELSE}
  Result := 'Легенда GR32'
{$ENDIF}
end;

function TGR32GraphicLegend.GetCheckBoxRect(Par: TXScalableParam; nX: Integer = 0): TRect;
var
  y: Integer;
  p: TGraphPar;
begin
  y := -Round(FRangeBar.Position);
  for p in Column.Params do
    if p = Par then
      Exit(TRect.Create(TPoint.Create(nX * (CHECKBOX_SIZE + 1) + CHECKBOX_SIZE div 2, y + FBitmap.TextHeight(']') + 1 + Par.Width div 2 - CHECKBOX_SIZE div 2), CHECKBOX_SIZE, CHECKBOX_SIZE))
    else
      Inc(y, GetPatamHeight(p));
end;

function TGR32GraphicLegend.GetPatamHeight(p: TGraphPar): Integer;
begin
  Result := FBitmap.TextHeight('[') * 2;
  if p is TLineParam then
    Inc(Result, TLineParam(p).Width)
  else
    Inc(Result, 1);
end;

procedure TGR32GraphicLegend.OnScroll(Sender: TObject);
begin
  UpdateShowRect;
  Paint;
end;

procedure TGR32GraphicLegend.Paint;
begin
  if not Graph.Frosted and Graph.HandleAllocated and Column.Visible and Row.Visible then
    FBitmap.DrawTo(Graph.Canvas.Handle, FCanvasShowRect, FBitmapShowRect);
end;

procedure TGR32GraphicLegend.ParamCollectionChanged;
begin
  UpdateRange;
  FRangeBar.SetParams(FRange, ClientRect.Height);
  FRangeBar.Visible := Column.Visible and Row.Visible and (FRange > ClientRect.Height);
  UpdateShowRect;
  UpdateBitmapBaund;
  Render;
  Paint;
end;

procedure TGR32GraphicLegend.ParamPropChanged;
begin
  ParamCollectionChanged;
end;

procedure TGR32GraphicLegend.ParentFontChanged;
begin
  FBitmap.Font := Graph.Font;
  UpdateRange;
  Render;
  //Paint//?
end;

procedure TGR32GraphicLegend.Render;
var
  p: TGraphPar;
  Y: Integer;
begin
  FBitmap.FillRect(0, 0, FBitmap.Width, FBitmap.Height, Color32(StyleServices.GetStyleColor(scTreeView)));
  Y := 0;
  for p in Column.Params do
    if not p.HideInLegend then
    begin
      if p is TStringParam then
        RenderStringPatam(Y, TStringParam(p))
      else if p is TXScalableParam then
        RenderXscalePatam(Y, TXScalableParam(p));
      inc(Y, GetPatamHeight(p));
    end;
end;

procedure TGR32GraphicLegend.RenderXscalePatam(Y: Integer; p: TXScalableParam);
var
  CaptionX, LineY, ym, i: Integer;
  s: Tsize;
  AxisLabel: Double;
  posX: Double;
  Fpp2mm: Double;
begin
  Fpp2mm := Screen.PixelsPerInch / 2.54 * 2;
  s := FBitmap.TextExtent(p.Title);
  CaptionX := (FBitmap.Width - s.cx) div 2;
  if CaptionX < 0 then
    CaptionX := 0;
  // заголовок
  if p.EUnit <> '' then
    FBitmap.RenderText(CaptionX, Y, p.Title + '[' + p.EUnit + ']', 1, Color32(StyleServices.GetStyleFontColor(sfWindowTextNormal)))// p.Color)
  else
    FBitmap.RenderText(CaptionX, Y, p.Title, 1, Color32(StyleServices.GetStyleFontColor(sfWindowTextNormal))); //p.Color);
  // линия
  LineY := Y + s.cy + 1 + p.Width div 2;
  DrawLineParametr(FBitmap, p, [TFloatPoint.Create(0, LineY), TFloatPoint.Create(FBitmap.Width, LineY)]);
  // гамма если волна
  if (p is TWaveParam) and Assigned(FBitmap.bits) then
  begin
    for i := 0 to Min(255 div 4, FBitmap.Width - CHECKBOX_SIZE * 3) do
      FBitmap.VertLineTS(i + CHECKBOX_SIZE * 3, Y + s.cy - 6, Y + s.cy - 4, TWaveParam(p).Gamma[i * 4 - 128]);
  end;
  // риски и шкала
  posX := 0;
  AxisLabel := p.DeltaX;
  FBitmap.PenColor := p.Color;
  ym := LineY + p.Width div 2;
  while posX < FBitmap.Width do
  begin
    FBitmap.VertLineTS(Round(posX), ym, ym + 8, p.Color);
    FBitmap.RenderText(Round(posX), ym, Format('%-10.5g', [AxisLabel]), 1, Color32(StyleServices.GetStyleFontColor(sfWindowTextNormal))); //p.Color);
    posX := posX + Fpp2mm;
    AxisLabel := AxisLabel + 1.0 / p.ScaleX;
    if Abs(AxisLabel) < 0.0000001 then
      AxisLabel := 0;
  end;
  // CheckBox
  DrawCheckBox(FBitmap, LineY, p.Visible);
  DrawCheckBox(FBitmap, LineY, p.Selected, 1);
//  yl := y+GetPatamHeight(p);
//  FBitmap.HorzLineTS(0, yl, FBitmap.Width, clBlack32);
end;

procedure TGR32GraphicLegend.RenderStringPatam(Y: Integer; p: TStringParam);
begin
  FBitmap.PenColor := p.Color;
  FBitmap.Textout(0, Y, p.Title);
end;

procedure TGR32GraphicLegend.SetCaption(const Value: string);
begin

end;

procedure TGR32GraphicLegend.SetClientRect(const Value: TRect);
begin
  inherited;
  FRangeBar.SetBounds(Value.Right - FRangeBar.Width, Value.Top, FRangeBar.Width, Value.Height);
  if FRange = 0 then
    UpdateRange;
  FRangeBar.SetParams(FRange, Value.Height);
  FRangeBar.Visible := FRange > Value.Height;
  UpdateShowRect;
  UpdateBitmapBaund;
  Render;
  if not Assigned(FRangeBar.Parent) then
    FRangeBar.Parent := Graph;
end;

procedure TGR32GraphicLegend.SetVisible(Visible: Boolean);
begin
  FRangeBar.Visible := Column.Visible and Row.Visible and (FRange > FBitmapShowRect.Height);
end;

procedure TGR32GraphicLegend.MouseDown(Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
var
  p: TGraphPar;
  clPoint, point: TPoint;
begin
  point := Tpoint.Create(X, Y);
  clPoint := MouseToClient(point);
  if TryHitParametr(point, p, Button, Shift) and (p is TXScalableParam) then
  begin
    if GetCheckBoxRect(TXScalableParam(p)).contains(clPoint) then
      p.Visible := not p.Visible;
    if GetCheckBoxRect(TXScalableParam(p), 1).contains(clPoint) then
      p.Selected := not p.Selected;
  end;
end;

procedure TGR32GraphicLegend.MouseWheel(var Message: TCMMouseWheel);
begin
  FRangeBar.DoMouseWheel(Message.ShiftState, Message.WheelDelta, Message.Pos)
end;

function TGR32GraphicLegend.TryHitParametr(pos: TPoint; out Par: TGraphPar; Button: TMouseButton = TMouseButton.mbLeft; Shift: TShiftState = []): Boolean;
var
  p: TGraphPar;
  top, ht: Integer;
  clPoint: TPoint;
begin
  top := -Round(FRangeBar.Position);
  clPoint := MouseToClient(pos);
  for p in Column.Params do
  begin
    ht := GetPatamHeight(p);
    if (clPoint.Y > top) and (clPoint.Y < top + ht) then
    begin
      Par := p;
      Exit(True);
    end;
    Inc(top, ht);
  end;
  Result := False;
end;

procedure TGR32GraphicLegend.UpdateBitmapBaund;
begin
  if FRange > FBitmapShowRect.Height then
    FBitmap.SetSize(FBitmapShowRect.Width, FRange)
  else
    FBitmap.SetSize(FBitmapShowRect.Width, FBitmapShowRect.Height)
end;

procedure TGR32GraphicLegend.UpdateRange;
var
  p: TGraphPar;
begin
  FRange := 0;
  for p in Column.Params do
    if not p.HideInLegend then
      Inc(FRange, GetPatamHeight(p));
end;

procedure TGR32GraphicLegend.UpdateShowRect;
var
  origin: TPoint;
begin
  FCanvasShowRect := ClientRect;
  if FRangeBar.Visible then
    FCanvasShowRect.Width := FCanvasShowRect.Width - FRangeBar.Width;
  FBitmapShowRect := FCanvasShowRect;
  origin.X := 0;
  origin.Y := 0;
  if FRangeBar.Position <= FRange - FBitmapShowRect.Height then
    origin.Y := Round(FRangeBar.Position)
  else if FRange - FBitmapShowRect.Height >= 0 then
    origin.Y := FRange - FBitmapShowRect.Height;
  FBitmapShowRect := TRect.Create(origin, FCanvasShowRect.Width, FCanvasShowRect.Height);
end;
{$ENDREGION}

initialization
  TGraphRegion.RegClsRegister(TGR32GraphicLegend, TGR32LegendRow, TGR32GraphicCollumn);
  RegisterClasses([TGR32GraphicLegend]);
end.

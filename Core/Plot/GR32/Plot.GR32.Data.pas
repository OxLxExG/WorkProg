unit Plot.GR32.Data;

interface

{$INCLUDE global.inc}


uses CustomPlot.DataLink, Plot.GR32.Tools,
  System.SysUtils, System.Classes, System.Types, System.UITypes, ExtendIntf, Vcl.Forms,
  Plot.DtLink, Vcl.Graphics, Vcl.Themes, Winapi.Windows, Winapi.Messages,
  System.Math, GR32_Math, GR32, GR32_Image, GR32_RangeBars, GR32_Blend, Controls,
  GR32_Polygons, GR32_Resamplers, GR32_VectorUtils, GR32_Geometry, RootImpl,
  Container, tools, JDtools, debug_except, CustomPlot;


type
{$REGION 'Отрисовка данных'}

  TGR32GraphicData = class;

  IParamMouseEdit = interface
    procedure DoMouseMove(X, Y: Integer);
    procedure DoMouseUp(X, Y: Integer);
  end;

  TWaveParamBuffer = class(TIObject)
    Bitmap: TBitmap32;
    constructor Create;
    destructor Destroy; override;
  end;

  TWaveShowGraph = class(TIObject, IParamMouseEdit)
    Owner: TGR32GraphicData;
    Bitmap: TBitmap32;
    constructor Create(AOwner: TGR32GraphicData; Y: Integer);
    destructor Destroy; override;
    procedure DoMouseMove(X, Y: Integer);
    procedure DoMouseUp(X, Y: Integer);
  end;

  {$REGION 'lines'}

  TLineParamBuffer = class(TIObject)
    Points: TArrayOfFloatPoint;
    LastPoint: TFloatPoint;
    DashOffset: TFloat;
    LastOffset: TFloat;
    procedure UpdateDashOffset;
  end;

  /// скроллинг мышкой
  TScrollMouseData = class(TIObject, IParamMouseEdit)
    Owner: TGR32GraphicData;
    YBegin: Integer;
    const
      MRTOINT: array[Boolean] of Integer = (-1, 1);
    constructor Create(AOwner: TGR32GraphicData; Y: Integer);
    procedure DoMouseMove(X, Y: Integer);
    procedure DoMouseUp(X, Y: Integer);
  end;
  /// корневой класс для ркдактирования линий

  TLineParamMouseEdit = class(TIObject, IParamMouseEdit)
    Owner: TGR32GraphicData;
    Param: TLineParam;
    XBegin: Integer;
    Points: TArrayOfFloatPoint;
    const
      PPMMDELTA = 1 / 4;
    constructor Create(AOwner: TGR32GraphicData; Par: TGraphPar; X: Integer); virtual;
    procedure DoMouseMove(X, Y: Integer); virtual; abstract;
    procedure DoMouseUp(X, Y: Integer); virtual; abstract;
  end;
  /// сдвигание линии

  TLineParamMouseMove = class(TLineParamMouseEdit)
    KSumm: Integer;
    procedure DoMouseMove(X, Y: Integer); override;
    procedure DoMouseUp(X, Y: Integer); override;
  end;
  /// масштабирование линии по Х

  TLineParamMouseScale = class(TLineParamMouseEdit)
    XMiddle: Double;
    KDeltaOLD: Integer;
    KScale: Double;
    Delta: Single;
    Origin: TArray<Single>;
    const
      PPMMSCALE = 1 / 10;
    constructor Create(AOwner: TGR32GraphicData; Par: TGraphPar; X: Integer); override;
    procedure DoMouseMove(X, Y: Integer); override;
    procedure DoMouseUp(X, Y: Integer); override;
  end;

{$ENDREGION lines}

  TGR32GraphicData = class(TGR32Region, ICaption)
    const
      ACL_AXIS = $F0A8A8A8;
      ACL_AXIS_LABEL = clBlack32;
  private
    FParamMouseEdit: IParamMouseEdit;
    FLastHitWaveParametrs: Tarray<TWaveParam>;
    FShowRect: TRect;
    FBitmap: TBitmap32;
    FPropertyChanged: string;
    FRenderNeeded: Boolean;
    FShowYlegend: boolean;
    procedure SetPropertyChanged(const Value: string);
    procedure Render(UpdateBuffers: Boolean = True);
    procedure SetShowYlegend(const Value: boolean);
  protected
    function GetCaption: string;
    procedure SetCaption(const Value: string);
    function GetCursor: Integer; override;
    procedure DrowAxis();
    procedure MouseDown(Button: TMouseButton; Shift: TShiftState; X, Y: Integer); override;
    procedure MouseMove(Shift: TShiftState; X, Y: Integer); override;
    procedure MouseUp(Button: TMouseButton; Shift: TShiftState; X, Y: Integer); override;
    procedure SetClientRect(const Value: TRect); override;
    procedure ParamCollectionChanged; override;
    procedure ParamPropChanged; override;
    procedure ParentFontChanged; override;
    procedure Paint; override;
  public
    constructor Create(Collection: TCollection); override;
    destructor Destroy; override;
    function TryHitParametr(pos: TPoint; out Par: TGraphPar; Button: TMouseButton = TMouseButton.mbLeft; Shift: TShiftState = []): Boolean; override;
    property Bitmap: TBitmap32 read FBitmap;
    property C_PropertyChanged: string read FPropertyChanged write SetPropertyChanged;
  published
    [ShowProp('Labels axis Y')]
    property ShowYlegend: boolean read FShowYlegend write SetShowYlegend default True;
  end;
{$ENDREGION 'Отрисовка данных'}


implementation



{$REGION 'TGR32GraphicData'}

{ TLineParamMouseEdit TLineParamMouseMove, TLineParamMouseScale TScrollMouseData }

constructor TScrollMouseData.Create(AOwner: TGR32GraphicData; Y: Integer);
begin
  Owner := AOwner;
  YBegin := Y;
  SetCursor(Screen.Cursors[crHandPoint])
end;

procedure TScrollMouseData.DoMouseMove(X, Y: Integer);
var
  k: Double;
begin
  if Y <> YBegin then
    with Owner.Graph do
    begin
      k := YScale * (Screen.PixelsPerInch / 2.54 * 2) * MRTOINT[YMirror];
      YPosition := YPosition + (Y - YBegin) / k;
      YBegin := Y;
    end;
end;

procedure TScrollMouseData.DoMouseUp(X, Y: Integer);
begin
end;

constructor TLineParamMouseEdit.Create(AOwner: TGR32GraphicData; Par: TGraphPar; X: Integer);
begin
  Owner := AOwner;
  Param := TLineParam(Par);
  XBegin := X;
  points := TLineParamBuffer((Param as ILineDataLink).DrowMemoryBuffer).points;
end;

constructor TLineParamMouseScale.Create(AOwner: TGR32GraphicData; Par: TGraphPar; X: Integer);
var
  I: Integer;
begin
  inherited;
  XMiddle := 0;
  SetLength(origin, Length(points));
  for I := 0 to High(points) do
  begin
    XMiddle := XMiddle + points[I].X;
    origin[I] := points[I].X;
  end;
  XMiddle := XMiddle / Length(points);
  KScale := 1;
end;

procedure TLineParamMouseMove.DoMouseMove(X, Y: Integer);
var
  Delta: Single;
  k, i: Integer;
  ppmm: Double;
begin
  ppmm := Screen.PixelsPerInch / 2.54 * 2 * PPMMDELTA;
  k := Trunc((X - XBegin) / ppmm);
  if Abs(k) > 0 then
  begin
    Delta := k * ppmm;
    for i := 0 to Length(points) - 1 do
      points[i].X := points[i].X + Delta;
    XBegin := X;
    inc(KSumm, k);
    Owner.Render(False);
    Owner.Paint;
  end;
end;

procedure TLineParamMouseScale.DoMouseMove(X, Y: Integer);
var
  k, i: Integer;
  ppmm: Double;
begin
  ppmm := Screen.PixelsPerInch / 2.54 * 2 * PPMMDELTA;
  k := Min(Max(Low(SCALE_PRESET_MOUSE), Trunc((X - XBegin) / ppmm)), High(SCALE_PRESET_MOUSE));
  if Abs(KDeltaOLD - k) > 0 then
  begin
    KDeltaOLD := k;
    KScale := SCALE_PRESET_MOUSE[k];
   /// Формулы в блонноте (Экран проект 3)
    Delta := XMiddle / KScale - XMiddle;
    for i := 0 to Length(points) - 1 do
      points[i].X := (origin[i] + Delta) * KScale;
    Owner.Render(False);
    Owner.Paint;
  end;
end;

procedure TLineParamMouseScale.DoMouseUp(X, Y: Integer);
var
  pp2mm: Double;
//  I: Integer;
begin
  pp2mm := Screen.PixelsPerInch / 2.54 * 2;
  Owner.Graph.Frost;
  try
   /// Формулы в блонноте (Экран проект 3)
    Param.DeltaX := Param.DeltaX - Delta / Param.ScaleX / pp2mm;
    Param.ScaleX := FindBestScale(Param.ScaleX * KScale);
    Param.DeltaX := Round(Param.DeltaX * Param.ScaleX) / Param.ScaleX;
  finally
    Owner.Graph.DeFrost;
  end;
end;

procedure TLineParamMouseMove.DoMouseUp(X, Y: Integer);
begin
  Param.DeltaX := Param.DeltaX - KSumm * PPMMDELTA / Param.ScaleX;
end;

{ TWaveShowGraph }

constructor TWaveShowGraph.Create(AOwner: TGR32GraphicData; Y: Integer);
begin
  Owner := AOwner;
  Bitmap := Bm32ThemeGreate;
  Bitmap.Assign(Owner.FBitmap);
  DoMouseMove(0, Y);
end;

destructor TWaveShowGraph.Destroy;
begin
  Bitmap.Free;
  inherited;
end;

procedure TWaveShowGraph.DoMouseMove(X, Y: Integer);
var
  p: TWaveParam;
  pntrs: TArrayOfFloatPoint;
  pss: IWaveDataLink;
  YFrom, Yold: Single;
  pp2mm: Double;
  Ye: Integer;
begin
  pp2mm := Screen.PixelsPerInch / 2.54 * 2;

  Y := Owner.MouseToClient(Tpoint.Create(X, Y)).Y;

  Owner.FBitmap.Assign(Bitmap);
  for p in Owner.FLastHitWaveParametrs do
    if Supports(p, IWaveDataLink, pss) then
    begin
      YFrom := Owner.Graph.YTopScreen - p.DeltaY + Y / (pp2mm * Owner.Graph.YScale);
      Yold := Single.MaxValue;
      SetLength(pntrs, 0);
      pss.Read(YFrom, YFrom, TWaveParam(p).ZeroGamma, TWaveParam(p).KoeffGamma,
        procedure(Y: Single; const X: TArray<ShortInt>)
        var
          i: Integer;
        begin
          if abs(YFrom - Y) < Yold then
          begin
            Yold := Y;
            Ye := Round(pp2mm * Owner.Graph.YScale * (-Owner.Graph.YTopScreen + p.DeltaY + Yold));
            SetLength(pntrs, Length(X));
            for i := 0 to Length(pntrs) - 1 do
            begin
              pntrs[i].X := (i - p.DeltaX) * pp2mm * p.ScaleX;
//              pntrs[i].Y := Ye - X[i];
              pntrs[i].Y := Ye + X[i];
            end;
          end;
        end);
      if Length(pntrs) > 0 then
      begin
        pntrs := VertexReduction(pntrs);
        DrawLineParametr(Owner.FBitmap, p, pntrs);
        DrawLineParametr(Owner.FBitmap, clBlack32, [TfloatPoint.Create(0, Ye), TfloatPoint.Create(owner.ClientRect.Width, Ye)]);
      end;
    end;
  Owner.Paint;
end;

procedure TWaveShowGraph.DoMouseUp(X, Y: Integer);
begin
  Owner.FBitmap.Assign(Bitmap);
  Owner.Paint;
end;

{ TGR32GraphicData }

constructor TGR32GraphicData.Create(Collection: TCollection);
begin
  inherited;
  FShowYlegend := True;
  FBitmap := Bm32ThemeGreate;
  TBindHelper.Bind(Self, 'C_PropertyChanged', Graph as IInterface, ['S_PropertyChanged']);
end;

destructor TGR32GraphicData.Destroy;
begin
  TBindHelper.RemoveExpressions(Self);
  FBitmap.Free;
  inherited;
end;

procedure TGR32GraphicData.DrowAxis();
var
  pp2mm: Double;
  x, y, ylb: Double;
  m: Integer;

  function nextAxis(var a: Double): Integer;
  begin
    a := a + pp2mm;
    Result := Round(a);
  end;

  function YtoBitmap(Ypos: Double): Integer;
  var
    pos: Double;
  begin
    pos := Ypos - Graph.YTopScreen;
    pos := pos * pp2mm * Graph.YScale;
    Result := Round(pos);
  end;

begin
  pp2mm := Screen.PixelsPerInch / 2.54 * 2;
  if Graph.YMirror then
    m := -1
  else
    m := 1;
  x := 0;
  while x < FBitmap.Width do
    FBitmap.VertLineTS(nextAxis(x), 0, FBitmap.Height, ACL_AXIS);
  ylb := Trunc(Graph.YTopScreen * Graph.YScale) / Graph.YScale; // ceil mirror ????
  y := m * YtoBitmap(ylb); { TODO : write function }
  while y < FBitmap.Height do
  begin
    FBitmap.HorzLineTS(0, Round(y), FBitmap.Width, ACL_AXIS);
    if FShowYlegend then
      FBitmap.RenderText(0, Round(y), FloatToStr(SimpleRoundTo(ylb, -4)), 1, Color32(StyleServices.GetStyleFontColor(sfWindowTextNormal)));
    ylb := ylb + m / Graph.YScale;
    y := y + pp2mm;
  end;
end;

function TGR32GraphicData.GetCaption: string;
begin
{$IFDEF ENG_VERSION}
  Result := 'Diagramas GR32'
{$ELSE}
  Result := 'Графики GR32'
{$ENDIF}
end;

function TGR32GraphicData.GetCursor: Integer;
begin
  Result := crCross;
end;

procedure TGR32GraphicData.MouseDown(Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
var
  p: TGraphPar;
begin
  if TryHitParametr(TPoint.Create(X, Y), p, Button, Shift) then
    if p is TLineParam then
      if ssShift in Shift then
        FParamMouseEdit := TLineParamMouseScale.Create(Self, p, X)
      else
        FParamMouseEdit := TLineParamMouseMove.Create(Self, p, X)
    else
    begin
      if p is TWaveParam then
        FParamMouseEdit := TWaveShowGraph.Create(Self, Y)
    end
  else
    FParamMouseEdit := TScrollMouseData.Create(Self, Y)
end;

procedure TGR32GraphicData.MouseMove(Shift: TShiftState; X, Y: Integer);
begin
  if Assigned(FParamMouseEdit) then
    FParamMouseEdit.DoMouseMove(X, Y);
end;

procedure TGR32GraphicData.MouseUp(Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
begin
  if Assigned(FParamMouseEdit) then
    FParamMouseEdit.DoMouseUp(X, Y);
  FParamMouseEdit := nil;
end;

procedure TGR32GraphicData.Paint;
begin
  if Graph.Frosted then
    Exit;
  if FRenderNeeded then
    Render();
  if Column.Visible and Row.Visible then
    FBitmap.DrawTo(Graph.Canvas.Handle, ClientRect, FShowRect);
   Tdebug.Log('------- TGR32GraphicData.Paint -----------');
end;

procedure TGR32GraphicData.ParamCollectionChanged;
begin
  Render;
  Paint;
end;

procedure TGR32GraphicData.ParamPropChanged;
begin
  Render;
  Paint;
end;

procedure TGR32GraphicData.ParentFontChanged;
begin
end;

procedure TGR32GraphicData.Render(UpdateBuffers: Boolean = True);
var
  pp2mm: Single;

  procedure RenderWaveparams;
  var
    p: TGraphPar;
    pss: IWaveDataLink;
 // экран:
 // экран       отображение БД  пересечение
 //
    {ScreenRect,}     DstRect{,        ClipDstRect}: TRect;
 // БД:
 // отображение экранa   Реальные данные    пересечение
 //
    {BDScreenRect,}            BDSrcRect        {, ClipSrcRect}: TRect;
 /// 1. находим ScreenRect - clientRect регионa данных это есть FBitmap.BoundsRect
 /// 2. находим BDSrcRect - Реальные данные Х-[0..ArraySize] Y-ближайшие реальные  данные от BDScreenRect
 /// 3. находим BDScreenRect - отобрадение в буффере ScreenRect => BDScreenRect
 /// 4. находим пересечение ClipSrcRect = BDScreenRect & BDSrcRect это будет источник
 /// 5  находим обратное оотображение в экран DstRect  ClipSrcRect => DstRect
 /// 6. находим пересечение ClipDstRect = ScreenRect & DstRect это будет приемник
 /// 6а. Если все правильно то действие 6. не нужно ClipDstRect == DstRect
 ///        вариант II
 /// 1. находим ScreenRect - это есть clientRect регионa данных ЭТО БУДЕТ DSTCLIPRECT !!!
 /// 2. по YTopScreen YButtomScreen находим ближайшие реальные (ВНЕ!!! или внутри экрана) Y0 Y1  Ytop Ybot находим BDSrcRect - Реальные данные Х-[0..ArraySize]
 /// 3. находим обратное оотображение в экран DstRect  BDSrcRect => DstRect это будет приемник
    Src: TBitmap32;
    ky, kx: Single;
    X0, X1, Y0, Y1, indx: Integer;
    Ytop, Ybot: Double;
  begin
    for p in Column.Params do
      if p.Visible and (p is TWaveParam) and Supports(p, IWaveDataLink, pss) then
      begin
        if not Assigned(pss.DrowMemoryBuffer) then
        begin
          pss.DrowMemoryBuffer := TWaveParamBuffer.Create;
          TWaveParamBuffer(pss.DrowMemoryBuffer).Bitmap.SetSize(pss.ArrayCount, pss.RecordCount);
        end;
        Src := TWaveParamBuffer(pss.DrowMemoryBuffer).Bitmap;
        Src.SetSize(pss.ArrayCount, pss.RecordCount);

      /// 2. находим BDSrcRect - Реальные данные Х-[0..ArraySize] Y-ближайшие реальные (вне экрана) данные от BDScreenRect
        Y0 := pss.IndexOfY(p.Graph.YTopScreen - p.DeltaY, fndLower, Ytop);
        Y1 := pss.IndexOfY(p.Graph.YButtomScreen - p.DeltaY, fndHiger, Ybot);
        BDSrcRect := TRect.Create(0, Y0, pss.ArrayCount, Y1);
      /// 3. находим обратное оотображение BDSrcRect в экран
        ky := p.Graph.YScale * pp2mm;
        kx := TWaveParam(p).ScaleX * pp2mm;
        X0 := Round((0 - p.DeltaX) * kx);
        X1 := Round((pss.ArrayCount - p.DeltaX) * kx);
        Y0 := Round((Ytop - p.Graph.YTopScreen + p.DeltaY) * ky);
        Y1 := Round((Ybot - p.Graph.YTopScreen + p.DeltaY) * ky);
        DstRect := TRect.Create(X0, Y0, X1, Y1);

        if DstRect.IsEmpty or BDSrcRect.IsEmpty then Exit;

        if UpdateBuffers { TODO : AND paramApdateGamma changed: ZeroGamma, KoeffGamma, Gamma} then
        begin
          indx := 0;
          pss.Read(TWaveParam(p).ZeroGamma, TWaveParam(p).KoeffGamma,
            procedure(Y: Single; const X: TArray<ShortInt>)
            var
              i: Integer;
            begin
              for i := 0 to Length(X) - 1 do
                Src.Pixel[i, indx] := TColor32(TWaveParam(p).Gamma[X[i]]);
              inc(indx);
            end);
        end;
   //    TDebug.Log('  %d    %d    ',[SrcRect.Width, SrcRect.Height]);
                                             // Destination Data     clip
        if not BDSrcRect.IsEmpty then
          StretchTransfer(FBitmap, DstRect, FBitmap.BoundsRect,
                                                   // Src
            Src, BDSrcRect,
                                                   // resamplers
            Src.Resampler,
                                                   // drow mode
            dmBlend, Src.OnPixelCombine);
      end;
  end;

  procedure RenderLineparams;
  var
    p: TGraphPar;
    pss: ILineDataLink;
    dx, dy, ky, kx: Single;
    i, cnt: Integer;
    fp: TFloatPoint;
  begin
    for p in Column.Params do
      if p.Visible and (p is TLineParam) and Supports(p, ILineDataLink, pss) then
      begin
     // создание буфера
        if not Assigned(pss.DrowMemoryBuffer) then
          pss.DrowMemoryBuffer := TLineParamBuffer.Create;
        with TLineParamBuffer(pss.DrowMemoryBuffer) do
        begin
          if UpdateBuffers then
          begin
          // подготовка буфера чтение из БД буфера фильтра
            SetLength(points, 0);
            ky := p.Graph.YScale * pp2mm;
            kx := TLineParam(p).ScaleX * pp2mm;
            // чтение из БД
            pss.Read(Min(p.Graph.YTopScreen, p.Graph.YButtomScreen) - p.DeltaY, Max(p.Graph.YTopScreen, p.Graph.YButtomScreen) - p.DeltaY,
              procedure(Y: Single; const X: Single)
              begin
                if not X.IsNan and not Y.IsNan and (Abs(X) < 10000000) and (Abs(Y) < 10000000) then
                  points := points + [TFloatPoint.Create(X * kx, Y * ky)];
              end);
           // удаление лишних точек
            if Length(points) > 100 then
              points := VertexReduction(points);
            if TXScalableParam(p).DashStyle <> ldsSolid then UpdateDashOffset();
            dx := p.DeltaX * kx;
            dy := (-p.Graph.YTopScreen + p.DeltaY) * ky;
            cnt := Length(points);
            if p.Graph.YMirror then
            begin
              if odd(cnt) then
              begin
                points[cnt div 2].X := points[cnt div 2].X - dx;
                points[cnt div 2].Y := -(points[cnt div 2].Y + dy);
              end;
              for i := 0 to cnt div 2 - 1 do
              begin
                fp := points[i];
                points[i].X := points[cnt - 1 - i].X - dx;
                points[i].Y := -(points[cnt - 1 - i].Y + dy);
                points[cnt - 1 - i].X := fp.X - dx;
                points[cnt - 1 - i].Y := -(fp.Y + dy);
              end
            end
            else
              for i := 0 to cnt - 1 do
              begin
                points[i].X := points[i].X - dx;
                points[i].Y := points[i].Y + dy;
              end;
            for i := 0 to cnt - 1 do
            begin
              if points[i].X > p.Column.Width + 10 then
                points[i].X := p.Column.Width + 10
              else if points[i].X < -10 then
                points[i].X := -10;
            end;
          end;
       // рендеринг
          if Length(points) > 1 then
            DrawLineParametr(FBitmap, TLineParam(p), points, DashOffset);
        end;
      end;
  end;

begin
  if Graph.Frosted then
  begin
    FRenderNeeded := True;
    Exit;
  end;
  FRenderNeeded := False;
  pp2mm := Screen.PixelsPerInch / 2.54 * 2;
  FBitmap.FillRect(0, 0, FBitmap.Width, FBitmap.Height,Color32(StyleServices.GetStyleColor(scTreeView)));
  RenderWaveparams;
  RenderLineparams; //
  DrowAxis;
end;

procedure TGR32GraphicData.SetCaption(const Value: string);
begin

end;

procedure TGR32GraphicData.SetClientRect(const Value: TRect);
begin
  inherited;
  FBitmap.SetSize(Value.Width, Value.Height);
  FShowRect := FBitmap.BoundsRect;
  Render;
  Paint;
end;

procedure TGR32GraphicData.SetPropertyChanged(const Value: string);
begin
  FPropertyChanged := Value;
  if Value = 'Screen' then
  begin
    Render;
    Paint;
  end;
end;

procedure TGR32GraphicData.SetShowYlegend(const Value: boolean);
begin
  FShowYlegend := Value;
  Render(False);
  Paint;
end;

function TGR32GraphicData.TryHitParametr(pos: TPoint; out Par: TGraphPar; Button: TMouseButton = TMouseButton.mbLeft; Shift: TShiftState = []): Boolean;
var
  p: TGraphPar;
  clPoint: TFloatPoint;
  Dist, delta: TFloat;
begin
  clPoint := TFloatPoint.Create(MouseToClient(pos));
  Result := False;
  SetLength(FLastHitWaveParametrs, 0);
  for p in Column.Params do
    if p.Visible then
    begin
      if p is TLineParam then
        with TLineParamBuffer((p as ILineDataLink).DrowMemoryBuffer) do
        begin
          delta := TLineParam(p).Width + 2;
          Dist := DistanceFromPointToCurve(clPoint, points);
          if Dist < delta then
          begin
            Par := p;
            Exit(True);
          end;
        end
      else if (ssCtrl in Shift) and (p is TWaveParam) and p.Selected then
      begin
        CArray.Add<TWaveParam>(FLastHitWaveParametrs, TWaveParam(p));
        Par := p;
        Result := True;
      end;
    end;
end;

{$ENDREGION}

{ TWaveParamBuffer }

constructor TWaveParamBuffer.Create;
begin
  Bitmap := Bm32ThemeGreate;
end;

destructor TWaveParamBuffer.Destroy;
begin
  Bitmap.Free;
  inherited;
end;

{ TLineParamBuffer }

procedure TLineParamBuffer.UpdateDashOffset;
 var
  lp: TFloatPoint;
begin
  if (Length(Points) > 1) then
   begin
    if (LastPoint = Points[0]) then
     begin
      DashOffset := DashOffset + LastOffset;
      lp := Points[0] - Points[1];
      LastOffset := System.Math.Hypot(lp.X, lp.Y);
     end
    else
     begin
      DashOffset := 0;
      LastOffset := 0;
     end;
    LastPoint := Points[1];
   end;
end;

initialization
  TGraphRegion.RegClsRegister(TGR32GraphicData, TCustomGraphDataRow, TGR32GraphicCollumn);
  RegisterClasses([TGR32GraphicData]);
end.


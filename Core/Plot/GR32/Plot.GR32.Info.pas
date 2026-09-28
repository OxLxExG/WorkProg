unit Plot.GR32.Info;

interface

uses CustomPlot.DataLink, Plot.GR32.Tools,
  System.SysUtils, System.Classes, System.Types, System.UITypes, ExtendIntf, Vcl.Forms,
  Plot.DtLink, Vcl.Graphics, Vcl.Themes, Winapi.Windows, Winapi.Messages,
  System.Math, GR32_Math, GR32, GR32_Image, GR32_RangeBars, GR32_Blend, Controls,
  GR32_Polygons, GR32_Resamplers, GR32_VectorUtils, GR32_Geometry, RootImpl,
  Container, tools, JDtools, debug_except, CustomPlot;

{$REGION 'Отрисовка info'}
  type
  TThemedRangeBar = class(TCustomRangeBar);


  TGR32DataRow = class(TCustomGraphDataRow)
  protected
    procedure MouseMove(Shift: TShiftState; X, Y: Integer); override;
  end;


  TGR32GraphicInfo = class(TGR32Region, ICaption)
  private
    FCanvasShowRect: TRect;
    FbitmapShowRect: TRect;
    FCurY: TFloat;
    FBitmap: TBitmap32;
    procedure Render;
  protected
    function GetCaption: string;
    procedure SetCaption(const Value: string);
    procedure ParamCollectionChanged; override;
    procedure ParamPropChanged; override;
    procedure ParentFontChanged; override;
    procedure Paint; override;
    procedure SetClientRect(const Value: TRect); override;
  public
    procedure OnCurrentParamsEvent( Sender: TObject; Y: TFloat);
    constructor Create(Collection: TCollection); override;
    destructor Destroy; override;
  end;
{$ENDREGION 'Отрисовка легенды'}

implementation

uses Plot.GR32.Data;

{$REGION 'TGR32GraphicInfo'}

{ TGR32GraphicInfo }

constructor TGR32GraphicInfo.Create(Collection: TCollection);
begin
  inherited;
  FBitmap := Bm32ThemeGreate;
  for var r in Column.Regions do if r is TGR32GraphicData then
//  TGR32GraphicData(r).CurrentParamsEvent := OnCurrentParamsEvent;
end;

destructor TGR32GraphicInfo.Destroy;
begin
  FBitmap.Free;
  inherited;
end;

function TGR32GraphicInfo.GetCaption: string;
begin
{$IFDEF ENG_VERSION}
  Result := 'info GR32'
{$ELSE}
  Result := 'Информация GR32'
{$ENDIF}
end;

procedure TGR32GraphicInfo.OnCurrentParamsEvent(Sender: TObject; Y: TFloat);
begin
  FCurY := Y;
  Render;
  Paint;
end;

procedure TGR32GraphicInfo.Paint;
begin
  if not Graph.Frosted and Graph.HandleAllocated and Column.Visible and Row.Visible then
    FBitmap.DrawTo(Graph.Canvas.Handle, ClientRect, TRect.Create(TPoint.Create(0,0), ClientRect.Width, ClientRect.Height));
end;

procedure TGR32GraphicInfo.ParamCollectionChanged;
begin
  Render;
  Paint;
end;

procedure TGR32GraphicInfo.ParamPropChanged;
begin
  ParamCollectionChanged;
end;

procedure TGR32GraphicInfo.ParentFontChanged;
begin
  FBitmap.Font := Graph.Font;
  Render;
  //Paint//?
end;

//procedure TGR32GraphicInfo.Render;
//var
//  p: TGraphPar;
//  YFrom, pp2mm: Double;
//  pss: ILineDataLink;
//
//  // Переменные для автоматического расчета строк таблицы
//  CurrentX: Integer;
//  ValueStr: string;
//  HalfRowsCount: Integer;
//  CenterY: Integer;
//
//  const HeaderHeight = 20;    // Высота, зарезервированная под заголовки (в пикселях)
//  const RowHeight = 16;       // Высота одной строки текста
//  const FixedColWidth = 130;  // Фиксированная ширина колонки
//  const TextPadding = 4;      // Отступ внутри ячейки, чтобы текст не прилипал к границам
//begin
//  // 1. Очистка фона
//  FBitmap.FillRect(0, 0, FBitmap.Width, FBitmap.Height, Color32(StyleServices.GetStyleColor(scTreeView)));
//
//  // Вычисляем доступную высоту для данных (за вычетом шапки)
//  var AvailableHeight := FBitmap.Height - HeaderHeight;
//  if AvailableHeight <= RowHeight then Exit;
//
//  // Сколько строк поместится в половину оставшегося экрана от центра
//  HalfRowsCount := (AvailableHeight div RowHeight) div 2;
//
//  // Находим точную экранную координату Y для центральной (жирной) строки с учетом шапки
//  CenterY := HeaderHeight + (AvailableHeight div 2) - (RowHeight div 2);
//
//  pp2mm := Screen.PixelsPerInch / 2.54 * 2;
//  var SignY := if Graph.YMirror then -1 else 1;
//
//  // Базовые настройки шрифта и цветов
//  FBitmap.Font.Style := [];
//  var DefaultTextColor := TColor32(StyleServices.GetStyleFontColor(sfWindowTextNormal)) or $FF000000;
//
//  // --- ШАГ 1: ВЫВОД ЗАГОЛОВКА ПЕРВОЙ КОЛОНКИ ---
//  FBitmap.Font.Style := [fsBold];
//  FBitmap.RenderText(0, 0, 'FromY', DefaultTextColor, True);
//  FBitmap.Font.Style := [];
//
//  // Смещение для последующих колонок параметров
//  CurrentX := FixedColWidth;
//
//  // Флаг, чтобы рассчитать и вывести колонку FromY только ОДИН раз
//  var FromYRendered := False;
//
//  // --- ШАГ 2: ЦИКЛ ПО КОЛОНКАМ ПАРАМЕТРОВ ---
//  for p in Column.Params do
//  begin
//    if (FCurY >= 0) and (p is TLineParam) and p.Visible and p.Selected and Supports(p, ILineDataLink, pss) and Assigned(pss.DrowMemoryBuffer) then
//    begin
//      var Buffer := TLineParamBuffer(pss.DrowMemoryBuffer);
//      var PointsCount := Length(Buffer.points);
//      if PointsCount = 0 then Continue;
//
//      var deltaOld := Single.MaxValue;
//      var Bestidx := 0;
//
//      // Поиск индекса ближайшей центральной точки (Bestidx) по FCurY
//      for var i := 0 to PointsCount - 1 do
//      begin
//        var pn := Buffer.points[i];
//        var delta := abs(FCurY - pn.Y);
//        if delta < deltaOld then
//        begin
//          deltaOld := delta;
//          Bestidx := i;
//        end;
//      end;
//
//      var lp := TLineParam(p);
//      var TextColor := TColor32(p.Color) or $FF000000;
//
//// --- ОБРЕЗКА ДЛИННОГО ЗАГОЛОВКА С НАЧАЛА С ТРОЕТОЧИЕМ ---
//      var OriginalTitle := p.Title;
//      var TrimmedTitle := OriginalTitle;
//      FBitmap.Font.Style := [fsBold]; // Включаем Bold перед замером
//
//      // Максимальная ширина текста внутри колонки с учетом отступов
//      var MaxTextWidth := FixedColWidth - (TextPadding * 2);
//
//      // Если исходный заголовок изначально не помещается в колонку
//      if FBitmap.TextWidth(OriginalTitle) > MaxTextWidth then
//      begin
//        // Отсекаем по одному символу слева, проверяя длину строки ВМЕСТЕ с троеточием
//        while (TrimmedTitle <> '') and (FBitmap.TextWidth('...' + TrimmedTitle) > MaxTextWidth) do
//        begin
//          Delete(TrimmedTitle, 1, 1);
//        end;
//
//        // Если что-то осталось, собираем финальную строку с троеточием
//        if TrimmedTitle <> '' then
//          TrimmedTitle := '...' + TrimmedTitle
//        else
//          TrimmedTitle := '...'; // На случай экстремально узкой колонки
//      end;
//      // Выводим (возможно, обзанный) заголовок параметра (Строка 1, Y = 0)
//      FBitmap.RenderText(CurrentX, 0, TrimmedTitle, TextColor, True);
//      FBitmap.Font.Style := [];
//
//      // Вывод строк данных от -HalfRowsCount до +HalfRowsCount
//      for var OffsetY := -HalfRowsCount to HalfRowsCount do
//      begin
//        var CurrentIdx := Bestidx + OffsetY;
//
//        if (CurrentIdx >= 0) and (CurrentIdx < PointsCount) then
//        begin
//          var CurrentPoint := Buffer.points[CurrentIdx];
//          var ScreenY := CenterY + (OffsetY * RowHeight);
//
//          if ScreenY < HeaderHeight then Continue; // Не затираем заголовок
//
//          // А) Вывод значений FromY для этой строки
//          if not FromYRendered then
//          begin
//            YFrom := Graph.YTopScreen + SignY * CurrentPoint.Y / (pp2mm * Graph.YScale);
//            ValueStr := FloatToStr(Round(YFrom));
//
//            if OffsetY = 0 then
//            begin
//              FBitmap.Font.Style := [fsBold];
//              FBitmap.RenderText(0, ScreenY, ValueStr, DefaultTextColor, True);
//              FBitmap.Font.Style := [];
//            end
//            else
//            begin
//              FBitmap.RenderText(0, ScreenY, ValueStr, DefaultTextColor, True);
//            end;
//          end;
//
//          // Б) Вывод значений X для текущего параметра
//          ValueStr := Format('%.'+lp.Presizion.ToString+'f', [CurrentPoint.X / (lp.ScaleX * pp2mm) + lp.DeltaX]);
//
//          if OffsetY = 0 then
//          begin
//            FBitmap.Font.Style := [fsBold];
//            FBitmap.RenderText(CurrentX, ScreenY, ValueStr, TextColor, True);
//            FBitmap.Font.Style := [];
//          end
//          else
//          begin
//            FBitmap.RenderText(CurrentX, ScreenY, ValueStr, TextColor, True);
//          end;
//        end;
//      end;
//
//      // После обработки первого параметра колонка FromY полностью заполнена для всех строк
//      FromYRendered := True;
//
//      // Сдвиг к следующей фиксированной позиции по горизонтали
//      Inc(CurrentX, FixedColWidth);
//    end;
//  end;
//end;
//procedure TGR32GraphicInfo.Render;
//var
//  p: TGraphPar;
//  YFrom, pp2mm: Double;
//  pss: ILineDataLink;
//
//  // Переменные для автоматического расчета строк таблицы
//  CurrentX: Integer;
//  ValueStr: string;
//  HalfRowsCount: Integer;
//  CenterY: Integer;
//
//  const ACL_AXIS = $F0A8A8A8; // Константа цвета сетки
//  const HeaderHeight = 20;    // Высота, зарезервированная под заголовки
//  const RowHeight = 16;       // Высота одной строки текста
//  const FixedColWidth = 130;  // Фиксированная ширина колонки
//  const TextPadding = 4;      // Отступ внутри ячейки
//begin
//  // 1. Очистка фона
//  FBitmap.FillRect(0, 0, FBitmap.Width, FBitmap.Height, Color32(StyleServices.GetStyleColor(scTreeView)));
//
//  // Вычисляем доступную высоту для данных (за вычетом шапки)
//  var AvailableHeight := FBitmap.Height - HeaderHeight;
//  if AvailableHeight <= RowHeight then Exit;
//
//  // Сколько строк поместится в половину оставшегося экрана от центра
//  HalfRowsCount := (AvailableHeight div RowHeight) div 2;
//
//  // Находим точную экранную координату Y для центральной (жирной) строки с учетом шапки
//  CenterY := HeaderHeight + (AvailableHeight div 2) - (RowHeight div 2);
//
//  pp2mm := Screen.PixelsPerInch / 2.54 * 2;
//  var SignY := if Graph.YMirror then -1 else 1;
//
//  // Базовые настройки шрифта и цветов
//  FBitmap.Font.Style := [];
//  var DefaultTextColor := TColor32(StyleServices.GetStyleFontColor(sfWindowTextNormal)) or $FF000000;
//
//  // --- ШАГ 1: ВЫВОД ЗАГОЛОВКА ПЕРВОЙ КОЛОНКИ ---
//  FBitmap.Font.Style := [fsBold];
//  FBitmap.RenderText(TextPadding, 0, 'FromY', DefaultTextColor, True);
//  FBitmap.Font.Style := [];
//
//  // Смещение для последующих колонок параметров
//  CurrentX := FixedColWidth;
//
//  // Флаг, чтобы рассчитать и вывести колонку FromY только ОДИН раз
//  var FromYRendered := False;
//
//  // --- ШАГ 2: ЦИКЛ ПО КОЛОНКАМ ПАРАМЕТРОВ ---
//  for p in Column.Params do
//  begin
//    if (FCurY >= 0) and (p is TXScalableParam) and Supports(p, ILineDataLink, pss) and Assigned(pss.DrowMemoryBuffer) then
//    begin
//      var Buffer := TLineParamBuffer(pss.DrowMemoryBuffer);
//      var PointsCount := Length(Buffer.points);
//      if PointsCount = 0 then Continue;
//
//      var deltaOld := Single.MaxValue;
//      var Bestidx := 0;
//
//      // Поиск индекса ближайшей центральной точки (Bestidx) по FCurY
//      for var i := 0 to PointsCount - 1 do
//      begin
//        var pn := Buffer.points[i];
//        var delta := abs(FCurY - pn.Y);
//        if delta < deltaOld then
//        begin
//          deltaOld := delta;
//          Bestidx := i;
//        end;
//      end;
//
//      var lp := TXScalableParam(p);
//      var TextColor := TColor32(p.Color) or $FF000000;
//
//      // Рисуем ВЕРТИКАЛЬНУЮ линию сетки слева от текущей колонки параметров через VertLineTS
//      FBitmap.VertLineTS(CurrentX, 0, FBitmap.Height, ACL_AXIS);
//
//      // --- ОБРЕЗКА ДЛИННОГО ЗАГОЛОВКА С НАЧАЛА С ТРОЕТОЧИЕМ ---
//      var OriginalTitle := p.Title;
//      var TrimmedTitle := OriginalTitle;
//      FBitmap.Font.Style := [fsBold]; // Включаем Bold перед замером
//
//      var MaxTextWidth := FixedColWidth - (TextPadding * 2);
//
//      if FBitmap.TextWidth(OriginalTitle) > MaxTextWidth then
//      begin
//        while (TrimmedTitle <> '') and (FBitmap.TextWidth('...' + TrimmedTitle) > MaxTextWidth) do
//        begin
//          Delete(TrimmedTitle, 1, 1);
//        end;
//        if TrimmedTitle <> '' then
//          TrimmedTitle := '...' + TrimmedTitle
//        else
//          TrimmedTitle := '...';
//      end;
//
//      // Выводим заголовок параметра (смещаем на TextPadding, чтобы не прилипал к линии)
//      FBitmap.RenderText(CurrentX + TextPadding, 0, TrimmedTitle, TextColor, True);
//      FBitmap.Font.Style := [];
//
//      // Вывод строк данных от -HalfRowsCount до +HalfRowsCount
//      for var OffsetY := -HalfRowsCount to HalfRowsCount do
//      begin
//        var CurrentIdx := Bestidx + OffsetY;
//
//        if (CurrentIdx >= 0) and (CurrentIdx < PointsCount) then
//        begin
//          var CurrentPoint := Buffer.points[CurrentIdx];
//          var ScreenY := CenterY + (OffsetY * RowHeight);
//
//          if ScreenY < HeaderHeight then Continue; // Не затираем заголовок
//
//          // А) Вывод значений FromY для этой строки
//          if not FromYRendered then
//          begin
//            YFrom := Graph.YTopScreen + SignY * CurrentPoint.Y / (pp2mm * Graph.YScale);
//            ValueStr := FloatToStr(Round(YFrom));
//
//            if OffsetY = 0 then
//            begin
//              FBitmap.Font.Style := [fsBold];
//              FBitmap.RenderText(TextPadding, ScreenY, ValueStr, DefaultTextColor, True);
//              FBitmap.Font.Style := [];
//            end
//            else
//            begin
//              FBitmap.RenderText(TextPadding, ScreenY, ValueStr, DefaultTextColor, True);
//            end;
//          end;
//
//          // Б) Вывод значений X для текущего параметра
//          ValueStr := Format('%.'+lp.Presizion.ToString+'f', [CurrentPoint.X / (lp.ScaleX * pp2mm) + lp.DeltaX]);
//
//          if OffsetY = 0 then
//          begin
//            FBitmap.Font.Style := [fsBold];
//            FBitmap.RenderText(CurrentX + TextPadding, ScreenY, ValueStr, TextColor, True);
//            FBitmap.Font.Style := [];
//          end
//          else
//          begin
//            FBitmap.RenderText(CurrentX + TextPadding, ScreenY, ValueStr, TextColor, True);
//          end;
//        end;
//      end;
//
//      FromYRendered := True;
//      Inc(CurrentX, FixedColWidth);
//    end;
//  end;

//  // --- ШАГ 3: ГОРИЗОНТАЛЬНЫЕ ЛИНИИ СЕТКИ ЧЕРЕЗ HorzLineTS ---
//  // 1. Линия под заголовками (отделяет шапку таблицы)
//  FBitmap.HorzLineTS(0, HeaderHeight, FBitmap.Width, ACL_AXIS);
//
//  // 2. Линии, выделяющие центральную строку "Best" сверху и снизу
//  FBitmap.HorzLineTS(0, CenterY, FBitmap.Width, ACL_AXIS);
//  FBitmap.HorzLineTS(0, CenterY + RowHeight, FBitmap.Width, ACL_AXIS);
//end;

function FindMaxIndex(const Arr: TArray<ShortInt>): Integer;
var
  I: Integer;
begin
  if Length(Arr) = 0 then
    Exit(-1); // Возвращаем -1, если массив пуст

  Result := 0; // Изначально считаем нулевой индекс максимальным

  for I := 1 to High(Arr) do
  begin
    if Arr[I] > Arr[Result] then
      Result := I; // Запоминаем новый индекс максимума
  end;
end;

function FindMinIndex(const Arr: TArray<ShortInt>): Integer;
var
  I: Integer;
begin
  if Length(Arr) = 0 then
    Exit(-1); // Возвращаем -1, если массив пуст

  Result := 0; // Изначально считаем нулевой индекс максимальным

  for I := 1 to High(Arr) do
  begin
    if Arr[I] < Arr[Result] then
      Result := I; // Запоминаем новый индекс максимума
  end;
end;

procedure TGR32GraphicInfo.Render;
const
  ACL_AXIS = $F0A8A8A8; // Константа цвета сетки
  HeaderHeight = 20;    // Высота, зарезервированная под заголовки
  RowHeight = 16;       // Высота одной строки текста
  FixedColWidth = 130;  // Фиксированная ширина колонки
  TextPadding = 4;      // Отступ внутри ячейки
var
  p: TXScalableParam;
  YFrom, pp2mm: Double;
  SignY: Integer;
  CurrentX: Integer;
  HalfRowsCount: Integer;
  CenterY: Integer;
  FromYRendered: Boolean;
  DefaultTextColor: TColor32;

  // --- 1. ОБЩАЯ ПОДФУНКЦИЯ ДЛЯ ОТРИСОВКИ ШАПКИ СТОЛБЦА ---
  function RenderColumnHeader(Param: TXScalableParam): TColor32;
  begin
    Result := TColor32(Param.Color) or $FF000000;
    FBitmap.VertLineTS(CurrentX, 0, FBitmap.Height, ACL_AXIS);

    var TrimmedTitle := Param.Title;

 if TrimmedTitle.EndsWith('.DEV', True) or TrimmedTitle.EndsWith('.CLC', True) then
    TrimmedTitle := TrimmedTitle.Substring(0, TrimmedTitle.Length - 4);

    FBitmap.Font.Style := [fsBold];
    var MaxTextWidth := FixedColWidth - (TextPadding * 2);
    if FBitmap.TextWidth(TrimmedTitle) > MaxTextWidth then
    begin
      while (TrimmedTitle <> '') and (FBitmap.TextWidth('...' + TrimmedTitle) > MaxTextWidth) do
        Delete(TrimmedTitle, 1, 1);
      if TrimmedTitle <> '' then TrimmedTitle := '...' + TrimmedTitle else TrimmedTitle := '...';
    end;

    FBitmap.RenderText(CurrentX + TextPadding, 0, TrimmedTitle, Result, True);
    FBitmap.Font.Style := [];
  end;

  // --- 2. ВНУТРЕННЯЯ ПОДФУНКЦИЯ ОТРЕСОВКИ СТРОКИ (Для FromY и значений) ---
  procedure DrawRowText(X: Integer; OffsetY: Integer; const FromYStr, ValueStr: string; TextColor: TColor32);
  var
    ScreenY: Integer;
  begin
    ScreenY := CenterY + (OffsetY * RowHeight);
    if ScreenY < HeaderHeight then Exit;

    // Отрисовка FromY (только один раз для всей таблицы)
    if not FromYRendered and (FromYStr <> '') then
    begin
      if OffsetY = 0 then
      begin
        FBitmap.Font.Style := [fsBold];
        FBitmap.RenderText(TextPadding, ScreenY, FromYStr, DefaultTextColor, True);
        FBitmap.Font.Style := [];
      end
      else
        FBitmap.RenderText(TextPadding, ScreenY, FromYStr, DefaultTextColor, True);
    end;

    // Отрисовка значения параметра
    if ValueStr <> '' then
    begin
      if OffsetY = 0 then
      begin
        FBitmap.Font.Style := [fsBold];
        FBitmap.RenderText(X + TextPadding, ScreenY, ValueStr, TextColor, True);
        FBitmap.Font.Style := [];
      end
      else
        FBitmap.RenderText(X + TextPadding, ScreenY, ValueStr, TextColor, True);
    end;
  end;

  // --- 3. ПОДФУНКЦИЯ: Специфичный рендеринг для TLineParam ---
  procedure RenderLineParam(lp: TLineParam; TextColor: TColor32);
  var
    pss: ILineDataLink;
  begin
    if not (Supports(lp, ILineDataLink, pss) and Assigned(pss.DrowMemoryBuffer)) then Exit;

    var Buffer := TLineParamBuffer(pss.DrowMemoryBuffer);
    var PointsCount := Length(Buffer.points);
    if PointsCount = 0 then Exit;

    var deltaOld := Single.MaxValue;
    var Bestidx := 0;

    // Специфичный для TLineParam поиск центрального индекса по FCurY
    for var i := 0 to PointsCount - 1 do
    begin
      var pn := Buffer.points[i];
      var delta := abs(FCurY - pn.Y);
      if delta < deltaOld then
      begin
        deltaOld := delta;
        Bestidx := i;
      end;
    end;

    // Вывод строк
    for var OffsetY := -HalfRowsCount to HalfRowsCount do
    begin
      var CurrentIdx := Bestidx + OffsetY;
      if (CurrentIdx >= 0) and (CurrentIdx < PointsCount) then
      begin
        var CurrentPoint := Buffer.points[CurrentIdx];

        // Специфичный расчет FromY для TLineParam
        var CalcYFrom := Graph.YTopScreen + SignY * CurrentPoint.Y / (pp2mm * Graph.YScale);
        var FromYStr := FloatToStr(Round(CalcYFrom));

        // Специфичный расчет значения X для TLineParam
        var ValueStr := Format('%.'+lp.Presizion.ToString+'f', [CurrentPoint.X / (lp.ScaleX * pp2mm) + lp.DeltaX]);

        DrawRowText(CurrentX, OffsetY, FromYStr, ValueStr, TextColor);
      end;
    end;
    FromYRendered := True; // Фиксируем, что первая колонка заполнена
  end;

  // --- 4. ПОДФУНКЦИЯ: Специфичный рендеринг для TWaveParam ---
  procedure RenderWaveParam(wp: TWaveParam; TextColor: TColor32);
  var
    wl: IWaveDataLink;
    FromYStr, ValueStr: string;
  begin
    if not Supports(wp, IWaveDataLink, wl) then Exit;
    // Сюда добавьте ваш алгоритм поиска центрального индекса для TWaveParam.
    // Предположим, вы нашли некоторый WaveBestIdx.
    var WaveBestIdx := FCurY;
    var WavePointsCount := wl.RecordCount; // Замените на реальное кол-во отсчетов/точек волны

    // Пример структуры цикла для TWaveParam
    for var OffsetY := -HalfRowsCount to HalfRowsCount do
    begin
      var CurrentIdx :=  Graph.YTopScreen + SignY * (WaveBestIdx + OffsetY) / (pp2mm * Graph.YScale);
      if (CurrentIdx >= 0) and (CurrentIdx < WavePointsCount) then
      begin
       // 1. Специфичный расчет FromY для TWaveParam на основе его структуры данных
       FromYStr := '0';

       // 2. Специфичный расчет значения для TWaveParam
       ValueStr := '0.00';
      wl.Read(CurrentIdx, wp.ZeroGamma, wp.KoeffGamma, procedure(Y: Single; const X: TArray<ShortInt>)
      var
        P_Threshold, S_Threshold: Integer;
        P_Idx, S_Idx: Integer;
        i, WindowEnd: Integer;
        SumSq_P, SumSq_S: Int64;
        P_Energy, S_Energy: Double;
      begin
        FromYStr := Round(Y).ToString;

        if Length(X) = 0 then
        begin
          ValueStr := '---';
          Exit;
        end;

        // 1. Пороги (для ShortInt от -128 до 127)
        P_Threshold := 10;
        S_Threshold := 40;

        P_Idx := -1;
        S_Idx := -1;
        P_Energy := 0;
        S_Energy := 0;

        // 2. Поиск первого вступления (P-волна)
        for i := 0 to High(X) do
        begin
          if Abs(X[i]) > P_Threshold then
          begin
            P_Idx := i;
            Break;
          end;
        end;

        // 3. Поиск второго вступления (S-волна)
        if P_Idx <> -1 then
        begin
          for i := P_Idx + 5 to High(X) do
          begin
            if Abs(X[i]) > S_Threshold then
            begin
              S_Idx := i;
              Break;
            end;
          end;
        end;

        // 4. Расчет энергии P-волны (ограничиваем точкой прихода S-волны)
        if P_Idx <> -1 then
        begin
          SumSq_P := 0;
          if (S_Idx <> -1) then
            WindowEnd := Min(P_Idx + 15, S_Idx - 1)
          else
            WindowEnd := Min(P_Idx + 15, High(X));

          for i := P_Idx to WindowEnd do
            SumSq_P := SumSq_P + (X[i] * X[i]);

          P_Energy := Sqrt(SumSq_P / (WindowEnd - P_Idx + 1));
        end;

        // 5. Расчет энергии S-волны (начиная от S_Idx до конца её окна)
        if S_Idx <> -1 then
        begin
          SumSq_S := 0;
          // Окно для S-волны берём чуть шире (например, 25 отсчётов)
          WindowEnd := Min(S_Idx + 25, High(X));

          for i := S_Idx to WindowEnd do
            SumSq_S := SumSq_S + (X[i] * X[i]);

          S_Energy := Sqrt(SumSq_S / (WindowEnd - S_Idx + 1));
        end;

        // 6. Формирование компактной результирующей строки
        if P_Idx <> -1 then
        begin
          if S_Idx <> -1 then
            // Вывод: P: индекс(энергия) S: индекс(энергия)
            ValueStr := Format('%5d %5.0f  %5d %5.0f', [P_Idx, P_Energy, S_Idx, S_Energy])
          else
            ValueStr := Format('%5d %5.0f  S nop', [P_Idx, P_Energy]);
        end
        else
        begin
          ValueStr := 'No Arrival';
        end;
      end);

        DrawRowText(CurrentX, OffsetY, FromYStr, ValueStr, TextColor);
      end;
    end;
    FromYRendered := True; // Фиксируем, если TWaveParam вдруг отрисовался первым
  end;

// --- ОСНОВНОЙ КОД МЕТОДА RENDER ---
begin
  if not (not Graph.Frosted and Graph.HandleAllocated and Column.Visible and Row.Visible) then Exit;

  FBitmap.FillRect(0, 0, FBitmap.Width, FBitmap.Height, Color32(StyleServices.GetStyleColor(scTreeView)));

  var AvailableHeight := FBitmap.Height - HeaderHeight;
  if AvailableHeight <= RowHeight then Exit;

  HalfRowsCount := (AvailableHeight div RowHeight) div 2;
  CenterY := HeaderHeight + (AvailableHeight div 2) - (RowHeight div 2);

  pp2mm := Screen.PixelsPerInch / 2.54 * 2;
  SignY := if Graph.YMirror then -1 else 1;

  FBitmap.Font.Style := [];
  DefaultTextColor := TColor32(StyleServices.GetStyleFontColor(sfWindowTextNormal)) or $FF000000;

  FBitmap.Font.Style := [fsBold];
  FBitmap.RenderText(TextPadding, 0, 'FromY', DefaultTextColor, True);
  FBitmap.Font.Style := [];

  CurrentX := FixedColWidth;
  FromYRendered := False;

  if FCurY >= 0 then
  begin
    for var baseParam in Column.Params do
    begin
      if baseParam is TXScalableParam then
      begin
        var ParamColor := RenderColumnHeader(TXScalableParam(baseParam));

        // Раздельный полиморфный вызов процедур отрисовки
        if baseParam is TLineParam then
          RenderLineParam(TLineParam(baseParam), ParamColor)
        else if baseParam is TWaveParam then
          RenderWaveParam(TWaveParam(baseParam), ParamColor);

        Inc(CurrentX, FixedColWidth);
      end;
    end;
  end;

  FBitmap.HorzLineTS(0, HeaderHeight, FBitmap.Width, ACL_AXIS);
  FBitmap.HorzLineTS(0, CenterY, FBitmap.Width, ACL_AXIS);
  FBitmap.HorzLineTS(0, CenterY + RowHeight, FBitmap.Width, ACL_AXIS);
end;


procedure TGR32GraphicInfo.SetCaption(const Value: string);
begin

end;

procedure TGR32GraphicInfo.SetClientRect(const Value: TRect);
begin
  inherited;
  FBitmap.SetSize(Value.Width, Value.Height);
  Render;
end;

{$ENDREGION}

{ TGR32DataRow }

procedure TGR32DataRow.MouseMove(Shift: TShiftState; X, Y: Integer);
 var
  RData: TGR32GraphicData;
  RInfo: TGR32GraphicInfo;
begin
  //to do get info row if region TGR32GraphicInfo then OnCurrentParamsEvent
  for var c in Graph.Columns do
   begin
    RData := nil;
    RInfo := nil;
    for var r in c.Regions do if r is TGR32GraphicData then
     begin
      RData := r as TGR32GraphicData;
      break;
     end;
    for var r in c.Regions do if r is TGR32GraphicInfo then
     begin
      RInfo := r as TGR32GraphicInfo;
      break;
     end;

     if Assigned(RData) and Assigned(RInfo) then
      begin
        var clPoint := TFloatPoint.Create(RData.MouseToClient(TPoint.Create(X,Y)));
        RInfo.OnCurrentParamsEvent(self, clPoint.Y);
      end;
   end;
end;

initialization
  TGraphRegion.RegClsRegister(TGR32GraphicInfo, TGR32InfoRow, TGR32GraphicCollumn);
  RegisterClasses([TGR32GraphicInfo]);
  TGraphRegion.RegClsRegister(TGR32GraphicData, TGR32DataRow, TGR32GraphicCollumn);
  RegisterClasses([TGR32DataRow]);

end.

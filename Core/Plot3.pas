unit Plot3;

interface

uses RootImpl, tools,
     SysUtils, Controls, Messages, Winapi.Windows, Classes, Winapi.GDIPAPI, WinAPI.GDIPObj,  Vcl.Graphics, System.Rtti, Vcl.Forms, types, Vcl.ExtCtrls,
     Vcl.Menus, Vcl.Themes, Vcl.GraphUtil, System.SyncObjs;

const
  MAX_VALL = 1000000;
  NULL_VALL: single = -987.654321;
  SCALE_ONE = 7;
  SCALE_PRESET: array[0..13] of Double =(0.001, 0.002, 0.005, 0.01, 0.02, 0.05, 0.1, 0.25, 0.5,
                                       1, 2, 5, 10, 20);//, 25, 50, 100, 200, 500, 1000, 2000, 5000, 10000, 20000);
  COLOR_PRESET: array[0..22] of TGPColor =(aclDarkRed, aclBlue, aclGreen, aclBlueViolet, aclBlack,
  aclDarkBlue,
  aclDarkCyan,
  aclDarkGoldenrod,
//  aclDarkGray,
  aclDarkGreen,
  aclDarkKhaki,
  aclDarkMagenta,
  aclDarkOliveGreen,
  aclDarkOrange,
  aclDarkOrchid,
  aclRed,
  aclDarkSalmon,
  aclDarkSeaGreen,
  aclDarkSlateBlue,
  aclDarkSlateGray,
  aclDarkTurquoise,
  aclDarkViolet,
  aclDeepPink,
  aclDeepSkyBlue);

type
  PlotState = (psUpdating, psSizing, psScrolling, psPainting);
  PlotColState = (pcsNormal, pcsSizing, pcsMoving, pcsColumnData);
  PlotStates = set of PlotState;

  TCustomPlot = class;
  TColumnHint = class;
  TPlotColumns = class;
  TExecFunc = reference to procedure(obj: TObject);

  TPlotCollectionItem = class(TICollectionItem)
  private
    FPlot: TCustomPlot;
  public
    constructor Create(Collection: TCollection); override;
    property Plot: TCustomPlot read FPlot;
  end;

  TPlotCollection = class(TICollection)
  private
    FPlot: TCustomPlot;
  protected
    procedure Update(Item: TCollectionItem); override;
  public
    constructor Create(AOwner: TObject); reintroduce; virtual;
    function Add<T: TPlotCollectionItem>: T; reintroduce; overload;
    function Add(const ItemClassName: string): TPlotCollectionItem; reintroduce; overload;
    property Plot: TCustomPlot read FPlot;
  end;


  TPlotColumn = class(TPlotCollectionItem)
  private
    FLeft: Integer;
    FWidth: Integer;
    FOnContextPopup: TContextPopupEvent;
    procedure SetWidth(const Value: Integer);
  protected
    FMinY, FMaxY: Double;
    function GetHintColor: TColor; virtual;
    procedure CalcLegendHeight(Gdip: TGPGraphics; var Height: Integer); virtual;
    procedure UpdateMinMaxY(var MinY, MaxY: Double); virtual;
    procedure ShowLegend(Gdip: TGPGraphics; const Height: Integer); virtual;
    procedure ShowData(Gdip: TGPGraphics);virtual;
    // для этих фумкций X - глобальное Y-локальное
    procedure DoSetCursorInData(X, Y: integer; var State: PlotColState; var Cursor: HCURSOR); virtual;
    procedure DoMouseDownInLegend(X, Y: integer); virtual;
    function CheckMouseDownInData(X, Y: integer; Shift: TShiftState): Boolean; virtual;
    procedure DoMouseMoveInData(X, Y: integer); virtual;
    procedure DoMouseUpInData(X, Y: integer); virtual;
    procedure DoShowHint(X,Y: integer; ShowCnt: integer); virtual;
    procedure DoHideHint(); virtual;
    procedure DoContextPopup(MousePos: TPoint; var Handled: Boolean); virtual;
    function Right: Integer; inline;
    procedure Exec(Func: TExecFunc); virtual;
    property Left: Integer read FLeft;
  public
    constructor Create(Collection: TCollection); override;
//    function SafeCallException(ExceptObject: TObject; ExceptAddr: Pointer): HResult; override;
    property HintColor: TColor read GetHintColor;
  published
    property Width: Integer read FWidth write SetWidth;
    property OnContextPopup: TContextPopupEvent read FOnContextPopup write FOnContextPopup;
  end;
  TPlotColumnClass = class of TPlotColumn;

  TYColumn = class(TPlotColumn)
  protected
    procedure CalcLegendHeight(Gdip: TGPGraphics; var Height: Integer); override;
    procedure ShowLegend(Gdip: TGPGraphics; const Height: Integer); override;
    procedure ShowData(Gdip: TGPGraphics); override;
  end;

  TParamPoint = record
     X,Y: Double;
  end;

  TGraphColumn = class;
  TChangeStateParam = (chspNone, chspMove, chspScale);

  TGraphParam = class(TPlotCollectionItem)
  private
    RChange: record
     X, OldDx: Integer;
     Poi: TGPPointF;
     Delta: Double;
     Scale: Double;
     State: TChangeStateParam;
    end;
    FDelta: Double;
    FScale: Double;
    FWidth: Single;
    FDashStyle: TDashStyle;
    FColor: TGPColor;
    FEUnit: string;
    FTitle: string;
    FPresizion: Integer;
    FVisible: Boolean;
    FLegendHeight: Single;

    FScPoints{, FPoints}: TPointFDynArray;
    FScFrom, FScTo: integer;

    FOnContextPopup: TContextPopupEvent;
    FParentTitle: string;
    FFixedParam: boolean;
    FHideInLegend: boolean;
    procedure SetColor(const Value: TGPColor);
    procedure SetDashStyle(const Value: TDashStyle);
    procedure SetDelta(const Value: Double);
    procedure SetEUnit(const Value: string);
    procedure SetScale(const Value: Double);
    procedure SetTitle(const Value: string);
    procedure SetWidth(const Value: Single);
    function GetOwnColumn: TGraphColumn; inline;
    procedure SetVisible(const Value: Boolean);
    procedure SetHideInLegend(const Value: boolean);
  protected
    { DONE : везде где используются нанные включить критич секцию
          RecalcScale-V,
          ShowDat-V
          DistanceToCurve-V
          NearlestPointToCurve-V
          UpdateMinMaxY и т д и в DBplot не забыть UpdateMinMaxY ненадо ?????
          CheckEOFandGetXY - ненадо - уже внутри критич секц}
    FLockPoints: TCriticalSection; // защита массива данных т.к. рисование и обновление scale могут быть в разных потоках
   // для других источников
    procedure UpdateMinMaxY(var MinY, MaxY: Double); virtual; abstract;
    function RecordCount: Integer; virtual; abstract;
    function CheckEOFandGetXY(var X,Y: Double; GoToFirst: Boolean = false): Boolean; virtual; abstract;
    // из координат колонки на промежуточные
    function ScreenXYToScaleCurvePoint(X, Y: Integer): TGPPointF;
    // из промежуточных на экранные координаты колонки
    function ScPointToScreen(scP: TGPPointF): TPoint;
    // из промежуточных реальные данные
    function ScPointToCurvePoint(scP: TGPPointF): TGPPointF;
// рисует данные всей колонки
    procedure ShowColumnData();
    procedure ShowLegend(Gdip: TGPGraphics);
    procedure ShowData(Gdip: TGPGraphics);
    function CalcLegendHeight(Gdip: TGPGraphics): Single;
    procedure DoMouseDownInLegend(X, Y, Top, Height: integer);
    procedure DoContextPopup(MousePos: TPoint; var Handled: Boolean); virtual;
  public
    constructor Create(Collection: TCollection); override;
    destructor Destroy; override;
    procedure RecalcScale(); virtual;
    function MouseToParam(X, Y: integer): TParamPoint;
    function DistanceToCurve(P: TGPPointF): Double;
    function NearlestPointToCurve(P: TGPPointF; var res: TGPPointF): double;
//    property Points: TGPPointFArray read FPoints;
    property Column: TGraphColumn read GetOwnColumn;
    property LegendHeight: Single read FLegendHeight;
  published
    property ParentTitle: string read FParentTitle write FParentTitle;
    [ShowProp('Показать')]                      property Visible: Boolean read FVisible write SetVisible default True;
    [ShowProp('Заморозить')]                    property FixedParam: boolean read FFixedParam write FFixedParam;
    [ShowProp('Скрыть легенду')]                property HideInLegend: boolean read FHideInLegend write SetHideInLegend;
    [ShowProp('Имя')]                           property Title        : string read FTitle write SetTitle;
    [ShowProp('Единицы измерения')]             property EUnit        : string read FEUnit write SetEUnit;
    [ShowProp('Точность(цифр после запятой)')]  property Presizion    : Integer read FPresizion write FPresizion default 2;
    [ShowProp('Масштаб')]                       property Scale        : Double read FScale write SetScale;
    [ShowProp('Смещение нуля')]                 property Delta        : Double read FDelta write SetDelta;
    [ShowProp('Ширина линии')]                  property Width        : Single read FWidth write SetWidth;
    [ShowProp('Цвет')]                          property Color        : TGPColor read FColor write SetColor default aclBlack;
    [ShowProp('Стиль штрихов')]                 property DashStyle    : TDashStyle read FDashStyle write SetDashStyle default DashStyleSolid;

    property OnContextPopup: TContextPopupEvent read FOnContextPopup write FOnContextPopup;
  end;

  TGraphParamClass = class of TGraphParam;
  TGraphParams = class;

  TGraphParamsEnumerator = record
  private
    i: Integer;
    FCollection: TGraphParams;
    function DoGetCurrent: TGraphParam; inline;
  public
    property Current: TGraphParam read DoGetCurrent;
    function MoveNext: Boolean; inline;
  end;

  TGraphParams = class(TPlotCollection)
  private
    Fcol: TGraphColumn;
  public
    constructor Create(AOwner: TObject); override;
    function GetEnumerator: TGraphParamsEnumerator; reintroduce;
    function Add<T: TGraphParam>: T; reintroduce;
  end;

  TGraphColumn = class(TPlotColumn)
  private
    FParams: TGraphParams;
    FChangeParam, FHintParam: TGraphParam;
  protected
    procedure DefineProperties(Filer: TFiler); override;
    function GetHintColor: TColor; override;
    procedure CalcLegendHeight(Gdip: TGPGraphics; var Height: Integer); override;
    procedure UpdateMinMaxY(var MinY, MaxY: Double); override;
    procedure ShowLegend(Gdip: TGPGraphics; const Height: Integer); override;
    procedure ShowData(Gdip: TGPGraphics); override;
    procedure DoSetCursorInData(X, Y: integer; var State: PlotColState; var Cursor: HCURSOR); override;
    procedure DoMouseDownInLegend(X, Y: integer); override;
    function CheckMouseDownInData(X, Y: integer; Shift: TShiftState): Boolean; override;
    function GetNearScCurve(X, Y: integer; out Curve: TGraphParam): Double;
    function GetLegendParam(X, Y: integer; out Curve: TGraphParam): Boolean;
    procedure DoMouseMoveInData(X, Y: integer); override;
    procedure DoMouseUpInData(X, Y: integer); override;
    procedure DoShowHint(X,Y: integer; ShowCnt: integer); override;
    procedure DoHideHint(); override;
    procedure DoContextPopup(MousePos: TPoint; var Handled: Boolean); override;
    procedure ShowYAxis(Gdip: TGPGraphics);
    procedure RecalcScale();
//    procedure Exec(Func: TExecFunc);  override;
  public
    constructor Create(Collection: TCollection); override;
    destructor Destroy; override;
    property HintParam: TGraphParam read FHintParam;
//  published
    property Params: TGraphParams read FParams;// write FParams;
  end;

  TPlotColumnsEnumerator = record
  private
    i: Integer;
    FCollection: TPlotColumns;
    function DoGetCurrent: TPlotColumn; inline;
  public
    property Current: TPlotColumn read DoGetCurrent;
    function MoveNext: Boolean; inline;
  end;

  TPlotColumns = class(TPlotCollection)
  private
    function GetItem(Index: Integer): TPlotColumn;
    procedure SetItem(Index: Integer; const Value: TPlotColumn);
  public
    function GetEnumerator: TPlotColumnsEnumerator; reintroduce;
    function Add<T: TPlotColumn, constructor>: T; reintroduce; overload;
    function Add(const PlotColumnClassName: string): TPlotColumn; reintroduce; overload;
    property Items[Index: Integer]: TPlotColumn read GetItem write SetItem;
  end;
  TPlotColumnsClass = class of TPlotColumns;

  TColumnHint = class(THintWindow)
  private
   class var ScreenColor: TColor;
   class var Font: TFont;
  protected
    procedure Paint; override;
  public
  end;

  THintData = record
    Column: TPlotColumn;
    DataPoint: TPoint;
    ShowCounter: Integer;
    Tic: Cardinal;
    function CheckHint(Col: TPlotColumn): boolean;
    procedure HideWait(Col: TPlotColumn);
    procedure Hide();
  end;

  TParamXAxisChangedEvent = procedure(Column: TGraphColumn; Param: TGraphParam; ChangeState: TChangeStateParam) of object;

  TCustomPlot = class(TICustomControl)
  public
   type
    TUpdate = (uColunsWidth, uLegendHeight, uScrollRect, uBitmapLegend, uBitmapData, uScrollBar,
               uPrepareLegend, uPaintLegend, uPaintData,
               uAsyncPrepareData, uAsyncPaintData, uSyncPrepareData, uSyncPaintData);
    TUpdates = set of TUpdate;
    TCheckMouse = (cmColSize, cmColMove, cmColData, cmColLegend);
    TCheckMouses = set of TCheckMouse;
    TCheckMouseFunc = reference to function (cm: TCheckMouse; Col: TPlotColumn; X, Y: integer): boolean;
    TRenderProc = procedure of object;
    TRenderTask = record
      Render, Show: TRenderProc;
      constructor Create(ARender, AShow: TRenderProc);
    end;
    TQeRender = class(TQeueThread<TRenderTask>)
    protected
      procedure Exec(data: TRenderTask); override;
    public
      function CompareTask (ToQeTask, InQeTask: TRenderTask): Boolean;
    end;
  private
    FRender: TQeRender;
    FCursorY: Double;
    FColumns: TPlotColumns;
    FIncrementY: Integer;
    FStates: PlotStates;
    FColState: PlotColState;
    FShowLegend: Boolean;
    FHintData: THintData;
    FHitTest: TPoint;
    FHorizontShowed: Boolean;
    FChangePos,
    FChangeLeft: Integer;
    FChangeColumn, FSwapColumn: TPlotColumn;
//    DataBitmap: TBitmap;
    {FBitmap, }LegendBitmap: TBitmap;
//    FGPGData, FGPGLegend: TGPGraphics;
    FScaleY: Double;
    FPresizionY: Integer;
    FEUnit: string;
    FTitle: string;
    FPresetScaleY: integer;
    FOnScaleChanged: TNotifyEvent;
    FOnParamXAxisChanged: TParamXAxisChangedEvent;
    FSelectedColumn: TPlotColumn;
//    Fcbch: TGPBitmap;
    procedure SetCursorY(const Value: Double);
    procedure SetShowLegend(const Value: Boolean);
    function SetOffsetY(Y: Integer; NeedRepaint: Boolean = False): Boolean;
    procedure WMVScroll(var Message: TWMVScroll); message WM_VSCROLL;
    procedure WMSize(var Message: TWMSize); message WM_SIZE;
    procedure CMMouseWheel(var Message: TCMMouseWheel); message CM_MOUSEWHEEL;
    procedure CMParentFontChanged(var Message: TCMParentFontChanged); message CM_PARENTFONTCHANGED;
    procedure CMHintShow(var Message: TCMHintShow); message CM_HINTSHOW;
    procedure WMPaint(var Message: TWMPaint); message WM_PAINT;
    procedure WMNCHitTest(var Msg: TWMNCHitTest); message WM_NCHITTEST;
    procedure WMSetCursor(var Msg: TWMSetCursor); message WM_SETCURSOR;
    procedure WMEraseBkgnd(var Msg: TWMEraseBkgnd); message WM_ERASEBKGND;
    procedure DrawSizingLine();
    procedure DrawMovingLine();
    procedure DrawCrossLine(X, Y: Integer);
    procedure SetScaleY(const Value: Double);
    procedure SetPresetScaleY(const Value: integer);
//    procedure ReadColumns(Reader: TReader);
//    procedure WriteColumns(Writer: TWriter);
    procedure SetYOffset(const Value: Integer);
  protected
    Ydpmm, Xdpmm: Double;
    FirstY, LastY, OffsetY: Integer;
    LegendHeight: Integer;
    ScrollRect: TRect;
    function CheckMousePosition(cms: TCheckMouses; X, Y: Integer; func: TCheckMouseFunc): Boolean;
    function LegendRect: TRect; inline;
    procedure DefineProperties(Filer: TFiler); override;
    procedure DoContextPopup(MousePos: TPoint; var Handled: Boolean); override;
    procedure CreateWnd; override;
    procedure MouseDown(Button: TMouseButton; Shift: TShiftState; X, Y: Integer); override;
    procedure MouseMove(Shift: TShiftState; X, Y: Integer); override;
    procedure MouseUp(Button: TMouseButton; Shift: TShiftState; X, Y: Integer); override;
    procedure KeyPress(var Key: Char); override;

    procedure DoPrepareData();
    procedure DoPrepareLegend();
    procedure DoPaintLegend();
    procedure DoPaintData();
    procedure UpdateScrollRect;
    procedure UpdateVerticalScrollBar;
    procedure UpdateColumns;
    function UpdateLegendHeight: TUpdates;
    function UpdateSizeBitmapData: TUpdates;
    function UpdateSizeBitmapLegend: TUpdates;
    function UpdateALL(const tsk: TUpdates): TUpdates;

    procedure DoParamXAxisChanged(Column: TGraphColumn; Param: TGraphParam; ChangeState: TChangeStateParam);

    function GetColumnsClass: TPlotColumnsClass; virtual;
    procedure ShowYWalls(G: TGPGraphics; top, Height: integer);
    procedure ShowXAxis(G: TGPGraphics);
    procedure ShowCursorY(G: TGPGraphics);
    function CreateGPFont: TGPFont;
    function Range: Integer; inline;
    function RangeY: Integer; inline;
    procedure Exec(Func: TExecFunc);
    procedure AsyncRepaint;
  public
    DataBitmap: TBitmap;
    ScaleFactor: Double;
    Mirror: Integer; { TODO : protected property DB plot check SQL for DESC to set mirror -1 }
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    function MouseYtoParamY(Y: Integer): Double;
    function ParamYToY(Y: Double): Double;
    procedure UpdateMinMaxY(ForceScale: boolean = False); virtual;
    procedure Update0Position;
    procedure UpdateAllAndRepaint;
    procedure UpdateDataAndRepaint;
    procedure BeginUpdate;
    procedure EndUpdate;
    procedure AsyncRun(Async, AfrerSync: TRenderProc);
    procedure GoToBookmark();
    function IsLegend(Y: Integer): Boolean; inline;
    procedure SetBookmark(Y: Integer); inline;
    property OnScaleChanged: TNotifyEvent read FOnScaleChanged write FOnScaleChanged;
    property Columns: TPlotColumns read FColumns;
    property SelectedColumn: TPlotColumn read FSelectedColumn write FSelectedColumn;
    property TitleY: string read FTitle write FTitle;
    property EUnitY: string read FEUnit write FEUnit;
    property PresizionY: Integer read FPresizionY write FPresizionY default 2;
    property DpmmX: Double read Xdpmm;
    property DpmmY: Double read Ydpmm;
    property OnParamXAxisChanged: TParamXAxisChangedEvent read FOnParamXAxisChanged write FOnParamXAxisChanged;
    property Popupmenu;
  published
    property ShowLegend: Boolean read FShowLegend write SetShowLegend default True;
    property ScaleY: Double read FScaleY write SetScaleY;
    property PresetScaleY: integer read FPresetScaleY write SetPresetScaleY default SCALE_ONE;
    property YOffset: Integer read OffsetY write SetYOffset; // должно быть после ScaleY PresetScaleY
    property CursorY: Double read FCursorY write SetCursorY;
  end;

  TPlot = class(TCustomPlot)
  published
    property Align;
    property ParentFont;
    property Font;
    property OnScaleChanged;
    property ParentColor;
    property Color;
    property OnContextPopup;
    property OnParamXAxisChanged;
  end;

var
 testcnt: Integer;


function SetPresetScale(s: double): Double;
procedure TstDebug(const msg: string);


implementation

uses System.Math, debug_except, Winapi.CommCtrl;

const
 CL_AXIS    = $00A8A8A8;
 ACL_AXIS   = $FFA8A8A8;
 CL_CURSOR  = $00C2B5FF;
 ACL_CURSOR = $FFFFB5C2;
 CHECKBOX_SIZE = 10;


function MeasureString(gdip: TGPGraphics; string_: WideString; font: TFont; stringFormat: TGPStringFormat = nil): TGPRectF;
 var
  f: TGPFont;
  fs: TFontStyles;
begin
  fs := font.Style;
  f := TGPFont.Create(font.Name, font.Size, PInteger(@fs)^);
  try
   gdip.MeasureString(string_, Length(string_), f, MakePoint(0.0,0.0), stringFormat, Result);
  finally
   f.Free;
  end;
end;

function SetPresetScale(s: double): Double;
 var
  m, dlt: Double;
begin
   dlt := 1000000;
   Result := s;
   for m in SCALE_PRESET do if Abs(m-s) < dlt then
    begin
     dlt := Abs(m-s);
     Result := m;
    end;
end;

procedure CheckBoxToGDIP(const Checked: Boolean; out Res: TGPBitmap);
 const
  DA: array[Boolean]of TThemedButton = (tbCheckBoxUncheckedNormal, tbCheckBoxCheckedNormal);
 var
  B: TBitmap;
  NonThemedCheckBoxState: Cardinal;
  R: TRect;
begin
  B := TBitmap.Create;
  B.SetSize(CHECKBOX_SIZE, CHECKBOX_SIZE);
  R := Rect(0,0,CHECKBOX_SIZE,CHECKBOX_SIZE);
  if StyleServices.Enabled then
    StyleServices.DrawElement(B.Canvas.Handle, StyleServices.GetElementDetails(DA[Checked]), R)
  else
   begin
    B.Canvas.FillRect(R);
    NonThemedCheckBoxState := DFCS_BUTTONCHECK;
    if Checked then  NonThemedCheckBoxState := NonThemedCheckBoxState or DFCS_CHECKED;
    DrawFrameControl(B.Canvas.Handle, R, DFC_BUTTON, NonThemedCheckBoxState);
   end;
  Res := TGPBitmap.Create(B.Handle, b.Palette);
  B.Free;
end;

procedure TstDebug(const msg: string);
begin
  Inc(testcnt);
  TDebug.Log(Format('%s %d   ',[msg, testcnt] ));
end;

{ TPlotCollectionItem }

constructor TPlotCollectionItem.Create(Collection: TCollection);
begin
  FPlot := TPlotCollection(Collection).Plot;
  inherited Create(Collection);
end;

//procedure TPlotCollectionItem.SetPlot(const Value: TCustomPlot);
//begin
//  FPlot := Value;
//end;

{ TPlotCollection }

function TPlotCollection.Add(const ItemClassName: string): TPlotCollectionItem;
begin
  Result := TPlotCollectionItem(TICollectionItemClass(FindClass(ItemClassName)).Create(Self));
end;

function TPlotCollection.Add<T>: T;
begin
  Result := TRttiContext.Create.GetType(TClass(T)).GetMethod('Create').Invoke(TClass(T), [Self]).AsType<T>; //через жопу работает
end;

constructor TPlotCollection.Create(AOwner: TObject);
begin
  FPlot := TCustomPlot(AOwner);
  inherited Create(TPlotCollectionItem);
end;

//procedure TPlotCollection.SetPlot(const Value: TCustomPlot);
//begin
//  FPlot := Value;
//end;

procedure TPlotCollection.Update(Item: TCollectionItem);
begin
  inherited;
  if  not FPlot.HandleAllocated or (psUpdating in FPlot.FStates) then Exit;
  FPlot.UpdateALL([uColunsWidth, uScrollRect, uLegendHeight, uBitmapLegend, uBitmapData, uScrollBar, uPrepareLegend,
                   uPaintLegend, uAsyncPrepareData, uAsyncPaintData]);
end;


{$REGION 'COLUMN CLASSES'}

{ TPlotColumnsEnumerator }

function TPlotColumnsEnumerator.DoGetCurrent: TPlotColumn;
begin
  Result := TPlotColumn(FCollection.Items[i]);
end;

function TPlotColumnsEnumerator.MoveNext: Boolean;
begin
  Inc(i);
  Result := i < FCollection.Count;
end;

{ TPlotColumns }

function TPlotColumns.GetEnumerator: TPlotColumnsEnumerator;
begin
  Result.i := -1;
  Result.FCollection := Self;
end;

function TPlotColumns.GetItem(Index: Integer): TPlotColumn;
begin
  Result := TPlotColumn(inherited GetItem(Index));
end;

procedure TPlotColumns.SetItem(Index: Integer; const Value: TPlotColumn);
begin
  inherited SetItem(Index, Value);
end;

function TPlotColumns.Add(const PlotColumnClassName: string): TPlotColumn;
begin
  Result := TPlotColumn(inherited Add(PlotColumnClassName));//  TPlotColumnClass(FindClass(PlotColumnClassName)).Create(Self);
  if (Count >= 2) and FPlot.HandleAllocated then
   begin
    TPlotColumn(Items[Count-2]).Width := TPlotColumn(Items[Count-2]).Width div 2;
    FPlot.UpdateColumns;
   end;
end;

function TPlotColumns.Add<T>: T;
begin
  if (Count > 0) then Items[Count-1].Width := Items[Count-1].Width div 2;
  Result := TRttiContext.Create.GetType(TClass(T)).GetMethod('Create').Invoke(TClass(T), [Self]).AsType<T>; //через жопу работает
  if FPlot.HandleAllocated then FPlot.UpdateColumns;
end;

{ TPlotColumn }

constructor TPlotColumn.Create(Collection: TCollection);
begin
  inherited Create(Collection);
  FWidth := 20;
end;

function TPlotColumn.Right: Integer;
begin
  Result := FLeft + FWidth;
end;

procedure TPlotColumn.SetWidth(const Value: Integer);
begin
  if Value > 20 then FWidth := Value
  else FWidth := 20
end;

procedure TPlotColumn.DoContextPopup(MousePos: TPoint; var Handled: Boolean);
begin
  if Assigned(FOnContextPopup) then FOnContextPopup(Self, MousePos, Handled);
end;

function TPlotColumn.GetHintColor: TColor;
begin
  Result := Screen.HintFont.Color;
end;

//function TPlotColumn.GetOwnPlot: TCustomPlot;
//begin
//  Result := TPlotColumns(Collection).FPlot;
//end;

function TPlotColumn.CheckMouseDownInData(X, Y: integer; Shift: TShiftState): Boolean;
begin
  Result := False;
end;

procedure TPlotColumn.UpdateMinMaxY(var MinY, MaxY: Double);
begin
  FMinY := MinY;
  FMaxY := MaxY;
end;

procedure TPlotColumn.DoHideHint();
begin
end;
procedure TPlotColumn.ShowData(Gdip: TGPGraphics);
begin
end;
procedure TPlotColumn.ShowLegend(Gdip: TGPGraphics; const Height: Integer);
begin
end;
procedure TPlotColumn.CalcLegendHeight(Gdip: TGPGraphics; var Height: Integer);
begin
end;
procedure TPlotColumn.DoMouseDownInLegend(X, Y: integer);
begin
end;
procedure TPlotColumn.DoMouseMoveInData(X, Y: integer);
begin
end;
procedure TPlotColumn.DoMouseUpInData(X, Y: integer);
begin
end;
procedure TPlotColumn.DoSetCursorInData(X, Y: integer; var State: PlotColState; var Cursor: HCURSOR);
begin
end;
procedure TPlotColumn.DoShowHint(X,Y: integer; ShowCnt: integer);
begin
end;
procedure TPlotColumn.Exec(Func: TExecFunc);
begin
  Func(Self);
end;

{ TYColumn }

procedure TYColumn.CalcLegendHeight(Gdip: TGPGraphics; var Height: Integer);
 var
  h: Integer;
begin
  h := Round(MeasureString(Gdip, Plot.TitleY, Plot.Font).Width + 1);
  if h > Height then Height := h;
end;

procedure TYColumn.ShowData(Gdip: TGPGraphics);
  var
   sf: TGPStringFormat;
   br: TGPBrush;
   mx: TGPMatrix;
   cntDpmm, mr: Integer;
   Y, off, ht, Ydpmm: Double;
   s: WideString;
   f: TGPFont;
begin
  Ydpmm := Gdip.GetDpiY*2/2.54;
  mr    := Plot.Mirror;
  off   := Plot.OffsetY;
  ht    := Plot.ScrollRect.Height;
  // создание вспомогательных интерфейсов
  sf := TGPStringFormat.Create;
  f  := Plot.CreateGPFont;
  try
    br := TGPSolidBrush.Create(aclBlack);
    try
      Gdip.SetClip(MakeRect(0,0, Width,  ht));
      mx := TGPMatrix.Create;
      try
        Gdip.GetTransform(mx);

        if mr = 1 then Gdip.TranslateTransform(0, Off)
        else Gdip.TranslateTransform(0, -Off+ht);

        cntDpmm := Trunc(-Off/Ydpmm);
        Y := Ydpmm*Trunc(cntDpmm);
        while Y <= (-Off + ht+Ydpmm) do
         begin
          // заголовок
          s := Format('%g',[Plot.FirstY + cntDpmm*2/Plot.ScaleY]);
          Gdip.DrawString(
                          s, Length(s),
                          f,
                          MakePoint(0, Y*mr),
                          sf,
                          br
                          );
          Inc(cntDpmm);
          Y := Y + Ydpmm;
         end;
        Gdip.SetTransform(mx);
      finally
       mx.Free;
      end;
      Gdip.ResetClip;
    finally
     br.Free;
    end;
  finally
   f.Free;
   sf.Free;
  end;
end;

procedure TYColumn.ShowLegend(Gdip: TGPGraphics; const Height: Integer);
  var
   sf: TGPStringFormat;
   br: TGPBrush;
   mx: TGPMatrix;
   s: string;
   f: TGPFont;
begin
  // создание вспомогательных интерфейсов
  sf := TGPStringFormat.Create;
  f  := Plot.CreateGPFont;
  try
    sf.SetAlignment(StringAlignmentCenter);
    sf.SetLineAlignment(StringAlignmentCenter);

    br := TGPSolidBrush.Create(aclBlack);
    try
      mx := TGPMatrix.Create;
      try
        Gdip.GetTransform(mx);
        Gdip.RotateTransform(90);

        if Plot.EUnitY <> '' then
             s := Plot.TitleY + ' ['+ Plot.EUnitY +']'
        else s := Plot.TitleY;
        // заголовок
        Gdip.DrawString(
                        s, Length(s),
                        f,
                        MakePoint(Height/2, -Width/2),
                        sf,
                        br
                        );
        Gdip.SetTransform(mx);
      finally
        mx.Free;
      end;
    finally
     br.Free;
    end;
  finally
    f.Free;
    sf.Free;
  end;
end;

{ TGraphColumn }

constructor TGraphColumn.Create(Collection: TCollection);
begin
  FParams := TGraphParams.Create(Self); // необходимо создать сначала
  FParams.FPlot := TPlotCollection(Collection).Plot;
  inherited Create(Collection);
end;

procedure TGraphColumn.DefineProperties(Filer: TFiler);
begin
  inherited;
  FParams.RegisterProperty(Filer, 'Params');
end;

destructor TGraphColumn.Destroy;
begin
  FParams.Free;
  inherited;
end;

function TGraphColumn.GetHintColor: TColor;
begin
  if Assigned(FHintParam) then Result := ARGBToColorRef(FHintParam.Color)
  else Result := inherited;
end;

function TGraphColumn.GetLegendParam(X, Y: integer; out Curve: TGraphParam): Boolean;
 var
  p: TGraphParam;
  top, ht: Double;
begin
  Curve := nil;
  Result := False;
  top := 0;
  for p in FParams do
   begin
    ht := p.LegendHeight;
    if (Y > top) and (y < top+ht) then
     begin
      Result := True;
      Curve := p;
      Exit;
     end;
    top := top + ht;
   end;
end;

function TGraphColumn.GetNearScCurve(X, Y: integer; out Curve: TGraphParam): Double;
 var
  p: TGraphParam;
  h: Double;
begin
  Curve := nil;
  Result := 100000;
  for p in FParams do if p.Visible then                      
   begin
    h := p.DistanceToCurve(TGraphParam(p).ScreenXYToScaleCurvePoint(X, Y));
    if Result > h then
     begin
      Result := h;
      Curve := p;
     end;
   end;
end;

function TGraphColumn.CheckMouseDownInData(X, Y: integer; Shift: TShiftState): Boolean;
begin
  if Plot.ShowLegend then Y := Y-plot.LegendHeight;
  if (GetNearScCurve(X-Left, Y, FChangeParam) < 4) and not FChangeParam.FixedParam then
   begin
    Result := True;
    FChangeParam.RChange.X := X;
    FChangeParam.RChange.Poi := FChangeParam.ScPointToCurvePoint(FChangeParam.ScreenXYToScaleCurvePoint(X-Left,Y));
    FChangeParam.RChange.Delta := FChangeParam.FDelta;
    FChangeParam.RChange.Scale := FChangeParam.FScale;
    FChangeParam.RChange.OldDx := -100000;
    if ssCtrl in Shift  then FChangeParam.RChange.State := chspScale
    else FChangeParam.RChange.State := chspMove;
    FChangeParam.ShowColumnData;
   end
  else Result := False;
end;

procedure TGraphColumn.DoContextPopup(MousePos: TPoint; var Handled: Boolean);
  var
   y: Integer;
   p: TGraphParam;
begin
  inherited;
  if Handled then Exit;
  y := MousePos.Y;
  // если на легенде то найти параметр легенды
  if Plot.ShowLegend and (Plot.LegendHeight > Y) then
   begin
    if GetLegendParam(MousePos.X-Left, Y, p) then
     begin
      p.DoContextPopup(MousePos, Handled);
      if Handled then Exit;
     end;
   end
  else
   begin
    if Plot.ShowLegend then Y := Y-Plot.LegendHeight;
    if GetNearScCurve(MousePos.X-Left, Y, p) < 4 then p.DoContextPopup(MousePos, Handled);
   end;
end;

procedure TGraphColumn.DoHideHint();
begin
  FHintParam := nil;
end;

procedure TGraphColumn.DoMouseDownInLegend(X, Y: integer);
 var
  p: TGraphParam;
  h, hall: Double;
begin
  hall := 0;
  for p in FParams do
   begin
    h := p.LegendHeight;
    if (Y > hall) and (Y < Hall + h) then
     begin
      p.DoMouseDownInLegend(X, Y, Round(hall), Round(h));
      Exit;
     end;
    hall := hall + h;
   end;
end;

procedure TGraphColumn.DoMouseMoveInData(X, Y: integer);
const
  SCP: array[0..24] of Double =(0.0005, 0.001, 0.002, 0.005, 0.01, 0.02, 0.05, 0.1, 0.25, 0.5,
                                       1, 2, 5, 10, 20, 25, 50, 100, 200, 500, 1000, 2000, 5000, 10000, 20000);
  function getI(s: double): Integer;
   var
    i: Integer;
    dlt: Double;
  begin
    dlt := 10000000;
    Result := 0;
    for I := 0 to Length(SCP)-1 do if Abs(s-SCP[i])< dlt then
     begin
       dlt := Abs(s-SCP[i]);
       Result := i;
     end;
  end;
  function GetSc(ind: Integer):Double;
  begin
    if ind<0 then ind := 0
    else if ind > High(SCP) then ind := High(SCP);
    Result := SCP[ind];
  end;
 var
  sc,olsc, d, dx: Double;
  idx: Integer;
begin
  if (X < Left) or (X > Right) then Exit;

  dx := (FChangeParam.RChange.X-X)/Plot.Xdpmm;
  idx := Round(dx);

  if FChangeParam.RChange.OldDx = idx then Exit;
  FChangeParam.RChange.OldDx := idx;

  sc := FChangeParam.Scale;
  d := FChangeParam.Delta;

  case FChangeParam.RChange.State of
    chspMove:  FChangeParam.RChange.Delta := Round((d*sc + dx))/ sc;
    chspScale:
     begin
      FChangeParam.RChange.Scale := GetSc(getI(sc)+ idx);
      d := (d-FChangeParam.RChange.Poi.X)*sc/FChangeParam.RChange.Scale + FChangeParam.RChange.Poi.X;
      FChangeParam.RChange.Delta := Round(d*FChangeParam.RChange.Scale)/FChangeParam.RChange.Scale;
      olsc := FChangeParam.Scale;
      FChangeParam.FScale := FChangeParam.RChange.Scale;
      FChangeParam.RecalcScale();
      FChangeParam.FScale := olsc;
     end;
  end;
  FChangeParam.ShowColumnData;
end;

procedure TGraphColumn.DoMouseUpInData(X, Y: integer);
begin
  case FChangeParam.RChange.State of
    chspMove:FChangeParam.FDelta := FChangeParam.RChange.Delta;
    chspScale:
     begin
      FChangeParam.FDelta := FChangeParam.RChange.Delta;
      FChangeParam.FScale := FChangeParam.RChange.Scale;
     end;
  end;
  if FChangeParam.RChange.State <> chspNone then Plot.DoParamXAxisChanged(Self, FChangeParam, FChangeParam.RChange.State);
  FChangeParam.RChange.State := chspNone;
end;

procedure TGraphColumn.DoSetCursorInData(X, Y: integer; var State: PlotColState; var Cursor: HCURSOR);
 var
  i,j: Integer;
  clt, clb: TColor;
begin
  for i := -4 to 4 do for j := -4 to 4 do
   begin
//    Plot.FAsyncTh.FLock.Acquire;
    clt := Plot.Canvas.Pixels[X+i,Y+j];
    clb := Plot.Canvas.Brush.Color;
//    Plot.FAsyncTh.FLock.Release;

    if (clt <> clb) and (clt <> CL_AXIS) and (clt <> CL_CURSOR) and (clt <> clBlack) and (clt <> 5723991) and (clt <> 4016640) then
     begin
      State := pcsColumnData;
      Cursor := Screen.Cursors[crCross];
      if Plot.FHintData.CheckHint(Self) then DoShowHint(X-Left, Y, Plot.FHintData.ShowCounter);
      Exit;
     end;
   end;
   plot.FHintData.HideWait(Self);
end;

procedure TGraphColumn.DoShowHint(X,Y: integer; ShowCnt: integer);
   const
    TXT = '%s'+#$D#$A+'%s'+#$D#$A+'%s';
  procedure shw;
   var
    p: TPoint;
    r: TGPPointF;
    sx,sy: string;
  begin
    if FHintParam.NearlestPointToCurve(FHintParam.ScreenXYToScaleCurvePoint(X, Y), r) < 10000 then
     begin
      p := FHintParam.ScPointToScreen(r);

      if p.Y < 0 then p.y := 16
      else if p.Y > plot.ScrollRect.Height then p.Y := plot.ScrollRect.Height-16;

      // коорд. колонки в клиента
      if Plot.ShowLegend then p.Y := p.Y + Plot.LegendHeight;
      p.X := p.X + Left;

      P := Plot.ClientToScreen(p);

      if (Plot.FHintData.DataPoint <> p) then
       begin
        r := FHintParam.ScPointToCurvePoint(r);
        sx := FloatToStrF(r.X, ffFixed, 10,  FHintParam.Presizion);
        if FHintParam.EUnit <>'' then sx := sx + '('+FHintParam.EUnit + ')';
        sy := FloatToStrF(r.Y, ffFixed, 10, Plot.PresizionY);
        if Plot.EUnitY <>'' then sy := sy + '('+Plot.EUnitY + ')';
        Plot.Hint := Format(TXT, [FHintParam.Title, sx, sy]);
        TColumnHint.Font := Plot.Font;
        TColumnHint.ScreenColor := HintColor;
        Plot.FHintData.DataPoint := p;
        HintWindowClass := TColumnHint;
        Plot.ShowHint := True;
        Application.ActivateHint(p);
//        TDebug.Log(Format('%d %d',[p.X, P.Y]));
       end;
     end;
  end;
begin
  if Plot.ShowLegend then Y := Y-Plot.LegendHeight;
  if ShowCnt = 0 then
   if GetNearScCurve(X, Y, FHintParam) < 8 then shw
   else Plot.FHintData.HideWait(Self)
  else shw;
end;

//procedure TGraphColumn.Exec(Func: TExecFunc);
//  var
//   p: TGraphParam;
//begin
//  inherited;
//  for p in FParams do Func(p);
//end;

procedure TGraphColumn.UpdateMinMaxY(var MinY, MaxY: Double);
  var
   p: TGraphParam;
begin
  for p in FParams do p.UpdateMinMaxY(MinY, MaxY);
  inherited;
end;

procedure TGraphColumn.RecalcScale();
  var
   p: TGraphParam;
begin
  for p in FParams do p.RecalcScale();
end;

procedure TGraphColumn.CalcLegendHeight(Gdip: TGPGraphics; var Height: Integer);
  var
   p: TGraphParam;
   h: Single;
begin
  h := 0;
  for p in FParams do h := h + p.CalcLegendHeight(Gdip);
  if h > Height then Height := Round(h);
end;

procedure TGraphColumn.ShowData(Gdip: TGPGraphics);
 var
  p: TGraphParam;
  m: TGPMatrix;
begin
  Gdip.SetClip(MakeRect(1,0, Width-1,  Plot.ScrollRect.Height));
  ShowYAxis(Gdip);
  m := TGPMatrix.Create;
  try
    for p in FParams do
     begin
      Gdip.GetTransform(m);
      if p.Visible then p.ShowData(Gdip);
      Gdip.SetTransform(m);
     end;
  finally
    m.Free;
  end;
  Gdip.ResetClip;
end;

procedure TGraphColumn.ShowLegend(Gdip: TGPGraphics; const Height: Integer);
 var
  p: TGraphParam;
  m: TGPMatrix;
begin
  m := TGPMatrix.Create;
  try
    Gdip.GetTransform(m);
    for p in FParams do if not p.HideInLegend then
     begin
      p.ShowLegend(Gdip);
      Gdip.TranslateTransform(0, p.CalcLegendHeight(Gdip));
     end;
    Gdip.SetTransform(m);
  finally
    m.Free;
  end;
end;

procedure TGraphColumn.ShowYAxis(Gdip: TGPGraphics);
  var
   pn: TGPPen;
   X, ht, Xdpmm: Double;
begin
  pn := TGPPen.Create(ACL_AXIS, 1);
  try
    Xdpmm := Gdip.GetDpiX*2/2.54;
    ht := Plot.ScrollRect.Height;
    X := Xdpmm;
    while X < Width do
     begin
      Gdip.DrawLine(pn, X, 0, X, ht);
      X := X + Xdpmm;
     end;
  finally
   pn.Free;
  end;
end;
{$ENDREGION}

{$REGION 'TGraphParam'}

{ TGraphParamsEnumerator }

function TGraphParamsEnumerator.DoGetCurrent: TGraphParam;
begin
  Result := TGraphParam(FCollection.Items[i]);
end;

function TGraphParamsEnumerator.MoveNext: Boolean;
begin
  Inc(i);
  Result := i < FCollection.Count;
end;

{ TGraphParams }

function TGraphParams.Add<T>: T;
begin
  Result := inherited Add<T>;
  Result.FColor := COLOR_PRESET[Result.Index mod Length(COLOR_PRESET)];
end;

constructor TGraphParams.Create(AOwner: TObject);
begin
  inherited Create(AOwner);
  FPlot := TGraphColumn(AOwner).Plot;
  Fcol := TGraphColumn(AOwner);
end;

function TGraphParams.GetEnumerator: TGraphParamsEnumerator;
begin
  Result.i := -1;
  Result.FCollection := Self;
end;

{ TGraphParam }

constructor TGraphParam.Create(Collection: TCollection);
begin
  FScale := 1;
  FPresizion := 2;
  FVisible := True;
  FWidth := 2;
  FLockPoints := TCriticalSection.Create;
  inherited;
end;

destructor TGraphParam.Destroy;
begin
  FLockPoints.Free;
  inherited;
end;

function TGraphParam.CalcLegendHeight(Gdip: TGPGraphics): Single;
begin
  if HideInLegend then Result := 0
  else Result := Round(MeasureString(Gdip, '[', Plot.Font).Height*2 + Width);
  FLegendHeight := Result;
end;

function TGraphParam.DistanceToCurve(P: TGPPointF): Double;
// расстояние от точки до отрезка
  function FindH(pA,pB,P: TGPPointF): double;
   var
    A, B, C: Double;
    distPA, distPB, distAB: Double;
    vA, vB: TGPPointF;
  begin
    // вектора
    vA.X := pA.X-p.X;
    vA.Y := pA.Y-p.Y;
    vB.X := pB.X-p.X;
    vB.Y := pB.Y-p.Y;
    A := pB.Y - pA.Y;
    B := pA.X - pB.X;
    // квадраты сторон
    distPA := Sqr(vA.X) + Sqr(vA.Y);
    distPB := Sqr(vB.X) + Sqr(vB.Y);
    distAB := Sqr(A)    + Sqr(B);
    // тупые углы
    if distPB >= distAB + distPA then Exit(Hypot(vA.X, vA.Y))
    else if distPA >= distAB + distPB then Exit(Hypot(vB.X, vB.Y))
    else
     begin
      C := -pA.X*A - pA.Y*B;
      // расстояние от точки до прямой
      // D = |Ax + By + C|/Hypot(A,B);
      Result := Abs(A*p.X + B*p.Y + C)/Hypot(A, B);
     end;
  end;
 var
  i: Integer;
  d: Double;
begin
  FLockPoints.Acquire;
  try
   Result := 100000;
   if (FScFrom > Length(FscPoints)) or (FScTo > Length(FscPoints)) then Exit;
   for i := FScFrom+1 to FScTo do if (FscPoints[i-1].X <> NULL_VALL) and (FscPoints[i].X <> NULL_VALL) then
    begin
     d := FindH(FscPoints[i-1], FscPoints[i], P);
     if d < Result then Result := d;
    end;
  finally
   FLockPoints.Release;
  end;
end;

procedure TGraphParam.DoContextPopup(MousePos: TPoint; var Handled: Boolean);
begin
  if Assigned(FOnContextPopup) then FOnContextPopup(Self, MousePos, Handled);
end;

function TGraphParam.NearlestPointToCurve(P: TGPPointF; var res: TGPPointF): double;
 var
  i: Integer;
  d: Double;
begin
  FLockPoints.Acquire;
  try
    Result := 10000;
    if (FScFrom > Length(FscPoints)) or (FScTo > Length(FscPoints)) then Exit;
    for i := FScFrom to FScTo do if FscPoints[i].X <> NULL_VALL then
     begin
      d := Hypot(FscPoints[i].X-P.X, FscPoints[i].Y-P.Y);
      if d < Result then
       begin
        res := FscPoints[i];
        Result := d;
       end;
     end;
  finally
   FLockPoints.Release;
  end;
end;

function TGraphParam.ScPointToScreen(scP: TGPPointF): TPoint;
begin
  if Plot.Mirror = 1 then Result.Y := Round(plot.OffsetY+scP.Y)
  else Result.Y := Round(-plot.OffsetY + plot.ScrollRect.Height + scP.Y);
  Result.X := Round(-Delta*Scale*plot.Xdpmm + scP.X);
end;

function TGraphParam.MouseToParam(X, Y: integer): TParamPoint;
 var
  poi: TGPPointF;
begin
  if Plot.ShowLegend then poi := ScPointToCurvePoint(ScreenXYToScaleCurvePoint(X-Column.Left, Y-plot.LegendHeight))
  else  poi := ScPointToCurvePoint(ScreenXYToScaleCurvePoint(X--Column.Left, Y));
  Result.X := poi.X;
  Result.Y := poi.Y;
  //Delta + (X-Column.Left)/(Plot.Xdpmm*Scale);
end;

function TGraphParam.ScreenXYToScaleCurvePoint(X, Y: Integer): TGPPointF;
begin
  if Plot.Mirror = 1 then Result.Y := -plot.OffsetY+Y
  else Result.Y := plot.OffsetY - plot.ScrollRect.Height + Y;
  Result.X := Delta*Scale*plot.Xdpmm + X;
end;

function TGraphParam.ScPointToCurvePoint(scP: TGPPointF): TGPPointF;
 var
  kY, kX: Double;
begin
  kX := Plot.Xdpmm*Scale;
  kY := Plot.Mirror*Plot.Ydpmm*Plot.ScaleY;
  Result.X := scP.X/kX;
  Result.Y := scP.Y/kY + Plot.FirstY;
end;

//function TGraphParam.CheckEOFandGetXY(var X, Y: Double; GoToFirst: Boolean): Boolean;
//const
// {$J+}i: Integer=0;  {$J-}
//begin
//  if Length(FPoints) = 0 then Exit(False);
//  if GoToFirst then
//   begin
//    i := 0;
//    X := FPoints[0].X;
//    Y := FPoints[0].Y;
//    Exit(True);
//   end;
//  X := FPoints[i].X;
//  Y := FPoints[i].Y;
//  inc(I);
//  Result := I<Length(FPoints);
//end;

//function TGraphParam.RecordCount: Integer;
//begin
//  Result := Length(FPoints);
//end;

//procedure TGraphParam.UpdateMinMaxY(var MinY, MaxY: Double);
//begin
//  if Length(Points) > 0 then
//   begin
//    MinY := Min(MinY,  Points[0].Y);
//    MaxY := Max(MaxY,  Points[High(Points)].Y);
//   end;
//end;

procedure TGraphParam.RecalcScale();
 var
  i, y, Yold: integer;
  Xmin, Xmax, X, OldMin, kY, kX, DX,DY: Double;
  EndRec: Boolean;
  procedure SetBf(mn, mx: Double);
  begin
    if mn >MAX_VALL then FScPoints[i].X := MAX_VALL
    else if mn <-MAX_VALL then FScPoints[i].X := -MAX_VALL
    else FScPoints[i].X := mn;
    FScPoints[i].Y := Yold;
    Inc(i);
    if (mn <> mx) then
     begin
      if mx >MAX_VALL then FScPoints[i].X := MAX_VALL
      else if mx <-MAX_VALL then FScPoints[i].X := -MAX_VALL
      else FScPoints[i].X := mx;
      FScPoints[i].Y := Yold;
      Inc(i);
     end;
  end;
begin
  FLockPoints.Acquire;
  try
  if RecordCount = 0 then Exit;

//  TDebug.Log(Format('recalc %d %d',[Plot.FirstY, Plot.LastY]));

  kX := Plot.Xdpmm*Scale;
  kY := Plot.Mirror*Plot.Ydpmm*Plot.ScaleY;
  i := 0;
  if not CheckEOFandGetXY(DX,DY,True) then Exit;
  Yold := Round((DY-Plot.FirstY)*kY);
  if DX = NULL_VALL then Xmin := DX
  else Xmin := DX*kX;
  Xmax := Xmin;
  OldMin := 0;
  SetLength(FScPoints, RecordCount);

  repeat
    EndRec := CheckEOFandGetXY(DX,DY);
    Y := Round((DY-Plot.FirstY)*kY);
    if DX = NULL_VALL then X := DX  else  X := DX*kX;
    if Y <> Yold then
     begin
      if OldMin < Xmin then SetBf(Xmin, Xmax)  // лучше рисует
      else SetBf(Xmax, Xmin);
      OldMin := Xmin;
      Yold := Y;
      Xmin := X;
      Xmax := X;
     end
    else
     if X <> NULL_VALL then
       if (Xmax = NULL_VALL) then
        begin
         Xmax := x;
         Xmin := x;
        end
       else if (X > Xmax) then Xmax := x
       else if (X < Xmin) then Xmin := x;
  until EndRec;

  if i < Length(FScPoints) then
   if OldMin < Xmin then SetBf(Xmin, Xmax)
   else SetBf(Xmax, Xmin);
   SetLength(FScPoints, i);
  finally
   FLockPoints.Release;
  end;
end;

procedure TGraphParam.ShowColumnData;
 var
  G: TGPGraphics;
  sb: TGPSolidBrush;
begin
  if psUpdating in Plot.FStates then Exit;
  Include(Plot.FStates, psUpdating);
  if Plot.ShowLegend then Plot.DoPrepareLegend;
  plot.DataBitmap.Canvas.Lock;
  GDIPlus.Lock;
  G := TGPGraphics.Create(plot.DataBitmap.Canvas.Handle);
  sb := TGPSolidBrush.Create(ColorRefToARGB(plot.color));
  try
    G.TranslateTransform(Column.Left, 0);
    G.SetClip(MakeRect(1,0, Column.Width-1,  Plot.ScrollRect.Height));
    G.FillRectangle(sb, MakeRect(1,0, Column.Width-1, plot.ScrollRect.Height));
    plot.ShowCursorY(G);
    plot.ShowXAxis(g);
    G.ResetTransform;
    G.TranslateTransform(Column.Left, 0);
    Column.ShowData(G);
  finally
   sb.Free;
   g.Free;
   GDIPlus.UnLock;
   plot.DataBitmap.Canvas.UnLock;
   Exclude(Plot.FStates, psUpdating);
  end;
  Plot.Repaint();
end;

procedure TGraphParam.ShowData(Gdip: TGPGraphics);
 var
  i,j: integer;
  pn: TGPPen;
  Dx,Sc, Y1,Y2: Single;
begin
  FLockPoints.Acquire;
  try
    pn := TGPPen.Create(Color, Width);
    try
      pn.SetDashStyle(DashStyle);
      pn.SetLineJoin(LineJoinBevel);
      // ТРАНСФОРМАЦИЯ
      Y1 := -plot.OffsetY;
      Y2 := -plot.OffsetY + plot.ScrollRect.Height;
      Dx := Delta;
      Sc := Scale;
      case RChange.State of
        chspMove:Dx := RChange.Delta;
        chspScale:
         begin
          Sc := RChange.Scale;
          Dx := RChange.Delta;
         end;
      end;
      if Plot.Mirror = 1 then Gdip.TranslateTransform(-Dx*Sc*plot.Xdpmm, -Y1)
      else Gdip.TranslateTransform(-Dx*Sc*plot.Xdpmm, Y2);
      // ОТ ДО
      FScFrom := 0;
      FScTo := -1;
      for i := 0 to Length(FscPoints)-1 do
       if (abs(FscPoints[i].Y) >= y1) and (FscPoints[i].X <> NULL_VALL) then
       begin
        if (i > 0) and (FscPoints[i-1].X <> NULL_VALL)  then  FScFrom := i-1
        else FScFrom := i;
        for j := Length(FscPoints)-1 downto FScFrom do if (abs(FscPoints[j].Y) <= y2) and (FscPoints[j].X <> NULL_VALL) then
         begin
          if (j+1 < Length(FscPoints)) and (FscPoints[j+1].X <> NULL_VALL) then FScTo := j+1
          else FScTo := j;
          Break;
         end;
        Break;
       end;
      // РИСОВАНИЕ
      i := FScFrom;
      while  FScTo-i >= 0 do
       begin
        while (FscPoints[i].X = NULL_VALL) and (FScTo-i >= 0) do inc(i);
        j := i;
        while (j < Length(FscPoints)) and (FscPoints[j].X <> NULL_VALL) and (FScTo-j >= 0) do inc(j); {TODO -oOwner -cCategory : Найти причину видимо J за границей массива}
    //    EInvalidOp    Invalid floating point operation
    //    [016E57FA]{Core.bpl    } Plot.TGraphParam.ShowData$qqr48System.%DelphiInterface$t20Igdiplus.TGPGraphics% (Line 1377, "Plot.pas")
        try
         if j > Length(FscPoints) then raise Exception.CreateFmt('j:%d > Length(FscPoints):%d',[j+i , Length(FscPoints)]);
         if j-i = 1 then Gdip.DrawLine(pn, FscPoints[i].X, FscPoints[i].Y, FscPoints[i].X, FscPoints[i].Y)
         else if j-i >= 1 then Gdip.DrawLines(pn, PGPPointF(@FscPoints[i]), j-i);
        except
         raise
        end;
        i := j;
       end;
    finally
     pn.Free;
    end;
  finally
   FLockPoints.Release;
  end;
end;

procedure TGraphParam.DoMouseDownInLegend(X, Y, Top, Height: integer);
 var
  cbR: TRect;
  X0,y0: Integer;
  G: TGPGraphics;
  f: Boolean;
  b: TGPBitmap;
begin
  GDIPlus.Lock;
  G := TGPGraphics.Create(Plot.LegendBitmap.Canvas.Handle);
  try
   X0 := Column.Left + CHECKBOX_SIZE div 2;
   Y0 := Round(Top + MeasureString(g, '[', Plot.Font).Height + Width) - CHECKBOX_SIZE - 1;
   cbR := Rect(X0, Y0, X0 + CHECKBOX_SIZE, Y0 + CHECKBOX_SIZE);
   f := cbR.Contains(Point(X,Y));
   if f then
    begin
     FVisible := not FVisible;
     CheckBoxToGDIP(FVisible, b);
     try
      G.DrawCachedBitmap(TGPCachedBitmap.Create(b, G), X0, Y0);
     finally
      b.Free;
     end;
    end;
  finally
   g.Free;
   GDIPlus.UnLock;
  end;
  if f then ShowColumnData();
end;

procedure TGraphParam.ShowLegend(Gdip: TGPGraphics);
  var
   sf: TGPStringFormat;
   pn: TGPPen;
   br: TGPBrush;
   s: WideString;
   X, Y, w, dpmm, lbl, dx,sc: Double;
   f: TGPFont;
   b: TGPBitmap;
begin
  dpmm := Gdip.getDpiX/2.54;
  // создание вспомогательных интерфейсов
  sf := TGPStringFormat.Create;
  f := Plot.CreateGPFont;
  try
    sf.SetAlignment(StringAlignmentCenter);
    pn := TGPPen.Create(Color, Width);
    try
      pn.SetDashStyle(DashStyle);
      br := TGPSolidBrush.Create(Color);
      try
        // заголовок
        if EUnit <> '' then s := Title + '['+ EUnit +']'
        else s := Title;

        Dx := Delta;
        Sc := Scale;
        case RChange.State of
          chspMove:Dx := RChange.Delta;
          chspScale:
           begin
            Sc := RChange.Scale;
            Dx := RChange.Delta;
           end;
        end;
        S := Format('%s:%g',[s,sc]);

        Y := MeasureString(Gdip, s, Plot.Font).Height + Width/2;
        w := Column.Width;
        // обрезка
        Gdip.SetClip(MakeRect(0,0,Column.Width, CalcLegendHeight(Gdip)));
        // заголовок и линия оси
        Gdip.DrawString(
                        s, Length(s),
                        f,
                        MakePoint(w/2, 0),
                        sf,
                        br);
        Gdip.DrawLine(pn, 0, Y, w, Y);
        // риски и шкала
        pn.SetDashStyle(DashStyleSolid);
        X := 0;

        lbl := Dx;
        pn.SetWidth(1);
        Y := Y + Width/2;
        while X < w do
         begin
          Gdip.DrawLine(pn, X, Y, X, Y+8);
          s := Format('%-10.5g', [lbl]);
          Gdip.DrawString(
                        s, Length(s),
                        f,
                        MakePoint(X+1, y),
                        br);
          X := X + 2*dpmm;
          lbl := lbl + 2.0/Sc;
          if Abs(lbl) < 0.0000001 then lbl := 0;
         end;
        finally
         br.Free;
        end;
    finally
     pn.Free;
    end;
  finally
   f.Free;
   sf.Free;
  end;
  CheckBoxToGDIP(FVisible, b);
  try
   Gdip.DrawCachedBitmap(TGPCachedBitmap.Create(b, Gdip), CHECKBOX_SIZE div 2, Trunc(Y-CHECKBOX_SIZE)-1);
   Gdip.ResetClip;
  finally
   b.Free;
  end;
end;

function TGraphParam.GetOwnColumn: TGraphColumn;
begin
  Result := TGraphParams(Collection).Fcol;
end;

//function TGraphParam.GetOwnPlot: TCustomPlot;
//begin
//  Result := TGraphParams(Collection).FPlot;
//end;

procedure TGraphParam.SetColor(const Value: TGPColor);
begin
  if FColor <> Value then
   begin
    FColor := Value;
    if not (csLoading in Plot.ComponentState) then Plot.AsyncRepaint;
   end;
end;

procedure TGraphParam.SetDashStyle(const Value: TDashStyle);
begin
  if FDashStyle <> Value then
   begin
    FDashStyle := Value;
    if not (csLoading in Plot.ComponentState) then Plot.AsyncRepaint;
   end;
end;

procedure TGraphParam.SetDelta(const Value: Double);
begin
  if FDelta <> Value then
   begin
    FDelta := Value;
    if not (csLoading in Plot.ComponentState) then Plot.AsyncRepaint;
   end;
end;

procedure TGraphParam.SetEUnit(const Value: string);
begin
  if FEUnit <> Value then
   begin
    FEUnit := Value;
    if not (csLoading in Plot.ComponentState) then Plot.AsyncRepaint;
   end;
end;

procedure TGraphParam.SetScale(const Value: Double);
begin
  if FScale <> Value then
   begin
    FScale := Value;
    if not (csLoading in Plot.ComponentState) and Plot.HandleAllocated  then
     begin
      RecalcScale();
      Plot.AsyncRepaint;
     end;
   end;
end;

procedure TGraphParam.SetTitle(const Value: string);
begin
  if FTitle <> Value then
   begin
    FTitle := Value;
    if not (csLoading in Plot.ComponentState) and Plot.HandleAllocated then Plot.AsyncRepaint;
   end;
end;

procedure TGraphParam.SetHideInLegend(const Value: boolean);
begin
  if FHideInLegend <> Value then
   begin
    FHideInLegend := Value;
    if FHideInLegend then FVisible := True;
    if not (csLoading in Plot.ComponentState) and Plot.HandleAllocated  then
      Plot.UpdateALL([uScrollRect, uLegendHeight, uBitmapLegend, uBitmapData, uScrollBar, uPrepareLegend, uPaintLegend, uAsyncPrepareData, uAsyncPaintData]);
    end;
end;

procedure TGraphParam.SetVisible(const Value: Boolean);
begin
  if FVisible <> Value then
   begin
    if FHideInLegend then FVisible := True
    else FVisible := Value;
    if not (csLoading in Plot.ComponentState) and Plot.HandleAllocated then Plot.AsyncRepaint;
   end;
end;

procedure TGraphParam.SetWidth(const Value: Single);
begin
  if FWidth <> Value then
   begin
    FWidth := Value;
    if not (csLoading in Plot.ComponentState) and Plot.HandleAllocated  then
       Plot.UpdateALL([uScrollRect, uLegendHeight, uBitmapLegend, uBitmapData, uScrollBar, uPrepareLegend,
                             uPaintLegend, uAsyncPrepareData, uAsyncPaintData]);
   end;
end;
{$ENDREGION}

{$REGION 'H I N T'}

{ THintData }

function THintData.CheckHint(Col: TPlotColumn): boolean;
begin
  Result := False;
  if Column <> Col then
   begin
    Application.HideHint;
    Column := Col;
    Tic := GetTickCount;
    ShowCounter := -1;
    DataPoint.X:= -1;
   end
  else if Assigned(Column) and (GetTickCount-Tic >= 300) then
   begin
    Inc(ShowCounter);
    Result := True;
   end;
end;

procedure THintData.Hide();
begin
  if Assigned(Column) then
   begin
    Column.DoHideHint();
    Column.Plot.ShowHint := False;
   end;
  Column := nil;
end;

procedure THintData.HideWait(Col: TPlotColumn);
begin
  if ShowCounter >= 0 then
   begin
    ShowCounter := -1;
    Tic := GetTickCount;
   end
  else if (not Assigned(Col) or (Column = Col)) and (GetTickCount-Tic >= 300) then Hide;
end;

{ TColumnHint }

procedure TColumnHint.Paint;
var
  R, ClipRect: TRect;
  LColor: TColor;
  LStyle: TCustomStyleServices;
  LDetails: TThemedElementDetails;
  LGradientStart, LGradientEnd: TColor;
begin
  R := ClientRect;
  LStyle := StyleServices;
  if LStyle.Enabled then
  begin
    ClipRect := R;
    InflateRect(R, 4, 4);
    if TOSVersion.Check(6) and LStyle.IsSystemStyle then
    begin
      // Paint Windows gradient background
      LStyle.DrawElement(Canvas.Handle, LStyle.GetElementDetails(tttStandardNormal), R, ClipRect);
    end
    else
    begin
      LDetails := LStyle.GetElementDetails(thHintNormal);
      if LStyle.GetElementColor(LDetails, ecGradientColor1, LColor) and (LColor <> clNone) then
        LGradientStart := LColor
      else
        LGradientStart := clInfoBk;
      if LStyle.GetElementColor(LDetails, ecGradientColor2, LColor) and (LColor <> clNone) then
        LGradientEnd := LColor
      else
        LGradientEnd := clInfoBk;
      GradientFillCanvas(Canvas, LGradientStart, LGradientEnd, R, gdVertical);
    end;
    R := ClipRect;
  end;
  Inc(R.Left, 2);
  Inc(R.Top, 2);
  Canvas.Font := Font;
  Canvas.Font.Color := ScreenColor;
  DrawText(Canvas.Handle, Caption, -1, R, DT_LEFT or DT_NOPREFIX or
    DT_WORDBREAK or DrawTextBiDiModeFlagsReadingOnly);
  HintWindowClass := THintWindow;
end;

{$ENDREGION}

{ TCustomPlot.TRenderTask }

constructor TCustomPlot.TRenderTask.Create(ARender, AShow: TRenderProc);
begin
  Render := ARender;
  Show := AShow;
end;

{ TCustomPlot.TQeRender }

function TCustomPlot.TQeRender.CompareTask(ToQeTask, InQeTask: TRenderTask): Boolean;
begin
  if TMethod(ToQeTask.Render) = TMethod(InQeTask.Render) then
   Result := True
  else Result := False;
end;

procedure TCustomPlot.TQeRender.Exec(data: TRenderTask);
begin
  if Assigned(data.Render) then
   begin
//    LockExec.Acquire;
//    try
     data.Render();
//    finally
//     LockExec.Release;
//    end;
   end;
//  if Terminated then Exit;
  if Assigned(data.Show) then
   begin
//    TDebug.Log('BEGIN Synchronize(data.Show);');
    Synchronize(data.Show);
//    TDebug.Log('---END Synchronize(data.Show);');
   end;
end;

{ TCustomPlot }

function TCustomPlot.GetColumnsClass: TPlotColumnsClass;
begin
  Result := TPlotColumns;
end;

constructor TCustomPlot.Create(AOwner: TComponent);
 var
  G: TGPGraphics;
begin
  inherited;
  FRender := TQeRender.Create(False, 'PLOT');
  FColumns := GetColumnsClass.Create(Self);
  FIncrementY := 20;
  Mirror := 1;
  FPresizionY := 2;
  FPresetScaleY := SCALE_ONE;
  FTitle := 'Глубина';
  FEUnit := 'метры';
  FScaleY := 1;
  FShowLegend := True;

  DataBitmap := TBitmap.Create;
  LegendBitmap := TBitmap.Create;
  DataBitmap.SetSize(100,100);
  LegendBitmap.SetSize(100,100);

  ScaleFactor := 1;
  FCursorY := NULL_VALL;
  GDIPlus.Lock;
  G := TGPGraphics.Create(LegendBitmap.Canvas.Handle);
  try
   Ydpmm := G.GetDpiY/2.54;
   Xdpmm := G.GetDpiX/2.54;
  finally
   g.Free;
   GDIPlus.UnLock;
  end;
end;

procedure TCustomPlot.CreateWnd;
begin
  Include(FStates, psSizing);
  inherited;
//  if CanFocus then SetFocus(); { TODO : ошибка когда скрытое окно забыл зачем нужен фокус}
  Exclude(FStates, psSizing);
end;

destructor TCustomPlot.Destroy;
begin
  FRender.Terminate;
  FRender.WaitFor;
  FRender.Free;
  FColumns.Free;
  DataBitmap.Free;
  LegendBitmap.Free;
  inherited;
end;

procedure TCustomPlot.BeginUpdate;
begin
  Include(FStates, psUpdating);
end;

procedure TCustomPlot.EndUpdate;
begin
  Exclude(FStates, psUpdating);
end;

procedure TCustomPlot.Exec(Func: TExecFunc);
 var
  c: TPlotColumn;
begin
  for c in Columns do c.Exec(Func);
end;

procedure TCustomPlot.AsyncRun(Async, AfrerSync: TRenderProc);
begin
  FRender.Enqueue(TRenderTask.Create(Async, AfrerSync), FRender.CompareTask);
end;

{$REGION 'Сериализация коллекции с у которой элементы разные классы'}
procedure TCustomPlot.DefineProperties(Filer: TFiler);
begin
  inherited DefineProperties(Filer);
  FColumns.RegisterProperty(Filer, 'PlotColumns');
//  Filer.DefineProperty('PlotColumns', ReadColumns, WriteColumns, True);
end;

{type
   TmyReader = class(TReader);
   TmyWriter = class(TWriter);

procedure TCustomPlot.ReadColumns(Reader: TReader);
 var
  Item: TPersistent;
begin
  FColumns.BeginUpdate;
  with TmyReader(Reader) do
   try
    if NextValue = vaCollection then ReadValue;
    if not EndOfList then FColumns.Clear;
    while not EndOfList do
     begin
      if NextValue in [vaInt8, vaInt16, vaInt32] then ReadInteger;
      ReadListBegin;
      ReadStr; //'ItemClassName' - property
      Item := FColumns.Add(ReadString); // - value
      while not EndOfList do ReadProperty(Item);
      ReadListEnd;
     end;
    ReadListEnd;
   finally
    FColumns.EndUpdate;
   end;
end;

procedure TCustomPlot.WriteColumns(Writer: TWriter);
var
  I: Integer;
  OldAncestor: TPersistent;
begin
  with TmyWriter(Writer) do
   begin
    OldAncestor := Ancestor;
    try
     Ancestor := nil;
     WriteValue(vaCollection);
      for I := 0 to FColumns.Count - 1 do
       begin
        WriteListBegin;
        WritePropName('ItemClassName');
        WriteString(FColumns.Items[I].ClassName);
        WriteProperties(FColumns.Items[I]);
        WriteListEnd;
       end;
     WriteListEnd;
    finally
     Ancestor := OldAncestor;
    end;
   end;
end;          }
{$ENDREGION}

procedure TCustomPlot.DoContextPopup(MousePos: TPoint; var Handled: Boolean);
 var
  c: TPlotColumn;
begin
  inherited;
  if Handled then Exit;
  for c in Columns do if (c.Left < MousePos.X) and (c.Right > MousePos.X) then
   begin
    c.DoContextPopup(MousePos, Handled);
    Break;
   end;
end;

function TCustomPlot.UpdateALL(const tsk: TUpdates): TUpdates;
begin
  Result := [];
  if (csLoading in ComponentState) then Exit;
  if uColunsWidth in tsk then UpdateColumns;
  if uLegendHeight in tsk then Result := Result + UpdateLegendHeight;
  if uScrollRect in tsk then UpdateScrollRect;
  if uBitmapLegend in tsk then Result := Result + UpdateSizeBitmapLegend;
  if uBitmapData in tsk then Result := Result + UpdateSizeBitmapData;
  if uScrollBar in tsk then UpdateVerticalScrollBar;
  if uPrepareLegend in tsk then DoPrepareLegend;
  if ShowLegend and (uPaintLegend in tsk) then DoPaintLegend;
  if uPaintData in tsk then DoPaintData;
  if uAsyncPrepareData in tsk then
    if uAsyncPaintData in tsk then AsyncRun(DoPrepareData, DoPaintData)
    else AsyncRun(DoPrepareData, nil);
  if uSyncPrepareData in tsk then
    if uSyncPaintData in tsk then
     begin
      DoPrepareData;
      DoPaintData;
     end
    else DoPrepareData;
end;

procedure TCustomPlot.UpdateAllAndRepaint;
begin
  UpdateALL([uColunsWidth, uScrollRect, uLegendHeight, uBitmapLegend, uBitmapData, uScrollBar, uPrepareLegend,
             uPaintLegend, uAsyncPrepareData, uAsyncPaintData]);
end;

function TCustomPlot.UpdateSizeBitmapData: TUpdates;
begin
  DataBitmap.Canvas.Lock;
  try
   if (DataBitmap.Width < ClientWidth) or (DataBitmap.Height < ScrollRect.Height) then
    begin
     DataBitmap.SetSize(ClientWidth, ScrollRect.Height);
     Result := [uBitmapData]
    end
   else Result := []
  finally
   DataBitmap.Canvas.Unlock;
  end;
end;

function TCustomPlot.UpdateSizeBitmapLegend: TUpdates;
begin
  if (LegendBitmap.Width < ClientWidth) or (LegendBitmap.Height < LegendHeight) then
   begin
    LegendBitmap.SetSize(ClientWidth, LegendHeight);
    Result := [uBitmapLegend]
   end
  else Result := []
end;

procedure TCustomPlot.UpdateColumns;
 var
  lf, i: Integer;
begin
  if Columns.Count = 0 then Exit;
  lf := 0;
  for i := 0 to Columns.Count-2 do
   begin
    Columns.Items[i].FLeft := lf;
    Inc(lf, Columns.Items[i].Width);
   end;
  Columns.Items[Columns.Count-1].FLeft := lf;
  Columns.Items[Columns.Count-1].Width := ClientWidth - lf;   // последняя колонка переменной ширины
end;

procedure TCustomPlot.UpdateDataAndRepaint;
begin
  AsyncRun(DoPrepareData, DoPaintData);
end;

function TCustomPlot.UpdateLegendHeight: TUpdates;
 var
  G: TGPGraphics;
  c: TPlotColumn;
  lh: Integer;
begin
  if not HandleAllocated then Exit;
  GDIPlus.Lock;
  G := TGPGraphics.Create(LegendBitmap.Canvas.Handle);
  try
   lh := 64;
   for c in Columns do c.CalcLegendHeight(G, lh);
  finally
   G.Free;
   GDIPlus.UnLock;
  end;
  if LegendHeight <> lh then Result := [uLegendHeight] else Result := [];
  LegendHeight := lh;
end;

procedure TCustomPlot.UpdateScrollRect;
  var
  last_mirror: Boolean;
begin
  if not HandleAllocated then Exit;
  last_mirror := (OffsetY = (ScrollRect.Height - Range)) and (Mirror = -1);
  ScrollRect := ClientRect;
  if FShowLegend then
   begin
    if LegendHeight > ScrollRect.Height then ScrollRect.Height := 1
    else ScrollRect.Height := ScrollRect.Height - LegendHeight;
    if last_mirror then
     begin
      if not (csLoading in ComponentState) and (Range > 1)  then OffsetY := ScrollRect.Height - Range;
      Exit;
     end;
   end;
  if not (csLoading in ComponentState) and (Range > 1) and (OffsetY < (ScrollRect.Height - Range)) then
   begin
    OffsetY := ScrollRect.Height - Range;
    if OffsetY > 0 then OffsetY := 0;
   end;
end;

procedure TCustomPlot.UpdateVerticalScrollBar();
 var
  ScrollInfo: TScrollInfo;
  ofY: Integer;
begin
  if  not HandleAllocated or (csLoading in ComponentState)  then Exit;
  ScrollInfo.cbSize := SizeOf(ScrollInfo);
  ScrollInfo.fMask := SIF_ALL;
  ScrollInfo.nMin := 0;
  if Range > ScrollRect.Height then ScrollInfo.nMax := Range else  ScrollInfo.nMax := 0;
  ScrollInfo.nPage := Max(1, ScrollRect.Height);
  if Mirror = 1 then ofY :=  -OffsetY
  else ofY := Range + OffsetY - ScrollRect.Height;
  ScrollInfo.nPos := OfY;
  ScrollInfo.nTrackPos := OfY;
  FlatSB_SetScrollInfo(Handle, SB_VERT, ScrollInfo, True);
end;


{ TODO : написать  ADDData RecalcScale только для последних данных}
procedure TCustomPlot.UpdateMinMaxY(ForceScale: boolean);
 var
  c: TPlotColumn;
  mx, mi: Double;
  OldFirstY, OldLastY: Integer;
begin
  mi := 1000000;
  mx := -1;
  OldFirstY := FirstY;
  OldLastY := LastY;
  { TODO : перерисать оптимально т.к . RecalcScale длительная операция }
  for c in Columns do
   begin
    c.UpdateMinMaxY(mi, mx);
    if mi < mx then
     begin
      FirstY := Trunc(mi);
      FirstY := FirstY div 10 * 10;
      LastY :=  Trunc(mx)+1;
     end;
   end;
  if (OldFirstY = FirstY) and (OldLastY = LastY) and not ForceScale then Exit;
  for c in Columns do if c is TGraphColumn then TGraphColumn(c).RecalcScale;
end;

procedure TCustomPlot.Update0Position;
begin
  if HandleAllocated then
   begin
    if Mirror = -1 then SetOffsetY(-10000000, True)
    else SetOffsetY(0, True);
    Exclude(FStates, psScrolling);
    UpdateVerticalScrollBar;
   end;
end;

function TCustomPlot.LegendRect: TRect;
begin
  Result := ClientRect;
  Result.Height := LegendHeight;
end;

function TCustomPlot.CreateGPFont: TGPFont;
 var
  f: TFontStyles;
begin
   f := Font.Style;
  Result := TGPFont.Create(Font.Name, Font.Size, PInteger(@F)^);
end;

function TCustomPlot.IsLegend(Y: Integer): Boolean;
begin
  Result := ShowLegend and (Y < LegendHeight);
end;

procedure TCustomPlot.KeyPress(var Key: Char);
begin
  if CharInSet(AnsiString(Key)[1], ['L','l','Д','д']) then ShowLegend := not ShowLegend
  else if CharInSet(AnsiString(Key)[1],['C','c','С','с']) then GoToBookmark;
  inherited;
end;

{$REGION 'SCROLL DATA'}
function TCustomPlot.Range: Integer;
begin
  Result := Trunc(RangeY * ScaleY*Ydpmm)+1;
end;

function TCustomPlot.RangeY: Integer;
begin
  Result := LastY - FirstY;
end;

procedure TCustomPlot.SetScaleY(const Value: Double);
 var
  p: TCollectionItem;
begin
  if FScaleY <> Value then
   begin
    if Mirror = 1 then OffsetY := Round(OffsetY *Value/FScaleY)
    else OffsetY := Round((OffsetY- ScrollRect.Height)*Value/FScaleY+ ScrollRect.Height);
    FScaleY := Value;
    for p in FColumns do if p is TGraphColumn then TGraphColumn(p).RecalcScale();
    if HandleAllocated then
     begin
      UpdateVerticalScrollBar;
      SetOffsetY(OffsetY, True);
      Exclude(FStates, psScrolling);
      if Assigned(FOnScaleChanged) then FOnScaleChanged(Self);
     end;
   end;
end;

procedure TCustomPlot.SetShowLegend(const Value: Boolean);
begin
  if (FShowLegend <> Value) then
   begin
    FShowLegend := Value;
    if not (csLoading in ComponentState) then
      UpdateALL([uScrollRect, uBitmapLegend, uBitmapData, uScrollBar, uPrepareLegend, uPaintLegend, uAsyncPrepareData, uAsyncPaintData]);
   end;
end;

procedure TCustomPlot.SetYOffset(const Value: Integer);
begin
  OffsetY := Value;
end;

procedure TCustomPlot.SetBookmark(Y: Integer);
begin
  CursorY := MouseYtoParamY(Y);
end;

procedure TCustomPlot.SetCursorY(const Value: Double);
begin
  FCursorY := Value;
end;

function TCustomPlot.SetOffsetY(Y: Integer; NeedRepaint: Boolean = False): Boolean;
 var
  DeltaY, ofY: Integer;
begin
  if Y < (ScrollRect.Height - Range) then Y := ScrollRect.Height - Range;
  if Y > 0 then Y := 0;
  DeltaY := Y - OffsetY;
  Result := (DeltaY <> 0);
  if Result or NeedRepaint then
   begin
    OffsetY := Y;
    Include(FStates, psScrolling);
    //Рисуем скроллбар
    if Mirror = 1 then ofY :=  -OffsetY
    else ofY := Range + OffsetY - ScrollRect.Height;
    if FlatSB_GetScrollPos(Handle, SB_VERT) <> -OffsetY then FlatSB_SetScrollPos(Handle, SB_VERT, OfY, True);

    if ScrollRect.Height > 0 then AsyncRun(DoPrepareData, DoPaintData);
   end;
end;

procedure TCustomPlot.SetPresetScaleY(const Value: integer);
begin
  if FPresetScaleY <> Value then
   begin
    if Value < 0 then FPresetScaleY := 0
    else if Value > High(SCALE_PRESET) then FPresetScaleY := High(SCALE_PRESET)
    else FPresetScaleY := Value;
    if HandleAllocated then ScaleY := SCALE_PRESET[FPresetScaleY]* ScaleFactor;
   end;
end;

procedure TCustomPlot.WMSize(var Message: TWMSize);
begin
  inherited;
  if HandleAllocated and (([psSizing, psUpdating] * FStates) = []) and (ClientHeight > 0) and not (csLoading in ComponentState) then
   try
    Include(FStates, psSizing);
    TDebug.Log(' *** TCustomPlot.WMSize  ****    ');                                                                             //??????
    UpdateALL([uColunsWidth, uLegendHeight, uScrollRect, uBitmapLegend, uBitmapData, uScrollBar, uPrepareLegend, uPaintLegend, uSyncPrepareData]);
   finally
    Exclude(FStates, psSizing);
   end;
end;

procedure TCustomPlot.CMHintShow(var Message: TCMHintShow);
begin
  with Message.HintInfo^ do  HintPos := FHintData.DataPoint;
end;

procedure TCustomPlot.CMMouseWheel(var Message: TCMMouseWheel);
 var
  ScrollAmount: Integer;
  ScrollLines: DWORD;
  WheelFactor: Double;
begin
  inherited;
  if Message.Result = 0  then
  begin
    with Message do
    begin
     Result := 1;
     if ([psPainting, {psScrolling,} psUpdating] * FStates) <> [] then Exit;
     if ssShift in ShiftState then
      begin
       if WheelDelta > 0 then PresetScaleY := PresetScaleY+1 else PresetScaleY := PresetScaleY-1
      end
     else if Range > ScrollRect.Height then
      begin
       WheelFactor := WheelDelta / WHEEL_DELTA;
       if ssCtrl in ShiftState then ScrollAmount := Trunc(WheelFactor * ScrollRect.Height)
       else
        begin
         SystemParametersInfo(SPI_GETWHEELSCROLLLINES, 0, @ScrollLines, 0);
         if ScrollLines = WHEEL_PAGESCROLL then ScrollAmount := Trunc(WheelFactor * ScrollRect.Height)
         else ScrollAmount := Trunc(WheelFactor * ScrollLines * Ydpmm);
        end;
       SetOffsetY(OffsetY + Mirror*ScrollAmount);
       Exclude(FStates, psScrolling);
      end
    end;
  end;
end;

procedure TCustomPlot.WMVScroll(var Message: TWMVScroll);
  function GetRealScrollPosition: Integer;
   var
    SI: TScrollInfo;
    Code: Integer;
  begin
    SI.cbSize := SizeOf(TScrollInfo);
    SI.fMask := SIF_TRACKPOS;
    Code := SB_VERT;
    FlatSB_GetScrollInfo(Handle, Code, SI);
    if Mirror = 1 then Result := SI.nTrackPos
    else Result := Range - SI.nTrackPos - ScrollRect.Height
  end;
begin
  case Message.ScrollCode of
    SB_BOTTOM:      SetOffsetY(-Range);
    SB_ENDSCROLL:
     begin
      UpdateVerticalScrollBar();
      Exclude(FStates, psScrolling);
     end;
    SB_LINEUP:      SetOffsetY(OffsetY + Mirror*FIncrementY);
    SB_LINEDOWN:    SetOffsetY(OffsetY - Mirror*FIncrementY);
    SB_PAGEUP:      SetOffsetY(OffsetY + Mirror*ScrollRect.Height);
    SB_PAGEDOWN:    SetOffsetY(OffsetY - Mirror*ScrollRect.Height);
    SB_THUMBPOSITION,
    SB_THUMBTRACK:  SetOffsetY(-GetRealScrollPosition);
    SB_TOP:         SetOffsetY(0);
  end;
  Message.Result := 0;
end;
{$ENDREGION 'SCROLL BAR'}

{$REGION 'MOVE, RESIZE COLUMN HIT'}

procedure TCustomPlot.DrawCrossLine(X, Y: Integer);
 procedure DrowCr;
 begin
   if ShowLegend then Canvas.MoveTo(FChangeLeft, LegendHeight)
   else Canvas.MoveTo(FChangeLeft, 0);
   Canvas.LineTo(FChangeLeft, ClientHeight);
   Canvas.MoveTo(0, FChangePos);
   Canvas.LineTo(Clientwidth, FChangePos);
 end;
begin
  Canvas.Pen.Color := clBlack;
  Canvas.Pen.Style := psDot;
  Canvas.Pen.Mode := pmXor;
  Canvas.Pen.Width := 1;
  if FHorizontShowed then DrowCr;
  FChangeLeft := X;
  FChangePos := Y;
  DrowCr;
  FHorizontShowed := True;
end;

procedure TCustomPlot.DrawMovingLine;
begin
  Canvas.Pen.Color := clWhite;
  Canvas.Pen.Style := psDot;
  Canvas.Pen.Mode := pmXor;
  Canvas.Pen.Width := 5;
  Canvas.MoveTo(FChangeLeft, 0);
  Canvas.LineTo(FChangeLeft, ClientHeight);
end;

procedure TCustomPlot.DrawSizingLine;
begin
  Canvas.Pen.Color := clBlack;
  Canvas.Pen.Style := psDot;
  Canvas.Pen.Mode := pmXor;
  Canvas.Pen.Width := 1;
  Canvas.MoveTo(FChangePos, 0);
  Canvas.LineTo(FChangePos, ClientHeight);
end;

procedure TCustomPlot.CMParentFontChanged(var Message: TCMParentFontChanged);
begin
  inherited;
  if not HandleAllocated then Exit;
  UpdateALL([uLegendHeight, uScrollRect, uBitmapLegend, uBitmapData, uScrollBar, uPrepareLegend, uPaintLegend, uAsyncPrepareData])
end;

procedure TCustomPlot.WMNCHitTest(var Msg: TWMNCHitTest);
begin
  DefaultHandler(Msg);
  FHitTest := ScreenToClient(SmallPointToPoint(Msg.Pos));
end;

function TCustomPlot.CheckMousePosition(cms: TCheckMouses; X, Y: Integer; func: TCheckMouseFunc): Boolean;
 var
  c: TPlotColumn;
  Yd: integer;
begin
  Result := False;
  if cmColSize in cms then for c in Columns do
    if (Abs(c.Right - X) < 7) then Exit(func(cmColSize, c, X, Y));

  if (cmColMove in cms) and (Y < 32) then for c in Columns do
    if (X > c.Left + CHECKBOX_SIZE + CHECKBOX_SIZE div 2) and (X < c.Right) then Exit(func(cmColMove, c, X, Y));

  if ShowLegend and (cmColLegend in cms) and (Y < LegendHeight) then
    for c in Columns do
     if (X > c.Left) and (X < c.Right) then Exit(func(cmColLegend, c, X, Y));

  if FShowLegend then Yd := Y - LegendHeight
  else Yd := Y;
  if (cmColData in cms) and (ClientHeight-Yd > 10) and (Yd > 10) then
    for c in Columns do
     if (X > c.Left+5) and (X < c.Right-5) then Exit(func(cmColData, c, X, Y));
end;

procedure TCustomPlot.WMSetCursor(var Msg: TWMSetCursor);
var
  State: PlotColState;
  Cur: HCURSOR;
begin
  Cur := 0;
  State := pcsNormal;
  if Msg.HitTest = HTCLIENT then
   begin
    if FColState = pcsNormal then CheckMousePosition([cmColSize, cmColData], FHitTest.X, FHitTest.Y,
     function (cm: TCheckMouse; Col: TPlotColumn; X, Y: integer): boolean
     begin
       Result := True;
       case cm of
        cmColSize: State := pcsSizing;
        cmColData: Col.DoSetCursorInData(FHitTest.X, Y, State, Cur);
       end;
     end)
    else State := FColState;
    if (State = pcsSizing) then Cur := Screen.Cursors[crHSplit]
    else if State = pcsMoving then Cur := Screen.Cursors[crDrag]
   end;
  if Cur <> 0 then SetCursor(Cur) else inherited;
end;

procedure TCustomPlot.MouseDown(Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
begin
  try
   FHintData.Hide;
   if not (csDesigning in ComponentState) and (CanFocus or (GetParentForm(Self) = nil)) then
    begin
     SetFocus;
    end;
   if (Button = mbLeft) and (ssDouble in Shift) then  DblClick
   else if Button = mbLeft then CheckMousePosition([cmColSize, cmColMove, cmColData, cmColLegend], FHitTest.X, FHitTest.Y,
    function (cm: TCheckMouse; Col: TPlotColumn; X, Y: integer): boolean
    begin
      Result := True;
      case cm of
       cmColSize:
        begin
         FColState := pcsSizing;
         FChangeColumn := Col;
         FChangePos := Col.Right;
         FChangeLeft := Col.Left;
         DrawSizingLine;
        end;
       cmColMove:
        begin
         FColState := pcsMoving;
         FChangeColumn := Col;
         FSwapColumn := Col;
         FChangeLeft := Col.Left;
         DrawMovingLine;
         SetCursor(Screen.Cursors[crDrag]);
        end;
       cmColData:
        begin
         FSelectedColumn := Col;
         if Col.CheckMouseDownInData(X, Y, Shift) then
          begin
           FColState := pcsColumnData;
           FChangeColumn := Col;
           FChangeLeft := Col.Left;
          end;
        end;
       cmColLegend: Col.DoMouseDownInLegend(X, Y);
      end;
    end)
  finally
   inherited;
  end;
end;

procedure TCustomPlot.MouseMove(Shift: TShiftState; X, Y: Integer);
 var
  c: TPlotColumn;
begin
//  TDebug.Log(FloatToStr(ParamYToY(MouseYtoParamY(Y))));

  case FColState of
   pcsSizing:
    begin
     DrawSizingLine();
     FChangePos := X;
     DrawSizingLine();
    end;
   pcsMoving: for c in Columns do if (X < c.Right) and (X > c.Left) and (FSwapColumn <> c) then
    begin
     DrawMovingLine;
     FSwapColumn := c;
     FChangeLeft := c.Left;
     DrawMovingLine;
     Break;
    end;
   pcsColumnData:
    begin
     if FShowLegend then Y := Y - LegendHeight;
     FChangeColumn.DoMouseMoveInData(X, Y);
    end;
   pcsNormal: if not IsLegend(Y) then DrawCrossLine(X, Y);
  end;
  inherited;
end;

procedure TCustomPlot.AsyncRepaint;
begin
  if ([psPainting, psScrolling, psUpdating] * FStates) <> [] then Exit;
  DoPrepareLegend;
  if ShowLegend then DoPaintLegend;
  AsyncRun(DoPrepareData, DoPaintData);
end;

procedure TCustomPlot.MouseUp(Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
  procedure rep;
  begin
    UpdateColumns;
    AsyncRepaint;
  end;
begin
  try
   case FColState of
    pcsSizing:
     begin
      DrawSizingLine();
      FChangePos := X;
      FChangeColumn.Width := FChangePos - FChangeLeft;
      rep;
     end;
    pcsMoving:
     begin
      DrawMovingLine();
      FChangeColumn.Index := FSwapColumn.Index;
      rep;
     end;
    pcsColumnData:
     begin
      if FShowLegend then Y := Y - LegendHeight;
      FChangeColumn.DoMouseUpInData(X, Y);
     end;
  end;
  finally
   FColState := pcsNormal;
  end;
  inherited;
end;

{$ENDREGION}

function TCustomPlot.MouseYtoParamY(Y: Integer): Double;
begin
  if ShowLegend then Y := Y-LegendHeight;
 //scaledY
  if Mirror = 1 then Result := -OffsetY+Y else Result := OffsetY - ScrollRect.Height + Y;
 //RealY
  Result := Result/(Mirror*Ydpmm*ScaleY) + FirstY;
end;

function TCustomPlot.ParamYToY(Y: Double): Double;
begin
 //scaledY
  Y := (Y-FirstY)*Mirror*Ydpmm*ScaleY;
 //screenY
  if Mirror = 1 then Result := OffsetY+Y else Result := -OffsetY + ScrollRect.Height + Y;
end;

procedure TCustomPlot.GoToBookmark;
 var
  y: Double;
  off: double;
begin
  if FCursorY = NULL_VALL then Exit;
  Y := ParamYToY(FCursorY);
  off := ScrollRect.Height/2;
  if ShowLegend then off := off - LegendHeight/2;
  SetOffsetY(Round(OffsetY +Mirror*(off - Y)));
  Exclude(FStates, psScrolling);
end;


{$REGION 'P A I N T'}
procedure TCustomPlot.ShowYWalls(G: TGPGraphics; top, Height: integer);
 var
  pn: TGPPen;
  i: Integer;
begin
  pn := TGPPen.Create(aclBlack, 1);
  try
  for i := 1 to Columns.Count-1 do G.DrawLine(pn, TPlotColumn(Columns.Items[i]).Left, top, TPlotColumn(Columns.Items[i]).Left, Height);
  finally
   pn.Free;
  end;
end;

procedure TCustomPlot.ShowCursorY(G: TGPGraphics);
  var
   Y: Double;
  pn: TGPPen;
begin
  if FCursorY <> NULL_VALL then
   begin
    Y := ParamYToY(FCursorY);
    if (Y >= 0) and (Y <= ScrollRect.Height) then
     begin
      pn := TGPPen.Create(ACL_CURSOR, 8);
      try
       G.DrawLine(pn, 0, Y, ClientWidth, Y);
      finally
       pn.Free;
      end;
     end;
   end;
end;

procedure TCustomPlot.ShowXAxis(G: TGPGraphics);
  var
   pn: TGPPen;
   Y: Double;
begin
  pn := TGPPen.Create(ACL_AXIS, 1);
  try
    if Mirror = 1 then g.TranslateTransform(0, OffsetY)
    else g.TranslateTransform(0, -OffsetY+ScrollRect.Height);

    Y := 2*Ydpmm*Trunc(-OffsetY/Ydpmm/2);
    while Y < (-OffsetY + ScrollRect.Height) do
     begin
      G.DrawLine(pn, 0, Y*Mirror, ClientWidth, Y*Mirror);
      Y := Y + Ydpmm*2;
     end;
  finally
   pn.Free;
  end;
end;

procedure TCustomPlot.DoPrepareData();
 var
  c: TPlotColumn;
  g: TGPGraphics;
  sb: TGPSolidBrush;
begin
  if psUpdating in FStates then Exit;
  Include(FStates, psUpdating);
//  TDebug.Log('  PrepareData() START---------');
  DataBitmap.Canvas.Lock;
//  TDebug.Log('  PrepareData() START++++++++++');
  try
   GDIPlus.Lock;
//   TDebug.Log('  PrepareData() START===== ');
   g := TGPGraphics.Create(DataBitmap.Canvas.Handle);
   sb := TGPSolidBrush.Create(ColorRefToARGB(color));
   try
    G.FillRectangle(sb, MakeRect(ScrollRect));
    ShowCursorY(G);
    ShowXAxis(G);
    G.ResetTransform;
    for c in Columns do
     begin
      c.ShowData(G);
      G.TranslateTransform(TPlotColumn(c).Width, 0);
     end;
    G.ResetTransform;
    ShowYWalls(G, 0, ScrollRect.Height);
   finally
    sb.Free;
    g.Free;
    GDIPlus.UnLock;
   end;
  finally
   DataBitmap.Canvas.Unlock;
//   TDebug.Log('  PrepareData() E N D ');
   Exclude(FStates, psUpdating);
  end;
end;

procedure TCustomPlot.DoPrepareLegend();
 var
  c: TPlotColumn;
  g: TGPGraphics;
  sb: TGPSolidBrush;
  p : TGPPen;
begin
  GDIPlus.Lock;
  G := TGPGraphics.Create(LegendBitmap.Canvas.Handle);
  sb := TGPSolidBrush.Create(ColorRefToARGB(color));
  p := TGPPen.Create(aclBlack, 1);
  try
   G.FillRectangle(sb, MakeRect(LegendRect));
   for c in Columns do
    begin
     c.ShowLegend(G, LegendHeight);
     G.TranslateTransform(TPlotColumn(c).Width, 0);
    end;
   G.ResetTransform;
   ShowYWalls(G, 0, LegendHeight-1);
   G.DrawLine(p, 0, LegendHeight-1, ClientWidth, LegendHeight-1);
  finally
   p.Free;
   sb.Free;
   g.free;
   GDIPlus.UnLock;
  end;
end;

procedure TCustomPlot.DoPaintData();
begin
//  TDebug.Log('  DoPaintData() START ');
  DataBitmap.Canvas.Lock;
  try
   if ShowLegend then BitBlt(Canvas.Handle, 0, LegendHeight, ClientWidth, ScrollRect.Height, DataBitmap.Canvas.Handle, 0, 0, SRCCOPY)
   else BitBlt(Canvas.Handle, 0, 0, ClientWidth, ScrollRect.Height, DataBitmap.Canvas.Handle, 0, 0, SRCCOPY);
   FHorizontShowed := False;
  finally
   DataBitmap.Canvas.Unlock;
  end;
//  TDebug.Log('  DoPaintData() E N D ');
end;

procedure TCustomPlot.DoPaintLegend();
begin
  BitBlt(Canvas.Handle, 0,0, ClientWidth, LegendHeight, LegendBitmap.Canvas.Handle, 0, 0, SRCCOPY);
end;

procedure TCustomPlot.DoParamXAxisChanged(Column: TGraphColumn; Param: TGraphParam; ChangeState: TChangeStateParam);
begin
  if Assigned(FOnParamXAxisChanged) then FOnParamXAxisChanged(Column, Param, ChangeState);
end;

procedure TCustomPlot.WMEraseBkgnd(var Msg: TWMEraseBkgnd);
begin
  Msg.Result := 1;
end;

procedure TCustomPlot.WMPaint(var Message: TWMPaint);
 var
  PS: TPaintStruct;
begin
//  TDebug.Log('  P A I N T   ');                                                      ;
  if (([psPainting, psScrolling, psUpdating] * FStates) <> []) or (Columns.Count <= 0) then Exit;
  Include(FStates, psPainting);
  BeginPaint(Handle, PS);
  try
   if ShowLegend then DoPaintLegend();
   DoPaintData();
  finally
   EndPaint(Handle, PS);
   Exclude(FStates, psPainting);
  end;
end;

{$ENDREGION}

initialization
  RegisterClasses([TPlotCollection, TPlotColumns, TPlotColumn, TYColumn, TGraphColumn, TPlot, TGraphParams, TGraphParam]);
end.

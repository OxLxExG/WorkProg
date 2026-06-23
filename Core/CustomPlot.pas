unit CustomPlot;

interface

{$INCLUDE global.inc}

uses
  RootImpl, RootIntf, tools, debug_except, ExtendIntf, FileCachImpl, JDtools, Container,
  Data.DB, DataSetIntf, IDataSets, System.Bindings.Helper, System.IOUtils,
  System.TypInfo, System.UITypes, Vcl.Grids, SysUtils, Controls, Messages,
  Winapi.Windows, Classes, System.Rtti, types, Vcl.Graphics, Vcl.Forms, Vcl.ExtCtrls,
  Vcl.Menus, Vcl.Themes, Vcl.GraphUtil;

const     // X
  SCALE_PRESET_MOUSE: array[-12..14] of Double = (0.0001, 0.0002, 0.0005, 0.001, 0.002, 0.005, 0.01, 0.02, 0.05, 0.1, 0.25, 0.5, 1, 2, 5, 10, 20, 25, 50, 100, 200, 500, 1000, 2000, 5000, 10000, 20000);
  SCALE_PRESET_Y: array[0..17] of Double = (0.0001, 0.0002, 0.0005, 0.001, 0.002, 0.005, 0.01, 0.02, 0.05, 0.1, 0.2, 0.5, 1, 2, 5, 10, 20, 50);
//  const
//    GUID_IDataLinkS = '{421A0AD1-48C0-4DB0-A08D-281E0121C13D}';
//    GUID_IDataLinkT : TGUID = GUID_IDataLinkS;

type
  /// основной класс графиков
  TCustomGraph = class;

  EGraphException = EBaseException;

  /// прямоугольник отрисовки  графиков легенды информации
  TGraphRegion = class;
  /// коллекция хранится в колонке

  TGraphRegions = class;

  /// колонки коллекция
  TGraphColmn = class;

  TGraphColumns = class;
  /// строки коллекция

  TGraphRow = class;

  TGraphRows = class;

  /// содержимое таблиц графиков
  EParamException = class(EGraphException);

  TGraphPar = class;

  TGraphParams = class;
  /// содержимое PARAM

  EParamFilter = class(EParamException);

  TParamFilter = class;

  TParamFilters = class;
  //TDialogAddParamsResult:

{$IFDEF ENG_VERSION}
  [EnumCaptions('ID, frame, Depth(m.), time')]
{$ELSE}
  [EnumCaptions('ID, Кадр, Глубина(м.), Время')]
{$ENDIF}
  TAxisY = (axyID, axyKadr, axyDept, axyTime);

  {$REGION 'всякие коллекции сохраняемые'}
  TGraphCollection = class;

  TGraphCollectionItem = class(TICollectionItem)
  private
    FGraph: TCustomGraph;
  protected
    // FGraph заполнено но коллекция не штшциализированна (Notify не вызывалась)
    procedure DoInitialize; virtual;
  public
    // конструктор вызывается загрузчиком и в CreateNew
    constructor Create(Collection: TCollection); override;
    // конструктор вызывается пользователем при созданн елемента коллекции
    constructor CreateNew(Collection: TGraphCollection); virtual;
    property Graph: TCustomGraph read FGraph;
  end;

  TGraphCollectionItemClass = class of TGraphCollectionItem;

  TGraphCollection = class abstract(TICollection)
  private
    FGraph: TCustomGraph;
  protected
  public
    function Add(const ItemClassName: string): TGraphCollectionItem; reintroduce; overload;
    function Add(ItemClass: TGraphCollectionItemClass): TGraphCollectionItem; reintroduce; overload;
    property Graph: TCustomGraph read FGraph;
  end;

  TGraphCollection<T: TGraphCollectionItem> = class(TGraphCollection)
  private
    type
      TEnumerator = record
      private
        i: Integer;
        FCollection: TGraphCollection<T>;
        function DoGetCurrent: T; inline;
      public
        property Current: T read DoGetCurrent;
        function MoveNext: Boolean; inline;
      end;
  protected
    function GetItem(Index: Integer): T;
    procedure SetItem(Index: Integer; const Value: T);
  public
    function Add<C: T>: C; reintroduce; overload;
    function GetEnumerator: TEnumerator; reintroduce;
    constructor Create(AOwner: TObject); virtual;
    destructor Destroy; override;
    property Items[Index: Integer]: T read GetItem write SetItem; default;
  end;
{$ENDREGION}

  {$REGION ' строки колонки '}
  /// строки колонки общее

  TColRowCollectionItem = class(TGraphCollectionItem)
  private
    FVisible: Boolean;
    procedure SetVisible(const Value: Boolean);
  protected
    FFrom: Integer;
    FLen: Integer;
    procedure DoVisibleChanged; virtual;
    function GetItem(Index: Integer): TGraphRegion; virtual; abstract;
    function GetRegionsCount: Integer; virtual; abstract;
    function GetTo: Integer; inline;
    procedure SetLen(const Value: Integer); inline;
    function AutoSize: Boolean; virtual;
  public
    constructor Create(Collection: TCollection); override;
    procedure Release; override;
    property Regions[Index: Integer]: TGraphRegion read GetItem; default;
    property RegionsCount: Integer read GetRegionsCount;
    property Visible: Boolean read FVisible write SetVisible default True;
  end;

  TCollectionColRows<T: TColRowCollectionItem> = class(TGraphCollection<T>)
  protected
    procedure Notify(Item: TCollectionItem; Action: TCollectionNotification); override;
    function LastToResize(FromLast: integer; ToFirst: Integer = 0): TColRowCollectionItem;
    function GetAllLen: Integer; virtual; abstract;
  public
    procedure UpdateSizes;
  end;

  // строки;
  TGraphRow = class(TColRowCollectionItem, ICaption)
  private
    procedure SetHeight(const Value: Integer);
//  protected
//    FCursor: Integer;
  public
    property Top: Integer read FFrom;
    property Bottom: Integer read GetTo;
//    property Cursor: Integer read FCursor;
  protected
    procedure DoInitialize; override;
    function GetItem(Index: Integer): TGraphRegion; override;
    function GetRegionsCount: Integer; override;
    // ICaption;
    function GetCaption: string; virtual;
    procedure SetCaption(const Value: string);
  published
{$IFDEF ENG_VERSION}
    [ShowProp('Row height')]
{$ELSE}
    [ShowProp('Высота строки')]
{$ENDIF}
    property Height: Integer read FLen write SetHeight;
  end;

  TGraphRowClass = class of TGraphRow;

  TGraphRows = class(TCollectionColRows<TGraphRow>)
  protected
    function GetCaption: string; override;
    function GetAllLen: Integer; override;
  public
    function FindRows(rc: TGraphRowClass): TArray<TGraphRow>;
  end;
  // типы строки;

  TNoSizebleGraphRow = class(TGraphRow)
  protected
    function AutoSize: Boolean; override;
  end;

  TCustomGraphLegendRow = class(TNoSizebleGraphRow)
  protected
    function GetCaption: string; override;
  published
{$IFDEF ENG_VERSION}
    [ShowProp('Show legend')]
{$ELSE}
    [ShowProp('Показать легенду')]
{$ENDIF}
    property Visible;
  end;

  TCustomGraphInfoRow = class(TNoSizebleGraphRow)
  protected
    function GetCaption: string; override;
  published
{$IFDEF ENG_VERSION}
    [ShowProp('Show information')]
{$ELSE}
    [ShowProp('Показать информацию')]
{$ENDIF}
    property Visible;
  end;

  TCustomGraphDataRow = class(TGraphRow)
  protected
    function GetCaption: string; override;
  end;

  /// колонки
  TColumnCollectionItem = class;

  TGraphColumnClass = class of TGraphColmn;

  TGraphColmn = class(TColRowCollectionItem)
  public
    type
      TColClassData = record
        ColCls: TGraphColumnClass;
        DisplayName: string;
      end;
  private
    FRegions: TGraphRegions;
    FParams: TGraphParams;
    FOnContextPopup: TContextPopupEvent;
    procedure CreateRegions();
    procedure CreateRegion(Row: TGraphRow);
//    procedure DeleteRegion(Row: TGraphRow);
    procedure UpdateRegionsSize; inline;
    procedure DoContextPopup(MousePos: TPoint; var Handled: Boolean);
    procedure SetWidth(const Value: Integer);
  protected
    procedure DoInitialize; override;
    procedure DefineProperties(Filer: TFiler); override;
    function GetItem(Index: Integer): TGraphRegion; override;
    function GetRegionsCount: Integer; override;
    procedure ColumnCollectionChanged(Collection: TGraphCollection); virtual;
    procedure ColumnCollectionItemChanged(const Item: TColumnCollectionItem); virtual;
    // Хранилище типов колонок
    class procedure ColClsRegister(acc: TGraphColumnClass; const DisplayName: string);
  public
    class var
      ColClassItems: TArray<TColClassData>;
//    constructor Create(Collection: TCollection); override;
//    constructor CreateNew(Collection: TGraphCollection); override;
//    constructor Create(Collection: TCollection); override; final;
    destructor Destroy; override;
    property Left: Integer read FFrom;
    property Right: Integer read GetTo;
    [ShowProp('Regions')]
    property Regions: TGraphRegions read FRegions;
    [ShowProp('Params')]
    property Params: TGraphParams read FParams;
  published
{$IFDEF ENG_VERSION}
    [ShowProp('Show column')]
{$ELSE}
    [ShowProp('Показать колонку')]
{$ENDIF}
    property Visible;
{$IFDEF ENG_VERSION}
    [ShowProp('Column width')]
{$ELSE}
    [ShowProp('Ширина колонки')]
{$ENDIF}
    property Width: Integer read FLen write SetWidth;
    property OnContextPopup: TContextPopupEvent read FOnContextPopup write FOnContextPopup;
  end;

  TGraphColumns = class(TCollectionColRows<TGraphColmn>)
  protected
    function GetCaption: string; override;
    function GetAllLen: Integer; override;
  end;

  TGraphColumnsClass = class of TGraphColumns;
{$ENDREGION}

  {$REGION 'коллекции хранящиеся в колонке: параметры, регионы, мeтки глубины'}
  /// коллекция колонки общее

  TColumnCollectionItem = class(TGraphCollectionItem)
  private
    FColumn: TGraphColmn;
  protected
    procedure NotifyCollumn;
  public
    constructor Create(Collection: TCollection); override;
    procedure Release; override;
    property Column: TGraphColmn read FColumn;
  end;

  TColumnCollection<T: TColumnCollectionItem> = class(TGraphCollection<T>)
  private
    FColumn: TGraphColmn;
  public
    constructor Create(AOwner: TObject); override;
    property Column: TGraphColmn read FColumn;
  end;

  {$REGION 'TGraphRegion'}
  /// основной класс отрисовки
  TGraphRegionClass = class of TGraphRegion;

  TGraphRegion = class(TColumnCollectionItem)
  private
    FClientRect: TRect;
    FGraphRow: TGraphRow;
    FOnContextPopup: TContextPopupEvent;
//    function GetRow: string;
    function GetRow: integer;
//    procedure SetRow(const Value: string);
    procedure SetRow(const Value: Integer);
    procedure DoContextPopup(MousePos: TPoint; var Handled: Boolean);
    type
      TRegClsData = record
        pc: TGraphRegionClass;
        rc: TGraphRowClass;
        cc: TGraphColumnClass;
      end;
    class var
      GRegClsItems: TArray<TRegClsData>;
  protected
    СaptureMouseWell: Boolean;
    function GetCursor: Integer; virtual;
    procedure ParentFontChanged; virtual;
    procedure MouseDown(Button: TMouseButton; Shift: TShiftState; X, Y: Integer); virtual;
    procedure MouseMove(Shift: TShiftState; X, Y: Integer); virtual;
    procedure MouseUp(Button: TMouseButton; Shift: TShiftState; X, Y: Integer); virtual;
    procedure MouseWheel(var Message: TCMMouseWheel); virtual;
    procedure SetClientRect(const Value: TRect); virtual;
    procedure UpdateSize;
    procedure Paint; virtual;
  public
    // поиск нкжного класса региона по колонке и ряду
    class procedure RegClsRegister(apc: TGraphRegionClass; arc: TGraphRowClass; acc: TGraphColumnClass);
    class function RegClsFind(arc: TGraphRowClass; acc: TGraphColumnClass): TGraphRegionClass;
    function TryHitParametr(pos: TPoint; out Par: TGraphPar; Button: TMouseButton = mbLeft; Shift: TShiftState = []): Boolean; virtual;
    function MouseToClient(pos: TPoint): TPoint;
    property Row: TGraphRow read FGraphRow write FGraphRow;
    property ClientRect: TRect read FClientRect write SetClientRect;
    property Cursor: Integer read GetCursor;
    class property RegionClasses: TArray<TRegClsData> read GRegClsItems;
  published
  //  property PropRow: string read GetRow write SetRow;
    property PropRow: Integer read GetRow write SetRow;
    property OnContextPopup: TContextPopupEvent read FOnContextPopup write FOnContextPopup;
  end;

  TGraphRegions = class(TColumnCollection<TGraphRegion>)
  protected
    function GetCaption: string; override;
  end;
  {$ENDREGION}

  {$REGION 'Параметры колонки'}

  {$REGION 'DataLink'}

  TFindIndexType = (fndLower, fndHiger, fndNear);

  IDataLink = interface
    ['{1D667235-A468-4DEA-B1AD-4EEF12F4BA25}']
  //private
    procedure SetDrowMemoryBuffer(const Value: IInterface);
    function GetDrowMemoryBuffer: IInterface;
  //public
    function IndexOfY(Y: Double; IndexOfType: TFindIndexType; out Yfind: Double): Integer;
    procedure ResetBuffer;
  /// <summary>
  /// некое хранилище готовых для рендеринга данных массив точек single, fixed для линии или битмап GR32, DGI+ для ФКД
  /// </summary>
    property DrowMemoryBuffer: IInterface read GetDrowMemoryBuffer write SetDrowMemoryBuffer;
  end;

  /// <summary>
  /// привязка к проекту БД, las, lines, или директории с файлами Log Ram Glu
  /// или к файлу активного фильтра
  /// </summary>
  TCustomDataLinkClass = class of TCustomDataLink;

  TCustomDataLink = class(TDataSetFactory, IDataLink, ICaption)
  private
    FOwner: TGraphPar;
   // FIDataSet: IDataSet;
//    FDataSetDef: TIDataSetDef;
    FXParamPath: string;
    FYParamPath: string;
    FDrowMemoryBuffer: IInterface;
    FXFieldDef: TFieldDef;
    FBindWrite: Integer;
//    procedure SetDataSetDef(const Value: TIDataSetDef);
//    function GetDataSetClass: string;
//    procedure SetDataSetClass(const Value: string);
//    function GetDataSet: TDataSet;
//    function GetIDataSet: IDataSet;
    function GetXField: TField;
    function GetXFieldDef: TFieldDef;
    function GetYField: TField;
    function FiendField(const Fullname: string): TField;
    procedure SetBindWriteFile(const Value: Integer);
  protected
    FFieldX: TField;
    FFieldY: TField;
  // IDataLink
    procedure SetDrowMemoryBuffer(const Value: IInterface);
    function GetDrowMemoryBuffer: IInterface;
    function IndexOfY(Y: Double; FindIndexType: TFindIndexType; out YFind: Double): Integer; virtual;
    function GenerateBufferFileName: string; virtual;
    procedure NillDataSet;
    property DrowMemoryBuffer: IInterface read GetDrowMemoryBuffer write SetDrowMemoryBuffer;
    function GetCaption: string; virtual;
    procedure SetCaption(const Value: string);
    procedure ResetBuffer; virtual;
  public
    constructor Create(AOwner: TGraphPar); virtual;
    destructor Destroy; override;
    property Owner: TGraphPar read FOwner;
//    property DataSet: TDataSet read GetDataSet;
//    property DataSetIntf: IDataSet read GetIDataSet;
    property FieldX: TField read GetXField write FFieldX;
    property FieldY: TField read GetYField write FFieldY;
    property XFieldDef: TFieldDef read GetXFieldDef write FXFieldDef;
    property BufferFileName: string read GenerateBufferFileName;

    /// <summary>
    /// Live Bind last write Size ib Bytes
    /// </summary>
    property C_Write: Integer read FBindWrite write SetBindWriteFile;
  published
   // property DataSetDefClass: string read GetDataSetClass write SetDataSetClass;
{$IFDEF ENG_VERSION}
    [ShowProp('DataBase', True)]
{$ELSE}
    [ShowProp('База данных', True)]
{$ENDIF}
    property DataSetDef;//: TIDataSetDef read FStored write SetROOT;
    [ShowProp('X', True)]
    property XParamPath: string read FXParamPath write FXParamPath;
    [ShowProp('Y', True)]
    property YParamPath: string read FYParamPath write FYParamPath;
  end;

  {$ENDREGION}

  TGraphParamClass = class of TGraphPar;

  TGraphPar = class(TColumnCollectionItem, IInterface, ICaption)
  private
    FFilters: TParamFilters;
    FLink: TCustomDataLink;
    FOnContextPopup: TContextPopupEvent;
    FTitle: string;
    FVisible: Boolean;
    FColor: TAlphaColor;
    FDeltaX: Double;
    FDeltaY: Double;
    FHideInLegend: boolean;
    FFixedParam: boolean;
    FEUnit: string;
    FPresizion: Integer;
    FActiveFilter: Integer;
    FSelected: Boolean;
   // FDashOffset: Double;
    procedure DoContextPopup(MousePos: TPoint; var Handled: Boolean);
    procedure SetTitle(const Value: string);
    function GetLinkClass: string;
    procedure SetLinkClass(const Value: string);
    procedure SetLink(const Value: TCustomDataLink);
    procedure SetVisible(const Value: Boolean);
    procedure SetColor(const Value: TAlphaColor);
    procedure SetDeltaX(const Value: Double);
    procedure SetDeltaY(const Value: Double);
    procedure SetEUnit(const Value: string);
    procedure SetHideInLegend(const Value: boolean);
    procedure SetSelected(const Value: Boolean);
  protected
    function GetCaption: string; virtual;
    procedure SetCaption(const Value: string);
    function QueryInterface(const IID: TGUID; out Obj): HResult; reintroduce; stdcall;
    procedure DefineProperties(Filer: TFiler); override;
  public
    constructor Create(Collection: TCollection); override;
    destructor Destroy; override;
    property Color: TAlphaColor read FColor write SetColor default $7FFF0000;
    property EUnit: string read FEUnit write SetEUnit;
    property Presizion: Integer read FPresizion write FPresizion default 2;
    //property DashOffset: Double read FDashOffset write FDashOffset;
    property FixedParam: boolean read FFixedParam write FFixedParam;
    property HideInLegend: boolean read FHideInLegend write SetHideInLegend;
{$IFDEF ENG_VERSION}
    [ShowProp('History of changes')]
{$ELSE}
    [ShowProp('История изменений')]
{$ENDIF}
    property Filters: TParamFilters read FFilters;
//    property DataSet: TDataSet read FDataSet write SetDataSet;
  published
    property LinkClass: string read GetLinkClass write SetLinkClass;
{$IFDEF ENG_VERSION}
    [ShowProp('Source', True)]
{$ELSE}
    [ShowProp('Источник', True)]
{$ENDIF}
    property Link: TCustomDataLink read FLink write SetLink;
{$IFDEF ENG_VERSION}
    [ShowProp('Name')]
{$ELSE}
    [ShowProp('Имя')]
{$ENDIF}
    property Title: string read FTitle write SetTitle;
{$IFDEF ENG_VERSION}
    [ShowProp('Show')]
{$ELSE}
    [ShowProp('Показать')]
{$ENDIF}
    property Visible: Boolean read FVisible write SetVisible default True;
{$IFDEF ENG_VERSION}
    [ShowProp('Select')]
{$ELSE}
    [ShowProp('Выбрать')]
{$ENDIF}
    property Selected: Boolean read FSelected write SetSelected;
{$IFDEF ENG_VERSION}
    [ShowProp('Offset X')]
{$ELSE}
    [ShowProp('Смещение X')]
{$ENDIF}
    property DeltaX: Double read FDeltaX write SetDeltaX;
{$IFDEF ENG_VERSION}
    [ShowProp('Offset Y')]
{$ELSE}
    [ShowProp('Смещение Y')]
{$ENDIF}
    property DeltaY: Double read FDeltaY write SetDeltaY;
//    [ShowProp('Масштаб')]        property Scale        : Double read FScale write SetScale;
    property OnContextPopup: TContextPopupEvent read FOnContextPopup write FOnContextPopup;
  end;

  TGraphParams = class(TColumnCollection<TGraphPar>)
  protected
    function GetCaption: string; override;
    procedure Notify(Item: TCollectionItem; Action: TCollectionNotification); override;
  end;

{$IFDEF ENG_VERSION}
  [EnumCaptions('solid, dot, dash, dot dash, dot dot dash')]
{$ELSE}
  [EnumCaptions('сплошная, точка, тире, точка тире, точка точка тире')]
{$ENDIF}
  TLineDashStyle = (ldsSolid, ldsDot, ldsDash, ldsDashDot, ldsDashDotDot);

  TXScalableParam = class(TGraphPar)
  private
    FWidth: Integer;
    FScaleX: Double;
    FDashStyle: TLineDashStyle;
    procedure SetDashStyle(const Value: TLineDashStyle);
    procedure SetWidth(const Value: Integer);
    procedure SetScale(const Value: Double);
  public
    constructor Create(Collection: TCollection); override;
    procedure SetRange(L, R: Double);
  published
{$IFDEF ENG_VERSION}
    [ShowProp('Color')]
{$ELSE}
    [ShowProp('Цвет')]
{$ENDIF}
    property Color;
{$IFDEF ENG_VERSION}
    [ShowProp('Line width')]
{$ELSE}
    [ShowProp('Ширина линии')]
{$ENDIF}
    property Width: Integer read FWidth write SetWidth default 1;
{$IFDEF ENG_VERSION}
    [ShowProp('Stroke style')]
{$ELSE}
    [ShowProp('Стиль штрихов')]
{$ENDIF}
    property DashStyle: TLineDashStyle read FDashStyle write SetDashStyle default ldsSolid;
{$IFDEF ENG_VERSION}
    [ShowProp('Scale')]
{$ELSE}
    [ShowProp('Масштаб')]
{$ENDIF}
    property ScaleX: Double read FScaleX write SetScale;
{$IFDEF ENG_VERSION}
    [ShowProp('Units')]
{$ELSE}
    [ShowProp('Единицы измерения')]
{$ENDIF}
    property EUnit;
  end;

  TLineParam = class(TXScalableParam)
  published
{$IFDEF ENG_VERSION}
    [ShowProp('Freeze')]
{$ELSE}
    [ShowProp('Заморозить')]
{$ENDIF}
    property FixedParam;
{$IFDEF ENG_VERSION}
    [ShowProp('Hide legend')]
{$ELSE}
    [ShowProp('Скрыть легенду')]
{$ENDIF}
    property HideInLegend;
{$IFDEF ENG_VERSION}
    [ShowProp('Precision(digits after decimal point)')]
{$ELSE}
    [ShowProp('Точность(цифр после запятой)')]
{$ENDIF}
    property Presizion;
  end;

  TGamma = array[ShortInt] of TColor;

  TGammaProp = type string;

{$IFDEF ENG_VERSION}
  [EnumCaptions('intensity, amplitude, VAC')]
{$ELSE}
  [EnumCaptions('интенсивность, амплитуда, ВАК')]
{$ENDIF}
  TWaveStyle = (wsGamma, wsColor, wsBAK);

  TWaveParam = class(TXScalableParam)
  private
    FGamma: TGamma;
    FWaveStyle: TWaveStyle;
    FZeroGamma: Double;
    FKoefGamma: Double;
    procedure SetGamma(const Value: TGamma);
    procedure SetGammaStr(const Value: TGammaProp);
    function GetGammaStr: TGammaProp;
    procedure SetWaveStyle(const Value: TWaveStyle);
    procedure SetKoefGamma(const Value: Double);
    procedure SetZeroGamma(const Value: Double);
  public
    constructor Create(Collection: TCollection); override;
    property Gamma: TGamma read FGamma write SetGamma;
  published
{$IFDEF ENG_VERSION}
    [ShowProp('Palette')]
{$ELSE}
    [ShowProp('Палитра')]
{$ENDIF}
    property GammaStr: TGammaProp read GetGammaStr write SetGammaStr;
{$IFDEF ENG_VERSION}
    [ShowProp('Render type')]
{$ELSE}
    [ShowProp('Тип отриствки')]
{$ENDIF}
    property WaveStyle: TWaveStyle read FWaveStyle write SetWaveStyle default wsGamma;
{$IFDEF ENG_VERSION}
    [ShowProp('Amplitude K')]
{$ELSE}
    [ShowProp('Амплитудный Кф')]
{$ENDIF}
    property KoeffGamma: Double read FKoefGamma write SetKoefGamma;
{$IFDEF ENG_VERSION}
    [ShowProp('Zero Offset')]
{$ELSE}
    [ShowProp('Смещение Нуля')]
{$ENDIF}
    property ZeroGamma: Double read FZeroGamma write SetZeroGamma;
  end;

  TStringParam = class(TGraphPar)
  published
{$IFDEF ENG_VERSION}
    [ShowProp('Color')]
{$ELSE}
    [ShowProp('Цвет')]
{$ENDIF}
    property Color;
  end;

    {$REGION 'коллекции хранящиеся в параметрe'}
  /// коллекция Параметра общее
  TParamCollectionItem = class(TColumnCollectionItem)
  private
    FParam: TGraphPar;
  public
    constructor Create(Collection: TCollection); override;
    property Param: TGraphPar read FParam;
  end;

  TParamCollection<T: TParamCollectionItem> = class(TColumnCollection<T>)
  private
    FParam: TGraphPar;
  public
    constructor Create(AOwner: TObject); override;
    property Param: TGraphPar read FParam;
  end;
       {$REGION 'коллекции параметра:  Фильтр'}

  TParamFilter = class(TParamCollectionItem, ICaption, IFileData)
  private
    FSourceFile: string;
    FActiv: Boolean;
    FIData: IFileData;
    procedure SetSourceFile(const Value: string);
    procedure SetActiv(const Value: Boolean);
    function GetIData: IFileData;
  protected
    function GetCaption: string; virtual; abstract;
    procedure SetCaption(const Value: string);
    property FileData: IFileData read GetIData implements IFileData;
  published
{$IFDEF ENG_VERSION}
    [ShowProp('Active')]
{$ELSE}
    [ShowProp('Активный')]
{$ENDIF}
    property Activ: Boolean read FActiv write SetActiv default False;
{$IFDEF ENG_VERSION}
    [ShowProp('File name', True)]
{$ELSE}
    [ShowProp('Название файла', True)]
{$ENDIF}
    property SourceFile: string read FSourceFile write SetSourceFile;
  end;

  TParamFilters = class(TParamCollection<TParamFilter>, ICaption)
  protected
    function GetCaption: string; override;
    procedure SetCaption(const Value: string);
  end;

  TWaveletFilter = class(TParamFilter)
  private
    FDisplayName: string;
  protected
    function GetCaption: string; override;
  published
{$IFDEF ENG_VERSION}
    [ShowProp('Setup')]
{$ELSE}
    [ShowProp('Настройка')]
{$ENDIF}
    property DisplayName: string read FDisplayName write FDisplayName;
  end;
      {$ENDREGION}
    {$ENDREGION}
  {$ENDREGION}
{$ENDREGION}

  /// перемещение или изменение размера рядов или колонок мышкой
  ///  сосотяние

  GraphState = (pcsNormal, pcsColSizing, pcsColMoving, pcsRowSizing, pcsRowMoving);
  {$REGION 'классы выполняюшие GraphState'}

  TCustomEditDlot = class
    FOwner: TCustomGraph;
    FItem, FSwap: TColRowCollectionItem;
    Fpos: Integer;
    FState: GraphState;
    function SetPos(Pos: TPoint): integer;
    procedure Drow; virtual;
    procedure Move(Pos: TPoint); virtual;
    constructor Create(Owner: TCustomGraph; Pos: TPoint; ps: GraphState; Item: TColRowCollectionItem);
    destructor Destroy; override;
  end;

  TCustomEditDlotClass = class of TCustomEditDlot;

  TColSizing = class(TCustomEditDlot)
    destructor Destroy; override;
  end;

  TRowSizing = class(TColSizing);

  TColMoving = class(TCustomEditDlot)
    procedure Move(Pos: TPoint); override;
    destructor Destroy; override;
  end;

  TRowMoving = class(TColMoving);
  {$ENDREGION}

  {$REGION 'классы выполняюшие ScrollBar'}

  TYScrollBarClass = class of TYScrollBar;


  TYScrollBar = class
  public
    Graph: TCustomGraph;
    FRow: TCustomGraphDataRow;
    Fpp2mm: Double;
    function GetRealScrollPosition: Integer;
    function GetRow: TCustomGraphDataRow;
    constructor Create(Owner: TCustomGraph);
    procedure Update;
    procedure Scroll(var Message: TWMVScroll);
    procedure Wheel(var Message: TCMMouseWheel);
    function Range: Integer;
    function Page: Integer;
    function Line: Integer;
    procedure UpdatePosition;
    procedure SetPosition(Y: Integer);
    property Row: TCustomGraphDataRow read GetRow;
    function GetPosition: Integer; virtual;
    procedure SetGraphPosition(Y: Integer); virtual;
    procedure SetGraphYScreen; virtual;
    property Position: Integer read GetPosition write SetPosition;
  end;

  TMirrorYScrollBar = class(TYScrollBar)
    function GetPosition: Integer; override;
    procedure SetGraphYScreen; override;
    procedure SetGraphPosition(Y: Integer); override;
  end;
  {$ENDREGION}

  TContextMenuItem = class(TMenuItem)
  public
    ContextObj: TObject;
    ContextMousePos: TPoint;
  end;

  TCustomContextPlotPopup = class(TPopupMenu)
  public
    type
      TPopupEvent = (ppeGraph, ppeColumn, ppeRegion, ppeParam);
  protected
    procedure DoContextPopup(AObject: TObject; Event: TPopupEvent; MousePos: TPoint); virtual; abstract;
  end;

  TParamsAddedEvent = procedure(d: TDataSet) of object;
  ///  клласс основной

  TCustomGraph = class(TICustomControl{, IYDataLink})
  public
    type
      [EnumCaptions('Все, Указать начало и диапазон, Сначала, Последние')]
      TYFrom = (yfmALL, yfmUser, yfmFirst, yfmLast);
  private
    FHitTest: TPoint;
    FState: GraphState;
    FEditGraph: TCustomEditDlot;
    FColumns: TGraphColumns;
    FRows: TGraphRows;
    FHitRegion: TGraphRegion;
    FYPosition: Double;
    FYScale: Double;
    FMirror: Boolean;
    FYRange: Double;
    FYFrom: Double;
    FYFromType: TYFrom;
    FYFirstAvail: Double;
    FYLastAvail: Double;
//    FOnDataAdded: TNotifyEvent;
    FYScrollBar: TYScrollBar;
    FPropertyChanged: string;
    FYTopScreen: Double;
    FYButtomScreen: Double;
    FFrostCount: Integer;
    FOnParamsAdded: TParamsAddedEvent;
 //   FYDataLink: TCustomYDataLink;

    procedure UpdateColRowRegionSizes;
    procedure UpdateRegionSizes;
    function IsMouseSizeMove(Pos: TPoint; var ps: GraphState; out Item: TColRowCollectionItem): Boolean; overload;
    function IsMouseSizeMove(Pos: TPoint; var ps: GraphState): Boolean; overload;
    procedure WMVScroll(var Message: TWMVScroll); message WM_VSCROLL;
    procedure CMMouseWheel(var Message: TCMMouseWheel); message CM_MOUSEWHEEL;
    procedure CMParentFontChanged(var Message: TCMParentFontChanged); message CM_PARENTFONTCHANGED;
    procedure WMNCHitTest(var Msg: TWMNCHitTest); message WM_NCHITTEST;
    procedure WMSetCursor(var Msg: TWMSetCursor); message WM_SETCURSOR;
    procedure WMSize(var Message: TWMSize); message WM_SIZE;
    procedure WMEraseBkgnd(var Msg: TWMEraseBkgnd); message WM_ERASEBKGND;
    procedure SetMirror(const Value: Boolean);
    procedure SetYFrom(const Value: Double);
    procedure SetYPosition(const Value: Double);
    procedure SetYScale(const Value: Double);
    procedure SetYRange(const Value: Double);
    procedure SetYFromType(const Value: TYFrom);
    function GetYRangeAvail: Double; inline;
    function GetYLast: Double; inline;
    procedure SetYLast(const Value: Double);
    procedure ChekYPosition;
    procedure SetPropertyChanged(const Value: string);
    procedure UpdateYScreen(t, d: Double);
    procedure ContextPopupEvent(AObject: TObject; Event: TCustomContextPlotPopup.TPopupEvent; MousePos: TPoint);
    procedure UpdateAvalableRangeY;
    function GetActiveData: boolean;
  protected
    /// Иызывается источником данных при поступлении данных
//    procedure DataAdded; virtual;
    function GetDefaultYAxis: TAxisY; virtual;
    procedure Loaded; override;
    procedure DefineProperties(Filer: TFiler); override;
    procedure DoContextPopup(MousePos: TPoint; var Handled: Boolean); override;
    procedure MouseDown(Button: TMouseButton; Shift: TShiftState; X, Y: Integer); override;
    procedure MouseMove(Shift: TShiftState; X, Y: Integer); override;
    procedure MouseUp(Button: TMouseButton; Shift: TShiftState; X, Y: Integer); override;
    procedure DrowRegionsBounds;
    procedure Paint; override;
    function HitRow(pos: TPoint): TGraphRow;
    function HitColumn(pos: TPoint): TGraphColmn;
    function TryHitRegion(pos: TPoint; out Reg: TGraphRegion): Boolean; overload;
    function TryHitRegion(c: TGraphColmn; r: TGraphRow; out Reg: TGraphRegion): Boolean; overload;
    function HitRegion(pos: TPoint): TGraphRegion; overload;
    function HitRegion(c: TGraphColmn; r: TGraphRow): TGraphRegion; overload;
    function LoadOrDestroy: Boolean; inline;
    procedure DoParamsAdded(DataSet: TDataSet);
  //  property YDataLink: TCustomYDataLink read FYDataLink implements IYDataLink;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    /// пересчет границ Y, scrollbar
    /// перерисовка обновленных колонок
    /// для события OnDataAdded
    procedure UpdateData;
    procedure Frost;
    procedure DeFrost;
    function Frosted: Boolean;
    property Canvas;
    property Font;
    property YRangeAvail: Double read GetYRangeAvail;
    property YLast: Double read GetYLast write SetYLast;
    [ShowProp('TOP Y', true)]
    property YTopScreen: Double read FYTopScreen;
    [ShowProp('BOT Y', true)]
    property YButtomScreen: Double read FYButtomScreen;
    [ShowProp('ActiveData', true)]
    property ActiveData: boolean read GetActiveData;
{$IFDEF ENG_VERSION}
    [ShowProp('Rows')]
{$ELSE}
    [ShowProp('Ряды')]
{$ENDIF}
    property Rows: TGraphRows read FRows;
{$IFDEF ENG_VERSION}
    [ShowProp('Columns')]
{$ELSE}
    [ShowProp('Колонки')]
{$ENDIF}
    property Columns: TGraphColumns read FColumns;
    /// ID , кадр, глубина
{$IFDEF ENG_VERSION}
    [ShowProp('Default Y-Axis', True)]
{$ELSE}
    [ShowProp('Ось Y по умолчанию', True)]
{$ENDIF}
    property DefaultYAxis: TAxisY read GetDefaultYAxis;
    property S_PropertyChanged: string read FPropertyChanged write SetPropertyChanged;
  published
    [ShowProp('min Y', true)]
    property YFirstAvail: Double read FYFirstAvail write FYFirstAvail;
    [ShowProp('max Y', true)]
    property YLastAvail: Double read FYLastAvail write FYLastAvail;
{$IFDEF ENG_VERSION}
    [ShowProp('Mirror Y')]
{$ELSE}
    [ShowProp('Инвертировать Y')]
{$ENDIF}
    property YMirror: Boolean read FMirror write SetMirror;
{$IFDEF ENG_VERSION}
    [ShowProp('Y range')]
{$ELSE}
    [ShowProp('Диапазон по Y')]
{$ENDIF}
    property YFromType: TYFrom read FYFromType write SetYFromType default yfmALL;
{$IFDEF ENG_VERSION}
    [ShowProp('Start Y with')]
{$ELSE}
    [ShowProp('Начать Y с')]
{$ENDIF}
    property YFromData: Double read FYFrom write SetYFrom;
{$IFDEF ENG_VERSION}
    [ShowProp('Y range')]
{$ELSE}
    [ShowProp('Диапазон Y')]
{$ENDIF}
    property YRangeData: Double read FYRange write SetYRange;
{$IFDEF ENG_VERSION}
    [ShowProp('Y position')]
{$ELSE}
    [ShowProp('Позиция Y')]
{$ENDIF}
    property YPosition: Double read FYPosition write SetYPosition;
{$IFDEF ENG_VERSION}
    [ShowProp('Y Scale')]
{$ELSE}
    [ShowProp('Масштаб по Y')]
{$ENDIF}
    property YScale: Double read FYScale write SetYScale;
    property OnParamsAdded: TParamsAddedEvent read FOnParamsAdded write FOnParamsAdded;
  end;

  TGraph = class(TCustomGraph)
  published
    property Align;
    property ParentFont;
    property Parent;
    property Font;
    property ParentColor;
    property Color;
    property PopupMenu;
    property OnContextPopup;
  end;

function FindBestScale(Scale: Double): Double;

implementation

uses
  System.Math, Winapi.CommCtrl, FileDataSet;

function FindBestScale(Scale: Double): Double;
var
  i: Integer;
begin
  for i := Low(SCALE_PRESET_MOUSE) to High(SCALE_PRESET_MOUSE) - 1 do
    if (Scale >= SCALE_PRESET_MOUSE[i]) and (Scale <= SCALE_PRESET_MOUSE[i + 1]) then
    begin
      if (Scale - SCALE_PRESET_MOUSE[i]) > (SCALE_PRESET_MOUSE[i + 1] - Scale) then
        Scale := SCALE_PRESET_MOUSE[i + 1]
      else
        Scale := SCALE_PRESET_MOUSE[i];
      Break
    end;
  Result := Scale;
end;

{$REGION 'Collection'}

   {$REGION 'GraphCollection'}

{ TGraphCollectionItem }

constructor TGraphCollectionItem.Create(Collection: TCollection);
begin
  FGraph := TGraphCollection(Collection).Graph;
  DoInitialize;
  inherited Create(Collection);
end;

constructor TGraphCollectionItem.CreateNew(Collection: TGraphCollection);
begin
  Create(Collection);
end;

procedure TGraphCollectionItem.DoInitialize;
begin

end;

{ TGraphCollection }

function TGraphCollection.Add(const ItemClassName: string): TGraphCollectionItem;
begin
  Result := TGraphCollectionItem(TGraphCollectionItemClass(FindClass(ItemClassName)).CreateNew(Self));
end;

function TGraphCollection<T>.Add<C>: C;
begin
  Result := TRttiContext.Create.GetType(TClass(C)).GetMethod('CreateNew').Invoke(TClass(C), [Self]).AsType < C > ; //через жопу работает
end;

constructor TGraphCollection<T>.Create(AOwner: TObject);
begin
  FGraph := TCustomGraph(AOwner);
  inherited Create(T);
end;

destructor TGraphCollection<T>.Destroy;
begin
  TDebug.Log('TGraphCollection<T>.Destroy  === %s', [ClassName]);
  inherited;
end;

function TGraphCollection<T>.GetEnumerator: TEnumerator;
begin
  Result.i := -1;
  Result.FCollection := Self;
end;

function TGraphCollection<T>.GetItem(Index: Integer): T;
begin
  Result := T(inherited GetItem(Index));
end;

procedure TGraphCollection<T>.SetItem(Index: Integer; const Value: T);
begin
  inherited SetItem(Index, Value);
end;

function TGraphCollection.Add(ItemClass: TGraphCollectionItemClass): TGraphCollectionItem;
begin
  Result := ItemClass.CreateNew(Self);
end;

{ TGraphCollection<T>.TEnumerator }

function TGraphCollection<T>.TEnumerator.DoGetCurrent: T;
begin
  Result := FCollection.Items[i];
end;

function TGraphCollection<T>.TEnumerator.MoveNext: Boolean;
begin
  Inc(i);
  Result := i < FCollection.Count;
end;
{$ENDREGION}

   {$REGION ' ColRowCollection строки колонки общее'}

function TColRowCollectionItem.AutoSize: Boolean;
begin
  Result := True;
end;

constructor TColRowCollectionItem.Create(Collection: TCollection);
begin
  FLen := 20;
  FVisible := True;
  inherited;
end;

procedure TColRowCollectionItem.Release;
var
  i: Integer;
begin
  inherited;
  if csDestroying in Graph.ComponentState then
    Exit;
  for i := RegionsCount - 1 downto 0 do
    Regions[i].Free;
  Graph.UpdateColRowRegionSizes;
  Graph.FYScrollBar.Update;
end;

procedure TColRowCollectionItem.DoVisibleChanged;
begin
  TCollectionColRows<TColRowCollectionItem>(Collection).UpdateSizes;
  Graph.FYScrollBar.SetGraphYScreen;
  Graph.UpdateRegionSizes;
  Graph.FYScrollBar.Update;
end;

function TColRowCollectionItem.GetTo: Integer;
begin
  Result := FFrom + FLen;
end;

procedure TColRowCollectionItem.SetLen(const Value: Integer);
begin
  if Value > 20 then
    FLen := Value
  else
    FLen := 20;
end;

procedure TColRowCollectionItem.SetVisible(const Value: Boolean);
begin
  if FVisible <> Value then
  begin
    FVisible := Value;
    if csLoading in Graph.ComponentState then
      Exit;
    DoVisibleChanged;
    Graph.Repaint;
  end;
end;

function TCollectionColRows<T>.LastToResize(FromLast: integer; ToFirst: Integer = 0): TColRowCollectionItem;
var
  i: Integer;
begin
  for i := FromLast downto ToFirst do
    if Items[i].Visible then
      if Items[i].AutoSize then
        Exit(Items[i])
      else
        Result := Items[i];
end;

procedure TCollectionColRows<T>.Notify(Item: TCollectionItem; Action: TCollectionNotification);
var
  r: TColRowCollectionItem;
  len: Integer;
begin
  inherited;
  if Graph.LoadOrDestroy then
    Exit;
  if (Action = TCollectionNotification.cnAdded) then
  begin
    if (Count >= 2) then
    begin
      r := LastToResize(Count - 2); // последний новый?
      r.SetLen(r.FLen div 2);
      TColRowCollectionItem(Item).FLen := r.FLen;
    end
    else
      TColRowCollectionItem(Item).FLen := GetAllLen;
    UpdateSizes;
    Graph.FYScrollBar.SetGraphYScreen;
    Graph.UpdateRegionSizes;
    Graph.FYScrollBar.Update;
  end;
end;

procedure TCollectionColRows<T>.UpdateSizes;
var
  lf, i, j, wf: Integer;
  r, rs: TColRowCollectionItem;
begin
  if (Count = 0) or Graph.LoadOrDestroy then
    Exit;
  rs := LastToResize(Count - 1);
  lf := 0;
  for i := 0 to Count - 1 do
    if Items[i].Visible then
    begin
      r := Items[i];
      r.FFrom := lf;
      if rs = r then
      begin
        wf := 0;
        for j := i + 1 to Count - 1 do
          if Items[j].Visible then
            wf := wf + Items[j].Flen;
        r.SetLen(GetAllLen - lf - wf);
      end;
      Inc(lf, r.FLen);
    end;
//  Tdebug.log('ALL: %d ',[GetAllLen]);
//  for i := 0 to Count-1 do with TColRowCollectionItem(Items[i]) do Tdebug.log('FROM: %d TO %d',[FFrom, FFrom+Flen]);
end;
  {$ENDREGION}

   {$REGION 'Column, Row'}

{ TGraphRows }

function TGraphRows.FindRows(rc: TGraphRowClass): TArray<TGraphRow>;
var
  r: TGraphRow;
begin
  for r in Self do
    if r is rc then
      CArray.Add<TGraphRow>(Result, r);
end;

function TGraphRows.GetAllLen: Integer;
begin
  Result := FGraph.ClientHeight;
end;

function TGraphRows.GetCaption: string;
begin
{$IFDEF ENG_VERSION}
  Result := 'Rows'
{$ELSE}
  Result := 'Ряды'
{$ENDIF}
end;

{ TGraphRow }

procedure TGraphRow.DoInitialize;
var
  c: TGraphColmn;
begin
  inherited;
  for c in FGraph.Columns do
    c.CreateRegion(Self);
end;

function TGraphRow.GetCaption: string;
begin
{$IFDEF ENG_VERSION}
  Result := 'Row'
{$ELSE}
  Result := 'Ряд'
{$ENDIF}
end;

function TGraphRow.GetItem(Index: Integer): TGraphRegion;
var
  r: TGraphRegion;
begin
  if (Index < 0) or (Index >= FGraph.Columns.Count) then
{$IFDEF ENG_VERSION}
    raise EGraphException.CreateFmt('Invalid Region Index I:%d L:%d', [Index, FGraph.Columns.Count]);
{$ELSE}
    raise EGraphException.CreateFmt('Неверный индекс Региона I:%d L:%d', [Index, FGraph.Columns.Count]);
{$ENDIF}
  for r in FGraph.Columns[Index].FRegions do
    if r.Row = Self then
      Exit(r);
{$IFDEF ENG_VERSION}
  raise EGraphException.CreateFmt('Region %s not found', [ClassName]);
{$ELSE}
  raise EGraphException.CreateFmt('Регион %s не найлен', [ClassName]);
{$ENDIF}
end;

function TGraphRow.GetRegionsCount: Integer;
begin
  Result := FGraph.Columns.Count;
end;

procedure TGraphRow.SetCaption(const Value: string);
begin

end;

procedure TGraphRow.SetHeight(const Value: Integer);
begin
  SetLen(Value);
  if Graph.LoadOrDestroy then
    Exit;
  Graph.UpdateColRowRegionSizes;
  Graph.Repaint;
end;

{ TNoSizebleGraphRow }

function TNoSizebleGraphRow.AutoSize: Boolean;
begin
  Result := False;
end;

{ TCustomGraphData }

//constructor TCustomGraphData.Create(Collection: TCollection);
//begin
//  inherited;
//  FCursor := crCross;
//end;

{ TGraphColumns }

function TGraphColumns.GetAllLen: Integer;
begin
  Result := FGraph.ClientWidth;
end;

{ TGraphColumn }

class procedure TGraphColmn.ColClsRegister(acc: TGraphColumnClass; const DisplayName: string);
var
  d: TColClassData;
begin
  d.ColCls := acc;
  d.DisplayName := DisplayName;
  CArray.Add<TColClassData>(ColClassItems, d);
end;

procedure TGraphColmn.ColumnCollectionChanged(Collection: TGraphCollection);
begin
end;

procedure TGraphColmn.ColumnCollectionItemChanged(const Item: TColumnCollectionItem);
begin
end;

procedure TGraphColmn.DoInitialize;
begin
  FRegions := TGraphRegions.Create(Self);
  FParams := TGraphParams.Create(Self);
  CreateRegions();
end;


{constructor TGraphColmn.Create(Collection: TCollection);
begin
  FGraph := TGraphColumns(Collection).Graph;
  FRegions := TGraphRegions.Create(Self);
  FParams := TGraphParams.Create(Self);
  inherited Create(Collection);
end;

constructor TGraphColmn.CreateNew(Collection: TGraphCollection);
begin
  inherited;
  CreateRegions();
end;}

procedure TGraphColmn.CreateRegion(Row: TGraphRow);
var
  c: TGraphRegionClass;
begin
  c := TGraphRegion.RegClsFind(TGraphRowClass(Row.ClassType), TGraphColumnClass(ClassType));
  TGraphRegion(FRegions.Add(c)).FGraphRow := Row;
end;

procedure TGraphColmn.UpdateRegionsSize;
var
  p: TGraphRegion;
begin
  for p in Regions do
    p.UpdateSize;
end;

procedure TGraphColmn.CreateRegions;
var
  r: TGraphRow;
//  p: TGraphRegion;
begin
  FRegions.Clear;
  for r in Graph.Rows do
    CreateRegion(r);
end;

procedure TGraphColmn.DefineProperties(Filer: TFiler);
begin
  inherited;
  FParams.RegisterProperty(Filer, 'Params');
  FRegions.RegisterProperty(Filer, 'Regions');
end;

{procedure TGraphColmn.DeleteRegion(Row: TGraphRow);
 var
  i: Integer;
begin
  for i := 0 to FRegions.Count-1 do if FRegions[i].Row = Row then
   begin
    FRegions.Delete(i);
    Exit;
   end;
end;}

destructor TGraphColmn.Destroy;
begin
  FParams.Free;
  inherited Destroy; // Перед удалением коллелции регионов в inherited Destroy вызывается удаление регионов
  FRegions.Free;
end;

procedure TGraphColmn.DoContextPopup(MousePos: TPoint; var Handled: Boolean);
var
  r: TGraphRegion;
begin
  Graph.ContextPopupEvent(Self, ppeColumn, MousePos);
  if Assigned(FOnContextPopup) then
    FOnContextPopup(Self, MousePos, Handled);
  if not Handled and Graph.TryHitRegion(Self, Graph.HitRow(MousePos), r) then
    r.DoContextPopup(MousePos, Handled);
end;

function TGraphColmn.GetItem(Index: Integer): TGraphRegion;
begin
  if (Index < 0) or (Index >= FRegions.Count) then
{$IFDEF ENG_VERSION}
    raise EGraphException.CreateFmt('Invalid Region Index I:%d L:%d', [Index, FRegions.Count]);
{$ELSE}
    raise EGraphException.CreateFmt('Неверный индекс Региона I:%d L:%d', [Index, FRegions.Count]);
{$ENDIF}
  Result := FRegions[Index];
end;

function TGraphColmn.GetRegionsCount: Integer;
begin
  Result := FRegions.Count;
end;

procedure TGraphColmn.SetWidth(const Value: Integer);
begin
  SetLen(Value);
  if csLoading in Graph.ComponentState then
    Exit;
  Graph.Columns.UpdateSizes;
  Graph.UpdateRegionSizes;
  Graph.Repaint;
end;

{$ENDREGION}

   {$REGION 'структура колонки: Regions, Parameters'}

  /// коллекция колонки общее

function TGraphColumns.GetCaption: string;
begin
{$IFDEF ENG_VERSION}
  Result := 'Columns'
{$ELSE}
  Result := 'Колонки'
{$ENDIF}
end;

{ TColumnCollection<T> }

constructor TColumnCollection<T>.Create(AOwner: TObject);
begin
  FColumn := TGraphColmn(AOwner);
  inherited Create(TGraphColmn(AOwner).Graph);
end;

{ TColumnCollectionItem }

constructor TColumnCollectionItem.Create(Collection: TCollection);
begin
  FColumn := TColumnCollection<TColumnCollectionItem>(Collection).Column;
  inherited Create(Collection);
end;

    {$REGION 'GraphRegion'}

procedure TColumnCollectionItem.Release;
begin
  inherited Release;
  NotifyCollumn;
end;

{ TGraphRegion }

procedure TGraphRegion.DoContextPopup(MousePos: TPoint; var Handled: Boolean);
var
  p: TGraphPar;
begin
  Graph.ContextPopupEvent(Self, ppeRegion, MousePos);
  if Assigned(FOnContextPopup) then
    FOnContextPopup(Self, MousePos, Handled);
  if not Handled and TryHitParametr(MousePos, p, Tmousebutton.mbRight) then
    p.DoContextPopup(MousePos, Handled);
end;

//function TGraphRegion.GetRow: string;
//begin
//  Result :=  FGraphRow.ClassName;
//end;
function TGraphRegion.GetCursor: Integer;
begin
  Result := crDefault;
end;

function TGraphRegion.GetRow: integer;
begin
  Result := FGraphRow.Index;
end;

procedure TGraphRegion.ParentFontChanged;
begin
end;

procedure TGraphRegion.MouseDown(Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
begin
end;

procedure TGraphRegion.MouseMove(Shift: TShiftState; X, Y: Integer);
begin
end;

function TGraphRegion.MouseToClient(pos: TPoint): TPoint;
begin
  Result := pos - clientRect.TopLeft;
end;

procedure TGraphRegion.MouseUp(Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
begin
end;

procedure TGraphRegion.MouseWheel(var Message: TCMMouseWheel);
begin

end;

procedure TGraphRegion.Paint;
begin
  if Column.Visible and Row.Visible then
  begin
    Graph.Canvas.FillRect(ClientRect);
    Graph.Canvas.TextRect(ClientRect, ClientRect.Left + ClientRect.Width div 2, ClientRect.Top + ClientRect.Height div 2, 'NOP');
  end;
end;

procedure TGraphRegion.UpdateSize;
var
  r: TRect;
begin
  r := TRect.Create(Column.Left + 1, Row.Top + 1, Column.Right, Row.Bottom);
  if r <> ClientRect then
    ClientRect := r;
end;

class function TGraphRegion.RegClsFind(arc: TGraphRowClass; acc: TGraphColumnClass): TGraphRegionClass;
var
  r: TRegClsData;
begin
  for r in GRegClsItems do
    if (r.cc = acc) and (r.rc = arc) then
      Exit(r.pc);
  Result := TGraphRegion;
//  raise EGraphException.CreateFmt('Ненайден класс региона %s  %s', [arc.ClassName, acc.ClassName]);
end;

class procedure TGraphRegion.RegClsRegister(apc: TGraphRegionClass; arc: TGraphRowClass; acc: TGraphColumnClass);
var
  d: TRegClsData;
begin
  d.pc := apc;
  d.rc := arc;
  d.cc := acc;
  CArray.Add<TRegClsData>(GRegClsItems, d);
end;

procedure TGraphRegion.SetClientRect(const Value: TRect);
begin
  FClientRect := Value;
end;

procedure TGraphRegion.SetRow(const Value: Integer);
begin
  FGraphRow := Graph.Rows[Value];
end;

{procedure TGraphRegion.SetRow(const Value: string);
 var
  r: TGraphRow;
begin
  for r in Graph.Rows do if SameText(r.ClassName, Value) then
   begin
    FGraphRow := r;
    Exit;
   end;
  raise EGraphException.CreateFmt('Ненайден класс ряда %s', [Value]);
end;}

function TGraphRegion.TryHitParametr(pos: TPoint; out Par: TGraphPar; Button: TMouseButton = mbLeft; Shift: TShiftState = []): Boolean;
begin
  Result := False;
end;
   {$ENDREGION}

   {$REGION 'GraphParam'}

{ TGraphParam }

constructor TGraphPar.Create(Collection: TCollection);
begin
  FVisible := True;
  FPresizion := 2;
  FGraph := TGraphParams(Collection).Graph;
  FColumn := TGraphParams(Collection).Column;
  FFilters := TParamFilters.Create(Self);
  FColor := $7FFF0000;
  inherited Create(Collection);
end;

procedure TGraphPar.DefineProperties(Filer: TFiler);
begin
  inherited;
  FFilters.RegisterProperty(Filer, 'Filters');
end;

destructor TGraphPar.Destroy;
begin
  TDebug.Log('TGraphPar.Destroy == %s', [Title]);
  if Assigned(FLink) then
    FreeAndNil(Flink);
  FFilters.Free;
  inherited Destroy;
end;

procedure TGraphPar.DoContextPopup(MousePos: TPoint; var Handled: Boolean);
begin
  Graph.ContextPopupEvent(Self, ppeParam, MousePos);
  if Assigned(FOnContextPopup) then
    FOnContextPopup(Self, MousePos, Handled);
end;

function TGraphPar.GetCaption: string;
begin
{$IFDEF ENG_VERSION}
  Result := 'Parameter ' + ClassName
{$ELSE}
  Result := 'Параметр ' + ClassName
{$ENDIF}
end;

function TGraphPar.GetLinkClass: string;
begin
  if Assigned(FLink) then
    Result := FLink.ClassName
  else
    Result := '';
end;

function TGraphPar.QueryInterface(const IID: TGUID; out Obj): HResult;
begin
  Result := inherited;
  if (Result <> S_OK) and Assigned(Link) then
    Result := Link.QueryInterface(IID, Obj)
end;

procedure TColumnCollectionItem.NotifyCollumn;
begin
  if csDestroying in Graph.ComponentState then
    Exit;
  Column.ColumnCollectionItemChanged(Self);
end;

procedure TGraphPar.SetCaption(const Value: string);
begin

end;

procedure TGraphPar.SetColor(const Value: TAlphaColor);
begin
  FColor := Value;
  NotifyCollumn;
end;

//procedure TGraphPar.SetDataSet(const Value: TDataSet);
//begin
//  FDataSet := Value;
//end;

procedure TGraphPar.SetDeltaX(const Value: Double);
begin
  FDeltaX := Value;
  NotifyCollumn;
end;

procedure TGraphPar.SetDeltaY(const Value: Double);
begin
  if FDeltaY <> Value then
  begin
    FDeltaY := Value;
    Graph.UpdateData;
    NotifyCollumn;
  end;
end;

procedure TGraphPar.SetEUnit(const Value: string);
begin
  FEUnit := Value;
  NotifyCollumn;
end;

procedure TGraphPar.SetHideInLegend(const Value: boolean);
begin
  FHideInLegend := Value;
  NotifyCollumn;
end;

procedure TGraphPar.SetLink(const Value: TCustomDataLink);
begin
  if Assigned(FLink) then
    FLink.Free;
  FLink := Value;
  NotifyCollumn;
end;

procedure TGraphPar.SetLinkClass(const Value: string);
begin
  if Assigned(FLink) then
    FreeAndNil(Flink);
  if Value <> '' then
    FLink := TCustomDataLinkClass(FindClass(Value)).Create(Self);
end;

procedure TGraphPar.SetSelected(const Value: Boolean);
begin
  FSelected := Value;
  NotifyCollumn;
end;

procedure TGraphPar.SetTitle(const Value: string);
begin
  FTitle := Value;
  NotifyCollumn;
end;

procedure TGraphPar.SetVisible(const Value: Boolean);
begin
  FVisible := Value;
  NotifyCollumn;
end;

{ TCustomDataLink }

constructor TCustomDataLink.Create(AOwner: TGraphPar);
begin
  FOwner := AOwner;
  Tdebug.log(' ===  TCustomDataLink.Create === ');
end;

destructor TCustomDataLink.Destroy;
begin
  Tdebug.log(' ===  TCustomDataLink.Destroy === ' + XParamPath + '      ');
  inherited;
end;

function TCustomDataLink.GenerateBufferFileName: string;
begin
  Result := DataSetIntf.GetTempDir + FYParamPath.Replace('.', '') + FXParamPath.Replace('.', '') + '.bin'
end;

function TCustomDataLink.GetCaption: string;
begin
{$IFDEF ENG_VERSION}
  Result := 'Parameter data source'
{$ELSE}
  Result := 'Источник данных параметра'
{$ENDIF}
end;

{function TCustomDataLink.GetDataSet: TDataSet;
begin
  if not Assigned(FIDataSet) then
    DataSetDef.TryGet(FIDataSet);
  Result := FIDataSet.DataSet;
end;

function TCustomDataLink.GetIDataSet: IDataSet;
begin
  if not Assigned(FIDataSet) then
    DataSetDef.TryGet(FIDataSet);
  Result := FIDataSet;
end;}

function TCustomDataLink.FiendField(const Fullname: string): TField;
var
  i: Integer;
begin
  for i := 0 to DataSet.FieldList.Count - 1 do
  begin
    if SameText(DataSet.FieldList[i].Fullname, Fullname) then
      Exit(DataSet.FieldList[i]);
  end;
{$IFDEF ENG_VERSION}
  raise Exception.CreateFmt('Field %s not found in %s', [Fullname, DataSet.Name]);
{$ELSE}
  raise Exception.CreateFmt('Поле %s ненайдено в %s', [Fullname, DataSet.Name]);
{$ENDIF}
end;

function TCustomDataLink.GetXField: TField;
begin
  if FFieldX = nil then
    FFieldX := FiendField(XParamPath);
  Result := FFieldX;
end;

function TCustomDataLink.GetXFieldDef: TFieldDef;
begin
  if FXFieldDef = nil then
    FXFieldDef := TFileDataSet(DataSet).FindFieldDef(XParamPath);
  Result := FXFieldDef;
end;

function TCustomDataLink.GetYField: TField;
begin
  if FFieldY = nil then
    FFieldY := FiendField(YParamPath);
  Result := FFieldY;
end;

function TCustomDataLink.IndexOfY(Y: Double; FindIndexType: TFindIndexType; out YFind: Double): Integer;
var
  d: TDataSet;
  dy: Double;

  function FindNext: Integer;
  begin
    Result := -1;
    while not d.Eof do
    begin
      YFind := FieldY.AsFloat;
      if YFind = Y then
        Exit(d.RecNo - 1)
      else if YFind > Y then
      begin
        //  возвращаем меньшее значение
        if FindIndexType = fndLower then
        begin
          d.Prior;
          YFind := FieldY.AsFloat;
        end;
        Exit(d.RecNo - 1);
      end;
      d.Next;
    end
  end;

  function FindPrior: Integer;
  begin
    Result := -1;
    while not d.Bof do
    begin
      YFind := FieldY.AsFloat;
      if YFind = Y then
        Exit(d.RecNo - 1)
      else if YFind < Y then
      begin
        if FindIndexType = fndHiger then
        begin
          d.Next;
          YFind := FieldY.AsFloat;
        end;
        Exit(d.RecNo - 1);
      end;
      d.Prior;
    end
  end;

begin
  Result := -1;
  d := DataSet;
  d.Active := True;
  if not Assigned(FieldY) then
    Exit;
  // проверка на зашкаливание
  d.Last;
  YFind := FieldY.AsFloat;
  if YFind <= Y then
    Exit(d.RecNo - 1);
  d.First;
  YFind := FieldY.AsFloat;
  if YFind >= Y then
    Exit(0);
  d.Next;
  dy := FieldY.AsFloat - YFind;
  // поиск по всем Y вверх
  if dy = 0 then
    Exit(FindNext)
  else
  begin
    d.RecNo := Round((Y - YFind) / dy);
    YFind := FieldY.AsFloat;
   // поиск Y вверх
    if YFind < Y then
      Exit(FindNext)
   // поиск Y вниз
    else if YFind > Y then
      Exit(FindPrior)
   // нашли сразу Y
    else
      Exit(d.RecNo - 1);
  end;
end;

procedure TCustomDataLink.NillDataSet;
begin
  //FIDataSet := nil;
  FFieldX := nil;
  FFieldY := nil;
  FXFieldDef := nil;
end;

procedure TCustomDataLink.ResetBuffer;
begin

end;

{function TCustomDataLink.GetDataSetClass: string;
begin
  if Assigned(FDataSetDef) then
    Result := FDataSetDef.ClassName
  else
    Result := '';
end;}

function TCustomDataLink.GetDrowMemoryBuffer: IInterface;
begin
  Result := FDrowMemoryBuffer;
end;

procedure TCustomDataLink.SetDrowMemoryBuffer(const Value: IInterface);
begin
  FDrowMemoryBuffer := Value;
end;

//procedure TCustomDataLink.SetDataSetDef(const Value: TIDataSetDef);
//begin
//  if Assigned(FDataSetDef) then
//    FDataSetDef.Free;
//  FDataSetDef := Value;
//end;

procedure TCustomDataLink.SetBindWriteFile(const Value: Integer);
begin
  FBindWrite := Value;
  owner.Graph.UpdateData;
end;

procedure TCustomDataLink.SetCaption(const Value: string);
begin
end;

//procedure TCustomDataLink.SetDataSetClass(const Value: string);
//begin
//  if Assigned(FDataSetDef) then
//    FreeAndNil(FDataSetDef);
//  if Value <> '' then
//    FDataSetDef := TIDataSetDef((FindClass(Value)).Create());
//end;

{ TGraphParams }

function TGraphParams.GetCaption: string;
begin
{$IFDEF ENG_VERSION}
  Result := 'Paramerers'
{$ELSE}
  Result := 'Параметры'
{$ENDIF}
end;

procedure TGraphParams.Notify(Item: TCollectionItem; Action: TCollectionNotification);
begin
  inherited;
  if Action = TCollectionNotification.cnAdded then
    FColumn.ColumnCollectionChanged(Self);
end;

{ TXScalableParam }

constructor TXScalableParam.Create(Collection: TCollection);
begin
  FScaleX := 0.001;
  FWidth := 1;
  inherited;
end;

procedure TXScalableParam.SetRange(L, R: Double);
begin
  FScaleX := FindBestScale(Column.Width / (Screen.PixelsPerInch / 2.54 * 2) / Abs(R - L));
  FDeltaX := Round(L * ScaleX) / ScaleX;
  NotifyCollumn;
end;

procedure TXScalableParam.SetScale(const Value: Double);
begin
  if Value = 0 then
    Exit;
  FScaleX := Value;
  NotifyCollumn;
end;

procedure TXScalableParam.SetDashStyle(const Value: TLineDashStyle);
begin
  FDashStyle := Value;
  NotifyCollumn;
end;

procedure TXScalableParam.SetWidth(const Value: Integer);
begin
  if FWidth = 0 then
    Exit;
  FWidth := Value;
  NotifyCollumn;
end;

{ TWaveParam }

constructor TWaveParam.Create(Collection: TCollection);
var
  i: Integer;
begin
  inherited;
  FWaveStyle := wsGamma;
  FKoefGamma := 0.01;
  for i := -128 to -1 do
    FGamma[i] := $7FFF0000 + (i div 2) * $100 + i div 2;
  for i := 0 to 127 do
    FGamma[i] := $7F0000FF + ((255 - i) div 2) * $10000 + ((255 - i) div 2) * $100;
end;

function TWaveParam.GetGammaStr: TGammaProp;
var
  c: TColor;
begin
  Result := '';
  for c in FGamma do
    Result := Result + ',' + IntToHex(c, 4);
 // Tdebug.log('GetGammaStr : '+Result);
end;

procedure TWaveParam.SetGamma(const Value: TGamma);
begin
  FGamma := Value;
  NotifyCollumn;
end;

procedure TWaveParam.SetGammaStr(const Value: TGammaProp);
var
  i: Integer;
  a: TArray<string>;
begin
//  Tdebug.log('SetGammaStr(const Value) : '+ Value);
  a := string(Value).Split([','], TStringSplitOptions.ExcludeEmpty);
  if Length(a) <> 256 then
    raise Exception.Create('Error Message');
  for i := 0 to 255 {Min(255, High(a))} do
    FGamma[i - 128] := ('$' + a[i]).ToInteger();
  NotifyCollumn;
end;

procedure TWaveParam.SetKoefGamma(const Value: Double);
begin
  FKoefGamma := Value;
  NotifyCollumn;
end;

procedure TWaveParam.SetWaveStyle(const Value: TWaveStyle);
begin
  FWaveStyle := Value;
  NotifyCollumn;
end;

procedure TWaveParam.SetZeroGamma(const Value: Double);
begin
  FZeroGamma := Value;
  NotifyCollumn;
end;

{$ENDREGION}
  {$ENDREGION 'структура колонки Region, Parameters'}

   {$REGION 'структура параметра: История изменений'}
/// коллекция Параметра общее

{ TParamCollectionItem }

constructor TParamCollectionItem.Create(Collection: TCollection);
begin
  FParam := TParamCollection<TParamCollectionItem>(Collection).FParam;
  inherited Create(Collection);
end;

{ TParamCollection<T> }

constructor TParamCollection<T>.Create(AOwner: TObject);
begin
  FParam := TGraphPar(AOwner);
  inherited Create(TGraphPar(AOwner).Column);
end;
     {$REGION 'История изменений (Фильтров) параметра'}

{ TParamFilter }

function TParamFilter.GetIData: IFileData;
begin
  if not Assigned(FIData) and TFile.Exists(FSourceFile) then
    FIData := GFileDataFactory.Factory(TFileData, FSourceFile);
  Result := FIData;
end;

procedure TParamFilter.SetActiv(const Value: Boolean);
var
  f: TParamFilter;
begin
  if Value = True then
  begin
    for f in Param.Filters do
      f.Activ := False;
    FActiv := True;

  end
  else
    FIData := nil;
end;

procedure TParamFilter.SetCaption(const Value: string);
begin
end;

procedure TParamFilter.SetSourceFile(const Value: string);
begin
  if FSourceFile <> '' then
{$IFDEF ENG_VERSION}
    raise EParamFilter.CreateFmt('file %s cannot be replaced with %s', [FSourceFile, Value]);
{$ELSE}
    raise EParamFilter.CreateFmt('файл %s нельзя заменить на %s', [FSourceFile, Value]);
{$ENDIF}
  if not TFile.Exists(Value) then
{$IFDEF ENG_VERSION}
    raise EParamFilter.CreateFmt('file %s not found', [Value]);
{$ELSE}
    raise EParamFilter.CreateFmt('файл %s не найден', [Value]);
{$ENDIF}
  FSourceFile := Value;
end;

{ TParamFilters }

function TParamFilters.GetCaption: string;
begin
{$IFDEF ENG_VERSION}
  Result := 'Filters'
{$ELSE}
  Result := 'Фильтры'
{$ENDIF}
end;

procedure TParamFilters.SetCaption(const Value: string);
begin
end;

{ TWaveletFilter }

function TWaveletFilter.GetCaption: string;
begin
{$IFDEF ENG_VERSION}
  Result := 'Wavelet'
{$ELSE}
  Result := 'Вейвлет'
{$ENDIF}
end;
     {$ENDREGION}
   {$ENDREGION}
{$ENDREGION Collection}

{$REGION ' классы выполняюшие GraphState '}

{ TCustomEditDlot }

constructor TCustomEditDlot.Create(Owner: TCustomGraph; Pos: TPoint; ps: GraphState; Item: TColRowCollectionItem);
begin
  FOwner := Owner;
  FItem := Item;
  FSwap := Item;
  FState := ps;
  if FState in [pcsColMoving, pcsRowMoving] then
    Fpos := Item.FFrom
  else
    Fpos := SetPos(Pos);
  Drow;
end;

destructor TCustomEditDlot.Destroy;
begin
  FOwner.FState := pcsNormal;
  inherited;
end;

procedure TCustomEditDlot.Drow;
begin
  with FOwner.Canvas do
  begin
    Pen.Style := psDot;
    Pen.Mode := pmXor;
    if FState in [pcsColSizing, pcsRowSizing] then
    begin
      Pen.Color := clBlack;
      Pen.Width := 1;
    end
    else
    begin
      Pen.Color := clWhite;
      Pen.Width := 5;
    end;
    if FState in [pcsColSizing, pcsColMoving] then
    begin
      MoveTo(Fpos, 0);
      LineTo(Fpos, FOwner.ClientHeight);
    end
    else
    begin
      MoveTo(0, Fpos);
      LineTo(FOwner.ClientWidth, Fpos);
    end;
  end;
end;

procedure TCustomEditDlot.Move(Pos: TPoint);
begin
  Drow;
  Fpos := SetPos(Pos);
  Drow;
end;

function TCustomEditDlot.SetPos(Pos: TPoint): integer;
begin
  if FState in [pcsColMoving, pcsColSizing] then
    Result := Pos.X
  else
    Result := Pos.Y;
end;

{ TRowSizing }

destructor TColMoving.Destroy;
begin
  if FItem <> FSwap then
  begin
    FItem.Index := FSwap.Index;
    if FState = pcsColMoving then
      FOwner.Columns.UpdateSizes()
    else
    begin
      FOwner.Rows.UpdateSizes();
      FOwner.FYScrollBar.SetGraphYScreen;
    end;
    FOwner.UpdateRegionSizes;
    FOwner.Repaint;
  end
  else
    Drow;
  inherited;
end;

procedure TColMoving.Move(Pos: TPoint);
var
  r: TColRowCollectionItem;
  p: Integer;
begin
  p := SetPos(Pos);
  for r in TGraphCollection<TColRowCollectionItem>(FItem.Collection) do
    if (p < r.GetTo) and (p > r.FFrom) and (FSwap <> r) then
    begin
      Drow;
      FSwap := r;
      Fpos := r.FFrom;
      Drow;
      Break;
    end;
end;

{ TColSizing }

destructor TColSizing.Destroy;
var
  wold: Integer;
begin
  wold := FItem.FLen;
  if FState = pcsColSizing then
    FSwap := FOwner.Columns.LastToResize(FOwner.Columns.Count - 1, FItem.Index + 1)
  else
    FSwap := FOwner.Rows.LastToResize(FOwner.Rows.Count - 1, FItem.Index + 1);
  if FItem <> FSwap then
  begin
    FItem.SetLen(Fpos - FItem.FFrom);
    FSwap.SetLen(FSwap.FLen - (FItem.FLen - wold));
    if FState = pcsColSizing then
      FOwner.Columns.UpdateSizes()
    else
    begin
      FOwner.Rows.UpdateSizes();
      FOwner.FYScrollBar.Update;
      FOwner.FYScrollBar.SetGraphYScreen;
    end;
    FOwner.UpdateRegionSizes;
    FOwner.Repaint;
  end
  else
    Drow;
  inherited;
end;
{$ENDREGION}

{$REGION 'классы выполняюшие ScrollBar'}
{ TYScrollBar }

constructor TYScrollBar.Create(Owner: TCustomGraph);
begin
  Graph := Owner;
  Fpp2mm := Screen.PixelsPerInch / 2.54 * 2;
  Update
end;

function TYScrollBar.GetRealScrollPosition: Integer;
var
  si: TScrollInfo;
begin
  si.cbSize := SizeOf(TScrollInfo);
  si.fMask := SIF_TRACKPOS;
  FlatSB_GetScrollInfo(Graph.Handle, SB_VERT, si);
  Result := si.nTrackPos;
end;

function TYScrollBar.GetRow: TCustomGraphDataRow;
var
  r: TGraphRow;
begin
  if Assigned(FRow) then
    Exit(FRow);
  for r in Graph.Rows do
    if r is TCustomGraphDataRow then
    begin
      FRow := TCustomGraphDataRow(r);
      Exit(Frow);
    end;
  Result := nil;
end;

function TYScrollBar.Line: Integer;
begin
  Result := Round(1000 / 3 / Graph.YScale);
end;

function TYScrollBar.Page: Integer;
begin
  Result := 1;
  if Assigned(Row) then
    Result := Round(FRow.Height / Fpp2mm / Graph.YScale * 1000);
  if Result = 0 then
    Result := 1;
end;

function TMirrorYScrollBar.GetPosition: Integer;
begin
  Result := Round((Graph.YRangeData - (Graph.YPosition - Graph.YFromData)) * 1000);
end;

function TYScrollBar.GetPosition: Integer;
begin
  Result := Round((Graph.YPosition - Graph.YFromData) * 1000);
end;

function TYScrollBar.Range: Integer;
begin
  Result := Round(Graph.YRangeData * 1000);
end;

procedure TYScrollBar.SetPosition(Y: Integer);
var
  DeltaY: Integer;
begin
  if Y < 0 then
    Y := 0
  else if Y > Range then
    Y := Range;
  DeltaY := GetPosition - Y;
  if DeltaY <> 0 then
  begin
    if WinApi.Windows.GetScrollPos(Graph.Handle, SB_VERT) <> Y then
      WinApi.Windows.SetScrollPos(Graph.Handle, SB_VERT, Y, True);
    SetGraphPosition(Y);
  end;
end;

procedure TYScrollBar.Scroll(var Message: TWMVScroll);
begin
  case Message.ScrollCode of
    SB_BOTTOM:
      SetPosition(Range);
    SB_ENDSCROLL:
      Update;
    SB_LINEUP:
      SetPosition(GetPosition - Line);
    SB_LINEDOWN:
      SetPosition(GetPosition + Line);
    SB_PAGEUP:
      SetPosition(GetPosition - Page);
    SB_PAGEDOWN:
      SetPosition(GetPosition + Page);
    SB_THUMBPOSITION, SB_THUMBTRACK:
      SetPosition(GetRealScrollPosition);
    SB_TOP:
      SetPosition(0);
  end;
  Message.Result := 0;
//  Graph.Perform(CM_UPDATE_SCROLLBAR,0,0);
end;

procedure TMirrorYScrollBar.SetGraphPosition(Y: Integer);
begin
  Graph.FYPosition := Graph.YRangeData - Y / 1000 + Graph.YFromData;
  SetGraphYScreen;
end;

procedure TYScrollBar.SetGraphPosition(Y: Integer);
begin
  Graph.FYPosition := Graph.YFromData + Y / 1000;
  SetGraphYScreen;
end;

procedure TMirrorYScrollBar.SetGraphYScreen;
var
  t, d, dl: Double;
begin
  if not Assigned(Row) then
    Exit;
  dl := FRow.Height / Fpp2mm / Graph.YScale;
  t := Graph.YPosition;
  d := t - dl;
  if dl > Graph.YRangeData then
  begin
    t := Graph.YLast;
    d := t - dl;
  end
  else if d < Graph.YFromData then
  begin
    d := Graph.YFromData;
    t := d + dl;
  end;
  if (t <> Graph.YTopScreen) or (d <> Graph.YButtomScreen) then
    Graph.UpdateYScreen(t, d);
end;

procedure TYScrollBar.SetGraphYScreen;
var
  t, d, dl: Double;
begin
  if not Assigned(Row) then
    Exit;
  dl := FRow.Height / Fpp2mm / Graph.YScale;
  t := Graph.YPosition;
  d := t + dl;
  if dl > Graph.YRangeData then
  begin
    t := Graph.YFromData;
    d := t + dl;
  end
  else if d > Graph.YLast then
  begin
    d := Graph.YLast;
    t := d - dl;
  end;
  if (t <> Graph.YTopScreen) or (d <> Graph.YButtomScreen) then
    Graph.UpdateYScreen(t, d);
end;

procedure TYScrollBar.UpdatePosition;
var
  y: Integer;
begin
  if Graph.LoadOrDestroy then
    Exit;
  y := Position;
  if WinApi.Windows.GetScrollPos(Graph.Handle, SB_VERT) <> y then
    WinApi.Windows.SetScrollPos(Graph.Handle, SB_VERT, y, True);
end;

procedure TYScrollBar.Update;
var
  ScrollInfo: TScrollInfo;
  ofY: Integer;
begin
  if Graph.LoadOrDestroy then
    Exit;
  ScrollInfo.cbSize := SizeOf(ScrollInfo);
  ScrollInfo.fMask := SIF_ALL;
  ScrollInfo.nMin := 0;
  ScrollInfo.nMax := Range;
  ScrollInfo.nPage := Page;
  ofY := GetPosition;
  ScrollInfo.nPos := ofY;
  ScrollInfo.nTrackPos := ofY;
//  FlatSB_SetScrollInfo(Graph.Handle, SB_VERT, ScrollInfo, True);
  WinApi.Windows.SetScrollInfo(Graph.Handle, SB_VERT, ScrollInfo, TRUE);
//  Graph.Perform(CM_UPDATE_SCROLLBAR,0,0);
end;

procedure TYScrollBar.Wheel(var Message: TCMMouseWheel);
var
  ScrollAmount: Integer;
  WheelFactor: Double;
begin
  inherited;
  with Message do
  begin
    if Page < Range then
    begin
      WheelFactor := WheelDelta / WHEEL_DELTA;
      if ssCtrl in ShiftState then
        ScrollAmount := Trunc(WheelFactor * Page)
      else
        ScrollAmount := Trunc(WheelFactor * line);
      SetPosition(GetPosition - ScrollAmount);
    end
  end;
end;
{$ENDREGION}

{$REGION 'TCustomGraph ----- Create Destroy'}

{ TCustomGraph }

constructor TCustomGraph.Create(AOwner: TComponent);
begin
  inherited;
  FFrostCount := 1;
  FYFirstAvail := 0;
  FYLastAvail := 1000;
  FYFromType := yfmALL;
  FYScale := 1;
  FRows := TGraphRows.Create(Self);
  FColumns := TGraphColumns.Create(Self);
  FYScrollBar := TYScrollBar.Create(Self);
end;

destructor TCustomGraph.Destroy;
begin
  FYScrollBar.Free;
  FColumns.Free;
  FRows.Free;
  inherited;
end;

procedure TCustomGraph.DoContextPopup(MousePos: TPoint; var Handled: Boolean);
var
  r: TGraphColmn;
begin
  inherited;
  ContextPopupEvent(Self, ppeGraph, MousePos);
//  if Assigned(PopupMenu) then
  if not Handled then
  begin
    r := HitColumn(MousePos);
    if Assigned(r) then
      r.DoContextPopup(MousePos, Handled);
  end;
end;

procedure TCustomGraph.DoParamsAdded(DataSet: TDataSet);
begin
  if Assigned(FOnParamsAdded) then
    FOnParamsAdded(DataSet)
end;

procedure TCustomGraph.ContextPopupEvent(AObject: TObject; Event: TCustomContextPlotPopup.TPopupEvent; MousePos: TPoint);
begin
  if Assigned(PopupMenu) and (PopupMenu is TCustomContextPlotPopup) then
    (PopupMenu as TCustomContextPlotPopup).DoContextPopup(AObject, Event, MousePos);
end;

//procedure TCustomGraph.DataAdded;
//begin
//  if Assigned(FOnDataAdded) then FOnDataAdded(self);
//end;

procedure TCustomGraph.DefineProperties(Filer: TFiler);
begin
  inherited DefineProperties(Filer);
  FRows.RegisterProperty(Filer, 'GraphRows');
  FColumns.RegisterProperty(Filer, 'GraphColumns');
end;


{$ENDREGION}

{$REGION 'TCustomGraph ----- SCROLL DATA'}
procedure TCustomGraph.WMVScroll(var Message: TWMVScroll);
begin
  FYScrollBar.Scroll(Message);
end;

procedure TCustomGraph.CMMouseWheel(var Message: TCMMouseWheel);
var
  dlt: Double;
  i, idx: Integer;
  gr: TGraphRegion;
begin
  if Message.Result <> 0 then
    Exit;
  with Message do
  begin
    Result := 1;
    if ssShift in ShiftState then
    begin
      dlt := 1000000;
      idx := -1;
      for i := 0 to High(SCALE_PRESET_Y) do
        if Abs(SCALE_PRESET_Y[i] - YScale) < dlt then
        begin
          idx := i;
          dlt := Abs(SCALE_PRESET_Y[i] - YScale);
        end;
      if idx = -1 then
        if WheelDelta > 0 then
          YScale := YScale * 2
        else
          YScale := YScale / 2
      else
      begin
        idx := idx + Sign(WheelDelta);
        if (idx >= 0) and (idx < Length(SCALE_PRESET_Y)) then
          YScale := SCALE_PRESET_Y[idx];
      end;
    end
    else
     begin
        if TryHitRegion(ScreenToClient(Tpoint.Create(XPos, YPos)), gr) and gr.СaptureMouseWell then
          gr.MouseWheel(Message)
       else FYScrollBar.Wheel(Message);
     end


  end
end;

procedure TCustomGraph.CMParentFontChanged(var Message: TCMParentFontChanged);
var
  c: TGraphColmn;
  r: TGraphRegion;
begin
  inherited;
  if not HandleAllocated then
    Exit;
  for c in Columns do
    for r in c.Regions do
      r.ParentFontChanged;
end;

{$ENDREGION 'TCustomGraph ----- SCROLL BAR'}

{$REGION 'TCustomGraph ----- MOVE, RESIZE HIT'}

procedure TCustomGraph.UpdateData;
var
  c: TGraphColmn;
  p: TGraphPar;
  b: TBookmark;
  SaveActive: Boolean;
  OldActiveData: Boolean;
  f, l, oldf, oldl: Double;
begin
  OldActiveData := ActiveData;
  oldf := FYFirstAvail;
  oldl := FYLastAvail;
  f := Single.MaxValue;
  l := 0;
  for c in Columns do
    for p in c.Params do
      with p.Link.DataSet do
      begin
        SaveActive := p.Link.DataSet.active;
        p.Link.DataSet.active := True;
        b := Bookmark;
        try
          First;
          f := min(f, p.Link.FieldY.AsFloat + p.DeltaY);
          Last;
          l := max(l, p.Link.FieldY.AsFloat + p.DeltaY);
        finally
          Bookmark := b;
          p.Link.DataSet.active := SaveActive;
        end;
      end;
  if l < f then f := 0;
  FYLastAvail  := l;
  FYFirstAvail := f;
  UpdateAvalableRangeY;
  if FYLastAvail < FYFirstAvail then  FYFirstAvail := 0;
  if (l <> oldl) or (f <> oldf) then (GContainer as IMainScreen).Changed;
  if OldActiveData and ((l <> oldl) or (f <> oldf)) then
   begin
//    Frost;
//    try
    for c in Columns do
     begin
      for p in c.Params do p.FLink.ResetBuffer;
     end;
    YPosition := Ylast;
//    finally
//     DeFrost;
//    end;
   end
  else
   begin
    ChekYPosition;
    FYScrollBar.Update;
    FYScrollBar.SetGraphYScreen;
   end;
end;

procedure TCustomGraph.UpdateColRowRegionSizes;
begin
  //if (csDestroying in ComponentState) or not HandleAllocated then Exit;
  if LoadOrDestroy then
    Exit;
  Rows.UpdateSizes;
  FYScrollBar.SetGraphYScreen;
  Columns.UpdateSizes;
  UpdateRegionSizes;
end;

procedure TCustomGraph.UpdateRegionSizes;
var
  c: TGraphColmn;
//  p: TGraphRegion;
begin
//  if csLoading in ComponentState then Exit;
  if LoadOrDestroy then
    Exit;
  for c in Columns do
    c.UpdateRegionsSize; // for p in c.Regions do p.UpdateSize;
end;

procedure TCustomGraph.UpdateYScreen(t, d: Double);
begin
  FYTopScreen := SimpleRoundTo(t);
  FYButtomScreen := SimpleRoundTo(d);
  S_PropertyChanged := 'Screen';
end;

function TCustomGraph.HitColumn(pos: TPoint): TGraphColmn;
var
  r: TGraphColmn;
begin
  for r in Columns do
    if r.Visible and (pos.X >= r.Left) and (pos.X <= r.Right) then
      Exit(r);
  Result := nil;
//  raise EBaseException.Create('Нет колонки в данном месте');
end;

function TCustomGraph.HitRegion(pos: TPoint): TGraphRegion;
begin
  Result := HitRegion(HitColumn(pos), HitRow(pos));
end;

function TCustomGraph.HitRegion(c: TGraphColmn; r: TGraphRow): TGraphRegion;
var
  p: TGraphRegion;
begin
  Result := nil;
  if Assigned(c) and Assigned(r) then
    for p in c.Regions do
      if p.Row = r then
        Exit(p);
//  raise EBaseException.Create('Нет региона в данном месте');
end;

function TCustomGraph.HitRow(pos: TPoint): TGraphRow;
var
  r: TGraphRow;
begin
  for r in Rows do
    if r.Visible and (pos.Y >= r.Top) and (pos.Y <= r.Bottom) then
      Exit(r);
  Result := nil;
//  raise EBaseException.Create('Нет ряда в данном месте');
end;

procedure TCustomGraph.WMEraseBkgnd(var Msg: TWMEraseBkgnd);
begin
  Msg.Result := 1;
end;

procedure TCustomGraph.WMNCHitTest(var Msg: TWMNCHitTest);
begin
  DefaultHandler(Msg);
  if Msg.Result = HTCLIENT then
    FHitTest := ScreenToClient(SmallPointToPoint(Msg.Pos));
end;

function TCustomGraph.IsMouseSizeMove(Pos: TPoint; var ps: GraphState; out Item: TColRowCollectionItem): Boolean;
const
  MM = 4;
var
  c: TGraphColmn;
  r: TGraphRow;

  function Setps(s: GraphState; ri: TColRowCollectionItem): Boolean;
  begin
    Item := ri;
    ps := s;
    Result := True;
  end;

begin
  if Pos.Y < MM * 2 then
    for c in Columns do
      if c.Visible and (c.Left < Pos.X) and (Pos.X < c.Right) then
        Exit(Setps(pcsColMoving, c));
  if Pos.X < MM * 2 then
    for r in Rows do
      if r.Visible and (r.Top < Pos.Y) and (Pos.Y < r.Bottom) then
        Exit(Setps(pcsRowMoving, r));
  if Pos.X < ClientWidth - MM * 2 then
    for c in Columns do
      if c.Visible and (Abs(c.Right - Pos.X) < MM) then
        Exit(Setps(pcsColSizing, c));
  if Pos.Y < ClientHeight - MM * 2 then
    for r in Rows do
      if r.Visible and (Abs(r.Bottom - Pos.Y) < MM) then
        Exit(Setps(pcsRowSizing, r));
  Result := False;
  ps := pcsNormal;
  Item := nil;
end;

function TCustomGraph.IsMouseSizeMove(Pos: TPoint; var ps: GraphState): Boolean;
const
  MM = 4;
var
  c: TGraphColmn;
  r: TGraphRow;

  function Setps(s: GraphState): Boolean;
  begin
    ps := s;
    Result := True;
  end;

begin
  if (Pos.Y < MM * 2) then
    Exit(Setps(pcsColMoving));
  if (Pos.X < MM * 2) then
    Exit(Setps(pcsRowMoving));
  if Pos.X < ClientWidth - MM * 2 then
    for c in Columns do
      if c.Visible and (Abs(c.Right - Pos.X) < MM) then
        Exit(Setps(pcsColSizing));
  if Pos.Y < ClientHeight - MM * 2 then
    for r in Rows do
      if r.Visible and (Abs(r.Bottom - Pos.Y) < MM) then
        Exit(Setps(pcsRowSizing));
  Result := False;
  ps := pcsNormal;
end;

procedure TCustomGraph.Loaded;
begin
  inherited;
  Color := StyleServices.GetStyleColor(scTreeView);
  font.Color := StyleServices.GetStyleFontColor(sfWindowTextNormal);
  UpdateColRowRegionSizes;
  Canvas.Font.Color := StyleServices.GetStyleFontColor(sfWindowTextNormal);
  Canvas.Brush.Color := Color;
end;

function TCustomGraph.LoadOrDestroy: Boolean;
begin
  Result := (ComponentState * [csLoading, csDestroying] <> []) or not HandleAllocated
end;

procedure TCustomGraph.WMSetCursor(var Msg: TWMSetCursor);
var
  State: GraphState;
  Cur: HCURSOR;
  r: TGraphRegion;
begin
  Cur := 0;
  State := pcsNormal;
  if Msg.HitTest = HTCLIENT then
  begin
    if FState <> pcsNormal then
      State := FState
    else if not IsMouseSizeMove(FHitTest, State) and TryHitRegion(FHitTest, r) then
      Cur := Screen.Cursors[r.Cursor];
    /// setup cursors
    if (State = pcsColSizing) then
      Cur := Screen.Cursors[crHSplit]
    else if (State = pcsRowSizing) then
      Cur := Screen.Cursors[crVSplit]
    else if State in [pcsColMoving, pcsRowMoving] then
      Cur := Screen.Cursors[crDrag]
  end;
  if Cur <> 0 then
    SetCursor(Cur)
  else
    inherited;
end;

procedure TCustomGraph.WMSize(var Message: TWMSize);
begin
  inherited;
  if HandleAllocated and (FState = pcsNormal) and (ClientHeight > 0) and (ClientWidth > 0) and not (csLoading in ComponentState) then
  try
//    Include(FStates, psSizing);
    UpdateColRowRegionSizes;
    FYScrollBar.Update;
  finally
//   Exclude(FStates, psSizing);
  end;
end;

procedure TCustomGraph.MouseDown(Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
const
  CCLS: array[GraphState] of TCustomEditDlotClass = (TCustomEditDlot, TColSizing, TColMoving, TRowSizing, TRowMoving);
var
  r: TColRowCollectionItem;
begin
  try
    if not (csDesigning in ComponentState) and (CanFocus or (GetParentForm(Self) = nil)) then
    begin
      SetFocus;
    end;
    if (Button = mbLeft) and (ssDouble in Shift) then
      DblClick
    else if Button = mbLeft then
      if IsMouseSizeMove(Tpoint.Create(X, Y), FState, r) then
        FEditGraph := CCLS[FState].Create(Self, Tpoint.Create(X, Y), FState, r)
      else if TryHitRegion(Tpoint.Create(X, Y), FHitRegion) then
        FHitRegion.MouseDown(Button, Shift, X, Y);
  finally
    inherited;
  end;
end;

procedure TCustomGraph.MouseMove(Shift: TShiftState; X, Y: Integer);
begin
  if Assigned(FEditGraph) then
    FEditGraph.Move(TPoint.Create(X, Y))
  else if Assigned(FHitRegion) then
    FHitRegion.MouseMove(Shift, X, Y);
  inherited;
end;

procedure TCustomGraph.MouseUp(Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
begin
  if Assigned(FEditGraph) then
    FreeAndNil(FEditGraph)
  else if Assigned(FHitRegion) then
  begin
    FHitRegion.MouseUp(Button, Shift, X, Y);
    FHitRegion := nil;
  end;
  inherited;
end;

{$ENDREGION}

{$REGION 'TCustomGraph ----- P A I N T'}

procedure TCustomGraph.Frost;
begin
  Inc(FFrostCount);
end;

function TCustomGraph.Frosted: Boolean;
begin
  Result := FFrostCount > 0;
end;

procedure TCustomGraph.DeFrost;
begin
  Dec(FFrostCount);
  if FFrostCount = 0 then
    Paint;
  if FFrostCount < 0 then
    FFrostCount := 0;
end;

procedure TCustomGraph.DrowRegionsBounds;
var
  c: TGraphColmn;
  r: TGraphRow;
begin
  Canvas.Pen.Color := StyleServices.GetStyleFontColor(sfWindowTextDisabled);
  Canvas.Pen.Width := 1;
  Canvas.Pen.Style := psSolid;
  Canvas.Pen.Mode := pmCopy;
  Canvas.moveTo(ClientWidth, 0);
  Canvas.LineTo(0, 0);
  Canvas.LineTo(0, ClientHeight);
  for c in Columns do
    if c.Visible then
    begin
      Canvas.moveTo(c.Right, 0);
      Canvas.LineTo(c.Right, ClientHeight);
    end;
  for r in Rows do
    if r.Visible then
    begin
      Canvas.moveTo(0, r.Bottom);
      Canvas.LineTo(ClientWidth, r.Bottom);
    end;
end;

procedure TCustomGraph.Paint;
var
  c: TGraphColmn;
  p: TGraphRegion;
begin
  if not Frosted and HandleAllocated then
  begin
    TDebug.Log('TCustomGraph ----- P A I N T');
    DrowRegionsBounds;
    for c in Columns do
      if c.Visible then
        for p in c.Regions do
          if p.Row.Visible then
            p.Paint;
  end;
end;
{$ENDREGION}

{$REGION 'TCustomGraph ----- Y'}

procedure TCustomGraph.SetMirror(const Value: Boolean);
const
  CSB: array[Boolean] of TYScrollBarClass = (TYScrollBar, TMirrorYScrollBar);
begin
  if FMirror <> Value then
  begin
    FMirror := Value;
    FYScrollBar.Free;
    FYScrollBar := CSB[FMirror].Create(Self);
    FYScrollBar.Position := FYScrollBar.Position - FYScrollBar.Page;
    FYScrollBar.SetGraphYScreen;
    S_PropertyChanged := 'YMirror';
  end;
end;

procedure TCustomGraph.SetPropertyChanged(const Value: string);
begin
  FPropertyChanged := Value;
  TBindings.Notify(Self, 'S_PropertyChanged');
end;

procedure TCustomGraph.ChekYPosition;
begin
  if FYPosition < FYFrom then
    FYPosition := FYFrom
  else if FYPosition > YLast then
    FYPosition := YLast;
end;

procedure TCustomGraph.SetYFrom(const Value: Double);
begin
  if FYFromType <> yfmUser then
    Exit;
  if (FYFrom <> Value) or (FYFrom < FYFirstAvail) or (FYFrom > FYLastAvail) then
  begin
    FYFrom := Value;
    if FYFrom < FYFirstAvail then
      FYFrom := FYFirstAvail
    else if FYFrom > FYLastAvail then
      FYFrom := FYLastAvail;
    if YLast > YLastAvail then
      YLast := YLastAvail;
    ChekYPosition;
    FYScrollBar.Update;
    FYScrollBar.SetGraphYScreen;
    S_PropertyChanged := 'YFrom';
  end;
end;

procedure TCustomGraph.UpdateAvalableRangeY;
begin
  case FYFromType of
    yfmUser:
      begin
        if FYFrom < FYFirstAvail then
          FYFrom := FYFirstAvail;
        if YLast > YLastAvail then
          YLast := YLastAvail;
      end;
    yfmFirst:
      begin
        FYFrom := FYFirstAvail;
        if FYRange > YRangeAvail then
          FYRange := YRangeAvail;
      end;
    yfmLast:
      begin
        if FYRange > YRangeAvail then
          FYRange := YRangeAvail;
        FYFrom := FYLastAvail - FYRange;
      end;
    yfmALL:
      begin
        FYFrom := FYFirstAvail;
        FYRange := YRangeAvail;
      end;
  end;
end;

procedure TCustomGraph.SetYFromType(const Value: TYFrom);
begin
  if FYFromType <> Value then
  begin
    FYFromType := Value;
    UpdateAvalableRangeY;
    ChekYPosition;
    FYScrollBar.Update;
    FYScrollBar.SetGraphYScreen;
    S_PropertyChanged := 'YFromType';
  end;
end;

procedure TCustomGraph.SetYLast(const Value: Double);
begin
  if (YLast <> Value) or (YLast > YLastAvail) then
  begin
    FYRange := Value - FYFrom;
    if YLast > YLastAvail then
      FYRange := YLastAvail - FYFrom;
    if FYRange < 0 then
      FYRange := 0;
    FYScrollBar.Update;
    FYScrollBar.SetGraphYScreen;
    S_PropertyChanged := 'YLast';
  end;
end;

procedure TCustomGraph.SetYPosition(const Value: Double);
begin
  if (FYPosition <> Value) or (FYPosition < FYFrom) or (FYPosition > YLast) then
  begin
    FYPosition := Value;
    ChekYPosition;
    FYScrollBar.UpdatePosition;
    FYScrollBar.SetGraphYScreen;
    S_PropertyChanged := 'YPosition';
  end;
end;

procedure TCustomGraph.SetYScale(const Value: Double);
begin
  if (FYScale <> Value) and (FYScale > 0) then
  begin
    FYScale := Value;
    ChekYPosition;
    FYScrollBar.Update;
    FYScrollBar.SetGraphYScreen;
    S_PropertyChanged := 'YScale';
  end;
end;

function TCustomGraph.TryHitRegion(c: TGraphColmn; r: TGraphRow; out Reg: TGraphRegion): Boolean;
begin
  Reg := HitRegion(c, r);
  Result := Assigned(Reg);
end;

function TCustomGraph.TryHitRegion(pos: TPoint; out Reg: TGraphRegion): Boolean;
begin
  Reg := HitRegion(pos);
  Result := Assigned(Reg);
end;

procedure TCustomGraph.SetYRange(const Value: Double);
begin
  if Value <= 0 then
    Exit;
  case FYFromType of
    yfmUser, yfmFirst:
      if (FYRange <> Value) or (YLast > YLastAvail) then
      begin
        FYRange := Value;
        if YLast > YLastAvail then
          YLast := YLastAvail;
        ChekYPosition;
        FYScrollBar.Update;
        FYScrollBar.SetGraphYScreen;
        S_PropertyChanged := 'YRange';
      end;
    yfmLast:
      if (FYRange <> Value) or (YLast > YLastAvail) then
      begin
        FYRange := Value;
        FYFrom := YLastAvail - FYRange;
        if FYFrom < FYFirstAvail then
        begin
          FYFrom := FYFirstAvail;
          FYRange := YRangeAvail;
        end;
        ChekYPosition;
        FYScrollBar.Update;
        FYScrollBar.SetGraphYScreen;
        S_PropertyChanged := 'YRange';
      end;
    yfmALL:
      if (FYRange <> YRangeAvail) or (FYFrom <> FYFirstAvail) then
      begin
        FYFrom := FYFirstAvail;
        FYRange := YRangeAvail;
        ChekYPosition;
        FYScrollBar.Update;
        FYScrollBar.SetGraphYScreen;
        S_PropertyChanged := 'YRange';
      end;
  end;

end;

function TCustomGraph.GetYLast: Double;
begin
  Result := FYFrom + FYRange;
end;

function TCustomGraph.GetYRangeAvail: Double;
begin
  Result := YLastAvail - YFirstAvail;
end;

function TCustomGraph.GetActiveData: boolean;
begin
  if YMirror then Result := YLastAvail <= YTopScreen
  else Result := YLastAvail <= YButtomScreen
end;

function TCustomGraph.GetDefaultYAxis: TAxisY;
begin
  Result := axyID;
end;

{$ENDREGION}

{ TCustomGraphLegendRow }

function TCustomGraphLegendRow.GetCaption: string;
begin
{$IFDEF ENG_VERSION}
  Result := 'Legend'
{$ELSE}
  Result := 'Легенда'
{$ENDIF}
end;

{ TCustomGraphInfoRow }

function TCustomGraphInfoRow.GetCaption: string;
begin
{$IFDEF ENG_VERSION}
  Result := 'Information'
{$ELSE}
  Result := 'Информация'
{$ENDIF}
end;

{ TCustomGraphDataRow }

function TCustomGraphDataRow.GetCaption: string;
begin
{$IFDEF ENG_VERSION}
  Result := 'Diagram'
{$ELSE}
  Result := 'Графики'
{$ENDIF}
end;

{ TGraphRegions }

function TGraphRegions.GetCaption: string;
begin
{$IFDEF ENG_VERSION}
  Result := 'Areas Columns'
{$ELSE}
  Result := 'Области Колонки'
{$ENDIF}
end;


initialization
  RegisterClasses([TCustomGraphLegendRow, TCustomGraphDataRow, TCustomGraphInfoRow]);
  RegisterClasses([TGraph, TGraphRegion, TGraphColmn, TGraphRow]);
  RegisterClasses([TDataSetFactory, TCustomDataLink, TGraphPar, TLineParam, TWaveParam, TWaveletFilter]);
  TCustomStyleEngine.RegisterStyleHook(TCustomGraph, TScrollingStyleHook);

finalization
  TCustomStyleEngine.UnRegisterStyleHook(TCustomGraph, TScrollingStyleHook);

end.


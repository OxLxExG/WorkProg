unit RootImpl;

interface

uses
     debug_except, Container, RootIntf, PluginAPI, ExtendIntf, Vcl.Buttons,

     Vcl.Controls, Vcl.Graphics, Vcl.ComCtrls, Winapi.Messages, Vcl.Forms, Winapi.Windows, JvInspector, System.SyncObjs,

     System.Classes, System.SysUtils, System.TypInfo, System.Threading,
     System.Generics.Defaults,
     System.Generics.Collections,
     System.Bindings.Expression,
     System.Bindings.EvalProtocol,
     System.Bindings.Helper,
     System.Bindings.Outputs,
     RTTI;

const
  PRIORITY_NoStore    = -1;
  PRIORITY_IComponent = 50;
  PRIORITY_IForm      = 200;

type

{$REGION 'Вспомогательные классы'}

 TCNavigator = class(TBaseNavigator)
 public
    constructor Create(AOwner: TComponent); override;
  published
//    property DataSource;
//    property VisibleButtons;
    property Align;
    property Anchors;
    property Constraints;
    property DragCursor;
    property DragKind;
    property DragMode;
    property Enabled;
    property Flat;
    property Ctl3D;
//    property Hints;
    property Orientation;
    property ParentCtl3D;
    property ParentShowHint;
    property PopupMenu;
    property ConfirmDelete;
    property ShowHint;
    property TabOrder;
    property TabStop;
    property Visible;
//    property BeforeAction;
    property OnClick;
    property OnContextPopup;
    property OnDblClick;
    property OnDragDrop;
    property OnDragOver;
    property OnEndDock;
    property OnEndDrag;
    property OnEnter;
    property OnExit;
    property OnResize;
    property OnStartDock;
    property OnStartDrag;
 end;

  // корневые объекты плугинов
  TICollectionItem = class(TCollectionItem, IInterface)
  protected
  //IInterface
    function QueryInterface(const IID: TGUID; out Obj): HResult; stdcall;
    function _AddRef: Integer; stdcall;
    function _Release: Integer; stdcall;
  public
    function SafeCallException(ExceptObject: TObject; ExceptAddr: Pointer): HResult; override;
//    constructor Create; reintroduce; virtual;
  end;

  TICollectionItemClass = class of TICollectionItem;

  TICollection = class(TCollection, IInterface, ICaption)
  protected
    procedure ReadItems(Reader: TReader); virtual;
    procedure WriteItems(Writer: TWriter); virtual;
  //IInterface
    function QueryInterface(const IID: TGUID; out Obj): HResult; stdcall;
    function _AddRef: Integer; stdcall;
    function _Release: Integer; stdcall;
  // ICaption
    function GetCaption: string; virtual;
    procedure SetCaption(const Value: string);
  public
//    constructor Create; virtual;
//    function Add<T: TICollectionItem, constructor>: T; reintroduce; overload;
//    function Add(const ItemClassName: string): TICollectionItem; reintroduce; overload;
    procedure RegisterProperty(Filer: TFiler; const PropName: string);
    function SafeCallException(ExceptObject: TObject; ExceptAddr: Pointer): HResult; override;
  end;

  TICustomControl = class(TCustomControl)
  public
    function SafeCallException(ExceptObject: TObject; ExceptAddr: Pointer): HResult; override;
  end;

  TIObject = class(TInterfacedObject)
  public
    function SafeCallException(ExceptObject: TObject; ExceptAddr: Pointer): HResult; override;
  end;

  TAggObject = class(TAggregatedObject)
  public
    function SafeCallException(ExceptObject: TObject; ExceptAddr: Pointer): HResult; override;
  end;

/// <summary>
/// не всегда идет связывание объектов
/// </summary>
  TBindObjWrap = record
    obj: TPersistent;
    class operator Implicit(d: TPersistent): TBindObjWrap;
    class operator Implicit(d: TBindObjWrap): TPersistent;
  end;
//  новый стиль
  TBindHelper = class
  private
    class function IsOutput(Obj: TObject; Expr: TBindingExpression): boolean;
    class function IsInput(Obj: TObject; Expr: TBindingExpression): boolean;
  public
    class procedure Bind(Control: TObject; const ControlExprStr: string; Source: IInterface; const SourceExpr: array of string);
//    class function GetControlExpressions(Obj: TObject; const PropertyName: string): TList<TBindingExpression>; overload;
//    class function GetControlExpressions(Obj: TObject): TList<TBindingExpression>; overload;
//    class function GetSourceExpressions(Obj: TObject; const PropertyName: string): TList<TBindingExpression>; overload;
//    class function GetSourceExpressions(Obj: TObject): TList<TBindingExpression>; overload;
    class procedure RemoveSourceExpressions(Obj: TObject; const Expr: array of string);
    class procedure RemoveControlExpressions(Obj: TObject; const Expr: array of string);
    class procedure RemoveExpressions(Obj: TObject);
  end;

  TCPageControl = class(TPageControl)
  public
    procedure GetChildren(Proc: TGetChildProc; Root: TComponent); override;
  end;
  TCTabSheet = class(TTabSheet)
  public
    procedure GetChildren(Proc: TGetChildProc; Root: TComponent); override;
  end;

{$ENDREGION}

 { EnumCaptionsAttribute = class;
  TJvInspectorEnumCaptionsItem = class(TJvInspectorEnumItem)
  private
    FCaptions: TArray<string>;
  protected
    function GetDisplayValue: string; override;
    procedure GetValueList(const Strings: TStrings); override;
    procedure SetDisplayValue(const Value: string); override;
  public
    constructor Create(const AParent: TJvCustomInspectorItem; const AData: TJvCustomInspectorData); override;
  end;

  TJvInspectorPropDataEx = class(TJvInspectorPropData)
    class function ItemRegister: TJvInspectorRegister; override;
  end;

  EnumCaptionsAttribute = class (TCustomAttribute)
  private
    FCaptions: TArray<string>;
  public
    constructor Create(const ACaptions: string);
    property Captions: TArray<string> read FCaptions;
  end;}

{  ShowPropAttribute = class (TCustomAttribute)
  private
    FDisplayName: string;
    FReadOnly: Boolean;
    class var RttiContext : TRttiContext;
    class function StrObj2Str(const s: string): string;
    class procedure ApplyItem(root: TJvCustomInspectorItem; o: TObject); static;
    class procedure ApplyItemArray(root: TJvCustomInspectorItem; o: TArray<TObject>); static;
    class procedure ApplyICollection(root: TJvCustomInspectorItem; cl: TICollection); static;
  public
   constructor Create(const ADisplayName: String; AReadOnly: Boolean = False);
   class procedure Apply(Obj: TObject; Insp: TJvInspector); overload;
   class procedure Apply(Obj: TArray<TObject>; Insp: TJvInspector); overload;
   property DisplayName: string read FDisplayName write FDisplayName;
   property ReadOnly: Boolean read FReadOnly write FReadOnly;
  end;}


{$REGION 'TIComponent TIForm'}
  //  основные классы для построения всего
  //       TIComponent TIForm
  //  ведут себя как интерфейсы поддерживают Livebinding

  TIComponent = class(TComponent, IInterface{!!!!!! иначе _AddRef _Release будут иногда старые}, IManagItem, IBind)
  private
    FRefCount: Integer;
    FWeekContainerReference: Boolean;
    FNillWeekReference: Boolean;
  protected
    FIsBindInit: Boolean;
    FPriority: Integer;
    function QueryInterface(const IID: TGUID; out Obj): HResult; override; stdcall;
    function _AddRef: Integer; reintroduce; stdcall;
    function _Release: Integer; reintroduce; stdcall;

  // IManagItem
    function Priority: Integer;
    function Model: ModelType;
    function GetItemName: String; virtual;
    function RootName: String;
    procedure SetItemName(const Value: String); virtual;
    // IBind
    procedure _EnableNotify;
    procedure Bind(const ControlExprStr: string; Source: IInterface; const SourceExpr: array of string); overload;
    procedure Bind(Control: IInterface; const ControlExprStr: string; const SourceExpr: array of string); overload;
    property IName: String read GetItemName write SetItemName;
   public
    procedure PubChange; inline;
    ///	<summary>
    ///	  В стиле Spring конструктор без параметров
    ///	</summary>
    constructor Create; reintroduce; virtual;
    destructor Destroy; override;
    class function NewInstance: TObject; override;
    procedure AfterConstruction; override;

    function SafeCallException(ExceptObject: TObject; ExceptAddr: Pointer): HResult; override;

    procedure Notify(const Prop: string);
    ///	<summary>
    ///	  для автосохранения данных сохраняемые published свойства  при
    ///	  изменении должны вызывать PubChange
    ///	</summary>
    property S_PublishedChanged: string read GetItemName write SetItemName;
/// <summary>
///   После добавления экземпляра в общее хранилище ltSingletonNamed
///  если WeekContainerReference = ДА, то если осталась тольо ссылка в контейнере то удаляем из контейнера
/// </summary>
/// <remarks>
///  Включать WeekContainerReference только после добавления В глобальный контейнер
///  IEnumXXX.ADD IEnumXXX.REMOVE Isaver - не использовать
/// </remarks>
    property WeekContainerReference: Boolean read FWeekContainerReference write FWeekContainerReference;
/// <summary>
///  если WeekContainerReference = ДА NillWeekReference = ДА,
///  если осталась одна ссылка в контейнере удаляем ТОЛЬКО ссылку из контейнера
///  но не Текст объекта (published могут быть загружены )
/// </summary>
    property NillWeekReference: Boolean read FNillWeekReference write FNillWeekReference;
  end;
  TIComponentClass = class of TIComponent;

  TIForm = class(TForm, IInterface{!!!!!!}, IManagItem, IForm, ICaption{, IBind})
  private
    FRefCount: Integer;
    FIcon: Integer;
    procedure SetIcon(const Value: Integer);
  protected
    function QueryInterface(const IID: TGUID; out Obj): HResult; override; stdcall;
    function _AddRef: Integer; reintroduce; stdcall;
    function _Release: Integer; reintroduce; stdcall;
  // IManagItem
    function Priority: Integer; virtual;
    function Model: ModelType;
    function GetItemName: String;
    function RootName: String;
    procedure SetItemName(const Value: String);
    // IFORM
    procedure IForm.Show = IShow; procedure IShow; virtual;
//    procedure InitializeNewForm; override;

    function GetCaption: string;
    procedure SetCaption(const Value: string);

    procedure Bind(const ControlExprStr: string; Source: IInterface; const SourceExpr: array of string); overload;
    procedure Bind(Control: IInterface; const ControlExprStr: string; const SourceExpr: array of string); overload;
  public
    ///	<summary>
    ///	  В стиле Spring конструктор без параметров
    ///	</summary>
    constructor Create; reintroduce; virtual;
    constructor CreateUser(const aName: string =''); virtual;
    destructor Destroy; override;
    procedure AfterConstruction; override;
    procedure GetChildren(Proc: TGetChildProc; Root: TComponent); override;
    function CreateUnLoad<T: TComponent>():T;
    class function NewInstance: TObject; override;
    class function NewForm(Model: ModelType; const Name: string = ''): IForm;
    function SafeCallException(ExceptObject: TObject; ExceptAddr: Pointer): HResult; override;
    class var DoDestroyApp: Boolean;
  published
    property Icon: Integer read FIcon write SetIcon;
  end;
  TIFormClass = class of TIForm;
{$ENDREGION}

  ///
  /// сериализация наследников пример в IdataSets
  ///
  TFactoryPersistent<ROOT: TInterfacedPersistent> = class(TInterfacedPersistent)
  private
    function GetClass: string;
    procedure SetClass(const Value: string);
  protected
    FStored: ROOT;
    procedure SetROOT(const Value: ROOT);
    function GetROOT: ROOT;
  public
    constructor CreateUser(AStored: ROOT);
    destructor Destroy; override;
  published
  // при загрузке создаем в SetClass StoredItem наследника ROOT по имени класса
    property StoredClass: string read GetClass write SetClass;
  // затем загружаем published значения StoredItem
//    property [StoredItem]<в наследнике создаем удобное для себя имя>: ROOT read FStored write SetROOT;
  end;

{$REGION 'абстрактное хранилище однообразных основных элементов'}

  TManagItemComparer = class(TComparer<IManagItem>)
    function Compare(const Left, Right: IManagItem): Integer; override;
  end;

  TManagItemComparer<T: IInterface> = class(TComparer<T>)
    function Compare(const Left, Right: T): Integer; override;
  end;

  EServiceManager = class(EBaseException);
  // фактически обертка Container
  TRootServiceManager<T: IManagItem> = class(TIComponent, IServiceManagerType, IStorable, IServiceManager, IServiceManager<T>)
  private
    FBindAdd: string;
    FBindRemove: string;
    FLastChangedName: string;
  protected
    class function SupportPublishedChanged: Boolean; virtual;
    procedure SetItemChanged(const Value: string); virtual;
    procedure DoBeforeAdd(mi: IManagItem); virtual;
    procedure DoAfterAdd(mi: IManagItem); virtual;
    procedure DoBeforeRemove(mi: IManagItem; const name: string); virtual;
    procedure DoAfterRemove(mi: IManagItem); virtual;
    function DoBeforeClear(mi: IManagItem): Boolean; virtual;
  //IServiceManager
    procedure Add(const Item: IManagItem);
    procedure Remove(model: ModelType; const Item: string); overload;
    procedure Remove(const Item: string); overload;
    procedure Remove(const Item: IManagItem); overload;
    function GetManagItem(model: ModelType; const ItemName: string; Initialize: Boolean = True): IManagItem; overload;
    function GetManagItem(const ItemName: string; Initialize: Boolean = True): IManagItem; overload;
    function GetService: ServiceType;
    procedure Clear();
  // IServiceManager<T>
    function GetEnumerator: TEnumerator<T>;
    type
     TEnumEnumerable<ET> = class(TEnumerable<ET>)
     protected
       FEnumerator: TEnumerator<ET>;
       function DoGetEnumerator: TEnumerator<ET>; override;
     end;
    function Enum(Initialize: Boolean = True): TEnumerable<T>; // с инициализацией
    function AsArrayRec: TArray<TInstanceRec<T>>;
    function Get(const ItemName: string; Initialize: Boolean = True): T; overload;
    function Get(model: ModelType; const ItemName: string; Initialize: Boolean = True): T; overload;
    // Storable
    // т.к. возможна отложенная загрузка объектов то они сами информируют о своем создании в процедуре Loaded
    procedure ItemInitialized(mi: IManagItem); virtual;
//    procedure DoBeforeLoad(mi: IManagItem); virtual; устарело
//    procedure DoAfterLoad(mi: IManagItem); virtual;  устарело
    procedure DoBeforeSave(mi: IManagItem); virtual;
    procedure DoAfterSave(mi: IManagItem); virtual;

    procedure DoLoadItem(const mit: string; Prior: Integer = 1000);
    // IStorable
    procedure New; virtual;
    procedure Save; virtual;
    procedure Load; virtual;
  public
    property S_BeforeAdd: string read FBindAdd write FBindAdd;
    property S_AfterAdd: string read FBindAdd write FBindAdd;
    property S_BeforeRemove: string read FBindRemove write FBindRemove;
    property S_AfterRemove: string read FBindRemove write FBindRemove;
    property C_PublishedChanged: string read FLastChangedName write SetItemChanged;
  end;

{$ENDREGION}

  TRegistryStorable<T: IManagItem> = class(TInterfacedObject, IStorable)
  public
   type
    TOnSaveFunc = reference to function(const InData: string): string;
  private
    FPath: string;
    FOwner: TRootServiceManager<T>;
    Ffunc: TOnSaveFunc;
  protected
    function GetService: ServiceType;
    procedure New;
    procedure Save;
    procedure Load;
  public
    constructor Create(AOwner: TRootServiceManager<T>; const Path: string; func: TOnSaveFunc = nil);
  end;

  RegisterDialog = class
  private
   type
     TDialogData = record
      DialogID: PTypeInfo;
      Description, Categoty: string;
    end;                         // класс   категория
    class var FItems: TDictionary<PTypeInfo, TDialogData>;
    class constructor Create;
    class destructor Destroy;
  public
    class procedure Add<T: class; D: IInterface>(const Category: string = ''; const Description: string = '');
    class procedure Remove<T: class>;
    class function Support<D: IInterface>: Boolean;
    class function TryGet<D: IInterface>(out Dialog: IDialog): Boolean; overload;
    class function TryGet(const Category, Description: string; out Dialog: IDialog): Boolean; overload;
    class procedure UnInitialize<D: IInterface>; overload;
    class procedure UnInitialize(D: PTypeInfo); overload;
    class procedure UnInitialize(const Category, Description: string); overload;
    class function CategoryDescriptions(const Category: string): TArray<string>;
  end;

  GTask = class
  private
    class var FTasks: TArray<ITask>;
    class var FLock: TObject;
    class var FRemovin: Boolean;
    class constructor Create;
    class destructor Destroy;
   public
    class procedure WaitForAll; static;
    class procedure Remove(task: ITask); static;
    class function Get(const Func: TProc): ITask; static;
    class function Run(const Func: TProc): ITask; static;
    class procedure SetRemove; static;
    class property IsRemove: Boolean read FRemovin;
  end;

  TStatisticCreate = class(TIObject, IStatistic)
  private
    FCount: UInt64;
    FTimeBegin: TDateTime;
    FStatistic: TStatistic;
    function GetStatistic: TStatistic;
    procedure UpdateAll(cnt: UInt64);
    procedure UpdateAdd(cnt: Cardinal);
    property Statistic: TStatistic read GetStatistic;
  public
    constructor Create(Count: UInt64);
    class procedure UpdateStandardStatusBar(sb: TStatusBar; Stat: TStatistic);
  end;
{  GDIPlus = class
  private
    class var Flock: TCriticalSection;
    class constructor Create;
    class destructor Destrroy;
  public
    class procedure Lock; static;
    class procedure UnLock; static;
  end;}

procedure MainScreenChanged; inline;

implementation

uses tools, System.Bindings.Factories, System.Bindings.Graph, System.Bindings.Manager;

procedure MainScreenChanged;
begin
  (GContainer as IMainScreen).Changed;
end;

{$REGION 'FormEnum'}

type
 TFormEnum = class(TRootServiceManager<IForm>, IFormEnum{, INoti f yAfteActionManagerLoad})
  private
    class function RemoveProp(const txt: string): string; static;
 protected
   const IFORMS_INI_DIR = 'IFormObjs';
//   procedure AfteActionManagerLoad();
   procedure Save(); override;
   procedure Load(); override;
 end;

{ TFormEnum }

class function TFormEnum.RemoveProp(const txt: string): string;
 const
  FRM: array of string = ['Tag', 'Left', 'Top', 'Align', 'ActiveControl', 'BorderStyle',
  'ClientHeight',  'ClientWidth',  'DockSite',  'DragMode', 'DragKind', {'Font.Charset',
  'Font.Color',  'Font.Height',
  {'Font.Name',  'Font.Style',}  'Position',
  'ExplicitLeft',  'ExplicitTop',  'ExplicitWidth',  'ExplicitHeight', 'PixelsPerInch', 'TextHeight'];
  OBJ: array[0..3] of string = ('FormMain.ImageList','NodeDataSize', 'RootNodeCount', 'TabOrder');
 var
  ss: TStringList;
  dd: string;
  i, tof: Integer;
begin
  ss := TStringList.Create;
  ss.Text := txt;
  try
   tof := 0;
  // Выкидываем ненужные
   for dd in FRM do
       for i := 1 to ss.Count-1 do
           if (Pos('object',ss[i]) > 0) then
            begin
             tof := i+1;
             Break;
            end
           else if Pos(dd, ss[i])>0 then
            begin
             ss.Delete(i);
             Break;
            end;

    for i := ss.Count-1 downto tof do
        for dd in OBJ do
            if Pos(dd, ss[i])>0 then
               begin
                ss.Delete(i);
                Break;
               end;


  // скрываем при загрузке докформы
//   for i := 1 to ss.Count-1 do
//    if (Pos('object',ss[i]) > 0) then Break
//    else if (Pos('Visible',ss[i]) > 0) then
//     begin
//      ss[i] := '  Visible = False';
//      Break
//     end;
   Result := ss.Text;
  finally
   ss.Free;
  end;
end;

//procedure TFormEnum.AfteActionManagerLoad;
// var
//  i: IForm;
//  ml: INotifyAfteActionMan ag erLoad;
//  a: TArray<IForm>;
//begin
//  a := GContainer.InstancesAsArray<IForm>(true);
//  TArray.Sort<IForm>(a, TManagItemComparer<IForm>.Create);
//  for i in a do if Supports(i, INotifyA fteAc tionManagerLoad, ml) then ml.AfteActionManagerLoad();
//end;

procedure TFormEnum.Load;
begin
  (TRegistryStorable<IForm>.Create(Self, IFORMS_INI_DIR) as IStorable).Load;
end;

procedure TFormEnum.Save;
begin
  (TRegistryStorable<IForm>.Create(Self, IFORMS_INI_DIR, function(const s: string): String
  begin
    Result := RemoveProp(s)
  end) as IStorable).Save;
end;

{$ENDREGION}

{$REGION 'Helper'}

{ TBindHelper }

class procedure TBindHelper.Bind(Control: TObject; const ControlExprStr: string; Source: IInterface; const SourceExpr: array of string);
 var
  c: TObject;
  s: string;
  b: IBind;
begin
//  c := (Source as IInterfaceComponentReference).GetComponent;
  c := TObject(Source);
  if Supports(Source, IBind, b) then b._EnableNotify;
  for s in SourceExpr do
   TBindings.CreateManagedBinding(
      [TBindings.CreateAssociationScope([Associate(c, 'Source')])], 'Source.' + s,
      [TBindings.CreateAssociationScope([Associate(Control, 'res')])], 'res.' + ControlExprStr,
      nil);
end;

class function TBindHelper.IsInput(Obj: TObject; Expr: TBindingExpression): boolean;
 var
  s: IScopeEx;
begin
  Result := Supports(Expr, IScopeEx, s) and Assigned(s.Lookup(Obj));
end;

class function TBindHelper.IsOutput(Obj: TObject; Expr: TBindingExpression): boolean;
 var
  p: TBindingOutput.TOutputPair;
begin
  Result := False;
  for p in Expr.Outputs.Destinations.Values do if p.Key = Obj then Exit(True)
end;

class procedure TBindHelper.RemoveExpressions(Obj: TObject);
 var
  Manager: TBindingManager;
  i: integer;
begin
   Manager := TBindingManagerFactory.AppManager;
   for i := Manager.ExprCount-1 downto 0 do
    if IsInput(Obj, Manager.Expressions[i]) or IsOutput(Obj, Manager.Expressions[i]) then Manager.Remove(Manager.Expressions[i]);
end;

class procedure TBindHelper.RemoveControlExpressions(Obj: TObject; const Expr: array of string);
 var
  s: string;
  Manager: TBindingManager;
  i: integer;
begin
//  try
   Manager := TBindingManagerFactory.AppManager;
   for i := Manager.ExprCount-1 downto 0 do
    for s in Expr do if TBindingGraph.IsOutput(Obj, s, Manager.Expressions[i]) then
     begin
      Manager.Remove(Manager.Expressions[i]);
      Break;
     end;
//  except
//    on E: Exception do TDebug.DoException(E);
//  end;
end;

class procedure TBindHelper.RemoveSourceExpressions(Obj: TObject; const Expr: array of string);
 var
  s: string;
  Manager: TBindingManager;
  i: integer;
begin
//  try
   Manager := TBindingManagerFactory.AppManager;
   for i := Manager.ExprCount-1 downto 0 do
    for s in Expr do if TBindingGraph.IsInput(Obj, s, Manager.Expressions[i]) then
     begin
      Manager.Remove(Manager.Expressions[i]);
      Break;
     end;
//  except
//    on E: Exception do TDebug.DoException(E);
//  end;
end;

{class function TBindHelper.GetControlExpressions(Obj: TObject; const PropertyName: string): TList<TBindingExpression>;
 var
  Manager: TBindingManager;
  i: integer;
begin
  Manager := TBindingManagerFactory.AppManager;
  Result := TList<TBindingExpression>.Create;
  for i := 0 to Manager.ExprCount-1 do
   if TBindingGraph.IsOutput(Obj, PropertyName, Manager.Expressions[i]) then Result.Add(Manager.Expressions[i])
end;

class function TBindHelper.GetControlExpressions(Obj: TObject): TList<TBindingExpression>;
 var
  Manager: TBindingManager;
  i: integer;
begin
  Manager := TBindingManagerFactory.AppManager;
  Result := TList<TBindingExpression>.Create;
  for i := 0 to Manager.ExprCount-1 do
   if IsOutput(Obj, Manager.Expressions[i]) then Result.Add(Manager.Expressions[i])
end;

class function TBindHelper.GetSourceExpressions(Obj: TObject; const PropertyName: string): TList<TBindingExpression>;
begin
  Result := TBindingGraph.GetDependentExprs(Obj, PropertyName, nil);
end;

class function TBindHelper.GetSourceExpressions(Obj: TObject): TList<TBindingExpression>;
begin
  Result := TBindingGraph.GetDependentExprs(Obj, '', nil);
end;  }

{ TIntegerHelper }

//function TIntegerHelper.ToStr: string;
//begin
//  Result := IntToStr(Self);
//end;

{ TStringHelper }

{function TStringHelper.ToInt: Integer;
begin
  Result := StrToInt(Self);
end;}

{ TIObject }

function TIObject.SafeCallException(ExceptObject: TObject; ExceptAddr: Pointer): HResult;
begin
  Result := TDebug.HandleSafeCallException(Self, ExceptObject, ExceptAddr);
end;

{ TAggObject }

function TAggObject.SafeCallException(ExceptObject: TObject; ExceptAddr: Pointer): HResult;
begin
  Result := TDebug.HandleSafeCallException(Self, ExceptObject, ExceptAddr);
end;

{$ENDREGION}

{$REGION 'TIComponent'}

{ TIComponent }

procedure TIComponent.AfterConstruction;
begin
  inherited;
  AtomicDecrement(FRefCount);
end;

constructor TIComponent.Create;
 var
  i: Integer;
begin
  inherited Create(nil);
  FPriority := PRIORITY_IComponent;
  i:= 1;
  while GContainer.Contains(RootName + i.ToString()) do Inc(i);
  Name := RootName + i.ToString;// FormatDateTime('yymdhnsz', now);
end;

destructor TIComponent.Destroy;
begin
  TBindHelper.RemoveExpressions(Self);
  TDebug.Log('  TIComponent.Destroy  %s  ', [Name]);
  inherited;
end;

function TIComponent.GetItemName: String;
begin
  Result := Name;
end;

function TIComponent.Model: ModelType;
begin
  Result := ClassInfo;
end;

procedure TIComponent.SetItemName(const Value: String);
begin
  Name := Value;
end;

class function TIComponent.NewInstance: TObject;
begin
  Result := inherited NewInstance;
  TIComponent(Result).FRefCount := 1;
end;

procedure TIComponent.Bind(const ControlExprStr: string; Source: IInterface; const SourceExpr: array of string);
begin
  TBindHelper.Bind(Self, ControlExprStr, Source, SourceExpr);
end;

procedure TIComponent.Bind(Control: IInterface; const ControlExprStr: string; const SourceExpr: array of string);
begin
  TBindHelper.Bind((Control as IInterfaceComponentReference).GetComponent, ControlExprStr, Self, SourceExpr);
end;

procedure TIComponent._EnableNotify;
begin
  FIsBindInit := True;
end;

procedure TIComponent.Notify(const Prop: string);
begin
  if not (csLoading in ComponentState) and FIsBindInit then TBindings.Notify(Self, Prop);
end;

function TIComponent.Priority: Integer;
begin
  Result := FPriority;
end;

procedure TIComponent.PubChange;
begin
  Notify('S_PublishedChanged');
end;

function TIComponent.QueryInterface(const IID: TGUID; out Obj): HResult;
begin
  Result := E_NOINTERFACE;
  if GetInterface(IID, Obj) then Exit(S_OK)
end;

function TIComponent.RootName: String;
begin
  if ClassName.Contains('<') then Result := ClassName.Substring(0, ClassName.IndexOf('<'))
  else Result := ClassName;
  Delete(Result, 1, 1);
end;

function TIComponent.SafeCallException(ExceptObject: TObject; ExceptAddr: Pointer): HResult;
begin
  Result := TDebug.HandleSafeCallException(Self, ExceptObject, ExceptAddr);
end;

function TIComponent._AddRef: Integer;
begin
  Result := AtomicIncrement(FRefCount);
end;

function TIComponent._Release: Integer;
begin
  Result := AtomicDecrement(FRefCount);
  if WeekContainerReference and (Result = 1) then
   begin
    if NillWeekReference then GContainer.NillInstance(Model, IName)
    else GContainer.RemoveInstance(Model, IName);
   end
  else if Result = 0 then Destroy;
end;

{$ENDREGION}

{$REGION 'TIForm'}

{ TIForm }

constructor TIForm.Create;
begin
  CreateNew(nil);
end;

constructor TIForm.CreateUser(const aName: string ='');
begin
  inherited Create(nil);
  if aName ='' then Name := RootName + FormatDateTime('yymdhnsz', now)
  else Name := aName;
end;

destructor TIForm.Destroy;
begin
  TBindHelper.RemoveExpressions(Self);
  TDebug.Log('  TIForm.Destroy  %s  ', [Caption]);
  inherited;
end;

procedure TIForm.AfterConstruction;
begin
  inherited;
  AtomicDecrement(FRefCount);
end;

function TIForm.GetCaption: string;
begin
  Result := Caption;
end;

procedure TIForm.GetChildren(Proc: TGetChildProc; Root: TComponent);
var
  I: Integer;
  OwnedComponent: TComponent;
  Control: TControl;
begin
  for I := 0 to ControlCount - 1 do
  begin
    Control := Controls[I];
    if (Control.Owner = Root) and (Control.Tag <> $12345678) then Proc(Control);
  end;
  if Root = Self then
    for I := 0 to ComponentCount - 1 do
    begin
      OwnedComponent := Components[I];
      if not OwnedComponent.HasParent and (OwnedComponent.Tag <> $12345678) then Proc(OwnedComponent);
    end;
end;

function TIForm.GetItemName: String;
begin
  Result := Name;
end;

//procedure TIForm.InitializeNewForm;
//begin
//  inherited;
//  FPriority := PRIORITY_IForm;
//end;

procedure TIForm.IShow;
begin
  Show;
end;

function TIForm.Model: ModelType;
begin
  Result := ClassInfo;
end;

class function TIForm.NewForm(Model: ModelType; const Name: string): IForm;
 var
  method: TRttiMethod;
  InstanceType: TRttiInstanceType;
  f: TIForm;
begin
  Result := nil;
  if GContainer.TryGetModelRTTI(Model, InstanceType) then
  for method in InstanceType.GetMethods do
    if method.IsConstructor and (Length(method.GetParameters) = 1) and SameText(method.Name, 'CreateUser') then
     begin
       f := TIForm(method.Invoke(InstanceType.MetaclassType, [Name]).AsObject);
       Exit(f as IForm);
     end;
end;

class function TIForm.NewInstance: TObject;
begin
  Result := inherited NewInstance;
  TIForm(Result).FRefCount := 1;
end;

function TIForm.Priority: Integer;
begin
  Result := PRIORITY_IForm;;
end;

procedure TIForm.Bind(const ControlExprStr: string; Source: IInterface; const SourceExpr: array of string);
begin
  TBindHelper.Bind(Self, ControlExprStr, Source, SourceExpr);
end;

procedure TIForm.Bind(Control: IInterface; const ControlExprStr: string; const SourceExpr: array of string);
 var
  i: IInterfaceComponentReference;
begin
  if Supports(Control, IInterfaceComponentReference, i) then
       TBindHelper.Bind(i.GetComponent, ControlExprStr, Self, SourceExpr)
  else
       TBindHelper.Bind(TObject(Control), ControlExprStr, Self, SourceExpr)
end;

function TIForm.QueryInterface(const IID: TGUID; out Obj): HResult;
begin
  Result := E_NOINTERFACE;
  if GetInterface(IID, Obj) then Exit(S_OK)
end;

function TIForm.RootName: String;
begin
  Result := ClassName;
  Delete(Result, 1, 1);
end;

function TIForm.SafeCallException(ExceptObject: TObject; ExceptAddr: Pointer): HResult;
begin
  Result := TDebug.HandleSafeCallException(Self, ExceptObject, ExceptAddr);
end;

procedure TIForm.SetCaption(const Value: string);
begin
  Caption := Value;
end;

procedure TIForm.SetIcon(const Value: Integer);
 var
  ii: IImagProvider;
begin
  FIcon := Value;
  if Supports(GlobalCore, IImagProvider, ii) then ii.GetIcon(FIcon, inherited Icon);
end;

procedure TIForm.SetItemName(const Value: String);
begin
  Name := Value;
end;

function TIForm.CreateUnLoad<T>: T;
begin
  Result := TRttiContext.Create.GetType(TClass(T)).GetMethod('Create').Invoke(TClass(T), [Self]).AsType<T>; //через жопу работает
  Result.Tag := $12345678;
end;
function TIForm._AddRef: Integer;
begin
  Result := AtomicIncrement(FRefCount);
end;

function TIForm._Release: Integer;
begin
  Result := AtomicDecrement(FRefCount);
//  TDebug.Log('  IForm._Release  %s  %d       ', [Name, Result]);
  if Result = 0 then
   begin
    if DoDestroyApp then
      Destroy
    else
     Release;
   end;
end;
{$ENDREGION}

{$REGION 'ALL'}

{ TCTabSheet }

procedure TCTabSheet.GetChildren(Proc: TGetChildProc; Root: TComponent);
var
  I, j: Integer;
  Control, SubConttol: TControl;
begin
//  for I := 0 to ControlCount - 1 do
//  begin
//    Control := Controls[I];
//    if Control.Owner = Root then
//     begin
//      Proc(Control);
//      if Control is TForm then for j := 0 to TForm(Control).ControlCount - 1 do
//       begin
//        SubConttol := TForm(Control).Controls[j];
//        if SubConttol.Owner = Control then Proc(SubConttol);
//       end;
//     end;
//  end;
/// всё уже умеет
  inherited GetChildren(Proc, Root);
end;
{ TCPageControl }

procedure TCPageControl.GetChildren(Proc: TGetChildProc; Root: TComponent);
var
  I, j: Integer;
  Control: TControl;
  OwnedComponent: TComponent;
begin
  for I := 0 to PageCount - 1 do if Pages[I].Tag <> $12345678 then
   begin
    Proc(TComponent(Pages[I]));  // сам tabsheet
    /// у коренного элемента страницы TForm.Owner = Root- родительская форма !!!
    /// ничего ненадо !!!
{    for j := 0 to Pages[I].ControlCount - 1 do
     begin
      Control := Pages[I].Controls[j];
      if ((Control.Owner = Pages[I]) or  (Control.Owner = self))  and (Control.Tag <> $12345678) then
         Proc(Control);
     end;
    if Root = Self then
      for j := 0 to ComponentCount - 1 do
      begin
        OwnedComponent := Pages[I].Components[j];
        if not OwnedComponent.HasParent and (OwnedComponent.Tag <> $12345678) then Proc(OwnedComponent);
      end;}
   end;
end;

{ TICollectionItem }

//constructor TICollectionItem.Create;
//begin
//end;

function TICollectionItem.QueryInterface(const IID: TGUID; out Obj): HResult;
begin
  if GetInterface(IID, Obj) then Result := 0
  else Result := E_NOINTERFACE;
end;

function TICollectionItem.SafeCallException(ExceptObject: TObject; ExceptAddr: Pointer): HResult;
begin
  Result := TDebug.HandleSafeCallException(Self, ExceptObject, ExceptAddr);
end;

function TICollectionItem._AddRef: Integer;
begin
  Result := -1;
end;

function TICollectionItem._Release: Integer;
begin
  Result := -1;
end;

{ TICollection }

//function TICollection.Add(const ItemClassName: string): TICollectionItem;
//begin
//  Result := TICollectionItemClass(FindClass(ItemClassName)).Create();
//  Result.Collection := Self;
//end;

//function TICollection.Add<T>: T;
//begin
//  Result := TRttiContext.Create.GetType(TClass(T)).GetMethod('Create').Invoke(TClass(T), [Self]).AsType<T>; //через жопу работает
//end;

//function TICollection.Add<T>: T;
//begin
//  Result := T.Create();
//  Result.Collection := Self;
//end;

//constructor TICollection.Create;
//begin
//  inherited Create(TICollectionItem);
//end;

function TICollection.GetCaption: string;
begin
  Result := 'Коллекция';
end;

function TICollection.QueryInterface(const IID: TGUID; out Obj): HResult;
begin
  if GetInterface(IID, Obj) then Result := 0
  else Result := E_NOINTERFACE;
end;

type
   TmyReader = class(TReader);
   TmyWriter = class(TWriter);

procedure TICollection.ReadItems(Reader: TReader);
 var
  Item: TPersistent;
begin
  BeginUpdate;
  with TmyReader(Reader) do
   try
    if NextValue = vaCollection then ReadValue;
    if not EndOfList then Clear;
    while not EndOfList do
     begin
      if NextValue in [vaInt8, vaInt16, vaInt32] then ReadInteger;
      ReadListBegin;
      ReadStr; //'ItemClassName' - property
      Item := TCollectionItemClass(FindClass(ReadString)).Create(Self); //Add(ReadString); // - value
      while not EndOfList do
       try
        ReadProperty(Item);
       except
        on E: Exception do TDebug.DoException(E);
       end;
      ReadListEnd;
     end;
    ReadListEnd;
   finally
    EndUpdate;
   end;
end;

procedure TICollection.WriteItems(Writer: TWriter);
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
      for I := 0 to Count - 1 do
       begin
        WriteListBegin;
        WritePropName('ItemClassName');
        WriteString(Items[I].ClassName);
        WriteProperties(Items[I]);
        WriteListEnd;
       end;
     WriteListEnd;
    finally
     Ancestor := OldAncestor;
    end;
   end;
end;

procedure TICollection.RegisterProperty(Filer: TFiler; const PropName: string);
begin
  Filer.DefineProperty(PropName, ReadItems, WriteItems, True);
end;

function TICollection.SafeCallException(ExceptObject: TObject; ExceptAddr: Pointer): HResult;
begin
  Result := TDebug.HandleSafeCallException(Self, ExceptObject, ExceptAddr);
end;

procedure TICollection.SetCaption(const Value: string);
begin
end;

function TICollection._AddRef: Integer;
begin
  Result := -1;
end;

function TICollection._Release: Integer;
begin
  Result := -1;
end;

{ TICustomControl }

function TICustomControl.SafeCallException(ExceptObject: TObject; ExceptAddr: Pointer): HResult;
begin
  Result := TDebug.HandleSafeCallException(Self, ExceptObject, ExceptAddr);
end;

{ ShowPropAttribute }
{type
 TCustomInspectorDataClassName = class(TJvCustomInspectorData)
 private
   FData: string;
 protected
   function GetAsString: string; override;
  public
   function HasValue: Boolean; override;
   function IsAssigned: Boolean; override;
   function IsInitialized: Boolean; override;
   class function New(const AParent: TJvCustomInspectorItem; const Data: string; pt: PTypeInfo): TJvCustomInspectorItem;
 end;
function TCustomInspectorDataClassName.IsAssigned: Boolean;
begin
  Result := True;
end;
function TCustomInspectorDataClassName.IsInitialized: Boolean;
begin
  Result := True
end;
function TCustomInspectorDataClassName.HasValue: Boolean;
begin
  Result := True;
end;
function TCustomInspectorDataClassName.GetAsString: string;
begin
  Result := FData;
end;
class function TCustomInspectorDataClassName.New(const AParent: TJvCustomInspectorItem; const Data: string; pt: PTypeInfo): TJvCustomInspectorItem;
 var
  dat: TCustomInspectorDataClassName;
begin
  Dat := CreatePrim(Data, pt);
  Dat.FData := Data;
  Dat := TCustomInspectorDataClassName(DataRegister.Add(Dat));
  if Dat <> nil then Result := Dat.NewItem(AParent)
  else Result := nil;
end;

class function ShowPropAttribute.StrObj2Str(const s: string): string;
begin
  Result := '('+s+')';
end;

class procedure ShowPropAttribute.ApplyItem(root: TJvCustomInspectorItem; o: TObject);
 var
  t : TRttiType;
  p : TRttiProperty;
  a : TCustomAttribute;
  ii: TJvCustomInspectorItem;
  oo: TObject;
  s: string;
begin
  if not Assigned(o) then Exit;
  t := RttiContext.GetType(o.ClassType);
  for p in t.getProperties do
  for a in p.GetAttributes do
   if a is ShowPropAttribute then
     if p.PropertyType.TypeKind = tkClass then
      begin
       oo := p.GetValue(o).AsObject;
       if not Assigned(oo) then s := string(p.PropertyType.Handle.Name)
       else s := oo.ClassName;
       ii := TCustomInspectorDataClassName.New(Root, StrObj2Str(s), TypeInfo(string));
       ii.DisplayName := ShowPropAttribute(a).DisplayName;
       ii.SortKind := iskNone;
       ii.Expanded := True;
       ii.ReadOnly := True;
       if Assigned(oo) and (oo is TICollection) then ApplyICollection(ii,  TICollection(oo));
       ApplyItem(ii, oo);
      end
     else
      begin
       ii := TJvInspectorPropDataEx.New(Root, o, TRttiInstanceProperty(p).PropInfo);
       ii.DisplayName := ShowPropAttribute(a).DisplayName;
       ii.ReadOnly := ShowPropAttribute(a).ReadOnly or not p.IsWritable;
       if ii is TJvInspectorBooleanItem then
         TJvInspectorBooleanItem(ii).ShowAsCheckbox := True;
//       if ii is TJvInspectorEnumItem then
//        for e in p.PropertyType.GetAttributes do
//         if e is EnumCaptionsAttribute then
//          ii.DropDownCount
      end;
end;

class procedure ShowPropAttribute.Apply(Obj: TArray<TObject>; Insp: TJvInspector);
begin
  Insp.Clear;
  RttiContext := TRttiContext.Create;
  try
   ApplyItemArray(Insp.Root, Obj);
  finally
   RttiContext.Free;
  end;
end;

class procedure ShowPropAttribute.ApplyICollection(root: TJvCustomInspectorItem; cl: TICollection);
 var
  ii: TJvCustomInspectorItem;
  ci: TCollectionItem;
  s: string;
  ca: ICaption;
begin
  if Supports(cl, ICaption, ca) then s := ca.Text
  else s := 'Items';
  Root := TCustomInspectorDataClassName.New(Root, '', TypeInfo(string));
  Root.DisplayName := s;
  Root.SortKind := iskNone;
  Root.Expanded := True;
  Root.ReadOnly := True;
  for ci in cl do
   begin
    if Supports(ci, ICaption, ca) then s := ca.Text
    else s := 'Item';
    ii := TCustomInspectorDataClassName.New(Root, StrObj2Str(ci.ClassName), TypeInfo(string));
    ii.DisplayName := s;
    ii.SortKind := iskNone;
    ii.Expanded := True;
    ii.ReadOnly := True;
    ApplyItem(ii, ci);
   end;
end;

class procedure ShowPropAttribute.ApplyItemArray(root: TJvCustomInspectorItem; o: TArray<TObject>);
 var
  t : TRttiType;
  p : TRttiProperty;
  a : TCustomAttribute;
  ii: TJvCustomInspectorItem;
  oo, no: TObject;
  i, j: Integer;
  s: string;
  aa: TArray<TArray<ShowPropAttribute>>;
begin
  SetLength(aa, Length(o));
  for i := 0 to Length(o)-1 do if Assigned(o[i]) then
   begin
    t := RttiContext.GetType(o[i].ClassType);
     for p in t.getProperties do
      for a in p.GetAttributes do
       if (a is ShowPropAttribute) and (p.PropertyType.TypeKind <> tkClass) then
        Carray.add<ShowPropAttribute>(aa[i], ShowPropAttribute(a))
   end;
  for i := 0 to Length(o)-1 do for j := Length(o[)-1 downto Length(o)-1 do
   begin

   end;

end;

class procedure ShowPropAttribute.Apply(Obj: TObject; Insp: TJvInspector);
begin
  Insp.Clear;
  RttiContext := TRttiContext.Create;
  try
   ApplyItem(Insp.Root, Obj);
  finally
   RttiContext.Free;
  end;
end;

constructor ShowPropAttribute.Create(const ADisplayName: String; AReadOnly: Boolean);
begin
  FDisplayName := ADisplayName;
  FReadOnly := AReadOnly;
end;    }

{$ENDREGION}

{$REGION 'TRootServiceManager<T>'}

{ TManagItemComparer<T> }

function TManagItemComparer<T>.Compare(const Left, Right: T): Integer;
 var
  L,R: IManagItem;
begin
  Result := 0;
  if Supports(Left, IManagItem, L) and Supports(Right, IManagItem, R) then
   begin
    Result := L.Priority - R.Priority;
    if Result = 0 then Result := CompareStr(L.IName, R.IName);
   end;
end;


{ TRootServiceManager<T> }

procedure TRootServiceManager<T>.Add(const Item: IManagItem);
begin
  DoBeforeAdd(Item);
  TRegistration.Create(Item.Model).Add(TypeInfo(T)).LiveTime(ltSingletonNamed).AddInstance(Item.IName, Item as IInterface);
  DoAfterAdd(Item);
end;

procedure TRootServiceManager<T>.Remove(const Item: IManagItem);
begin
  DoBeforeRemove(Item, Item.IName);
  GContainer.RemoveInstance(Item.Model, Item.IName);
  DoAfterRemove(Item);
end;

function TRootServiceManager<T>.AsArrayRec: TArray<TInstanceRec<T>>;
begin
  Result := TArray<TInstanceRec<T>>(GContainer.InstancesAsArrayRec<T>);
end;

procedure TRootServiceManager<T>.Clear();
 var
  i: Integer;
  a: TArray<T>;
begin
  a := GContainer.InstancesAsArray<T>(False);
//  TArray.Sort<T>(a, TManagItemComparer<T>.Create); сортеруен InstancesAsArray
  for i :=Length(a)-1 downto 0 do
   begin
    if DoBeforeClear(a[i]) then
      GContainer.RemoveInstance(a[i].Model, a[i].IName); //Remove(a[i]);
    a[i] := nil;
   end;
  GContainer.RemoveInstKnownServ(TypeInfo(T)); // УДАЛЯЕМ текстовые не инициализированные объекты
end;

procedure TRootServiceManager<T>.DoAfterAdd(mi: IManagItem);
 var
  aa: INotifyAfterAdd;
begin
  Notify('S_AfterAdd');
  if Supports(mi, INotifyAfterAdd, aa) then aa.AfterAdd();
end;

procedure TRootServiceManager<T>.DoAfterRemove(mi: IManagItem);
 var
  ar: INotifyAfterRemove;
begin
  Notify('S_AfterRemove');
  if Supports(mi, INotifyAfterRemove, ar) then ar.AfterRemove();
end;

procedure TRootServiceManager<T>.DoBeforeAdd(mi: IManagItem);
 var
  ba: INotifyBeforeAdd;
begin
  FBindAdd := mi.IName;
  if Supports(mi, INotifyBeforeAdd, ba) then ba.BeforeAdd();
  Notify('S_BeforeAdd');
  if SupportPublishedChanged then Bind('C_PublishedChanged', mi, ['S_PublishedChanged']);
end;

procedure TRootServiceManager<T>.DoBeforeRemove(mi: IManagItem; const name: string);
 var
  br: INotifyBeforeRemove;
begin
  FBindRemove := name;
  if Supports(mi, INotifyBeforeRemove, br) then br.BeforeRemove();
  Notify('S_BeforeRemove');
end;

function TRootServiceManager<T>.DoBeforeClear(mi: IManagItem): Boolean;
 var
  bc: INotifyBeforeClean;
begin
  Result := True;
  if Supports(mi, INotifyBeforeClean, bc) then bc.BeforeClean(Result);
end;

procedure TRootServiceManager<T>.Remove(model: ModelType; const Item: string);
 var
  ir: TInstanceRec;
begin
  if GContainer.TryGetInstRec(model, Item, ir) then
  begin  //  если ir.Inst не инициализирован то будет АВ
   DoBeforeRemove(ir.Inst as IManagItem, Item);
   GContainer.RemoveInstance(model, Item);
   DoAfterRemove(ir.Inst as IManagItem);
  end;
end;

procedure TRootServiceManager<T>.Remove(const Item: string);
 var
  ir: TInstanceRec;
begin
  if GContainer.TryGetInstRecKnownServ(TypeInfo(T), Item, ir) then
  begin
   DoBeforeRemove(ir.Inst as IManagItem, Item);
   GContainer.RemoveInstKnownServ(TypeInfo(T), Item);
   DoAfterRemove(ir.Inst as IManagItem);
  end;
end;

function TRootServiceManager<T>.GetEnumerator: TEnumerator<T>;
begin
  Result := TContainer.TEnumService<T>.Create();
end;

{ TRootServiceManager<T>.TEnumEnumerable<T> }

function TRootServiceManager<T>.TEnumEnumerable<ET>.DoGetEnumerator: TEnumerator<ET>;
begin
  Result := FEnumerator;
end;

function TRootServiceManager<T>.Enum(Initialize: Boolean): TEnumerable<T>;
begin
  Result := TEnumEnumerable<T>.Create;
  TEnumEnumerable<T>(Result).FEnumerator := TContainer.TEnumService<T>.Create(Initialize);
end;

function TRootServiceManager<T>.GetManagItem(const ItemName: string; Initialize: Boolean): IManagItem;
 var
  ii: IInterface;
begin
  Result := nil;
  if GContainer.TryGetInstKnownServ(TypeInfo(T), ItemName, ii, Initialize) and Assigned(ii) then ii.QueryInterface(IManagItem, Result)
end;

function TRootServiceManager<T>.GetManagItem(model: ModelType; const ItemName: string; Initialize: Boolean): IManagItem;
 var
  ii: IInterface;
begin
  Result := nil;
  if GContainer.TryGetInstance(model, ItemName, ii, Initialize) and Assigned(ii) then ii.QueryInterface(IManagItem, Result)
end;

function TRootServiceManager<T>.Get(const ItemName: string; Initialize: Boolean): T;
 var
  ii: IInterface;
begin
  Result := nil;
  if GContainer.TryGetInstKnownServ(TypeInfo(T), ItemName, ii, Initialize) and Assigned(ii) then ii.QueryInterface(GetTypeData(TypeInfo(T)).Guid, Result)
end;

function TRootServiceManager<T>.Get(model: ModelType; const ItemName: string; Initialize: Boolean): T;
begin
  Supports(GetManagItem(model, ItemName, Initialize), GetTypeData(TypeInfo(T)).Guid, Result);
end;

function TRootServiceManager<T>.GetService: ServiceType;
begin
  Result := TypeInfo(T);
end;

procedure TRootServiceManager<T>.SetItemChanged(const Value: string);
begin
  FLastChangedName := Value;
end;

class function TRootServiceManager<T>.SupportPublishedChanged: Boolean;
begin
  Result := False;
end;

{ TManagItemComparer }

function TManagItemComparer.Compare(const Left, Right: IManagItem): Integer;
begin
  Result := Left.Priority - Right.Priority;
  if Result = 0 then Result := CompareStr(Left.IName, Right.IName);
end;

{$ENDREGION }

{$REGION 'Storable<T>'}

{ TRootStorable<T> }

procedure TRootServiceManager<T>.ItemInitialized(mi: IManagItem);
begin
  if SupportPublishedChanged then Bind('C_PublishedChanged', mi, ['S_PublishedChanged']);
end;

//procedure TRootServiceManager<T>.DoBeforeLoad(mi: IManagItem);
// var
//  lba: INotifyLoadBeroreAdd;
//begin
//  if Supports(mi, INotifyLoadBeroreAdd, lba) then lba.LoadBeroreAdd();
//end;
//
//procedure TRootServiceManager<T>.DoAfterLoad(mi: IManagItem);
// var
//  laa: INotifyLoadAfteAdd;
//begin
//  if Supports(mi, INotifyLoadAfteAdd, laa) then laa.LoadAfteAdd();
//end;

procedure TRootServiceManager<T>.DoBeforeSave(mi: IManagItem);
 var
  bs: INotifyBeforeSave;
begin
 if Supports(mi, INotifyBeforeSave, bs) then bs.BeforeSave();
end;

procedure TRootServiceManager<T>.DoAfterSave(mi: IManagItem);
 var
  sa: INotifyAfteSave;
begin
  if Supports(mi, INotifyAfteSave, sa) then sa.AfteSave();
end;

procedure TRootServiceManager<T>.DoLoadItem(const mit: string; Prior: Integer = 1000);
begin
  GContainer.AddTextInstance(TypeInfo(T), mit, Prior);
end;

procedure TRootServiceManager<T>.Load;
begin

end;

procedure TRootServiceManager<T>.New;
begin
  GContainer.RemoveInstKnownServ(TypeInfo(T));
end;

procedure TRootServiceManager<T>.Save;
begin

end;

{ TRegistryStorable<T> }

constructor TRegistryStorable<T>.Create(AOwner: TRootServiceManager<T>; const Path: string; func: TOnSaveFunc);
begin
  FOwner := AOwner;
  if not Assigned(func) then Ffunc := function(const InData: string): String
  begin
    Result := InData;
  end
  else Ffunc := func;
  FPath := Path;
end;

procedure TRegistryStorable<T>.New;
begin

end;

function TRegistryStorable<T>.GetService: ServiceType;
begin
  Result := TypeInfo(T);
end;

procedure TRegistryStorable<T>.Load;
 var
  r: TArray<TInstanceRec>;
  sss: TArray<string>;
  a: TInstanceRec;
  i: Integer;
  s: string;
begin
  (GlobalCore as IRegistry).LoadArrayString(FPath, sss);
  SetLength(r, Length(sss));
  for i := 0 to High(sss) do
   begin
    r[i].Text := sss[i].Remove(0, sss[i].IndexOf('|')+1);
    r[i].Priority := sss[i].Substring(0, sss[i].IndexOf('|')).ToInteger()
   end;
//   TArray.Sort<TInstanceRec>(r, TComparer<TInstanceRec>.Construct(function(const Left, Right: TInstanceRec): Integer
//    begin
//      Result := Left.Priority - Right.Priority;
//    end));
  for a in r do
   try
    FOwner.DoLoadItem(a.Text, a.Priority);
   except
    on E: Exception do TDebug.DoException(E, False);
   end;
end;

procedure TRegistryStorable<T>.Save;
 var
  a: TArray<TInstanceRec>;
  r: TInstanceRec;
  b: TArray<string>;
  f: T;
//  i: Integer;
begin
  for f in GContainer.Enum<T>(False) do FOwner.DoBeforeSave(f);
  a := GContainer.InstancesAsArrayRec<T>;
//  Tarray.Sort<TInstanceRec>(a, TComparer<TInstanceRec>.Construct(function(const Left, Right: TInstanceRec): Integer
//  begin
//    if not (Assigned(left.Inst) and Assigned(Right.Inst)) then Result := 0
//    else Result := (Left.Inst as ImanagItem).Priority - (Right.Inst as ImanagItem).Priority
//  end));
  for r in a do if r.Priority > 0 then
   try
    CArray.Add<string>(b, r.Priority.ToString + '|'+ Ffunc(r.Text));
   except
    on E: Exception do TDebug.DoException(E, False);
   end;
//  for i := 0 to Length(a)-1 do
//    if not (Assigned(a[i].Inst) and ((a[i].Inst as IManagItem).Priority < 0)) then
//      CArray.Add<WideString>(TArray<WideString>(b), a[i] Ffunc(a[i].Text));
  (GlobalCore as IRegistry).SaveArrayString(FPath, b);
  for f in GContainer.Enum<T>(False) do FOwner.DoAfterSave(f);
end;

{$ENDREGION}

{$REGION 'Dialog'}

{ RegisterDialog }

class function RegisterDialog.CategoryDescriptions(const Category: string): TArray<string>;
 var
  p : TPair<PTypeInfo,TDialogData>;
begin
  for p in FItems do
  if SameText(Category, p.Value.Categoty) then
   begin
     CArray.Add<string>(Result, p.Value.Description);
   end;
end;

class constructor RegisterDialog.Create;
begin
  FItems := TDictionary<PTypeInfo, TDialogData>.Create;
end;

class destructor RegisterDialog.Destroy;
begin
  FItems.Free;
end;

class procedure RegisterDialog.Add<T, D>(const Category: string = ''; const Description: string = '');
 var
  dd: TDialogData;
begin
  dd.DialogID := TypeInfo(D);
  dd.Description := Description;
  dd.Categoty := Category;
  FItems.AddOrSetValue(TypeInfo(T), dd);
  TRegister.AddType<T, IDialog>.LiveTime(ltSingleton);
end;

class procedure RegisterDialog.Remove<T>;
begin
  FItems.Remove(TypeInfo(T));
  GContainer.RemoveModel<T>;
end;

class function RegisterDialog.Support<D>: Boolean;
 var
  p : TPair<PTypeInfo,TDialogData>;
  i : IInterface;
begin
  Result := False;
  for p in FItems do if (p.Value.DialogID = TypeInfo(D)) then Exit(True);
end;

class function RegisterDialog.TryGet(const Category, Description: string; out Dialog: IDialog): Boolean;
 var
  p : TPair<PTypeInfo,TDialogData>;
  i : IInterface;
begin
  Result := False;
  for p in FItems do
    if SameText(Category, p.Value.Categoty) and SameText(Description, p.Value.Description) then
     Exit(Gcontainer.TryGetInstance(p.Key, i) and Supports(i, IDialog, Dialog));
end;

class procedure RegisterDialog.UnInitialize(const Category, Description: string);
 var
  p : TPair<PTypeInfo,TDialogData>;
begin
  for p in FItems do if SameText(Category, p.Value.Categoty) and SameText(Description, p.Value.Description) then
   begin
    Gcontainer.RemoveInstance(p.Key);
    Exit;
   end;
end;

class function RegisterDialog.TryGet<D>(out Dialog: IDialog): Boolean;
 var
  p : TPair<PTypeInfo,TDialogData>;
  i : IInterface;
begin
  Result := False;
  for p in FItems do
    if (p.Value.DialogID = TypeInfo(D)) then
     Exit(Gcontainer.TryGetInstance(p.Key, i) and Supports(i, IDialog, Dialog));
end;

class procedure RegisterDialog.UnInitialize(D: PTypeInfo);
 var
  p : TPair<PTypeInfo,TDialogData>;
begin
  for p in FItems do if p.Value.DialogID = D then begin Gcontainer.RemoveInstance(p.Key); Exit; end;
end;

class procedure RegisterDialog.UnInitialize<D>;
begin
  UnInitialize(TypeInfo(D));
end;

{$ENDREGION}


{class constructor GDIPlus.Create;
begin
  Flock := TCriticalSection.Create;
end;
class destructor GDIPlus.Destrroy;
begin
  Flock.Free;
end;
class procedure GDIPlus.Lock;
begin
//  TDebug.Log('GDI befo LOCK');
  Flock.Acquire;
//  TDebug.Log('GDI After LOCK');
end;
class procedure GDIPlus.UnLock;
begin
  Flock.Release;
//  TDebug.Log('GDI After RELEASE');
end;}

{ EnumCaptionsAttribute }

//constructor EnumCaptionsAttribute.Create(const ACaptions: string);
// var
//  i: Integer;
//begin
//  FCaptions := ACaptions.Split([',',';']);
//  for I := 0 to High(FCaptions) do FCaptions[i] := FCaptions[i].Trim;
//end;

{ TJvEnumCaptionsInspectorData }

//class function TJvInspectorPropDataEx.ItemRegister: TJvInspectorRegister;
//begin
//  Result := inherited;
//  with Result do
//   begin
//    Delete(TJvInspectorEnumItem);
//    Add(TJvInspectorTypeKindRegItem.Create(TJvInspectorEnumCaptionsItem, tkEnumeration));
//    Add(TJvInspectorTypeInfoRegItem.Create(TJvInspectorBooleanItem, System.TypeInfo(Boolean)));
//    Add(TJvInspectorTypeInfoRegItem.Create(TJvInspectorBooleanItem, System.TypeInfo(ByteBool)));
//    Add(TJvInspectorTypeInfoRegItem.Create(TJvInspectorBooleanItem, System.TypeInfo(WordBool)));
//    Add(TJvInspectorTypeInfoRegItem.Create(TJvInspectorBooleanItem, System.TypeInfo(LongBool)));
//   end;
//end;
//
{ TJvInspectorEnumCaptionsItem }

{constructor TJvInspectorEnumCaptionsItem.Create(const AParent: TJvCustomInspectorItem; const AData: TJvCustomInspectorData);
 var
  c: TRttiContext;
  a : TCustomAttribute;
begin
  inherited;
  c := TRttiContext.Create;
  try
  for a in c.GetType(Data.TypeInfo).GetAttributes do if a is EnumCaptionsAttribute then
   begin
    FCaptions := EnumCaptionsAttribute(a).Captions;
    Break;
   end;
  finally
    c.Free;
  end;
end;

function TJvInspectorEnumCaptionsItem.GetDisplayValue: string;
begin
  if Length(FCaptions) = 0 then Result := inherited
  else Result := FCaptions[Data.AsOrdinal];
end;

procedure TJvInspectorEnumCaptionsItem.GetValueList(const Strings: TStrings);
 var
  s: string;
begin
  if Length(FCaptions) = 0 then inherited
  else for s in FCaptions do Strings.Add(s)
end;

procedure TJvInspectorEnumCaptionsItem.SetDisplayValue(const Value: string);
 var
  i: Integer;
begin
  if Length(FCaptions) = 0 then inherited
  else
   begin
    for I := 0 to High(FCaptions) do if SameText(Value, FCaptions[i]) then
     begin
      Data.AsOrdinal := i;
      Exit;
     end;
    i := StrToIntDef(Value, -1);
    if i >= 0 then Data.AsOrdinal := i;
   end;
end;       }

{ GTask }

class constructor GTask.Create;
begin
  FLock := TObject.Create;
  SetLength(FTasks, 8);
end;

class destructor GTask.Destroy;
begin
  WaitForAll;
  FLock.Free;
end;

class function GTask.Get(const Func: TProc): ITask;
var
  I: Integer;
  LArray, NewArray: TArray<ITask>;
begin
  while True do
  begin
    Result := TTask.Create(Func);
    LArray := FTasks;
    System.TMonitor.Enter(FLock);
    try
      for I := 0 to Length(LArray) - 1 do
      begin
        if not Assigned(LArray[I]) or (LArray[I].Status > TTaskStatus.Running) then
         begin
          FTasks[I] := Result;
          Exit;
         end
        else if I = Length(LArray) - 1 then
         begin
          if LArray <> FTasks then Continue;
          SetLength(NewArray, Length(LArray) * 2);
          TArray.Copy<ITask>(LArray, NewArray, I + 1);
          NewArray[I + 1] := Result;
          FTasks := NewArray;
          Exit;
         end;
      end;
    finally
      System.TMonitor.Exit(FLock);
    end;
  end;
end;

class procedure GTask.Remove(task: ITask);
var
  I: Integer;
begin
  System.TMonitor.Enter(FLock);
  try
    for I := 0 to Length(FTasks) - 1 do
      if FTasks[I] = task then
       begin
        FTasks[I] := nil;
        Exit;
       end;
  finally
    System.TMonitor.Exit(FLock);
  end;
end;

class function GTask.Run(const Func: TProc): ITask;
begin
  Result := Get(Func).Start;
end;

class procedure GTask.SetRemove;
begin
  System.TMonitor.Enter(FLock);
  try
   FRemovin := True;
  finally
   System.TMonitor.Exit(FLock);
  end;
end;

class procedure GTask.WaitForAll;
 var
  i: Integer;
begin
  System.TMonitor.Enter(FLock);
  try
   for i := Length(FTasks)-1 downto 0 do
    if not Assigned(FTasks[i]) then Delete(FTasks, i, 1);// else FTasks[i].Cancel;
   TTask.WaitForAll(FTasks);
   SetLength(FTasks, 0);
  finally
   System.TMonitor.Exit(FLock);
  end;
end;


{ TBindObjWrap<T> }

class operator TBindObjWrap.Implicit(d: TPersistent): TBindObjWrap;
begin
  Result.obj := d;
end;

class operator TBindObjWrap.Implicit(d: TBindObjWrap): TPersistent;
begin
  Result := d.obj;
end;

{ TCNavigator }

constructor TCNavigator.Create(AOwner: TComponent);
 var
  play, step, pouse: TButtonDescription;
begin
  inherited;
end;

{ TFactoryPersistent<ROOT> }

constructor TFactoryPersistent<ROOT>.CreateUser(AStored: ROOT);
begin
  if not Assigned(AStored) then raise Exception.Create('TFactoryPersistent<ROOT>.CreateUser(AStored: ROOT) AStored = nil !!!');
  FStored := AStored;
end;

destructor TFactoryPersistent<ROOT>.Destroy;
begin
  if Assigned(FStored) then FreeAndNil(FStored);
  TDebug.Log('TFactoryPersistent.Destroy ' + StoredClass);
  inherited;
end;

function TFactoryPersistent<ROOT>.GetClass: string;
begin
  if Assigned(FStored) then Result := FStored.ClassName
  else Result := '';
end;

function TFactoryPersistent<ROOT>.GetROOT: ROOT;
begin
  Result := FStored;
end;

procedure TFactoryPersistent<ROOT>.SetClass(const Value: string);
begin
  if Assigned(FStored) then
    FreeAndNil(FStored);
  if Value <> '' then
    FStored := ROOT((FindClass(Value)).Create());
end;

procedure TFactoryPersistent<ROOT>.SetROOT(const Value: ROOT);
begin
  if Assigned(FStored) then FStored.Free;
  FStored := Value;
end;

{ TStatistic }

constructor TStatisticCreate.Create(Count: UInt64);
begin
  if Count = 0 then raise EBaseException.Create('Нет данных для работы [Count=0]');

  FCount := Count;
  FTimeBegin := Now;
end;

function TStatisticCreate.GetStatistic: TStatistic;
begin
  Result := FStatistic;
end;

procedure TStatisticCreate.UpdateAdd(cnt: Cardinal);
begin
  UpdateAll(FStatistic.NRead + cnt);
end;

procedure TStatisticCreate.UpdateAll(cnt: UInt64);
 var
  Spd: double;
begin
  FStatistic.NRead := cnt;
  FStatistic.TimeFromBegin := Now - FTimeBegin;
  FStatistic.ProcRun := FStatistic.NRead/FCount*100;
  // speed
  if FStatistic.TimeFromBegin > 0 then Spd := FStatistic.NRead / FStatistic.TimeFromBegin else Spd := 0;
  FStatistic.Speed := Spd/1024/1024 /24/3600; // MB/sec
  if Spd > 0 then FStatistic.TimeToEnd := (FCount - FStatistic.NRead)/spd
  else FStatistic.TimeToEnd := 1;
end;

class procedure TStatisticCreate.UpdateStandardStatusBar(sb: TStatusBar; Stat: TStatistic);
begin
  sb.Panels[0].Text := Stat.ProcRun.ToString(ffFixed, 7, 1)+'%';
  if Stat.Speed > 0.1 then
    sb.Panels[1].Text := Stat.Speed.ToString(ffFixed, 7, 0)+'Mb/s'
  else
    sb.Panels[1].Text := (Stat.Speed*1024).ToString(ffFixed, 7, 0)+'Kb/s';
  sb.Panels[2].Text := TimeToStr(Stat.TimeFromBegin);
  sb.Panels[3].Text := TimeToStr(Stat.TimeToEnd);
end;

initialization
//  RegisterClass();
 TRegister.AddType<TFormEnum, IFormEnum, IStorable>.LiveTime(ltSingleton);

{  TValueRefConverterFactory.RegisterConversion(TypeInfo(TSetConnectIOStatus), TypeInfo(string),
  TConverterDescription.Create(procedure(const I: TValue; var O: TValue)
  begin
    O := 'SetConnectIOStatus';
  end, 'SetConnectIOStatusToStr', 'SetConnectIOStatusToStr', '', True, '', nil));

  TValueRefConverterFactory.RegisterConversion(TypeInfo(TDeviceStatus), TypeInfo(string),
  TConverterDescription.Create( procedure(const I: TValue; var O: TValue)
  begin
    O := 'DeviceStatus';
  end, 'DeviceStatusToStr', 'DeviceStatusToStr', '', True, '', nil));
finalization

  TValueRefConverterFactory.UnRegisterConversion('SetConnectIOStatusToStr');
  TValueRefConverterFactory.UnRegisterConversion('DeviceStatusToStr');}
end.


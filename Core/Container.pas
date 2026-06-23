unit Container;

interface

{$DEFINE MEMO_DEBUG}

uses System.Classes, System.SysUtils, System.TypInfo, RTTI,
     System.Generics.Defaults,
     System.Generics.Collections,
     Controls,
     debug_except;

type
  ModelType = PTypeInfo;
  ServiceType = PTypeInfo;

  TInstanceRec = record
//    IName: string;
    Inst: IInterface;
    Priority: Integer;
    Text: string;
  end;

  ///	<summary>
  ///	  Внутренний интерфейс для загрузки и сохранения объекта
  ///	</summary>
  IManagItem = interface(IInterfaceComponentReference)
  ['{1EC89F48-842C-4415-AA10-9161570B0549}']
    ///	<summary>
    ///	  приоритет загрузки
    ///	</summary>
    ///	<remarks>
    ///	  фактически константа инициализируемая при создании
    ///	</remarks>
    function Priority: Integer;
    ///	<summary>
    ///	  имя для формирования имен объектов TDevice =&gt;  Device
    ///	</summary>
    function RootName: String;
    function GetItemName: String;
    ///	<summary>
    ///	  Вызывается менегером TEnumer<T>.Add при создании или загрузки
    ///	</summary>
    procedure SetItemName(const Value: String);
    function Model: ModelType;
    ///	<summary>
    ///	  имя компонента или формы
    ///	</summary>
    ///	<remarks>
    ///	  инициализируется менегером TEnumer<T>.Add при создании или загрузки
    ///   под этим именем хранится в контейнере
    ///	</remarks>
    property IName: String read GetItemName write SetItemName;
  end;

  TInstanceRec<T: IManagItem> = record
    Inst: T;
    Priority: Integer;
    Text: string;
  end;

  ICaption = interface
  ['{DBBF1D44-F436-435C-BF09-1A58290A4B11}']
    function GetCaption: string;
    procedure SetCaption(const Value: string);
    property Text: string read GetCaption write SetCaption;
  end;

  // основные классы
  TComponentModel = class;
  TInstance = class;
  // помошники
  TObjDictionary<TKey; TObj: class> = class(TDictionary<TKey,TObj>)
  protected   // классы уничтожаем вручную
    procedure ValueNotify(const Value: TObj; Action: TCollectionNotification); override;
  end;
  // словари коллекции
  TModels = class(TList<TComponentModel>)
  public
    function TryGetTInstance(const InstanceName: string; out Inst: TInstance): Boolean;
  end;
  // словарь по сервисам на сервисе может быть много моделей у модели может быть много сервисов
  TServicePair  = TPair<ServiceType, TModels>;
  TServiceDict = TObjDictionary<ServiceType, TModels>;
  // словарь по моделям однозначное соответствие
  TModelPair = TPair<ModelType, TComponentModel>;
  TModelDict = class(TObjDictionary<ModelType, TComponentModel>)
  protected
    fSrv: TServiceDict;
    procedure ValueNotify(const Value: TComponentModel; Action: TCollectionNotification); override;
  end;
  // поиск ServiceType по TGUID  однозначное соответствие
  TGuidPair  = TPair<TGUID, ServiceType>;
  TGuidDict = TDictionary<TGUID, ServiceType>;
  // у модели может быть много именных ltSingleton реализаций
  TInstancePair = TPair<string, TInstance>;
  TInstancesDict = TObjDictionary<string, TInstance>;

{$REGION 'Dependency, Injection'}

  // атрибуты Injection
  TInjectionAttribute = class(TCustomAttribute);

  TDependenceAttribute = class(TInjectionAttribute)
  protected
    FModel: PTypeInfo;
    FService: PTypeInfo;
  public
    property Model: PTypeInfo read FModel;
    property Service: PTypeInfo read FService;
  end;
  // дочерние объекты
  TDependency = record
    Model: ModelType;
    Service: ServiceType;
    InstanceName: string;
  end;
  TDependencies = TArray<TDependency>;

  IAttributeInjection = interface
  ['{2A231830-312C-4F5B-88D9-8E7C7A70F2F5}']
    function Support(a: TCustomAttribute): Boolean;
    procedure AddDependency(RootModel: TRttiInstanceType;
                            RttiMember: TRttiMember;
                            Atr: TCustomAttribute;
                        var Ds: TDependencies); overload;
    procedure AddDependency(RootModel: TRttiInstanceType;
                            RttiMember: TRttiMember;
                            Atr: TCustomAttribute;
                      const InstName: string;
                        var Ds: TDependencies); overload;
    procedure Inject(RootModel: TRttiInstanceType;
                     RttiMember: TRttiMember;
                     Atr: TCustomAttribute); overload;
    procedure Inject(RootModel: TRttiInstanceType;
                     RttiMember: TRttiMember;
                     Atr: TCustomAttribute;
               const InstName: string); overload;
  end;

  TAttrInjection = record
    member: TRttiMember;
    a: TCustomAttribute;
    aij: IAttributeInjection;
    constructor Create(RttiMember: TRttiMember; Attr: TCustomAttribute; AttrInj: IAttributeInjection);
  end;
  TAttrInjections = TArray<TAttrInjection>;

  TCustomAttributeInjection = class(TInterfacedObject, IAttributeInjection)
  protected
    function Support(a: TCustomAttribute): Boolean; virtual; abstract;
    procedure AddDependency(RootModel: TRttiInstanceType; RttiMember: TRttiMember; Atr: TCustomAttribute; var Ds: TDependencies); overload; virtual;
    procedure AddDependency(RootModel: TRttiInstanceType; RttiMember: TRttiMember; Atr: TCustomAttribute; const InstName: string; var Ds: TDependencies); overload; virtual;
    procedure Inject(RootModel: TRttiInstanceType; RttiMember: TRttiMember; Atr: TCustomAttribute); overload; virtual;
    procedure Inject(RootModel: TRttiInstanceType; RttiMember: TRttiMember; Atr: TCustomAttribute; const InstName: string); overload; virtual;
  end;
{$ENDREGION}

{$REGION 'TComponentModel'}

  TInstance = class
    fValue: IInterface;
    Priority: Integer;
    fText: string;
//   destructor Destroy; override;
  end;

  TInstanceRecH = record helper for TInstanceRec
  private
    constructor Create({const n: string;} AInst: TInstance);
  end;
  // свойства сервисов
             //             хранит       не хранит    хранит по имент   хранит модель по имени
             //             обект        обект        обект             обект не хранит
  TLiveTime = (ltAttribute, ltSingleton, ltTransient, ltSingletonNamed, ltTransientNamed);

  EComponentModel = class(EBaseException);
  TComponentModel = class
  private
    fClassType: PTypeInfo;
    //  именные объекты
    fInst: TInstancesDict;
    fInstanceType: TRttiInstanceType;

    fLiveTime: TLiveTime;

    fSingleton: IInterface;
    fModelPriority: Integer;
    //  ссылки на дочерние объекты класса или создадут (factory) Singleton Transient и выполнят задачу
    //  например IAction создающие экземпляр класса (factory), авто конструкторы
    //  class vars class procedures constructors
    fClsDependencies: TDependencies;
    //  заготовка ссылок на объектные зависимости
    fInstDependencies: TDependencies;
    // создание зависимостей при создании экземпляра объекта
    fInstInject: TAttrInjections;

    function CreateInstance: TObject;
    function CreateTInstance(const Name: string): TInstance;
    procedure InjectInstance(const Name: string);
    procedure RemoveDependencies(const Name: string);
  public
    constructor Create(ClassType: PTypeInfo);
    destructor Destroy; override;

    function Contains(const Name: string): boolean;

    function GetInstance(Initialize: Boolean = True): IInterface; overload;
    function GetInstance(const Name: string; Initialize: Boolean): IInterface; overload;
    function GetInstance(Inst: TInstance; Initialize: Boolean): IInterface; overload;
    class function GetTextInstance(Inst: TInstance): string;

    procedure AddInstance(const Name: string; Inst: IInterface); overload;
//    procedure AddInstance(const Name: string; Inst: string); overload;
    procedure AddInstance(const Name: string; Inst: string; Prior: Integer = 1000); overload;
//    function ContainsInstance(const Name: string):Boolean; { TODO : write }
    procedure NillInstance(const Name: string);
    procedure RemovInstance(const Name: string);
    procedure RemovInstances;

    property InstanceType: TRttiInstanceType read fInstanceType;
    property LiveTime: TLiveTime read fLiveTime;
    property ModelPriority: Integer read fModelPriority;
  end;
{$ENDREGION}

{$REGION 'TContainer'}
type
  EContainer = class(EBaseException);
  TContainer = class(TObject, IInterface)
  private
    FModels: TModelDict;
    FGuids: TGuidDict;
    FServices: TServiceDict;
    FAids: TArray<IAttributeInjection>;
    class var RttiContext: TRttiContext;
    class var This: TContainer;
    class constructor Create;
    class destructor Destroy;
  protected
    function QueryInterface(const IID: TGUID; out Obj): HResult; stdcall;
    function _AddRef: Integer; stdcall;
    function _Release: Integer; stdcall;
    function Contains(cm: TComponentModel; InstanceName: string): Boolean; overload;
    function TryFindComponentModel(Inst: IInterface; out cm: TComponentModel; out ip: TInstancePair): Boolean;
    function GetDynamicActionsNames(Inst: IInterface): TArray<string>;
 public
    constructor Create;
    destructor Destroy; override;
    // основные функции проверки Instance без создания объекта
    function Contains(Model: ModelType; InstanceName: string): Boolean; overload;
    function Contains(InstanceName: string): Boolean; overload;
    // основные функции получения Instance Service
    function TryGetInstance(Model: ModelType; out Obj: IInterface; Initialize: Boolean = true): Boolean; overload;
    function TryGetInstance(const InstanceName: string; out Obj: IInterface; Initialize: Boolean = true): Boolean; overload;
    function TryGetInstance(Model: ModelType; const InstanceName: string; out Obj: IInterface; Initialize: Boolean = True): Boolean; overload;
    function TryGetInstKnownServ(serv: ServiceType; const InstanceName: string; out Obj: IInterface; Initialize: Boolean = True): Boolean; overload;
    function TryGetInstRecKnownServ(serv: ServiceType; const InstanceName: string; out Rec: TInstanceRec): Boolean;
    function TryGetInstRec(Model: ModelType; const InstanceName: string; out Rec: TInstanceRec): Boolean;

    function CreateValuedInstance<T>(const ClassName, ConstructorName: string; Data: T): IInterface;


    function GetService(const IID: TGUID; out Obj): HResult; overload; inline;
    function GetService<Service: IInterface>(out Obj): HResult; overload;

    function TryGetModelRTTI(Model: ModelType; out InstanceType: TRttiInstanceType): Boolean;

    function GetModelType(const ClassName: string): ModelType;
    function GetModelLiveTime(Model: ModelType): TLiveTime;

    class function GetIName(const InstanceText: string): string;
    class function GetClassName(const InstanceText: string): string;

    procedure AddTextInstance(serv: ServiceType; const InstanceText: string; Prior: Integer = 1000);
    // удаление
    /// <summary>
    /// обнуление Instance интерфейса
    /// создается и сохраняется текст объекта
    /// </summary>
    procedure NillInstKnownServ(serv: ServiceType; const InstanceName: string);
    procedure NillInstance(model: ModelType;  const InstanceName: string); overload;

    procedure RemoveModel<T: class>; inline; //при выгрузке плугина
    procedure RemoveModels;  inline; // при выгрузке программы

    procedure RemoveInstances;
//    procedure RemoveInstance(Instance: TObject); overload;
    procedure RemoveInstance(model: ModelType;  const InstanceName: string); overload;
    procedure RemoveInstance<T: class>(const InstanceName: string); overload;
    procedure RemoveInstance(model: ModelType); overload; // singleton
    procedure RemoveInstance(const InstanceName: string); overload;
    procedure RemoveInstKnownServ(serv: ServiceType; const InstanceName: string);overload;
    procedure RemoveInstKnownServ(serv: ServiceType);overload;

    procedure InjectDependences(const InstanceName: string);
    {$IFDEF MEMO_DEBUG}
    procedure UpdateDebugData(ss: TStrings);
    {$ENDIF}
//             зависимости
    procedure RegisterAttrInjection(aid: IAttributeInjection);
    function TryGetAttrInjection(Attr: TCustomAttribute; out aid: IAttributeInjection): Boolean;


    /// итерации
    /// основная итерация используется энумератором
    /// сортировка по приоритету:
    ///  - приоритет модели
    ///  - приоритет именных объектов
    ///  смешанные livetime
    type
     /// вспомогательные классы к InstancesAsArray
     TModelsInst = record
      m: TComponentModel;
      p: TInstancePair;
     end;
     TModelsInstComparer = class(TComparer<TModelsInst>)
       function Compare(const Left, Right: TModelsInst): Integer; override;
       class procedure Add(var mi: TArray<TModelsInst>; cm: TComponentModel; ip: TInstancePair); overload;
       class procedure Add(var mi: TArray<TModelsInst>; cm: TComponentModel); overload;
     end;
    function InstancesAsArray<Service: IInterface>(InitializeInstatces: Boolean = False): TArray<Service>;
    // модели ltSingletonNamed, ltTransientNamed
    function InstancesAsArrayRec<Service: IInterface>: TArray<TInstanceRec>;
//    function InstancesAsNamedArray<Service: IInterface>(InitializeInstatces: Boolean = False): TArray<TPair<string, Service>>;
    function ModelsAsArray<Service: IInterface>: TArray<ModelType>; overload; inline;
    function ModelsAsArray(Serv: ServiceType): TArray<ModelType>; overload;
    type
     TEnumService<T: IInterface> = class(TEnumerator<T>)
     private
       i: Integer;
       Data: TArray<T>;
     protected
       function DoGetCurrent: T; override;
       function DoMoveNext: Boolean; override;
     public
       constructor Create(InitializeInstatces: Boolean = False);
       function GetEnumerator: TEnumerator<T>;
     end;
{     TEnumerService<T: IInterface> = record// class(TEnumerable<T>)
       EnumService: TEnumService<T>;
       function GetEnumerator: TEnumerator<T>;// override;
     end;}
    function Enum<Service: IInterface>(InitializeInstatces: Boolean = False): TEnumService<Service>;
  end;

{$ENDREGION}

{$REGION 'Registration'}
  TRegistration = record
  private
    fClassType: PTypeInfo;
    fModel: TComponentModel;
  public
    constructor Create(ClassType: PTypeInfo);
    function Add(Srv: PTypeInfo): TRegistration;
    function LiveTime(const lt: TLiveTime): TRegistration;
    function AddInstance(const Inst: IInterface): TRegistration; overload;
    function AddInstance(const Name: string; const Inst: IInterface): TRegistration; overload;
    function AddInstance(const Name: string; const Inst: string; Prior: Integer = 1000): TRegistration; overload;
  end;

  TRegistration<T: class> = record
  private
    fRegist: TRegistration;
  public
    function Add<I1: IInterface>: TRegistration<T>; overload;
    function Add<I1,I2: IInterface>: TRegistration<T>; overload;
    function Add<I1,I2,I3: IInterface>: TRegistration<T>; overload;
    function Add<I1,I2,I3,I4: IInterface>: TRegistration<T>; overload;
    function Add<I1,I2,I3,I4,I5: IInterface>: TRegistration<T>; overload;
    function Add<I1,I2,I3,I4,I5,I6: IInterface>: TRegistration<T>; overload;
    function Add<I1,I2,I3,I4,I5,I6,I7: IInterface>: TRegistration<T>; overload;
    function Add<I1,I2,I3,I4,I5,I6,I7,I8: IInterface>: TRegistration<T>; overload;
    function Add<I1,I2,I3,I4,I5,I6,I7,I8,I9: IInterface>: TRegistration<T>; overload;
    function LiveTime(const lt: TLiveTime): TRegistration<T>;
    function SingletonPriority(const pr: Integer): TRegistration<T>;
    function AddInstance(const Inst: IInterface): TRegistration<T>; overload;
    function AddInstance(const Name: string; const Inst: IInterface): TRegistration<T>; overload;
    function AddInstance(const Name: string; const Inst: string; Prior: Integer = 1000): TRegistration<T>; overload;
    function AddInstance(const Name: string): TRegistration<T>; overload;
//    function Name(const AName: string): TRegistration<T>;
  end;

  TRegister = class
    class function AddType<T: class>: TRegistration<T>; overload;
    class function AddType<T: class; I1: IInterface>: TRegistration<T>; overload;
    class function AddType<T: class; I1,I2: IInterface>: TRegistration<T>; overload;
    class function AddType<T: class; I1,I2,I3: IInterface>: TRegistration<T>; overload;
    class function AddType<T: class; I1,I2,I3,I4: IInterface>: TRegistration<T>; overload;
    class function AddType<T: class; I1,I2,I3,I4,I5: IInterface>: TRegistration<T>; overload;
    class function AddType<T: class; I1,I2,I3,I4,I5,I6: IInterface>: TRegistration<T>; overload;
    class function AddType<T: class; I1,I2,I3,I4,I5,I6,I7: IInterface>: TRegistration<T>; overload;
    class function AddType<T: class; I1,I2,I3,I4,I5,I6,I7,I8: IInterface>: TRegistration<T>; overload;
    class function AddType<T: class; I1,I2,I3,I4,I5,I6,I7,I8, I9: IInterface>: TRegistration<T>; overload;
  end;
{$ENDREGION}

 var
//  LastModelInst: TInstancesDict;
//  LastModel: TComponentModel;
  GlobalCore: IInterface;
  function GContainer: TContainer; inline;

implementation

uses tools;

function GContainer: TContainer;
begin
  Result := TContainer.This;
end;

{$REGION 'small helpers'}

{ TAttrInjection }

constructor TAttrInjection.Create(RttiMember: TRttiMember; Attr: TCustomAttribute; AttrInj: IAttributeInjection);
begin
  member := RttiMember;
  a := Attr;
  aij := AttrInj;
end;

{ TDictionary<TKey, TObj> }

procedure TObjDictionary<TKey, TObj>.ValueNotify(const Value: TObj; Action: TCollectionNotification);
begin
  if Action = cnRemoved then Value.Free;
end;

{ TModelDict }

procedure TModelDict.ValueNotify(const Value: TComponentModel; Action: TCollectionNotification);
 var
  p: TServicePair;
  i: Integer;
begin
  if Action <> cnRemoved then Exit;
  // удаляем все ссылки на модель
  for p in fSrv do for I := p.Value.Count-1 downto 0 do if p.Value[i] = Value then p.Value.Remove(Value);
 // если нет моделей нет и сервиса
 { TODO : find error  работает только в двух циклах !!! ?????}
  for p in fSrv do if p.Value.Count <= 0 then fSrv.Remove(p.Key);
  Value.Free;
end;

{ TModels }

function TModels.TryGetTInstance(const InstanceName: string; out Inst: TInstance): Boolean;
 var
  m: TComponentModel;
begin
  Result := False;
  for m in self do if (m.LiveTime = ltSingletonNamed) and Assigned(m.fInst) and m.fInst.TryGetValue(InstanceName, Inst) then Exit(True);
end;

{$ENDREGION}

{$REGION 'TCustomAttributeInjection'}

{ TCustomAttributeInjection }

procedure TCustomAttributeInjection.AddDependency(RootModel: TRttiInstanceType; RttiMember: TRttiMember; Atr: TCustomAttribute; var Ds: TDependencies);
 var
  d: TDependency;
begin
  if not (Atr is TDependenceAttribute) then Exit;
  d.Model := TDependenceAttribute(Atr).Model;
  d.Service := TDependenceAttribute(Atr).Service;
  d.InstanceName := Format('%s_%s',[RootModel.Name, RttiMember.Name]);
  CArray.Add<TDependency>(Ds, d);
end;

procedure TCustomAttributeInjection.AddDependency(RootModel: TRttiInstanceType; RttiMember: TRttiMember; Atr: TCustomAttribute; const InstName: string; var Ds: TDependencies);
 var
  d: TDependency;
begin
  if not (Atr is TDependenceAttribute) then Exit;
  d.Model := TDependenceAttribute(Atr).Model;
  d.Service := TDependenceAttribute(Atr).Service;
  d.InstanceName := Format('%s_%s',[InstName, RttiMember.Name]);
  CArray.Add<TDependency>(Ds, d);
end;
procedure TCustomAttributeInjection.Inject(RootModel: TRttiInstanceType; RttiMember: TRttiMember; Atr: TCustomAttribute);
begin
end;
procedure TCustomAttributeInjection.Inject(RootModel: TRttiInstanceType; RttiMember: TRttiMember; Atr: TCustomAttribute; const InstName: string);
begin
end;
{$ENDREGION}

{$REGION 'TComponentModel'}

{ TInstanceRec }

constructor TInstanceRecH.Create({const n: string;} AInst: TInstance);
begin
//  IName := n;
  Inst := AInst.fValue;
  Priority := AInst.Priority;
  Text := TComponentModel.GetTextInstance(AInst);
end;


{ TComponentModel }

function TComponentModel.Contains(const Name: string): boolean;
begin
  if not Assigned(fInst) then Exit(False);
  Result := fInst.ContainsKey(Name);
end;

constructor TComponentModel.Create(ClassType: PTypeInfo);
 var
  m: TRttiMethod;
  a: TCustomAttribute;
  aij: IAttributeInjection;
begin
  fClassType := ClassType;
  fModelPriority := 1000;
  fInst := TInstancesDict.Create(10);
  fInstanceType := TContainer.RttiContext.GetType(ClassType).AsInstance;
  for m in fInstanceType.GetDeclaredMethods do for a in m.GetAttributes do
   if (a is TInjectionAttribute) and GContainer.TryGetAttrInjection(a, aij) then
    if m.IsClassMethod then
     begin
      aij.AddDependency(fInstanceType, m, a, fClsDependencies);
      aij.Inject(fInstanceType, m, a);
     end
    else
     begin
      aij.AddDependency(fInstanceType, m, a, '%s', fInstDependencies);
      CArray.Add<TAttrInjection>(fInstInject, TAttrInjection.Create(m, a, aij));
     end;
end;

destructor TComponentModel.Destroy;
 var
  d: TDependency;
  m: TComponentModel;
begin
  // удаляем дочерние зависимости
  for d in fClsDependencies do
   if GContainer.FModels.TryGetValue(d.Model, m) then
    m.RemovInstance(d.InstanceName);
  if Assigned(fInst) then FreeAndNil(fInst);
  inherited;
end;

function TComponentModel.CreateTInstance(const Name: string): TInstance;
begin
  if not Assigned(fInst) then
   begin
     fInst := TInstancesDict.Create();
     //Tdebug.Log('TInstancesDict.Create %s',[fClassType.Name])
   end;
  Assert(fLiveTime in [ltSingletonNamed, ltTransientNamed], 'Необходимо инициализировать fLiveTime!!!');
  if not fInst.TryGetValue(Name, Result) then
   begin
    Result := TInstance.Create;
    fInst.Add(Name, Result);
   // Tdebug.Log('fInst.Add %s %x',[Name, LastModelInst.Count])
   end;
end;

procedure TComponentModel.AddInstance(const Name: string; Inst: IInterface);
 var
  v: TInstance;
  m: IManagItem;
begin
  v := CreateTInstance(Name);
  v.fValue := Inst;
  if Supports(inst, IManagItem, m) then v.Priority := m.Priority;
  InjectInstance(Name);
end;

//procedure TComponentModel.AddInstance(const Name: string; Inst: string);
// var
//  v: TInstance;
//begin
//  CreateTInstance(Name).fText := Inst;
//  InjectInstance(Name);
//end;

procedure TComponentModel.AddInstance(const Name: string; Inst: string; Prior: Integer);
 var
  v: TInstance;
begin
  v := CreateTInstance(Name);
  v.fText := Inst;
  v.Priority := Prior;
end;

procedure TComponentModel.RemoveDependencies(const Name: string);
 var
  i: TDependency;
begin
  for i in fInstDependencies do GContainer.RemoveInstance(i.Model, Format(i.InstanceName, [Name]));
end;

procedure TComponentModel.RemovInstance(const Name: string);
begin
  RemoveDependencies(Name);
  if Assigned(fInst) then fInst.Remove(Name);
end;

procedure TComponentModel.RemovInstances;
 var
  n: string;
begin
  fSingleton := nil;
  if Assigned(fInst) then
   begin
    for n in fInst.Keys do RemoveDependencies(n);
    fInst.Clear;
   end;
end;

function TComponentModel.CreateInstance: TObject;
 var
  method: TRttiMethod;
begin
  Result := nil;
  for method in fInstanceType.GetMethods do
    if method.IsConstructor and (Length(method.GetParameters) = 0) and SameText(method.Name, 'Create') then
       Exit(method.Invoke(fInstanceType.MetaclassType, []).AsObject);
end;

function TComponentModel.GetInstance(Initialize: Boolean): IInterface;
begin
  Result := fSingleton;
  if Assigned(Result) or not Initialize then Exit;
  case fLiveTime of
   ltAttribute: raise Exception.Create('ltAttribute');
   ltSingletonNamed: raise Exception.Create('ltSingletonNamed');
//   ltTransientNamed: raise Exception.Create('ltTransientNamed');
  end;
  CreateInstance.GetInterface(IInterface, Result);
  if fLiveTime = ltSingleton then fSingleton := Result;    // AtomicCmpExchange(fSingleton, Result, nil);
end;

 type
  TMyInnerComponent = class(TComponent);

function TComponentModel.GetInstance(Inst: TInstance; Initialize: Boolean): IInterface;
 var
  o: TMyInnerComponent;
  ss: TStringStream;
  ms: TMemoryStream;
  p : TInstancePair;
begin
  Result := Inst.fValue;
  if Assigned(Result) or not Initialize then Exit;
  o := TMyInnerComponent(CreateInstance);
  o.GetInterface(IInterface, Result); // - ВАЖННЫЙ МОМЕНТ чтобы не вызвать деструктор при чтении компонента (если например будет (self as IBind) )
  if fLiveTime = ltTransientNamed then Exit;
//  o := (Inst.fValue as IInterfaceComponentReference).GetComponent;
  if Inst.fText <> '' then
   begin
    ss := TStringStream.Create;
    ms := TMemoryStream.Create;
    try
     ss.WriteString(Inst.fText);
     ss.Position := 0;
     ObjectTextToBinary(ss, ms);
     ms.Position := 0;
     try
      ms.ReadComponent(o);
      // Если компонент загружается при вызове Loaded другого компонента (было с Формой) то o.Loaded системой не вызывается
      // проверяем это и вызываем вручную
      if (csLoading in o.ComponentState) then o.Loaded;
     except
      for p in fInst do if p.Value = Inst then fInst.Remove(p.Key);
      raise
     end;
     Inst.fValue := Result;
    finally
     ss.Free;
     ms.Free;
    end;
   end
  else raise Exception.Create('бытьнеможет');//  (Result as IManagItem).IName := Name;
end;

//class function TComponentModel.GetTextInstance(Inst: TInstance): string;
// var
//  ss: TStringStream;
//  ms: TMemoryStream;
//  icr: IInterfaceComponentReference;
//begin
//  if Assigned(inst.fValue) then
//   begin
//    ss := TStringStream.Create;
//    ms := TMemoryStream.Create;
//    try
//     if not Supports(Inst.fValue, IInterfaceComponentReference, icr) then raise EComponentModel.Create('IInterfaceComponentReference не поддерживается');
//     ms.WriteComponent((icr as IInterfaceComponentReference).GetComponent);
//     ms.Position := 0;
//     ObjectBinaryToText(ms, ss);
//     Result := ss.DataString;
//    finally
//     ss.Free;
//     ms.Free;
//    end;
//   end
//  else Result := inst.fText;
//  if Result ='' then raise EComponentModel.Create('TEXT не поддерживается');
//end;

type
  // Объявляем класс-взломщик прямо перед методом или в секции type модуля
  TControlHack = class(TControl);
class function TComponentModel.GetTextInstance(Inst: TInstance): string;
  var
  ss: TStringStream;
  ms: TMemoryStream;
  icr: IInterfaceComponentReference;
  LComponent: TComponent;
  LControl: TControl;
  LOriginalPPI: Integer;
begin
  if Assigned(inst.fValue) then
  begin
    ss := TStringStream.Create;
    ms := TMemoryStream.Create;
    try
      if not Supports(Inst.fValue, IInterfaceComponentReference, icr) then
        raise EComponentModel.Create('IInterfaceComponentReference не поддерживается');

      LComponent := icr.GetComponent;
      LControl := nil;
      LOriginalPPI := 96;

      // Проверяем, является ли компонент визуальным элементом (TControl)
      if LComponent is TControl then
      begin
        LControl := TControl(LComponent);
        LOriginalPPI := LControl.CurrentPPI;

        // Временно откатываем масштаб всего компонента к базовым 100% (96 DPI)
       TControlHack(LControl).ChangeScale(96, LOriginalPPI);
      end;

      try
        // Записываем компонент в "чистом" масштабе 100%
        ms.WriteComponent(LComponent);
        ms.Position := 0;
        ObjectBinaryToText(ms, ss);
        Result := ss.DataString;
      finally
        // ОБЯЗАТЕЛЬНО возвращаем текущий масштаб обратно,
        // чтобы интерфейс приложения не испортился на экране
        if LControl <> nil then
        begin
          TControlHack(LControl).ChangeScale(LOriginalPPI, 96);
        end;
      end;

    finally
      ss.Free;
      ms.Free;
    end;
  end
  else
    Result := inst.fText;

  if Result = '' then
    raise EComponentModel.Create('TEXT не поддерживается');
end;


function TComponentModel.GetInstance(const Name: string; Initialize: Boolean): IInterface;
 var
  v: TInstance;
begin
//  if fLiveTime <> ltSingletonNamed then raise Exception.Create(' <> ltSingletonNamed');
  Result := nil;
  if not Assigned(fInst) then Exit;
  if fInst.TryGetValue(Name, v) then
     Result := GetInstance(v, Initialize);
end;

procedure TComponentModel.InjectInstance(const Name: string);
 var
  i: TAttrInjection;
begin
  for i in fInstInject do i.aij.Inject(fInstanceType, i.member, i.a, Name);
end;

procedure TComponentModel.NillInstance(const Name: string);
 var
  v: TInstance;
begin
//  if fLiveTime <> ltSingletonNamed then raise Exception.Create(' <> ltSingletonNamed');
  fSingleton := nil;
  if not Assigned(fInst) then Exit;
  if fInst.TryGetValue(Name, v) then
   begin
    v.fText := GetTextInstance(v);
    v.fValue := nil;
   end;
end;

{$ENDREGION}

{$REGION 'TContainer'}

{ TContainer }

class constructor TContainer.Create;
begin
//  if Assigned(This) then Exit;
  RttiContext := TRttiContext.Create;
  This := TContainer.Create;
  GlobalCore := This;
end;
class destructor TContainer.Destroy;
begin
  This.Free;
  RttiContext.Free;
end;

constructor TContainer.Create;
begin
  FGuids := TGuidDict.Create;
  FServices := TServiceDict.Create;
  FModels := TModelDict.Create;
  FModels.fSrv := FServices;
end;

function TContainer.CreateValuedInstance<T>(const ClassName, ConstructorName: string; Data: T): IInterface;
 var
  model: PTypeInfo;
  m: TComponentModel;
  method: TRttiMethod;
  o: TObject;
begin
  Result := nil;
  model := GetModelType(ClassName);
  if Assigned(model) and FModels.TryGetValue(Model, m) then  for method in m.fInstanceType.GetMethods do
   if method.IsConstructor and (Length(method.GetParameters) = 1) and SameText(method.Name, ConstructorName) then
    begin
     o := method.Invoke(m.fInstanceType.MetaclassType, [TValue.From<T>(Data)]).AsObject;
     o.GetInterface(IInterface, Result);
     Exit;
    end;
end;

destructor TContainer.Destroy;
begin
  FModels.Free;
  FServices.Free;
  FGuids.Free;
end;

function TContainer._AddRef: Integer; begin Result := -1; end;
function TContainer._Release: Integer;begin Result := -1; end;
function TContainer.QueryInterface(const IID: TGUID; out Obj): HResult;
 var
  ms: TModels;
  s: ServiceType;
begin
  Result := E_NOINTERFACE;
  if GetInterface(IID, obj) then  Result := S_OK
  else if FGuids.TryGetValue(IID, s) and fServices.TryGetValue(s, ms) then
   begin
    Result := ms[0].GetInstance.QueryInterface(IID, Obj);
   end;
end;

function TContainer.Contains(cm: TComponentModel; InstanceName: string): Boolean;
begin
  Result := Assigned(cm.fInst) and cm.fInst.ContainsKey(InstanceName);
end;

procedure TContainer.AddTextInstance(serv: ServiceType; const InstanceText: string; Prior: Integer = 1000);
 var
  CName, IName: string;
  md: ModelType;
begin
  CName := GetClassName(InstanceText);
//  CName := Trim(Copy(InstanceText, Pos(':', InstanceText)+1, Pos(#$A, InstanceText)-Pos(':', InstanceText)-1));
  md := GContainer.GetModelType(CName);
  if not Assigned(md) then raise EContainer.CreateFmt('класс %s не найден',[CName]);
  IName := GetIName(InstanceText);
  TRegistration.Create(md).Add(Serv).AddInstance(IName, InstanceText, Prior);
end;

function TContainer.Contains(Model: ModelType; InstanceName: string): Boolean;
 var
  m: TComponentModel;
begin
  Result := FModels.TryGetValue(Model, m) and Contains(m, InstanceName);
end;

function TContainer.Contains(InstanceName: string): Boolean;
 var
  m: TComponentModel;
begin
  Result := False;
  for m in FModels.Values do if m.Contains(InstanceName) then Exit(True)
end;

function TContainer.TryFindComponentModel(Inst: IInterface; out cm: TComponentModel; out ip: TInstancePair): Boolean;
 var
  m: TComponentModel;
  i: TInstancePair;
begin
  Result := False;
  ip.Key := '';
  for m in FModels.Values do if m.fSingleton = Inst then 
    begin
     cm := m; 
     Exit(True)
    end
   else if Assigned(m.fInst) then for i in m.fInst do if i.Value.fValue = Inst then 
    begin
     cm := m; 
     ip := i;
     Exit(True)
    end    
end;

function TContainer.GetDynamicActionsNames(Inst: IInterface): TArray<string>;
 var
  cm: TComponentModel;
  ip: TInstancePair;
  ai: TAttrInjection;
begin
  if TryFindComponentModel(Inst, cm, ip) then 
   if ip.Key <> '' then 
    for ai in cm.fInstInject do                                                
     CArray.Add<string>(Result, Format('%s_%s', [ip.Key, ai.member.Name]))   
end;

function TContainer.TryGetAttrInjection(Attr: TCustomAttribute; out aid: IAttributeInjection): Boolean;
 var
  a: IAttributeInjection;
begin
  Result := False;
  for a in FAids do if a.Support(Attr) then
   begin
    aid := a;
    Exit(True);
   end;
end;

function TContainer.TryGetInstance(const InstanceName: string; out Obj: IInterface; Initialize: Boolean): Boolean;
 var
  m: TComponentModel;
begin
  Result := False;
  for m in FModels.Values do
   begin
    Obj := m.GetInstance(InstanceName, Initialize);
    if Assigned(Obj) then Exit(True);
   end;
end;

function TContainer.TryGetInstance(Model: ModelType; const InstanceName: string; out Obj: IInterface; Initialize: Boolean): Boolean;
 var
  m: TComponentModel;
begin
  if FModels.TryGetValue(Model, m) then Obj := m.GetInstance(InstanceName, Initialize)
  else  Obj := nil;
  Result := Assigned(Obj);
end;

function TContainer.TryGetInstance(Model: ModelType; out Obj: IInterface; Initialize: Boolean): Boolean;
 var
  m: TComponentModel;
begin
  if FModels.TryGetValue(Model, m) then Obj := m.GetInstance(Initialize)
  else  Obj := nil;
  Result := Assigned(Obj);
end;

function TContainer.TryGetInstKnownServ(serv: ServiceType; const InstanceName: string; out Obj: IInterface; Initialize: Boolean): Boolean;
 var
  m: TComponentModel;
  ms: TModels;
begin
  Result := False;
  if FServices.TryGetValue(Serv, ms) then
   begin
//   LastModel := ms[0];
    for m in ms do
     begin
    //  Tdebug.Log('fInst.Add %s %x %x',[m.fClassType.Name, Integer(@m), Integer(@m.fInst)]);
      Obj := m.GetInstance(InstanceName, Initialize);
      if Assigned(Obj) then Exit(True);
     end;
   end;
end;

function TContainer.TryGetInstRec(Model: ModelType; const InstanceName: string; out Rec: TInstanceRec): Boolean;
 var
  m: TComponentModel;
  i: TInstance;
begin
  Result := False;
  if FModels.TryGetValue(Model, m) and Assigned(m.fInst) and m.fInst.TryGetValue(InstanceName, i) then
   begin
    Rec := TInstanceRec.Create(i);
    Exit(True);
   end;
end;

function TContainer.TryGetInstRecKnownServ(serv: ServiceType; const InstanceName: string; out Rec: TInstanceRec): Boolean;
 var
  ms: TModels;
  i: TInstance;
begin
  Result := False;
  if FServices.TryGetValue(Serv, ms) and ms.TryGetTInstance(InstanceName, i) then
   begin
    Rec := TInstanceRec.Create( i);
    Exit(True);
   end;
end;

function TContainer.TryGetModelRTTI(Model: ModelType; out InstanceType: TRttiInstanceType): Boolean;
 var
  m: TComponentModel;
begin
  Result := FModels.TryGetValue(Model, m);
  if Result then InstanceType := m.fInstanceType;
end;

{$IFDEF MEMO_DEBUG}
procedure TContainer.UpdateDebugData(ss: TStrings);
 var
  m: TModelPair;
  ip: TInstancePair;
  ai: TAttrInjection;
  sp: TServicePair;
  mc: TComponentModel;
  s: string;
  function IntfToString(i: IInterface): string;
   var
    m: IManagItem;
    c: ICaption;
  begin
    if Assigned(i) then
     if Supports(i, IManagItem, m) then
      if Supports(i, ICaption, c) then Result := Format('[CLASS:%-10s CAPT:%-25s  Prio:%d]',[m.RootName, c.Text, m.Priority])
      else  Result := Format('[CLASS:%-10s INAME:%-25s  Prio:%d]',[m.RootName, m.IName, m.Priority])
     else Result := Format('[NOT IManagItem Ptr: %x]',[Integer(Pointer(i))])
    else Result := '[nil]'
  end;
  procedure AddDepend(const Pram: string; dps: TDependencies);
   var
    d: TDependency;
  begin
    for d in dps do ss.Add(Format(' +++ %s Dependency:[MODEL:%s SERV:%s NAME:%s]',[Pram, d.Model.Name,d.Service.Name, d.InstanceName]))
  end;
begin
  ss.Clear;
  ss.Add('**********    M O D E L S     ********');
  for m in FModels do
  begin
   ss.Add(string(m.Key.Name));
   case m.Value.LiveTime of
    ltAttribute: ss.Add('  LT:  ltAttribute');
    ltSingleton: ss.Add('  LT:  ltSingleton');
    ltTransient: ss.Add('  LT:  ltTransient');
    ltSingletonNamed: ss.Add('  LT:  ltSingleton Named');
    ltTransientNamed: ss.Add('  LT:  ltTransient Named');
   end;
   ss.Add('  Singleton: ' + IntfToString(m.Value.fSingleton));
   if Assigned(m.Value.fInst) then
    for ip in m.Value.fInst do
     ss.Add(Format('  -----  InstName: %-30s Intf: %-30s TXT: %s', [ip.Key , IntfToString(ip.Value.fValue), {ip.Value.fText}Copy(ip.Value.fText, 1, 20)]));
   AddDepend('CLASS', m.Value.fClsDependencies);
   AddDepend('INST_', m.Value.fInstDependencies);
   for ai in m.Value.fInstInject do
     ss.Add(Format(' +++ Injection:  member:%-10s  Attr:%-20s   aid:%S', [ai.member.Name, ai.a.ClassName, IntfToString(ai.aij)]));
   ss.Add('-------------------------------------------');
  end;
  ss.Add('**********    S E R V I C E S     ********');
  for sp in FServices do
   begin
    s := Format('[%:-20s]',[string(sp.Key.Name)]);
    for mc in sp.Value do s := s + ' '+ mc.fInstanceType.Name;
    ss.Add(s);
   end;
end;
{$ENDIF}

class function TContainer.GetClassName(const InstanceText: string): string;
begin
  Result := InstanceText.Substring(InstanceText.IndexOf(':')+1, InstanceText.IndexOf(#$A)-InstanceText.IndexOf(':')-1).Trim;
end;

class function TContainer.GetIName(const InstanceText: string): string;
begin
  Result := Trim(Copy(InstanceText, Pos(' ', InstanceText)+1, Pos(':', InstanceText)- Pos(' ', InstanceText)-1));
end;

function TContainer.GetModelLiveTime(Model: ModelType): TLiveTime;
 var
  m : TComponentModel;
begin
  Result := ltAttribute;
  if FModels.TryGetValue(Model, m) then Exit(m.LiveTime);
end;

function TContainer.GetModelType(const ClassName: string): ModelType;
 var
  mt: ModelType;
begin
  for mt in FModels.Keys do if SameText(string(mt.Name), ClassName) then Exit(mt);
  Result := nil;
end;

function TContainer.GetService(const IID: TGUID; out Obj): HResult;
begin
  Result := QueryInterface(IID,  Obj);
end;

function TContainer.GetService<Service>(out Obj): HResult;
 var
  ms: TModels;
  s: ServiceType;
begin
  Result := E_NOINTERFACE;
  s := TypeInfo(Service);
  if fServices.TryGetValue(s, ms) then Result := ms[0].GetInstance.QueryInterface(GetTypeData(s).Guid, Obj);
end;

procedure TContainer.RegisterAttrInjection(aid: IAttributeInjection);
begin
  CArray.Add<IAttributeInjection>(FAids, aid);
end;

procedure TContainer.RemoveInstance(const InstanceName: string);
 var
  m: TComponentModel;
begin
  for m in FModels.Values do
   if Assigned(m.fInst) and m.fInst.ContainsKey(InstanceName) then
    begin
     m.RemovInstance(InstanceName);
     Exit;
    end;
end;

procedure TContainer.RemoveInstance(model: ModelType; const InstanceName: string);
 var
  m: TComponentModel;
begin
  if GContainer.FModels.TryGetValue(model, m) then m.RemovInstance(InstanceName);
end;

procedure TContainer.RemoveInstKnownServ(serv: ServiceType; const InstanceName: string);
 var
  m: TComponentModel;
  ms: TModels;
begin
  if FServices.TryGetValue(Serv, ms) then for m in ms do if Contains(m, InstanceName) then
   begin
    m.RemovInstance(InstanceName);
    Exit;
   end;
end;

procedure TContainer.RemoveInstance(model: ModelType);
 var
  m: TComponentModel;
begin
  if FModels.TryGetValue(model, m) then m.fSingleton := nil;
end;

procedure TContainer.RemoveInstance<T>(const InstanceName: string);
 var
  m: TComponentModel;
begin
  if GContainer.FModels.TryGetValue(TypeInfo(T), m) then m.RemovInstance(InstanceName);
end;

procedure TContainer.RemoveInstances;
 var
  m: TComponentModel;
begin
  for m in FModels.Values do m.RemovInstances;
end;

procedure TContainer.RemoveInstKnownServ(serv: ServiceType);
 var
  m: TComponentModel;
  ms: TModels;
begin
  if FServices.TryGetValue(Serv, ms) then for m in ms do
   begin
    m.RemovInstances;
   end;
end;

procedure TContainer.RemoveModel<T>;
begin
  FModels.Remove(TypeInfo(T));
end;

procedure TContainer.RemoveModels;
begin
  FModels.Clear;
end;

{ TContainer.TEnumService<T> }

constructor TContainer.TEnumService<T>.Create(InitializeInstatces: Boolean = False);
begin
  i := -1;
  data := GContainer.InstancesAsArray<T>(InitializeInstatces);
end;

function TContainer.TEnumService<T>.DoGetCurrent: T;
begin
  Result := data[i];
end;

function TContainer.TEnumService<T>.DoMoveNext: Boolean;
begin
  Inc(i);
  Result := i < Length(data);
end;

function TContainer.TEnumService<T>.GetEnumerator: TEnumerator<T>;
begin
  Result := Self;
end;

{ TContainer.TEnumerService<T> }

{function TContainer.TEnumerService<T>.GetEnumerator: TEnumerator<T>;
begin
  Result := EnumService;
end;}

{function TContainer.InstancesAsNamedArray<Service>(InitializeInstatces: Boolean = False): TArray<TPair<string, Service>>;
 var
  ms: TModels;
  m: TComponentModel;
  st: ServiceType;
  s: Service;
  si: IInterface;
  Guid: TGUID;
  i: TInstancePair;
begin
  st := TypeInfo(Service);
  Guid := GetTypeData(st).Guid;
  if FServices.TryGetValue(st, ms) then
   for m in ms do
     if (m.LiveTime = ltSingletonNamed) then
       if Assigned(m.fInst) then
        for i in m.fInst do
          if Supports(m.GetInstance(i.Value, i.Key, InitializeInstatces), Guid, s) then CArray.Add<TPair<string, Service>>(Result, TPair<string, Service>.Create(i.Key, s));
end;}

function TContainer.TModelsInstComparer.Compare(const Left, Right: TModelsInst): Integer;
begin
  Result := Left.m.fModelPriority - Right.m.fModelPriority;
  if (Result = 0) and Assigned(Left.p.Value) and Assigned(Right.p.Value) then
      Result := Left.p.Value.Priority - Right.p.Value.Priority;
end;

class procedure TContainer.TModelsInstComparer.Add(var mi: TArray<TModelsInst>; cm: TComponentModel; ip: TInstancePair);
 var
  a: TModelsInst;
begin
  a.m := cm;
  a.p := ip;
  CArray.Add<TModelsInst>(mi, a);
end;

class procedure TContainer.TModelsInstComparer.Add(var mi: TArray<TModelsInst>; cm: TComponentModel);
 var
  a: TModelsInst;
begin
  a.m := cm;
  a.p.Value := nil;
  CArray.Add<TModelsInst>(mi, a);
end;

procedure TContainer.InjectDependences(const InstanceName: string);
 var
  m: TComponentModel;
begin
  for m in FModels.Values do
   if Assigned(m.fInst) and m.fInst.ContainsKey(InstanceName) then
    begin
     m.InjectInstance(InstanceName);
     Exit;
    end;
end;

function TContainer.InstancesAsArray<Service>(InitializeInstatces: Boolean): TArray<Service>;
 var
  mi: TArray<TModelsInst>;
  mis: TModelsInst;

  ms: TModels;
  m: TComponentModel;

  st: ServiceType;
  s: Service;
  si: IInterface;
  Guid: TGUID;

  i: TInstancePair;
begin
  st := TypeInfo(Service);
  Guid := GetTypeData(st).Guid;
  /// формирование массива объектов
  if FServices.TryGetValue(st, ms) then
   for m in ms do
     case m.LiveTime of

       ltSingleton:
        if Assigned(m.fSingleton) or InitializeInstatces then TModelsInstComparer.Add(mi, m);

       ltTransient:
        if InitializeInstatces then TModelsInstComparer.Add(mi, m);

       ltSingletonNamed:
        if Assigned(m.fInst) then
         for i in m.fInst do
          if Assigned(i.Value.fValue) or InitializeInstatces then TModelsInstComparer.Add(mi, m, i);

       ltTransientNamed:
        if InitializeInstatces and Assigned(m.fInst) then
         for i in m.fInst do TModelsInstComparer.Add(mi, m, i);
     end;
  ///  сортировка
  TArray.Sort<TModelsInst>(mi, TModelsInstComparer.Create);
  /// инициализация
  for mis in mi do
   begin
    si := nil;
    case mis.m.LiveTime of

     ltSingleton, ltTransient:

       if Assigned(mis.m.fSingleton) then si := mis.m.fSingleton
       else if InitializeInstatces then
        try
         si := mis.m.GetInstance(InitializeInstatces);
        except
         on E: Exception do TDebug.DoException(E);
        end;

     ltSingletonNamed, ltTransientNamed:

       if Assigned(mis.p.Value.fValue) then si := mis.p.Value.fValue
       else if InitializeInstatces then
        try
         si := mis.m.GetInstance(mis.p.Value, InitializeInstatces);
        except
         on E: Exception do TDebug.DoException(E);
        end;
    end;
    if Supports(si, Guid, s) then CArray.Add<Service>(Result, s);
   end;
///  old function
///  if FServices.TryGetValue(st, ms) then
///   for m in ms do
///     if (m.LiveTime = ltSingletonNamed) then
///      begin
///       if Assigned(m.fInst) then
///        for i in m.fInst do
///         try
///          if Supports(m.GetInstance(i.Value, InitializeInstatces), Guid, s) then
///            CArray.Add<Service>(Result, s);
///         except
///          on E: Exception do
///           begin
///            m.fInst.Remove(i.Key);
///            TDebug.DoException(E);
///           end;
///         end
///      end
///     else
///      begin
///       if InitializeInstatces then si := m.GetInstance
///       else si := m.fSingleton;
///       if Supports(si, Guid, s) then CArray.Add<Service>(Result, s);
///      end;
end;

function TContainer.InstancesAsArrayRec<Service>: TArray<TInstanceRec>;
 var
  ms: TModels;
  m: TComponentModel;
  st: ServiceType;
  s: Service;
  si: IInterface;
  i: TInstancePair;
begin
  st := TypeInfo(Service);
  if FServices.TryGetValue(st, ms) then
   for m in ms do
     if m.LiveTime in [ltSingletonNamed, ltTransientNamed] then
       if Assigned(m.fInst) then for i in m.fInst do
        try
         CArray.Add<TInstanceRec>(Result, TInstanceRec.Create(i.Value));
        except
         on E: Exception do TDebug.DoException(E, False);
        end;
end;

function TContainer.ModelsAsArray(Serv: ServiceType): TArray<ModelType>;
 var
  ms: TModels;
  m: TComponentModel;
begin
  if FServices.TryGetValue(Serv, ms) then
   for m in ms do CArray.Add<ModelType>(Result, m.fClassType);
end;

function TContainer.ModelsAsArray<Service>: TArray<ModelType>;
begin
  Result := ModelsAsArray(TypeInfo(Service));
end;

procedure TContainer.NillInstance(model: ModelType; const InstanceName: string);
 var
  m: TComponentModel;
begin
  if GContainer.FModels.TryGetValue(model, m) then m.nillInstance(InstanceName);
end;

procedure TContainer.NillInstKnownServ(serv: ServiceType; const InstanceName: string);
 var
  m: TComponentModel;
  ms: TModels;
begin
  if FServices.TryGetValue(Serv, ms) then for m in ms do if Contains(m, InstanceName) then
   begin
    m.NillInstance(InstanceName);
    Exit;
   end;
end;

function TContainer.Enum<Service>(InitializeInstatces: Boolean): TEnumService<Service>;
begin
  Result := TEnumService<Service>.Create(InitializeInstatces);
end;
{$ENDREGION}

{$REGION 'Registration'}

{ TRegister}

class function TRegister.AddType<T, I1, I2, I3, I4, I5, I6, I7, I8, I9>: TRegistration<T>;
begin
  Result.fRegist := TRegistration.Create(TypeInfo(T));
  Result.Add<I1, I2, I3,I4,I5,I6,I7,I8,I9>;
end;

class function TRegister.AddType<T, I1, I2, I3, I4, I5, I6, I7, I8>: TRegistration<T>;
begin
  Result.fRegist := TRegistration.Create(TypeInfo(T));
  Result.Add<I1, I2, I3,I4,I5,I6,I7,I8>;
end;

class function TRegister.AddType<T, I1, I2, I3, I4, I5, I6, I7>: TRegistration<T>;
begin
  Result.fRegist := TRegistration.Create(TypeInfo(T));
  Result.Add<I1, I2, I3,I4,I5,I6,I7>;
end;

class function TRegister.AddType<T, I1, I2, I3, I4, I5, I6>: TRegistration<T>;
begin
  Result.fRegist := TRegistration.Create(TypeInfo(T));
  Result.Add<I1, I2, I3,I4,I5,I6>;
end;

class function TRegister.AddType<T, I1, I2, I3, I4, I5>: TRegistration<T>;
begin
  Result.fRegist := TRegistration.Create(TypeInfo(T));
  Result.Add<I1, I2, I3,I4,I5>;
end;

class function TRegister.AddType<T, I1, I2, I3, I4>: TRegistration<T>;
begin
  Result.fRegist := TRegistration.Create(TypeInfo(T));
  Result.Add<I1, I2, I3,I4>;
end;

class function TRegister.AddType<T, I1, I2, I3>: TRegistration<T>;
begin
  Result.fRegist := TRegistration.Create(TypeInfo(T));
  Result.Add<I1, I2, I3>;
end;

class function TRegister.AddType<T, I1, I2>: TRegistration<T>;
begin
  Result.fRegist := TRegistration.Create(TypeInfo(T));
  Result.Add<I1, I2>;
end;

class function TRegister.AddType<T, I1>: TRegistration<T>;
begin
  Result.fRegist := TRegistration.Create(TypeInfo(T));
  Result.Add<I1>;
end;

class function TRegister.AddType<T>: TRegistration<T>;
begin
  Result.fRegist := TRegistration.Create(TypeInfo(T));
end;

{ TRegistration }

constructor TRegistration.Create(ClassType: PTypeInfo);
 var
  m: TComponentModel;
begin
  fClassType := ClassType;
  if not GContainer.FModels.TryGetValue(ClassType, m) then
   begin
    m := TComponentModel.Create(fClassType);
    GContainer.FModels.Add(ClassType, m);
   end;
  fModel := m;
end;

function TRegistration.Add(Srv: PTypeInfo): TRegistration;
 var
  ms: TModels;
begin
  Result := Self;
  GContainer.FGuids.AddOrSetValue(GetTypeData(Srv).Guid, Srv);
  if not GContainer.FServices.TryGetValue(Srv, ms) then
   begin
    ms := TModels.Create;
    GContainer.FServices.Add(Srv, ms);
   end;
  if not ms.Contains(fModel) then ms.Add(fModel);
end;

function TRegistration.AddInstance(const Inst: IInterface): TRegistration;
begin
  Result := Self;
  fModel.fSingleton := Inst;
  fModel.fLiveTime := ltSingleton;
end;

function TRegistration.AddInstance(const Name: string; const Inst: IInterface): TRegistration;
begin
  Result := Self;
  fModel.AddInstance(Name, Inst);
end;

function TRegistration.AddInstance(const Name, Inst: string; Prior: Integer = 1000): TRegistration;
begin
  Result := Self;
  fModel.AddInstance(Name, Inst, Prior);
end;

function TRegistration.LiveTime(const lt: TLiveTime): TRegistration;
begin
  Result := Self;
  fModel.fLiveTime := lt;
end;

{ TRegistration<T> }

function TRegistration<T>.Add<I1, I2, I3, I4, I5, I6, I7, I8, I9>: TRegistration<T>;
begin
  Result := Self;
  fRegist.Add(TypeInfo(I1)).Add(TypeInfo(I2)).Add(TypeInfo(I3)).Add(TypeInfo(I4)).Add(TypeInfo(I5)).Add(TypeInfo(I6)).Add(TypeInfo(I7)).Add(TypeInfo(I8)).Add(TypeInfo(I9));
end;

function TRegistration<T>.Add<I1, I2, I3, I4, I5, I6, I7, I8>: TRegistration<T>;
begin
  Result := Self;
  fRegist.Add(TypeInfo(I1)).Add(TypeInfo(I2)).Add(TypeInfo(I3)).Add(TypeInfo(I4)).Add(TypeInfo(I5)).Add(TypeInfo(I6)).Add(TypeInfo(I7)).Add(TypeInfo(I8));
end;

function TRegistration<T>.Add<I1, I2, I3, I4, I5, I6, I7>: TRegistration<T>;
begin
  Result := Self;
  fRegist.Add(TypeInfo(I1)).Add(TypeInfo(I2)).Add(TypeInfo(I3)).Add(TypeInfo(I4)).Add(TypeInfo(I5)).Add(TypeInfo(I6)).Add(TypeInfo(I7));
end;

function TRegistration<T>.Add<I1, I2, I3, I4, I5, I6>: TRegistration<T>;
begin
  Result := Self;
  fRegist.Add(TypeInfo(I1)).Add(TypeInfo(I2)).Add(TypeInfo(I3)).Add(TypeInfo(I4)).Add(TypeInfo(I5)).Add(TypeInfo(I6));
end;

function TRegistration<T>.Add<I1, I2, I3, I4, I5>: TRegistration<T>;
begin
  Result := Self;
  fRegist.Add(TypeInfo(I1)).Add(TypeInfo(I2)).Add(TypeInfo(I3)).Add(TypeInfo(I4)).Add(TypeInfo(I5));
end;

function TRegistration<T>.Add<I1, I2, I3, I4>: TRegistration<T>;
begin
  Result := Self;
  fRegist.Add(TypeInfo(I1)).Add(TypeInfo(I2)).Add(TypeInfo(I3)).Add(TypeInfo(I4));
end;

function TRegistration<T>.Add<I1, I2, I3>: TRegistration<T>;
begin
  Result := Self;
  fRegist.Add(TypeInfo(I1)).Add(TypeInfo(I2)).Add(TypeInfo(I3));
end;

function TRegistration<T>.Add<I1, I2>: TRegistration<T>;
begin
  Result := Self;
  fRegist.Add(TypeInfo(I1)).Add(TypeInfo(I2));
end;

function TRegistration<T>.Add<I1>: TRegistration<T>;
begin
  Result := Self;
  fRegist.Add(TypeInfo(I1));
end;

function TRegistration<T>.AddInstance(const Name: string): TRegistration<T>;
begin
  Result := Self;
  fRegist.fModel.AddInstance(Name, '');
end;

function TRegistration<T>.AddInstance(const Name: string; const Inst: IInterface): TRegistration<T>;
begin
  Result := Self;
  fRegist.fModel.AddInstance(Name, Inst);
end;

function TRegistration<T>.AddInstance(const Name, Inst: string; Prior: Integer = 1000): TRegistration<T>;
begin
  Result := Self;
  fRegist.fModel.AddInstance(Name, Inst, Prior);
end;

function TRegistration<T>.AddInstance(const Inst: IInterface): TRegistration<T>;
begin
  Result := Self;
  fRegist.fModel.fSingleton := Inst;
  fRegist.fModel.fLiveTime := ltSingleton;
end;

function TRegistration<T>.LiveTime(const lt: TLiveTime): TRegistration<T>;
begin
  Result := Self;
  fRegist.fModel.fLiveTime := lt;
end;

function TRegistration<T>.SingletonPriority(const pr: Integer): TRegistration<T>;
begin
  Result := Self;
  fRegist.fModel.fModelPriority := pr;
end;

{$ENDREGION}

end.

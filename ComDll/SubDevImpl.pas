unit SubDevImpl;

interface

uses System.SysUtils,  System.Classes, System.TypInfo, System.Rtti,
     System.Bindings.Helper,
     Actns, DeviceIntf, AbstractDev, debug_except, ExtendIntf, Container, PluginAPI, RootImpl, RootIntf;

type
   ISetCollection = interface
   ['{2248E634-5DD9-48B1-B525-035E06AA3755}']
     procedure SetCollection(Value: TCollection);
     procedure SetIndex(Value: Integer);
   end;

   TRootDevice = class;
   TSubDev = class(TICollectionItem, ISubDevice, ISetCollection, ICaption, IManagItem, IInterfaceComponentReference)
   private
     FIName: string;
   protected
     FChildSubDevice: TSubDev;
     FParentSubDevice: TSubDev;
     IsLoaded: Boolean;
//     procedure SetChild(SubDevice: ISubDevice); virtual;

     function GetComponent: TComponent;
  // IManagItem
     function Priority: Integer;
     function Model: ModelType;
     function RootName: String;
     procedure SetItemName(const Value: String);
     function GetItemName: string;

     function GetCategory: TSubDeviceInfo; virtual; abstract;
     function GetCaption: string; virtual; abstract;

     function GetDeviceName: string;
     procedure SetDeviceName(const Value: string);
     function ICaption.GetCaption = GetDeviceName;
     procedure ICaption.SetCaption = SetDeviceName;

     procedure BeforeRemove(); virtual;

     procedure Extract(); virtual;
     procedure Insert(Index: Integer); virtual;

     procedure OnUserRemove; virtual;

     procedure SetChildSubDevice(const Value: TSubDev); virtual;
     procedure SetParentSubDevice(const Value: TSubDev); virtual;

     function GetUniqueCaption(const Capt: string): string;

     procedure Loaded; virtual;

   public
     procedure InputData(Data: Pointer; DataSize: integer); virtual; abstract;
     procedure DeleteData(DataSize: integer); virtual;
     constructor Create; reintroduce; overload; virtual;
     constructor Create(Collection: TCollection); overload; override; final;
     destructor Destroy; override;
     function GetOwner1: TRootDevice; inline;
     property Category: TSubDeviceInfo read GetCategory;
     property Caption: string read GetCaption;
     property Owner: TRootDevice read GetOwner1;
     property ChildSubDevice: TSubDev read FChildSubDevice write SetChildSubDevice;
     property ParentSubDevice: TSubDev read FParentSubDevice write SetParentSubDevice;
   published
     property IName: String read GetItemName write SetItemName;
   end;

   TSubDev<T> = class(TSubDev, ISubDevice<T>)
   protected
     FS_Data: T;
     function GetData: T;
     procedure NotifyData;
   public
     property S_Data: T read GetData write FS_Data;
   end;


   TSubDevWithForm<T> = class(TSubDev<T>, ISubDevice<T>)
   protected
     FFormClassName: string;
     FPrefixFormName: string;
     function TryGetSubDevForm(const model, prefix: string; out F: IForm; NeedCreate: Boolean = False): Boolean;
     procedure InitConst(const aFormClass, aPrefixFormName{, aPropertyName}: string);
     procedure RemoveUserForm; virtual;
     procedure BeforeRemove(); override;
     procedure OnUserRemove; override;
     procedure DoSetup(Sender: IAction); virtual;
   end;

  TSubDevCollection = class(TICollection)
  private
    FOwner: TIComponent;
  public
    constructor Create(Owner: TIComponent); reintroduce;
   public
     property OwnerDevice: TIComponent read FOwner;
  end;

  TRootDevice = class(TAbstractDevice, IRootDevice, INotifyBeforeRemove)
  private
    FS_Add: ISubDevice;
    function TryFindAvailIndex(const Category: string; out idx: Integer; needFreeUniqe: boolean): Boolean;
    procedure UpdateParents(check: Boolean = false);
    procedure SetS_Add(const Value: ISubDevice);
    procedure SetS_Remove(const Value: ISubDevice);
  protected
    FSubDevs: TSubDevCollection;
    procedure DefineProperties(Filer: TFiler); override;
    function GetSubDevices: TArray<ISubDevice>;
    function Index(SubDevice: ISubDevice): Integer;
    procedure Remove(Index: Integer);
    function AddOrReplase(SubDeviceType: ModelType): ISubDevice;
    function TryMove(SubDevice: ISubDevice; UpTrueDownFalse: Boolean): Boolean;
    function GetService: PTypeInfo; virtual; abstract;
    function GetStructure: TArray<TSubDeviceInfo>; virtual; abstract;
    procedure Loaded; override;
    procedure BeforeRemove(); virtual;
  public
    constructor Create(); override;
    destructor Destroy; override;
    procedure DoSetup(Sender: IAction); virtual;
    property SubDevices: TArray<ISubDevice> read GetSubDevices;
    property S_Add: ISubDevice read FS_Add write SetS_Add;
    property S_Remove: ISubDevice read FS_Add write SetS_Remove;
  end;

implementation

procedure TRootDevice.BeforeRemove;
 var
  c: TCollectionItem;
begin
  for c in FSubDevs do TSubDev(c).BeforeRemove();
  ((GContainer as IFormEnum) as IStorable).Save;
end;

constructor TRootDevice.Create;
begin
  inherited;
  FSubDevs := TSubDevCollection.Create(Self);
  FStatus := dsReady;
end;

procedure TRootDevice.DefineProperties(Filer: TFiler);
begin
  inherited;
  FSubDevs.RegisterProperty(Filer, 'SubDevs');
end;

procedure TRootDevice.UpdateParents(check: Boolean = false);
 var
  i: Integer;
begin
  if FSubDevs.Count = 0 then Exit;
  if check then
   begin
    if TSubDev(FSubDevs.Items[0]).FParentSubDevice <> nil then
     begin
      Tdebug.Log('TSubDev(FSubDevs.Items[0]).FParentSubDevice <> nil');
     end;
    if TSubDev(FSubDevs.Items[FSubDevs.Count-1]).FChildSubDevice <> nil then
     begin
      Tdebug.Log('TSubDev(FSubDevs.Items[FSubDevs.Count-1]).FChildSubDevice <> nil');
     end;
    for i := 1 to FSubDevs.Count-1 do
     begin
      if TSubDev(FSubDevs.Items[i-1]).FChildSubDevice <> TSubDev(FSubDevs.Items[i]) then
       begin
        TDebug.Log('%s C %s  <> %s', [
          TSubDev(FSubDevs.Items[i-1]).caption,
          TSubDev(FSubDevs.Items[i-1]).FChildSubDevice.caption,
          TSubDev(FSubDevs.Items[i]).Caption]);
       end;
      if TSubDev(FSubDevs.Items[i]).FParentSubDevice <> TSubDev(FSubDevs.Items[i-1]) then
       begin
        TDebug.Log('%s P %s <> %s', [
          TSubDev(FSubDevs.Items[i]).caption,
          TSubDev(FSubDevs.Items[i]).FParentSubDevice.caption,
          TSubDev(FSubDevs.Items[i-1]).Caption]);
       end;
     end;
    Exit;
   end;
  TSubDev(FSubDevs.Items[0]).ParentSubDevice := nil;
  TSubDev(FSubDevs.Items[FSubDevs.Count-1]).ChildSubDevice := nil;
  for i := 1 to FSubDevs.Count-1 do
   begin
    TSubDev(FSubDevs.Items[i-1]).ChildSubDevice := TSubDev(FSubDevs.Items[i]);
    TSubDev(FSubDevs.Items[i]).ParentSubDevice := TSubDev(FSubDevs.Items[i-1]);
   end;
end;

destructor TRootDevice.Destroy;
 var
  c: TCollectionItem;
begin
  for c in FSubDevs do GContainer.RemoveInstance(c.ClassInfo, TSubDev(c).IName);
  FSubDevs.Free;
  if Assigned(IConnect) then
   begin
    ConnectIO.FTimerRxTimeOut.Enabled := False;
    ConnectIO.FEventReceiveData := nil;
   end;
  inherited;
//  try
//   (GContainer as IActionProvider).UpdateWidthBars;
//  except
//   on E: Exception do TDebug.DoException(E);
//  end;
end;

function TRootDevice.AddOrReplase(SubDeviceType: ModelType): ISubDevice;
 var
  i: Integer;
  II:IInterface;
  c: string;
begin
  Result := nil;
  if GContainer.TryGetInstance(SubDeviceType, ii) then
   begin
    Supports(II, ISubDevice, Result);
    if TryFindAvailIndex(Result.Category.Category, i, True) then
     begin
      (Result as ISetCollection).SetCollection(FSubDevs);
      Result.Caption;
      (Result as ISetCollection).SetIndex(i);
      TSubDev(Result).Insert(i);
      TRegistration.Create(SubDeviceType).LiveTime(ltTransientNamed).Add(GetService).AddInstance(Result.IName, Result as IInterface);
     // Update Parents;
      MainScreenChanged;
      S_Add := Result;
     end
    else
     begin
      c := Result.Category.Category;
      TObject(Result).Free;
      raise EBaseException.CreateFmt('Категория неподдерживается %s', [c]);
     end;
   end;
end;

procedure TRootDevice.DoSetup(Sender: IAction);
 var
  d: Idialog;
begin
  if RegisterDialog.TryGet<Dialog_SetupRootDevice>(d) then (d as IDialog<IRootDevice>).Execute(Self as IRootDevice);
end;

function TRootDevice.GetSubDevices: TArray<ISubDevice>;
 var
  i: Integer;
begin
  SetLength(Result, FSubDevs.Count);
  for i := 0 to FSubDevs.Count-1 do Result[i] := TICollectionItem(FSubDevs.Items[i]) as ISubDevice;
end;

procedure TRootDevice.Loaded;
 var
  c: TCollectionItem;
begin
  inherited;
  for c in FSubDevs do
   begin
    TRegistration.Create(c.ClassInfo).Add(GetService).AddInstance(TSubDev(c).IName, TSubDev(c) as IInterface);
   end;
  UpdateParents;
  for c in FSubDevs do TSubDev(c).Loaded;
end;

function TRootDevice.Index(SubDevice: ISubDevice): Integer;
 var
  i: Integer;
begin
  Result := -1;
  for i := 0 to FSubDevs.Count-1 do if TSubDev(FSubDevs.Items[i]) as ISubDevice = SubDevice then Exit(i);
end;

procedure TRootDevice.Remove(Index: Integer);
begin
  GContainer.RemoveInstKnownServ(GetService(), TSubDev(FSubDevs.Items[Index]).IName);
  TSubDev(FSubDevs.Items[Index]).OnUserRemove;
  S_Remove := TSubDev(FSubDevs.Items[Index]) as ISubDevice;
  FSubDevs.Delete(Index);
//  Update Parents;
  MainScreenChanged;
end;

procedure TRootDevice.SetS_Add(const Value: ISubDevice);
begin
  FS_Add := Value;
  try
   TBindings.Notify(Self, 'S_Add');
  finally
   FS_Add := nil;
  end;
end;

procedure TRootDevice.SetS_Remove(const Value: ISubDevice);
begin
  FS_Add := Value;
  try
   TBindings.Notify(Self, 'S_Remove');
  finally
   FS_Add := nil;
  end;
end;

function TRootDevice.TryFindAvailIndex(const Category: string; out idx: Integer; needFreeUniqe: boolean): Boolean;
 var
  si: TSubDeviceInfo;
  sd: TSubDev;
begin
  idx := 0;
  for si in GetStructure do if si.Category = Category then
   begin
    if needFreeUniqe and (idx < FSubDevs.Count)
      and (TSubDev(FSubDevs.Items[idx]).GetCategory.Category = Category)
      and (sdtUniqe in TSubDev(FSubDevs.Items[idx]).GetCategory.Typ) then
       begin
        sd := TSubDev(FSubDevs.Items[idx]);
        sd.BeforeRemove;
        S_Remove := sd as ISubDevice;
        GContainer.RemoveInstKnownServ(GetService(), sd.IName);
        FSubDevs.Delete(idx);
       end;
    Exit(True);
   end
   else while (idx < FSubDevs.Count) and (TSubDev(FSubDevs.Items[idx]).GetCategory.Category = si.Category) do inc(idx);
  Result := False;
end;

function TRootDevice.TryMove(SubDevice: ISubDevice; UpTrueDownFalse: Boolean): Boolean;
 var
  i: Integer;
  function ChIndex(old, new: Integer): Boolean;
   var
    sd: TSubDev;
  begin
    sd := TSubDev(FSubDevs.Items[old]);
    sd.Extract;
    sd.Index := new;
    sd.Insert(new);
    //UpdateParents(True);
    Result := True;
  end;
begin
  Result := False;
  for i := 0 to FSubDevs.Count-1 do if TSubDev(FSubDevs.Items[i]) as ISubDevice = SubDevice then
   begin
    if UpTrueDownFalse and (i-1 > 0) and (TSubDev(FSubDevs.Items[i-1]).GetCategory.Category = SubDevice.Category.Category) then Exit(ChIndex(i, i-1));
    if not UpTrueDownFalse and (i+1 < FSubDevs.Count) and (TSubDev(FSubDevs.Items[i+1]).GetCategory.Category = SubDevice.Category.Category) then Exit(ChIndex(i, i+1));
   end;
end;

{ TSubDev }

constructor TSubDev.Create;
begin
 // TDebug.Log('TSubDev.Create  %s  %s  %s', [IName, Category.Category, Caption]);
end;

constructor TSubDev.Create(Collection: TCollection);
begin
  inherited;
  IsLoaded := True;
  Create;
  IsLoaded := False;
end;

destructor TSubDev.Destroy;
begin
 // TDebug.Log('TSubDev.Destroy  %s  %s  %s', [IName, Category.Category, Caption]);
  TBindHelper.RemoveExpressions(Self);
  inherited;
end;

procedure TSubDev.DeleteData(DataSize: integer);
begin
end;

procedure TSubDev.Insert(Index: Integer);
begin
  if Index > 0 then ParentSubDevice := TSubDev(Collection.Items[Index-1])
  else ParentSubDevice := nil;

  if Index < Collection.Count-1 then ChildSubDevice := TSubDev(Collection.Items[Index+1])
  else ChildSubDevice := nil;
end;

procedure TSubDev.Loaded;
begin

end;

function TSubDev.Model: ModelType;
begin
  Result := ClassInfo;
end;

procedure TSubDev.Extract;
begin
  if Assigned(FParentSubDevice) then FParentSubDevice.ChildSubDevice := FChildSubDevice;
  if Assigned(FChildSubDevice) then  FChildSubDevice.ParentSubDevice := FParentSubDevice;
  FParentSubDevice := nil;
  FChildSubDevice := nil;
end;

procedure TSubDev.BeforeRemove;
begin
  Extract()
end;

procedure TSubDev.OnUserRemove;
begin
  Extract()
end;

function TSubDev.Priority: Integer;
begin
  Result := 300;
end;

function TSubDev.RootName: String;
begin
 Result := ClassName.Substring(1)
end;

function TSubDev.GetComponent: TComponent;
begin
  Result := Owner;
end;

function TSubDev.GetDeviceName: string;
begin
  Result := (TSubDevCollection(Collection).FOwner as ICaption).Text;
end;

function TSubDev.GetItemName: string;
begin
  if FIName = '' then FIName := RootName + FormatDateTime('yymdhnsz', now);
  Result := FIName;
end;

function TSubDev.GetOwner1: TRootDevice;
begin
  if Assigned(Collection) then Result := TRootDevice(TSubDevCollection(Collection).OwnerDevice)
  else Result := nil;
end;

function TSubDev.GetUniqueCaption(const Capt: string): string;
 var
   slf: ISubDevice;
   n: Integer;
  function Chcpt(const C: string): Boolean;
   var
    s: ISubDevice;
  begin
    if not Assigned(Owner) then Exit(False);
    Result := False;
    for s in Owner.SubDevices do if (s <> slf) and SameText(c, s.Caption) then Exit(True);
  end;
begin
  slf := Self as ISubDevice;
  Result := Capt;
  n := 0;
  while Chcpt(Result) do
   begin
    Inc(n);
    Result := Capt + ' ' + n.ToString();
   end;
end;

procedure TSubDev.SetChildSubDevice(const Value: TSubDev);
begin
  FChildSubDevice := Value;
  if Assigned(Value) and (Value.ParentSubDevice <> Self) then Value.ParentSubDevice := Self;
end;

procedure TSubDev.SetParentSubDevice(const Value: TSubDev);
begin
  FParentSubDevice := Value;
  if Assigned(Value) and (Value.ChildSubDevice <> Self) then Value.ChildSubDevice := Self;
end;

procedure TSubDev.SetDeviceName(const Value: string);
begin
  raise Exception.Create('Error Writing programm call procedure TSubDev.SetDeviceName(const Value: string);');
end;

procedure TSubDev.SetItemName(const Value: String);
begin
  FIName := Value;
end;

{ TSubDevCollection }

constructor TSubDevCollection.Create(Owner: TIComponent);
begin
  inherited Create(TSubDev);
  FOwner := Owner;
end;

{ TSubDevWithForm }

procedure TSubDevWithForm<T>.BeforeRemove;
begin
  inherited;
  RemoveUserForm;
end;

procedure TSubDevWithForm<T>.OnUserRemove;
begin
  inherited;
  RemoveUserForm;
end;

function TSubDevWithForm<T>.TryGetSubDevForm(const model, prefix: string; out F: IForm; NeedCreate: Boolean = False): Boolean;
 var
  m: ModelType;
  s: string;
begin
  Result := False;
  s := prefix + IName;
  F := (Gcontainer as IformEnum).Get(s);
  if Assigned(F) then Exit(True);
  m := GContainer.GetModelType(model);
  if Assigned(m) and NeedCreate then
    begin
     F := TIForm.NewForm(m, s);
     Result := Assigned(F);
     if Result then (Gcontainer as IformEnum).Add(F);
    end
end;

procedure TSubDevWithForm<T>.RemoveUserForm;
 var
  FormData: IForm;
begin
//  TBindHelper.RemoveSourceExpressions(Self, ['S_Data']);
  if TryGetSubDevForm(FFormClassName, FPrefixFormName, FormData) then
   begin
    (Gcontainer as IformEnum).Remove(FormData);
    ((Gcontainer as IformEnum) as IStorable).Save;
   end;
end;

procedure TSubDevWithForm<T>.DoSetup(Sender: IAction);
 var
  FormData: IForm;
begin
  if TryGetSubDevForm(FFormClassName, FPrefixFormName, FormData, True) then
   begin
    (FormData as IControlForm).ControlName := Owner.Name;
    (FormData as IRootControlForm).SubControlName := IName;
//    TBindHelper.RemoveSourceExpressions(Self, ['S_Data']);
//    TBindHelper.Bind(TObject(FormData),'C_Data', Self as IInterface, ['S_Data']);
    FormData.Show;
   end;
end;

procedure TSubDevWithForm<T>.InitConst(const aFormClass, aPrefixFormName{, aPropertyName}: string);
begin
  FFormClassName := aFormClass;
  FPrefixFormName := aPrefixFormName;
//  FPropertyName := aPropertyName;
end;

//procedure TSubDevWithForm<T>.Loaded;
// var
//  FormData: IForm;
//begin
//  if TryGetSubDevForm(FFormClass, FPrefixFormName, FormData) then
//   begin
//    TBindHelper.Bind(TObject(FormData),'C_Data', Self as IInterface, ['S_Data']);
//   end;
//end;

procedure TSubDev<T>.NotifyData;
begin
  TBindings.Notify(Self, 'S_Data');
end;

function TSubDev<T>.GetData: T;
begin
  Result := FS_Data;
end;

//procedure TSubDev<T>.BeforeRemove;
//begin
//  TBindHelper.RemoveSourceExpressions(Self, ['S_Data']);
//end;

//procedure TSubDev<T>.OnUserRemove;
//begin
//  TBindHelper.RemoveSourceExpressions(Self, ['S_Data']);
//end;

end.

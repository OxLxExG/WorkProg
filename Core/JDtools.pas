unit JDtools;

interface

uses
     debug_except, RootIntf, PluginAPI, ExtendIntf, Container, RootImpl,  System.UITypes, Xml.XMLIntf,
     Vcl.Controls, Vcl.Graphics, Vcl.ComCtrls, Winapi.Messages, Vcl.Forms, Winapi.Windows, JvInspector,JvResources,
     System.SyncObjs,

     System.Classes, System.SysUtils, System.TypInfo,
     System.Generics.Defaults,
     System.Generics.Collections,
     System.Bindings.Expression,
     System.Bindings.EvalProtocol,
     System.Bindings.Helper,
     System.Bindings.Outputs,
     RTTI;

type
  TJvInspectorStringItemEx = class(TJvInspectorStringItem)
  protected
    procedure Apply; override;
  public
    procedure DrawValue(const ACanvas: TCanvas); override;
  end;

  TJvInspectorIntegerItemEx = class(TJvInspectorIntegerItem)
  protected
    procedure Apply; override;
  public
    procedure DrawValue(const ACanvas: TCanvas); override;
  end;

  TJvInspectorFloatItemEx = class(TJvInspectorFloatItem)
  protected
    procedure Apply; override;
  public
    procedure DrawValue(const ACanvas: TCanvas); override;
  end;

  EnumCaptionsAttribute = class;
  TJvInspectorEnumCaptionsItem = class(TJvInspectorEnumItem)
  private
    FCaptions: TArray<string>;
  protected
    procedure Apply; override;
    function GetDisplayValue: string; override;
    procedure GetValueList(const Strings: TStrings); override;
    procedure SetDisplayValue(const Value: string); override;
  public
    constructor Create(const AParent: TJvCustomInspectorItem; const AData: TJvCustomInspectorData); override;
    procedure DrawValue(const ACanvas: TCanvas); override;
  end;

  EnumCaptionsAttribute = class (TCustomAttribute)
  private
    FCaptions: TArray<string>;
  public
    constructor Create(const ACaptions: string);
    property Captions: TArray<string> read FCaptions;
  end;



  TJvInspectorArrayPropData = class(TJvInspectorPropData)
   type
    TGetPropProc<T> = function(Instance: TObject; PropInfo: PPropInfo): T;
  private
    FBefoSet, FAfteSet: TNotifyEvent;
    FInstances: TArray<TObject>;
    FLastGetAsDifferent: Boolean;
    FApplyin: Boolean;
  protected
    function GetAsFloat: Extended; override;
    function GetAsInt64: Int64; override;
    function GetAsOrdinal: Int64; override;
    function GetAsString: string; override;
    function GetAsVariant: Variant; override;
    function GetAs<T>(a0: T; GetProp: TGetPropProc<T>): T;

    procedure SetAsFloat(const Value: Extended); override;
    procedure SetAsInt64(const Value: Int64); override;
    procedure SetAsOrdinal(const Value: Int64); override;
    procedure SetAsString(const Value: string); override;
    procedure SetAsVariant(const Value: Variant); override;
  public
    class function New(const AParent: TJvCustomInspectorItem; const AObjs: TArray<TObject>; PropInfo: PPropInfo;
                       BefoSet, AfteSet: TNotifyEvent): TJvCustomInspectorItem; reintroduce;
    function IsAssigned: Boolean; override;
  end;

  ShowPropAttribute = class (TCustomAttribute)
  private
    FDisplayName: string;
    FReadOnly: Boolean;
    class var RttiContext : TRttiContext;
    class function StrObj2Str(inst: TObject; const s: string): string;
    class procedure ApplyItem(root: TJvCustomInspectorItem; o: TObject); static;
    class procedure ApplyItemArray(root: TJvCustomInspectorItem; o: TArray<TObject>; BefoSet, AfteSet: TNotifyEvent); static;
    class procedure ApplyICollection(root: TJvCustomInspectorItem; cl: TICollection); static;
    class procedure ApplyList(root: TJvCustomInspectorItem; cl: TObject; ItemType: TRttiType); static;
  public
   constructor Create(const ADisplayName: String; AReadOnly: Boolean = False);
   class procedure Apply(Obj: TObject; Insp: TJvInspector); overload;
   class procedure Apply(Obj: TArray<TObject>; Insp: TJvInspector; BefoSet, AfteSet: TNotifyEvent); overload;
   property DisplayName: string read FDisplayName write FDisplayName;
   property ReadOnly: Boolean read FReadOnly write FReadOnly;
  end;

  /// для SERIAL_NO
  TJvInspectorOptionDataEvent = reference to procedure(Item: TJvCustomInspectorItem; Option: IXMLNode; var Data: IXMLNode);
  TJvInspectorOptionData = class(TJvInspectorCustomConfData)
  private
    /// не атрибут а XMLNode
    FDataNode: IXMLNode;
    FOption: IXMLNode;
  protected
    function GetAsFloat: Extended; override;
    procedure SetAsFloat(const Value: Extended); override;
    function ExistingValue: Boolean; override;
    procedure WriteValue(const Value: string); override;
    class function ToTypeInfo(atip: Integer): PTypeInfo; overload;
    class function ToTypeInfo(Option: IXMLNode): PTypeInfo; overload;
  public
    function ReadValue: string; override;
    class function New1(const AParent: TJvCustomInspectorItem;
          DataNode, Option: IXMLNode; AOnAddOPtion: TJvInspectorOptionDataEvent): TJvCustomInspectorItem;
    class function New(const AParent: TJvCustomInspectorItem;
          RootDataNode, RootOption: IXMLNode; AOnAddOPtion: TJvInspectorOptionDataEvent): TJvInspectorItemInstances; reintroduce;
  end;
  IDialogOptions = IDialog<IXMLNode, IXMLNode, TJvInspectorOptionDataEvent, TDialogResult>;

procedure SetInspectorItemFont(Item: TJvCustomInspectorItem; const ACanvas: TCanvas);

implementation

uses tools;

{$REGION 'TJvInspectorXXXXXItemEx'}

{ TJvInspectorStringItemEx }

procedure SetInspectorItemFont(Item: TJvCustomInspectorItem; const ACanvas: TCanvas);
begin
  with Item do if (Data is TJvInspectorArrayPropData) and Data.IsAssigned then
   begin
    DisplayValue;
    if TJvInspectorArrayPropData(Data).FLastGetAsDifferent then
     begin
      ACanvas.Font.Color := clGrayText;
      ACanvas.Font.Style := ACanvas.Font.Style - [fsBold];
     end;
   end;
end;

procedure TJvInspectorStringItemEx.Apply;
begin
  if Data is TJvInspectorArrayPropData then TJvInspectorArrayPropData(Data).FApplyin := True;
  inherited Apply;
end;

procedure TJvInspectorStringItemEx.DrawValue(const ACanvas: TCanvas);
begin
  SetInspectorItemFont(Self, ACanvas);
  inherited DrawValue(ACanvas);
end;


{ TJvInspectorIntegerItemEx }

procedure TJvInspectorIntegerItemEx.Apply;
begin
  if Data is TJvInspectorArrayPropData then TJvInspectorArrayPropData(Data).FApplyin := True;
  inherited Apply;
end;

procedure TJvInspectorIntegerItemEx.DrawValue(const ACanvas: TCanvas);
begin
  SetInspectorItemFont(Self, ACanvas);
  inherited DrawValue(ACanvas);
end;


{ TJvInspectorFloatItemEx }

procedure TJvInspectorFloatItemEx.Apply;
begin
  if Data is TJvInspectorArrayPropData then TJvInspectorArrayPropData(Data).FApplyin := True;
  inherited Apply;
end;

procedure TJvInspectorFloatItemEx.DrawValue(const ACanvas: TCanvas);
begin
  SetInspectorItemFont(Self, ACanvas);
  inherited DrawValue(ACanvas);
end;


{ EnumCaptionsAttribute }

constructor EnumCaptionsAttribute.Create(const ACaptions: string);
 var
  i: Integer;
begin
  FCaptions := ACaptions.Split([',',';']);
  for I := 0 to High(FCaptions) do FCaptions[i] := FCaptions[i].Trim;
end;

{ TJvInspectorEnumCaptionsItem }

procedure TJvInspectorEnumCaptionsItem.Apply;
begin
  if Data is TJvInspectorArrayPropData then TJvInspectorArrayPropData(Data).FApplyin := True;
  inherited Apply;
end;

constructor TJvInspectorEnumCaptionsItem.Create(const AParent: TJvCustomInspectorItem; const AData: TJvCustomInspectorData);
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

procedure TJvInspectorEnumCaptionsItem.DrawValue(const ACanvas: TCanvas);
begin
  SetInspectorItemFont(Self, ACanvas);
  inherited DrawValue(ACanvas);
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
end;
{$ENDREGION}

{$REGION 'ShowPropAttribute'}

{ ShowPropAttribute }
type
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

constructor ShowPropAttribute.Create(const ADisplayName: String; AReadOnly: Boolean);
begin
  FDisplayName := ADisplayName;
  FReadOnly := AReadOnly;
end;

class procedure ShowPropAttribute.Apply(Obj: TObject; Insp: TJvInspector);
begin
  Insp.Clear;
  Insp.Root.SortKind := iskNone;
  RttiContext := TRttiContext.Create;
  try
   ApplyItem(Insp.Root, Obj);
  finally
   RttiContext.Free;
  end;
end;

class procedure ShowPropAttribute.Apply(Obj: TArray<TObject>; Insp: TJvInspector; BefoSet, AfteSet: TNotifyEvent);
 var
  i: Integer;
begin
  for i := Length(Obj)-1 downto 0 do if not Assigned(Obj[i]) then Delete(Obj, 0, 1);
  if Length(Obj) = 0 then Exit
  else if Length(Obj) = 1 then Apply(Obj[0], Insp)
  else
   begin
    Insp.Clear;
    Insp.Root.SortKind := iskNone;
    RttiContext := TRttiContext.Create;
    try
     ApplyItemArray(Insp.Root, Obj, BefoSet, AfteSet);
    finally
     RttiContext.Free;
    end;
   end;
end;

class function ShowPropAttribute.StrObj2Str(inst: TObject; const s: string): string;
begin
  if Supports(inst, ICaption) then Result := ''
  else Result := '('+s+')';
end;

class procedure ShowPropAttribute.ApplyItem(root: TJvCustomInspectorItem; o: TObject);
 var
  t : TRttiType;
  p : TRttiProperty;
  a : TCustomAttribute;
  ii: TJvCustomInspectorItem;
  oo: TObject;
  s: string;
  ic: ICaption;
  c: TClass;
  ast: TArray<string>;
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
       if Supports(oo, ICaption, ic) then
        begin
         ii := TCustomInspectorDataClassName.New(Root, '', TypeInfo(string));
         ii.DisplayName := ic.Text;
        end
       else
        begin
         ii := TCustomInspectorDataClassName.New(Root, StrObj2Str(oo, s), TypeInfo(string));
         ii.DisplayName := ShowPropAttribute(a).DisplayName;
        end;
       ii.SortKind := iskNone;
       ii.Expanded := True;
       ii.ReadOnly := True;
       if Assigned(oo) then
       if oo is TICollection then ApplyICollection(ii,  TICollection(oo))
       else
        begin
         c := oo.ClassType;
         while c <> nil do
          begin
           if c.ClassName.Contains('TEnumerable<') then
            begin
             ast := c.ClassName.Split(['<','>']);
             if Length(ast) = 2 then ApplyList(ii,  oo, RttiContext.FindType(ast[1]));
             Break;
            end;
           c := c.ClassParent;
          end;
        end;
       ApplyItem(ii, oo);
      end
     else
      begin
       ii := TJvInspectorPropData.New(Root, o, TRttiInstanceProperty(p).PropInfo);
       ii.DisplayName := ShowPropAttribute(a).DisplayName;
       ii.ReadOnly := ShowPropAttribute(a).ReadOnly or not p.IsWritable;
       if ii is TJvInspectorBooleanItem then TJvInspectorBooleanItem(ii).ShowAsCheckbox := True;
      end;
end;

class procedure ShowPropAttribute.ApplyList(root: TJvCustomInspectorItem; cl: TObject; ItemType: TRttiType);
 var
  o: TObject;
  ii: TJvCustomInspectorItem;
  s: string;
  ca: ICaption;
begin
  if ItemType.TypeKind = tkClass then  
  for o in TEnumerable<TObject>(cl) do
   begin
    if Supports(o, ICaption, ca) then s := ca.Text
    else s := 'Item';
    ii := TCustomInspectorDataClassName.New(Root, StrObj2Str(o, o.ClassName), TypeInfo(string));
    ii.DisplayName := s;
    ii.SortKind := iskNone;
    ii.Expanded := True;
    ii.ReadOnly := True;
    ApplyItem(ii, o);
   end;
end;

class procedure ShowPropAttribute.ApplyICollection(root: TJvCustomInspectorItem; cl: TICollection);
 var
  ii: TJvCustomInspectorItem;
  ci: TCollectionItem;
  s: string;
  ca: ICaption;
begin
//  if Supports(cl, ICaption, ca) then s := ca.Text
//  else s := 'Items';
//  Root := TCustomInspectorDataClassName.New(Root, '', TypeInfo(string));
//  Root.DisplayName := s;
//  Root.SortKind := iskNone;
//  Root.Expanded := True;
//  Root.ReadOnly := True;
  for ci in cl do
   begin
    if Supports(ci, ICaption, ca) then s := ca.Text
    else s := 'Item';
    ii := TCustomInspectorDataClassName.New(Root, StrObj2Str(ci, ci.ClassName), TypeInfo(string));
    ii.DisplayName := s;
    ii.SortKind := iskNone;
    ii.Expanded := True;
    ii.ReadOnly := True;
    ApplyItem(ii, ci);
   end;
end;

class procedure ShowPropAttribute.ApplyItemArray(root: TJvCustomInspectorItem; o: TArray<TObject>; BefoSet, AfteSet: TNotifyEvent);
 type
  Tsp = record
   a: ShowPropAttribute;
   p: TRttiProperty;
   cnt: Integer;
  end;
 var
  t : TRttiType;
  p : TRttiProperty;
  a : TCustomAttribute;
  ii: TJvCustomInspectorItem;
  i, j: Integer;
  aa: TArray<Tsp>;
  function GetTsp(atr: TCustomAttribute; prp: TRttiProperty): Tsp;
  begin
    Result.a := ShowPropAttribute(atr);
    Result.p := prp;
    Result.cnt := 0;
  end;
begin
  SetLength(aa, 0);
  t := RttiContext.GetType(o[0].ClassType);
  // заполнение
  for p in t.getProperties do
   for a in p.GetAttributes do
    if (a is ShowPropAttribute) and (p.PropertyType.TypeKind <> tkClass) then Carray.add<Tsp>(aa, GetTsp(a,p));
  // удаление не найденых
  for i := 1 to Length(o)-1 do
   begin
    t := RttiContext.GetType(o[i].ClassType);
     for p in t.getProperties do
      for a in p.GetAttributes do
       if (a is ShowPropAttribute) and (p.PropertyType.TypeKind <> tkClass) then
         for j := 0 to Length(aa)-1 do if (aa[j].a = ShowPropAttribute(a)) and (aa[j].p = p) then
          begin
           inc(aa[j].cnt);
           Break
          end;
    for j := Length(aa)-1 downto 0 do
     if aa[j].cnt = 0 then Delete(aa, 0, 1)
     else aa[j].cnt := 0;
   end;
  // отрисовка
  for i := 0 to Length(aa)-1 do
   begin
    ii := TJvInspectorArrayPropData.New(Root, o, TRttiInstanceProperty(aa[i].p).PropInfo, BefoSet, AfteSet);
    ii.DisplayName := aa[i].a.DisplayName;
    ii.ReadOnly := aa[i].a.ReadOnly or not aa[i].p.IsWritable;
    if ii is TJvInspectorBooleanItem then TJvInspectorBooleanItem(ii).ShowAsCheckbox := True;
   end;
  SetLength(aa, 0);
end;

{$ENDREGION}

{$REGION 'TJvInspectorArrayPropData'}

{ TJvInspectorArrayPropData }

class function TJvInspectorArrayPropData.New(const AParent: TJvCustomInspectorItem; const AObjs: TArray<TObject>; PropInfo: PPropInfo;
                  BefoSet, AfteSet: TNotifyEvent): TJvCustomInspectorItem;
var
  Data: TJvInspectorArrayPropData;
  RegItem: TJvCustomInspectorRegItem;
begin
  if PropInfo = nil then  raise EJvInspectorData.CreateRes(@RsEJvAssertPropInfo);
  Data := CreatePrim(string(PropInfo.Name), PropInfo.PropType^);
  Data.FBefoSet := BefoSet;
  Data.FAfteSet := AfteSet;
  Data.Instance := AObjs[0];
  Data.FInstances := AObjs;
  Data.Prop := PropInfo;
  Data := TJvInspectorArrayPropData(DataRegister.Add(Data));
  if Data <> nil then
   begin
    RegItem := TypeInfoMapRegister.FindMatch(Data);
    if (RegItem <> nil) and (RegItem is TJvInspectorTypeInfoMapperRegItem) then
      Data.TypeInfo := TJvInspectorTypeInfoMapperRegItem(RegItem).NewTypeInfo;
    Result := Data.NewItem(AParent);
   end
  else
    Result := nil;
end;

function TJvInspectorArrayPropData.GetAs<T>(a0: T; GetProp: TGetPropProc<T>): T;
 var
  a: TArray<T>;
  i: Integer;
begin
  SetLength(a, Length(FInstances));
  FLastGetAsDifferent := False;
  a[0] := a0;
  for i := 1 to High(a) do
   begin
    a[i] := GetProp(FInstances[i], Prop);
    if not TEqualityComparer<T>.Default.Equals(a[i], a0) then FLastGetAsDifferent := True;
   end;
  TArray.Sort<T>(a);
  Result := a[Length(a) div 2];
end;

function TJvInspectorArrayPropData.GetAsFloat: Extended;
begin
  Result := GetAs<Extended>(inherited, GetFloatProp);
end;

function TJvInspectorArrayPropData.GetAsInt64: Int64;
begin
  Result := GetAs<Int64>(inherited, GetInt64Prop);
end;

function TJvInspectorArrayPropData.GetAsOrdinal: Int64;
begin
  Result := GetAs<NativeInt>(inherited, GetOrdProp);
end;

function TJvInspectorArrayPropData.GetAsString: string;
begin
  Result := GetAs<string>(inherited, GetStrProp);
end;

function TJvInspectorArrayPropData.GetAsVariant: Variant;
begin
  Result := GetAs<Variant>(inherited, GetVariantProp);
end;

function TJvInspectorArrayPropData.IsAssigned: Boolean;
begin
  Result := inherited and not (FApplyin and FLastGetAsDifferent);
  FApplyin := False;
end;

procedure TJvInspectorArrayPropData.SetAsFloat(const Value: Extended);
 var
  o: TObject;
begin
  if Assigned(FBefoSet) then FBefoSet(Self);
  try
   inherited;
   for o in FInstances do SetFloatProp(o, Prop, Value);
  finally
   if Assigned(FAfteSet) then FAfteSet(Self);
  end;
end;

procedure TJvInspectorArrayPropData.SetAsInt64(const Value: Int64);
 var
  o: TObject;
begin
  if Assigned(FBefoSet) then FBefoSet(Self);
  try
  inherited;
  for o in FInstances do SetInt64Prop(o, Prop, Value)
  finally
   if Assigned(FAfteSet) then FAfteSet(Self);
  end;
end;

procedure TJvInspectorArrayPropData.SetAsOrdinal(const Value: Int64);
 var
  o: TObject;
begin
  if Assigned(FBefoSet) then FBefoSet(Self);
  try
  inherited SetAsOrdinal(Value);
  for o in FInstances do
   if GetTypeData(Prop.PropType^).OrdType = otULong then
      SetOrdProp(o, Prop, Cardinal(Value))
    else
      SetOrdProp(o, Prop, Value);
  finally
   if Assigned(FAfteSet) then FAfteSet(Self);
  end;
end;

procedure TJvInspectorArrayPropData.SetAsString(const Value: string);
 var
  o: TObject;
begin
  if Assigned(FBefoSet) then FBefoSet(Self);
  try
  inherited;
  for o in FInstances do SetStrProp(o, Prop, Value)
  finally
   if Assigned(FAfteSet) then FAfteSet(Self);
  end;
end;

procedure TJvInspectorArrayPropData.SetAsVariant(const Value: Variant);
 var
  o: TObject;
begin
  if Assigned(FBefoSet) then FBefoSet(Self);
  try
  inherited;
  for o in FInstances do SetVariantProp(o, Prop, Value)
  finally
   if Assigned(FAfteSet) then FAfteSet(Self);
  end;
end;

{$ENDREGION TJvInspectorArrayPropData}

{$REGION 'TJvInspectorOptionData'}

{ TJvInspectorOptionData }

function TJvInspectorOptionData.ExistingValue: Boolean;
begin
  if not FDataNode.HasAttribute(key) then FDataNode.Attributes[key] := FOption.Attributes['Значение'];
  Result := True;
end;

function TJvInspectorOptionData.ReadValue: string;
begin
  Result := FDataNode.Attributes[key];
end;

procedure TJvInspectorOptionData.SetAsFloat(const Value: Extended);
begin
  CheckReadAccess;
  if TypeInfo = System.TypeInfo(TDateTime) then WriteValue(DateTimeToStr(Value))
  else if TypeInfo = System.TypeInfo(TTime) then WriteValue(TimeToStr(Value))
  else if TypeInfo = System.TypeInfo(TDate) then WriteValue(DateToStr(Value))
  else inherited
end;

class function TJvInspectorOptionData.ToTypeInfo(Option: IXMLNode): PTypeInfo;
 var
  i: Integer;
begin
  if Option.HasAttribute('DataType') then i := StrToIntDef(Option.Attributes['DataType'], 0) else i := 0;
  Result := ToTypeInfo(i);
end;

class function TJvInspectorOptionData.ToTypeInfo(atip: Integer): PTypeInfo;
begin
  case atip of
   PRG_TIP_INT      : Result := System.TypeInfo(Integer);
   PRG_TIP_REAL     : Result := System.TypeInfo(Double);
   PRG_TIP_DATE_TIME: Result := System.TypeInfo(TDateTime);
   PRG_TIP_DATE     : Result := System.TypeInfo(TDate);
   PRG_TIP_TIME     : Result := System.TypeInfo(TTime);
   PRG_TIP_BOOL     : Result := System.TypeInfo(Boolean);
   else               Result := System.TypeInfo(string);
  end;
end;

procedure TJvInspectorOptionData.WriteValue(const Value: string);
begin
  FDataNode.Attributes[key] := Value;
end;

class function TJvInspectorOptionData.New1(const AParent: TJvCustomInspectorItem; DataNode, Option: IXMLNode; AOnAddOPtion: TJvInspectorOptionDataEvent): TJvCustomInspectorItem;
 var
  Data: TJvInspectorOptionData;
begin
  if not Assigned(DataNode) or not Assigned(Option) then raise EJvInspectorData.CreateRes(@RsEDataSetDataSourceIsUnassigned);
  if Option.HasAttribute('Hidden') and (Option.Attributes['Hidden'] = '1') then Exit(nil);

  Data := CreatePrim(Option.Attributes['Описание'], Option.ParentNode.Attributes['Категория'], Option.NodeName, ToTypeInfo(Option));
  Data.FDataNode := DataNode;
  Data.FOption := Option;
  Data := TJvInspectorOptionData(DataRegister.Add(Data));
  if Data <> nil then
   begin
    Result := Data.NewItem(AParent);
    if Option.HasAttribute('ReadOnly') then Result.ReadOnly := Option.Attributes['ReadOnly'] = '1';
    if Result is TJvInspectorBooleanItem then TJvInspectorBooleanItem(Result).ShowAsCheckbox := True;
    if Assigned(AOnAddOPtion) then AOnAddOPtion(Result, Option, DataNode);
    Data.FDataNode := DataNode;
   end
  else
    Result := nil;
end;

function TJvInspectorOptionData.GetAsFloat: Extended;
 var
  d: TDateTime;
begin
  if (TypeInfo = System.TypeInfo(TDateTime)) or (TypeInfo = System.TypeInfo(TTime)) or(TypeInfo = System.TypeInfo(TDate)) then
   begin
    CheckReadAccess;
    if TryStrToFloat(FDataNode.Attributes[key], Result) then Exit;
    if TryStrToDateTime(FDataNode.Attributes[key], d) then Exit(d);
    Result := Now;
   end
  else Result := inherited
end;

class function TJvInspectorOptionData.New(const AParent: TJvCustomInspectorItem; RootDataNode, RootOption: IXMLNode; AOnAddOPtion: TJvInspectorOptionDataEvent): TJvInspectorItemInstances;
 var
  TmpItem: TJvCustomInspectorItem;
  CatItem: TJvInspectorCustomCategoryItem;
  c,o: IXMLNode;
  Res: TArray<TJvCustomInspectorItem>;
begin
  for c in XEnum(RootOption) do
   begin
    CatItem := TJvInspectorCustomCategoryItem.Create(AParent, nil);
    CatItem.Name := c.NodeName; // the internal value.  <BUGFIX OCT 23, 2003: WAP.>
    CatItem.DisplayName := c.Attributes['Категория']; // The displayed value
    CatItem.SortKind := iskNone;
    CatItem.Expanded := True;
    for o in XEnum(c) do
     begin
      TmpItem := New1(CatItem, RootDataNode, o, AOnAddOPtion);
      if Assigned(TmpItem) then CArray.Add<TJvCustomInspectorItem>(Res, TmpItem);
     end;
   end;
   Result := TJvInspectorItemInstances(Res);
end;

{$ENDREGION}

initialization
  with TJvCustomInspectorData.ItemRegister do
   begin
    Delete(TJvInspectorEnumItem);
    Delete(TJvInspectorFloatItem);
    Delete(TJvInspectorIntegerItem);
    Delete(TJvInspectorStringItem);

    Add(TJvInspectorTypeKindRegItem.Create(TJvInspectorEnumCaptionsItem, tkEnumeration));
    Add(TJvInspectorTypeKindRegItem.Create(TJvInspectorFloatItemEx, tkFloat));

    Add(TJvInspectorTypeKindRegItem.Create(TJvInspectorIntegerItemEx, tkInteger));
    {$IFDEF UNICODE}
    Add(TJvInspectorTypeKindRegItem.Create(TJvInspectorStringItemEx, tkUString));
    {$ENDIF UNICODE}
    Add(TJvInspectorTypeKindRegItem.Create(TJvInspectorStringItemEx, tkLString));
    Add(TJvInspectorTypeKindRegItem.Create(TJvInspectorStringItemEx, tkWString));
    Add(TJvInspectorTypeKindRegItem.Create(TJvInspectorStringItemEx, tkString));
//    Add(TJvInspectorTypeInfoRegItem.Create(TJvInspectorStringItemEx, System.TypeInfo(string)));

    Add(TJvInspectorTypeInfoRegItem.Create(TJvInspectorBooleanItem, System.TypeInfo(Boolean)));
    Add(TJvInspectorTypeInfoRegItem.Create(TJvInspectorBooleanItem, System.TypeInfo(ByteBool)));
    Add(TJvInspectorTypeInfoRegItem.Create(TJvInspectorBooleanItem, System.TypeInfo(WordBool)));
    Add(TJvInspectorTypeInfoRegItem.Create(TJvInspectorBooleanItem, System.TypeInfo(LongBool)));
   end;
end.

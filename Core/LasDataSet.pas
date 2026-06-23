unit LasDataSet;

interface

uses System.Classes, sysutils, System.Variants, Data.DB, IDataSets, LasImpl, LAS, DataSetIntf, Container, JDtools, System.IOUtils;

type
  TLASDataSetDef = class(TIDataSetDef)
  private
    FLasFile: string;
    FEncoding: LasEncoding;
  public
    constructor CreateUser(const FileName: string; AEncoding: LasEncoding);
    function TryGet(out ids: IDataSet): Boolean; override;
    function CreateNew(out ids: IDataSet; UniDirectional: Boolean = True): Boolean; override;
  published
   [ShowProp('Encoding')] property Encoding: LasEncoding read FEncoding write FEncoding;
   [ShowProp('LAS file', True)] property LasFile: string read FLasFile write FLasFile;
  end;

  TLasDataSet = class(TRLDataSet)
  private
    FlasDoc: ILasDoc;
    FLasFile: string;
    FEncoding: LasEncoding;
    procedure SetLasFile(const Value: string);
    procedure SetEncoding(const Value: LasEncoding);
    function GetFlasDoc: ILasDoc;
  protected
    function GetTempDir: string; override;
    function GetRecordCount: Integer; override;
    procedure InternalClose; override;
    procedure InternalOpen; override;
//    function GetFileName: string; override;
  public
    function GetFieldData(Field: TField; var Buffer: TValueBuffer): Boolean; override;
    procedure UpdateFields();
/// <summary>
///  {week reference container}
/// </summary>
    class procedure New(const FileName: string; out Res: IDataSet; Encoding: LasEncoding = lsenANSI);
//  published
  public
    property LasFile: string read FLasFile write SetLasFile;
    property LasDoc: ILasDoc read GetFlasDoc;
    property Encoding: LasEncoding read FEncoding write SetEncoding;
  end;

implementation

{ TLasDataSet }

class procedure TLasDataSet.New(const FileName: string; out Res: IDataSet; Encoding: LasEncoding = lsenANSI);
 var
  ii: IInterface;
begin
//  if not (GContainer as IDataSetEnum).TryFind(FileName, Res) then
  if GContainer.TryGetInstance(ClassInfo, FileName, ii, False) then Res := ii as IDataSet
  else
   begin
    Res := Create as IDataSet;
    TLasDataSet(Res.DataSet).Encoding := Encoding;
    TLasDataSet(Res.DataSet).LasFile := FileName;
    TRegistration.Create(ClassInfo).AddInstance(FileName, Res);
    TLasDataSet(Res.DataSet).WeekContainerReference := True;
   end;
end;

function TLasDataSet.GetFieldData(Field: TField; var Buffer: TValueBuffer): Boolean;
 var
  p: PRecBuffer;
  v: Variant;
  s: string;
begin
  Result := True;
  if not GetActiveRecBuf(p) then Exit(False);
  if Field.FieldName = 'ID' then
   begin
    SetLength(Buffer, Sizeof(Integer));
    PInteger(@Buffer[0])^ := p.ID;
   end
  else
   begin
    SetLength(Buffer, Sizeof(Double));
    v := FlasDoc[Field.FieldName,  p.ID-1];
    if VarIsNull(v) then PDouble(@Buffer[0])^ := Double.NaN
    else
     begin
      if VarIsNumeric(V) then PDouble(@Buffer[0])^ := Double(v)
      else
       begin
        s := v;
        SetLength(Buffer, s.Length);
        Move(s[1], Buffer[0], Length(Buffer));
       end;
     end;
   end;
end;

//function TLasDataSet.GetFileName: string;
//begin
//  Result := FLasFile;
//end;

function TLasDataSet.GetFlasDoc: ILasDoc;
begin
  if not Assigned(FlasDoc) then  FlasDoc := GetLasDoc(LasFile, Encoding);
  Result := FlasDoc;
end;

function TLasDataSet.GetRecordCount: Integer;
begin
  if not Assigned(FlasDoc) then  FlasDoc := GetLasDoc(LasFile, Encoding);
  Result := FlasDoc.DataCount;
end;

procedure TLasDataSet.InternalClose;
begin
  FlasDoc := nil;
  inherited;
end;

procedure TLasDataSet.InternalOpen;
begin
  inherited;
  FlasDoc := GetLasDoc(LasFile, Encoding);
end;

procedure TLasDataSet.SetEncoding(const Value: LasEncoding);
begin
  if FEncoding <> Value then
   begin
    if IsCursorOpen then Close;
    FLasFile := '';
    FEncoding := Value;
    FieldDefs.Clear;
   end;
end;

procedure TLasDataSet.SetLasFile(const Value: string);
// var
//  s: string;
//  d: ILasDoc;
begin
  if FLasFile <> Value then
   begin
    if IsCursorOpen then Close;
    FLasFile := Value;
    if not (csLoading in ComponentState) then
     begin
     UpdateFields;
//      d := GetLasDoc(LasFile, Encoding);
//      FieldDefs.Clear;
//      FieldDefs.Add('ID', ftInteger);
//      for s in d.Curve.Mnems do
//       begin
//        FieldDefs.Add(s, ftFloat);
//       end;
     end;
   end;
end;

procedure TLasDataSet.UpdateFields;
 var
  s: string;
begin
      FieldDefs.Clear;
      FieldDefs.Add('ID', ftInteger);
      for s in GetLasDoc(LasFile, Encoding).Curve.Mnems do
       begin
        FieldDefs.Add(s, ftFloat);
       end;
end;

function TLASDataSet.GetTempDir: string;
begin
  Result := TPath.GetDirectoryName(LasFile)+'\' + TPath.GetFileNameWithoutExtension(LasFile) +'\';
end;

{ TLASDataSetDef }

function TLASDataSetDef.CreateNew(out ids: IDataSet; UniDirectional: Boolean): Boolean;
begin
  ids := TLASDataSet.Create as IDataSet;
  TLasDataSet(ids.DataSet).Encoding := Encoding;
  TLasDataSet(ids.DataSet).LasFile := LasFile;
  TLasDataSet(ids.DataSet).SetUniDirectional(UniDirectional);
  Result := True;
end;

constructor TLASDataSetDef.CreateUser(const FileName: string; AEncoding: LasEncoding);
begin
  FLasFile := FileName;
  FEncoding := AEncoding;
end;

function TLASDataSetDef.TryGet(out ids: IDataSet): Boolean;
begin
  TLasDataSet.New(LasFile, ids);
  Result := Assigned(ids);
end;

initialization
  RegisterClasses([TLasDataSet, TLASDataSetDef]);
  TRegister.AddType<TLasDataSet, IDataSet>.LiveTime(ltSingletonNamed);
finalization
  GContainer.RemoveModel<TLasDataSet>;
end.

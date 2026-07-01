unit CustomPlot.DataLink;

interface

uses
  RootImpl, RootIntf, tools, debug_except, ExtendIntf, FileCachImpl, JDtools, Container,
  Data.DB, DataSetIntf, IDataSets, FileDataSet,
  System.Bindings.Helper, System.IOUtils,
  System.TypInfo, System.UITypes, Vcl.Grids, SysUtils, Controls, Messages,
  Winapi.Windows, Classes, System.Rtti, types, Vcl.Graphics, Vcl.Forms, Vcl.ExtCtrls,
  Vcl.Menus, Vcl.Themes, Vcl.GraphUtil, System.SyncObjs;

type
  {$REGION 'DataLink'}

  TFindIndexType = (fndLower, fndHiger, fndNear);

    IDataLink = interface
    ['{1D667235-A468-4DEA-B1AD-4EEF12F4BA25}']
    function IndexOfY(Y: Double; IndexOfType: TFindIndexType; out Yfind: Double): Integer;
  end;

  IDataLinkBuffer = interface(IDataLink)
    ['{F63650B6-13AE-497D-AF7D-373E0D1981F8}']
  //private
    function GenerateBufferFileName: string;
    procedure SetDrowMemoryBuffer(const Value: IInterface);
    function GetDrowMemoryBuffer: IInterface;
  //public
    procedure ResetBuffer;
  /// <summary>
  /// некое хранилище готовых для рендеринга данных массив точек single, fixed для линии или битмап GR32, DGI+ для ФКД
  /// </summary>
    property DrowMemoryBuffer: IInterface read GetDrowMemoryBuffer write SetDrowMemoryBuffer;
    property BufferFileName: string read GenerateBufferFileName;
  end;

  /// <summary>
  /// привязка к проекту БД, las, lines, или директории с файлами Log Ram Glu
  /// или к файлу активного фильтра
  /// </summary>
  TCustomDataLinkClass = class of TCustomDataLink;

  TCustomDataLink = class(TDataSetFactory, IDataLink, ICaption)
  private
    FOwner: TObject;
   // FIDataSet: IDataSet;
//    FDataSetDef: TIDataSetDef;
    FXParamPath: string;
    FYParamPath: string;
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
    function IndexOfY(Y: Double; FindIndexType: TFindIndexType; out YFind: Double): Integer;
    procedure NillDataSet;
    function GetCaption: string; virtual;
    procedure SetCaption(const Value: string);
  public
    constructor Create(AOwner: TObject); virtual;
    destructor Destroy; override;
    property Owner: TObject read FOwner;
//    property DataSet: TDataSet read GetDataSet;
//    property DataSetIntf: IDataSet read GetIDataSet;
    property FieldX: TField read GetXField write FFieldX;
    property FieldY: TField read GetYField write FFieldY;
    property XFieldDef: TFieldDef read GetXFieldDef write FXFieldDef;

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

  TCustomDataLinkBuffer = class(TCustomDataLink, IDataLinkBuffer)
  private
    FDrowMemoryBuffer: IInterface;
    procedure SetDrowMemoryBuffer(const Value: IInterface);
    function GetDrowMemoryBuffer: IInterface;
  protected
    function GenerateBufferFileName: string; virtual;
  public
    procedure ResetBuffer; virtual;
    property BufferFileName: string read GenerateBufferFileName;
    property DrowMemoryBuffer: IInterface read GetDrowMemoryBuffer write SetDrowMemoryBuffer;
  end;

implementation

uses  CustomPlot;
{ TCustomDataLink }

constructor TCustomDataLink.Create(AOwner: TObject);
begin
  FOwner := AOwner;
  Tdebug.log(' ===  TCustomDataLink.Create === ');
end;

destructor TCustomDataLink.Destroy;
begin
  Tdebug.log(' ===  TCustomDataLink.Destroy === ' + XParamPath + '      ');
  inherited;
end;

function TCustomDataLinkBuffer.GenerateBufferFileName: string;
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

procedure TCustomDataLinkBuffer.ResetBuffer;
begin

end;

{function TCustomDataLink.GetDataSetClass: string;
begin
  if Assigned(FDataSetDef) then
    Result := FDataSetDef.ClassName
  else
    Result := '';
end;}

function TCustomDataLinkBuffer.GetDrowMemoryBuffer: IInterface;
begin
  Result := FDrowMemoryBuffer;
end;

procedure TCustomDataLinkBuffer.SetDrowMemoryBuffer(const Value: IInterface);
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
  TGraphPar(owner).Graph.UpdateData;
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

end.

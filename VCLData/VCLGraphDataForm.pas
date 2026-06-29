unit VCLGraphDataForm;

interface


{$INCLUDE global.inc}

uses  VCL.CustomDataForm, Container, ExtendIntf, Actns,
  CustomPlot,
  CustomPlot.DataLink,
  plot.GR32.Data,
  plot.GR32.Legend,
  plot.GR32.Tools,
  plot.Controls, Data.DB, XMLDataSet, RootIntf,  FileCachImpl,
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, RootImpl,  System.SyncObjs;

{$IFDEF ENG_VERSION}
  const
   C_CaptGrForm ='New chart';
   C_MenuView ='Visualization windows';
   C_Memu_Show='Show';
{$ELSE}
  const
      C_CaptGrForm ='Новый график';
      C_MenuView ='Окна визуализации';
      C_Memu_Show='Показать';
{$ENDIF}

type
  TGraphDataForm = class(TCustomFormData, INotifyCanClose, INotifyClientBeforeRemove)
    Graph: TGraph;
    procedure GraphParamsAdded(d: TDataSet);
    procedure FormShow(Sender: TObject);
  private
    FActiveDataSetBinds: Tarray<string>;
    FBindLock: TCriticalSection;
    FC_Write: Integer;
    function IsBinded(ds: TXMLDataSet): boolean;
    procedure SetC_Write(const Value: Integer);
//    procedure NAddDataClick(Sender: TObject);
   const
    NICON = 135;
  protected
    procedure Loaded; override;
    class function ClassIcon: Integer; override;
    procedure CanClose(var CanClose: Boolean);
    procedure ClientBeforeRemove(Service: ServiceType; ClientName: string);
  public
    destructor Destroy; override;
    [StaticAction(C_CaptGrForm, C_MenuView, NICON, '0:'+C_Memu_Show+'.'+C_MenuView)]
    class procedure DoCreateForm(Sender: IAction); override;
    property C_Write: Integer read FC_Write write SetC_Write;
  end;

implementation

{$R *.dfm}

{ TGraphDataForm }

destructor TGraphDataForm.Destroy;
begin
  FBindLock.Free;
  inherited;
end;

procedure TGraphDataForm.CanClose(var CanClose: Boolean);
begin
  Graph.Frost;
end;

class function TGraphDataForm.ClassIcon: Integer;
begin
  Result := NICON;
end;

procedure TGraphDataForm.ClientBeforeRemove(Service: ServiceType; ClientName: string);
var
  c: TGraphColmn;
  p: TGraphPar;
  i: Integer;
  br: INotifyClientBeforeRemove;
begin
  Graph.Frost;
  try
  for c in Graph.Columns do
   for i := c.Params.Count-1 downto 0 do if (c.Params[i].Link.DataSet is TXMLDataSet) then
    begin
     p := c.Params[i];
     if  (SameText(ClientName, TXMLDataSet(p.Link.DataSet).BinFileName)
         or SameText(ClientName, TXMLDataSet(p.Link.DataSet).CLCFileName)) then
      begin
       var lb: IDataLinkBuffer;
       if Supports(p.Link, IDataLinkBuffer, lb) then
       (GContainer as IProjectDataFile).TmpFileNeedDelete(lb.BufferFileName);
       p.Free;
      end;
     end;
  finally
   Graph.DeFrost;
  end;
end;

class procedure TGraphDataForm.DoCreateForm(Sender: IAction);
 var
  gdf: TGraphDataForm;
  f: IForm;
  fe: IFormEnum;
begin
  gdf := CreateUser();
  gdf.Graph.Rows.Add<TGR32LegendRow>;
  gdf.Graph.Rows.Add<TCustomGraphDataRow>;
  gdf.Graph.Rows.Add<TCustomGraphInfoRow>;
  gdf.Graph.Columns.Add<TGR32GraphicCollumn>;
  gdf.Caption := 'Chart';
  f := gdf as IForm;
  if Supports(GlobalCore, IFormEnum, fe) then fe.Add(f);
  (GContainer as ITabFormProvider).Tab(f);
  f.Show;
end;

procedure TGraphDataForm.FormShow(Sender: TObject);
begin
  Graph.DeFrost;
end;

procedure TGraphDataForm.GraphParamsAdded(d: TDataSet);
var
  s: string;
  needBind: Boolean;
begin
  if (d is TXMLDataSet) and TXMLDataSet(d).IsActive then
  begin
    FBindLock.Enter;
    try
      needBind := not IsBinded(TXMLDataSet(d));
      if needBind then
        s := TXMLDataSet(d).BinFileName;
    finally
      FBindLock.Leave;
    end;
    if needBind then
    begin
      Bind('C_Write', TXMLDataSet(d).FileData, ['S_Write']);
      FBindLock.Enter;
      try
        FActiveDataSetBinds := FActiveDataSetBinds + [s];
      finally
        FBindLock.Leave;
      end;
    end;
  end;
end;

function TGraphDataForm.IsBinded(ds: TXMLDataSet): boolean;
 var
  s: string;
begin
  Result := False;
  FBindLock.Enter;
  try
    for s in FActiveDataSetBinds do if SameText(s, ds.BinFileName) then Exit(True);
  finally
    FBindLock.Leave;
  end;
end;

procedure TGraphDataForm.Loaded;
var
  c: TGraphColmn;
  p: TGraphPar;
begin
  inherited;
  FBindLock := TCriticalSection.Create;
  //AddToNCMenu('Долбавить данные текущего проекта...', NAddDataClick);
  Graph.PopupMenu := CreateUnLoad<TPlotMenu>;
  for c in Graph.Columns do
    for p in c.Params do GraphParamsAdded(p.Link.DataSet);
end;

//procedure TGraphDataForm.NAddDataClick(Sender: TObject);
//begin
//
//end;

procedure TGraphDataForm.SetC_Write(const Value: Integer);
begin
  FC_Write := Value;
  Graph.UpdateData;
end;

initialization
  RegisterClass(TGraphDataForm);
  TRegister.AddType<TGraphDataForm, IForm, INotifyClientBeforeRemove>.LiveTime(ltSingletonNamed);
finalization
  GContainer.RemoveModel<TGraphDataForm>;
end.

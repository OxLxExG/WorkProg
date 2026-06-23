unit VCLGraphDataForm;

interface

{$INCLUDE global.inc}

uses  VCL.CustomDataForm, Container, ExtendIntf, Actns, plot.GR32, plot.Controls, Data.DB, XMLDataSet, RootIntf,  FileCachImpl,
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, RootImpl, CustomPlot;

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
    [StaticAction(C_CaptGrForm, C_MenuView, NICON, '0:'+C_Memu_Show+'.'+C_MenuView)]
    class procedure DoCreateForm(Sender: IAction); override;
    property C_Write: Integer read FC_Write write SetC_Write;
  end;

implementation

{$R *.dfm}

{ TGraphDataForm }

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
       (GContainer as IProjectDataFile).TmpFileNeedDelete(p.Link.BufferFileName);
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
begin
  if (d is TXMLDataSet) and TXMLDataSet(d).IsActive and not IsBinded(TXMLDataSet(d)) then
   begin
    Bind('C_Write', TXMLDataSet(d).FileData, ['S_Write']);
    FActiveDataSetBinds := FActiveDataSetBinds +[TXMLDataSet(d).BinFileName];
   end;
end;

function TGraphDataForm.IsBinded(ds: TXMLDataSet): boolean;
 var
  s: string;
begin
  for s in FActiveDataSetBinds do if SameText(s, ds.BinFileName) then Exit(True);
  Result := False;
end;

procedure TGraphDataForm.Loaded;
var
  c: TGraphColmn;
  p: TGraphPar;
begin
  inherited;
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

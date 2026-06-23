unit FormDBGRLog;

interface

uses intf, ExtendIntf, DockIForm, debug_except, DeviceIntf, PluginAPI, Xml.XMLIntf, IGDIPlus,
  DataDBForm,
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs,
  uADStanIntf, uADStanOption, uADStanParam, uADStanError, uADDatSManager, uADPhysIntf, uADDAptIntf, uADStanAsync,
  uADDAptManager, uADStanExprFuncs, uADGUIxIntf, uADStanDef, uADStanPool, uADPhysManager, Data.DB, uADCompClient,
  uADPhysSQLite, uADCompDataSet, Plot, Vcl.Menus, PlotDB;

type
  TContextMenuItem = class(TMenuItem)
  public
   ContextObj: TObject;
   ContextMousePos: TPoint;
  end;

  TFormGraph = class(TFormDataDB)
    Plt: TPlotDB;
    procedure PltContextPopup(Sender: TObject; MousePos: TPoint; var Handled: Boolean);
  protected
    procedure Loaded; override;
    procedure DoAfterOpen; override;
    procedure DoAfterDialog; override;
    procedure NCPopup(Sender: TObject); override;
    function GetTableFormClass: TFormDataDBClass; virtual; abstract;
  private
    FPltMenu: TPopupMenu;
    FShowLegendMenu: TMenuItem;
    procedure ShowLegendClick(Sender: TObject);
    procedure NewDBParam(c: TGraphColumnDB; field: TField);
    procedure AddColumnClick(Sender: TObject);
    procedure SetBookmarkClick(Sender: TObject);
    procedure GotoBookmarkClick(Sender: TObject);
    procedure ShowBookmarkInTableClick(Sender: TObject);
    procedure RemoveColumnClick(Sender: TObject);
    procedure SelectParametersClick(Sender: TObject);
    procedure EditParameterClick(Sender: TObject);
    procedure UpdateParameters(c: TGraphColumnDB ; pr: TArray<string>; NeedAddNew: Boolean);
//    procedure SetNewParam(p: TGraphParamDB; Node: IXMLNode);
  public
    constructor CreateFromDialog(AOwner: TComponent; tdsh: TypeDataShow; const ADBName: string);override;
    function AddToMenu(const ACaption: string; AClick: TNotifyEvent; ContObj: TObject; MousePos: TPoint): TContextMenuItem;
    procedure GotoBookMark(BookMark : Double); override;
  published
    procedure ContextPopupColumn(Sender: TObject; MousePos: TPoint; var Handled: Boolean);
    procedure ContextPopupParametr(Sender: TObject; MousePos: TPoint; var Handled: Boolean);
  end;

implementation

{$R *.dfm}

uses tools, DlgViewParams, FormDBCursor, DlgEditParam;

{ TFormGraphLog }

constructor TFormGraph.CreateFromDialog(AOwner: TComponent; tdsh: TypeDataShow; const ADBName: string);
begin
  inherited;
  Plt.Columns.Add<TYColumn>;
  Plt.Columns.Add<TGraphColumnDB>.OnContextPopup := ContextPopupColumn;
end;

procedure TFormGraph.Loaded;
begin
  inherited;
  if DataType in [hdtLog, hdtRam] then
   begin
    Plt.FiedName := 'ID';
    Plt.TitleY := 'ID';
    Plt.EUnitY := '';
    if DataType = hdtLog then Plt.Mirror := -1;
    Plt.ScaleFactor := 0.1;
    Plt.PresizionY := 0;
   end;
  AddToNCMenu('Показывать легенду', ShowLegendClick, FShowLegendMenu);
  FShowLegendMenu.MenuIndex := 0;
  FPltMenu := CreateUnLoad<TPopupMenu>;
  Plt.Popupmenu := FPltMenu;
  ResetParamsAndScreen;
end;

function TFormGraph.AddToMenu(const ACaption: string; AClick: TNotifyEvent; ContObj: TObject; MousePos: TPoint): TContextMenuItem;
begin
  Result := TContextMenuItem.Create(FPltMenu);
  Result.Caption := ACaption;
  Result.OnClick := AClick;
  Result.ContextObj := ContObj;
  Result.ContextMousePos := MousePos;
  FPltMenu.Items.Add(Result);
end;

procedure TFormGraph.NewDBParam(c: TGraphColumnDB; field: TField);
 var
  digit, pres: integer;
  L,R: Double;
  p : TGraphParamDB;
  Node: IXMLNode;
begin
  if not (Assigned(field) and (field is TNumericField)) then Exit;
  p := TGraphParamDB(c.Params.Add);
  p.DataSet := FDataSet;
  p.XFiedName := field.FieldName;
  p.OnContextPopup := ContextPopupParametr;
  // настройки параметра по атрибутам
  Node := XFormats.DocumentElement.ChildNodes[field.Index];
  if Node.HasAttribute(AT_FMT) then
   begin
    DecodeFmt(Node.Attributes[AT_FMT], digit, pres);
    p.Presizion := pres;
   end;
  if Node.HasAttribute(AT_EU) then p.EUnit := Node.Attributes[AT_EU];
  if Node.HasAttribute(AT_RLO) then
   begin
    L := Node.Attributes[AT_RLO];
    R := Node.Attributes[AT_RHI];
    p.Delta := -(R-L)/2;
    p.Scale := SetPresetScale(c.Width/Plt.DpmmX/(R-L));
   end
   else p.Scale := p.Scale + 0.000000001;
end;

procedure TFormGraph.UpdateParameters(c: TGraphColumnDB; pr: TArray<string>; NeedAddNew: Boolean);
  function InArray(const dta: string): Boolean;
   var
    s: string;
  begin
    Result := False;
    for s in pr do if dta = s then Exit(True)
  end;
  function InParams(const dta: string): Boolean;
   var
    p: TGraphParam;
  begin
    Result := False;
    for p in c.Params do if dta = TGraphParamDB(p).XFiedName then Exit(True)
  end;
 var
  i: Integer;
  s: string;
begin
  // убрать старые
  for i := c.Params.Count-1 downto 0 do if not InArray(TGraphParamDB(c.Params.Items[i]).XFiedName) then c.Params.Items[i].Destroy;
  // добавить новые
  if NeedAddNew then for s in pr do if not InParams(s) then NewDBParam(c, FDataSet.Fields.FieldByName(s));
end;

procedure TFormGraph.DoAfterOpen;
begin
  Plt.BeginUpdate;
  try
   Plt.DataSet := FDataSet;
   Plt.UpdateMinMaxY;
  finally
   Plt.EndUpdate;
  end;
  Plt.Repaint;
end;

procedure TFormGraph.DoAfterDialog;
 var
  c: TPlotColumn;
  all: TArray<string>;
  i: Integer;
begin
  for i := 0 to FDataSet.FieldCount-1 do  CArray.Add<string>(all, FDataSet.Fields[i].FieldName);
  Plt.BeginUpdate;
  try
   for c in Plt.Columns do if c is TGraphColumnDB then UpdateParameters(TGraphColumnDB(c), all, False);
   Plt.UpdateMinMaxY;
  finally
   Plt.EndUpdate;
  end;
  Plt.Repaint;
end;


//{$REGION ' popup click'}

procedure TFormGraph.NCPopup(Sender: TObject);
begin
  inherited;
  FShowLegendMenu.Checked := Plt.ShowLegend;
end;

procedure TFormGraph.PltContextPopup(Sender: TObject; MousePos: TPoint; var Handled: Boolean);
begin
  FPltMenu.Items.Clear;
  if not Plt.IsLegend(MousePos.Y) then
   begin
    AddToMenu('Отметить закладку', SetBookmarkClick, Sender, MousePos);
    AddToMenu('Перейти на закладку', GotoBookmarkClick, Sender, MousePos);
    AddToMenu('Показать закладку в таблице', ShowBookmarkInTableClick, Sender, MousePos);
    AddToMenu('-', nil, Sender, MousePos);
   end;
  AddToMenu('Добавить колонку', AddColumnClick, Sender, MousePos);
end;

procedure TFormGraph.ContextPopupColumn(Sender: TObject; MousePos: TPoint; var Handled: Boolean);
begin
  AddToMenu('Удалить колонку', RemoveColumnClick, Sender, MousePos);
  if Sender is TGraphColumn then AddToMenu('Выбрать параметры колонки ...', SelectParametersClick, Sender, MousePos);
end;

procedure TFormGraph.ContextPopupParametr(Sender: TObject; MousePos: TPoint; var Handled: Boolean);
begin
  AddToMenu('-', nil, nil, MousePos).MenuIndex := 0;
  AddToMenu('Редактироваить параметр '+ TGraphParam(Sender).Title+' ...' , EditParameterClick, Sender, MousePos).MenuIndex := 0;
end;

procedure TFormGraph.EditParameterClick(Sender: TObject);
begin
  (GlobalCore as Idialogs).Execute(DIALOG_PARAM_Edit, TEditParamImpl.Create(Self, TGraphParam(TContextMenuItem(Sender).ContextObj)))
end;


procedure TFormGraph.SelectParametersClick(Sender: TObject);
 var
  d: TSelectParamsStrings;
  cch: TGraphColumnDB;
  p: TGraphParam;
  i: Integer;
begin
  cch := TGraphColumnDB(TContextMenuItem(Sender).ContextObj);
  for p in cch.Params do CArray.Add<string>(d.Selected, TGraphParamDb(p).XFiedName);
  for i := 0 to FDataSet.FieldCount-1 do  CArray.Add<string>(d.All, FDataSet.Fields[i].FieldName);
  (GlobalCore as Idialogs).Execute(DIALOG_PARAM_Select, TSelectParamsStringsImpl.Create(Self, d, procedure (sel: Tarray<string>)
   var
    c: TPlotColumn;
  begin
    for c in plt.Columns do if (c is TGraphColumnDB) and (c = cch) then // проверка на удаление редактируемой колонки
     begin
      Plt.BeginUpdate;
      try
       UpdateParameters(cch, Sel, true);
       Plt.UpdateMinMaxY;
      finally
       Plt.EndUpdate;
      end;
      plt.Repaint;
      break;
     end;
  end));
end;

procedure TFormGraph.SetBookmarkClick(Sender: TObject);
begin
  Plt.SetBookmark(TContextMenuItem(Sender).ContextMousePos.Y);
  Plt.Repaint;
end;

procedure TFormGraph.GotoBookMark(BookMark: Double);
begin
  Plt.CursorY := BookMark;
  Plt.GoToBookmark;
end;

procedure TFormGraph.GotoBookmarkClick(Sender: TObject);
begin
  Plt.GoToBookmark;
end;

procedure TFormGraph.RemoveColumnClick(Sender: TObject);
begin
  TPlotColumn(TContextMenuItem(Sender).ContextObj).Destroy;
  Plt.Repaint;
end;

procedure TFormGraph.AddColumnClick(Sender: TObject);
  var
   c: TGraphColumnDB;
begin
  c := Plt.Columns.Add<TGraphColumnDB>;
  c.OnContextPopup := ContextPopupColumn;
  Plt.Repaint;
end;

procedure TFormGraph.ShowBookmarkInTableClick(Sender: TObject);
 var
  f: TFormDataDB;
  fe: IFormEnum;
  fi : IForm;
begin
  if not Supports(GlobalCore, IFormEnum, fe) then Exit;
  fi := fe.Get(FrendFormName);
  if not Assigned(fi) then
   begin
    f := TFormCursor.CreateFromDialog(nil, DataType, DBName);
    fi := f as IForm;
    fe.Add(fi);
    f.XInfo := Xinfo;
    f.FrendFormName := Name;
    FrendFormName := f.Name;
    f.ResetParamsAndScreen;
   end
   else f := TFormDataDB((fi as IInterfaceComponentReference).GetComponent);
  fi.Show; // из интерфейса Show покажет скрытые формы
  f.GotoBookMark(plt.CursorY);
  Plt.SetFocus;
end;

procedure TFormGraph.ShowLegendClick(Sender: TObject);
begin
  Plt.ShowLegend := not Plt.ShowLegend;
end;

//{$ENDREGION}

initialization
  RegisterClass(TFormGraph);
end.

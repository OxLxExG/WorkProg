unit FormDBGR;

interface

uses RootImpl, ExtendIntf, DockIForm, debug_except, DeviceIntf, PluginAPI, Xml.XMLIntf, Container, Actns, DataExchange, Winapi.GDIPAPI,
  DataDBForm, Data.DB, DBIntf, DlgFltParam, AbstractDlgParams, Plot.DB, Plot.GraphParams,
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Plot, Vcl.Menus;

type
  TContextMenuItem = class(TMenuItem)
  public
   ContextObj: TObject;
   ContextMousePos: TPoint;
  end;

  ///	<remarks>
  ///	  абстрактный класс графиков
  ///	</remarks>
  TFormGraph = class(TFormDataDB)
    Plt: TPlotDB;
    procedure PltContextPopup(Sender: TObject; MousePos: TPoint; var Handled: Boolean);
    procedure PltParamXAxisChanged(Column: TGraphColumn; Param: TGraphParam; ChangeState: TChangeStateParam);
  protected
    procedure Loaded; override;
    procedure DoAfterOpen; override;
    procedure DoAfterDialog; override;
    procedure NCPopup(Sender: TObject); override;
    procedure SetC_UpdateFields(const Value: Integer); override;
    function GetTableFormClass: TFormDataDBClass; virtual; abstract;
  private
    FPltMenu: TPopupMenu;
    FShowLegendMenu: TMenuItem;
    procedure ShowLegendClick(Sender: TObject);
    procedure NewDBParam(c: TGraphColumn; field: TField);
    procedure NewLASParam(c: TGraphColumn; const LasFile, XName: string);
    procedure AddColumnClick(Sender: TObject);
    procedure SetBookmarkClick(Sender: TObject);
    procedure GotoBookmarkClick(Sender: TObject);
    procedure ShowBookmarkInTableClick(Sender: TObject);
    procedure RemoveColumnClick(Sender: TObject);
    procedure SelectParametersClick(Sender: TObject);
    procedure EditParametersClick(Sender: TObject);
    procedure ImportLASClick(Sender: TObject);
    procedure EditParameterClick(Sender: TObject);
    procedure DeleteParameterClick(Sender: TObject);
    procedure UpdateParameters(c: TGraphColumn ; pr: TArray<string>; NeedAddNew: Boolean);
    procedure UpdateMinMaxY;
    procedure Pos0Repaint;
//    procedure SetNewParam(p: TGraphParamDB; Node: IXMLNode);
  public
    constructor CreateFromDialog(AOwner: TComponent; tdsh: TypeDataShow; const ADBName: string); override;
    function AddToMenu(const ACaption: string; AClick: TNotifyEvent; ContObj: TObject; MousePos: TPoint): TContextMenuItem;
    procedure GotoBookMark(BookMark : Double); override;
  published
    procedure ContextPopupColumn(Sender: TObject; MousePos: TPoint; var Handled: Boolean);
    procedure ContextPopupParametr(Sender: TObject; MousePos: TPoint; var Handled: Boolean);
  end;

  TFormGraphLog = class(TFormGraph)
  protected
   const
    NICON = 114;
//    function GetTypeDataClass: TFormDBTypeDataClass; override;
    function GetTableFormClass: TFormDataDBClass; override;
    class function ClassIcon: Integer; override;
  public
    //Capt, Categ: string; AImageIndex: Integer; APaths: string; AHint: string; AAutoCheck AChecked AGroupIndex AEnabled
    [StaticAction('Новый график Log', 'Открыть для просмотра', NICON, '0:Файл.Открыть для просмотра|0:0')]
    class procedure DoCreateForm(Sender: IAction); override;
  published
//    property FromData;
  end;

  TFormGraphRam = class(TFormGraph, IPlotForm)
  protected
   const
    NICON = 159;
//    function GetTypeDataClass: TFormDBTypeDataClass; override;
    function Plot: IInterface;
    procedure SetContextPopupParametr(Parametr: TObject);
    function GetTableFormClass: TFormDataDBClass; override;
    class function ClassIcon: Integer; override;
    procedure Loaded; override;
    procedure PltMouseUp(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
  public
    //Capt, Categ: string; AImageIndex: Integer; APaths: string; AHint: string; AAutoCheck AChecked AGroupIndex AEnabled
    [StaticAction('Новый график памяти', 'Открыть для просмотра', NICON, '0:Файл.Открыть для просмотра|0:-1')]
    class procedure DoCreateForm(Sender: IAction); override;
  published
//    property FromData;
  end;

implementation

{$R *.dfm}

uses tools, DlgViewParam, FormDBCursor, DlgEditParam, DialogOpenLas;

{$REGION 'TFormGraph'}

{ TFormGraph }

constructor TFormGraph.CreateFromDialog(AOwner: TComponent; tdsh: TypeDataShow; const ADBName: string);
begin
  inherited;
  Plt.Columns.Add<TYColumn>;
  Plt.Columns.Add<TGraphColumn>.OnContextPopup := ContextPopupColumn;
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
  FShowLegendMenu := AddToNCMenu('Показывать легенду', ShowLegendClick, 0);
  FPltMenu := CreateUnLoad<TPopupMenu>;
  Plt.Popupmenu := FPltMenu;
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

procedure TFormGraph.NewDBParam(c: TGraphColumn; field: TField);
 var
  L,R: Double;
  p : TGraphParamDB;
  Node: IXMLNode;
begin
  if not (Assigned(field) and (field is TNumericField)) then Exit;
  p := c.Params.Add<TGraphParamDB>;
//  p.DataSet := FDataSet;
  p.XFiedName := field.FullName;
  p.OnContextPopup := ContextPopupParametr;
  // настройки параметра по атрибутам
  Node := FMemQuery.GetXParam(field.FieldName);

  if not Assigned(Node) then raise EBaseException.CreateFmt('XML несовпадаеет  с DB !!! field: %s',[field.FieldName]);

  if Node.HasAttribute(AT_COLOR) then p.Color := Cardinal(Node.Attributes[AT_COLOR]);
  if Node.HasAttribute(AT_WIDTH) then p.Width := Node.Attributes[AT_WIDTH];
  if Node.HasAttribute(AT_DASH) then p.DashStyle := TDashStyle(Node.Attributes[AT_DASH]);

  if Node.HasAttribute(AT_TITLE) then p.Title := Node.Attributes[AT_TITLE];
  if Node.HasAttribute(AT_AQURICY) then p.Presizion := Node.Attributes[AT_AQURICY];
  if Node.HasAttribute(AT_EU) then p.EUnit := Node.Attributes[AT_EU];
  if Node.HasAttribute(AT_RLO) then
   begin
    L := Node.Attributes[AT_RLO];
    R := Node.Attributes[AT_RHI];
   end
  else
   begin
    L := -1000;
    R := 1000;
   end;
  p.Delta := L;// -(R-L)/2;
  p.Scale := SetPresetScale(c.Width/Plt.DpmmX/(R-L));
end;

procedure TFormGraph.NewLASParam(c: TGraphColumn; const LasFile, XName: string);
 var
  p : TGraphParamLAS;
begin
  if TGraphParamLAS.Exists(c.Params, LasFile, XName) then Exit;
  p := c.Params.Add<TGraphParamLAS>;
  p.FileName := LasFile;
  p.XName := XName;
  /// test
//  p.UpdateFields;
//  p.ParentTitle := TGraphParam(c.Params.Items[1]).Title;
//  TGraphParam(c.Params.Items[1]).ParentTitle := p.Title;
  ///
  p.OnContextPopup := ContextPopupParametr;
//  p.Scale := SetPresetScale(c.Width/Plt.DpmmX/1000);
end;

procedure TFormGraph.UpdateParameters(c: TGraphColumn; pr: TArray<string>; NeedAddNew: Boolean);
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
    for p in c.Params do if p is TGraphParamDB then if dta = TGraphParamDB(p).XFiedName then Exit(True)
  end;
 var
  i: Integer;
  s: string;
begin
  // убрать старые
  for i := c.Params.Count-1 downto 0 do
   if (c.Params.Items[i] is TGraphParamDB) and
      not InArray(TGraphParamDB(c.Params.Items[i]).XFiedName) then c.Params.Items[i].Destroy;
  // добавить новые
  if NeedAddNew then for s in pr do if not InParams(s) then NewDBParam(c, FDataSet.FieldList.FieldByName(s));
end;

procedure TFormGraph.DoAfterOpen;
 var
  c: TPlotColumn;
  all: TArray<string>;
  i: Integer;
begin
  for i := 0 to FDataSet.FieldCount-1 do  CArray.Add<string>(all, FDataSet.Fields[i].FieldName);
  Plt.BeginUpdate;
  try
   Plt.DataSet := FDataSet;
   for c in Plt.Columns do if c is TGraphColumn then UpdateParameters(TGraphColumn(c), all, False);
   UpdateMinMaxY;
   Plt.UpdateAllAndRepaint;
  finally
   Plt.EndUpdate;
  end;
end;


procedure TFormGraph.DoAfterDialog;
begin
  DoAfterOpen;
end;

{$REGION ' popup click'}

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

procedure TFormGraph.PltParamXAxisChanged(Column: TGraphColumn; Param: TGraphParam; ChangeState: TChangeStateParam);
 var
  P: TGraphParam;
  FneedUpd: Boolean;
begin
  Plt.BeginUpdate;
  FneedUpd := False;
  try
   for p in Column.Params do if (p.ParentTitle <> '') and SameText(p.ParentTitle, Param.Title) then
    begin
     p.Delta := Param.Delta;
     p.Scale := Param.Scale;
     FneedUpd := True;
    end;
  finally
   Plt.EndUpdate;
  end;
  if FneedUpd then plt.UpdateAllAndRepaint;
end;

procedure TFormGraph.ContextPopupColumn(Sender: TObject; MousePos: TPoint; var Handled: Boolean);
begin
  AddToMenu('Удалить колонку', RemoveColumnClick, Sender, MousePos);
  if Sender is TGraphColumn then
   begin
    AddToMenu('Выбрать параметры колонки ...', SelectParametersClick, Sender, MousePos);
    AddToMenu('Редактировать выбранные параметры...', EditParametersClick, Sender, MousePos);
    if DataType <> hdtLog then AddToMenu('Импорт LAS...', ImportLASClick, Sender, MousePos);
   end;
end;

procedure TFormGraph.ContextPopupParametr(Sender: TObject; MousePos: TPoint; var Handled: Boolean);
begin
  AddToMenu('-', nil, nil, MousePos).MenuIndex := 0;
  AddToMenu('Редактироваить параметр '+ TGraphParam(Sender).Title+' ...' , EditParameterClick, Sender, MousePos).MenuIndex := 0;
  AddToMenu('Удалить параметр '+ TGraphParam(Sender).Title , DeleteParameterClick, Sender, MousePos).MenuIndex := 1;
end;

procedure TFormGraph.EditParameterClick(Sender: TObject);
 var
  d: Idialog;
begin
  if RegisterDialog.TryGet<Dialog_EditViewParameters>(d) then (d as IDialog<TGraphParam>).Execute(TGraphParam(TContextMenuItem(Sender).ContextObj));
end;

procedure TFormGraph.EditParametersClick(Sender: TObject);
 var
  d: Idialog;
  cch: TGraphColumn;
  p: TGraphParam;
  a: TArray<TObject>;
begin
  cch := TGraphColumn(TContextMenuItem(Sender).ContextObj);
  for p in cch.Params do if p.Selected then CArray.Add<TObject>(a, p);
  if RegisterDialog.TryGet<Dialog_EditArrayParameters>(d) then (d as IDialog<TArray<TObject>, TNotifyEvent, TNotifyEvent>).Execute(a, nil, nil);
end;

procedure TFormGraph.DeleteParameterClick(Sender: TObject);
begin
  Plt.BeginUpdate;
  try
   TGraphParam(TContextMenuItem(Sender).ContextObj).Destroy;
   UpdateMinMaxY;
   plt.UpdateAllAndRepaint;
  finally
   Plt.EndUpdate;
  end;
end;

procedure TFormGraph.SelectParametersClick(Sender: TObject);
 var
  sd:  TArray<string>;
  cch: TGraphColumn;
  p: TGraphParam;
//  i: Integer;
 var
  d: Idialog;
begin
  cch := TGraphColumn(TContextMenuItem(Sender).ContextObj);
  for p in cch.Params do if p is TGraphParamDb then CArray.Add<string>(sd, TGraphParamDb(p).XFiedName);
  if RegisterDialog.TryGet<Dialog_SelectViewParameters>(d) then (d as IDialog<TViewParams>).Execute(TViewParams.Create(DBName, DataType, sd,
  procedure (sel: Tarray<string>)
   var
    c: TPlotColumn;
  begin
    for c in plt.Columns do if (c is TGraphColumn) and (c = cch) then // проверка на удаление редактируемой колонки
     begin
      Plt.BeginUpdate;
      try
       UpdateParameters(cch, Sel, true);
       UpdateMinMaxY;
      finally
       Plt.EndUpdate;
      end;
      plt.UpdateAllAndRepaint;
      break;
     end;
  end));
end;

procedure TFormGraph.SetBookmarkClick(Sender: TObject);
begin
  Plt.SetBookmark(TContextMenuItem(Sender).ContextMousePos.Y);
  Plt.UpdateAllAndRepaint;
end;

procedure TFormGraph.SetC_UpdateFields(const Value: Integer);
begin
  if Value < 0 then inherited SetC_UpdateFields(Value)
  else Plt.AsyncRun(UpdateMinMaxY, Pos0Repaint);
end;

procedure TFormGraph.UpdateMinMaxY;
begin
  Plt.UpdateMinMaxY(True);
end;

procedure TFormGraph.Pos0Repaint;
begin
//  Tdebug.Log('Pos0Repaint START       ', []);
  Plt.Update0Position;
end;

//procedure TFormGraph.SetTableChange(const Value: string);
//begin
//  if Value = 'Modul' then ResetParamsAndScreen
//  else if FDBConnection.Active and (Value = 'Log') then
//   begin
//    Tdebug.Log('SetTableChange DB Begin ', []);
//    Plt.AsyncRun(UpdateMinMaxY, Pos0Repaint);
{    FDataSet.AsyncSQL('qcRefresh',[],[], qcRefresh, procedure
    begin
     Tdebug.Log('SetTableChange DB End Begin Paint', []);
     Plt.AsyncRun(UpdateMinMaxY, Pos0Repaint);
    end, false);}
//   end;
//end;

procedure TFormGraph.GotoBookMark(BookMark: Double);
begin
  Plt.CursorY := BookMark;
  Plt.GoToBookmark;
end;

procedure TFormGraph.GotoBookmarkClick(Sender: TObject);
begin
  Plt.GoToBookmark;
end;

procedure TFormGraph.ImportLASClick(Sender: TObject);
 var
  fle, s: string;
  sel: TArray<string>;
  cch: TGraphColumn;
begin
  Plt.BeginUpdate;
  try
   if TDlgOpenLAS.Execute(fle, sel, ExtractFilePath(ParamStr(0))) then
    begin
     cch := TGraphColumn(TContextMenuItem(Sender).ContextObj);
     for s in sel do NewLASParam(cch, fle, s);
    end;
   UpdateMinMaxY;
   Plt.UpdateAllAndRepaint;
  finally
   Plt.EndUpdate;
  end;
end;

procedure TFormGraph.RemoveColumnClick(Sender: TObject);
begin
  TPlotColumn(TContextMenuItem(Sender).ContextObj).Destroy;
end;

procedure TFormGraph.AddColumnClick(Sender: TObject);
  var
   c: TGraphColumn;
begin
  Plt.DataBitmap.Free;
  Plt.DataBitmap := TBitmap.Create;
  Plt.DataBitmap.SetSize(Plt.ClientWidth, Plt.ClientHeight);

  c := Plt.Columns.Add<TGraphColumn>;
  c.OnContextPopup := ContextPopupColumn;
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
    f := GetTableFormClass.CreateFromDialog(nil, DataType, DBName);
    fi := f as IForm;
    fe.Add(fi);
//    f.XInfo := Xinfo;
    f.FrendFormName := Name;
    FrendFormName := f.Name;
    f.ResetParamsAndScreen;
   end
   else f := TFormDataDB(fi.GetComponent);
  fi.Show; // из интерфейса Show покажет скрытые формы
  f.GotoBookMark(plt.CursorY);
  Plt.SetFocus;
end;

procedure TFormGraph.ShowLegendClick(Sender: TObject);
begin
  Plt.ShowLegend := not Plt.ShowLegend;
end;

{$ENDREGION}

{$ENDREGION}

{ TFormGraphLog }

class function TFormGraphLog.ClassIcon: Integer;
begin
  Result := NICON;
end;

class procedure TFormGraphLog.DoCreateForm(Sender: IAction);
begin
  inherited;
end;

function TFormGraphLog.GetTableFormClass: TFormDataDBClass;
begin
  Result := TFormCursorlog;
end;

{ TFormGraphRam }

class function TFormGraphRam.ClassIcon: Integer;
begin
  Result := NICON;
end;

class procedure TFormGraphRam.DoCreateForm(Sender: IAction);
begin
  CreateNewForm(hdtRam);
end;

function TFormGraphRam.GetTableFormClass: TFormDataDBClass;
begin
  Result := TFormCursorRam;
end;

procedure TFormGraphRam.Loaded;
begin
  inherited;
  Plt.OnMouseUp := PltMouseUp;
end;

function TFormGraphRam.Plot: IInterface;
begin
  Result := plt as IInterface;
end;

procedure TFormGraphRam.PltMouseUp(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
 var
  a: IDataAsk<TAskRamY, Double>;
  p: IDataAsk<TAskPlotFormFormMouse, TAnswePlotFormFormMouse>;
  ans: TAnswePlotFormFormMouse;
begin
  if CDataExchange.Check<TAskPlotFormFormMouse, TAnswePlotFormFormMouse>(p) then
   begin
    ans.X := X;
    ans.Y := Y;
    ans.Active := FDBConnection.Active;
    ans.Form := Self;
    p.Answer(sdaGood, ans);
   end
  else if CDataExchange.Check<TAskRamY, Double>(a) then
   begin
    if Plt.IsLegend(Y) then a.Answer(sdaBadData, 0)
    else a.Answer(sdaGood, Plt.MouseYtoParamY(Y));
   end
  else CDataExchange.Answer(sdaUnknownTypeData);
 end;

procedure TFormGraphRam.SetContextPopupParametr(Parametr: TObject);
begin
  TGraphParam(Parametr).OnContextPopup := ContextPopupParametr;
end;

initialization
  RegisterClass(TFormGraphLog);
  TRegister.AddType<TFormGraphLog, IForm>.LiveTime(ltSingletonNamed);
  RegisterClass(TFormGraphRam);
  TRegister.AddType<TFormGraphRam, IForm>.LiveTime(ltSingletonNamed);
finalization
  GContainer.RemoveModel<TFormGraphLog>;
  GContainer.RemoveModel<TFormGraphRam>;
end.

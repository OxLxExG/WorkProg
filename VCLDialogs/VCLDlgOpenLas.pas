unit VCLDlgOpenLas;

interface

uses RootIntf, debug_except, ExtendIntf, DockIForm, PluginAPI, RootImpl, Container, JDtools,
     DataSetIntf, IDataSets, LasDataSet, CustomPlot, LAS, LasImpl, Plot.DataLink,
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, System.TypInfo, Xml.XMLIntf,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.ComCtrls,  Vcl.Graphics,
  JvExComCtrls, JvComCtrls, JvDotNetControls, Plot.GR32, Data.DB, Vcl.Menus, JvComponentBase, JvInspector, Vcl.StdCtrls, Vcl.Grids,
  Vcl.DBGrids, Vcl.ExtCtrls, JvExControls, Vcl.FileCtrl, JvExStdCtrls, JvListBox, JvCombobox, JvDriveCtrls, JvMenus;

type

  TDlgOpenLASDataSet = class(TDialogIForm, IDialog, IDialog<TGraphColmn>)
    Inspector: TJvInspector;
    btCancel: TButton;
    btOK: TButton;
    pc: TPageControl;
    tshLAS: TTabSheet;
    tshData: TTabSheet;
    DBGrid1: TDBGrid;
    ds: TDataSource;
    Panel: TPanel;
    Label1: TLabel;
    cbY: TComboBox;
    PopupMenu: TPopupMenu;
    NDOS: TMenuItem;
    ANSY1: TMenuItem;
    UTF81: TMenuItem;
    Painter: TJvInspectorDotNETPainter;
    Panelbott: TPanel;
    PanelL: TPanel;
    DriveCombo: TDriveComboBox;
    DirectoryList: TDirectoryListBox;
    Splitter1: TSplitter;
    FileList: TFileListBox;
    Splitter2: TSplitter;
    procedure FileListChange(Sender: TObject);
    procedure btOKClick(Sender: TObject);
    procedure EncodeClick(Sender: TObject);
    procedure btCancelClick(Sender: TObject);
  private
    ids: IDataSet;
    Selected: TArray<Boolean>;
    Fcol: TGraphColmn;
    CurrEncode: Integer;
   const
    CEN: array [0..2] of LasEncoding = (lsenANSI, lsenDOS, lsenUTF8);
  protected
    function GetInfo: PTypeInfo; override;
    function Execute(col: TGraphColmn): Boolean;
    class function ClassIcon: Integer; override;
//
//  public
//    class function Execute(var LasFile: string; var SelMnems: TArray<string>; const InitialDir: string =''): boolean;
  end;

implementation

uses tools;

{$R *.dfm}

{$REGION 'TLasFormatData'}

type
  TLasFormatData = class(TJvInspectorCustomConfData)
  private
    las: ILasFormatSection;
    FItem: string;
  protected
    function ExistingValue: Boolean; override;
    procedure WriteValue(const Value: string); override;
  public
    function ReadValue: string; override;
    class function New(AParent: TJvCustomInspectorItem; ALasData: ILasFormatSection; const aMnem: string; ReadOnly: Boolean = True): TJvCustomInspectorItem; reintroduce;
  end;

{ TLasFormatData }


function TLasFormatData.ExistingValue: Boolean;
begin
  Result := True;
end;

class function TLasFormatData.New(AParent: TJvCustomInspectorItem; ALasData: ILasFormatSection; const aMnem: string; ReadOnly: Boolean = True): TJvCustomInspectorItem;
var
  cData: TLasFormatData;
begin
  with ALasData.Items[aMnem]^ do
       cData := CreatePrim(Format('[%9s.%-5s] %s', [aMnem, Units, string.LowerCase(Description)]) ,'nop', aMnem, System.TypeInfo(string));
  if not ReadOnly then cData.las := ALasData;
  if not ReadOnly then cData.FItem := aMnem
  else cData.FItem := ALasData.Items[aMnem].Data;
  cData := TLasFormatData(DataRegister.Add(cData));
  Result := cData.NewItem(AParent);
  Result.ReadOnly := ReadOnly;
end;

function TLasFormatData.ReadValue: string;
begin
  if Assigned(las) then Result := las.Items[FItem].Data
  else Result := FItem
end;

procedure TLasFormatData.WriteValue(const Value: string);
begin
 if Assigned(las) then las.Items[FItem].Data := Value;
end;

{$ENDREGION}

//class function TDlgOpenLAS.Execute(var LasFile: string; var SelMnems: TArray<string>; const InitialDir: string =''): boolean;
// var
//  i: Integer;
//begin
//  with Create(nil) do
//   try
//    if InitialDir <> '' then  DirectoryList.Directory := InitialDir;
//    Result := (ShowModal() = mrOk);
//    if Result then
//     begin
//      LasFile := Caption;
//      SetLength(SelMnems, 0);
//      for I := 0 to Length(Selected)-1 do if Selected[i] then CArray.Add<string>(SelMnems, Items[i]);
//      Result := Length(SelMnems) > 0;
//     end;
//   finally
//    Free;
//   end;
//end;

procedure TDlgOpenLASDataSet.btCancelClick(Sender: TObject);
begin
  RegisterDialog.UnInitialize(IMPORT_DB_DIALOG_CATEGORY, 'LAS');
end;

procedure TDlgOpenLASDataSet.btOKClick(Sender: TObject);
 var
  i: Integer;
  p: TLineParam;
begin
  Fcol.Graph.Frost;
  try
   if Assigned(ids) and Assigned(TLasDataSet(ids).LasDoc) then
    with TLasDataSet(ids).LasDoc do
     for I := 0 to Length(Selected)-1 do if Selected[i] then
      begin
       p := Fcol.Params.Add<TLineParam>;
       p.Title := Curve.Formats[i].Mnem;
       p.EUnit := Curve.Formats[i].Units;
       p.Color := RandomColor;
       p.link := TlineDataLink.Create(p);
       p.link.DataSetDef := TLASDataSetDef.CreateUser(FileName, Encoding);
       p.link.XParamPath := p.Title;
       p.link.YParamPath := cbY.Items[cbY.ItemIndex];
      end;
   Fcol.Graph.UpdateData;
  finally
   Fcol.Graph.DeFrost;
  end;
end;

class function TDlgOpenLASDataSet.ClassIcon: Integer;
begin
  Result := 125;
end;

function TDlgOpenLASDataSet.Execute(col: TGraphColmn): Boolean;
begin
  Result := True;
  FCol := Col;
  if CurrentThemeIsDark then
   begin
    Painter.BackgroundColor := clThBkg;
    Painter.NameFont.Color := clThWindowTextNormal;
    Painter.ValueFont.Color := clSkyBlue;
    Painter.CategoryColor := clThButtonNormal;
    Painter.CategoryFont.Color := clThWindowTextNormal;
    Painter.DividerColor := clThBorder;
    Painter.GridColor1 := clThBorder;
    Painter.GridColor2 := clThBorder;
   end;
  IShow;
end;

function TDlgOpenLASDataSet.GetInfo: PTypeInfo;
begin
  Result := TypeInfo(Dialog_OpenLAS);
end;

procedure TDlgOpenLASDataSet.EncodeClick(Sender: TObject);
begin
  if Assigned(ids) and Assigned(TLasDataSet(ids).LasDoc) then with TLasDataSet(ids) do
   begin
    CurrEncode := TMenuItem(Sender).MenuIndex;
    LasDoc.Encoding := CEN[CurrEncode];
    LasDoc.LoadFromFile(FileList.FileName);
    Encoding := LasDoc.Encoding;
    LasFile := FileList.FileName;
    Fields.Clear;
    FileListChange(Self);
   end;
end;

procedure TDlgOpenLASDataSet.FileListChange(Sender: TObject);
  function CeateCat(lfs: ILasFormatSection; exp: Boolean = True; aditems: Boolean = true): TJvInspectorCustomCategoryItem;
   var
    s: string;
  begin
    Result := TJvInspectorCustomCategoryItem.Create(Inspector.Root, nil);
    Result.SortKind := iskNone;
    Result.DisplayName := lfs.Priambula[0].Substring(1);
    Result.Expanded := exp;
    if aditems then for s in lfs.Mnems do TLasFormatData.New(Result, lfs, s);
  end;
  procedure CreateCurve(lfs: ICurveSection);
   var
    i: Integer;
    c: TJvInspectorCustomCategoryItem;
  begin
    c := CeateCat(lfs, true, false);
    SetLength(Selected, Length(lfs.Formats));
    for i := 0 to High(Selected) do with lfs.Formats[i] do TJvInspectorBooleanItem(TJvInspectorVarData.New(c, Format('[%9s.%-5s] %s', [Mnem, Units, string.LowerCase(Description)]), System.TypeInfo(Boolean), @Selected[i])).ShowAsCheckbox := True;
  end;
 var
  il: ILasDoc;
  i: Integer;
begin
  Inspector.Clear;
  Inspector.Root.SortKind := iskNone;
  SetLength(Selected, 0);
  if FileList.FileName <>'' then
   begin
    Caption := FileList.FileName;

    TLasDataSet.New(FileList.FileName, ids, CEN[CurrEncode]);
    ds.DataSet := ids.DataSet;
    ids.DataSet.Open;

    cbY.Clear;
    for I := 0 to ids.DataSet.FieldList.Count-1 do cbY.Items.Add(ids.DataSet.FieldList[i].FullName);
    cbY.ItemIndex := 0;

    il := TLasDataSet(ids).LasDoc;
   // with il.Version.Items['WRAP']^ do if Data <> 'NO' then raise Exception.CreateFmt('WRAP=%s Перенос строк не поддерживается', [Data]);
    CreateCurve(il.Curve);
    CeateCat(il.Well);
    CeateCat(il.Params);
    CeateCat(il.Version);
   end
  else Caption := 'Import LAS';
end;

initialization
  RegisterDialog.Add<TDlgOpenLASDataSet, Dialog_OpenLAS>(IMPORT_DB_DIALOG_CATEGORY, 'LAS');
finalization
  RegisterDialog.Remove<TDlgOpenLASDataSet>;
end.

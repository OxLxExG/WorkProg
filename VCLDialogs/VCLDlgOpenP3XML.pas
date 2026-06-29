unit VCLDlgOpenP3XML;

interface

{$WARN UNIT_PLATFORM OFF}

uses RootIntf, debug_except, ExtendIntf, DockIForm, PluginAPI, RootImpl, Container, JDtools, XMLDataSet,
     DataSetIntf, IDataSets, CustomPlot, Plot.DtLink, Plot.GR32, Data.DB, System.IOUtils,
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, System.TypInfo, Xml.XMLIntf,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.ComCtrls,  Vcl.Graphics,
  Vcl.Menus, Vcl.StdCtrls, Vcl.Grids, Vcl.DBGrids, Vcl.ExtCtrls,
  JvExStdCtrls, JvListBox, JvCombobox, JvDriveCtrls, VCLFrameSelectParam, Vcl.FileCtrl, VCLFrameSelectPath;

type

  TDlgOpenP3DataSet = class(TDialogIForm, IDialog, IDialog<TGraphColmn>)
    btCancel: TButton;
    btOK: TButton;
    pc: TPageControl;
    tshSelParam: TTabSheet;
    tshData: TTabSheet;
    tshSelDir: TTabSheet;
    DBGrid1: TDBGrid;
    ds: TDataSource;
    Panel: TPanel;
    Label1: TLabel;
    cbY: TComboBox;
    FrameSelectPath: TFrameSelectPath;
    FrameSelectParam1: TFrameSelectParam;
    PopupMenu: TPopupMenu;
    NObjectView: TMenuItem;
    Panelbott: TPanel;
    PanelL: TPanel;
    Splitter1: TSplitter;
    DriveCombo: TDriveComboBox;
    DirectoryList: TDirectoryListBox;
    FileList: TFileListBox;
    Splitter2: TSplitter;
    procedure FileListChange(Sender: TObject);
    procedure btOKClick(Sender: TObject);
    procedure btCancelClick(Sender: TObject);
  private
    ids: IDataSet;
    Fcol: TGraphColmn;
  protected
    function GetInfo: PTypeInfo; override;
    function Execute(col: TGraphColmn): Boolean;
    class function ClassIcon: Integer; override;
  end;

implementation

uses tools;

{$R *.dfm}

class function TDlgOpenP3DataSet.ClassIcon: Integer;
begin
  Result := 125;
end;

function TDlgOpenP3DataSet.Execute(col: TGraphColmn): Boolean;
 var
  m: IManager;
begin
  Result := True;
  FCol := Col;
  DirectoryList.Directory := TPath.GetSharedDocumentsPath +'\Горизонт\WorkProg\Projects';
  if Supports(GContainer, IManager, m) and (m.ProjectName <> '') then
      FileList.FileName := m.ProjectName;
  IShow;
end;

function TDlgOpenP3DataSet.GetInfo: PTypeInfo;
begin
  Result := TypeInfo(Dialog_OpenLAS);
end;

type TmyGrap = class(TGraph);
procedure TDlgOpenP3DataSet.btCancelClick(Sender: TObject);
begin
  RegisterDialog.UnInitialize(IMPORT_DB_DIALOG_CATEGORY, 'XML Project');
end;

procedure TDlgOpenP3DataSet.btOKClick(Sender: TObject);
 var
  p: TXScalableParam;
  f: TField;
  n : IXMLNode;
begin
  Fcol.Graph.Frost;
  try
   if Assigned(ids) then
    with TXMLDataSet(ids) do
     begin
     for f in FrameSelectParam1.GetSelected do
      begin
       if f is TBlobField then
        begin
         p := Fcol.Params.Add<TWaveParam>;
         p.link := TWaveDataLink.Create(p);
        end
       else if f is TNumericField then
        begin
         p := Fcol.Params.Add<TLineParam>;
         p.link := TlineDataLink.Create(p)
        end
       else //if f is TStringField then
        begin
         raise Exception.Create('Error Message TStringField ');
//         p := Fcol.Params.Add<TStringParam>;
//         p.link := TStringDataLink.Create(p)
        end;
       p.link.DataSetDef := TXMLDataSetDef.CreateUser(XMLSection, ObjectView);
       p.link.XParamPath := f.FullName;
       p.link.YParamPath := cbY.Items[cbY.ItemIndex];

       p.Title := f.FullName;
       p.Color := RandomColor;

       if TryGetX(f.FullName, n) then
        begin
         if n.HasAttribute(AT_WIDTH) then TLineParam(p).Width := n.Attributes[AT_WIDTH];
         if n.HasAttribute(AT_DASH) then TLineParam(p).DashStyle := TLineDashStyle(n.Attributes[AT_DASH]);
         if n.HasAttribute(AT_COLOR) then p.Color := Cardinal(n.Attributes[AT_COLOR]);
         { TODO : gamma TWaveParam}
         if n.HasAttribute(AT_TITLE) then p.Title := n.Attributes[AT_TITLE];
         if n.HasAttribute(AT_AQURICY) then p.Presizion := n.Attributes[AT_AQURICY];
         if n.HasAttribute(AT_EU) then p.EUnit := n.Attributes[AT_EU];
         if n.HasAttribute(AT_RLO) then p.SetRange(n.Attributes[AT_RLO], n.Attributes[AT_RHI]);
        end;
      end;
     end;
   TmyGrap(Fcol.Graph).DoParamsAdded(ids.DataSet);
   Fcol.Graph.UpdateData;
  finally
   Fcol.Graph.DeFrost;
  end;
end;

procedure TDlgOpenP3DataSet.FileListChange(Sender: TObject);
begin
  if FileList.FileName <>'' then
   begin
    Caption := FileList.FileName;
    pc.ActivePageIndex := 0;
    FrameSelectPath.Execute(Caption, procedure(XMLSection: IXMLNode)
     var
      i: Integer;
    begin
      TXMLDataSet.Get(XMLSection,  ids,  NObjectView.Checked);
      ids.DataSet.Open;
      cbY.Clear;
      with ids.DataSet do
      for I := 0 to FieldList.Count-1 do if FieldList[i] is TNumericField then cbY.Items.Add(FieldList[i].FullName);
      cbY.ItemIndex := 0;
      FrameSelectParam1.InitTree(ids.DataSet);
      ds.DataSet := ids.DataSet;
    end);
   end
  else Caption := 'Project Import';
end;

initialization
  RegisterDialog.Add<TDlgOpenP3DataSet, Dialog_OpenLAS>(IMPORT_DB_DIALOG_CATEGORY, 'XML Project');
finalization
  RegisterDialog.Remove<TDlgOpenP3DataSet>;
end.

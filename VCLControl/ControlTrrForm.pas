unit ControlTrrForm;

interface

uses Actns, Parser, ImportExport,
  RootImpl, ExtendIntf, DockIForm, debug_except, DeviceIntf, PluginAPI, ControlDBForm, Xml.XMLIntf, Xml.XMLDoc, Container,
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.Grids, Vcl.DBGrids;

 type
  EFormControlTrrException = class(EBaseException);

  TFormControlTrr = class(TFormControlDB)
  protected
    procedure DBGridEditButtonClick(Sender: TObject);
    procedure Loaded; override;
    procedure DoAfterOpen; override;
    function GetSQL: string; override;
    function GetQueryName: string; override;
    class function ClassIcon: Integer; override;
  public
    //Capt, Categ: string; AImageIndex: Integer; APaths: string; AHint: string; AAutoCheck AChecked AGroupIndex AEnabled
    [StaticAction('Окно импорта метрологии', 'Показать', 270, '0:Показать:3')]
    class procedure DoCreateForm(Sender: IAction); override;
  end;

implementation

uses tools;

{$R *.dfm}

{ TFormControlTrr }

class function TFormControlTrr.ClassIcon: Integer;
begin
  Result := 270;
end;

class procedure TFormControlTrr.DoCreateForm(Sender: IAction);
begin
  GetUniqueForm('GlobalControlTrrForm');
end;

function TFormControlTrr.GetQueryName: string;
begin
  Result := 'QueViewTrr';
end;

function TFormControlTrr.GetSQL: string;
begin
  Result := 'select * from Customer_Metrol';
end;

procedure TFormControlTrr.Loaded;
begin
  inherited;
  FDBGrid.Options := FDBGrid.Options + [dgAlwaysShowEditor];
  FDBGrid.ReadOnly := True;
  FDBGrid.OnEditButtonClick := DBGridEditButtonClick;
end;

procedure TFormControlTrr.DoAfterOpen;
begin
  inherited;
  FDBGrid.Columns[FDBGrid.Columns.Count-1].ButtonStyle := cbsEllipsis;
end;

procedure TFormControlTrr.DBGridEditButtonClick(Sender: TObject);
 var
  p: IMetrology;
  d: IXMLDocument;
  ie, n: IXMLNode;
  FImportExport: IImportExport;
begin
  ie := GetXNode(TPars.XMLScript, FDBGrid.Fields[2].AsString+'.MODEL.'+ FDBGrid.Fields[3].AsString);
  if Assigned(ie) then FImportExport := TImportExport.Create(ie);

  if FDBGrid.Fields[0].AsString = '' then Exit;
  if Supports(GlobalCore, IMetrology, p) then
  with TOpenDialog.Create(nil) do
   try
    InitialDir := ExtractFilePath(ParamStr(0)) + T_MTR;
    Options := Options + [ofPathMustExist, ofFileMustExist];
    DefaultExt := 'xml';
    Filter := 'Файл тарировки (*.xml)|*.xml';

    if Assigned(FImportExport) then Filter := Filter + FImportExport.GetImportFilters;

    if Execute(Handle) then
    begin
     d := NewXDocument();
     if FilterIndex > 1 then
      begin
       n := d.AddChild('TRR').AddChild(FDBGrid.Fields[1].AsString).AddChild(T_MTR).AddChild(FDBGrid.Fields[2].AsString);
       FImportExport.ExecuteImport(FilterIndex-1, FileName, n);
      end
     else d.LoadFromFile(FileName);

//     d.SaveToFile(ExtractFilePath(ParamStr(0))+'ind2.xml');

     p.Setup(FDBGrid.Fields[0].AsInteger, d.DocumentElement, ExtractFileName(FileName));
    end;
   finally
    Free;
   end;
end;

initialization
  RegisterClass(TFormControlTrr);
  TRegister.AddType<TFormControlTrr, IForm>.LiveTime(ltSingletonNamed);
finalization
  GContainer.RemoveModel<TFormControlTrr>;
end.

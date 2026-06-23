unit ControlRamForm;

interface

uses Actns,
  RootImpl, ExtendIntf, DockIForm, debug_except, DeviceIntf, PluginAPI, Xml.XMLIntf, Xml.XMLDoc, ControlDBForm, Container,
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.DBGrids, Vcl.Grids, DB;

type
  TFormControlRam = class(TFormControlDB)
  protected
    procedure DBGridEditButtonClick(Sender: TObject);
    procedure Loaded; override;
    procedure DoAfterOpen; override;
    class function ClassIcon: Integer; override;
    function GetQueryName: string; override;
    function GetSQL: string; override;
//    procedure CreateConnection; override;
  public
    const
     NICON = 143;
    //Capt, Categ: string; AImageIndex: Integer; APaths: string; AHint: string; AAutoCheck AChecked AGroupIndex AEnabled
    [StaticAction('Окно чтения памяти', 'Показать', NICON, '0:Показать:4')]
    class procedure DoCreateForm(Sender: IAction); override;
  end;

implementation

{$R *.dfm}

{ TTFormControlRam }

class function TFormControlRam.ClassIcon: Integer;
begin
  Result := NICON;
end;

//procedure TFormControlRam.CreateConnection;
//begin
//  inherited;
//  FDataSet.FieldDefs.Update;
//  FDataSet.FieldDefs.Find('С(время)').DataType := ftDateTime;
//  FDataSet.FieldDefs.Find('По(время)').DataType := ftDateTime;
//end;

procedure TFormControlRam.DBGridEditButtonClick(Sender: TObject);
 var
  d: Idialog;
begin
  if (FDBGrid.Fields[0].AsString = '')or(FDBGrid.Fields[1].AsString = '')or(FDBGrid.Fields[2].AsString = '') then Exit;
  if RegisterDialog.TryGet<Dialog_RamRead>(d) then (d as IDialog<Integer>).Execute(FDBGrid.Fields[0].AsInteger);
//  di.Execute(DIALOG_CREATE_RamRead, TDialogInputData<Integer>.Create(FDBGrid.Fields[0].AsInteger));
end;

procedure TFormControlRam.DoAfterOpen;
begin
  inherited;
  FDBGrid.Columns[FDBGrid.Columns.Count-1].ButtonStyle := cbsEllipsis;
end;

class procedure TFormControlRam.DoCreateForm(Sender: IAction);
begin
  GetUniqueForm('GlobalControlRamForm');
end;

function TFormControlRam.GetQueryName: string;
begin
  Result := 'QueViewRam';
end;

function TFormControlRam.GetSQL: string;
begin
  Result := 'select * from Customer_Ram';
end;

procedure TFormControlRam.Loaded;
begin
  inherited;
  FDBGrid.Options := FDBGrid.Options + [dgAlwaysShowEditor];
  FDBGrid.ReadOnly := True;
  FDBGrid.OnEditButtonClick := DBGridEditButtonClick;
end;

initialization
  RegisterClass(TFormControlRam);
  TRegister.AddType<TFormControlRam, IForm>.LiveTime(ltSingletonNamed);
finalization
  GContainer.RemoveModel<TFormControlRam>;
end.

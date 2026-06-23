unit DialogProject;

interface

uses  DeviceIntf, DockIForm, debug_except, ExtendIntf, intf, PluginAPI,
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls, Data.DbxSqlite, Data.DB, Data.SqlExpr;

type
  EDlgProjectException = class(EBaseException);

  TFormProject = class(TDialogIForm)
    btClose: TButton;
    SQLConnection: TSQLConnection;
    SQLMonitor1: TSQLMonitor;
    procedure btCloseClick(Sender: TObject);
  private
  protected
    procedure Execute(InputData: IInterface); override;
  public
  end;

implementation

{$R *.dfm}

const
  CREATE_XML_TBL = 'CREATE TABLE IF NOT EXISTS Devices(node_id INTEGER PRIMARY KEY, Attribute TEXT, Value TEXT)';
         XML_VLE = 'INSERT INTO %s VALUES(NULL, :path, :data)';
{ TFormProject }

procedure TFormProject.btCloseClick(Sender: TObject);
 var
  fe: IFormEnum;
  s: string;
begin
  s := ExtractFilePath(ParamStr(0)) + 'Projects\___test.db';
  if not FileExists(s) then FileClose(FileCreate(s))
  else raise Exception.Create('Error Message');

  SQLConnection.Params.Clear;
  SQLConnection.Params.Add('PRAGMA encoding = ''UTF-16le''');
  SQLConnection.Params.Add('Database=' + s );
//  SQLConnection.Params.Add(Format('ATTACH DATABASE "%s"',[s]));
  SQLConnection.Connected := true;
  SQLConnection.Execute(CREATE_XML_TBL, nil);
  SQLConnection.Execute('INSERT INTO Devices VALUES(NULL, "attr_1", "val_1")', nil);
  SQLConnection.Execute('INSERT INTO Devices VALUES(NULL, "attr_2", "val_2")', nil);
  SQLConnection.Execute('INSERT INTO Devices VALUES(NULL, "attr_3", "val_3")', nil);
  SQLConnection.Close;
  SQLMonitor1.SaveToFile(ExtractFilePath(ParamStr(0))+'Log.txt');
  if Supports(GlobalCore, IFormEnum, fe) then fe.Remove(Self);
end;

procedure TFormProject.Execute(InputData: IInterface);
begin
  Show;
end;

end.

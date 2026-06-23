unit DlgFltParam;

interface

uses AbstractDlgParams,
  RootImpl, ExtendIntf, DockIForm, debug_except, DeviceIntf, PluginAPI, Data.DB,  TypInfo, Xml.XMLIntf, RootIntf, Container,
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics, tools,  System.IOUtils,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls, VirtualTrees, Vcl.Menus, Vcl.PlatformDefaultStyleActnCtrls, Vcl.ActnPopup,
  System.Generics.Collections,
  System.Bindings.Expression,
  System.Bindings.Helper,
  System.Bindings.Graph, RTTI;

type
  TFilterParams = record
  private
    DataBase: string;
    TypeData: TypeDataShow;
  public
    constructor Create(const ADataBase: string; ATypeData: TypeDataShow);
  end;

  TFormFilterParams = class(TFormParamsAbstract, IDialog, IDialog<TFilterParams>)
  private
    FS_TableUpdate: string;
    FMetaData: IALLMetaData;
  protected
    function GetInfo: PTypeInfo; override;
    function Execute(Data: TFilterParams): Boolean;
    procedure DoApply; override;
    procedure DoExitClick; override;
  public
    property S_TableUpdate: string read FS_TableUpdate write FS_TableUpdate;
  end;

implementation

{ TFilterParams }

constructor TFilterParams.Create(const ADataBase: string; ATypeData: TypeDataShow);
begin
  DataBase := ADataBase;
  TypeData := ATypeData;
end;

{ TFormFilterParams }

procedure TFormFilterParams.DoApply;
begin
  FMetaData.Save;
  TBindings.Notify(Self, 'S_TableUpdate');
end;

procedure TFormFilterParams.DoExitClick;
begin
  RegisterDialog.UnInitialize<Dialog_FilterParameters>;
end;

function TFormFilterParams.GetInfo: PTypeInfo;
begin
  Result := TypeInfo(Dialog_FilterParameters);
end;

function TFormFilterParams.Execute(Data: TFilterParams): Boolean;
 const
  TXTDT: array [TypeDataShow] of string = ('LOG', 'RAM', 'GLU');
begin
  Result := True;
  TBindHelper.RemoveExpressions(Self);
  CheckName := AT_DB_SELECT;
  TypeData := Data.TypeData;
  FS_TableUpdate := 'Filter;' + TXTDT[TypeData] + ';' + Data.DataBase;
  FMetaData := (GContainer as IALLMetaDataFactory).Get(Data.DataBase);
  Doc := FMetaData.Get;

//  Doc.SaveToFile(ExtractFilePath(ParamStr(0))+'DB_GK.xml');

  ExecXtree(Doc.DocumentElement, procedure(n: IXMLNode)
  begin
    if ((n.NodeName = T_DEV) or (n.NodeName = T_CLC)) and not n.HasAttribute(CheckName) then n.Attributes[CheckName] := False;
  end);

//  Doc.SaveToFile(ExtractFilePath(ParamStr(0))+'DB_GK.xml');

  Bind((GContainer as IManager), 'C_TableUpdate', ['S_TableUpdate']);
  UpdateTree;
  Caption := Format('%s[%s]', [Tpath.GetFileNameWithoutExtension(Data.DataBase), TXTDT[Data.TypeData]]);
  IShow;
end;

initialization
  RegisterDialog.Add<TFormFilterParams, Dialog_FilterParameters>;
finalization
  RegisterDialog.Remove<TFormFilterParams>;
end.

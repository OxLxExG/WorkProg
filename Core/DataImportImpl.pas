unit DataImportImpl;

interface

uses System.SysUtils, DataSetIntf, DataImportIntf, RootImpl, Container,
     System.Generics.Defaults,
     System.Generics.Collections,
     debug_except;

type
  TImportDataManager = class(TIObject, IImportDataManager, IImportDataManagerRegister)
  private
    class var Imports: TDictionary<string, TExecImport>;
  protected
  //IImportDataManager = interface
    function GetFilters: string;
    function Execute(const Filter, FileName: string; out Res: IDataSet): boolean;
  //IImportDataManagerRegister = interface
    procedure  RegisterImport(const Filter: string; func: TExecImport);
  end;

implementation

{ TImportDataManager }

function TImportDataManager.Execute(const Filter, FileName: string; out Res: IDataSet): boolean;
 var
  ei: TExecImport;
begin
  if Imports.TryGetValue(Filter, ei) then Result := ei(FileName, Res)
  else Result := False;
end;

function TImportDataManager.GetFilters: string;
 var
  p: Tpair<string, TExecImport>;
begin
  Result := '';
  for p in Imports do Result := Result + ';' + p.Key;
end;

procedure TImportDataManager.RegisterImport(const Filter: string; func: TExecImport);
begin
  Imports.Add(Filter, func);
end;

initialization
  TImportDataManager.Imports := TDictionary<string, TExecImport>.Create;
  TRegister.AddType<TImportDataManager, IImportDataManager, IImportDataManagerRegister>.LiveTime(ltTransient);
finalization
  GContainer.RemoveModel<TImportDataManager>;
  TImportDataManager.Imports.Free;
end.

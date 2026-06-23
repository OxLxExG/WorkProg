unit DataImportIntf;

interface

uses DataSetIntf;

type
   TExecImport = reference to function (const FileName: string; out Res: IDataSet): boolean;

  IImportDataManager = interface
  ['{0AB55745-2019-4E84-8A27-65229D1269AC}']
    function GetFilters: string;
    function Execute(const Filter, FileName: string; out Res: IDataSet): boolean;
  end;

  IImportDataManagerRegister = interface
  ['{61CAEF75-451D-4D95-AD1F-78C348E13688}']
    procedure  RegisterImport(const Filter: string; func: TExecImport);
  end;

implementation

end.

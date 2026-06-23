unit ImportExport;

interface

uses ExtendIntf, Container,
     System.SysUtils, Vcl.Dialogs, System.Variants, Xml.XMLIntf, RootImpl, debug_except, System.TypInfo,
     System.Generics.Defaults,
     System.Generics.Collections;

type
  IImportExport = interface
  ['{F20F93A8-EB03-4EF4-A57A-8468F5FEF0B2}']
    function GetImportFilters: string;
    function GetExportFilters: string;
    procedure ExecuteImport(FilrerNo: Integer; const ImportFile: string; Etalon: IXMLNode);
    procedure ExecuteExport(FilrerNo: Integer; const ExportFile: string; Data: IXMLNode);
  end;

  TImportExport = class(TIObject, IImportExport)
  private
    Froot: IXMLNode;
    procedure Exec(const Section: string; FilrerNo: Integer; const TrrFile: string; Etalon: IXMLNode);
    function GetFilters(const Section: string): string;
  protected
    function GetImportFilters: string;
    function GetExportFilters: string;
    procedure ExecuteImport(FilrerNo: Integer; const ImportFile: string; Etalon: IXMLNode);
    procedure ExecuteExport(FilrerNo: Integer; const ExportFile: string; Data: IXMLNode);
  public
    constructor Create(Root: IXMLNode);
  end;

{  GImport = class
  private
   type
    TDialogData = record
      DialogID: PTypeInfo;
      Description: string;
    end;                                 //   категория
    class var Fitems: TDictionary<TDialogData, string>;
    class constructor Create;
    class destructor Destroy;
  public
    class procedure Add<DialogID: IInterface>(const Category, Description: string);
    class function CategoryDescriptions(const Category: string): TArray<string>;
    class function TryGet(const Category, Description: string; out Dialog: IDialog): Boolean;
  end;}

implementation

uses tools;

{ TImportExport }

constructor TImportExport.Create(Root: IXMLNode);
begin
  Froot := Root;
end;

function TImportExport.GetFilters(const Section: string): string;
 var
  a: IXMLNode;
  s: IXmlScript;
begin
  Result := '';
  for a in XEnumAttr(FRoot.ChildNodes[Section]) do
   begin
    s := (GContainer as IXMLScriptFactory).Get(nil);
    try
     s.Lines.Text := a.NodeValue;
     if not s.Compile then MessageDlg('Ошибка компиляции '+FRoot.NodeName+' '+a.NodeName+':'+s.ErrorPos, TMsgDlgType.mtError, [mbOK], 0)
     else Result := Result + '|'+ s.CallFunction('GetFilterName', [0], 1)[0];
    finally
     //s.Free;
    end;
  end;
end;

procedure TImportExport.Exec(const Section: string; FilrerNo: Integer; const TrrFile: string; Etalon: IXMLNode);
 var
  a: IXMLNode;
  s: IXmlScript;
begin
  a := FRoot.ChildNodes[Section].AttributeNodes[Section+(FilrerNo-1).ToString];
  s := (GContainer as IXMLScriptFactory).Get(nil);
  try
   s.Lines.Text := a.NodeValue;
   if not s.Compile then MessageDlg('Ошибка компиляции '+FRoot.NodeName+' '+a.NodeName+':'+s.ErrorPos, TMsgDlgType.mtError, [mbOK], 0)
   else s.CallFunction('OnExecuteFilter', [TrrFile, XToVar(Etalon)]);
  finally
   //s.Free;
  end;
end;

procedure TImportExport.ExecuteExport(FilrerNo: Integer; const ExportFile: string; Data: IXMLNode);
begin
  Exec('EXPORT', FilrerNo, ExportFile, Data);
end;

procedure TImportExport.ExecuteImport(FilrerNo: Integer; const ImportFile: string; Etalon: IXMLNode);
begin
  Exec('IMPORT', FilrerNo, ImportFile, Etalon);
end;

function TImportExport.GetImportFilters: string;
begin
  Result := GetFilters('IMPORT');
end;

function TImportExport.GetExportFilters: string;
begin
  Result := GetFilters('EXPORT');
end;

{ GImport }

{class procedure GImport.Add<DialogID>(const Category, Description: string);
 var
  d: TDialogData;
begin
  d.DialogID := TypeInfo(DialogID);
  d.Description := Description;
  Fitems.AddOrSetValue(d, Category);
end;

class function GImport.CategoryDescriptions(const Category: string): TArray<string>;
 var
  p :TPair<TDialogData, string>;
begin
  for p in Fitems do if SameText(p.Value, Category) then CArray.Add<string>(Result, p.Key.Description);
end;

class constructor GImport.Create;
begin
  Fitems := TDictionary<TDialogData, string>.Create();
end;

class destructor GImport.Destroy;
begin
  Fitems.Free;
end;

class function GImport.TryGet(const Category, Description: string; out Dialog: IDialog): Boolean;
begin

end;    }

end.

unit DataSetIntf;

interface

uses Container, RootIntf, Data.DB, Xml.XMLIntf;

type
  IDataSet = interface(IManagItem)
  ['{62A17AE5-4665-4DB2-8CE8-2C56174B9642}']
    function GetDataSet: TDataSet;
    /// <returns>
    /// возврашает директорию дл€ создани€ временных вспомогательных файлов
    /// св€занную с источником
    /// данных DataSet
    ///  и проектом
    /// </returns>
    function GetTempDir: string;
    property DataSet: TDataSet read GetDataSet;
  end;

  ///  настройки датазет в меню с изпользованием атрибута [ShowProp(....
  ///  реализаци€ TInterfacedPersistent
  ///  т.к. DataSet не сохран€ем
  ///  factory интерфейс дл€ DataSet
  IDataSetDef = interface
  ['{9031864C-F873-40E1-943E-9D065EEB1577}']
    function TryGet(out ids: IDataSet): Boolean;
    function CreateNew(out ids: IDataSet; UniDirectional: Boolean = True): Boolean;
  end;

//  IXMLDataSet = interface(IDataSet)
//  ['{9FA3ED03-2F98-4077-B354-83326456251A}']
//   function TryGetX(const FullName: string; out X: IXMLNode): Boolean;
//  end;

  IDataSetEnum = interface(IServiceManager<IDataSet>)
  ['{5CAF18C6-B981-4456-BAEE-1691DD752D6B}']
//    function TryFind(const FileName: string; out ds: IDataSet): Boolean;
  end;

  //TDataSetDialogEvent = reference to procedure(DataSet: IDataSet; var DataSetDef: IDataSetDef; SelectedFields: TArray<TField>);

 const
  IMPORT_DB_DIALOG_CATEGORY = '»мпорт данных';
  EXPORT_DIALOG_CATEGORY = 'Ёкспорт данных';

implementation

end.

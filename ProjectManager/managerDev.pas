unit managerDev;

interface

uses intf, DeviceIntf, ExtendIntf, debug_except,
    System.SysUtils, Data.DB, Xml.XMLIntf;

type
  TDevices = class(TDBEnumer<IDevice>)
  protected
    procedure DoAdd(const Item: IDevice); override;
  public
    const
     CREATE_MODULE_TBL = 'CREATE TABLE IF NOT EXISTS Modul(Адрес INTEGER NOT NULL, id INTEGER NOT NULL REFERENCES Device(id),'+
     'MetaData TEXT, Ram TEXT, Log TEXT, Eeprom TEXT)';
    procedure CreateTables; override;
    procedure LoadTables; override;
  end;

implementation

uses tools;

{ TDevices }

procedure TDevices.CreateTables;
begin
  inherited;
  Connection.Execute(CREATE_MODULE_TBL, nil);
end;

procedure TDevices.DoAdd(const Item: IDevice);
 var
  a, id: Integer;
  Res: TDataSet;
  dd: IDataDevice;
  ir: TInfoEventRes;
  u: IXMLNode;
begin
  inherited;
  if GetDevID(Connection, Item, id) then
  for a in Item.GetAddrs do
   begin
    Connection.Execute(Format('INSERT INTO Modul VALUES(%d, %d, NULL, NULL, NULL, NULL)', [a, id]), nil);
   end;
   if Supports(Item,  IDataDevice, dd) then
    begin
     ir := dd.GetMetaData;
     if Assigned(ir.Info) then for u in XEnum(ir.Info) do if u.HasAttribute(AT_ADDR) then
      begin
       Connection.Execute(Format('UPDATE Modul SET MetaData = ''%s'' WHERE (Адрес = %d) AND (id = %d)', [u.XML, Integer(u.Attributes[AT_ADDR]), id]), nil);
      end;
    end;
end;

procedure TDevices.LoadTables;
begin
  inherited;

end;



end.

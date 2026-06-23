unit ExcelImpl;

interface

uses SysUtils, Winapi.Windows,Vcl.Dialogs, Classes, Container, ExtendIntf, RootImpl, debug_except, System.TypInfo, ComObj, ActiveX,
     System.Variants;

type
  EExcelException = class(EBaseException);

  TImplExcel = class(TIObject, IReport)
  private
    FSrv, FDoc: Variant;
    function MakePropertyValue(const PropertyName: string; PropertyValue: variant): variant;
  protected
    function GetService: Variant;
    function GetDocument: Variant;
    function OpenDocument(const FileName: string): Variant;
    procedure SaveAs(const FileName: String);
    procedure CloseDocument;
  public
    destructor Destroy; override;
  end;

implementation

{ TExcelImpl }

{function TImplExcel.GetExcel: Variant;
 const
  APP = 'Excel.Application';
 var
  ClassID: TCLSID;
  i: IInterface;
  d: IDispatch;
begin
  if CLSIDFromProgID(APP, ClassID) <> S_OK then raise EExcelException.Create('класс Excel не найден !!!');
  if GetActiveObject(ClassID, nil, i) = S_OK then
    if i.QueryInterface(IDispatch, d) = S_OK then Exit(d)
    else raise EExcelException.Create('объект Excel не найден !!!');
  Result := CreateOleObject(APP);
end;

function TImplExcel.GetOOCalc: Variant;
 const
  APP = 'com.sun.star.ServiceManager';
 var
  ClassID: TCLSID;
  i: IInterface;
  d: IDispatch;
begin
  if CLSIDFromProgID(APP, ClassID) <> S_OK then raise EExcelException.Create('класс OOCalc не найден !!!');
  if GetActiveObject(ClassID, nil, i) = S_OK then
    if i.QueryInterface(IDispatch, d) = S_OK then Exit(d)
    else raise EExcelException.Create('объект OOCalc не найден !!!');
  Result := CreateOleObject(APP);
end;       }

{ TImplExcel }

procedure TImplExcel.CloseDocument;
begin
  if not (VarIsEmpty(FDoc) or VarIsNull(FDoc)) then FDoc.Close(True);
end;

destructor TImplExcel.Destroy;
begin
  CloseDocument;
  inherited;
end;

function TImplExcel.GetDocument: Variant;
begin
  Result := FDoc;
end;

function TImplExcel.GetService: Variant;
begin
  Result := FSrv;
end;

function TImplExcel.MakePropertyValue(const PropertyName: string; PropertyValue: variant): variant;
begin
  Result :=  FSrv.Bridge_GetStruct('com.sun.star.beans.PropertyValue');
  Result.Name := PropertyName;
  Result.Value := PropertyValue;
end;

function ConvertToURL(const FileName: string): string;
var
  i:integer;
  ch:char;
begin
  Result:='';
  for i:=1 to Length(FileName) do
    begin
      ch:=FileName[i];
      case ch of
        ' ':Result:=Result+'%20';
        '\':Result:=Result+'/';
      else
        Result:=Result+ch;
      end;
    end;
  Result:='file:///'+Result;
end;

function TImplExcel.OpenDocument(const FileName: string): Variant;
 var
  Desktop: Variant;
  Ar: variant;
begin
  Result := Null;
  if VarIsEmpty(FSrv) then FSrv := CreateOleObject('com.sun.star.ServiceManager');
  if VarIsEmpty(FSrv) or VarIsNull(FSrv) then raise EExcelException.Create('класс OOCalc не найден !!!');
  Desktop := FSrv.CreateInstance('com.sun.star.frame.Desktop');
  Ar := VarArrayCreate([0,1],varVariant);
  Ar[0] := MakePropertyValue('Hidden', True);
  Ar[1] := MakePropertyValue('AsTemplate', True);
  FDoc := Desktop.LoadComponentFromURL(ConvertToURL(FileName), '_blank',  0,Ar);
  if VarIsEmpty(FDoc) or VarIsNull(FDoc) then raise EExcelException.CreateFmt('файл %s не найден !!!',['file:///'+FileName]);
  Result := Fdoc;
end;

procedure TImplExcel.SaveAs(const FileName: String);
 var
  VariantArray: Variant;
begin
  VariantArray := VarArrayCreate([0, 0], varVariant);
  VariantArray[0] := MakePropertyValue('Overwrite', True);
  FDoc.StoreToURL(ConvertToURL(FileName), VariantArray);
end;

initialization
//  ShowMessage('dfsadfasf');
  TRegister.AddType<TImplExcel, IReport>.LiveTime(ltTransient);
finalization
  GContainer.RemoveModel<TImplExcel>;
end.

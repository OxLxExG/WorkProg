unit CheckFormSetup;

interface

uses RootImpl,  debug_except, JDtools,
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics, Xml.XMLIntf,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls, JvComponentBase, JvInspector, JvExControls;

type
  TFormCheckSetup = class(TForm)
    insp: TJvInspector;
    InspectorBorlandPainter: TJvInspectorBorlandPainter;
    btOK: TButton;
    btCancel: TButton;
  private
    FMetrolog: string;
    FDate: TDate;
    FRoom: string;
    FUsedStol: string;
    FMaker: string;
    FCategory: string;
    FDevName: string;
    FDevNo: Integer;
    FNextDate: TDate;
    FReady: Boolean;
 protected
    FRoot: IXMLNode;
    function getp(r: IXMLNode; const attr: string; def: Variant): Variant;
    procedure DoBeforeShow; virtual;
    procedure DoApplySettings; virtual;
  public
    [ShowProp('Наименование прибора')]             property DevName: string read FDevName write FDevName;
    [ShowProp('Заводской номер прибора', True)]    property DevNo: Integer read FDevNo write FDevNo;
    [ShowProp('Изготовитель')]                     property Maker: string read FMaker write FMaker;
    [ShowProp('Используемое оборудование')]        property UsedStol: string read FUsedStol write FUsedStol;
    [ShowProp('Категория и принадлежность средств измерения')] property Category: string read FCategory write FCategory;
    [ShowProp('Условия проверки')]                 property Room: string read FRoom write FRoom;
    [ShowProp('Прибор готов')]                     property Ready: Boolean read FReady write FReady;
    [ShowProp('Дата следующей поверки')]           property NextDate: TDate read FNextDate write FNextDate;
    [ShowProp('Дата поверки')]                     property Date: TDate read FDate write FDate;
    [ShowProp('Поверку провел')]                   property Metrolog: string read FMetrolog write FMetrolog;
    class function Execute(Root: IXMLNode): Boolean;
  end;

implementation

{$R *.dfm}

uses tools, math;

{ TFormInclinCheckSetup }

procedure TFormCheckSetup.DoApplySettings;
begin
  FRoot.Attributes['DevName'] := DevName;
  FRoot.Attributes['Maker'] := Maker;
  FRoot.Attributes['UsedStol'] := UsedStol;
  FRoot.Attributes['Category'] := Category;
  FRoot.Attributes['Room'] := Room;
  FRoot.Attributes['Metrolog'] := Metrolog;
  FRoot.Attributes['Ready'] := Ready;
  FRoot.Attributes['NextDate'] := DateToStr(NextDate);
  FRoot.Attributes[AT_TIMEATT] := DateToStr(Date);
end;

procedure TFormCheckSetup.DoBeforeShow;
begin
  DevNo :=    getp(FRoot.ParentNode.ParentNode.ParentNode, AT_SERIAL, 1000);
  Maker :=    getp(FRoot, 'Maker', 'ООО НПФ "АМК Горизонт"');
  Category := getp(FRoot, 'Category', 'Рабочее СИ, ООО НПФ "АМК Горизонт"');
  Metrolog := getp(FRoot, 'Metrolog', '');
  Ready :=    getp(FRoot, 'Ready', True);
  Date :=     StrToDate(getp(FRoot, AT_TIMEATT, DateToStr(Now)));
  DevName :=  getp(FRoot, 'DevName', FRoot.ParentNode.ParentNode.ParentNode.NodeName +'.'+FRoot.ParentNode.NodeName);
  NextDate := StrToDate(getp(FRoot, 'NextDate', DateToStr(Now+90)));
end;

function TFormCheckSetup.getp(r: IXMLNode; const attr: string; def: Variant): Variant;
begin
  if r.HasAttribute(attr) then Result := r.Attributes[attr]
  else Result := def
end;

class function TFormCheckSetup.Execute(Root: IXMLNode): Boolean;
 var
  o: TFormCheckSetup;
begin
  o := Create(nil);
  with o do
   try
    FRoot := Root;
    DoBeforeShow;
    Insp.Root.SortKind := iskNone;
    ShowPropAttribute.Apply(o, Insp);
    Result := ShowModal() = mrOk;
    if not Result then Exit;
    DoApplySettings;
   finally
    Free;
   end;
end;

end.

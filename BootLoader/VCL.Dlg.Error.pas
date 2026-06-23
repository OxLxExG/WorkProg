unit VCL.Dlg.Error;

interface

uses DeviceIntf, RootImpl, RootIntf, ExtendIntf, DockIForm,  System.TypInfo, PluginAPI, Actns, Container, debug_except,
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls;

const
   CMD_EROR = $E;
type
  EFormErrorError = class(EBaseException);
  TFormError = class(TDockIForm)
    btOK: TButton;
    btClear: TButton;
    edAdr: TEdit;
    Label1: TLabel;
    MemoX: TMemo;
    procedure ReadClick(Sender: TObject);
  private
    { Private declarations }
    function GetDevice(adr: Integer): ILowLevelDeviceIO;
  protected
   const
    NICON = 290;
    class function ClassIcon: Integer; override;
  public
    [StaticAction('Обработка ошибок', 'Отладочные', NICON, '0:Показать.Отладочные:-1')]
    class procedure DoCreateForm(Sender: IAction); override;
  end;

implementation

{$R *.dfm}

uses tools;

{ TFormError }


function TFormError.GetDevice(adr: Integer): ILowLevelDeviceIO;
 var
  d: IDevice;
  a: Integer;
  de: IDeviceEnum;
begin
  if Supports(GlobalCore, IDeviceEnum, de) then
   for d in de do for a in d.GetAddrs do if a = adr then
     if d.Status in [dsNoInit, dsPartReady, dsReady] then Exit(d as ILowLevelDeviceIO)
     else raise EFormErrorError.Create(Format('Устройство с адресом %d в работе',[adr]));
  raise EFormErrorError.Create(Format('Нет устройств с адресом %d',[adr]));
end;


procedure TFormError.ReadClick(Sender: TObject);
 var
  a: array[0..3] of Byte;
  adr: Integer;
begin
  adr := StrToInt(edAdr.Text);
  if Sender = btClear then  a[1] := $A5 else a[1] := 0;
  a[0] := (adr shl 4) or CMD_EROR;
  GetDevice(adr).SendROW(@a[0], 2, procedure(p: Pointer; n: integer)
   var
    i: Integer;
    s: string;
    b: PByteArray;
  begin
    b := p;
    if n < 2 then memox.Lines.Add('нет ответа')
    else if b[0] = a[0] then
     begin
      memox.Lines.Add('');
      memox.Lines.Add(Format('код ошибки: %d  0x%x', [b[1], b[1]]));
      s := '';
      for i := 0 to n - 1 do s := s + Format('%2.2x ', [b[i]]);
      memox.Lines.Add(s);
      memox.Lines.Add('');
      memox.Lines.Add(string(PAnsiChar(@b[2])));
     end
    else memox.Lines.Add(Format('пришел BAD пакет %x <> %x', [b[0], a[0]]));
  end);
end;

class function TFormError.ClassIcon: Integer;
begin
  Result := NICON;
end;

class procedure TFormError.DoCreateForm(Sender: IAction);
begin
  GetUniqueForm('GlobalFormError');
end;

initialization
  RegisterClass(TFormError);
  TRegister.AddType<TFormError, IForm>.LiveTime(ltSingletonNamed);
finalization
  GContainer.RemoveModel<TFormError>;
end.

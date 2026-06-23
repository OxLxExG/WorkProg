unit VCLDlgConnectIO;

interface

uses RootImpl, DeviceIntf, debug_except, ExtendIntf,
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs,
  Vcl.StdCtrls, CPortCtl, Vcl.ComCtrls;

type
  TFormSetupConnect = class(TForm)
    sb: TStatusBar;
    ButtonOK: TButton;
    btTest: TButton;
    EdWait: TEdit;
    Label2: TLabel;
    Button1: TButton;
    btClose: TButton;
    btOpen: TButton;
    procedure FormShow(Sender: TObject);
    procedure ButtonOKClick(Sender: TObject);
    procedure btCloseClick(Sender: TObject);
    procedure btOpenClick(Sender: TObject);
    procedure btTestClick(Sender: TObject);
  public
    Item : IConnectIO;
    function CreateConnectInfo: string; virtual; abstract;
    procedure PortClose();
    procedure SetupButtons(Isopen: Boolean; const port: string);
    class function Execute(ConnectIO :IConnectIO): TModalResult;
  end;
  resourcestring
   RS_portNotOpen='Порт %s открыить не удалось';
   RS_TestOK='Тест %s прошел';
   RS_TestBAD='Тест %s НЕ прошел';
   RS_CloseErr='Закрыть порт не удается, необходимо удалить Подключение';
   RS_Close='Порт %s закрыт';
   RS_Open='Порт %s открыт';

implementation

{$R *.dfm}

class function TFormSetupConnect.Execute(ConnectIO: IConnectIO): TModalResult;
begin
  with Create(nil) do
  try
   Item := ConnectIO;
   Result := ShowModal;
  finally
   Free;
  end;
end;

procedure TFormSetupConnect.btCloseClick(Sender: TObject);
begin
  PortClose();
  SetupButtons(Item.IsOpen, Item.ConnectInfo);
end;

procedure TFormSetupConnect.btOpenClick(Sender: TObject);
begin
  try
   Item.Open;
   SetupButtons(Item.IsOpen, Item.ConnectInfo);
  except
   sb.Panels[0].text := Format(RS_portNotOpen, [Item.ConnectInfo]);
   raise;
  end;
end;

procedure TFormSetupConnect.btTestClick(Sender: TObject);
 var
  opn: Boolean;
//  old: string;
begin
  opn := Item.IsOpen;
//  old := Item.ConnectInfo;
  try
   PortClose();
   Item.ConnectInfo := CreateConnectInfo;
   Item.Open;
   sb.Panels[0].text := Format(RS_TestOK,[Item.ConnectInfo]);
   if not opn then Item.Close;
  except
   sb.Panels[0].text := Format(RS_TestBAD,[Item.ConnectInfo]);
//   io.Close;
//   io.ConnectInfo := old;
//   cbCom.Text := old;
//   if opn then io.Open;
  end;
end;

procedure TFormSetupConnect.ButtonOKClick(Sender: TObject);
begin
  Item.ConnectInfo := CreateConnectInfo;
  Item.Wait := StrToInt(EdWait.Text);
end;

procedure TFormSetupConnect.PortClose();
begin
  try
   Item.Close;
  except
   MessageDlg(RS_CloseErr, TMsgDlgType.mtError, [mbOK], 0);
   raise;
  end;
end;

procedure TFormSetupConnect.FormShow(Sender: TObject);
begin
  EdWait.Text := IntToStr(Item.Wait);
  SetupButtons(Item.IsOpen, Item.ConnectInfo);
end;

procedure TFormSetupConnect.SetupButtons(Isopen: Boolean; const port: string);
begin
  if IsOpen then
   begin
    sb.Panels[0].text := Format(RS_Open,[port]);
    btOpen.Enabled := False;
    btClose.Enabled := True;
   end
  else
   begin
    btOpen.Enabled := True;
    btClose.Enabled := False;
    sb.Panels[0].text := Format(RS_Close,[port]);
   end;
end;

end.

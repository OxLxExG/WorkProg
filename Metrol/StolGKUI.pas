unit StolGKUI;

interface

uses DeviceIntf, PluginAPI, ExtendIntf, RootIntf, Container, Actns, debug_except, DockIForm, StolGKIntf, RootImpl, tools,
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics, Vcl.Menus,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls, Vcl.ExtCtrls, Vcl.ComCtrls, Vcl.Buttons;

type
  TFormStolGK = class(TCustomFontIForm)
    btStop: TButton;
    sb: TStatusBar;
    cb: TComboBox;
    lbPosition: TLabel;
    btGo: TButton;
    btAct: TSpeedButton;
    procedure btStopClick(Sender: TObject);
    procedure btGoClick(Sender: TObject);
    procedure btActClick(Sender: TObject);
  private
    FBinded: Boolean;
    FC_Actuator: Boolean;
    FC_StatusStol: TStatusStol;
    FC_Position: Integer;
    function GetStolGK: IStolGK;
    procedure ComSetupClick(Sender: TObject);
    procedure ComSetupConnection(u: IStolGK);
    procedure UpdateScreen(e: TEventStol; const cmd: AnsiString);
    procedure SetC_Actuator(const Value: Boolean);
    procedure SetC_Position(const Value: Integer);
    procedure SetC_StatusStol(const Value: TStatusStol);
  protected
   const
    NICON = 274;
    procedure InitializeNewForm; override;
    procedure Loaded; override;
    class function ClassIcon: Integer; override;
  public
    [StaticAction('Стол аттестации ГК', 'Метрология', NICON, '0:Метрология.ГК:0')]
    class procedure DoCreateForm(Sender: IAction); override;
    property StolGK: IStolGK read GetStolGK;
    property C_Actuator: Boolean read FC_Actuator write SetC_Actuator;
    property C_Position: Integer read FC_Position write SetC_Position;
    property C_StatusStol: TStatusStol read FC_StatusStol write SetC_StatusStol;
  end;

implementation

{$R *.dfm}

{ TFormStolGK }

class function TFormStolGK.ClassIcon: Integer;
begin
  Result := NICON
end;

class procedure TFormStolGK.DoCreateForm(Sender: IAction);
begin
  GetUniqueForm('GlobalStolGKForm');
end;

procedure TFormStolGK.InitializeNewForm;
begin
  inherited;
  AddToNCMenu('Установки соединения...', ComSetupClick);
end;

procedure TFormStolGK.Loaded;
 var
  a: string;
begin
  inherited;
  cb.Items.Clear;
  for a in StolGK.Commands do cb.Items.Add(a);
  lbPosition.Caption := '-----';
  sb.Panels[0].Text := '';
  sb.Panels[1].Text := '';
  sb.Panels[2].Text := '';
end;

procedure TFormStolGK.ComSetupClick(Sender: TObject);
begin
  ComSetupConnection(StolGK);
end;

procedure TFormStolGK.ComSetupConnection(u: IStolGK);
 var
  c: IConnectIO;
  ge: IConnectIOEnum;
  gc: IGetConnectIO;
  d: IDialog;
begin
  if Assigned(u) and not Assigned(u.IConnect) then
   begin
    if Supports(GlobalCore, IConnectIOEnum, ge) and Supports(GlobalCore, IGetConnectIO, gc) then
     begin
       c := gc.ConnectIO(1);
       if RegisterDialog.TryGet<Dialog_SetupConnectIO>(d) then (d as IDialog<IConnectIO>).Execute(c);
       u.IConnect := c;
       ge.Add(c);
     end;
   end
  else if RegisterDialog.TryGet<Dialog_SetupConnectIO>(d) then (d as IDialog<IConnectIO>).Execute(u.IConnect);
end;

function TFormStolGK.GetStolGK: IStolGK;
 var
  g: IGetDevice;
  de: IDeviceEnum;
  d: IDevice;
  a: TAddressArray;
begin
  try
  if Supports(GlobalCore, IGetDevice, g) and Supports(GlobalCore, IDeviceEnum, de) then
   begin
    for d in de.Enum() do if Supports(d, IStolGK, Result) then Exit;
    SetLength(a, 1);
    a[0] := ADR_STOL_GK;
    d := g.Device(a, 'STOL_GK', 'STOL_GK');
    de.Add(d);
    FBinded := False;
    Result := d as IStolGK;
    ComSetupConnection(Result);
   end;
  finally
   if not FBinded then
    begin
     Bind('C_Actuator', d, ['S_Actuator']);
     Bind('C_Position', d, ['S_Position']);
     Bind('C_StatusStol', d, ['S_StatusStol']);
     FBinded := True;
    end;
  end;
end;

procedure TFormStolGK.btActClick(Sender: TObject);
begin
  StolGK.Actuator(btAct.Down, UpdateScreen);
end;

procedure TFormStolGK.btGoClick(Sender: TObject);
begin
  StolGK.Run(cb.Text, UpdateScreen);
end;

procedure TFormStolGK.btStopClick(Sender: TObject);
begin
  StolGK.Stop(UpdateScreen);
end;

procedure TFormStolGK.SetC_Actuator(const Value: Boolean);
begin
  btAct.Down := Value;
end;

procedure TFormStolGK.SetC_Position(const Value: Integer);
begin
  lbPosition.Caption := Value.ToString;
end;

procedure TFormStolGK.SetC_StatusStol(const Value: TStatusStol);
begin
  if ssSync in Value then
   begin
    lbPosition.Caption := StolGK.Position.ToString;
    sb.Panels[0].Text := 'SYNC'
   end
  else
   begin
    lbPosition.Caption := '-----';
    sb.Panels[0].Text := '';
   end;
  if ssRun in Value then sb.Panels[1].Text := 'RUN' else sb.Panels[1].Text := '';
end;


procedure TFormStolGK.UpdateScreen(e: TEventStol; const cmd: AnsiString);
  var
   sp, ss,c, txt: string;
   sa: TArray<string>;
  function CtoTxt(const cz: AnsiString): Boolean;
    var
     a: TAnswer;
  begin
    for a in STOL_GK_AVAIL_ACSWER do if a.Str = cz then
     begin
      txt := txt + ' ' +a.text;
      Exit(True);
     end;
    Result := False;
  end;
begin
  with StolGK do
   begin
{     if ssSync in StatusStol then
      begin
       lbPosition.Caption := Position.ToString;
       sb.Panels[0].Text := 'SYNC';
      end
     else
      begin
       lbPosition.Caption := '-----';
       sb.Panels[0].Text := '';
      end;

     if ssRun in StatusStol then sb.Panels[1].Text := 'RUN' else sb.Panels[1].Text := '';}

     txt := STOL_GK_EVENT_INFO[e];
     sp := '';
     ss := '';
     c := '';
     if cmd <> '' then
      begin
       sa := string(cmd).Split(['|'], TStringSplitOptions.ExcludeEmpty);
       if Length(sa) = 2 then
        begin
         sp := sa[0];
         ss := sa[1];
         txt := 'Пакет: '+sp+ ' '+txt ;
        end
       else if string(cmd).Contains('|') then
        begin
         sp := sa[0];
         txt := 'Пакет: '+sp+ ' '+txt;
        end
       else ss := sa[0];
       if ss <> '' then
        begin
         sa := ss.Split(['*'], TStringSplitOptions.ExcludeEmpty);
         ss := '';
         if Length(sa) = 2 then
          begin
           ss := sa[0];
           c := sa[1];
          end
         else c := sa[0];
         if (ss <> '') and (ss+'*' <> sp) then
          begin
           txt := txt + ' Команда: ' + ss;
          end;
         if not CtoTxt(AnsiString(c + '*')) then txt := txt + ' ОШ.' + c;
        end;
      end;
  //  TDebug.Log(txt);
    sb.Panels[2].Text := txt;
   end;
end;

initialization
  RegisterClass(TFormStolGK);
  TRegister.AddType<TFormStolGK, IForm>.LiveTime(ltSingletonNamed);
finalization
  GContainer.RemoveModel<TFormStolGK>;
end.

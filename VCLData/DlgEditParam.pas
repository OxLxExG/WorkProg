unit DlgEditParam;

interface

uses RootImpl, ExtendIntf, DockIForm, debug_except, DeviceIntf, PluginAPI,  RTTI, Container, RootIntf, JDtools,
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics, System.UITypes, System.TypInfo,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls, JvExControls, JvInspector, Vcl.ExtCtrls, JvComponentBase,
  Vcl.Themes;

type
  TFormEditParam = class(TDialogIForm, IDialog, IDialog<TObject>)
    btExit: TButton;
    Insp: TJvInspector;
    Painter: TJvInspectorDotNETPainter;
    procedure btExitClick(Sender: TObject);
  private
    FEditParam: TObject;
  public
    { Public declarations }
  protected
    procedure SetDark;
    function GetInfo: PTypeInfo; override;
    function Execute(InputData: TObject): Boolean;
  end;

  TFormEditArrayParam = class(TFormEditParam, IDialog<TArray<TObject>, TNotifyEvent, TNotifyEvent>)
    procedure btExitClick(Sender: TObject);
  private
    FEditParams: TArray<TObject>;
  public
    function GetInfo: PTypeInfo; override;
    function Execute(InputData: TArray<TObject>; Before, Afte: TNotifyEvent): Boolean; reintroduce;
  end;


implementation

{$R *.dfm}

uses SetGPClolor, tools;

{ TFormEditParam }

procedure TFormEditParam.btExitClick(Sender: TObject);
begin
  RegisterDialog.UnInitialize<Dialog_EditViewParameters>;
end;

function TFormEditParam.Execute(InputData: TObject): Boolean;
begin
  Result := True;
  FEditParam := InputData;
  Insp.Root.SortKind := iskNone;
  SetDark;
  ShowPropAttribute.Apply(FEditParam, Insp);
  IShow;
end;

function TFormEditParam.GetInfo: PTypeInfo;
begin
  Result := TypeInfo(Dialog_EditViewParameters);
end;

procedure TFormEditParam.SetDark;
begin
  if CurrentThemeIsDark then
   begin
    Painter.BackgroundColor := clThBkg;
    Painter.NameFont.Color := clThWindowTextNormal;
    Painter.ValueFont.Color := clSkyBlue;
    Painter.CategoryColor := clThButtonNormal;
    Painter.CategoryFont.Color := clThWindowTextNormal;
    Painter.DividerColor := clThBorder;
    Painter.GridColor1 := clThBorder;
    Painter.GridColor2 := clThBorder;
   end;

end;

procedure TFormEditArrayParam.btExitClick(Sender: TObject);
begin
  RegisterDialog.UnInitialize<Dialog_EditArrayParameters>;
end;

{ TFormEditArrayParam }

//procedure TFormEditArrayParam.btExitClick(Sender: TObject);
//begin
//end;

function TFormEditArrayParam.Execute(InputData: TArray<TObject>; Before, Afte: TNotifyEvent): Boolean;
begin
  Result := True;
  FEditParams := InputData;
  SetDark;
  Insp.Root.SortKind := iskNone;
  ShowPropAttribute.Apply(FEditParams, Insp, Before, Afte);
  IShow;
end;

function TFormEditArrayParam.GetInfo: PTypeInfo;
begin
  Result := TypeInfo(Dialog_EditArrayParameters);
end;

initialization
  RegisterDialog.Add<TFormEditParam, Dialog_EditViewParameters>;
  RegisterDialog.Add<TFormEditArrayParam, Dialog_EditArrayParameters>;
  TCustomStyleEngine.RegisterStyleHook(TJvInspector, TScrollingStyleHook);

finalization
  RegisterDialog.Remove<TFormEditParam>;
  RegisterDialog.Remove<TFormEditArrayParam>;
end.

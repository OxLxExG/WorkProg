unit ExceptionForm;

interface

uses System.SysUtils,  ExtendIntf, RootImpl, debug_except, DeviceIntf, DockIForm,
  Winapi.Windows, Winapi.Messages, System.Variants, System.Classes, Vcl.Graphics, System.Rtti,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls, Vcl.Menus,  Winapi.ActiveX, System.Win.ComObj, JvDockControlForm,
  Vcl.PlatformDefaultStyleActnCtrls, Vcl.ActnPopup, PluginAPI, Vcl.ActnList, Vcl.StdActns, System.Actions;

type
  TFormExceptions = class(TDockIForm, INotifyBeforeClean)
    Memo: TMemo;
    procedure FormShow(Sender: TObject);
  private
    procedure NDialogClick(Sender: TObject);
    procedure NClearClick(Sender: TObject);
    procedure NSaveAsClick(Sender: TObject);
    procedure NCloseClick(Sender: TObject);
    class procedure AsyncException(const CsName, msg, StackTrace: WideString);
  protected
    procedure DoShow;  override;
    procedure BeforeClean(var CanClean: Boolean); //virtual;
    procedure InitializeNewForm; override;
    function Priority: Integer; override;
    class function ClassIcon: Integer; override;
  public
    NShowDebug: TMenuItem;
    NDialog: TMenuItem;
    class var This: TFormExceptions;
    destructor Destroy; override;
    class procedure Init();
    class procedure DeInit();
  end;

implementation

{$R *.dfm}

uses PluginManager;

{ TFormDebug }

class function TFormExceptions.ClassIcon: Integer;
begin
  Result := 257;
end;

class procedure TFormExceptions.Init;
 var
  fe: IFormEnum;
begin
  if Assigned(This) then Exit;
  TDebug.ExeptionEvent := AsyncException;
  This := TFormExceptions.CreateUser('FormExceptions');
  (This as IInterface)._AddRef();
  This.NClose.OnClick := This.NCloseClick;
  if Supports(Plugins, IFormEnum, fe)then fe.Add(This as Iform);
end;

procedure TFormExceptions.InitializeNewForm;
begin
  inherited;
  AddToNCMenu('-');
  AddToNCMenu('Clear', NClearClick);
  AddToNCMenu('-');
  NDialog := AddToNCMenu('Show Dialog', NDialogClick, -1, 0);
//  NDialog.AutoCheck := True;
  NShowDebug := AddToNCMenu('Show stack', nil, -1, 1);
//  NShowDebug.AutoCheck := True;
//  NShowDebug.Checked := True;
  AddToNCMenu('-');
  AddToNCMenu('Save to file...', NSaveAsClick);
  FDockClient.OnFormShow := nil;
  FDockClient.OnFormHide := nil;
end;

class procedure TFormExceptions.DeInit;
begin
  if Assigned(This) then
   begin
    This.RemoveSelfFromDock;
    FreeAndNil(This);
   end;
end;

destructor TFormExceptions.Destroy;
begin
  TDebug.ExeptionEvent := nil;
  This := nil;
  TDebug.Log('TFormExceptions.Destroy');
  inherited;
end;

procedure TFormExceptions.DoShow;
begin
  inherited;
  FEnableCloseDialog := False;
end;

procedure TFormExceptions.BeforeClean(var CanClean: Boolean);
begin
  CanClean := False;
end;

procedure TFormExceptions.NCloseClick(Sender: TObject);
begin
  HideDockForm(Self);
end;

procedure TFormExceptions.NDialogClick(Sender: TObject);
begin
  if NDialog.Checked then TDebug.ExeptionEvent := nil
  else TDebug.ExeptionEvent := AsyncException;
end;

procedure TFormExceptions.NSaveAsClick(Sender: TObject);
begin
  with TSaveDialog.Create(nil) do
  try
   InitialDir := ExtractFilePath(ParamStr(0));
   DefaultExt := 'txt';
   Options := Options + [ofOverwritePrompt, ofPathMustExist];
   Filter := 'File (*.txt)|*.txt';
   if Execute(Handle) then Memo.Lines.SaveToFile(FileName);
  finally
   Free;
  end;
end;

function TFormExceptions.Priority: Integer;
begin
  Result := PRIORITY_NoStore;
end;

procedure TFormExceptions.FormShow(Sender: TObject);
begin
  Icon := ClassIcon;
end;

procedure TFormExceptions.NClearClick(Sender: TObject);
begin
  Memo.Clear;
end;

class procedure TFormExceptions.AsyncException(const CsName, msg, StackTrace: WideString);
 var
  i: Integer;
begin
  if not Assigned(This) then Exit;
  with This do
   begin
    if CsName = 'EAbort' then Exit;
    if Pos('no user Err', string(msg)) > 0  then Exit;
    Memo.Lines.BeginUpdate;
    if NShowDebug.Checked then
     begin
      if string(StackTrace).Trim <> '' then Memo.Lines.Insert(0, string(StackTrace));
      Memo.Lines.Insert(0, FormatDateTime('hh:nn:ss.zzz', Now)+': ' + string(CsName) + '    ' + string(msg));
     end
    else
     begin
      i := Pos('[', string(msg));
      if i > 0 then Memo.Lines.Insert(0, FormatDateTime('hh:nn:ss.zzz', Now)+': ' + string(CsName) + '    ' + Copy(string(msg), 1, i-2))
      else Memo.Lines.Insert(0, FormatDateTime('hh:nn:ss.zzz', Now)+': ' + string(CsName) + '    ' + string(msg));
     end;
    while Memo.Lines.Count > 100 do Memo.Lines.Delete(Memo.Lines.Count-1);
    Memo.Lines.EndUpdate;
   end;
end;

end.


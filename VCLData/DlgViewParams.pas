unit DlgViewParams;

interface

uses  RootImpl, ExtendIntf, DockIForm, debug_except, DeviceIntf, PluginAPI, Container, RootIntf,  System.TypInfo,
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls, Vcl.CheckLst;

type
  TUpdateFunc = TProc<TArray<string>>;

  TSelectParamsStrings = record
//  private
    All: TArray<string>;
    Selected: TArray<string>;
    UpdateNotify: TUpdateFunc;

    // OwnerName: string;
    // OwnerModel: PtypeInfo;
  end;

  TFormSelectViewParams = class(TDialogIForm, IDialog, IDialog<TSelectParamsStrings>)
    btApply: TButton;
    btExit: TButton;
    clb: TCheckListBox;
    procedure btExitClick(Sender: TObject);
    procedure btApplyClick(Sender: TObject);
    procedure clbClickCheck(Sender: TObject);
  private
    Fparams: TSelectParamsStrings;
  protected
    function GetInfo: PTypeInfo;
    procedure Execute(InputData: TSelectParamsStrings);
  end;

implementation

{$R *.dfm}

uses tools;

{TFormSelectParams}

procedure TFormSelectViewParams.btApplyClick(Sender: TObject);
 var
  i: Integer;
  s: TArray<string>;
begin
  btApply.Enabled := False;
//  if GContainer.Contains(OwnerModel, OwnerName) then ...
  for i := 0 to clb.Count-1 do if clb.Checked[i] then CArray.Add<string>(s, clb.Items[i]);
  Fparams.UpdateNotify(s);
end;

procedure TFormSelectViewParams.btExitClick(Sender: TObject);
begin
  RegisterDialog.UnInitialize<Dialog_SelectViewParameters>
end;

procedure TFormSelectViewParams.clbClickCheck(Sender: TObject);
begin
  btApply.Enabled := True;
end;

procedure TFormSelectViewParams.Execute(InputData: TSelectParamsStrings);
 var
  s: string;
begin
  Fparams := InputData;
  clb.Clear;
  for s in Fparams.All do clb.AddItem(s, nil);
  for s in Fparams.Selected do if clb.Items.IndexOf(s) > -1 then clb.Checked[clb.Items.IndexOf(s)] := True;
  IShow;
end;

function TFormSelectViewParams.GetInfo: PTypeInfo;
begin
  Result := TypeInfo(Dialog_SelectViewParameters);
end;

initialization
  RegisterDialog.Add<TFormSelectViewParams, Dialog_SelectViewParameters>;
finalization
  RegisterDialog.Remove<TFormSelectViewParams>;
end.

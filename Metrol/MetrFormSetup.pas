unit MetrFormSetup;

interface

uses MetrForm, RootIntf,
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Xml.XMLIntf, Vcl.StdCtrls, Vcl.ComCtrls;

type
  TFormMetrSetup = class(TForm)
    btOK: TButton;
    btCancel: TButton;
    edNAtt: TEdit;
    lbNatt: TLabel;
    lbDev: TLabel;
    edDev: TEdit;
    cbAny: TCheckBox;
    lbSerial: TLabel;
    edSerial: TEdit;
    lbTrr: TLabel;
    dtTrr: TDateTimePicker;
    procedure cbAnyClick(Sender: TObject);
    procedure dtTrrChange(Sender: TObject);
  private
    Frm: TFormMetrolog;
    FlagChangeTrrData: Boolean;
  public
    class function Execute(FormMetrolog: TFormMetrolog): Boolean;
  end;

implementation

{$R *.dfm}

uses tools;
{ TFormMetrSetup }

procedure TFormMetrSetup.cbAnyClick(Sender: TObject);
begin
  edDev.Enabled := not cbAny.Checked;
  lbDev.Enabled := not cbAny.Checked;
end;

procedure TFormMetrSetup.dtTrrChange(Sender: TObject);
begin
  FlagChangeTrrData := True;
end;

class function TFormMetrSetup.Execute(FormMetrolog: TFormMetrolog): Boolean;
 var
  m, r: IXMLNode;
begin
  with TFormMetrSetup.Create(nil) do
   try
    Result := False;
    Frm := FormMetrolog;
    edNAtt.Text := Frm.AttCount.ToString;
    if not Assigned(Frm.FileData) then
     begin
      lbDev.Enabled := False;
      edDev.Enabled := False;
      cbAny.Enabled := False;
      lbSerial.Enabled := False;
      edSerial.Enabled := False;
      lbTrr.Enabled := False;
      dtTrr.Enabled := False;
     end
    else with Frm do
     begin
      m := GetMetr([MetrolType], FileData);
      r := m.ParentNode.ParentNode.ParentNode;
      edDev.Text := r.NodeName;
      cbAny.Checked := edDev.Text = 'ANY_DEVICE';
      cbAnyClick(nil);
      if r.HasAttribute(AT_SERIAL) then edSerial.Text := r.Attributes[AT_SERIAL];
      if m.HasAttribute(AT_TIMEATT) then dtTrr.DateTime := StrToDate(m.Attributes[AT_TIMEATT]);
     end;
    Result := ShowModal = mrOk;
    if not Result then Exit;
//    Frm.AttCount := StrToInt(edNAtt.Text);
//    if Frm.AttCount <= 0  then Frm.AttCount := 1;
    if Assigned(Frm.FileData) then
     begin
      if cbAny.Checked then edDev.Text := 'ANY_DEVICE';
      if m.ParentNode.ParentNode.ParentNode.NodeName <> edDev.Text then RenameXMLNode(m.ParentNode.ParentNode.ParentNode, edDev.Text);
      if StrToInt(edSerial.Text) > 0 then r.Attributes[AT_SERIAL] := edSerial.Text;
      if FlagChangeTrrData then m.Attributes[AT_TIMEATT] := DateToStr(dtTrr.DateTime);
     end;
   finally
    Free;
   end;
end;

end.

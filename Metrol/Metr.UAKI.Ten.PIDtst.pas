unit Metr.UAKI.Ten.PIDtst;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.ExtCtrls, Vcl.StdCtrls,  System.StrUtils,
  //VCLTee.TeEngine, VCLTee.Series, VCLTee.TeeProcs, VCLTee.Chart,
  DeviceIntf, PluginAPI, ExtendIntf, RootIntf, Container, Actns, debug_except, DockIForm, UakiIntf, RootImpl, Vcl.Mask,
  //JvExMask, JvToolEdit,
//  Data.Bind.EngExt, Vcl.Bind.DBEngExt, System.Rtti, System.Bindings.Outputs, Vcl.Bind.Editors,Data.Bind.Components,
  Xml.XMLIntf, tools;

type
  TFormPIDsetup = class(TCustomFontIForm)
    Panel1: TPanel;
    edInt: TEdit;
    edT: TEdit;
    btStart: TButton;
    lbTincl: TLabel;
    lbPower: TLabel;
    lbT: TLabel;
    Label6: TLabel;
    Label5: TLabel;
    Label3: TLabel;
    Label2: TLabel;
    Label1: TLabel;
    Label4: TLabel;
    edKp: TEdit;
    Label7: TLabel;
    edKi: TEdit;
    Label8: TLabel;
    edKd: TEdit;
    procedure btStartClick(Sender: TObject);
    procedure TimerTimer(Sender: TObject);
    procedure odAfterDialog(Sender: TObject; var AName: string; var AAction: Boolean);
    procedure FormDestroy(Sender: TObject);
  private
    FStream: TStreamWriter;
    FTempNode: IXMLNode;
    FFile: string;
    FC_TenUpdate: Integer;
    FBinded: Boolean;
    function GetUaki: IUaki;
    procedure SetC_TenUpdate(const Value: Integer);
    procedure UpdateScreen;
    procedure UpdateChart(const FileName: string);
    function GetInclinT: Double;
  protected
    procedure Loaded; override;
   const
    NICON = 273;
    class function ClassIcon: Integer; override;
  public
    [StaticAction('УАК-СИ-PID-setup', 'Метрология', NICON, '0:Метрология.Инклинометры:-1')]
    class procedure DoCreateForm(Sender: IAction); override;
    property Uaki: IUaki read GetUaki;
    property InclinT: Double read GetInclinT;
    property C_TenUpdate: Integer read FC_TenUpdate write SetC_TenUpdate;
  end;

//var
//  FormPIDsetup: TFormPIDsetup;

implementation

{$R *.dfm}

uses PID;

{ TFormPIDsetup }

procedure TFormPIDsetup.btStartClick(Sender: TObject);
 var
  v: IUaki;
begin
  v := Uaki;
  var t := v.TenPower[0] + StrToInt(edT.Text);
  v.TenPower[0] := t;
  v.TenPower[1] := t;
  v.TenPower[2] := t;
  v.TenStart;
end;

procedure TFormPIDsetup.TimerTimer(Sender: TObject);
 var
  pw, tinc, tten: Double;
  Time: Double;
begin
 if Assigned(FStream) then
  begin
   var v := Uaki;
   if Length(v.Temperature) > 0 then tten := v.Temperature[0]
   else tten := -0.0;
   Time := Frac(Now);
   pw := v.TenPower[0];
   tinc := InclinT;
//   srsPower.AddXY(Time*24, pw);
//   srsTten.AddXY(Time*24, tten);
//   srsTincl.AddXY(Time*24, tinc);
   FStream.WriteLine(Format('%s;%f;%f;%f',[TimeToStr(Time), pw, tten, tinc]));
  end;
end;

class function TFormPIDsetup.ClassIcon: Integer;
begin
  Result := NICON;
end;

class procedure TFormPIDsetup.DoCreateForm(Sender: IAction);
begin
  GetUniqueForm('GlobalUakiPIDSetupForm');
end;

procedure TFormPIDsetup.FormDestroy(Sender: TObject);
begin
  if Assigned(FStream) then FreeAndNil(FStream);
end;

function TFormPIDsetup.GetInclinT: Double;
begin
  if not Assigned(FTempNode) then
   begin
    for var n in FindDevs((GContainer as IALLMetaDataFactory).Get.Get.DocumentElement) do
     if (n.Attributes[AT_ADDR] = 3) and TryGetX(n,'WRK.Inclin.T.DEV', FTempNode, AT_VALUE) then
       Break;
   end;
   if Assigned(FTempNode) then
     Result := Double(FTempNode.NodeValue)
   else
     Result := 0;
end;

function TFormPIDsetup.GetUaki: IUaki;
 var
  de: IDeviceEnum;
  d: IDevice;
begin
  Result := nil;
  if Supports(GlobalCore, IDeviceEnum, de) then
    for d in de.Enum() do if Supports(d, IUaki, Result) then
     begin
      if not FBinded then
       begin
        Bind('C_TenUpdate', d, ['S_TenUpdate']);
        FBinded := True;
       end;
      Exit(d as IUaki);
     end;
   raise ENeedDialogException.Create('УАКСИ не найдено !');
end;

procedure TFormPIDsetup.Loaded;
begin
  inherited;
//  if (od.FileName <> '') then
//    begin
//      try
//       UpdateChart(od.FileName);
//      finally
//      FStream := TStreamWriter.Create(od.FileName, True, TEncoding.UTF8);
//      end;
//    end;
//  UpdateScreen;
  //(Uaki as ICycle).Cycle := True;
end;

procedure TFormPIDsetup.odAfterDialog(Sender: TObject; var AName: string; var AAction: Boolean);
begin
  if (AName <> '') and (AName <> FFile) then
   begin
    if Assigned(FStream) then FreeAndNil(FStream);
    try
     UpdateChart(AName);
    finally
    FStream := TStreamWriter.Create(AName, True, TEncoding.UTF8);
    end;
   end;
end;

procedure TFormPIDsetup.SetC_TenUpdate(const Value: Integer);
begin
  FC_TenUpdate := Value;
  UpdateScreen;
end;

procedure TFormPIDsetup.UpdateChart(const FileName: string);
 var
  r: TStreamReader;
  Time,pw,tinc,tten: Double;
begin
//  srsPower.Clear;
//  srsTten.Clear;
//  srsTincl.Clear;
  if not fileExists(FileName) then Exit;
  r := TStreamReader.Create(FileName, TEncoding.UTF8);
  try
    repeat
     var a := r.ReadLine.Split([';']);
     if Length(a) = 4 then
      begin
       Time := StrToTime(a[0])*24;
       pw := a[1].ToDouble;
       tten := a[2].ToDouble;
       tinc := a[3].ToDouble;
//       srsPower.AddXY(Time, pw);
//       srsTten.AddXY(Time, tten);
//       srsTincl.AddXY(Time, tinc);
      end;
    until r.EndOfStream;
  finally
    r.Free;
  end;
end;

procedure TFormPIDsetup.UpdateScreen;
 var
  v: IUaki;
begin
  v := Uaki;
  lbT.Caption := '';
  for var a in uaki.Temperature do lbT.Caption := lbT.Caption + Format('%6.2f ',[a]);
  lbPower.Caption := Format('%-6d %-6d %-6d',[v.TenPower[0],v.TenPower[1],v.TenPower[2]]);
  lbTincl.Caption := InclinT.ToString(ffFixed, 6, 2);
end;

initialization
  RegisterClass(TFormPIDsetup);
  TRegister.AddType<TFormPIDsetup, IForm>.LiveTime(ltSingletonNamed);
finalization
  GContainer.RemoveModel<TFormPIDsetup>;
end.

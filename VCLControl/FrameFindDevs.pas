unit FrameFindDevs;

interface

uses RootImpl, ExtendIntf, DockIForm, debug_except, DeviceIntf, PluginAPI, RootIntf, Container, Actns,  tools,
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes,
  Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls;

type
  TFrameFindDev = class(TFrame)
    lbCon: TLabel;
    dv1: TCheckBox;
    dv2: TCheckBox;
    dv3: TCheckBox;
    dv4: TCheckBox;
    dv5: TCheckBox;
    dv6: TCheckBox;
    dv7: TCheckBox;
    dv8: TCheckBox;
    dv9: TCheckBox;
    dv10: TCheckBox;
    dv11: TCheckBox;
    dv12: TCheckBox;
    dv13: TCheckBox;
    dv14: TCheckBox;
    edName: TEdit;
    btAdd: TButton;
    procedure btAddClick(Sender: TObject);
  private
    inx,found: Integer;
    memo: Tmemo;
    ComPort: string;
    procedure ClearDC(onEnd: Tproc<TFrameFindDev>);
  public
    FConnectCreated: Boolean;
    Fconnect: IConnectIO;
    FTmpDev: IDevice;
    Fterminate: Boolean;
    FExecuted: Boolean;
    procedure Execute(const ComPort: string; memo: Tmemo; onEnd: Tproc<TFrameFindDev>);
    procedure Rec(onEnd: Tproc<TFrameFindDev>);
  end;

implementation

uses FormDlgDev;

{$R *.dfm}

{ TFrameFindDev }
var devCnt: Integer=1;

procedure TFrameFindDev.Execute(const ComPort: string; memo: Tmemo; onEnd: Tproc<TFrameFindDev>);
 var ii: IInterface;
 m: TComponentModel;
begin
  Self.memo := memo;
  Self.ComPort := ComPort;
  FExecuted := False;
  Fconnect := nil;
  for var cn in (GlobalCore as IConnectIOEnum) do if cn.ConnectInfo = ComPort then
   begin
    Fconnect := cn;
    FConnectCreated := False;
    Break;
   end;
  if not Assigned(Fconnect) then
   begin
    Fconnect := (GlobalCore as IGetConnectIO).ConnectIO(1);
    Fconnect.ConnectInfo := ComPort;
    Fconnect.Status := Fconnect.Status + [icUserAdding];
    (GlobalCore as IConnectIOEnum).Add(Fconnect);
    FConnectCreated := True;
   end;
  FTmpDev := (GlobalCore as IGetDevice).Device([$FFFF],'поиск приборов'+devCnt.ToString,'m1');
  inc(devCnt);
  FTmpDev.IConnect := Fconnect;
  Memo.Lines.Add('Поиск модулей на: '+ FTmpDev.IConnect.ConnectInfo);
  inx := 1;
  found := 0;
  rec(onEnd);
end;

procedure TFrameFindDev.btAddClick(Sender: TObject);
 var
  a: TAddressArray;
  inf: Tarray<string>;
  names: string;
begin
  for var i := 1 to 14 do
   begin
    var cb := TCheckBox(FindChildControl('dv'+i.ToString));
    if cb.Checked then
     begin
      a := a + [i];
      names := names +  ' adr'+i.ToString;
     end;
   end;
  Fconnect.Status := [];
  if Length(a) >0 then TFormCreateDev.AddDevises(a,edName.Text,names.Trim,Fconnect,True, FTmpDev);
  btAdd.Enabled := False;
end;

procedure TFrameFindDev.ClearDC(onEnd: Tproc<TFrameFindDev>);
begin
  FExecuted := True;
//  if FConnectCreated then (GlobalCore as IConnectIOEnum).Remove(Fconnect);
  onEnd(self);
end;

procedure TFrameFindDev.Rec(onEnd: Tproc<TFrameFindDev>);
   var
     sd: TStdRec;
begin
  if Fterminate then
   begin
    ClearDC(onEnd);
    Exit();
   end;
  sd := TStdRec.Create(inx, 7, 1);
  sd.AssignByte(1);
  try
   (FTmpDev as ILowLevelDeviceIO).SendROW(sd.Ptr, sd.SizeOf, procedure(p: Pointer; n: integer)
   begin
     if Fterminate then
      begin
       ClearDC(onEnd);
       Exit();
      end;
     var cb := TCheckBox(FindChildControl('dv'+inx.ToString));
     if (n > 0) and sd.CheckAC(p) then
      begin
       cb.Checked := True;
       inc(found);
       var s := Format('  Порт %s - устройство %d найдено',[Fconnect.ConnectInfo, inx]);
       for var d in TAddressRec.Devices do
        if d.Adr = inx then
         s := s + Format(' [%s] %s',[d.Name,d.Info]);
       memo.Lines.add(s);
      end;
     if inx = 14 then
      begin
       if found>0 then
        begin
         btAdd.Enabled := True;
         edName.Enabled := True;
         edName.Text := 'сборка'+found.ToString+ '_'+devCnt.ToString;
         Inc(devCnt);
        end;
       Memo.Lines.Add('3. работа окончена');
       ClearDC(onEnd);
       Exit;
      end;
     Inc(inx);
     rec(onEnd);
   end, 100);
  except
  lbCon.Color := clRed;
  Memo.Lines.Add(Format('Ошибка порта %s',[ComPort]));
  ClearDC(onEnd);
  end;
end;

end.

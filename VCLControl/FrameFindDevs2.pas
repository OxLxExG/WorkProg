unit FrameFindDevs2;

interface

uses RootImpl, ExtendIntf, DockIForm, debug_except, DeviceIntf, PluginAPI, RootIntf, Container, Actns,  tools,
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes,
  Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls, Vcl.CheckLst;

const
  DEF_HEIGHT = 40;
type
  TFrameFindDev = class(TFrame)
    lbCon: TLabel;
    edName: TEdit;
    btAdd: TButton;
    cbx: TCheckListBox;
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

  resourcestring
     RS_findDevs= 'поиск приборов';
     RS_findModules= 'Поиск модулей на: ';
     RS_FindResult= '  Порт %s - найдено устройство: %s ';
     RS_FindEnd= '3. работа окончена';
     RS_PortErr= 'Ошибка порта %s %s';

implementation

uses FormDlgDev;

{$R *.dfm}

{ TFrameFindDev }
var devCnt: Integer=1;

procedure TFrameFindDev.Execute(const ComPort: string; memo: Tmemo; onEnd: Tproc<TFrameFindDev>);
begin
  Self.memo := memo;
  Self.ComPort := ComPort;
  FExecuted := False;
  Fconnect := nil;
  for var cn in (GlobalCore as IConnectIOEnum) do
    if cn.ConnectInfo = ComPort then
   begin
    Fconnect := cn;
    FConnectCreated := False;
    Break;
   end;
  if not Assigned(Fconnect) and ComPort.Contains('COM') then
   begin
    Fconnect := (GlobalCore as IGetConnectIO).ConnectIO(1);
    Fconnect.ConnectInfo := ComPort;
    Fconnect.Status := Fconnect.Status + [icUserAdding];
    (GlobalCore as IConnectIOEnum).Add(Fconnect);
    FConnectCreated := True;
   end;
  FTmpDev := (GlobalCore as IGetDevice).Device([$FFFF],RS_findDevs+devCnt.ToString,'m1');
  inc(devCnt);
  FTmpDev.IConnect := Fconnect;
  Memo.Lines.Add(RS_findModules+ FTmpDev.IConnect.ConnectInfo);
  inx := 1;
  found := 0;
  //// Для красоты
  Application.ProcessMessages;
  Sleep(300);
  Application.ProcessMessages;
  ////
  rec(onEnd);
end;

procedure TFrameFindDev.btAddClick(Sender: TObject);
 var
  a: TAddressArray;
  names: string;
begin
  for var i := 0 to cbx.Count-1 do if cbx.Checked[i] then
     begin
      var adr := Integer(Pointer(cbx.Items.Objects[i]));
      a := a + [adr];
      names := names +  ' adr'+adr.ToString;
     end;
  Fconnect.Status := [];
  if Length(a) >0 then TFormCreateDev.AddDevises(a,edName.Text,names.Trim,Fconnect,True, FTmpDev);
  btAdd.Enabled := False;
end;

procedure TFrameFindDev.ClearDC(onEnd: Tproc<TFrameFindDev>);
begin
  FExecuted := True;
  Self.Height := DEF_HEIGHT + cbx.Count*cbx.ItemHeight+ 16 * Integer(cbx.Count>0) ;
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
     if (n > 0) and sd.CheckAC(p) then
      begin
       var dr: TAddressRec.TDevRec := TAddressRec.TDevRec.Create(inx,'unknown','');
       for var d in TAddressRec.Devices do if d.Adr = inx then
        begin
          dr := d;
          Break;
        end;
       var s := Format('%d: [%s] %s', [inx, dr.Name, dr.Info]);
       cbx.AddItem(s, TObject(Pointer(inx)));
       cbx.Checked[cbx.Count-1] := True;
       inc(found);
       memo.Lines.add(Format(RS_FindResult,[Fconnect.ConnectInfo,s]));
      end;
     if inx = 14 then
      begin
       if found>0 then
        begin
         btAdd.Enabled := True;
         edName.Enabled := True;
         edName.Text := 'Tool'+found.ToString+ '_'+devCnt.ToString;
         Inc(devCnt);
        end;
       Memo.Lines.Add(RS_FindEnd);
       Fconnect.Status := Fconnect.Status - [iosOpen];
       ClearDC(onEnd);
       Exit;
      end;
     Inc(inx);
     rec(onEnd);
   end, 100);
  except
   on E: Exception do
    begin
     TDebug.DoException(E, False);
     lbCon.Color := clRed;
     Memo.Lines.Add(Format(RS_PortErr,[ComPort, e.Message]));
     ClearDC(onEnd);
    end;
  end;
end;

end.

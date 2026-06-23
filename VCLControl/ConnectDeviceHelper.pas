unit ConnectDeviceHelper;

interface

uses RootImpl, ExtendIntf, DockIForm, debug_except, DeviceIntf, PluginAPI, RootIntf, Container, Actns,
     System.SysUtils, Vcl.Menus, System.Classes;

resourcestring
 RS_New_conn='Новое соединение...';

type
  TSelectConnectIO = reference to procedure( c: IConnectIO);

  TMenuConnectIO = class(TComponent)
  private
    FConnNew, FConnOld: TSelectConnectIO;
    procedure OnClick(Sender: TObject);
    procedure OnNewClick(Sender: TObject);
  public
    constructor Apply(RootControl: TMenuItem; ConnNew, ConnOld: TSelectConnectIO);
  end;

implementation


{ TMenuConnectIO }

constructor TMenuConnectIO.Apply(RootControl: TMenuItem; ConnNew, ConnOld: TSelectConnectIO);
 var
  gc: IGetConnectIO;
begin
  RootControl.AutoHotkeys := maManual;
  inherited Create(RootControl);
  FConnNew := ConnNew;
  FConnOld := ConnOld;
  RootControl.Clear;
  if Supports(GlobalCore, IGetConnectIO, gc) then
    gc.Enum(procedure(ConnectID: Integer; const ConnectName, ConnectInfo: string)
      function AddMenu(root: TMenuItem; const Capt: string; ev: TNotifyEvent): TMenuItem;
      begin
        Result := TMenuItem.Create(Root);
        Result.Caption := Capt;
        Result.Tag := ConnectID;
        Result.OnClick := ev;
        root.Add(Result);
      end;
      procedure AddAvail(root: TMenuItem);
       var
        s: string;
      begin
        for s in gc.GetConnectInfo(ConnectID) do AddMenu(root, s, OnClick);
      end;
      procedure AddCreateNew(root: TMenuItem);
      begin
        AddMenu(root, RS_New_conn, OnNewClick);
        AddMenu(root, '-', nil);
      end;
     var
      Item: TMenuItem;
    begin
      Item := AddMenu(RootControl, ConnectInfo, nil);
      if gc.IsManualCreate(ConnectID) then AddCreateNew(Item);
      AddAvail(Item);
    end);
end;

procedure TMenuConnectIO.OnClick(Sender: TObject);
 var
  c: IConnectIO;
  gc: IGetConnectIO;
  ce: IConnectIOEnum;
  dv: IDevice;
begin
  GlobalCore.QueryInterface(IConnectIOEnum, ce);
  if Supports(GlobalCore, IConnectIOEnum, ce) then for c in ce do if SameText(c.ConnectInfo, TMenuItem(Sender).Caption) then
   begin
     if Assigned(FConnOld) then FConnOld(c);
    Exit;
   end;
  if Supports(GlobalCore, IGetConnectIO, gc) then
   begin
    c := gc.ConnectIO(TMenuItem(Sender).Tag);
    c.ConnectInfo := TMenuItem(Sender).Caption;
    if Assigned(FConnNew) then FConnNew(c);
   end;
end;

procedure TMenuConnectIO.OnNewClick(Sender: TObject);
 var
  c: IConnectIO;
  gc: IGetConnectIO;
  ce: IConnectIOEnum;
  d: Idialog;
  dv: IDevice;
begin
  if Supports(GlobalCore, IGetConnectIO, gc) then
   begin
    c := gc.ConnectIO(TMenuItem(Sender).Tag);
    if RegisterDialog.TryGet<Dialog_SetupConnectIO>(d) and (d as IDialog<IConnectIO>).Execute(c) then
      begin
       if Assigned(FConnNew) then FConnNew(c);
      end;
   end;
end;

end.

unit DevUakiNet;

interface

uses System.SysUtils, System.Classes, Vcl.Graphics, tools, DevUaki,
     System.Generics.Collections, System.Generics.Defaults,
     UakiIntf, DeviceIntf, AbstractDev, debug_except, ExtendIntf, Container, PluginAPI, RootImpl;
type

 TDevUakiNet = class(TDevUaki)
 protected
   procedure DoRegister; override;
 public
   constructor Create(); override;
 end;


implementation

{ TDevUakiNet }

constructor TDevUakiNet.Create;
begin
  inherited;                                                     //to   from
  FViz := GetAxisVizClass.Create(self as IInterface, ADR_AXIS_VIZ, -8,0, -1/8,0);
  FZen := GetAxisVizClass.Create(self as IInterface, ADR_AXIS_ZU, -1,0,  -1,0);
//  FCyclePeriod := 500;
  FAddressArray := TAddressRec(ADR_UAKI_NET.ToString());
  FtenSupport := False;
end;

procedure TDevUakiNet.DoRegister;
begin
  TRegister.AddType<TDevUakiNet>.AddInstance(Name, Self as IInterface);
end;

initialization
  RegisterClass(TDevUakiNet);
  TRegister.AddType<TDevUakiNet, IDevice>.LiveTime(ltSingletonNamed);
finalization
  GContainer.RemoveModel<TDevUakiNet>;
end.

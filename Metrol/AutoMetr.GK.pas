unit AutoMetr.GK;

interface

uses System.SysUtils, System.Generics.Collections, Vcl.ExtCtrls, Winapi.mmSystem, System.Types, Vcl.Dialogs,
ExtendIntf, MetrForm, Xml.XMLIntf, RootIntf, RootImpl, StolGKIntf, Container, DeviceIntf, debug_except, tools;

type
  TGKAuto = class(TAutomatMetrology)
  private
    FHideTerminateError: Boolean;
    FNeedSendStop: Boolean;
    FStol: IStolGK;
    function GetStol: IStolGK;
  protected
    procedure StartStep(Step: IXMLNode); override;
    procedure Stop(); override;
    procedure DoEndMetrology(); override;
  public
    property StolGK: IStolGK read GetStol;
  end;


implementation

{ TGKAuto }

function TGKAuto.GetStol: IStolGK;
 var
  de: IDeviceEnum;
  d: IDevice;
begin
  if Assigned(FStol) then Exit(FStol);
  if Supports(GlobalCore, IDeviceEnum, de) then for d in de.Enum() do if Supports(d, IStolGK, FStol) then Exit(FStol);
  Result := nil;
  raise EFormMetrolog.Create('Устройство стол поверки ГК отсутствует');
end;

procedure TGKAuto.StartStep(Step: IXMLNode);
begin
  inherited;
  FHideTerminateError := False;
  FNeedSendStop := False;
  try
   StolGK.Run(FStep.Attributes['Gk_Stol'], procedure (e: TEventStol; const cmd: AnsiString)
     procedure err(const ermsg: string);
     begin
//       FNeedSendStop := False;
       Report(samError, ermsg);
       Error(ermsg);
     end;
   begin
     case e of
       esWait:
        begin
         FNeedSendStop := True;
         Report(samRun, 'Ожидание команды стола');
        end;
       esEndCmd: DelayKadr(2, procedure
       begin
         DoStop;
       end);
       esTerminateCmd:
        if not FHideTerminateError then err('Прервано пользователем')
        else FNeedSendStop := False;
       esErrCmd: err('Ошибка команды '+ string(cmd));
       esTimeOut: err('Нет ответа команды '+ string(cmd));
     end;
   end);
  except
   on E: Exception do Error(E.Message);
  end
end;

procedure TGKAuto.DoEndMetrology;
begin
  StolGK.Actuator(False, nil);
end;

procedure TGKAuto.Stop;
begin
  inherited;
  FHideTerminateError := True;
  if FNeedSendStop then StolGK.Stop(nil);
end;

end.

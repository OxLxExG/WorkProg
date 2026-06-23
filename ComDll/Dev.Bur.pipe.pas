unit Dev.Bur.pipe;

interface
{$INCLUDE global.inc}

uses  tools, System.IOUtils, RootIntf,  ProtocolBurUnit, DevBur,
  Winapi.Windows, System.SysUtils, System.Classes, CPort, CRC16, Vcl.ExtCtrls, System.Variants, Xml.XMLIntf, Xml.XMLDoc,
  Generics.Collections,  Vcl.Forms, Vcl.Dialogs,Vcl.Controls, Actns,
  DeviceIntf, AbstractDev, debug_except, ExtendIntf, Container, PluginAPI, RootImpl;

type
  TMetaDataPipelineStep = reference to procedure(Next: TProc; const Res: TInfoEventRes);

  TMetaDataPipeline = class
  private
    FOrigInitEv: TInfoEvent;
    FSavedRes: TInfoEventRes;
    FSteps: TList<TMetaDataPipelineStep>;
    FCurrentStepIndex: Integer;
    procedure ExecuteNextStep;
    procedure HookInitFinished(Res: TInfoEventRes);
  public
    constructor Create;
    destructor Destroy; override;
    function AddStep(AStep: TMetaDataPipelineStep): TMetaDataPipeline;
    procedure Run(Func: TProc<TInfoEvent>; AOriginalEv: TInfoEvent);
  end;

implementation

{ TMetaDataPipeline }

constructor TMetaDataPipeline.Create;
begin
  inherited Create;
  FSteps := TList<TMetaDataPipelineStep>.Create;
  FCurrentStepIndex := 0;
end;

destructor TMetaDataPipeline.Destroy;
begin
  FSteps.Free;
  inherited Destroy;
end;

function TMetaDataPipeline.AddStep(AStep: TMetaDataPipelineStep): TMetaDataPipeline;
begin
  FSteps.Add(AStep);
  Result := Self;
end;

procedure TMetaDataPipeline.ExecuteNextStep;
begin
  if FCurrentStepIndex < FSteps.Count then
  begin
    var CurrentStep := FSteps[FCurrentStepIndex];
    Inc(FCurrentStepIndex);
    try
      CurrentStep(procedure
        begin
          Self.ExecuteNextStep;
        end, FSavedRes);
    except
      on E: Exception do
      begin
        TDebug.DoException(E, False);
        Self.ExecuteNextStep;
      end;
    end;
  end
  else
  begin
    try
      if Assigned(FOrigInitEv) then
        FOrigInitEv(FSavedRes);
    finally
      Self.Free;
    end;
  end;
end;

procedure TMetaDataPipeline.HookInitFinished(Res: TInfoEventRes);
begin
  FSavedRes := Res;
  ExecuteNextStep;
end;

procedure TMetaDataPipeline.Run(Func: TProc<TInfoEvent>; AOriginalEv: TInfoEvent);
begin
  FOrigInitEv := AOriginalEv;
  Func(HookInitFinished);
end;

end.

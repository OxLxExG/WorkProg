unit ActionAdapter;

interface

uses Winapi.Windows, Forms, Container, RootIntf, RootImpl, Classes, Vcl.ActnMan, Vcl.ActnList, ExtendIntf, System.UITypes;

type
  TIAction = class(TIObject, IAction, IInterfaceComponentReference)
  private
    FAction: TCustomAction;
    FOnClick: TIActionEvent;
    procedure OnExecute(Sender: TObject);
  protected

    function Priority: Integer;
    function RootName: String;
    function GetItemName: String;
    procedure SetItemName(const Value: String);
    function Model: ModelType;

    function GetCaption: String;
    function GetCategory: String;
    function GetChecked: Boolean;
    function GetAutoCheck: Boolean;
    function GetEnabled: Boolean;
    function GetHint: String;
    function GetImageIndex: System.UITypes.TImageIndex;
    function GetGroupIndex: Integer;
    function GetActionName: String;
    function GetEventHandler: TIActionEvent;

    procedure SetActionName(const AValue: String);
    procedure SetCaption(const AValue: String);
    procedure SetCategory(const AValue: String);
    procedure SetChecked(AValue: Boolean);
    procedure SetAutoCheck(AValue: Boolean);
    procedure SetEnabled(AValue: Boolean);
    procedure SetHint(const AValue: String);
    procedure SetImageIndex(AValue: System.UITypes.TImageIndex);
    procedure SetGroupIndex(const AValue: Integer);
    procedure SetEventHandler(const AEventHandler: TIActionEvent);

    procedure DefaultShow;
    function OwnerExists: Boolean;
//  ядро создает  FAction: TCustomAction плугины используют только IAction
//  —»ѕќЋ№«”≈“—я “ќЋ№ ќ ¬ яƒ–≈ “. . ¬ќ«¬–јўј≈“ TObject = TCustomAction
//  в данном случае IInterfaceComponentReference используетс€ в основной форме IActionProvider.ShowInMenu

//  –ешил использовать и в плугинах
    function GetComponent: TComponent;
  public
    constructor CreateAction(ActionManager: TActionManager; const ACategory, ACaption, AName: WideString; Event: TIActionEvent; ImagIndex, GroupIndex: Integer);
    destructor Destroy; override;
  end;


implementation

{ TIActionCreate }

constructor TIAction.CreateAction(ActionManager: TActionManager; const ACategory, ACaption, AName: WideString; Event: TIActionEvent; ImagIndex, GroupIndex: Integer);
begin
  inherited Create;
  FAction := TCustomAction.Create(Application.Mainform);
  FAction.Category := ACategory;
  FAction.Caption := ACaption;
  FAction.Name := AName;
  FAction.OnExecute := OnExecute;
  FOnClick := Event;
  FAction.ImageIndex := ImagIndex;
  FAction.GroupIndex := GroupIndex;
  FAction.ActionList := ActionManager;
end;

procedure TIAction.DefaultShow;
begin

end;

destructor TIAction.Destroy;
begin
  OutputDebugString(PChar('        TIActionCreate.Destroy     '+ FAction.Caption+ '            '));
  FAction.OnExecute := nil;
  FAction.Free;
  inherited;
end;

procedure TIAction.OnExecute(Sender: TObject);
begin
// FOnClick должен быть safecall но RTTI не надолит пользовательские атрибуты если иетод safecall проблемма !!!
  { TODO : ќбработка системой sherif }
  if Assigned(FOnClick) then FOnClick(Self as IAction);
end;

function TIAction.OwnerExists: Boolean;
begin

end;

{$REGION  'обЄртка'}

function TIAction.Priority: Integer;
begin

end;

function TIAction.RootName: String;
begin

end;

function TIAction.GetActionName: String;
begin
  Result := FAction.Name;
end;

function TIAction.GetAutoCheck: Boolean;
begin
  Result := FAction.AutoCheck;
end;

function TIAction.GetCaption: String;
begin
  Result := FAction.Caption;
end;

function TIAction.GetCategory: String;
begin
  Result := FAction.Category;
end;

function TIAction.GetChecked: Boolean;
begin
  Result := FAction.Checked;
end;

function TIAction.GetComponent: TComponent;
begin
  Result := FAction;
end;

function TIAction.GetEnabled: Boolean;
begin
  Result := FAction.Enabled;
end;

function TIAction.GetEventHandler: TIActionEvent;
begin
  Result := FOnClick;
end;

function TIAction.GetGroupIndex: Integer;
begin
  Result := FAction.GroupIndex;
end;

function TIAction.GetHint: String;
begin
  Result := FAction.Hint;
end;

function TIAction.GetImageIndex: System.UITypes.TImageIndex;
begin
  Result := FAction.ImageIndex;
end;

function TIAction.GetItemName: String;
begin

end;

function TIAction.Model: ModelType;
begin

end;

procedure TIAction.SetActionName(const AValue: String);
begin
  FAction.Name := AValue;
end;

procedure TIAction.SetAutoCheck(AValue: Boolean);
begin
  FAction.AutoCheck := AValue;
end;

procedure TIAction.SetCaption(const AValue: String);
begin
  FAction.Caption := AValue;
end;

procedure TIAction.SetCategory(const AValue: String);
begin
  FAction.Category := AValue;
end;

procedure TIAction.SetChecked(AValue: Boolean);
begin
  FAction.Checked := AValue;
end;

procedure TIAction.SetEnabled(AValue: Boolean);
begin
  FAction.Enabled := AValue;
end;

procedure TIAction.SetEventHandler(const AEventHandler: TIActionEvent);
begin
  FOnClick := AEventHandler;
end;

procedure TIAction.SetGroupIndex(const AValue: Integer);
begin
  FAction.GroupIndex := AValue;
end;

procedure TIAction.SetHint(const AValue: String);
begin
  FAction.Hint := AValue;
end;

procedure TIAction.SetImageIndex(AValue: System.UITypes.TImageIndex);
begin
  FAction.ImageIndex := AValue;
end;
procedure TIAction.SetItemName(const Value: String);
begin

end;

{$ENDREGION}

end.

unit DataExchange;

interface

uses System.SysUtils, ExtendIntf, RootIntf, RootImpl, Container, rtti, System.TypInfo;

type
  CDataExchange = class
    class procedure Ask<TAsk, TAns>(Data: TAsk; Func: TAnswerFunc<TAns>);
    class function Check<TAsk, TAns>(out Data: IDataAsk<TAsk, TAns>): boolean;
    class procedure Answer(Rez: StatusDataAsk);
  end;

  TAskAnsVal = class(TIComponent, IDataAsk)
  private
    function Check(Ask, Ans: PTypeInfo): Boolean; virtual; abstract;
  end;

  TAskAns<TAsk, TAns> = class(TAskAnsVal, IDataAsk<TAsk, TAns>, IDataAnswer)
  private
    FData: TAsk;
    FAns: TAns;
    FRez: TAnswerFunc<TAns>;
    function Check(Ask, Ans: PTypeInfo): Boolean; override;
    function GetTAsk: TAsk;
    procedure Answer(Rez: StatusDataAsk; const Ans: TAns); overload;
    procedure Answer(Rez: StatusDataAsk); overload;
    constructor CreateWithData(Data: TAsk; Func: TAnswerFunc<TAns>);
  end;

implementation

{ CDataExchange }

class procedure CDataExchange.Answer(Rez: StatusDataAsk);
 var
  ins: IInterface;
begin
  if GContainer.TryGetInstance(TypeInfo(TAskAnsVal), ins, False) then (ins as IDataAnswer).Answer(Rez);
end;

class procedure CDataExchange.Ask<TAsk, TAns>(Data: TAsk; Func: TAnswerFunc<TAns>);
 var
  ins: IInterface;
begin
  if GContainer.TryGetInstance(TypeInfo(TAskAnsVal), ins, False) then (ins as IDataAnswer).Answer(sdaCancel);
  TRegister.AddType<TAskAnsVal, IDataAsk>.AddInstance(TAskAns<TAsk, TAns>.CreateWithData(Data, Func));
end;

class function CDataExchange.Check<TAsk, TAns>(out Data: IDataAsk<TAsk, TAns>): boolean;
 var
  ins: IInterface;
begin
  Result := GContainer.TryGetInstance(TypeInfo(TAskAnsVal), ins, False) and (ins as IDataAsk).Check(TypeInfo(TAsk), TypeInfo(TAns));
  if Result then Result := ins.QueryInterface(IDataAsk<TAsk, TAns>, Data) = S_OK;
end;

{ TAskAns<TAsk, TAns> }

procedure TAskAns<TAsk, TAns>.Answer(Rez: StatusDataAsk);
begin
  FRez(Rez, FAns);
  GContainer.RemoveInstance(TypeInfo(TAskAnsVal));
end;

procedure TAskAns<TAsk, TAns>.Answer(Rez: StatusDataAsk; const Ans: TAns);
begin
  FAns := Ans;
  Answer(Rez);
end;

function TAskAns<TAsk, TAns>.Check(Ask, Ans: PTypeInfo): Boolean;
begin
  Result := (TypeInfo(TAsk) = Ask) and (TypeInfo(TAns) = Ans);
end;

constructor TAskAns<TAsk, TAns>.CreateWithData(Data: TAsk; Func: TAnswerFunc<TAns>);
begin
  inherited Create;
  FRez := Func;
  FData := Data;
end;

function TAskAns<TAsk, TAns>.GetTAsk: TAsk;
begin
  Result := FData;
end;

end.

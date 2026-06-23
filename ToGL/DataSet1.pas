unit DataSet1;

interface

uses
  System.SysUtils, System.Classes, Data.DB;

type
  TDataSetGti = class(TDataSet)
  private
    { Private declarations }
  protected
    { Protected declarations }
  public
    { Public declarations }
  published
    { Published declarations }
  end;

procedure Register;

implementation

procedure Register;
begin
  RegisterComponents('Samples', [TDataSetGti]);
end;

end.

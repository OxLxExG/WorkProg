unit VCLFrameTGamma;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes,
  Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.ExtCtrls, Vcl.StdCtrls, Vcl.ComCtrls;

type
  TFrameGamma = class(TFrame)
    PaintBox: TPaintBox;
    clTop: TColorBox;
    clBot: TColorBox;
    tbPlus: TTrackBar;
    tbMinus: TTrackBar;
  private
    { Private declarations }
  public
    { Public declarations }
  end;

implementation

{$R *.dfm}

end.

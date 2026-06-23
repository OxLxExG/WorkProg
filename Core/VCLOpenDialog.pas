unit VCLOpenDialog;

interface

uses
     System.SysUtils, Dialogs, Winapi.ShlObj, System.UITypes;

type
  TOpenDialogEx = class(TCustomFileOpenDialog)
  strict protected
    procedure DoOnExecute; override;
  end;

implementation

{ TOpenDialogEx }

procedure TOpenDialogEx.DoOnExecute;
 var
//  pif: TPreviewHandlerFrameInfo;
  c: IFileDialogCustomize;
//  ipi: IPreviewItem;
//  iph: IPreviewHandler;
begin
  inherited;
  c :=  (Dialog as IFileDialogCustomize);
   c.StartVisualGroup(0, 'It is a group');
    c.AddComboBox(2);
    c.AddControlItem(2, 1, 'item 1');
    c.AddControlItem(2, 2, 'item 2');
    c.EndVisualGroup;
    c.MakeProminent(0);

end;

end.

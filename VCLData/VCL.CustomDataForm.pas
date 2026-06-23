unit VCL.CustomDataForm;

interface

uses AbstractDlgParams, DlgFltParam, RootIntf, Container, DataSetIntf, DataImportIntf,
     RootImpl, ExtendIntf, DockIForm, debug_except, DeviceIntf, PluginAPI,
     Xml.XMLIntf, System.Generics.Collections,
     System.Classes, System.SysUtils,
     Vcl.Forms, Vcl.Controls, Vcl.Graphics, Data.DB, Vcl.Grids, Vcl.DBGrids, Vcl.Menus, Vcl.Dialogs;

type
  TCustomFormData = class(TCustomFontIForm)
  private
//    procedure NAddDataClick(Sender: TObject);
  protected
//    procedure Loaded; override;
  end;

implementation

{ TCustomFormData }

//procedure TCustomFormData.Loaded;
//begin
//  inherited;
//  AddToNCMenu('Add Data...', NAddDataClick);
//end;
//
//procedure TCustomFormData.NAddDataClick(Sender: TObject);
// var
//  me: IManagerEx;
//  ids: IDataSet;
//  a: TArray<string>;
//begin
//  with TOpenDialog.Create(nil) do
//  try
//   Filter := (GContainer as IImportDataManager).GetFilters;
//   if Supports(GContainer, IManagerEx, me) then InitialDir := me.GetProjectDirectory
//   else InitialDir := ExtractFilePath(ParamStr(0))+ '\Projects';
//   Options := [ofOverwritePrompt, ofHideReadOnly, ofEnableSizing];
//   if not Execute() then Exit;
//   TDebug.Log('%s, %d',[filter, FilterIndex]);
//   a := filter.Split([';'], TStringSplitOptions.ExcludeEmpty);
//   if (Length(a) >= FilterIndex) and (GContainer as IImportDataManager).Execute(a[FilterIndex-1], FileName, ids) then
//    begin
//
//    end;
//  finally
//   Free;
//  end;
//end;

end.

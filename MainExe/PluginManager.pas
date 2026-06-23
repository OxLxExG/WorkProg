unit PluginManager;

interface

uses
  Winapi.Windows,
  system.SysUtils,
  system.Classes,
  system.RTTI,
  System.TypInfo,
  Container,
  System.Generics.Collections,
  debug_except,
  PluginAPI;

type
  EPluginManagerError = class(Exception);
    EPluginLoadError = class(EPluginManagerError);
      EDuplicatePluginError = class(EPluginLoadError);
      EPluginsLoadError = class(EPluginLoadError)
      private
        FItems: TStrings;
      public
        constructor Create(const AText: String; const AFailedPlugins: TStrings);
        destructor Destroy; override;
        property FailedPluginFileNames: TStrings read FItems;
      end;

  IPluginManager = interface//(IPlugins)
  // protected
    function GetItemFile(const Instance: IInterface): String;
  // public
    procedure LoadPlugin(const AFileName: String);
    procedure UnloadPlugin(const AIndex: Integer);

    procedure LoadPlugins(const AFolder: String; const AFileExt: String = '');

    procedure Ban(const AFileName: String);
    procedure Unban(const AFileName: String);

    procedure SaveSettings(const ARegPath: String);
    procedure LoadSettings(const ARegPath: String);

//    procedure DoLoaded;

    procedure UnloadAll;

    procedure SetVersion(const AVersion: Tversion);
    function GetBanCount: Integer;
    function GetBan(const AIndex: Integer): string;
  // public
    property BanCount: Integer read GetBanCount;
    property Bans[const AIndex: Integer]: string read GetBan;
  end;

function Plugins: IPluginManager;

implementation

uses
  system.Contnrs,
  VCL.Forms,
  System.Win.Registry;

const
  rsPluginsLoadError = 'One or more plugins has failed to load:' + sLineBreak + '%s';
  rsDuplicatePlugin  = 'Plugin is already loaded.' + sLineBreak + 'ID: %s; Name: %s;' + sLineBreak + 'File name 1: %s' + sLineBreak + 'File name 2: %s';

var
  FPluginManager: IPluginManager;

type
  TPlugin = class;

  TPluginManager = class(TInterfacedObject, IPluginManager)//, ICore, IPlugins)
  private
    FItems: TObjectList<TPlugin>;
    FBanned: TStringList;
    FVersion: Tversion;
    function CanLoad(const AFileName: String): Boolean;
  protected
    function QueryInterface(const IID: TGUID; out Obj): HResult; reintroduce; stdcall;
    // IPluginManager
    procedure LoadPlugin(const AFileName: String);
    procedure UnloadPlugin(const AIndex: Integer);
    procedure LoadPlugins(const AFolder, AFileExt: String);
    function GetItemFile(const Instance: IInterface): String;
    procedure Ban(const AFileName: String);
    procedure Unban(const AFileName: String);
    procedure SaveSettings(const ARegPath: String);
    procedure LoadSettings(const ARegPath: String);
    procedure UnloadAll;
//    procedure DoLoaded;
    procedure SetVersion(const AVersion: Tversion);
    function GetBanCount: Integer;
    function GetBan(const AIndex: Integer): string;

  public
    constructor Create;
    destructor Destroy; override;
  end;

  TPlugin = class
    FFileName: String;
    FHandle: HMODULE;
    FInit: TInitPluginFunc;
    FDone: TDonePluginFunc;
    FPlugin: PTypeInfo;
    constructor Create(const AFileName: String); virtual;
    destructor Destroy; override;
  end;

{ TPluginManager }

constructor TPluginManager.Create;
begin
  OutputDebugString('TPluginManager.Create');
  inherited Create;
  FBanned := TStringList.Create;
  FItems := TObjectList<TPlugin>.Create;
  SetVersion(VERS1000);
end;

destructor TPluginManager.Destroy;
begin
  FreeAndNil(FBanned);
  OutputDebugString('TPluginManager.Destroy');
  inherited;
end;

{procedure TPluginManager.DoLoaded;
 var
  errs: TStrings;
  p: IPluginNotify;
begin
  errs := TStringList.Create;
  try
    for p in GContainer.Enum<IPluginNotify>(True) do// .CreateAndExecService<IPluginNotify>(procedure(p: IPluginNotify)
     try
      p.LoadNotify();
     except
      on e: Exception do errs.Add(E.Message);
     end;
   if errs.Count > 0 then raise EPluginManagerError.Create(errs.Text);
  finally
   errs.Free;
  end;
end;}

procedure TPluginManager.UnloadAll;
{ var
  errs: TStrings;
  procedure NotifyRelease;
   var
    p: IPluginNotify;
  begin
    for p in GContainer.Enum<IPluginNotify> do// .CreateAndExecService<IPluginNotify>(procedure(p: IPluginNotify)
//    GContainer.ExecExistsService<IPluginNotify>(procedure(p: IPluginNotify)
     try
      p.DestroyNotify();
     except
      on e: Exception do errs.Add(E.Message);
     end;
  end;}
begin
//  errs := TStringList.Create;
  try
//   NotifyRelease;
   GContainer.RemoveInstances;
//   if errs.Count > 0 then raise EPluginManagerError.Create(errs.Text);
  finally
//   errs.Free;
   FItems.Clear;
  end;
end;

procedure TPluginManager.LoadPlugin(const AFileName: String);
 var
  d: TPlugin;
begin
  if CanLoad(AFileName) then Exit;
  // Загружаем плагин
  try
    d := TPlugin.Create(AFileName);
  except
    on E: Exception do
      raise EPluginLoadError.Create(Format('[%s] %s', [E.ClassName, E.Message]));
  end;
  // Заносим в список
  FItems.Add(d);
end;

procedure TPluginManager.LoadPlugins(const AFolder, AFileExt: String);

  function PluginOK(const APluginName, AFileExt: String): Boolean;
  begin
    Result := (AFileExt = '');
    if Result then Exit;
    Result := SameFileName(ExtractFileExt(APluginName), AFileExt);
  end;

var
  Path: String;
  SR: TSearchRec;
  Failures: TStringList;
  FailedPlugins: TStringList;
begin
  Path := IncludeTrailingPathDelimiter(AFolder);

  Failures := TStringList.Create;
  FailedPlugins := TStringList.Create;
  try
    if FindFirst(Path + '*.*', 0, SR) = 0 then
    try
      repeat
        if ((SR.Attr and faDirectory) = 0) and PluginOK(SR.Name, AFileExt) then
        try
          LoadPlugin(Path + SR.Name);
        except
          on E: Exception do
          begin
            FailedPlugins.Add(Path + SR.Name);
            Ban(Path + SR.Name);
            Failures.Add(Format('%s: %s', [Path + SR.Name, E.Message]));
          end;
        end;
      until FindNext(SR) <> 0;
    finally
      FindClose(SR);
    end;

    if Failures.Count > 0 then
      raise EPluginsLoadError.Create(Format(rsPluginsLoadError, [Failures.Text]), FailedPlugins);
  finally
    FreeAndNil(FailedPlugins);
    FreeAndNil(Failures);
  end;
end;

procedure TPluginManager.UnloadPlugin(const AIndex: Integer);
begin
  FItems.Delete(AIndex);
end;

procedure TPluginManager.Ban(const AFileName: String);
begin
  Unban(AFileName);
  FBanned.Add(AFileName);
end;

procedure TPluginManager.Unban(const AFileName: String);
var
  X: Integer;
begin
  for X := 0 to FBanned.Count - 1 do
    if SameFileName(FBanned[X], AFileName) then
    begin
      FBanned.Delete(X);
      Break;
    end;
end;

function TPluginManager.CanLoad(const AFileName: String): Boolean;
var
  X: Integer;
begin
  // Не грузить отключенные
  for X := 0 to FBanned.Count - 1 do if SameFileName(FBanned[X], AFileName) then Exit(True);
  // Не грузить уже загруженные
  for X := 0 to FItems.Count - 1 do if SameFileName(FItems[X].FFileName, AFileName) then Exit(True);
  Result := False;
end;

const
  SRegDisabledPlugins = 'Disabled plugins';
  SRegPluginX         = 'Plugin%d';

procedure TPluginManager.SaveSettings(const ARegPath: String);
var
  Reg: TRegIniFile;
  X: Integer;
begin
  Reg := TRegIniFile.Create(ARegPath, KEY_ALL_ACCESS);
  try
    // Удаляем старые
    Reg.EraseSection(SRegDisabledPlugins);
    // Сохраняем новые
    for X := 0 to FBanned.Count - 1 do Reg.WriteString(SRegDisabledPlugins, Format(SRegPluginX, [X]), FBanned[X]);
  finally
    FreeAndNil(Reg);
  end;
end;

procedure TPluginManager.SetVersion(const AVersion: Tversion);
begin
  FVersion := AVersion;
end;

procedure TPluginManager.LoadSettings(const ARegPath: String);
var
  Reg: TRegIniFile;
//  Path: String;
  X: Integer;
begin
  Reg := TRegIniFile.Create(ARegPath, KEY_READ);
  try
    FBanned.BeginUpdate;
    try
      FBanned.Clear;
      Reg.ReadSectionValues(SRegDisabledPlugins, FBanned);
      for X := 0 to FBanned.Count - 1 do FBanned[X] := FBanned.ValueFromIndex[X];
    finally
      FBanned.EndUpdate;
    end;
  finally
    FreeAndNil(Reg);
  end;
end;

function TPluginManager.QueryInterface(const IID: TGUID; out Obj): HResult;
begin
  Result := inherited QueryInterface(IID, Obj);
  if Succeeded(Result) then Exit;
  Result := GContainer.GetService(IID, Obj);
end;

function TPluginManager.GetBan(const AIndex: Integer): string;
begin
  Result := FBanned[AIndex];
end;

function TPluginManager.GetBanCount: Integer;
begin
  Result := FBanned.Count;
end;

function TPluginManager.GetItemFile(const Instance: IInterface): String;
var
  p: TPlugin;
  c: PTypeInfo;
begin
  c := (Instance as IInterfaceComponentReference).GetComponent.ClassInfo;
  for p in FItems do
   if p.FPlugin = c then Exit(p.FFileName)
end;

{ TPlugin }

constructor TPlugin.Create(const AFileName: String);
begin
  OutputDebugString(PChar('TPlugin.Create: ' + ExtractFileName(AFileName)));
  inherited Create;
  FFileName := AFileName;
  FHandle := SafeLoadLibrary(AFileName, SEM_NOOPENFILEERRORBOX or SEM_FAILCRITICALERRORS);
  if FHandle = 0 then RaiseLastOSError;
  FDone := GetProcAddress(FHandle, SPluginDoneFuncName);
  FInit := GetProcAddress(FHandle, SPluginInitFuncName);
  if not Assigned(FInit) then RaiseLastOSError;
  FPlugin :=  FInit();
end;

destructor TPlugin.Destroy;
begin
  OutputDebugString(PChar('TPlugin.Destroy: ' + ExtractFileName(FFileName)));
  if Assigned(FDone) then FDone;
  if FHandle <> 0 then
  begin
    FreeLibrary(FHandle);
    FHandle := 0;
  end;
  inherited;
end;

{ EPluginsLoadError }

constructor EPluginsLoadError.Create(const AText: String; const AFailedPlugins: TStrings);
begin
  inherited Create(AText);
  FItems := TStringList.Create;
  FItems.Assign(AFailedPlugins);
end;

destructor EPluginsLoadError.Destroy;
begin
  FreeAndNil(FItems);
  inherited;
end;

function Plugins: IPluginManager;
begin
  Result := FPluginManager;
end;


initialization
  FPluginManager := TPluginManager.Create;
finalization
 // if Assigned(FPluginManager) then FPluginManager.UnloadAll;
  FPluginManager := nil;
end.

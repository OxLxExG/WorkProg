unit debug_except;

interface

uses
     system.Win.comobj, SysUtils, Winapi.Windows, Classes, Generics.Collections,
     JvDockControlForm, ExtCtrls,
     Vcl.Controls, winapi.ActiveX;

type
  EBaseException = class(EOleException)
  private
    function GetDefaultCode: HRESULT;
    class var ShowDialog: Boolean;
    class var timer: TTimer;
    class procedure TimerTimer(Sender: TObject);
  public
    class procedure NeedShowDialog(time: Integer = 4000);
    constructor Create(const Msg: string);
    constructor CreateFmt(const Msg: string; const Args: array of const);
    destructor Destroy; override;
  end;
  ENeedDialogException = class(EBaseException);
  ENoStackException = class(EBaseException);
  EHiddenException = class(EBaseException);

  TAsyncException = procedure (const ClassName, msg, StackTrace: WideString) of object;

  TDebug = class(TObject)
  private
//   type
//         TRaiseProc = procedure (dwExceptionCode, dwExceptionFlags, nNumberOfArguments: DWORD; lpArguments: PDWORD); stdcall;
//         THanldleAutoException = function (excPtr: PExceptionRecord; errPtr: Pointer; ctxPtr: Pointer; dspPtr: Pointer): DWord; stdcall;
   const GUID_DefaultErrorSource: TGUID = '{EFA9AA52-4A4E-4007-85D8-5F46CB65C426}';
//         cDelphiException: DWord = $EEDFADE;
//         PHanldleAutoException: Pointer = Pointer($500409A0);
//   class var IsInit: Boolean;
   class var FjclDbgInfo: TStrings;
//   class var PrevRaiseExceptionProc: Pointer;
   class var HandlingAutoException: boolean;
//   class var CSRaiseException: TRTLCriticalSection;
   class constructor Create;
   class destructor Destroy;
  public
   class var ExeptionEvent: TAsyncException;
//   class procedure Init;
//   class procedure DeInit;
   class function GetStack(): string;
   ///	<summary>
   ///	  Если нужно скрыть диалог исключения
   ///	</summary>
   class function DoException(E: Exception; ShoNoSafe: Boolean = True): boolean;
//   class function HookModulException(const ModulName: WideString): boolean;
   class function HandleSafeCallException(Caller: TObject; ExceptObject: TObject; ExceptAddr: Pointer): HResult;
   class procedure Log(const DebugMessage: string); overload;{$IFDEF RELEASE} inline; {$ENDIF}
   class procedure Log(const DebugMessage: string; const Args: array of const); overload;
   class procedure Log2Exept(const ClassName, msg, StackTrace: WideString);
  end;


implementation

uses
  {CRC16err, } JclDebug;//, JclPeImage;

{$REGION  'EBaseException - все процедуры и функции'}

{ EBaseException }

function EBaseException.GetDefaultCode: HRESULT;
begin
  Result := MakeResult(SEVERITY_ERROR, FACILITY_ITF, $EFEA{CalcCRC16(ClassName)});
end;

class procedure EBaseException.NeedShowDialog(time: Integer);
begin
  ShowDialog := True;
  if not Assigned(timer) then timer := TTimer.Create(nil);
  timer.OnTimer := TimerTimer;
  timer.Interval := time;
  timer.Enabled := True;
end;

class procedure EBaseException.TimerTimer(Sender: TObject);
begin
  FreeAndNil(timer);
  ShowDialog := False;
end;

constructor EBaseException.Create(const Msg: string);
begin
  inherited Create(Msg, GetDefaultCode, '', '', 0);
end;

constructor EBaseException.CreateFmt(const Msg: string; const Args: array of const);
begin
  inherited Create(Format(Msg, Args), GetDefaultCode, '', '', 0);
end;

destructor EBaseException.Destroy;
begin

  inherited;
end;

{$ENDREGION  EBaseException}

{$REGION  'TDebug - все процедуры и функции'}

{ TDebug }

threadvar
  ExceptionAddress: Pointer;
  ExceptionRecord: TExceptionRecord;

//procedure MyRaise(dwExceptionCode, dwExceptionFlags, nNumberOfArguments: DWORD; lpArguments: PDWORD); stdcall;
//begin
//  with  TDebug do
//   begin
//    EnterCriticalSection(CSRaiseException);
//    if HandlingAutoException then
//     begin
//      LeaveCriticalSection(CSRaiseException);
//      FillChar(ExceptionRecord, SizeOf(TExceptionRecord), 0);
//      ExceptionRecord.ExceptionCode := dwExceptionCode;
//      ExceptionRecord.ExceptionFlags := dwExceptionFlags;
//      ExceptionRecord.ExceptionRecord := nil;
//      ExceptionRecord.ExceptionAddress := ExceptionAddress;
//      ExceptionRecord.NumberParameters := nNumberOfArguments;
//      if nNumberOfArguments > 0 then Move(lpArguments^, ExceptionRecord.ExceptionInformation[0], SizeOf(DWord)*nNumberOfArguments);
//     end
//    else
//     begin
//      LeaveCriticalSection(CSRaiseException);
//      if assigned(prevRaiseExceptionProc) then
//         TDebug.TRaiseProc(prevRaiseExceptionProc)(dwExceptionCode, dwExceptionFlags, nNumberOfArguments, lpArguments);
//     end;
//   end;
//end;
//
//{$O-}
//function MyHanldleAutoException (excPtr: PExceptionRecord; errPtr: Pointer; ctxPtr: Pointer; dspPtr: Pointer): DWord; stdcall;
//type
//  TProc1 = function (p: Pointer): TObject;
// var
//  obj: TObject;
//begin
//  with TDebug do if excPtr.ExceptionCode = cDelphiException then Result := TDebug.THanldleAutoException(PHanldleAutoException)(excPtr, errPtr, ctxPtr, dspPtr)
//  else
//   begin
//    System.Set8087CW($1332);
//    obj := TProc1(ExceptObjProc)(excPtr);
//    ExceptionAddress := excPtr.ExceptionAddress;
//    EnterCriticalSection(CSRaiseException);
//     HandlingAutoException := True;
//      RaiseExceptionProc := @MyRaise;
//       raise obj;
//      RaiseExceptionProc := prevRaiseExceptionProc;
//     HandlingAutoException := False;
//    LeaveCriticalSection(CSRaiseException);
//    Result := TDebug.THanldleAutoException(PHanldleAutoException)(@ExceptionRecord, errPtr, ctxPtr, dspPtr);
//   end;
//end;
//{$O+}
{(class procedure TDebug.Init;
begin
  if not IsInit then
   begin
    Log('     ----- TDebug.Init ------    ');
    InitializeCriticalSection(CSRaiseException);
    PrevRaiseExceptionProc := RaiseExceptionProc;
    HandlingAutoException := False;
    IsInit := True;
    FjclDbgInfo := TStringList.Create;
    Include(JclStackTrackingOptions, stAllModules);
//    Include(JclStackTrackingOptions,  stRawMode);
    JclStartExceptionTracking;
   end;
end;}

class procedure TDebug.Log(const DebugMessage: string; const Args: array of const);
 var
  s: string;
begin
  DateTimeToString(s, 'nn:ss:zzz', Now);
  OutputDebugString(PChar('     ' + s +'        '+ Format(DebugMessage, Args) ));
end;

class procedure TDebug.Log2Exept(const ClassName, msg, StackTrace: WideString);
begin
  if Assigned(ExeptionEvent) then ExeptionEvent(ClassName, msg, StackTrace);
end;

class procedure TDebug.Log(const DebugMessage: string);
begin
  {$IFDEF DEBUG}
  OutputDebugString(PChar(DebugMessage));
  {$ENDIF}
end;

class constructor TDebug.Create;
begin
  Log('     ----- TDebug.Init ------    ');
//  InitializeCriticalSection(CSRaiseException);
//  PrevRaiseExceptionProc := RaiseExceptionProc;
  HandlingAutoException := False;
//  IsInit := True;
  FjclDbgInfo := TStringList.Create;
  Include(JclStackTrackingOptions, stAllModules);
//    Include(JclStackTrackingOptions,  stRawMode);
  JclStartExceptionTracking;
end;

class destructor TDebug.Destroy;
begin
  JclStopExceptionTracking;
  FjclDbgInfo.Free;
//    DeleteCriticalSection(CSRaiseException);
  Log('   ---- TDebug.DeInit ----   ');
end;

{class procedure TDebug.DeInit;
begin
  if IsInit then
   begin
    IsInit := False;
    JclStopExceptionTracking;
    FjclDbgInfo.Free;
    DeleteCriticalSection(CSRaiseException);
    Log('   ---- TDebug.DeInit ----   ');
   end;
end;}

class function TDebug.GetStack: string;
 var
  i: integer;
begin
  FjclDbgInfo.Clear;
  JclLastExceptStackListToStrings(FjclDbgInfo, True, False, False, False);
  for i := FjclDbgInfo.Count-1 downto 0 do
    if (Pos('vcl190.bpl', FjclDbgInfo[i]) <> 0)
    or (Pos('rtl190.bpl', FjclDbgInfo[i]) <> 0)
    or (Pos('Line', FjclDbgInfo[i]) = 0)  then
     FjclDbgInfo.Delete(i);
  Result :=  FjclDbgInfo.Text;
end;

class function TDebug.HandleSafeCallException(Caller, ExceptObject: TObject; ExceptAddr: Pointer): HResult;
  function HResultFromException(const E: Exception): HRESULT;
  begin
    if E.ClassType = Exception then Result := E_UNEXPECTED
    else if E is EOleSysError then  Result := EOleSysError(E).ErrorCode
    else if E is EOSError then      Result := HResultFromWin32(EOSError(E).ErrorCode)
    else                            Result := MakeResult(SEVERITY_ERROR, FACILITY_ITF, $EEEE{CalcCRC16(E.ClassName)});
  end;
var
  E: TObject;
  CreateError: ICreateErrorInfo;
  ErrorInfo: IErrorInfo;
  sta, src: WideString;
begin
  Result := E_UNEXPECTED;
  E := ExceptObject;
  if Succeeded(CreateErrorInfo(CreateError)) then
   begin
    if E is Exception then
     begin
      if E is EOleException then
       begin
        if EOleException(E).HelpFile <> '' then sta := EOleException(E).HelpFile
        else sta := GetStack();
        if EOleException(E).Source <> '' then src := EOleException(E).Source
        else src := Caller.ClassName+ '.' + E.ClassName;
       end
      else
       begin
        sta := GetStack();
        src := Caller.ClassName+ '.' + E.ClassName;
       end;
      CreateError.SetSource(PWideChar(src));
      CreateError.SetDescription(PWideChar(WideString(Exception(E).Message)));
      CreateError.SetHelpFile(PWideChar(sta));
      CreateError.SetHelpContext(Exception(E).HelpContext);

      Result := HResultFromException(Exception(E));
     end;

    if HResultFacility(Result) = FACILITY_ITF then CreateError.SetGUID(GUID_DefaultErrorSource)
    else CreateError.SetGUID(GUID_NULL);

    if CreateError.QueryInterface(IErrorInfo, ErrorInfo) = S_OK then SetErrorInfo(0, ErrorInfo);
   end;
end;

//class function TDebug.HookModulException(const ModulName: WideString): boolean;
//begin
//  Result := TJclPeMapImgHooks.ReplaceImport(Pointer(GetModuleHandle(PWideChar(ModulName))), 'rtl190.bpl', PHanldleAutoException, @MyHanldleAutoException);
//end;

class function TDebug.DoException(E: Exception; ShoNoSafe: Boolean = True): boolean;
begin
  Result := Assigned(ExeptionEvent);
  if Result then
   begin
    if EBaseException.ShowDialog then Exit(False)
    else if E is ENeedDialogException then Exit(False)
    else if E is EHiddenException then Exit(True)
    else if E is ENoStackException then ExeptionEvent(E.ClassName, E.Message, '')
    else if (E is EOleException) and (EOleException(E).HelpFile <> '') then ExeptionEvent(EOleException(E).Source, E.Message, EOleException(E).HelpFile)
//    else if ShoNoSafe then ExeptionEvent('[НЕ safe]'+E.ClassName, E.Message, GetStack())
         else ExeptionEvent(E.ClassName, E.Message, GetStack())
   end;
end;
{$ENDREGION  TDebug}

//initialization
//  TDebug.Init;
//finalization
//  TDebug.DeInit;
end.

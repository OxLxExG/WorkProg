unit Hock_Exept;

interface

uses Windows, SysUtils, Vcl.Dialogs, JclHookExcept, JclPeImage;

procedure DE_INIT_hock;
procedure INIT_hock;

function tstRise: Boolean; safecall;
procedure MyRaise(dwExceptionCode, dwExceptionFlags, nNumberOfArguments: DWORD; lpArguments: PDWORD); stdcall;

implementation

//System.pas.18663: MOV     EAX,[ESP+4]
//500409A0 8B442404         mov eax,[esp+$04]


 var
    prevHAE: array [0..15] of Byte; //кусок памяти чтобы функция была "как оригинальная"
    prevHanldleAutoException: THanldleAutoException; //указатель на оригинальную функцию



 threadvar
    ExceptionAddress: Pointer;
    ExceptionRecord: TExceptionRecord;

procedure MyRaise(dwExceptionCode, dwExceptionFlags, nNumberOfArguments: DWORD; lpArguments: PDWORD); stdcall;
begin
  EnterCriticalSection(CSRaiseException);
  if HandlingAutoException then
   begin
//    ShowMessage('ssssss');
    LeaveCriticalSection(CSRaiseException);
    FillChar(ExceptionRecord, SizeOf(TExceptionRecord), 0);      //сохраняем информацию о рейзе в нашей тредовой переменной ExceptionRecord
    ExceptionRecord.ExceptionCode := dwExceptionCode;
    ExceptionRecord.ExceptionFlags := dwExceptionFlags;
    ExceptionRecord.ExceptionRecord := nil;
    ExceptionRecord.ExceptionAddress := ExceptionAddress;
    ExceptionRecord.NumberParameters := nNumberOfArguments;
    if nNumberOfArguments > 0 then
      Move(lpArguments^, ExceptionRecord.ExceptionInformation[0], SizeOf(DWord)*nNumberOfArguments);
   end
  else
   begin
    LeaveCriticalSection(CSRaiseException);                      //либо рейзим обычным способом
    if assigned(prevRaiseExceptionProc) then
      TRaiseProc(prevRaiseExceptionProc)(dwExceptionCode, dwExceptionFlags, nNumberOfArguments, lpArguments);
   end;
end;

//function RaiseExceptionAddress: Pointer;
//begin
//  Result := GetProcAddress(GetModuleHandle(kernel32), 'RaiseException');
//  Assert(Result <> nil);
//end;
//
//function JclHookExceptions: Boolean;
//var
//  RaiseExceptionAddressCache: Pointer;
//begin
//  RaiseExceptionAddressCache := RaiseExceptionAddress;
//  with TJclPeMapImgHooks do Result := ReplaceImport(SystemBase, kernel32, RaiseExceptionProc, @MyRaise);
//  if Result then
//   begin
//    prevRaiseExceptionProc := RaiseExceptionAddressCache;
//   end;
//end;

function tstRise: Boolean;
begin
  PInteger(0)^ := 0;
  Result := RaiseExceptionProc = @MyRaise;
end;

{$O-} //выключаем оптимизацию, дабы после нашего супер raise-а компилятор не заоптимизировал хвост функции
function MyHanldleAutoException (excPtr: PExceptionRecord; errPtr: Pointer; ctxPtr: Pointer; dspPtr: Pointer): DWord; stdcall;
type
  TProc1 = function (p: Pointer): TObject;
 var
  obj: TObject;
begin
  if excPtr.ExceptionCode = cDelphiException then
   begin
    Result := THanldleAutoException(pHAE)(excPtr, errPtr, ctxPtr, dspPtr); //это делфи исключение, вызываем обычный _HandleAutoException
   end
  else
   begin
    System.Set8087CW($1332);
    obj := TProc1(ExceptObjProc)(excPtr);                               //создаем объект исключения
    ExceptionAddress := excPtr.ExceptionAddress;                        //записываем адрес настоящего исключения
    EnterCriticalSection(CSRaiseException);                             //входим в крит секцию и...
     HandlingAutoException := True;
      RaiseExceptionProc := @MyRaise;
       raise obj;
      RaiseExceptionProc := prevRaiseExceptionProc;                 //резйим объект (рейза не будет, там заглушка), а в тредовой переменной
     HandlingAutoException := False;
    LeaveCriticalSection(CSRaiseException);
    Result := THanldleAutoException(pHAE)(@ExceptionRecord, errPtr, ctxPtr, dspPtr); //ну и финальный аккорд, вызываем оригинальный _HandleAutoException                                                                                  //для нашей новой структурки ExceptionRecord
   end;
end;
{$O+}


procedure DE_INIT_hock;
begin
  DeleteCriticalSection(CSRaiseException);
end;

function RaiseExceptionAddress: Pointer;
begin
  Result := GetProcAddress(GetModuleHandle(kernel32), 'RaiseException');
  Assert(Result <> nil);
end;

function JclHookExcept: Boolean;
var
  RaiseExceptionAddressCache: Pointer;
  Module: HMODULE;
begin
//  RaiseExceptionAddressCache := RaiseExceptionAddress;
//  with TJclPeMapImgHooks do Result := ReplaceImport(Pointer(GetModuleHandle('jcl170.bpl')), kernel32, RaiseExceptionAddressCache, @MyRaise);
//  with TJclPeMapImgHooks do Result := ReplaceImport(Pointer(GetModuleHandle('ComDev.dlp')), kernel32, RaiseExceptionAddressCache, @MyRaise);
//  with TJclPeMapImgHooks do Result := ReplaceImport(Pointer(GetModuleHandle('monitor.dlp')), kernel32, RaiseExceptionAddressCache, @MyRaise);
//  with TJclPeMapImgHooks do Result := ReplaceImport(Pointer(GetModuleHandle('VCLcontrol.dlp')), kernel32, RaiseExceptionAddressCache, @MyRaise);
//  with TJclPeMapImgHooks do Result := ReplaceImport(Pointer(GetModuleHandle('VCLData.dlp')), kernel32, RaiseExceptionAddressCache, @MyRaise);
//  with TJclPeMapImgHooks do Result := ReplaceImport(Pointer(GetModuleHandle('core.bpl')), kernel32, RaiseExceptionAddressCache, @MyRaise);
  with TJclPeMapImgHooks do Result := ReplaceImport(SystemBase, 'rtl170.bpl', pHAE, @MyHanldleAutoException);
  with TJclPeMapImgHooks do Result := ReplaceImport(Pointer(GetModuleHandle('core.bpl')), 'rtl170.bpl', pHAE, @MyHanldleAutoException);
  with TJclPeMapImgHooks do Result := ReplaceImport(Pointer(GetModuleHandle('VCLcontrol.dlp')), 'rtl170.bpl', pHAE, @MyHanldleAutoException);
  with TJclPeMapImgHooks do Result := ReplaceImport(Pointer(GetModuleHandle('VCLData.dlp')), 'rtl170.bpl', pHAE, @MyHanldleAutoException);
  with TJclPeMapImgHooks do Result := ReplaceImport(Pointer(GetModuleHandle('monitor.dlp')), 'rtl170.bpl', pHAE, @MyHanldleAutoException);
  with TJclPeMapImgHooks do Result := ReplaceImport(Pointer(GetModuleHandle('ComDev.dlp')), 'rtl170.bpl', pHAE, @MyHanldleAutoException);
    if Result then
    begin
//       prevRaiseExceptionProc := RaiseExceptionAddressCache;
//      @Kernel32_RaiseException := RaiseExceptionAddressCache;
//      {$IFDEF BORLAND}
//      SysUtils_ExceptObjProc := System.ExceptObjProc;
//      System.ExceptObjProc := @HookedExceptObjProc;
//      {$ENDIF BORLAND}
//      {$IFDEF FPC}
//      SysUtils_ExceptProc := System.ExceptProc;
//      System.ExceptProc := @HookedExceptProc;
//      {$ENDIF FPC}
    end;
end;

procedure INIT_hock;
begin
  InitializeCriticalSection(CSRaiseException);
  prevRaiseExceptionProc := RaiseExceptionProc;
//  if SetHook then // Be careful with breakpoints in _HandleAutoException. Hook may be not set when there are breakpoints in _HandleAutoException.
   if JclHookExcept then
   begin
//    if JclHookExceptions then

    HandlingAutoException := False;// not JclHookExcept;
   end;
//  PInteger(0)^ := 0;
end;

end.

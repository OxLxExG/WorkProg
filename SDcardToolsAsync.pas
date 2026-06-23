unit SDcardToolsAsync;

interface

{$INCLUDE global.inc}

uses RootIntf, debug_except,
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, System.Threading,
  System.IOUtils, JclFileUtils, JclBase;

type
  TLogicalDevice = record
    Letter: Char;
    DiskSize: Int64;
    NumSectors: DWORD;
    SectorSize: DWORD;
  end;
  TCopyAsyncEvent = procedure(car: EnumCopyAsyncRun; Stat: TStatistic) of object;

  TSDStream = class;
  TReadAsync = class
   private
    FReaded: DWORD;
    FNeedRead: DWORD;
    FOverlaped: TOverlapped;
    FError: Boolean;
    FNeedClear: Boolean;
    function GetReaded: DWORD;
   public
    constructor Create(AOwner: TSDStream; offset: Int64; nRead: DWORD; Memory: Pointer; NeedClear: Boolean = False);
    property Event: THandle read FOverlaped.hEvent;
    property Readed: DWORD read GetReaded;
    property NeedRead: DWORD read FNeedRead;
    property Error: Boolean read FError;
    destructor Destroy; override;
  end;
  TSDStream = class(THandleStream)
  private
    FDiskSize: Int64;
    FNumSectors: DWORD;
    FSectorSize: DWORD;
  protected
    function GetSize: Int64; override;
    procedure SetSize(NewSize: Longint); override;
    procedure SetSize(const NewSize: Int64); override;
  public
    constructor Create(const Dev: TLogicalDevice; access: ULONG);
    destructor Destroy; override;
    function Seek(const Offset: Int64; Origin: TSeekOrigin): Int64; override;
    function AsyncCopyTo(const FlName: string; Offset, Count: Int64; ToZ: Boolean; ev: TCopyAsyncEvent): ITask;
    property SectorSize: DWORD read FSectorSize;
    property NumSectors: DWORD read FNumSectors;
    class function EnumLogicalDrives: TArray<TLogicalDevice>;
  end;

  TAsyncCopy = class
   const
    GIG = 1024*1024*512;
    M32 = 32*1024*1024;
    ZPOROG = 4096;
  private
    FStrmFile: TFileStream;
    FOffset, FCount: Int64;
    FReadCount: Int64;
    FToZ: Boolean;
    Fevent: TCopyAsyncEvent;
    FDestFile: string;
    FMap: TJclFileMapping;
    FBeginTime: TDateTime;
    class var
      FTerminate: Boolean;
      FStrmSD: TSDStream;
    procedure InnerCreateMap;
    procedure InnerCreateStream;
    //function View: TJclFileMappingView;
   type
    TLoadViewResult = record
     Res: EnumCopyAsyncRun;
     NumLoad: Cardinal;
     //LastNozerro: Cardinal;
    end;
    function UpdateStatistic(Cur: Pbyte; size: Cardinal; var Res: TLoadViewResult): Boolean;
    function LoadErrorView(Memory: Pbyte; size: Cardinal; var Res: TLoadViewResult): Boolean;
    function LoadView(Memory: Pointer; size: Cardinal; var Res: TLoadViewResult): Boolean;
    procedure InnerRemap;
    procedure CheckData;
    function CheckZerroes(p: PByte; cnt: Cardinal; out ZBegin: Cardinal): Boolean;
    function GetStatistic(LocalRead: Cardinal): TStatistic;
  public
    constructor Create(SrcSD: TSDStream; const DestFile: string; Offset, Count: Int64; ToZ: Boolean; ev: TCopyAsyncEvent);
    procedure Execute;
    destructor Destroy; override;
    class procedure Terminate;
  end;
  const
 {$IFDEF ENG_VERSION}
  RSM_SecAdr='E:%d Sector: %x Adr: %x';
  RSEV_Sec='Error sector';
 {$ELSE}
  RSM_SecAdr='E:%d —ектор: %x јдрес: %x';
  RSEV_Sec='ќшибочный сектор';
 {$ENDIF}

implementation

{$REGION 'TYPES'}
type
    MEDIA_TYPE = (
      Unknown,                // Format is unknown
      F5_1Pt2_512,            // 5.25", 1.2MB,  512 bytes/sector
      F3_1Pt44_512,           // 3.5",  1.44MB, 512 bytes/sector
      F3_2Pt88_512,           // 3.5",  2.88MB, 512 bytes/sector
      F3_20Pt8_512,           // 3.5",  20.8MB, 512 bytes/sector
      F3_720_512,             // 3.5",  720KB,  512 bytes/sector
      F5_360_512,             // 5.25", 360KB,  512 bytes/sector
      F5_320_512,             // 5.25", 320KB,  512 bytes/sector
      F5_320_1024,            // 5.25", 320KB,  1024 bytes/sector
      F5_180_512,             // 5.25", 180KB,  512 bytes/sector
      F5_160_512,             // 5.25", 160KB,  512 bytes/sector
      RemovableMedia,         // Removable media other than floppy
      FixedMedia,             // Fixed hard disk media
      F3_120M_512,            // 3.5", 120M Floppy
      F3_640_512,             // 3.5" ,  640KB,  512 bytes/sector
      F5_640_512,             // 5.25",  640KB,  512 bytes/sector
      F5_720_512,             // 5.25",  720KB,  512 bytes/sector
      F3_1Pt2_512,            // 3.5" ,  1.2Mb,  512 bytes/sector
      F3_1Pt23_1024,          // 3.5" ,  1.23Mb, 1024 bytes/sector
      F5_1Pt23_1024,          // 5.25",  1.23MB, 1024 bytes/sector
      F3_128Mb_512,           // 3.5" MO 128Mb   512 bytes/sector
      F3_230Mb_512,           // 3.5" MO 230Mb   512 bytes/sector
      F8_256_128,             // 8",     256KB,  128 bytes/sector
      F3_200Mb_512,           // 3.5",   200M Floppy (HiFD)
      F3_240M_512,            // 3.5",   240Mb Floppy (HiFD)
      F3_32M_512              // 3.5",   32Mb Floppy
    );

  DISK_GEOMETRY = record
    Cylinders: Int64; //LARGE_INTEGER
    MediaType: MEDIA_TYPE;
    TracksPerCylinder: Cardinal;
    SectorsPerTrack: Cardinal;
    BytesPerSector: Cardinal;
  end;
  PDISK_GEOMETRY = ^DISK_GEOMETRY;

  DISK_GEOMETRY_EX = record
    Geometry: DISK_GEOMETRY;
    DiskSize: Int64; //LARGE_INTEGER
    Data: array [0..1-1] of Byte;
  end;
  PDISK_GEOMETRY_EX = ^DISK_GEOMETRY_EX;


//
// Device property descriptor - this is really just a rehash of the inquiry
// data retrieved from a scsi device
//
// This may only be retrieved from a target device.  Sending this to the bus
// will result in an error
//

//  Required to ensure correct PhysicalDrive IOCTL structure setup
{$ALIGN 4}

//
// IOCTL_STORAGE_QUERY_PROPERTY
//
// Input Buffer:
//      a STORAGE_PROPERTY_QUERY structure which describes what type of query
//      is being done, what property is being queried for, and any additional
//      parameters which a particular property query requires.
//
//  Output Buffer:
//      Contains a buffer to place the results of the query into.  Since all
//      property descriptors can be cast into a STORAGE_DESCRIPTOR_HEADER,
//      the IOCTL can be called once with a small buffer then again using
//      a buffer as large as the header reports is necessary.
//


//
// Types of queries
//

type
{$Z4} //size of each enumeration type should be equal 4
STORAGE_QUERY_TYPE = (
    PropertyStandardQuery = 0,          // Retrieves the descriptor
    PropertyExistsQuery,                // Used to test whether the descriptor is supported
    PropertyMaskQuery,                  // Used to retrieve a mask of writeable fields in the descriptor
    PropertyQueryMaxDefined     // use to validate the value
);
{$Z1}

//
// define some initial property id's
//
{$Z4} //size of each enumeration type should be equal 4
STORAGE_PROPERTY_ID = (StorageDeviceProperty = 0, StorageAdapterProperty);
{$Z1}

//
// Query structure - additional parameters for specific queries can follow
// the header
//

type
	STORAGE_PROPERTY_QUERY =
                            record
    //
    // ID of the property being retrieved
    //
    PropertyId: STORAGE_PROPERTY_ID;
    //
    // Flags indicating the type of query being performed
    //
    QueryType: STORAGE_QUERY_TYPE;
    //
    // Space for additional parameters if necessary
    //
    AdditionalParameters: array [0..1-1] of UCHAR;
end;
{$ALIGN on}
PSTORAGE_PROPERTY_QUERY = ^STORAGE_PROPERTY_QUERY;


type
  STORAGE_BUS_TYPE = (
    BusTypeUnknown = $00,
    BusTypeScsi,
    BusTypeAtapi,
    BusTypeAta,
    BusType1394,
    BusTypeSsa,
    BusTypeFibre,
    BusTypeUsb,
    BusTypeRAID,
    BusTypeiScsi,
    BusTypeSas,
    BusTypeSata,
    BusTypeSd,
    BusTypeMmc,
    BusTypeMax,
    BusTypeMaxReserved = $7F);

    DEVICE_TYPE = DWORD;

//typedef struct _DEVICE_NUMBER
//{
//    DEVICE_TYPE  DeviceType;
//    ULONG  DeviceNumber;
//    ULONG  PartitionNumber;
//} DEVICE_NUMBER, *PDEVICE_NUMBER;

  PDEVICE_NUMBER =^DEVICE_NUMBER;
  DEVICE_NUMBER = record
   DeviceType: DEVICE_TYPE;
   DeviceNumber: ULONG;
   PartitionNumber: ULONG;
  end;

{$ALIGN 4}
type
  STORAGE_DEVICE_DESCRIPTOR = record
    // Sizeof(STORAGE_DEVICE_DESCRIPTOR)
    Version: Cardinal;
    // Total size of the descriptor, including the space for additional
    // data and id strings
    Size: Cardinal;
    // The SCSI-2 device type
    DeviceType: Byte;
    // The SCSI-2 device type modifier (if any) - this may be zero
    DeviceTypeModifier: Byte;
    // Flag indicating whether the device's media (if any) is removable.  This
    // field should be ignored for media-less devices
    RemovableMedia: Byte;
    // Flag indicating whether the device can support mulitple outstanding
    // commands.  The actual synchronization in this case is the responsibility
    // of the port driver.
    CommandQueueing: Byte;
    // Byte offset to the zero-terminated ascii string containing the device's
    // vendor id string.  For devices with no such ID this will be zero
    VendorIdOffset: Cardinal;
    // Byte offset to the zero-terminated ascii string containing the device's
    // product id string.  For devices with no such ID this will be zero
    ProductIdOffset: Cardinal;
    // Byte offset to the zero-terminated ascii string containing the device's
    // product revision string.  For devices with no such string this will be
    // zero
    ProductRevisionOffset: Cardinal;
    // Byte offset to the zero-terminated ascii string containing the device's
    // serial number.  For devices with no serial number this will be zero
    SerialNumberOffset: Cardinal;
    // Contains the bus type (as defined above) of the device.  It should be
    // used to interpret the raw device properties at the end of this structure
    // (if any)
    BusType: STORAGE_BUS_TYPE;
    // The number of bytes of bus-specific data which have been appended to
    // this descriptor
    RawPropertiesLength: Cardinal;
    // Place holder for the first byte of the bus specific property data
    RawDeviceProperties: array [0..1-1] of Byte;
end;
PSTORAGE_DEVICE_DESCRIPTOR = ^STORAGE_DEVICE_DESCRIPTOR;
{$ALIGN on}

{$ENDREGION 'TYPES'}

{$REGION 'FUNCS'}
function GetDisksProperty(hDevice: Thandle; pDevDesc: PSTORAGE_DEVICE_DESCRIPTOR; var devInfo: DEVICE_NUMBER): Boolean;
var
  Query: STORAGE_PROPERTY_QUERY;
  dwOutBytes: DWORD;
  //cbBytesReturned: DWORD;
begin
//  SetFilePointer(
//  ReadFile(
 	// specify the query type
  FillMemory(@Query, sizeof(Query), 0);
	Query.PropertyId := StorageDeviceProperty;
	Query.QueryType := PropertyStandardQuery;

	// Query using IOCTL_STORAGE_QUERY_PROPERTY
	Result := DeviceIoControl(hDevice, IOCTL_STORAGE_QUERY_PROPERTY,
    				@Query, sizeof(STORAGE_PROPERTY_QUERY), pDevDesc, pDevDesc.Size, dwOutBytes, nil);

	Result := Result and DeviceIoControl(hDevice, IOCTL_STORAGE_GET_DEVICE_NUMBER,
				                  	nil, 0, @devInfo, sizeof(DEVICE_NUMBER), dwOutBytes,	nil);
end;

function getGeometry(DevLetter: Char): TLogicalDevice;
 var
  cbBytesReturned: DWORD;
  dg: DISK_GEOMETRY_EX;
  FHandle: THandle;
begin
  FHandle := CreateFile(PChar(Format('\\.\%s:', [DevLetter])), GENERIC_READ,
             FILE_SHARE_READ or FILE_SHARE_WRITE, nil, OPEN_EXISTING, FILE_FLAG_OVERLAPPED, 0);
  if FHandle = INVALID_HANDLE_VALUE then RaiseLastOSError;
  try
    if not DeviceIoControl(FHandle, IOCTL_DISK_GET_DRIVE_GEOMETRY_EX, nil, 0, @dg, sizeof(dg), cbBytesReturned, nil) then RaiseLastOSError;
    Result.SectorSize := dg.Geometry.BytesPerSector;
    Result.DiskSize := dg.DiskSize;
    Result.NumSectors := dg.DiskSize div Result.SectorSize;
    Result.Letter := DevLetter;
  finally
    CloseHandle(FHandle);
  end;
end;

function checkDriveType(DriveLette: Char; var pID: ULONG): Boolean;
 var
  hDevice: THandle;
  DevDesc: PSTORAGE_DEVICE_DESCRIPTOR;
  buffer: array [0..10000-1] of AnsiChar;

  deviceInfo: DEVICE_NUMBER;
  nameWithSlash, nameNoSlash: PChar;
  driveType: Integer;
  cbBytesReturned, Ntom, fs: DWORD;
begin
   nameWithSlash := PChar(Format('\\.\%s:\', [DriveLette]));
   nameNoSlash := PChar(Format('\\.\%s:', [DriveLette]));
   driveType := GetDriveType(nameWithSlash);
   Result := False;
   if driveType = DRIVE_REMOVABLE then
    begin
     hDevice := CreateFile(nameNoSlash, FILE_READ_ATTRIBUTES, FILE_SHARE_READ or FILE_SHARE_WRITE, nil, OPEN_EXISTING, 0, 0);
     if hDevice = INVALID_HANDLE_VALUE then Exit(False);

     FillMemory(@buffer, sizeof(buffer), 0);
     DevDesc := @buffer[0];
     DevDesc.Size := sizeof(buffer);

     if GetDisksProperty(hDevice, DevDesc, deviceInfo) and (DevDesc.BusType <> BusTypeSata) then
      begin
      // ensure that the drive is actually accessible
     // multi-card hubs were reporting "removable" even when empty
       if DeviceIoControl(hDevice, IOCTL_STORAGE_CHECK_VERIFY2, nil, 0, nil, 0, cbBytesReturned, nil) then
        begin
         pid := deviceInfo.DeviceNumber;
         Result := true;
        end
       else
        begin
         // IOCTL_STORAGE_CHECK_VERIFY2 fails on some devices under XP/Vista, try the other (slower) method, just in case.
         CloseHandle(hDevice);
         hDevice := CreateFile(nameNoSlash, FILE_READ_DATA, FILE_SHARE_READ or FILE_SHARE_WRITE, nil, OPEN_EXISTING, 0, 0);
         if DeviceIoControl(hDevice, IOCTL_STORAGE_CHECK_VERIFY, nil, 0, nil, 0, cbBytesReturned, nil) then
          begin
           pid := deviceInfo.DeviceNumber;
           Result := true;
          end;
        end;
       Result := Result and not GetVolumeInformation(nameWithSlash, nil, 0, nil, Ntom, fs, nil, 0); // нет фаиловой систкмы
      end;
     CloseHandle(hDevice);
    end;
end;


{ TSDflashStream }

class function TSDStream.EnumLogicalDrives: TArray<TLogicalDevice>;
 var
  driveMask: DWORD;
  pID: ULONG;
  D: Char;
//  drivename: string;
begin
  driveMask := GetLogicalDrives();
  D := 'A';
  while (driveMask <> 0) do
   begin
    if ((driveMask and 1) <> 0) and checkDriveType(D, pID) then Result := Result + [getGeometry(D)];
    driveMask := driveMask shr 1;
    D := Succ(d);
   end;
end;
{$ENDREGION 'FUNCS'}

{$REGION 'TSDStream'}
constructor TSDStream.Create(const Dev: TLogicalDevice; access: ULONG);
// var
//  cbBytesReturned: DWORD;
//  dg: DISK_GEOMETRY_EX;
begin
  FHandle := CreateFile(PChar(Format('\\.\%s:', [Dev.Letter])), access,
             FILE_SHARE_READ or FILE_SHARE_WRITE, nil, OPEN_EXISTING, FILE_FLAG_OVERLAPPED, 0);
  if FHandle = INVALID_HANDLE_VALUE then RaiseLastOSError;
//  if not DeviceIoControl(FHandle, IOCTL_DISK_GET_DRIVE_GEOMETRY_EX, nil, 0, @dg, sizeof(dg), cbBytesReturned, nil) then RaiseLastOSError;
  FSectorSize := Dev.SectorSize;//.Geometry.BytesPerSector;
  FDiskSize := Dev.DiskSize;
  FNumSectors := Dev.NumSectors;
  inherited Create(FHandle);
end;

destructor TSDStream.Destroy;
// var
//  cbBytesReturned: DWORD;
begin
  if FHandle <> INVALID_HANDLE_VALUE then CloseHandle(FHandle);
  inherited;
end;

function TSDStream.GetSize: Int64;
begin
  Result := FDiskSize;
end;
procedure TSDStream.SetSize(NewSize: Integer);
begin
end;
procedure TSDStream.SetSize(const NewSize: Int64);
begin
end;

function TSDStream.Seek(const Offset: Int64; Origin: TSeekOrigin): Int64;
begin
  SetLastError(0);
  if Origin = soEnd then Result := FileSeek(FHandle, FDiskSize+Offset, Ord(soBeginning))
  else Result := FileSeek(FHandle, Offset, Ord(Origin));
  if GetLastError <> ERROR_SUCCESS then
   begin
    RaiseLastOSError;
   end;
end;

function TSDStream.AsyncCopyTo(const FlName: string; Offset, Count: Int64; ToZ: Boolean; ev: TCopyAsyncEvent): ITask;

begin
  // поток
  Result := TTask.Run(procedure
   var
    CapturedException : Exception;
    dummy_stat: TStatistic;
  begin
    with TAsyncCopy.Create(Self, FlName, Offset, Count, ToZ, ev) do
    try
      try
       Execute;
      except
       CapturedException := TObject(AcquireExceptionObject) as Exception;
       Fevent(carError, dummy_stat);
       TThread.Queue(TThread.CurrentThread, procedure
        begin
          raise CapturedException;
        end);
      end;
    finally
     Free;
    end;
  end);
end;
{$ENDREGION 'TSDStream'}


{ TAsyncCopy }

procedure TAsyncCopy.CheckData;
begin
  // проверка на диапазон
  if FOffset mod FStrmSD.SectorSize <> 0 then raise Exception.CreateFmt('Offset[%d] mod SectorSize[%d] <> 0',[FOffset,FStrmSD.SectorSize]);
  if FCount mod FStrmSD.SectorSize <> 0 then raise Exception.CreateFmt('Count[%d] mod SectorSize[%d] <> 0',[FCount,FStrmSD.SectorSize]);
  if FOffset >= FStrmSD.Size then raise Exception.Create('Offset >= SD Size');
  if FOffset + FCount > FStrmSD.Size then raise Exception.Create('Offset+Count > SD Size');
end;

function TAsyncCopy.CheckZerroes(p: PByte; cnt: Cardinal; out ZBegin: Cardinal): Boolean;
 var
  pdw: PDword;
  n: Cardinal;
begin
  /////
  //Exit(False);
  ////
  PByte(pdw) := p + cnt;
  n := ZPOROG div 4;
  // 512 bytes test
  repeat
   Dec(pdw);
   Dec(n);
   if not ((pdw^ = 0) or (pdw^ = $FFFFFFFF)) then Exit(False);
  until n = 0;
 // find last no z
  Result := True;
  n := (cnt - ZPOROG) div 4;
  repeat
   Dec(pdw);
   Dec(n);
   if not ((pdw^ = 0) or (pdw^ = $FFFFFFFF)) then Break
//   if (pdw^ <> 0)   then Break;
  until n = 0;
  Inc(pdw); // первый нулевой указатель
  ZBegin := PByte(pdw) - p;
end;

constructor TAsyncCopy.Create(SrcSD: TSDStream; const DestFile: string; Offset, Count: Int64; ToZ: Boolean; ev: TCopyAsyncEvent);
begin
  FStrmSD := TSDStream(SrcSD);
  FOffset := Offset;
  if Count = 0 then FCount := FStrmSD.Size - FOffset else FCount := Count;
  FToZ  := ToZ;
  Fevent := ev;
  FDestFile := DestFile;
end;



destructor TAsyncCopy.Destroy;
begin
  if Assigned(FMap) then FreeAndNil(FMap);
  if Assigned(FStrmFile) then FreeAndNil(FStrmFile);
  inherited;
end;

procedure TAsyncCopy.Execute;
 var
  r: TLoadViewResult;
  FLagEnd: Boolean;
begin
  CheckData;
  FStrmSD.Position := FOffset;
  InnerCreateStream;
  InnerCreateMap;
  FReadCount := 0;
  FTerminate := False;
  FBeginTime := Now;
  repeat
   FLagEnd := LoadView(FMap.Views[0].Memory, FMap.Views[0].Size, r);
   Inc(FReadCount, r.NumLoad);
   if not FLagEnd then InnerRemap;
  until FLagEnd;
  if Assigned(FMap) then FreeAndNil(FMap);
  FStrmFile.Size := FReadCount;
end;

procedure TAsyncCopy.InnerCreateStream;
 var
  path: string;
begin
  if Assigned(FStrmFile) then FreeAndNil(FStrmFile);
  if TFile.Exists(FDestFile) then FStrmFile := TFileStream.Create(FDestFile, fmOpenReadWrite)
  else
   begin
    path := TPath.GetDirectoryName(FDestFile);
    if not TDirectory.Exists(path) then TDirectory.CreateDirectory(path);
    FStrmFile := TFileStream.Create(FDestFile, fmCreate);
   end;
  // file Size
  if (FCount > GIG) and FToZ then FStrmFile.Size := GIG // чтение до нулей начнем с GIG
  else FStrmFile.Size := FCount; // весь файл даже если 16 гиг
end;

  function ResetTimout(NumRead: Cardinal): Cardinal;
  begin
    Result := NumREad *1000 div 2000000;
    if Result < 300 then Result := 300;
  end;

function TAsyncCopy.LoadErrorView(Memory: Pbyte; size: Cardinal; var Res: TLoadViewResult): Boolean;
 const
  NUM_TH = 32;
 var
  ras: array[0..NUM_TH-1] of TReadAsync;
  ev: array[0..NUM_TH-1] of THandle;
  cntev: Integer;
  ssdFrom: Int64;
  Cur: Pbyte;
  function CretateRead(numRead: Cardinal): Cardinal;
   var
    i: Integer;
    needread: Cardinal;
  begin
    cntev := 0;
    Result := 0;
    for i := 0 to NUM_TH-1 do
     begin
      if size >= numRead then
         needread := numRead
      else
         needread := size;
      ras[i] := TReadAsync.Create(FStrmSD, ssdFrom + Res.NumLoad + Result, needread, Cur + Result, True);
      ev[i] := ras[i].Event;
      inc(cntev);
      Inc(Result, needread);
      Dec(size, needread);
      if size = 0 then Exit;
     end
  end;
  function CheckErrorSectors: TArray<Integer>;
   var
    i: Integer;
    nRead: DWORD;
  begin
    Result := [];
    for i := 0 to cntev-1 do
     begin
      if not GetOverlappedResult(FStrmSD.Handle, ras[i].FOverlaped, nRead, FALSE) then
       begin
        CancelIoEx(FStrmSD.Handle, @ras[i].FOverlaped);
        Result := Result + [i];
       end
      else if nRead <> ras[i].FNeedRead then
       begin
        Result := Result + [i];
       end;
     end;
  end;
  procedure DestroyRead;
   var
    i: Integer;
  begin
    for i := 0 to NUM_TH-1 do if Assigned(ras[i]) then
     begin
      FreeAndNil(ras[i]);
      ev[i] := 0;
     end
  end;
 var
  timout: Cardinal;
  wres: Cardinal;
  nRead: Cardinal;
begin
  Result := False;
  ssdFrom := FOffset+FReadCount;
  while size > 0 do
   begin
    cur := Pointer(TJclAddr(Memory) + TJclAddr(Res.NumLoad));
    nRead := CretateRead(FStrmSD.FSectorSize);
    timout := ResetTimout(nRead); // TODO: Function of nRead, cntev
    try
     wres := WaitForMultipleObjects(cntev, @ev, True, timout);
     if wres >= DWORD(WAIT_OBJECT_0+cntev) then
      begin
       var s := Format(RSM_SecAdr, [wres, (ssdFrom+Res.NumLoad) div FStrmSD.FSectorSize, ssdFrom+Res.NumLoad]);
       for var erSec in CheckErrorSectors() do s := s + ' '+ erSec.ToString;
       if Assigned(TDebug.ExeptionEvent) then TDebug.ExeptionEvent(RSEV_Sec, s, '');
      end;
    finally
     DestroyRead
    end;
    Inc(Res.NumLoad, nRead);
    if UpdateStatistic(Cur, nread, Res) then Exit(True);
   end
end;

function TAsyncCopy.LoadView(Memory: Pointer; size: Cardinal; var Res: TLoadViewResult): Boolean;
 var
  nread, needread: Cardinal;
  Cur: Pbyte;
  ras: TReadAsync;
  wres: DWORD;
  timout: DWORD;
  label M1;
begin
  Result := False;
  Res.Res := carOk;
  Res.NumLoad := 0;
  timout := ResetTimout(M32);
  while size > 0 do
   begin
    cur := Pointer(TJclAddr(Memory) + TJclAddr(Res.NumLoad));
    if size >= M32 then needread := M32
    else needread :=  size;
    ras := TReadAsync.Create(FStrmSD, FOffset + FReadCount + Res.NumLoad , needread, Cur);
    try
      wres := WaitForSingleObject(ras.Event, timout);
      nread := ras.Readed;
      if (WAIT_OBJECT_0 <> wres) or (nread = 0) then
       begin
        // err
        CancelIoex(FStrmSD.Handle, @ras.FOverlaped);
        FreeAndNil(ras);
        if LoadErrorView(Memory, needread, Res) then Exit(True);
        Dec(size, needread);
       end
      else
       begin
        // next
        inc(Res.NumLoad, nread);
        Dec(size, nread);
        if UpdateStatistic(Cur, nread, Res) then Exit(True);
       end
     finally
      if Assigned(ras) then FreeAndNil(ras);
     end;
   end;
end;

class procedure TAsyncCopy.Terminate();
begin
  FTerminate := True;
  if Assigned(FStrmSD) then CancelIoEx(FStrmSD.Handle, nil);
end;

function TAsyncCopy.UpdateStatistic(Cur: Pbyte; size: Cardinal; var Res: TLoadViewResult): Boolean;
 var
  lastNZ: Cardinal;
  prc: TStatistic;
begin
  Result := False;
  prc := GetStatistic(Res.NumLoad);
  // check empty  об€зательно сначала вычисл€ем нули  т.к. считано может быть до конца
  if FToZ and CheckZerroes(Cur, size, lastNZ) then
   begin
    Res.Res := carZerroes;
    Res.NumLoad := Res.NumLoad - size + lastNZ;
    Fevent(carZerroes, GetStatistic(Res.NumLoad));
    Exit(True);
   end
  // check end
  else if prc.ProcRun >= 100 then
   begin
    Res.Res := carEnd;
    Fevent(carEnd, prc);
    Exit(True);
   end
  else
   begin
    Fevent(carOk, prc);
   // check user terminate
    if FTerminate then
     begin
      Res.Res := carTerminate;
      Fevent(carTerminate, prc);
      Exit(True);
     end;
   end;
end;

function TAsyncCopy.GetStatistic(LocalRead: Cardinal): TStatistic;
 var
  Spd: double;
begin
  Result.NRead := FReadCount+LocalRead;
  Result.TimeFromBegin := Now - FBeginTime;
  Result.ProcRun := Result.NRead/FCount*100;
  // speed
  Spd := Result.NRead / Result.TimeFromBegin;
  Result.Speed := Spd/1024/1024 /24/3600; // MB/sec
  Result.TimeToEnd := (FCount - Result.NRead)/spd;
end;

procedure TAsyncCopy.InnerCreateMap;
 const                        //0- малый мап all file
  NSZ: array[Boolean] of Int64 = (0, GIG);
begin
  // create Map and first view
  if Assigned(FMap) then FreeAndNil(FMap);
  FMap := TJclFileMapping.Create(FStrmFile.Handle, '', PAGE_READWRITE, 0, nil);
  FMap.Add(SECTION_MAP_WRITE, NSZ[FCount > GIG], 0);
end;

procedure TAsyncCopy.InnerRemap;
 var
  toEnd: int64;
begin
  toEnd := FCount - FReadCount;
  if toend > GIG then toend := GIG;
  if FToZ then  // увеличиваем казмер файла
   begin
    // resize and recreate map
    if Assigned(FMap) then FreeAndNil(FMap);
    FStrmFile.Size := FStrmFile.Size + toend;
    FMap := TJclFileMapping.Create(FStrmFile.Handle, '', PAGE_READWRITE, 0, nil);
   end
  // delete view
  else FMap.Delete(0);
  // add view
  FMap.Add(SECTION_MAP_WRITE, toend, FReadCount);
end;

//function TAsyncCopy.View: TJclFileMappingView;
//begin
//  Result := FMap.Views[0];
//end;

{ TReadAsync }

constructor TReadAsync.Create(AOwner: TSDStream; offset: Int64; nRead: DWORD; Memory: Pointer; NeedClear: Boolean);
begin
  FNeedRead := nRead;
  FNeedClear := NeedClear;
  FillChar(FOverlaped, SizeOf(FOverlaped), 0);
  PInt64(@FOverlaped.Offset)^ := offset;
  if NeedClear then FillChar(Memory^, nRead, $FF);
  FOverlaped.hEvent := CreateEvent(nil, True, False, nil);
  if not ReadFile(AOwner.Handle, Memory^, FNeedRead, FReaded, @FOverlaped) then FError := GetLastError() <> ERROR_IO_PENDING
  else FError := False;
end;

destructor TReadAsync.Destroy;
begin
  CloseHandle(FOverlaped.hEvent);
  inherited;
end;

function TReadAsync.GetReaded: DWORD;
begin
  if (FOverlaped.InternalHigh = 0) and FNeedClear then Result := FNeedRead
  else Result := DWORD(FOverlaped.InternalHigh);
end;

end.

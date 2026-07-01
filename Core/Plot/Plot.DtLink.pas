unit Plot.DtLink;

interface

{$INCLUDE global.inc}

uses
  CustomPlot.DataLink, CustomPlot, Plot.VirtualData, Plot.VirtualDataLink,
  System.SysUtils, System.Classes, System.Math, Data.DB, DataSetIntf, IDataSets,
  FileDataSet, Parser, debug_except, ExtendIntf, Container, tools;

type
  {$REGION 'Legacy interfaces preserved for compatibility'}

  ILineDataLink = interface(IVirtualLineDataLink)
    ['{437AAA7B-C3CD-4D30-8A75-4CD745EB8BB3}']
  end;

  IWaveDataLink = interface(IVirtualWaveDataLink)
    ['{D9EA754D-F43C-4029-A05F-F6008EFB3052}']
  end;

  {$ENDREGION}

  {$REGION 'Legacy names forwarded to new virtualized implementations'}

  /// <summary>
  /// Legacy line DataLink. Now inherits from the virtualized implementation and
  /// no longer uses a temporary file buffer. It keeps the old published class name
  /// so existing projects load without changes.
  /// </summary>
  TlineDataLink = class(TVirtualLineDataLink, ILineDataLink)
  public
    constructor Create(AOwner: TObject); override;
  end;

  /// <summary>
  /// Legacy wave DataLink. Now inherits from the virtualized implementation.
  /// </summary>
  TWaveDataLink = class(TVirtualWaveDataLink, IWaveDataLink)
  public
    constructor Create(AOwner: TObject); override;
  end;

  /// <summary>
  /// Generic forwarder. Exists only to satisfy code that references TDataLink<T>.
  /// </summary>
  TDataLink<T> = class(TVirtualDataLink)
  protected
    function CreateReader: TVirtualDataReaderBase; override;
  end;

  {$ENDREGION}

implementation

{$REGION 'TlineDataLink'}

constructor TlineDataLink.Create(AOwner: TObject);
begin
  inherited;
end;

{$ENDREGION}

{$REGION 'TWaveDataLink'}

constructor TWaveDataLink.Create(AOwner: TObject);
begin
  inherited;
end;

{$ENDREGION}

{$REGION 'TDataLink<T>'}

function TDataLink<T>.CreateReader: TVirtualDataReaderBase;
const
  MSG = 'Generic TDataLink<T> cannot be instantiated directly; use TlineDataLink or TWaveDataLink.';
begin
  raise Exception.Create(MSG);
end;

{$ENDREGION}

initialization
  RegisterClasses([TlineDataLink, TWaveDataLink, TDataLink<Single>, TDataLink<TArray<ShortInt>>]);

end.

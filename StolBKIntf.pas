unit StolBKIntf;

interface

uses System.SysUtils, DeviceIntf, tools;

const
  ADR_PULT_BK     = 2415;

type
 TPultRes = reference to procedure (Res: Boolean);

 IPultBK = interface(IDevice)
 ['{90B7B9B5-2786-4E26-B898-9ECC376600E8}']
   procedure Command(Data: Word; Res: TPultRes);
 end;


implementation

end.

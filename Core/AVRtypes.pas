unit AVRtypes;

interface

 const
  DECOD_SP = -2;
  DECOD_NOTSP = -4;
  DECOD_BADCODE = -6;
  DECOD_RETRA = -8;
  DECOD_BADRETRA = -10;
  DECOD_SIGNAL_SHUM = -12;
  DECOD_O1H = 1;
  DECOD_O2H = 3;
  DECOD_ZH = 5;
  DECOD_O3H = 7;
  DECOD_AH = 9;
  DECOD_O4H = 11;
  DECOD_RH = 13;
  DECOD_O5H = 15;

  STDDATA_O1 = 0;
  STDDATA_O2 = 1;
  STDDATA_O3 = 2;
  STDDATA_O4 = 3;
  STDDATA_O5 = 4;
  STDDATA_Z =  5;
  STDDATA_A =  6;
  STDDATA_R1L = 7;
  STDDATA_R2L = 8;
  STDDATA_R3L = 9;
  STDDATA_R1H = 10;
  STDDATA_R2H = 11;
  STDDATA_R3H = 12;

 type
   TDataType = (dtBadCode, dtNotSP, dtSP, dtOtklonitel, dtZenit, dtAzimut, dtR1, dtR2, dtR3,
   dtVibra, dtTemp, dtGK, dtAO, dtZamerZenit, dtZamerAzimut, dtZabur, dtNotZabur, dtMapMag, dtVibraZen,
   dtAmpAcc, dtTAcc, dtTMag, dtV, dtObr, dtI, dtR, dtF, dtR4, dtR5, dtR6, dtRetra, dtBadRetra, dtSignalShum,
   dtBegin, dtGoodEnd, dtOtklonitelZamer, dtAOZamer);

   PPriborData = ^TPriborData;

   TPriborData = record
     DataType : TDataType;
     Data : Real;
     Probability : Real;
   end;

   PStdDecoderData = ^TStdDecoderData;
   
   TStdDecoderData = record
     Data : integer;
     Probability : Real;
   end;

   TPriborPaketData = record
     TimePak: TDateTime;
     PriborDataPaket: array[0..9] of TPriborData;
   end;

implementation

end.
 
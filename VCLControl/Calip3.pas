
unit Calip3;

interface

//#pragma pack(push, 1)
//typedef struct
//
//    int16_t X;
//    int16_t Y;
//    int16_t Z;
// accel_t;
//#pragma pack(pop)
 type
   accel_t = packed record
    X,Y,Z: SmallInt;
   end;

//#pragma pack(push, 1)
//typedef struct
//    int16_t d0[679];
//    int16_t d1[682];
//    int16_t d2[682];
//    int16_t d3[682];
//    int16_t d4[682];
//    int16_t d5[682];
//    int16_t d6[682];
//    int16_t d7[682];
//    int16_t d8[682];
// fkd_t;
//#pragma pack(pop)
   fkd_t = packed record
    d0: array [0..678] of SmallInt;
    d1: array [0..681] of SmallInt;
    d2: array [0..681] of SmallInt;
    d3: array [0..681] of SmallInt;
    d4: array [0..681] of SmallInt;
    d5: array [0..681] of SmallInt;
    d6: array [0..681] of SmallInt;
    d7: array [0..681] of SmallInt;
    d8: array [0..680] of SmallInt;
   end;

//#pragma pack(push, 1)
//typedef struct
//
//	int16_t gk; ///гк
// gamma_t;
//#pragma pack(pop)
///*    Установка размера выравнивания в 1 байт,
//    описание структуры и возврат предыдущей настройки. */
   gamma_t = packed record
    gk: word;
   end;
//#pragma pack(push, 1)
//typedef struct
//
//	float T;
//	uint16_t AmpH;  /// потребление
//	gamma_t GR;     /// ГК|GK1
//	accel_t accel;  /// accel|CLA1
//	fkd_t fkd;
// Caliper_t ;
//#pragma pack(pop)
   Caliper_t = packed record
    T: Single;
    AmpH: Word;
    GR: gamma_t;
    accel: accel_t;
    fkd: fkd_t;
   end;


//#pragma pack(push, 1)
//typedef struct
//	uint8_t automat;   /// автомат|AU
//	int32_t Time;      /// время|WT
//	Caliper_t Caliper;
// DataStructW_t ;
//#pragma pack(pop)

   TProfilemerData3 = packed record //
     automat: Byte;
     Time: Integer;
     Caliper: Caliper_t;
     Dummi: Byte;
   end;




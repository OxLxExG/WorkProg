#pragma  once
#include <stdint.h>

#pragma pack(push, 1)
//-name=accel
//-metr=CLA1
//- RangeLo = -2000
//- RangeHi =  2000
//- eu = G
typedef struct
{
	int16_t X;
	int16_t Y;
//- RangeLo = -4000
//- RangeHi =  4000
	int16_t Z;
} accel_t;
#pragma pack(pop)


#	define LEN_MS 682  // simple comment
#	define LEN_MS1 0x2A7  // simple comment
//- arrayShowLen = 30
#pragma pack(push, 1)
typedef struct
{
   //- noname
	int16_t d0[LEN_MS1];
	int16_t d1[LEN_MS];
	int16_t d2[LEN_MS];
	int16_t d3[LEN_MS];
	int16_t d4[LEN_MS];
	int16_t d5[LEN_MS];
	int16_t d6[LEN_MS];
	int16_t d7[LEN_MS];
    int16_t d8[LEN_MS];
} fkd_t;
#pragma pack(pop)

//-name=зонд
//- metr=MZ1
//- arrayShowLen=6
#pragma pack(push, 1)
typedef struct
{
	int16_t i[7];
	int16_t u[7];
//-name=Бк
//- RangeLo = -0.3
//- RangeHi = 3.1
	uint16_t uBk;
} zond_t;
#pragma pack(pop)


//-name=ГК
//- metr=GK1
//-	eu=мкР
#pragma pack(push, 1)
typedef struct
{
	//-name=гк
	int16_t gk;
} gamma_t;
#pragma pack(pop)

/*    Установка размера выравнивания в 1 байт,
    описание структуры и возврат предыдущей настройки. */

#pragma pack(push, 1)
typedef struct
{
	//- digits=4
	//- precision=1
	// color=0x00FF30FF
	float T;
	//- name=потребление
	uint16_t AmpH;
	//-structname
	gamma_t GR;
	//-structname
	accel_t acc;
	//-structname
	//- info = "данные зондов"
	zond_t z[3];
	fkd_t fkd;
} Caliper_t ;
#pragma pack(pop)

#pragma pack(push, 1)
typedef struct
{
	//- name= автомат
	//- metr = AU
	uint8_t automat;
	//- name= время
	//- metr= WT
	int32_t Time;
	Caliper_t Caliper;
} DataStructW_t ;
#pragma pack(pop)

#pragma pack(push, 1)
typedef struct __attribute__((packed))
{
  //- name= время
  //- metr =WT
	int32_t Time;
	Caliper_t Caliper;
} DataStructR_t ;
#pragma pack(pop)

#define ADR_PROC 7

#pragma pack(push, 1)
//- adr = ADR_PROC
//- info = "__DATE__ __TIME__ Профилемер v3"
//- chip = 9
//- serial = 529
//- NoPowerDataCount = 33
//- name = Calip3
//- SupportUartSpeed = 0xE0
//- export
typedef struct
{
 //- WRK
//- noname
   DataStructW_t Wrk;
   //- RamSize =65000
   //- RAM
   //- noname
   DataStructR_t Ram;
} AllDataStruct_t;
#pragma pack(pop)





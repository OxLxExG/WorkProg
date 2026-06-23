#pragma  once

namespace adxl356gk_v2
{
	
typedef struct __attribute__((packed))
{
	int32_t X;
	int32_t Y;
	int32_t Z;
} Dat_t;

typedef struct __attribute__((packed))
{
	float X;
	float Y;
	float Z;
} Dat_m_t;

typedef struct __attribute__((packed))
{
	//- digits=10
	//- precision=5
	float  kGK;
//-color = 0x00FF0000	
	uint16_t DAC;
} TrrGk_t;

// - name=m3x4
//- digits = 12
//- precision=8
typedef struct __attribute__((packed))
{
	float  m11;
	float  m12;
	float  m13;
	float  m14;
	float  m21;
	float  m22;
	float  m23;
	float  m24;
	float  m31;
	float  m32;
	float  m33;
	float  m34;
} m3x4_t;

typedef struct __attribute__((packed))
{
	m3x4_t m3x4;
} TrrSensor_t ;

typedef struct __attribute__((packed))
{
	TrrSensor_t accel;
	TrrSensor_t magnit;
} TrrInclin_t;

typedef struct __attribute__((packed))
{
	Dat_m_t AmpMag[3];
	Dat_m_t DMag[3];
	Dat_m_t DAcc[3];
} TrrInclinT_t;

typedef struct __attribute__((packed))
{	
//- name=ГК
	TrrGk_t GR1; 
	TrrInclin_t Inclin;
	TrrInclinT_t InclinT;
} eep_t;

//- ShowHex
typedef struct __attribute__((packed))
{
	uint16_t id;
	uint16_t status;
	uint16_t mode;
	uint16_t clock;
	uint16_t gain1;
	uint16_t gain2;
	uint16_t cfg;	
} eep_ads131_t;


typedef struct __attribute__((packed))
{
	//- name=автомат
	//- metr=AU
	uint8_t AppState;
	//- name=время
	//- metr=WT
	int32_t time;
} eep_save_t;

typedef struct __attribute__((packed))
{
	//- from=0
	eep_t metr;
	//- from=1024
	eep_ads131_t ads313regs;
	//- from=2048
	eep_save_t eep;
} EepData_t;
	
//- name=ГК
//- metr=GK1
typedef struct __attribute__((packed))
{
//- name= гк
	uint16_t gk; 
} Gk_t ;

//- name=Inclin
//- metr=INKLGK1
typedef struct __attribute__((packed))
{
	//- eu = mG
	//- digits=10
	//- precision=1
	Dat_m_t accel_m;
	//- eu = nT
	//- digits=10
	//- precision=1
	Dat_m_t magnit_m;
	//- eu  = мкР
	//- digits=10
	//- precision=2
	float gk_m;
	//- name= отклонитель
	//- eu= grad
	//- digits=10
	//- precision=1
	float Gtf; 
	//- name= зенит
	//- eu= grad
	//- digits=10
	//- precision=2
	float Zenit; 
	//- name= азимут
	//- eu= grad
	//- digits=10
	//- precision=1
	float Azimut = 1.1f;
	//- name= маг_отклон
	//- eu= grad
	//- digits=10
	//- precision=1
	float Mtf; 
	//- name= амплит_accel
	//- eu = mG
	//- digits=10
	//- precision=0
	int16_t Gtot; 
	//- name= амплит_magnit
	//- eu = nT
	//- digits=10
	//- precision=0
	int16_t Mtot; 
	//- name= маг_наклон
	//- eu= grad
	//- digits=10
	//- precision=1
	float Mn; 
	//- eu= grad.C
	//- digits=10
	//- precision=3
	float T;
	Dat_t accel;
	Dat_t magnit;
} InclW_t;

typedef  struct __attribute__((packed))
{
//- name=автомат
//- metr=AU
	uint8_t AppState;
//- name=время
//- metr=WT
	int32_t time;    
	//-structname
	InclW_t dat;	
	//-structname
	Gk_t gk;        
} WorkData_t;

typedef struct __attribute__((packed))
{
//#	define RAM_SIZE 32 /// varRamSize
//- name=время
//- metr=WT
	int32_t ramtime;    
	//-structname
	InclW_t dat;  
	//-structname
	Gk_t gk;        
} RamData_t;

//- adr = 3
//- info = "__DATE__ __TIME__  ADXL356.1 GK EEP"
//- chip = 6
//- serial = 1
//- name = InclGK2
//- SupportUartSpeed = 0xE0
//- export
typedef struct __attribute__((packed))
{
 //- WRK
 //- noname
   WorkData_t Wrk; 
   //- RamSize = 32
   //- RAM
   //- noname
   RamData_t Ram; 
   //- EEP
   //- noname
   EepData_t eep;
} AllDataStruct_t; 
}


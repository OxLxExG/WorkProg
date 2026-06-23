#pragma  once

namespace adxl354gk
{
	
typedef struct __attribute__((packed))
{
	uint16_t gk; ///гк
} Gk_t ;

typedef struct __attribute__((packed))
{
	Gk_t GR1; /// ГК|GK1
} EepData_t;
	
typedef struct __attribute__((packed))
{
	int16_t X;
	int16_t Y;
	int16_t Z;
} Dat_t;

typedef struct __attribute__((packed))
{
	Dat_t accel;
	Dat_t magnit;
	int16_t T;
	float Zenit; /// зенит
	float Azimut; /// азимут
	float Gtf; /// отклонитель
	float Mtf; /// маг_отклон
	int16_t Gtot; /// амплит_accel
	int16_t Mtot; /// амплит_magnit
} InclW_t;

typedef struct __attribute__((packed))
{
	Dat_t accel;
	Dat_t magnit;
	int16_t T;
} InclR_t_old;

typedef  struct __attribute__((packed))
{
	uint8_t AppState; ///  автомат|AU
	int32_t time;    ///  время|WT
	InclW_t dat;	/// Inclin|INKLGK
	Gk_t gk;        /// ГК|GK1
} WorkData_t;

typedef struct __attribute__((packed))
{
#	define RAM_SIZE 32 /// varRamSize
	int32_t ramtime;    ///  время|WT
	InclW_t dat;  /// Inclin|INKLGK
	Gk_t gk;        /// ГК|GK1
} RamData_t;

typedef struct __attribute__((packed))
{
#	define ADDRESS_PROC 3			/// var_adr
#	define DEV_INFO  "__DATE__ ADXL354 GK" /// var_info
#	define CHIP_NUMBER 4       		   /// varChip
#	define SERIAL_NUMBER 1    		   /// varSerial
#	define UART_SPEED_MASK 192 /// varSupportUartSpeed
   WorkData_t Wrk; /// WRK
   RamData_t Ram; /// RAM
   EepData_t Eep; /// EEP
} AllDataStruct_t; /// InclGK1
}

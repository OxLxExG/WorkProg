#ifndef STRUCTOFDATA_H
#define STRUCTOFDATA_H

#pragma pack(push, 1)
typedef struct
{
    int16_t X;
    int16_t Y;
    int16_t Z;
} accel_t;
#pragma pack(pop)

#pragma pack(push, 1)
typedef struct
{
    int16_t d0[677];
    int16_t d1[682];
    int16_t d2[682];
    int16_t d3[682];
    int16_t d4[682];
    int16_t d5[682];
    int16_t d6[682];
    int16_t d7[682];
    int16_t d8[682];
} fkd_t;
#pragma pack(pop)

#pragma pack(push, 1)
typedef struct
{
	uint16_t gk; ///гк
} gamma_t;
#pragma pack(pop)

#pragma pack(push, 1)
typedef struct
{
	float T;
	uint16_t AmpH;  /// потребление
	float vcc;  /// напряжение_питания
	gamma_t GR;     /// ГК|GK1
	accel_t accel;  /// accel|CLA1
	fkd_t fkd;
} Caliper_t ;
#pragma pack(pop)

#pragma pack(push, 1)
typedef struct
{
	uint8_t automat;   /// автомат|AU
	int32_t Time;      /// время|WT
	Caliper_t Caliper;
} DataStructW_t ;
#pragma pack(pop)

#pragma pack(push, 1)
typedef struct
{
    #define RAM_SIZE 160000 /// varRamSize
	int32_t Time;         /// время|WT
	Caliper_t Caliper;
} DataStructR_t ;
#pragma pack(pop)

#pragma pack(push, 1)
typedef struct
{
    float Charge_mAH;
    float Voltage_V;
    float Current_mA;
    float Temperature_C;
} cell_data_t;
#pragma pack(pop)

#pragma pack(push, 1)
typedef struct
{
    uint8_t aktive_cell;
    cell_data_t BATT_0;
	cell_data_t BATT_1;
} batt_manager_t;
#pragma pack(pop)

#pragma pack(push, 1)
typedef struct
{
	uint16_t GR1;
	batt_manager_t BATTERY_MANAGER;
} EepData_t;
#pragma pack(pop)

#pragma pack(push, 1)
typedef struct
{
  #define ADDRESS_PROC 7         /// var_adr
  #define DEV_INFO  "__DATE__ Профилемер v3" /// var_info
  #define CHIP_NUMBER 2       		   /// varChip
  #define SERIAL_NUMBER 1    		   /// varSerial
  #define UART_SPEED_MASK 16384 /// varSupportUartSpeed
   DataStructW_t Wrk; /// WRK
   DataStructR_t Ram; /// RAM
    EepData_t Eep; /// EEP
} AllDataStruct_t; /// Calip3
#pragma pack(pop)

#endif





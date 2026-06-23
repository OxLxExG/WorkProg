#ifndef STRUCTOFDATA_H
#define STRUCTOFDATA_H

#include <cstdint>
#include "automat.h"

#define FKD0_LEN        677
#define FKD1_8_LEN      682

#pragma pack(push, 1)
//- name=accel
//- metr=CLA1
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
    int16_t d0[FKD0_LEN];
    int16_t d1[FKD1_8_LEN];
    int16_t d2[FKD1_8_LEN];
    int16_t d3[FKD1_8_LEN];
    int16_t d4[FKD1_8_LEN];
    int16_t d5[FKD1_8_LEN];
    int16_t d6[FKD1_8_LEN];
    int16_t d7[FKD1_8_LEN];
    int16_t d8[FKD1_8_LEN];
} fkd_t;
#pragma pack(pop)

#pragma pack(push, 1)
//- name=ГК
//- metr=GK1
typedef struct
{
	//- name= гк
	uint16_t gk;
} gamma_t;
#pragma pack(pop)

#pragma pack(push, 1)
//- name = Caliper
typedef struct
{
	//- digits=8
	//- precision=2
	//-eu = Град
	float T;
	//-name =Потребление
	//-eu = мАЧ
	uint16_t AmpH;
	//-name =Напряжение_питания
	//-eu = V
	//- digits=8
	//- precision=3
	float vcc;
	//-structname
	gamma_t GR;
	//-structname
	accel_t accel;
	fkd_t fkd;
} Caliper_t;
#pragma pack(pop)

#pragma pack(push, 1)
typedef struct
{
//- name=автомат
//- metr=AU
	uint8_t automat;
//- name=время
//- metr=WT
	int32_t Time;
	//-structname
	Caliper_t Caliper;
} DataStructW_t;
#pragma pack(pop)

#pragma pack(push, 1)
typedef struct
{
//- name=время
//- metr=WT
	int32_t Time;
	//-structname
	Caliper_t Caliper;
} DataStructR_t;
#pragma pack(pop)

#pragma pack(push, 1)
typedef struct
{
	//- name = Счетчик
	//- eu = мАЧ
	//- digits=8
	//- precision=3
	float Charge_mAH;
	//- name = Напряжение
	//- eu = В
	//- digits=8
	//- precision=3
	float Voltage_V;
} cell_t;
#pragma pack(pop)

#pragma pack(push, 1)
//-name = БАТАРЕЯ_ПИТАНИЯ
typedef struct
{
	//- name = Общий_счетчик
	//- eu = мАЧ
	//- digits=8
	//- precision=2
//-color = 0x00FF0000
	float common_charge_mAH;
	//- name = ЭЛЕМЕНТ_1
	cell_t CELL_0;
	//-name =ЭЛЕМЕНТ_2
	cell_t CELL_1;

} batt_manager_t;
#pragma pack(pop)

#pragma pack(push, 1)
//- name = ВРЕМЯ_НАРАБОТКИ
typedef struct
{
	//- name= режим_простоя
	//- eu=Ч
	//- metr =WT
	uint32_t idle_time;
	//- name= режим_записи
	//- eu=Ч
	//- metr =WT
	uint32_t work_time;
} working_time_t;
#pragma pack(pop)

#pragma pack(push, 1)
typedef struct
{
	//- name= Триггер_ГК
	//-eu= мВ
	//- readonly
	uint16_t        GR_TRIG;
	//-structname
	batt_manager_t  BATTERY;
	//-structname
	working_time_t  WORKING_TIME;
} EepData_t;
#pragma pack(pop)

#define ADDRESS_PROC 7

#pragma pack(push, 1)
//- adr = ADDRESS_PROC
//- info = "__DATE__ __TIME__  MAIN_BOARD_108_120_V1 Версия платы: 6.1"
//- chip = 2
//- serial = 1
//- name = Calip3
//- SupportUartSpeed = 16384
//- export
typedef struct
{
	//- WRK
	//-noname
   DataStructW_t Wrk;
   //- RamSize = 16000
	//- RAM
	//-noname
   DataStructR_t Ram;
	//- EEP
	//-noname
	EepData_t Eep;
} AllDataStruct_t;
#pragma pack(pop)

#endif





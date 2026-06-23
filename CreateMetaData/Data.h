#pragma  once
#include <avr/io.h>

namespace induc
{
 typedef struct __attribute__((packed))
 {
	 uint16_t page;  
	 uint16_t block;   
 } tst_RowAddrs;
    
typedef struct __attribute__((packed))
{
	uint16_t reis;  
	uint16_t block;  
} tst_reis_t;
	
//-readonly
typedef struct __attribute__((packed))
{
	uint16_t ResetCount;	
	uint8_t ResetFunction;	
	uint8_t ResetRegister;
	//- name=восстановленый_кадр
	//- metr=WT
	int32_t kadr_Reset;
} reset_t;

//-color = 0x000000FF
//-ShowHex
//-readonly
typedef struct __attribute__((packed))
{	
	//-name=Ошибки_устройств
	uint16_t ErrPerifMsk;
	//-name=Ошибки_NAND
	uint16_t ErrNandMsk;
} perif_errors_t;

typedef struct __attribute__((packed))
{
	//- name=Аномальный_сброс
	reset_t reset; //8
	//- name=время_qzErr
	//- metr=WT
	//- readonly
	int32_t kadr_qzErr;	//4
    //- name = Ошибки_битовая_маска
    perif_errors_t err; //4
} eep_errors_t; //16 


//-readonly
typedef struct __attribute__((packed))
{
	//- name=автомат
	//- metr=AU
	uint8_t AppState;
	//- name=время
	//- metr=WT
	int32_t time;	
} work_state_t;


typedef struct __attribute__((packed))
{
	//- ShowHex
	//-readonly
	uint16_t bad_blocks[40];
} flash_nand_bad_bloks_t;

//-readonly
typedef struct __attribute__((packed))
{
	//-color=0x000000FF
	char manufacturer[13];
	/** Device part number */
	//-color=0x0000FF00
	char model[21];
	/** Number of data bytes per page */
	//-ShowHex
	uint16_t data_bytes_per_page;
	/** Number of spare bytes per page */
	//-ShowHex
	uint16_t spare_bytes_per_page;
	/** Number of pages per block */
	//-ShowHex
	uint8_t pages_per_block;
	/** Number of blocks per unit */
	//-ShowHex
	uint16_t blocks_per_lun;
	/** Bad blocks maximum per unit */
	//-ShowHex
	uint8_t max_bad_blocks_per_lun;
	/** Guaranteed valid blocks at beginning of target */
	//-ShowHex
	uint8_t guarenteed_valid_blocks;
} flash_nand_t;

typedef struct __attribute__((packed))
{
	//- name=рейс
	 	uint16_t reis;
    //-readonly
	//- name=число_блоков
	 	uint16_t blocks;
	//-readonly
    //- name=блок_памяти_начало
	 	uint16_t startBlock;
	//-readonly
    //- name=блок_памяти_конец
	 	uint16_t endBlock;
} ereis_t;

//-readonly
typedef struct __attribute__((packed))
{
	//- name=оконченый_рейс
	ereis_t reises[4];   // 8*4
} eep_reis_history_t;

typedef struct __attribute__((packed))
{
    //-name=текущий_рейс
    ereis_t reis; //8
	//- name=состояние_и_кадр
	work_state_t State; //5
} eep_save_state30_t;

/////////////////////////////////

typedef struct __attribute__((packed))
{
    float Re;
    float Im;
} complex_t;


typedef struct __attribute__((packed))
{
	float Azm;
	float Zen;
	float Aps;
} inclinometer_t;
 
typedef struct __attribute__((packed))
{//128
	complex_t Tx_0;//8
	complex_t Geo[4];//32
	float amp_Vzz[4];//16
	float amp_Vzx[4];//16
	float ph_Vzx_Vzz[4];//16
	float dv[4];//16
	float border_angle[4];//16
	float temperature;//4
	uint32_t condition;//4
} direct_RX_t;

typedef struct __attribute__((packed))
{
	complex_t Tx_0[2];
	complex_t Rzz1[4];
	complex_t Rzz2[4];
	float temperature;
	uint32_t condition;
} undirect_RX_t;

typedef struct __attribute__((packed))
{ //RAW с напр. приемников (3,4) по номеру TX(1,2,4,5 или 1,2,3,5)
	float Re[16];//Re,Im
	float Im[16];//Re,Im
} sector16_t;


typedef struct __attribute__((packed))
{
	sector16_t Left[4];// Rx_Left, Rx_Right, Tx1234[4] 
	sector16_t Right[4];// Rx_Left, Rx_Right, Tx1234[4] 
} RX_raw_data_t;


typedef struct __attribute__((packed))
{ // всего 512 байт.
	//-name=информация
	uint32_t signature; 
	//передается в ГЕРС//////
	//-name=кадр
	uint32_t frame;   
	//- name=частота	
	//- eu=kHz
	uint32_t dds_freq;   
	//- name=направленные_затухание
	//- eu=dB
	float ATT_dB_geo_signal_smt[4]; //затухание в дециБеллах направленные компенсированные измерения
	//- name=направленные_фаза
	//- eu=°
	float PH_deg_geo_signal_smt[4]; //фаза в градусах направленные компенсированные измерения 
	//- name=УЭС
	//- eu=Om*m
	float rho_smt[4];//УЭС ,рассчитанные на компьютере
	//конец передачи в ГЕРС/////////
	//- name=фаза
	//- eu=°
	float phase_smt[4];//калиборвенные фазы ,рассчитанные на компьютере
	//- name=побитово_упакованне_данне
	uint8_t out_arr[32];//массив сжатых и побитово упакованных данных для отправки в телесистему
	//- name=количество_значащих_бит
	uint32_t all_bit_cntr;//количество значащих бит в этом массиве
	//- name=глубина
	uint32_t depth; //глубина, на которой были сделаны измерения(заполняется при привязке к глубине*)
	//информация для отладки////////////////////////////////////////
	//- name=направленный_приемник_верхний
	direct_RX_t R_zx_up;// данные от двух направленных приемников [0]верхний(левый) и [1]нижний(правый)
	// - name=направленный_приемник_нижний
	direct_RX_t R_zx_down;// данные от двух направленных приемников [0]верхний(левый) и [1]нижний(правый)
	// - name=приемник_центральный
	undirect_RX_t R_zz;// данные от центрального приемника                                      
	// - name=инклинометр
	inclinometer_t INC;// углы ABS, ZEN, AZM
	// - name=начальный_сектор_направленных_измерений
	int32_t  start_sector; // начальный сектор направленных измерений 0-15
	// - name=угловая_скорость
	// - eu=об.мин
	float Wg; //угловая скорость                                                  
	// - name=пропущенные_сектора
	uint32_t Tx_sector_condition[8];//информация о пропущенных секторах
} data_t;

//AllData_Direct_1DDS_1freq  
/*typedef struct __attribute__((packed))
{ // всего 480 байт.
	uint32_t signature;                                          //
	uint32_t frame;                                              //
	uint32_t dds_freq;                                           //
	direct_RX_t R_zx[2];                                    //
	undirect_RX_t R_zz;                                     //
	complex_t geo_signal_smt[4];                           //  
	float phase_smt[4];                                          //
	float rho_smt[4];                                            //
	float rho_up_smt[4];                                         // 
	float rho_down_smt[4];                                       // 
	inclinometer_t inclin;                                     //
	int32_t ApsStartAngle;                                       //
	float Wg ;                                                   // 
	uint32_t error_msg;  
	uint32_t depth;                                             
	//uint16_t expService[16];                                     
	uint32_t Tx_sector_condition[8];//
} data_t;*/

// это структура, которую отдает прибор по команде выполнить измерения
//- name=картограф
typedef struct __attribute__((packed))
{
	data_t data;
	RX_raw_data_t rx_raw_data;
} Cart_t;

////////////////////////////////


// виртуальная структура EEPROM ROM RAM

typedef struct __attribute__((packed))
{
	//- from=0
	// - password=виьклиеьщукщш
	//- name=Модель_NAND
	flash_nand_t NAND;
	//- from=16
	//- password=rwelgrtgh
	//-name=errors
	eep_errors_t errors;
	//- from=32
	//- password=STATE
	//- name=сохраненное_состояние
	eep_save_state30_t state;
	//- from=64
	//- password=цукукерьа
	//- name=История_рейсов 
    eep_reis_history_t hist;	
	//- from=128
	//- password=виьклиеьщукщш
	//- name=Сбойные_Блоки
	flash_nand_bad_bloks_t badBlock;
} EepData_t;

typedef struct __attribute__((packed))
{
	tst_RowAddrs waddr;
	tst_reis_t wreis;
	int8_t WCursorStatus;
	uint16_t pageCnt;	
	ereis_t LastReis;
    uint16_t CurrReisStartBlock;
} tst_ram;


//- name=accel
typedef struct __attribute__((packed))
{
	int16_t X;
	int16_t Y;
	int16_t Z;
	int8_t T;	
} ais21h_t;

typedef  struct __attribute__((packed))
{
	//- name=автомат
	//- metr=AU
	uint8_t AppState;
	//- name=время
	//- metr=WT
	int32_t time;
	ais21h_t accel;
	//-structname
	Cart_t dat;
    tst_ram tstram;
} WorkData_t;

typedef struct __attribute__((packed))
{
	//- name=время
	//- metr=WT
	int32_t ramtime;
	ais21h_t accel;
	//-structname
	Cart_t dat;
    tst_ram tstram;
} RamData_t;

//- adr = 6
//- info = "__DATE__ __TIME__  Картограф"
//- chip = 6
//- serial = 1
//- name = Cart
//- SupportUartSpeed = 0xFA
//- export
typedef struct __attribute__((packed))
{
	//- WRK
	//- noname
	WorkData_t Wrk;
	//- RamSize = 256
	//- RAM
	//- noname
	RamData_t Ram;
	//- EEP
	//- noname
	EepData_t eep;
} AllDataStruct_t;

}


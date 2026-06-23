unit PluginAPI;

interface

uses {Winapi.Messages,} System.TypInfo, System.SysUtils;

//const
//     WM_SYNC = WM_USER + 10;

type
  TVersion = record
    Major, Minor, Release, Build: Integer;
  end;

  // происходят плугины и сервисы ядра
//  IPluginNotify = interface
//  ['{4E658164-7690-44AA-8F07-5B97CBE4BF6F}']
//    procedure DestroyNotify;
//    procedure LoadNotify;
//  end;

  // ******** плугин **************
//  ICore = interface;
  IPlugin = interface//(IProvider)
  ['{631B96BB-1E7E-407D-83F1-5C673D2B5A15}']
  // private
//    function GetID: TGUID;
    function GetName: String;
    function GetVersion: TVersion;
  // public
//    procedure SetGore(Core: ICore);
//    procedure CheckSynchronize;
//    property ID: TGUID read GetID;
    property Name: String read GetName;
    property Version: TVersion read GetVersion;
  end;

  EClearItem = (ecIO, ecDevice, ecForm, ecFile);
  EClearItems = set of EClearItem;
  ///	<summary>
  ///	  контейнер всех динамических объектов (один из плугинов)
  ///   функции управления обьектами вызываются ядром
  ///	</summary>
  IManager = interface
  ['{0556BBBA-5DFC-4A50-9042-A1D44F0A36F1}']
//    procedure RegisterDialog(const id: TGUID; ItemClass: TClass);
    ///	<summary>
    ///	  Удаляет  динамически созданные объекты
    ///	</summary>
    procedure ClearItems(ClearItems: EClearItems = [ecIO, ecDevice, ecForm, ecFile]);
    ///	<summary>
    ///	  сообщает динамическим объектам (для показа в меню осн.прог.)
    ///	</summary>
//    procedure NotifyAfteActionManagerLoad;
    ///	<summary>
    ///	  читает формы из текущего экрана
    ///	</summary>
    procedure LoadScreen();
    ///	<summary>
    ///	  пишет формы в текущий экран
    ///	</summary>
    procedure SaveScreen();

    function ProjectName: string;

    procedure NewProject(const FileName: string; AfterCreateProject: Tproc = nil);
    procedure LoadProject(const FileName: string; AfterCreateProject: Tproc = nil);
  end;

  IManagerEx = interface
  ['{4040A260-D710-46D1-AD4E-16C350A2B990}']
    function GetProjectFilter: string;
    function GetProjectDefaultExt: string;
    function GetProjectDirectory: string;
  end;
  // ***********  ядро  ************  -
//  ICore = interface
//  ['{602AFD4B-D766-4352-BA77-91AACCB8981D}']
  // private
//    function GetVersion: TVersion;
//   public
//    property Version: TVersion read GetVersion;
//  end;

//  IPlugins = interface(ICore)
//  ['{AB739898-6A48-4876-A9FF-FFE89B409A56}']
  // private
//    function CreateInterface(const PluginIID, ServiceIID: TGUID; out Intf): Boolean;
//    function IndexOf(const PluginIID: TGUID): Integer;
//    function GetCount: Integer;
//    function GetPlugin(const AIndex: Integer): IPlugin;
  // public
//    property Count: Integer read GetCount;
//    property Plugins[const AIndex: Integer]: IPlugin read GetPlugin; default;
//  end;

type
//  TInitPluginFunc = function(const ACore: ICore): IPlugin;
  TInitPluginFunc = function: PTypeInfo;
  TDonePluginFunc = procedure;

const
  VERS1000: TVersion =(Major:1; Minor:0; Release:0; Build:0);

  SPluginInitFuncName = 'Aeqreqrtfwgtewr8BF5DE';
  SPluginDoneFuncName = SPluginInitFuncName + '_done';
  SPluginExt          = '.dlp';


//  PLUGIN_ComDev: TGUID = '{CFEDB7B7-B70A-4329-9383-20F088F7B515}';
//  PLUGIN_Managers: TGUID = '{E648CF38-A525-44DE-98B2-4BBA7B43ED76}';
//  PLUGIN_Dialogs: TGUID = '{427BC359-518A-491B-85C5-FAE964E0D226}';

//  MAIN_Application: TGUID = '{BE758C62-E084-4D86-881F-74DC0C3266F6}';
//    FORM_Exceptions: TGUID = '{2D41A3B8-CE94-4EF2-BDDE-404D3AD9666A}';
//    FORM_io: TGUID = '{34F434AA-A323-49CC-952D-1091F44E9C59}';
//
//  PLUGIN_3DMDH3: TGUID = '{179D6E7F-2ED9-4F73-9211-A94B2B89B902}';
//    FORM_3DMDH3_Dialog: TGUID = '{311B8467-3F81-4356-AF2E-DC6BDD97B4C2}';
//
//  PLUGIN_BootLoader: TGUID = '{F716ACEF-8838-4D2E-A4D1-A89C32B2753D}';
//    FORM_BootLoader: TGUID = '{34EB2CA9-5C14-4CED-9A76-29D117F21503}';
//
//  PLUGIN_VclForms: TGUID = '{15F49170-511D-4611-90E5-21D434664289}';
//    FORM_Control: TGUID = '{54C53AFD-40EC-45F0-AE6A-4FF195EDBB53}';
//    FORM_Devices: TGUID = '{B18E36E2-D846-47CE-9776-BDF710E0489B}';
//    FORM_DevCollection: TGUID = '{C55DD572-D9C1-415E-94ED-383D9E341E13}';
//    FORM_Work: TGUID = '{B548104E-7D8A-4802-AA15-98B06D1C66D3}';
//    FORM_Graph: TGUID = '{2C4138F7-6859-49B2-96D2-B23884EFDCC8}';
//    FORM_Table: TGUID = '{6E1E2FC5-27F3-4AEA-A4DA-3A023C4B0EA0}';
//    FORM_RamRead: TGUID = '{E9CE84C6-D6F7-4B98-AC37-C5632B192627}';
//    FORM_RamShow: TGUID = '{D9849325-5BE2-4411-A129-C7988334A3D3}';
//    FORM_Hist_Table: TGUID = '{0A01F6D1-F6A5-4978-8BB8-9B717F952CD6}';
//    FORM_Hist_Graph: TGUID = '{F61E64C4-5980-413B-82A4-159B5CDD1F07}';
//    FORM_Hist_ArrayGraph: TGUID = '{DB2D47C5-B60A-4654-A7D3-DB4EBBBF751F}';

  PLUGIN_CreatePSK: TGUID = '{F5AD4766-598E-4241-B981-56FFF93A9426}';
    FORM_CreatePSK: TGUID = '{BC0CC1B7-7A01-4F52-9258-3A3E1FC79B17}';
  Dialog_SyncDelay_ICON = 217;
type
  Dialog_ComPortConnectIO = interface
  ['{9D5A0010-7D0F-4D07-A25C-89D3FBA01D36}']
  end;
  Dialog_NetPortConnectIO = interface
  ['{5C7BD7F3-60C4-40D1-9577-D0DA2A4E4BA2}']
  end;
  Dialog_CreateDevice = interface
  ['{22D6DE2E-F014-4E1A-8F9B-EC55B5D7FA7F}']
  end;
  Dialog_SetDeviceDelay = interface
  ['{7EE69A85-46DD-46AB-A0AD-13C8814AACAC}']
  end;
  Dialog_SyncDelay = interface
  ['{41E18551-0A5D-4A39-85DF-30275421FA67}']
  end;
  Dialog_RamRead = interface
  ['{B24C949D-2774-4A98-8077-A26CCC7B722A}']
  end;
  Dialog_Eep = interface
  ['{F41B3170-69F2-423D-91E8-D06FA0192529}']
  end;
  Dialog_ClcWrite = interface
  ['{FF7A4140-4795-43C5-A90F-183AA1F70B09}']
  end;
  Dialog_SetupProject = interface
  ['{03E77FD4-62AD-4821-BA63-C5BAB425F9FA}']
  end;
  Dialog_FilterParameters = interface
  ['{60E097B8-3650-44C1-BA5F-13B5AC340262}']
  end;
  Dialog_SelectViewParameters = interface
  ['{E4C9431F-A46C-4206-893F-46455EF6ADFE}']
  end;
  Dialog_EditViewParameters = interface
  ['{94008161-8717-4C14-862D-1271DE6FDB6C}']
  end;
  Dialog_EditArrayParameters = interface
  ['{5C798048-DA44-4988-B467-198968FF07CC}']
  end;
  Dialog_AddParameters = interface
  ['{B42F5BE0-78B6-47DB-9190-63E69AC12516}']
  end;
  Dialog_GlubionmerTRR = interface
  ['{FE2AECD1-5510-4CC5-B5E2-3B1899D738E1}']
  end;
  Dialog_SetupConnectIO = interface
  ['{7B0A13DE-B657-40A5-8FBA-202E32C72B37}']
  end;
  Dialog_SetupDevice = interface
  ['{386C290A-C13C-4D4D-A71C-675DA363DA10}']
  end;
  Dialog_SetupRootDevice = interface
  ['{3937B0BF-C38B-4EDD-8448-FCE62D8C7CAC}']
  end;
  Dialog_SetupOptions = interface
  ['{7C787021-291B-4ADE-B7AF-18335E46BC89}']
  end;
  Dialog_OpenLAS = interface
  ['{79669877-1863-41A7-837C-CAAF41FC00D2}']
  end;
  Dialog_Export = interface
  ['{419B512F-A0EA-4D08-ABFA-43A032539F3C}']
  end;
  Dialog_Export_Caliper = interface
  ['{CE0DE5D0-56BC-4285-93DF-445AFC7EAAF0}']
  end;
  Dialog_Error = interface
  ['{679FB10F-DD4B-44CB-BAF7-8AC674BE9B04}']
  end;
  Dialog_Text_Init = interface
  ['{79A4F32B-67FE-4A19-A591-802E9AD0369D}']
  end;
  Dialog_MultiProfile = interface
  ['{D5EE74FD-98BF-4B54-B0D7-01B5BB1F6A52}']
  end;
  Dialog_Logg = interface
  ['{A7D8406D-849C-42B1-A690-8534C20EAECA}']
  end;


//  DIALOG_SETUP_ComPortConnectIO: TGUID = '{96F45FBD-735E-4350-823A-77DA84785BF0}';
//  DIALOG_SETUP_NetConnectIO: TGUID     = '{BC171C83-9C49-42A0-B6BC-ED2079BE4742}';
//  DIALOG_CREATE_Device: TGUID          = '{263F6ED8-2507-4B20-BEDA-4CA090CF2AD1}';
//  DIALOG_SetDevCollection: TGUID       = '{E3717067-3331-4DB6-890E-4B03FAB3B9E2}';
//  DIALOG_SetDeviceDelay: TGUID         = '{55DD27B7-4C91-4044-99FC-C030E7A7266F}';
//  DIALOG_CREATE_RamRead: TGUID         = '{6137420A-BE9E-4DCD-BECD-F95F1C30F8F8}';
//  DIALOG_PARAM_Project: TGUID          = '{00CEF449-A91C-4545-A463-39AEFC057C25}';
//  DIALOG_PARAM_Show: TGUID          = '{23BDC6BF-36F1-43C7-849B-F9DB46CB4812}';
//  DIALOG_PARAM_Select: TGUID          = '{E3865208-F575-4C49-BC98-D1328024BFB8}';
//  DIALOG_PARAM_Edit: TGUID          = '{7476848A-5018-4388-9FBD-140599CD5BCA}';


implementation

end.



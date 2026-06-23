object FormMeta: TFormMeta
  Left = 0
  Top = 0
  Caption = #1043#1077#1085#1077#1088#1072#1090#1086#1088' '#1084#1077#1090#1072#1076#1072#1085#1085#1099#1093
  ClientHeight = 661
  ClientWidth = 1090
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  OldCreateOrder = False
  OnCreate = FormCreate
  PixelsPerInch = 96
  TextHeight = 13
  object Splitter: TSplitter
    Left = 513
    Top = 0
    Width = 5
    Height = 661
    Color = clMoneyGreen
    ParentColor = False
    ExplicitLeft = -2
  end
  object mIn: TMemo
    Left = 0
    Top = 0
    Width = 513
    Height = 661
    TabStop = False
    Align = alLeft
    Font.Charset = RUSSIAN_CHARSET
    Font.Color = clWindowText
    Font.Height = -13
    Font.Name = 'Courier New'
    Font.Style = []
    ParentFont = False
    PopupMenu = ppM
    ScrollBars = ssVertical
    TabOrder = 1
  end
  object mOut: TMemo
    Left = 518
    Top = 0
    Width = 572
    Height = 661
    TabStop = False
    Align = alClient
    Font.Charset = RUSSIAN_CHARSET
    Font.Color = clBlue
    Font.Height = -13
    Font.Name = 'Courier New'
    Font.Style = []
    ParentFont = False
    ScrollBars = ssVertical
    TabOrder = 0
  end
  object FormStorage: TJvFormStorage
    AppStorage = FileStorage
    AppStoragePath = '%FORM_NAME%\'
    StoredProps.Strings = (
      'mIn.Lines'
      'mIn.Height'
      'mOut.Height'
      'mOut.Lines')
    StoredValues = <>
    Left = 152
    Top = 48
  end
  object FileStorage: TJvAppIniFileStorage
    StorageOptions.BooleanStringTrueValues = 'TRUE, YES, Y'
    StorageOptions.BooleanStringFalseValues = 'FALSE, NO, N'
    FileName = 'setup.ini'
    SubStorages = <>
    Left = 72
    Top = 48
  end
  object ppM: TPopupMenu
    Left = 216
    Top = 48
    object NCompile: TMenuItem
      Caption = 'Compile'
      OnClick = NCompileClick
    end
  end
end

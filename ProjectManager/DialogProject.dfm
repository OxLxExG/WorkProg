object FormProject: TFormProject
  Left = 0
  Top = 0
  Caption = #1057#1074#1086#1081#1089#1090#1074#1072' '#1087#1088#1086#1077#1082#1090#1072
  ClientHeight = 289
  ClientWidth = 554
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  OldCreateOrder = False
  PixelsPerInch = 96
  TextHeight = 13
  object btClose: TButton
    Left = 19
    Top = 248
    Width = 89
    Height = 24
    Cancel = True
    Caption = #1047#1072#1082#1088#1099#1090#1100' '#1086#1082#1085#1086
    TabOrder = 0
    OnClick = btCloseClick
  end
  object SQLConnection: TSQLConnection
    ConnectionName = 'SQLITECONNECTION'
    DriverName = 'Sqlite'
    LoginPrompt = False
    Params.Strings = (
      'DriverName=Sqlite'
      'Database=test.db')
    Left = 48
    Top = 24
  end
  object SQLMonitor1: TSQLMonitor
    SQLConnection = SQLConnection
    Left = 48
    Top = 80
  end
end

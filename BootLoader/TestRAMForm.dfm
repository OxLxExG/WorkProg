object FormRamTest: TFormRamTest
  Left = 0
  Top = 0
  Caption = #1055#1088#1086#1074#1077#1088#1082#1072' '#1087#1072#1084#1103#1090#1080
  ClientHeight = 495
  ClientWidth = 584
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  TextHeight = 13
  object sb: TStatusBar
    Left = 0
    Top = 476
    Width = 584
    Height = 19
    Panels = <
      item
        Width = 600
      end>
  end
  object Memo: TMemo
    Left = 121
    Top = 0
    Width = 463
    Height = 476
    Align = alClient
    Font.Charset = RUSSIAN_CHARSET
    Font.Color = clWindowText
    Font.Height = -11
    Font.Name = 'Courier'
    Font.Style = []
    ParentFont = False
    ReadOnly = True
    TabOrder = 1
  end
  object Panel1: TPanel
    Left = 0
    Top = 0
    Width = 121
    Height = 476
    Align = alLeft
    TabOrder = 2
    object Label1: TLabel
      Left = 10
      Top = 0
      Width = 59
      Height = 30
      AutoSize = False
      Caption = #1072#1076#1088#1077#1089' '#1091#1089#1090#1088#1086#1081#1089#1090#1074#1072
      WordWrap = True
    end
    object Label2: TLabel
      Left = 10
      Top = 36
      Width = 84
      Height = 13
      Caption = #1089#1090#1088#1072#1085#1080#1094#1072' '#1079#1072#1087#1080#1089#1080
      WordWrap = True
    end
    object lbBaseW: TLabel
      Left = 90
      Top = 72
      Width = 6
      Height = 13
      Caption = '0'
    end
    object Label3: TLabel
      Left = 8
      Top = 230
      Width = 52
      Height = 13
      Caption = #1072#1076#1088#1077#1089' HEX'
    end
    object Label4: TLabel
      Left = 6
      Top = 335
      Width = 52
      Height = 13
      Caption = #1072#1076#1088#1077#1089' HEX'
    end
    object Label5: TLabel
      Left = 68
      Top = 231
      Width = 39
      Height = 26
      Caption = #1076#1083#1080#1085#1072' DWORD'
      WordWrap = True
    end
    object Label6: TLabel
      Left = 64
      Top = 322
      Width = 39
      Height = 26
      Caption = #1076#1083#1080#1085#1072' DWORD'
      WordWrap = True
    end
    object AdrHex: TLabel
      Left = 10
      Top = 52
      Width = 6
      Height = 13
      Caption = '0'
    end
    object edADR: TEdit
      Left = 87
      Top = 2
      Width = 29
      Height = 21
      TabOrder = 0
      Text = '6'
    end
    object edPageW: TEdit
      Left = 48
      Top = 69
      Width = 41
      Height = 21
      TabOrder = 1
      Text = '0'
    end
    object btSetBase: TButton
      Left = 6
      Top = 67
      Width = 23
      Height = 25
      Caption = 'Set'
      TabOrder = 2
      OnClick = btSetBaseClick
    end
    object btRead: TButton
      Left = 5
      Top = 138
      Width = 110
      Height = 25
      Caption = #1095#1080#1090#1072#1090#1100' '#1087#1072#1084#1103#1090#1100
      TabOrder = 3
      Visible = False
      OnClick = btReadClick
    end
    object btWrite: TButton
      Left = 6
      Top = 96
      Width = 110
      Height = 25
      Caption = #1079#1072#1087#1080#1089#1100' '#1074' '#1087#1072#1084#1103#1090#1100
      TabOrder = 4
      OnClick = btWriteClick
    end
    object edBaseR: TEdit
      Left = 80
      Top = 127
      Width = 34
      Height = 21
      TabOrder = 5
      Text = '0'
    end
    object edPageR: TEdit
      Left = 39
      Top = 127
      Width = 41
      Height = 21
      TabOrder = 6
      Text = '0'
    end
    object btClear: TButton
      Left = 6
      Top = 169
      Width = 109
      Height = 25
      Caption = #1054#1095#1080#1089#1090#1080#1090#1100' memo'
      TabOrder = 7
      OnClick = btClearClick
    end
    object edArdesWrite: TEdit
      Left = 5
      Top = 261
      Width = 53
      Height = 21
      TabOrder = 8
      Text = '0'
    end
    object btWriteRam: TButton
      Left = 5
      Top = 288
      Width = 110
      Height = 25
      Caption = #1079#1072#1087#1080#1089#1100' '#1074' '#1087#1072#1084#1103#1090#1100
      TabOrder = 9
      OnClick = btWriteRamClick
    end
    object edAdresRead: TEdit
      Left = 6
      Top = 351
      Width = 52
      Height = 21
      TabOrder = 10
      Text = '0'
    end
    object btReadRam: TButton
      Left = 5
      Top = 378
      Width = 110
      Height = 25
      Caption = #1095#1080#1090#1072#1090#1100' '#1087#1072#1084#1103#1090#1100
      TabOrder = 11
      OnClick = btReadRamClick
    end
    object btLenRead: TEdit
      Left = 62
      Top = 351
      Width = 53
      Height = 21
      TabOrder = 12
      Text = '8'
    end
    object btReadBads: TButton
      Left = 5
      Top = 409
      Width = 110
      Height = 25
      Caption = #1095#1080#1090#1072#1090#1100' BAD'
      TabOrder = 13
      OnClick = btReadBadsClick
    end
    object edChip: TEdit
      Left = 31
      Top = 69
      Width = 19
      Height = 21
      TabOrder = 14
      Text = '0'
      Visible = False
    end
    object SetMX: TButton
      Left = 5
      Top = 244
      Width = 36
      Height = 17
      Caption = 'SetMX'
      TabOrder = 15
      OnClick = SetMXClick
    end
    object btFormat: TButton
      Left = 5
      Top = 440
      Width = 110
      Height = 25
      Caption = 'FRAM FORMAT'
      TabOrder = 16
      OnClick = btFormatClick
    end
  end
  object elLenWrite: TEdit
    Left = 62
    Top = 261
    Width = 53
    Height = 21
    TabOrder = 3
    Text = '0'
  end
end

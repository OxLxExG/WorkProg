object FormBoot: TFormBoot
  Left = 0
  Top = 0
  Caption = #1047#1072#1075#1088#1091#1079#1095#1080#1082' '#1055#1088#1086#1075#1088#1072#1084#1084#1099
  ClientHeight = 540
  ClientWidth = 633
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  TextHeight = 13
  object Panel: TPanel
    Left = 0
    Top = 0
    Width = 123
    Height = 521
    Align = alLeft
    BevelOuter = bvNone
    Caption = 'Panel'
    ShowCaption = False
    TabOrder = 0
    object btRead: TButton
      Left = 8
      Top = 163
      Width = 99
      Height = 25
      Caption = ' '#1052'.'#1076#1072#1085'. '#1091#1089#1090#1088#1086#1081#1089#1090'.'
      TabOrder = 4
      OnClick = btReadClick
    end
    object btStop: TButton
      Left = 8
      Top = 225
      Width = 99
      Height = 25
      Caption = #1055#1088#1077#1088#1074#1072#1090#1100
      TabOrder = 6
      OnClick = btStopClick
    end
    object btFile: TButton
      Left = 8
      Top = 12
      Width = 99
      Height = 25
      Caption = #1054#1090#1082#1088#1099#1090#1100' '#1060#1072#1081#1083'...'
      TabOrder = 0
      OnClick = btFileClick
    end
    object btOut: TButton
      Left = 8
      Top = 132
      Width = 99
      Height = 25
      Caption = #1042#1099#1093#1086#1076' '#1080#1079' '#1079#1072#1075#1088#1091#1079#1095'.'
      TabOrder = 3
      OnClick = btOutClick
    end
    object btLoad: TButton
      Left = 8
      Top = 194
      Width = 99
      Height = 25
      Caption = #1047#1072#1075#1088#1091#1079#1082#1072
      TabOrder = 5
      OnClick = btLoadClick
    end
    object btIn: TButton
      Left = 8
      Top = 101
      Width = 99
      Height = 25
      Caption = #1042#1093#1086#1076' '#1074' '#1079#1072#1075#1088#1091#1079#1095#1080#1082
      TabOrder = 2
      OnClick = btInClick
    end
    object btHandle: TButton
      Left = 8
      Top = 43
      Width = 99
      Height = 25
      Caption = #1059#1089#1090'.'#1074#1088#1091#1095#1085#1091#1102'...'
      TabOrder = 1
      OnClick = btHandleClick
    end
  end
  object Memo: TMemo
    Left = 123
    Top = 0
    Width = 510
    Height = 521
    TabStop = False
    Align = alClient
    BevelInner = bvNone
    BevelOuter = bvNone
    BorderStyle = bsNone
    Font.Charset = RUSSIAN_CHARSET
    Font.Color = clWindowText
    Font.Height = -13
    Font.Name = 'Courier New'
    Font.Style = []
    ParentFont = False
    ScrollBars = ssVertical
    TabOrder = 2
  end
  object sb: TStatusBar
    Left = 0
    Top = 521
    Width = 633
    Height = 19
    Panels = <
      item
        Width = 100
      end
      item
        Width = 100
      end
      item
        Width = 100
      end
      item
        Width = 100
      end
      item
        Width = 50
      end>
  end
  object od: TOpenDialog
    Filter = #1073#1080#1085#1072#1088#1085#1099#1081' '#1092#1072#1081#1083' (.bin)|*.bin'
    Left = 208
    Top = 16
  end
end

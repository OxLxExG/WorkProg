object FormExportToPSK6: TFormExportToPSK6
  Left = 0
  Top = 0
  BorderStyle = bsSizeToolWin
  Caption = #1101#1082#1089#1087#1086#1088#1090' '#1074' '#1055#1057#1050'6'
  ClientHeight = 154
  ClientWidth = 292
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  OldCreateOrder = False
  Position = poMainFormCenter
  OnCreate = FormCreate
  DesignSize = (
    292
    154)
  PixelsPerInch = 96
  TextHeight = 13
  object Label1: TLabel
    Left = 8
    Top = 8
    Width = 41
    Height = 13
    Caption = #1057' '#1082#1072#1076#1088#1072
  end
  object Label2: TLabel
    Left = 161
    Top = 8
    Width = 41
    Height = 13
    Caption = #1055#1086' '#1082#1072#1076#1088
  end
  object edFrom: TEdit
    Left = 8
    Top = 24
    Width = 121
    Height = 21
    TabOrder = 0
    Text = '0'
  end
  object edTo: TEdit
    Left = 161
    Top = 24
    Width = 121
    Height = 21
    TabOrder = 1
    Text = '0'
  end
  object od: TJvFilenameEdit
    Left = 8
    Top = 51
    Width = 274
    Height = 21
    DialogKind = dkSave
    DefaultExt = 'if'
    Filter = #1041#1080#1085#1072#1088#1085#1099#1081' '#1092#1072#1081#1083' (*.if)|*.if'
    DialogOptions = [ofOverwritePrompt, ofHideReadOnly, ofPathMustExist]
    DirectInput = False
    Anchors = [akLeft, akTop, akRight]
    TabOrder = 2
    Text = ''
  end
  object sb: TStatusBar
    Left = 0
    Top = 135
    Width = 292
    Height = 19
    Panels = <
      item
        Width = 50
      end>
  end
  object btStart: TButton
    Left = 8
    Top = 101
    Width = 75
    Height = 25
    Caption = #1057#1090#1072#1088#1090
    TabOrder = 4
    OnClick = btStartClick
  end
  object btTerminate: TButton
    Left = 89
    Top = 101
    Width = 75
    Height = 25
    Caption = #1055#1088#1077#1088#1074#1072#1090#1100
    TabOrder = 5
    OnClick = btTerminateClick
  end
  object btExit: TButton
    Left = 207
    Top = 101
    Width = 75
    Height = 25
    Caption = #1042#1099#1093#1086#1076
    ModalResult = 1
    TabOrder = 6
    OnClick = btExitClick
  end
  object Progress: TProgressBar
    Left = 8
    Top = 78
    Width = 274
    Height = 17
    Anchors = [akLeft, akTop, akRight]
    TabOrder = 7
  end
end

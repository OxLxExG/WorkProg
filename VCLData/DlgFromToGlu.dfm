object FormDlgGluFilter: TFormDlgGluFilter
  Left = 0
  Top = 0
  BorderStyle = bsDialog
  Caption = #1060#1080#1083#1100#1090#1088' '#1087#1086' '#1075#1083#1091#1073#1080#1085#1077
  ClientHeight = 144
  ClientWidth = 480
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  TextHeight = 13
  object lbWork: TLabel
    Left = 26
    Top = 17
    Width = 189
    Height = 26
    AutoSize = False
    Caption = #1057' '#1082#1072#1076#1088#1072#13#10'(0-'#1085#1077' '#1091#1089#1090#1072#1085#1086#1074#1083#1077#1085')'
    WordWrap = True
  end
  object Label1: TLabel
    Left = 266
    Top = 17
    Width = 189
    Height = 26
    AutoSize = False
    Caption = #1055#1086' '#1082#1072#1076#1088#13#10'(0-'#1085#1077' '#1091#1089#1090#1072#1085#1086#1074#1083#1077#1085')'
    WordWrap = True
  end
  object medFrom: TMaskEdit
    Left = 26
    Top = 49
    Width = 187
    Height = 24
    EditMask = '!99999;1;_'
    Font.Charset = RUSSIAN_CHARSET
    Font.Color = clBlue
    Font.Height = -16
    Font.Name = 'Courier'
    Font.Style = []
    MaxLength = 5
    ParentFont = False
    TabOrder = 0
    Text = '     '
  end
  object medTo: TMaskEdit
    Left = 266
    Top = 49
    Width = 187
    Height = 24
    EditMask = '!99999;1;_'
    Font.Charset = RUSSIAN_CHARSET
    Font.Color = clBlue
    Font.Height = -16
    Font.Name = 'Courier'
    Font.Style = []
    MaxLength = 5
    ParentFont = False
    TabOrder = 1
    Text = '     '
  end
  object btApply: TButton
    Left = 26
    Top = 96
    Width = 111
    Height = 25
    Caption = #1055#1088#1080#1084#1077#1085#1080#1090#1100
    TabOrder = 2
    OnClick = btApplyClick
  end
  object btClose: TButton
    Left = 266
    Top = 96
    Width = 111
    Height = 25
    Caption = #1042#1099#1093#1086#1076
    ModalResult = 8
    TabOrder = 3
  end
end

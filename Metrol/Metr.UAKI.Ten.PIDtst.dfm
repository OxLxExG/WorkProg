object FormPIDsetup: TFormPIDsetup
  Left = 0
  Top = 0
  Caption = #1085#1072#1089#1090#1088#1086#1081#1082#1072' '#1090#1077#1088#1084#1086#1089#1090#1072#1090#1072' '#1059#1040#1050'-'#1057#1048
  ClientHeight = 577
  ClientWidth = 824
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -12
  Font.Name = 'Segoe UI'
  Font.Style = []
  OnDestroy = FormDestroy
  TextHeight = 15
  object Panel1: TPanel
    Left = 0
    Top = 0
    Width = 824
    Height = 105
    Align = alTop
    Caption = 'Panel1'
    ShowCaption = False
    TabOrder = 0
    object lbTincl: TLabel
      Left = 431
      Top = 80
      Width = 50
      Height = 16
      AutoSize = False
      Caption = '11212 '
      Color = clWhite
      Font.Charset = RUSSIAN_CHARSET
      Font.Color = clMaroon
      Font.Height = -12
      Font.Name = 'Courier New'
      Font.Style = [fsBold]
      ParentColor = False
      ParentFont = False
      Transparent = False
    end
    object lbT: TLabel
      Left = 247
      Top = 80
      Width = 170
      Height = 16
      AutoSize = False
      Caption = '11212   12312312  123213'
      Color = clWhite
      Font.Charset = RUSSIAN_CHARSET
      Font.Color = clRed
      Font.Height = -12
      Font.Name = 'Courier New'
      Font.Style = [fsBold]
      ParentColor = False
      ParentFont = False
      Transparent = False
    end
    object Label6: TLabel
      Left = 247
      Top = 59
      Width = 119
      Height = 15
      Caption = #1044#1072#1085#1085#1099#1077' '#1090#1077#1084#1087#1077#1088#1072#1090#1091#1088#1099
    end
    object Label5: TLabel
      Left = 8
      Top = 59
      Width = 77
      Height = 15
      Caption = #1044#1072#1085#1085#1099#1077' '#1090#1077#1085#1086#1074
    end
    object lbPower: TLabel
      Left = 8
      Top = 80
      Width = 222
      Height = 16
      AutoSize = False
      Caption = '11212   12312312  123213'
      Color = clWhite
      Font.Charset = RUSSIAN_CHARSET
      Font.Color = clBlue
      Font.Height = -12
      Font.Name = 'Courier New'
      Font.Style = [fsBold]
      ParentColor = False
      ParentFont = False
      Transparent = False
    end
    object Label3: TLabel
      Left = 166
      Top = 8
      Width = 73
      Height = 15
      Caption = #1060#1072#1081#1083' '#1076#1072#1085#1085#1099#1093
    end
    object Label2: TLabel
      Left = 39
      Top = 4
      Width = 96
      Height = 15
      Caption = #1048#1085#1090#1077#1088#1074#1072#1083' '#1086#1087#1088#1086#1089#1072
    end
    object Label1: TLabel
      Left = 8
      Top = 6
      Width = 13
      Height = 15
      Caption = 'dT'
    end
    object Label4: TLabel
      Left = 581
      Top = 4
      Width = 14
      Height = 15
      Caption = 'Kp'
    end
    object Label7: TLabel
      Left = 639
      Top = 4
      Width = 10
      Height = 15
      Caption = 'Ki'
    end
    object Label8: TLabel
      Left = 697
      Top = 4
      Width = 14
      Height = 15
      Caption = 'Kd'
    end
    object edInt: TEdit
      Left = 39
      Top = 27
      Width = 121
      Height = 23
      TabOrder = 0
      Text = '1000'
    end
    object edT: TEdit
      Left = 8
      Top = 27
      Width = 25
      Height = 23
      TabOrder = 1
      Text = '5'
    end
    object btStart: TButton
      Left = 500
      Top = 71
      Width = 75
      Height = 25
      Caption = #1089#1090#1072#1088#1090
      TabOrder = 2
      OnClick = btStartClick
    end
    object edKp: TEdit
      Left = 581
      Top = 25
      Width = 52
      Height = 23
      TabOrder = 3
      Text = '1'
    end
    object edKi: TEdit
      Left = 639
      Top = 25
      Width = 52
      Height = 23
      TabOrder = 4
      Text = '0'
    end
    object edKd: TEdit
      Left = 697
      Top = 25
      Width = 52
      Height = 23
      TabOrder = 5
      Text = '0'
    end
  end
end

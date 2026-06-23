object FormInclSetup: TFormInclSetup
  Left = 0
  Top = 0
  BorderStyle = bsDialog
  Caption = #1058#1072#1088#1080#1088#1086#1074#1082#1072' '#1080#1085#1082#1083#1080#1085#1086#1084#1077#1090#1088#1072' - '#1091#1089#1090#1072#1085#1086#1074#1082#1080' '
  ClientHeight = 149
  ClientWidth = 477
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  OldCreateOrder = False
  Position = poMainFormCenter
  PixelsPerInch = 96
  TextHeight = 13
  object Label1: TLabel
    Left = 16
    Top = 7
    Width = 164
    Height = 13
    Caption = #1092#1086#1088#1084#1072#1090#1080#1088#1086#1074#1072#1085#1080#1077' '#1076#1072#1085#1085#1099#1093' '#1096#1072#1075#1086#1074' '
  end
  object Label2: TLabel
    Left = 16
    Top = 56
    Width = 96
    Height = 13
    Caption = #1092#1086#1088#1084#1072#1090#1080#1088#1086#1074#1072#1085#1080#1077' D'
  end
  object Label3: TLabel
    Left = 160
    Top = 56
    Width = 143
    Height = 13
    Caption = #1092#1086#1088#1084#1072#1090#1080#1088#1086#1074#1072#1085#1080#1077' '#1076#1080#1072#1075#1086#1085#1072#1083#1080
  end
  object Label4: TLabel
    Left = 320
    Top = 56
    Width = 144
    Height = 13
    Caption = #1092#1086#1088#1084#1072#1090#1080#1088#1086#1074#1072#1085#1080#1077' '#1086#1089#1090#1072#1083#1100#1085#1099#1077
  end
  object btOk: TButton
    Left = 144
    Top = 116
    Width = 75
    Height = 25
    Caption = 'Ok'
    ModalResult = 1
    TabOrder = 0
  end
  object btCansel: TButton
    Left = 240
    Top = 116
    Width = 75
    Height = 25
    Caption = #1054#1090#1084#1077#1085#1072
    ModalResult = 2
    TabOrder = 1
  end
  object edData: TEdit
    Left = 16
    Top = 23
    Width = 121
    Height = 21
    TabOrder = 2
    Text = '%1.0f'
  end
  object edD: TEdit
    Left = 16
    Top = 72
    Width = 121
    Height = 21
    TabOrder = 3
    Text = '%1.1f'
  end
  object edNN: TEdit
    Left = 160
    Top = 72
    Width = 121
    Height = 21
    TabOrder = 4
    Text = '%1.3f'
  end
  object edAver: TEdit
    Left = 320
    Top = 72
    Width = 121
    Height = 21
    TabOrder = 5
    Text = '%1.3f'
  end
end

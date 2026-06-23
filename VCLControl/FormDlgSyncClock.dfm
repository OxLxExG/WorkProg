object DialogSyncDelay: TDialogSyncDelay
  Left = 0
  Top = 0
  Caption = 'SyncDelay'
  ClientHeight = 289
  ClientWidth = 510
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  OldCreateOrder = False
  Position = poDesktopCenter
  PixelsPerInch = 96
  TextHeight = 13
  object pnShow: TPanel
    Left = 0
    Top = 235
    Width = 510
    Height = 54
    Align = alBottom
    Caption = 'pnShow'
    ShowCaption = False
    TabOrder = 0
    object btClose: TButton
      Left = 326
      Top = 14
      Width = 89
      Height = 27
      Cancel = True
      Caption = #1047#1072#1082#1088#1099#1090#1100' '#1086#1082#1085#1086
      TabOrder = 0
      OnClick = btCloseClick
    end
    object btCorrect: TButton
      Left = 80
      Top = 14
      Width = 190
      Height = 27
      HelpType = htKeyword
      HelpKeyword = 'BUTTONHELP'
      Cancel = True
      Caption = #1057#1080#1085#1093#1088#1086#1085#1080#1079#1080#1088#1086#1074#1072#1090#1100' '#1095#1072#1089#1099
      Enabled = False
      TabOrder = 1
      OnClick = btCorrectClick
    end
  end
  object Tree: TVirtualStringTree
    Left = 0
    Top = 0
    Width = 510
    Height = 235
    Align = alClient
    Header.AutoSizeIndex = 5
    Header.Font.Charset = DEFAULT_CHARSET
    Header.Font.Color = clWindowText
    Header.Font.Height = -11
    Header.Font.Name = 'Tahoma'
    Header.Font.Style = []
    Header.Options = [hoAutoResize, hoColumnResize, hoDblClickResize, hoDrag, hoShowImages, hoShowSortGlyphs, hoVisible]
    TabOrder = 1
    TreeOptions.MiscOptions = [toAcceptOLEDrop, toCheckSupport, toFullRepaintOnResize, toInitOnSave, toToggleOnDblClick, toWheelPanning, toEditOnClick]
    TreeOptions.PaintOptions = [toShowButtons, toShowDropmark, toShowHorzGridLines, toShowRoot, toShowTreeLines, toShowVertGridLines, toThemeAware, toUseBlendedImages]
    OnGetText = TreeGetText
    OnGetNodeDataSize = TreeGetNodeDataSize
    Columns = <
      item
        Position = 0
        Width = 100
        WideText = #1048#1084#1103
      end
      item
        Position = 1
        Width = 90
        WideText = #1042#1088#1077#1084#1103' '#1084#1086#1076#1091#1083#1103
      end
      item
        Position = 2
        Width = 80
        WideText = #1042#1088#1077#1084#1103' '#1055#1050
      end
      item
        Position = 3
        Width = 60
        WideText = #1086#1096#1080#1073#1082#1072' '#1082#1072#1076#1088#1086#1074
      end
      item
        Position = 4
        Width = 90
        WideText = #1050#1086#1101#1092#1092'.'#1090#1077#1082#1091#1097#1080#1081
      end
      item
        Position = 5
        Width = 90
        WideText = #1050#1086#1101#1092#1092'.'#1089#1086#1093#1088#1072#1085#1077#1085#1085#1099#1081
      end>
  end
end

object FormDlgEeprom: TFormDlgEeprom
  Left = 0
  Top = 0
  Caption = 'FormDlgEeprom'
  ClientHeight = 579
  ClientWidth = 551
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  Position = poMainFormCenter
  TextHeight = 13
  object Tree: TVirtualStringTree
    Left = 0
    Top = 0
    Width = 551
    Height = 519
    Align = alClient
    DefaultNodeHeight = 17
    Header.AutoSizeIndex = 0
    Header.Height = 17
    Header.Options = [hoColumnResize, hoDrag, hoShowSortGlyphs, hoVisible]
    PopupMenu = ppm
    TabOrder = 1
    TreeOptions.MiscOptions = [toAcceptOLEDrop, toEditable, toFullRepaintOnResize, toInitOnSave, toToggleOnDblClick, toWheelPanning, toEditOnClick]
    TreeOptions.PaintOptions = [toHotTrack, toShowButtons, toShowDropmark, toShowHorzGridLines, toShowRoot, toShowTreeLines, toShowVertGridLines, toThemeAware, toUseBlendedImages, toFullVertGridLines]
    TreeOptions.SelectionOptions = [toExtendedFocus]
    TreeOptions.StringOptions = []
    OnCreateEditor = TreeCreateEditor
    OnEditing = TreeEditing
    OnGetText = TreeGetText
    OnPaintText = TreePaintText
    OnGetNodeDataSize = TreeGetNodeDataSize
    Touch.InteractiveGestures = [igPan, igPressAndTap]
    Touch.InteractiveGestureOptions = [igoPanSingleFingerHorizontal, igoPanSingleFingerVertical, igoPanInertia, igoPanGutter, igoParentPassthrough]
    Columns = <
      item
        Options = [coEnabled, coParentBidiMode, coParentColor, coResizable, coShowDropMark, coVisible, coAllowFocus, coStyleColor]
        Position = 0
        Text = #1055#1072#1088#1072#1084#1077#1090#1088#1099' '
        Width = 180
      end
      item
        Options = [coDraggable, coEnabled, coParentBidiMode, coParentColor, coResizable, coShowDropMark, coVisible, coAllowFocus, coStyleColor]
        Position = 1
        Text = 'EEPROM'
        Width = 100
      end
      item
        Position = 2
        Text = #1056#1072#1089#1095#1077#1090#1085#1099#1077
        Width = 68
      end
      item
        Options = [coDraggable, coEnabled, coParentBidiMode, coParentColor, coResizable, coShowDropMark, coVisible, coAutoSpring, coSmartResize, coAllowFocus, coStyleColor]
        Position = 3
        Text = #1052#1077#1090#1088#1086#1083#1086#1075#1080#1103
        Width = 71
      end
      item
        Options = [coDraggable, coEnabled, coParentBidiMode, coParentColor, coResizable, coShowDropMark, coVisible, coAllowFocus, coStyleColor]
        Position = 4
        Text = #1077#1076#1080#1085#1080#1094#1099
      end>
  end
  object st: TStatusBar
    Left = 0
    Top = 560
    Width = 551
    Height = 19
    Panels = <
      item
        Width = 100
      end
      item
        Width = 50
      end>
  end
  object Panel1: TPanel
    Left = 0
    Top = 519
    Width = 551
    Height = 41
    Align = alBottom
    Caption = 'Panel1'
    ShowCaption = False
    TabOrder = 2
    DesignSize = (
      551
      41)
    object btExit: TButton
      Left = 272
      Top = 10
      Width = 75
      Height = 25
      Anchors = [akLeft, akBottom]
      Caption = #1042#1099#1093#1086#1076
      ModalResult = 1
      TabOrder = 0
      OnClick = btExitClick
    end
    object btRead: TButton
      Left = 13
      Top = 10
      Width = 172
      Height = 25
      Anchors = [akLeft, akBottom]
      Caption = #1063#1080#1090#1072#1090#1100' '#1080' '#1089#1086#1093#1088#1072#1085#1080#1090#1100' '#1074' '#1092#1072#1081#1083#1099
      TabOrder = 1
      OnClick = btReadClick
    end
    object btWrite: TButton
      Left = 191
      Top = 10
      Width = 75
      Height = 25
      Anchors = [akLeft, akBottom]
      Caption = #1055#1080#1089#1072#1090#1100
      Enabled = False
      TabOrder = 2
      OnClick = btWriteClick
    end
  end
  object ppm: TPopupMenu
    OnPopup = ppmPopup
    Left = 248
    Top = 176
    object EEPROM1: TMenuItem
      Caption = #1047#1072#1087#1080#1089#1072#1090#1100' '#1057#1077#1082#1094#1080#1102' EEPROM'
      Enabled = False
      OnClick = EEPROM1Click
    end
    object File1: TMenuItem
      Caption = #1047#1072#1087#1080#1089#1072#1090#1100' '#1089#1077#1082#1094#1080#1102' '#1074' '#1092#1072#1081#1083'...'
      OnClick = File1Click
    end
    object Load1: TMenuItem
      Caption = #1047#1072#1075#1088#1091#1079#1080#1090#1100' '#1089#1077#1082#1094#1080#1102' '#1080#1079' '#1092#1072#1081#1083#1072'...'
      OnClick = Load1Click
    end
    object nPasw: TMenuItem
      Caption = #1042#1074#1077#1089#1090#1080' '#1087#1072#1088#1086#1083#1100' '#1089#1077#1082#1094#1080#1080'...'
      OnClick = nPaswClick
    end
  end
end

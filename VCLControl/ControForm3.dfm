object FormControl: TFormControl
  Left = 0
  Top = 0
  Caption = #1059#1087#1088#1072#1074#1083#1077#1085#1080#1077' '#1059#1089#1090#1088#1086#1081#1089#1090#1074#1072#1084#1080
  ClientHeight = 358
  ClientWidth = 608
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  TextHeight = 13
  object Tree: TVirtualStringTree
    Left = 0
    Top = 0
    Width = 608
    Height = 358
    Align = alClient
    Color = clBtnFace
    DefaultNodeHeight = 17
    Header.AutoSizeIndex = 0
    Header.Height = 17
    Header.Options = [hoColumnResize, hoDrag, hoShowSortGlyphs, hoVisible]
    PopupMenu = ppM
    TabOrder = 0
    TreeOptions.MiscOptions = [toAcceptOLEDrop, toEditable, toFullRepaintOnResize, toInitOnSave, toToggleOnDblClick, toWheelPanning, toEditOnClick]
    TreeOptions.PaintOptions = [toHotTrack, toShowButtons, toShowDropmark, toShowHorzGridLines, toShowRoot, toShowTreeLines, toShowVertGridLines, toThemeAware, toUseBlendedImages, toFullVertGridLines]
    TreeOptions.SelectionOptions = [toExtendedFocus]
    OnCreateEditor = TreeCreateEditor
    OnEditing = TreeEditing
    OnGetText = TreeGetText
    OnPaintText = TreePaintText
    OnGetImageIndex = TreeGetImageIndex
    Touch.InteractiveGestures = [igPan, igPressAndTap]
    Touch.InteractiveGestureOptions = [igoPanSingleFingerHorizontal, igoPanSingleFingerVertical, igoPanInertia, igoPanGutter, igoParentPassthrough]
    Columns = <
      item
        Position = 0
        Text = #1059#1089#1090#1088#1086#1081#1089#1090#1074#1086
        Width = 200
      end
      item
        Position = 1
        Text = #1057#1090#1072#1090#1091#1089
        Width = 200
      end
      item
        Position = 2
        Text = #1042#1088#1077#1084#1103
      end>
  end
  object ppM: TPopupActionBar
    OnPopup = ppMPopup
    Left = 104
    Top = 88
    object NSetup: TMenuItem
      Caption = #1057#1074#1086#1081#1089#1090#1074#1072'...'
      OnClick = NSetupClick
    end
    object NSepConn: TMenuItem
      Caption = '-'
    end
    object NAddDev: TMenuItem
      Caption = #1053#1086#1074#1086#1077' '#1091#1089#1090#1088#1086#1081#1089#1090#1074#1086
      OnClick = NAddDevClick
    end
    object N2: TMenuItem
      Caption = '-'
    end
    object NRemove: TMenuItem
      Caption = #1059#1076#1072#1083#1080#1090#1100
      OnClick = NRemoveClick
    end
    object NConnect: TMenuItem
      Caption = #1055#1086#1076#1082#1083#1102#1095#1080#1090#1100
    end
    object NControl: TMenuItem
      Caption = #1059#1087#1088#1072#1074#1083#1077#1085#1080#1077
    end
    object NSetupDev: TMenuItem
      Caption = #1057#1074#1086#1081#1089#1090#1074#1072'...'
      OnClick = NSetupDevClick
    end
    object N1: TMenuItem
      Caption = '-'
    end
    object NReadRam: TMenuItem
      Caption = #1063#1090#1077#1085#1080#1077' '#1087#1072#1084#1103#1090#1080' '#1084#1086#1076#1091#1083#1103'...'
      OnClick = NReadRamClick
    end
    object NClc: TMenuItem
      Caption = #1055#1077#1088#1077#1089#1095#1077#1090' '#1084#1077#1090#1088#1086#1083#1086#1075#1080#1080'  '#1084#1086#1076#1091#1083#1103'...'
      OnClick = NClcClick
    end
    object NInfo: TMenuItem
      Caption = #1056#1077#1078#1080#1084' '#1080#1085#1092#1086#1088#1084#1072#1094#1080#1080
    end
    object NRamSize: TMenuItem
      Caption = #1059#1089#1090#1072#1085#1086#1074#1082#1072' '#1084#1072#1082#1089#1080#1084#1072#1083#1100#1085#1086#1075#1086' '#1074#1088#1077#1084#1077#1085#1080' '#1088#1072#1073#1086#1090#1099' '#1074#1088#1091#1095#1085#1091#1102'('#1057#1091#1090')...'
      OnClick = NRamSizeClick
    end
    object NGlu: TMenuItem
      Caption = #1044#1072#1085#1085#1099#1077' '#1089' '#1087#1088#1080#1074#1103#1079#1082#1086#1081' '#1087#1086' '#1075#1083#1091#1073#1080#1085#1077
    end
    object NeepEdit: TMenuItem
      Caption = 'EEPROM '#1056#1077#1076#1072#1082#1090#1080#1088#1086#1074#1072#1090#1100'...'
      OnClick = NeepEditClick
    end
    object NeepCmp: TMenuItem
      Caption = 'EEPROM '#1057#1088#1072#1074#1085#1080#1090#1100' '#1089' '#1052#1077#1090#1088#1086#1083#1086#1075#1080#1077#1081'...'
      OnClick = NeepCmpClick
    end
    object NMetrolExport: TMenuItem
      Caption = #1052#1077#1090#1088#1086#1083#1086#1075#1080#1103' '#1058#1077#1089#1090'...'
      OnClick = NMetrolTestClick
    end
    object NMetrolImport: TMenuItem
      Caption = #1052#1077#1090#1088#1086#1083#1086#1075#1080#1103' '#1048#1084#1087#1086#1088#1090'...'
      OnClick = NMetrolImportClick
    end
    object NRep: TMenuItem
      Caption = #1055#1086#1082#1072#1079#1072#1090#1100' '#1086#1090#1095#1077#1090' '#1087#1086' '#1085#1072#1088#1072#1073#1086#1090#1082#1077'...'
      OnClick = NRepClick
    end
    object NSepDEv: TMenuItem
      Caption = '-'
    end
    object NUpdate: TMenuItem
      Caption = #1054#1073#1085#1086#1074#1080#1090#1100
      OnClick = NUpdateClick
    end
  end
end

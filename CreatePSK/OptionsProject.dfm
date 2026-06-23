object FormProjectOptions: TFormProjectOptions
  Left = 0
  Top = 0
  Caption = #1057#1074#1086#1081#1089#1090#1074#1072' '#1087#1088#1086#1077#1082#1090#1072
  ClientHeight = 129
  ClientWidth = 573
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
    Width = 573
    Height = 129
    Align = alClient
    BorderWidth = 1
    Header.AutoSizeIndex = 6
    Header.Height = 13
    Header.Options = [hoAutoResize, hoColumnResize, hoDrag, hoShowSortGlyphs, hoVisible, hoAutoSpring, hoHeaderClickAutoSort]
    PopupMenu = ppM
    TabOrder = 0
    TreeOptions.AutoOptions = [toAutoDropExpand, toAutoScrollOnExpand, toAutoSpanColumns, toAutoTristateTracking, toAutoHideButtons, toAutoDeleteMovedNodes]
    TreeOptions.MiscOptions = [toAcceptOLEDrop, toEditable, toFullRepaintOnResize, toGridExtensions, toInitOnSave, toToggleOnDblClick, toWheelPanning, toEditOnClick]
    TreeOptions.PaintOptions = [toShowButtons, toShowDropmark, toShowHorzGridLines, toShowRoot, toShowTreeLines, toShowVertGridLines, toThemeAware, toUseBlendedImages, toFullVertGridLines]
    TreeOptions.SelectionOptions = [toExtendedFocus, toMultiSelect]
    OnGetText = TreeGetText
    Touch.InteractiveGestures = [igPan, igPressAndTap]
    Touch.InteractiveGestureOptions = [igoPanSingleFingerHorizontal, igoPanSingleFingerVertical, igoPanInertia, igoPanGutter, igoParentPassthrough]
    Columns = <
      item
        Position = 0
        Text = ' '#1048#1084#1103', '#1050#1072#1090#1077#1088#1086#1088#1080#1103
        Width = 140
      end
      item
        Position = 1
        Text = #1054#1087#1080#1089#1072#1085#1080#1077
        Width = 70
      end
      item
        Position = 2
        Text = #1045#1076#1080#1085#1080#1094#1099
        Width = 70
      end
      item
        Position = 3
        Text = #1057#1082#1088#1099#1090#1099#1081
      end
      item
        Position = 4
        Text = #1063#1090#1077#1085#1080#1077
      end
      item
        Position = 5
        Text = #1058#1080#1087
      end
      item
        Position = 6
        Text = #1047#1085#1072#1095#1077#1085#1080#1077
        Width = 143
      end>
  end
  object ppM: TPopupActionBar
    Left = 88
    Top = 53
    object NCategery: TMenuItem
      Caption = #1053#1086#1074#1072#1103' '#1082#1072#1090#1077#1075#1086#1088#1080#1103'...'
      OnClick = NCategeryClick
    end
    object N1: TMenuItem
      Caption = '-'
    end
    object NNew: TMenuItem
      Caption = #1053#1086#1074#1086#1077' '#1089#1074#1086#1081#1089#1090#1074#1086'...'
      OnClick = NNewClick
    end
    object NDelete: TMenuItem
      Caption = #1059#1076#1072#1083#1080#1090#1100' '#1089#1074#1086#1081#1089#1090#1074#1086'...'
      OnClick = NDeleteClick
    end
    object NEdit: TMenuItem
      Caption = #1056#1077#1076#1072#1082#1090#1080#1088#1086#1074#1072#1090#1100'...'
      OnClick = NEditClick
    end
  end
end

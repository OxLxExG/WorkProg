object FormWrok: TFormWrok
  Left = 0
  Top = 0
  ParentCustomHint = False
  BorderStyle = bsSizeToolWin
  Caption = #1076#1077#1088#1077#1074#1086' '#1076#1072#1085#1085#1099#1093
  ClientHeight = 338
  ClientWidth = 636
  Color = clWindow
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -12
  Font.Name = 'Segoe UI'
  Font.Style = []
  TextHeight = 15
  object TreeBad: TVirtualStringTree
    Left = 8
    Top = 48
    Width = 452
    Height = 209
    BorderWidth = 1
    Colors.BorderColor = 15987699
    Colors.DisabledColor = clGray
    Colors.DropMarkColor = 15385233
    Colors.DropTargetColor = 15385233
    Colors.DropTargetBorderColor = 15385233
    Colors.FocusedSelectionColor = 15385233
    Colors.FocusedSelectionBorderColor = 15385233
    Colors.GridLineColor = 15987699
    Colors.HeaderHotColor = clBtnText
    Colors.HotColor = clBtnText
    Colors.SelectionRectangleBlendColor = 15385233
    Colors.SelectionRectangleBorderColor = 15385233
    Colors.SelectionTextColor = clBlack
    Colors.TreeLineColor = clBtnText
    Colors.UnfocusedColor = clGray
    Colors.UnfocusedSelectionColor = 13421772
    Colors.UnfocusedSelectionBorderColor = 13421772
    Header.AutoSizeIndex = 2
    Header.Height = 13
    Header.Options = [hoAutoResize, hoColumnResize, hoDrag, hoShowSortGlyphs, hoVisible, hoAutoSpring, hoHeaderClickAutoSort]
    PopupMenu = ppM
    TabOrder = 0
    TreeOptions.AutoOptions = [toAutoDropExpand, toAutoScrollOnExpand, toAutoSpanColumns, toAutoTristateTracking, toAutoHideButtons, toAutoDeleteMovedNodes]
    TreeOptions.PaintOptions = [toHotTrack, toShowButtons, toShowDropmark, toShowHorzGridLines, toShowRoot, toShowTreeLines, toShowVertGridLines, toThemeAware, toUseBlendedImages, toFullVertGridLines]
    TreeOptions.SelectionOptions = [toDisableDrawSelection, toExtendedFocus, toSimpleDrawSelection]
    TreeOptions.StringOptions = [toSaveCaptions, toShowStaticText, toAutoAcceptEditChange]
    Touch.InteractiveGestures = [igPan, igPressAndTap]
    Touch.InteractiveGestureOptions = [igoPanSingleFingerHorizontal, igoPanSingleFingerVertical, igoPanInertia, igoPanGutter, igoParentPassthrough]
    Columns = <
      item
        Options = [coEnabled, coParentBidiMode, coParentColor, coResizable, coShowDropMark, coVisible, coSmartResize, coAllowFocus]
        Position = 0
        Text = #1055#1072#1088#1072#1084#1077#1090#1088#1099
        Width = 180
      end
      item
        Options = [coDraggable, coEnabled, coParentBidiMode, coParentColor, coResizable, coShowDropMark, coVisible, coAllowFocus]
        Position = 1
        Text = #1041#1077#1079' '#1092#1086#1088#1084#1072#1090#1080#1088#1086#1074#1072#1085#1080#1103
        Width = 170
      end
      item
        Options = [coDraggable, coEnabled, coParentBidiMode, coParentColor, coResizable, coShowDropMark, coVisible, coAutoSpring, coSmartResize, coAllowFocus]
        Position = 2
        Text = #1057' '#1084#1077#1090#1088#1086#1083#1086#1075#1080#1077#1081
        Width = 96
      end>
  end
  object Tree: TVirtualStringTree
    Left = 0
    Top = 0
    Width = 636
    Height = 338
    AccessibleName = #1056#1072#1089#1095#1077#1090#1085#1099#1077
    Align = alClient
    DefaultNodeHeight = 19
    Header.AutoSizeIndex = 0
    Header.Options = [hoColumnResize, hoDrag, hoShowSortGlyphs, hoVisible]
    PopupMenu = ppM
    TabOrder = 1
    TreeOptions.PaintOptions = [toHotTrack, toShowButtons, toShowDropmark, toShowHorzGridLines, toShowRoot, toShowTreeLines, toShowVertGridLines, toThemeAware, toUseBlendedImages, toFullVertGridLines]
    TreeOptions.SelectionOptions = [toDisableDrawSelection, toExtendedFocus, toSimpleDrawSelection]
    TreeOptions.StringOptions = [toSaveCaptions, toShowStaticText, toAutoAcceptEditChange]
    OnGetText = TreeBadGetText
    OnPaintText = TreeBadPaintText
    Touch.InteractiveGestures = [igPan, igPressAndTap]
    Touch.InteractiveGestureOptions = [igoPanSingleFingerHorizontal, igoPanSingleFingerVertical, igoPanInertia, igoPanGutter, igoParentPassthrough]
    Columns = <
      item
        Position = 0
        Text = #1055#1072#1088#1072#1084#1077#1090#1088#1099
        Width = 200
      end
      item
        Position = 1
        Text = #1055#1088#1080#1073#1086#1088
        Width = 200
      end
      item
        Position = 2
        Text = #1056#1072#1089#1095#1077#1090#1085#1099#1077
        Width = 200
      end>
  end
  object ppM: TPopupActionBar
    OnPopup = ppMPopup
    Left = 240
    Top = 136
    object NShow: TMenuItem
      Caption = #1055#1086#1082#1072#1079#1072#1090#1100' '#1085#1072' '#1085#1086#1074#1086#1084' '#1075#1088#1072#1092#1080#1082#1077
      OnClick = NShowClick
    end
  end
end

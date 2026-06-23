object FormMetrInclinT: TFormMetrInclinT
  Left = 0
  Top = 0
  ActiveControl = Tree
  Caption = 'FormMetrInclinT'
  ClientHeight = 466
  ClientWidth = 872
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  TextHeight = 13
  object lbInfo: TLabel
    Left = 0
    Top = 453
    Width = 872
    Height = 13
    Align = alBottom
    Caption = '--------------------'
    WordWrap = True
    ExplicitWidth = 80
  end
  object Tree: TVirtualStringTree
    Left = 0
    Top = 0
    Width = 872
    Height = 453
    AccessibleName = 'AHz'
    Align = alClient
    BorderWidth = 1
    Colors.BorderColor = 15987699
    Colors.DisabledColor = clGray
    Colors.DropMarkColor = 15385233
    Colors.DropTargetColor = 15385233
    Colors.DropTargetBorderColor = 15385233
    Colors.FocusedSelectionColor = 15385233
    Colors.FocusedSelectionBorderColor = 15385233
    Colors.GridLineColor = 15987699
    Colors.HeaderHotColor = clBlack
    Colors.HotColor = clBlack
    Colors.SelectionRectangleBlendColor = 15385233
    Colors.SelectionRectangleBorderColor = 15385233
    Colors.SelectionTextColor = clBlack
    Colors.TreeLineColor = 9471874
    Colors.UnfocusedColor = clGray
    Colors.UnfocusedSelectionColor = 13421772
    Colors.UnfocusedSelectionBorderColor = 13421772
    Header.AutoSizeIndex = -1
    Header.Options = [hoAutoResize, hoColumnResize, hoDrag, hoShowSortGlyphs, hoVisible, hoAutoSpring]
    TabOrder = 0
    TreeOptions.AutoOptions = [toAutoDropExpand, toAutoScrollOnExpand, toAutoSpanColumns, toAutoTristateTracking, toAutoHideButtons, toAutoDeleteMovedNodes]
    TreeOptions.MiscOptions = [toAcceptOLEDrop, toFullRepaintOnResize, toGridExtensions, toInitOnSave, toToggleOnDblClick, toWheelPanning, toEditOnClick]
    TreeOptions.PaintOptions = [toShowButtons, toShowDropmark, toShowHorzGridLines, toShowTreeLines, toShowVertGridLines, toThemeAware, toUseBlendedImages, toFullVertGridLines]
    TreeOptions.SelectionOptions = [toFullRowSelect]
    OnAddToSelection = TreeAddToSelection
    OnGetText = TreeGetText
    Columns = <
      item
        Options = [coEnabled, coParentBidiMode, coParentColor, coResizable, coShowDropMark, coVisible, coAllowFocus]
        Position = 0
        Text = #8470
        Width = 40
      end
      item
        Options = [coEnabled, coParentBidiMode, coParentColor, coResizable, coShowDropMark, coVisible, coAllowFocus]
        Position = 1
        Text = 'T'
      end
      item
        Position = 2
        Text = #1047#1077#1085'.'#1057#1090
        Width = 60
      end
      item
        Position = 3
        Text = #1040#1079#1080'.'#1057#1090
        Width = 60
      end
      item
        Position = 4
        Text = #1042#1080#1079'.'#1057#1090
        Width = 60
      end
      item
        Options = [coEnabled, coParentBidiMode, coParentColor, coResizable, coShowDropMark, coVisible, coAllowFocus]
        Position = 5
        Text = 'Gx'
        Width = 60
      end
      item
        Options = [coEnabled, coParentBidiMode, coParentColor, coResizable, coShowDropMark, coVisible, coAllowFocus]
        Position = 6
        Text = 'Gy'
        Width = 60
      end
      item
        Options = [coEnabled, coParentBidiMode, coParentColor, coResizable, coShowDropMark, coVisible, coAllowFocus]
        Position = 7
        Text = 'Gz'
        Width = 60
      end
      item
        Options = [coEnabled, coParentBidiMode, coParentColor, coResizable, coShowDropMark, coVisible, coAllowFocus]
        Position = 8
        Text = 'Hx'
        Width = 60
      end
      item
        Options = [coEnabled, coParentBidiMode, coParentColor, coResizable, coShowDropMark, coVisible, coAllowFocus]
        Position = 9
        Text = 'Hy'
        Width = 60
      end
      item
        Options = [coEnabled, coParentBidiMode, coParentColor, coResizable, coShowDropMark, coVisible, coAllowFocus]
        Position = 10
        Text = 'Hz'
        Width = 60
      end
      item
        Options = [coEnabled, coParentBidiMode, coParentColor, coResizable, coShowDropMark, coVisible, coAllowFocus]
        Position = 11
        Text = 'G '#1080#1083#1080' H'
        Width = 60
      end
      item
        Options = [coEnabled, coParentBidiMode, coParentColor, coResizable, coShowDropMark, coVisible, coAllowFocus]
        Position = 12
        Text = #1054#1089#1100
        Width = 60
      end
      item
        Options = [coEnabled, coParentBidiMode, coParentColor, coResizable, coShowDropMark, coVisible, coAllowFocus]
        Position = 13
        Text = #1040#1084#1087
        Width = 60
      end
      item
        Options = [coEnabled, coParentBidiMode, coParentColor, coResizable, coShowDropMark, coVisible, coAllowFocus]
        Position = 14
        Text = #1057#1084#1077#1097#1077#1085#1080#1077
        Width = 56
      end>
  end
end

object FormRes: TFormRes
  Left = 0
  Top = 0
  Caption = #1052#1077#1090#1088#1086#1083#1086#1075#1080#1103' '#1042#1050
  ClientHeight = 317
  ClientWidth = 834
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  TextHeight = 13
  object PanelM: TPanel
    Left = 0
    Top = 0
    Width = 834
    Height = 317
    Align = alClient
    BevelOuter = bvNone
    Caption = 'PanelM'
    ShowCaption = False
    TabOrder = 0
    object lbInfo: TLabel
      Left = 0
      Top = 304
      Width = 834
      Height = 13
      Align = alBottom
      Alignment = taCenter
      WordWrap = True
      ExplicitWidth = 3
    end
    object lbAlpha: TLabel
      Left = 0
      Top = 291
      Width = 834
      Height = 13
      Align = alBottom
      WordWrap = True
      ExplicitWidth = 3
    end
    object Tree: TVirtualStringTree
      Left = 0
      Top = 0
      Width = 834
      Height = 291
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
      Header.Height = 13
      Header.Options = [hoAutoResize, hoColumnResize, hoDrag, hoShowSortGlyphs, hoVisible, hoAutoSpring]
      TabOrder = 0
      TreeOptions.AutoOptions = [toAutoDropExpand, toAutoScrollOnExpand, toAutoSpanColumns, toAutoTristateTracking, toAutoHideButtons, toAutoDeleteMovedNodes]
      TreeOptions.MiscOptions = [toAcceptOLEDrop, toEditable, toFullRepaintOnResize, toGridExtensions, toInitOnSave, toToggleOnDblClick, toWheelPanning, toEditOnClick]
      TreeOptions.PaintOptions = [toShowButtons, toShowDropmark, toShowHorzGridLines, toShowTreeLines, toShowVertGridLines, toThemeAware, toUseBlendedImages, toFullVertGridLines]
      TreeOptions.SelectionOptions = [toExtendedFocus, toFullRowSelect]
      OnAddToSelection = TreeAddToSelection
      OnGetText = TreeGetText
      Columns = <
        item
          MaxWidth = 100
          Options = [coEnabled, coParentBidiMode, coParentColor, coResizable, coShowDropMark, coVisible, coAllowFocus]
          Position = 0
          Text = #8470
          Width = 36
        end
        item
          Options = [coEnabled, coParentBidiMode, coParentColor, coResizable, coShowDropMark, coVisible, coAllowFocus, coEditable]
          Position = 1
          Text = #1042#1074#1086#1076' Y'
          Width = 64
        end
        item
          MaxWidth = 100
          Options = [coEnabled, coParentBidiMode, coParentColor, coResizable, coShowDropMark, coVisible, coAllowFocus]
          Position = 2
          Text = 'U'
          Width = 64
        end
        item
          Options = [coEnabled, coParentBidiMode, coParentColor, coResizable, coShowDropMark, coVisible, coAllowFocus]
          Position = 3
          Text = 'I'
          Width = 64
        end
        item
          Options = [coEnabled, coParentBidiMode, coParentColor, coResizable, coShowDropMark, coVisible, coAllowFocus]
          Position = 4
          Text = 'Y'
          Width = 64
        end
        item
          Options = [coEnabled, coParentBidiMode, coParentColor, coResizable, coShowDropMark, coVisible, coAllowFocus]
          Position = 5
          Text = 'Y.trr'
          Width = 64
        end
        item
          Options = [coEnabled, coParentBidiMode, coParentColor, coResizable, coShowDropMark, coVisible, coAllowFocus]
          Position = 6
          Text = #1086#1096'%'
          Width = 64
        end
        item
          Options = [coEnabled, coParentBidiMode, coParentColor, coResizable, coShowDropMark, coVisible, coAllowFocus]
          Position = 7
          Text = 'R.trr'
          Width = 60
        end
        item
          Options = [coEnabled, coParentBidiMode, coParentColor, coResizable, coShowDropMark, coVisible, coAllowFocus]
          Position = 8
          Text = 'k0'
          Width = 57
        end
        item
          Options = [coEnabled, coParentBidiMode, coParentColor, coResizable, coShowDropMark, coVisible, coAllowFocus]
          Position = 9
          Text = 'k1'
          Width = 64
        end
        item
          Position = 10
          Text = 'k2'
          Width = 47
        end
        item
          Position = 11
          Text = 'k3'
          Width = 40
        end
        item
          Position = 12
          Text = 'k4'
          Width = 40
        end
        item
          Position = 13
          Text = 'k5'
          Width = 40
        end
        item
          Options = [coEnabled, coParentBidiMode, coParentColor, coResizable, coShowDropMark, coVisible, coAllowFocus]
          Position = 14
          Text = 'R2'
          Width = 60
        end>
    end
  end
end

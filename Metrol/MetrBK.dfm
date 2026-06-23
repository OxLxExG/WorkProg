object FormBK: TFormBK
  Left = 0
  Top = 0
  ActiveControl = Tree
  Caption = #1052#1077#1090#1088#1086#1083#1086#1075#1080#1103' '#1042#1050
  ClientHeight = 317
  ClientWidth = 911
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
    Width = 911
    Height = 317
    Align = alClient
    BevelOuter = bvNone
    Caption = 'PanelM'
    ShowCaption = False
    TabOrder = 0
    object Splitter: TSplitter
      Left = 697
      Top = 0
      Height = 291
      ExplicitLeft = 8
      ExplicitHeight = 377
    end
    object lbInfo: TLabel
      Left = 0
      Top = 304
      Width = 3
      Height = 13
      Align = alBottom
      Alignment = taCenter
      WordWrap = True
    end
    object lbAlpha: TLabel
      Left = 0
      Top = 291
      Width = 3
      Height = 13
      Align = alBottom
      WordWrap = True
    end
    object Tree: TVirtualStringTree
      Left = 0
      Top = 0
      Width = 697
      Height = 291
      Align = alLeft
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
          Width = 33
        end
        item
          Options = [coEnabled, coParentBidiMode, coParentColor, coResizable, coShowDropMark, coVisible, coAllowFocus, coEditable]
          Position = 1
          Text = #1042#1074#1086#1076' U'
          Width = 52
        end
        item
          MaxWidth = 100
          Options = [coEnabled, coParentBidiMode, coParentColor, coResizable, coShowDropMark, coVisible, coAllowFocus]
          Position = 2
          Text = 'Z1'
          Width = 41
        end
        item
          Options = [coEnabled, coParentBidiMode, coParentColor, coResizable, coShowDropMark, coVisible, coAllowFocus]
          Position = 3
          Text = 'Z2'
          Width = 44
        end
        item
          Options = [coEnabled, coParentBidiMode, coParentColor, coResizable, coShowDropMark, coVisible, coAllowFocus]
          Position = 4
          Text = 'Z3'
          Width = 40
        end
        item
          Options = [coEnabled, coParentBidiMode, coParentColor, coResizable, coShowDropMark, coVisible, coAllowFocus]
          Position = 5
          Text = 'Z4'
          Width = 35
        end
        item
          Options = [coEnabled, coParentBidiMode, coParentColor, coResizable, coShowDropMark, coVisible, coAllowFocus]
          Position = 6
          Text = 'Z5'
          Width = 41
        end
        item
          Options = [coEnabled, coParentBidiMode, coParentColor, coResizable, coShowDropMark, coVisible, coAllowFocus]
          Position = 7
          Text = 'Z6'
          Width = 49
        end
        item
          Options = [coEnabled, coParentBidiMode, coParentColor, coResizable, coShowDropMark, coAllowFocus]
          Position = 8
          Text = 'Z1.c'
          Width = 44
        end
        item
          Options = [coEnabled, coParentBidiMode, coParentColor, coResizable, coShowDropMark, coAllowFocus]
          Position = 9
          Text = 'Z2.c'
          Width = 40
        end
        item
          Options = [coEnabled, coParentBidiMode, coParentColor, coResizable, coShowDropMark, coAllowFocus]
          Position = 10
          Text = 'Z3.c'
          Width = 40
        end
        item
          Options = [coEnabled, coParentBidiMode, coParentColor, coResizable, coShowDropMark, coAllowFocus]
          Position = 11
          Text = 'Z4.c'
          Width = 44
        end
        item
          Options = [coEnabled, coParentBidiMode, coParentColor, coResizable, coShowDropMark, coAllowFocus]
          Position = 12
          Text = 'Z5.c'
          Width = 41
        end
        item
          Options = [coEnabled, coParentBidiMode, coParentColor, coResizable, coShowDropMark, coAllowFocus]
          Position = 13
          Text = 'Z6.c'
          Width = 43
        end
        item
          Options = [coEnabled, coParentBidiMode, coParentColor, coResizable, coShowDropMark, coVisible, coAllowFocus]
          Position = 14
          Text = 'KSI'
          Width = 35
        end
        item
          Options = [coEnabled, coParentBidiMode, coParentColor, coResizable, coShowDropMark, coAllowFocus]
          Position = 15
          Text = 'KSI.c'
          Width = 10
        end
        item
          Options = [coEnabled, coParentBidiMode, coParentColor, coResizable, coShowDropMark, coVisible, coAllowFocus]
          Position = 16
          Text = 'PS1'
          Width = 35
        end
        item
          Options = [coEnabled, coParentBidiMode, coParentColor, coResizable, coShowDropMark, coVisible, coAllowFocus]
          Position = 17
          Text = 'PS2'
          Width = 36
        end
        item
          Options = [coEnabled, coParentBidiMode, coParentColor, coResizable, coShowDropMark, coVisible, coAllowFocus]
          Position = 18
          Text = 'DPS'
          Width = 35
        end
        item
          Options = [coEnabled, coParentBidiMode, coParentColor, coResizable, coShowDropMark, coAllowFocus]
          Position = 19
          Text = 'PS1.c'
          Width = 49
        end
        item
          Options = [coEnabled, coParentBidiMode, coParentColor, coResizable, coShowDropMark, coAllowFocus]
          Position = 20
          Text = 'PS2.c'
          Width = 47
        end
        item
          Options = [coEnabled, coParentBidiMode, coParentColor, coResizable, coShowDropMark, coAllowFocus]
          Position = 21
          Text = 'DPS.c'
          Width = 47
        end
        item
          Options = [coEnabled, coParentBidiMode, coParentColor, coResizable, coShowDropMark, coAllowFocus]
          Position = 22
          Text = 'I10'
          Width = 42
        end
        item
          Options = [coEnabled, coParentBidiMode, coParentColor, coResizable, coShowDropMark, coVisible, coAllowFocus]
          Position = 23
          Text = 'I11'
          Width = 35
        end
        item
          Options = [coEnabled, coParentBidiMode, coParentColor, coResizable, coShowDropMark, coAllowFocus]
          Position = 24
          Text = 'I12'
          Width = 36
        end
        item
          Options = [coEnabled, coParentBidiMode, coParentColor, coResizable, coShowDropMark, coAllowFocus]
          Position = 25
          Text = 'I13'
          Width = 31
        end
        item
          Options = [coEnabled, coParentBidiMode, coParentColor, coResizable, coShowDropMark, coAllowFocus]
          Position = 26
          Text = 'I14'
          Width = 33
        end
        item
          Options = [coEnabled, coParentBidiMode, coParentColor, coResizable, coShowDropMark, coAllowFocus]
          Position = 27
          Text = 'I15'
          Width = 32
        end
        item
          Options = [coEnabled, coParentBidiMode, coParentColor, coResizable, coShowDropMark, coVisible, coAllowFocus]
          Position = 28
          Text = 'I16'
          Width = 32
        end
        item
          Options = [coEnabled, coParentBidiMode, coParentColor, coResizable, coShowDropMark, coAllowFocus]
          Position = 29
          Text = 'I20'
          Width = 32
        end
        item
          Options = [coEnabled, coParentBidiMode, coParentColor, coResizable, coShowDropMark, coVisible, coAllowFocus]
          Position = 30
          Text = 'I21'
          Width = 31
        end
        item
          Options = [coEnabled, coParentBidiMode, coParentColor, coResizable, coShowDropMark, coAllowFocus]
          Position = 31
          Text = 'I22'
          Width = 32
        end
        item
          Options = [coEnabled, coParentBidiMode, coParentColor, coResizable, coShowDropMark, coAllowFocus]
          Position = 32
          Text = 'I23'
          Width = 36
        end
        item
          Options = [coEnabled, coParentBidiMode, coParentColor, coResizable, coShowDropMark, coAllowFocus]
          Position = 33
          Text = 'I24'
          Width = 34
        end
        item
          Options = [coEnabled, coParentBidiMode, coParentColor, coResizable, coShowDropMark, coAllowFocus]
          Position = 34
          Text = 'I25'
          Width = 31
        end
        item
          Options = [coEnabled, coParentBidiMode, coParentColor, coResizable, coShowDropMark, coVisible, coAllowFocus]
          Position = 35
          Text = 'I26'
          Width = 35
        end
        item
          Options = [coEnabled, coParentBidiMode, coParentColor, coResizable, coShowDropMark, coAllowFocus]
          Position = 36
          Text = 'I11.c'
          Width = 10
        end
        item
          Options = [coEnabled, coParentBidiMode, coParentColor, coResizable, coShowDropMark, coAllowFocus]
          Position = 37
          Text = 'I12.c'
          Width = 10
        end
        item
          Options = [coEnabled, coParentBidiMode, coParentColor, coResizable, coShowDropMark, coAllowFocus]
          Position = 38
          Text = 'I13.c'
          Width = 10
        end
        item
          Options = [coEnabled, coParentBidiMode, coParentColor, coResizable, coShowDropMark, coAllowFocus]
          Position = 39
          Text = 'I14.c'
          Width = 10
        end
        item
          Options = [coEnabled, coParentBidiMode, coParentColor, coResizable, coShowDropMark, coAllowFocus]
          Position = 40
          Text = 'I15.c'
          Width = 10
        end
        item
          Options = [coEnabled, coParentBidiMode, coParentColor, coResizable, coShowDropMark, coAllowFocus]
          Position = 41
          Text = 'I16.c'
          Width = 10
        end
        item
          Options = [coEnabled, coParentBidiMode, coParentColor, coResizable, coShowDropMark, coAllowFocus]
          Position = 42
          Text = 'I21.c'
          Width = 10
        end
        item
          Options = [coEnabled, coParentBidiMode, coParentColor, coResizable, coShowDropMark, coAllowFocus]
          Position = 43
          Text = 'I22.c'
          Width = 10
        end
        item
          Options = [coEnabled, coParentBidiMode, coParentColor, coResizable, coShowDropMark, coAllowFocus]
          Position = 44
          Text = 'I23.c'
          Width = 10
        end
        item
          Options = [coEnabled, coParentBidiMode, coParentColor, coResizable, coShowDropMark, coAllowFocus]
          Position = 45
          Text = 'I24.c'
          Width = 10
        end
        item
          Options = [coEnabled, coParentBidiMode, coParentColor, coResizable, coShowDropMark, coAllowFocus]
          Position = 46
          Text = 'I25.c'
          Width = 10
        end
        item
          Options = [coEnabled, coParentBidiMode, coParentColor, coResizable, coShowDropMark, coAllowFocus]
          Position = 47
          Text = 'I26.c'
          Width = 10
        end
        item
          Options = [coEnabled, coParentBidiMode, coParentColor, coResizable, coShowDropMark, coVisible, coAllowFocus]
          Position = 48
          Text = 'U0'#13#10
          Width = 39
        end
        item
          Options = [coEnabled, coParentBidiMode, coParentColor, coResizable, coShowDropMark, coAllowFocus]
          Position = 49
          Text = 'U0.c'
          Width = 10
        end
        item
          Options = [coEnabled, coParentBidiMode, coParentColor, coResizable, coShowDropMark, coVisible, coAllowFocus]
          Position = 50
          Text = 'IT'
          Width = 49
        end>
    end
    object Inspector: TJvInspector
      Left = 700
      Top = 0
      Width = 211
      Height = 291
      Align = alClient
      BevelOuter = bvNone
      Divider = 100
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -11
      Font.Name = 'Courier'
      Font.Style = []
      ItemHeight = 16
      TabStop = True
      TabOrder = 1
    end
  end
end

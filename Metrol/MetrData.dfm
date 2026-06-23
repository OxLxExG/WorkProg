object FormMetrData: TFormMetrData
  Left = 0
  Top = 0
  ClientHeight = 195
  ClientWidth = 447
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  OldCreateOrder = False
  PixelsPerInch = 96
  TextHeight = 13
  object Tree: TVirtualStringTree
    Left = 0
    Top = 0
    Width = 447
    Height = 195
    Align = alClient
    BorderWidth = 1
    Header.AutoSizeIndex = -1
    Header.Options = [hoAutoResize, hoColumnResize, hoDrag, hoShowSortGlyphs, hoVisible, hoAutoSpring]
    Header.ParentFont = True
    TabOrder = 0
    TreeOptions.AutoOptions = [toAutoDropExpand, toAutoScrollOnExpand, toAutoSpanColumns, toAutoTristateTracking, toAutoHideButtons, toAutoDeleteMovedNodes]
    TreeOptions.MiscOptions = [toAcceptOLEDrop, toFullRepaintOnResize, toGridExtensions, toInitOnSave, toToggleOnDblClick, toWheelPanning, toEditOnClick]
    TreeOptions.PaintOptions = [toShowButtons, toShowDropmark, toShowHorzGridLines, toShowTreeLines, toShowVertGridLines, toThemeAware, toUseBlendedImages, toFullVertGridLines]
    TreeOptions.SelectionOptions = [toFullRowSelect]
    OnGetText = TreeGetText
    Columns = <
      item
        Options = [coEnabled, coParentBidiMode, coParentColor, coResizable, coShowDropMark, coVisible, coAllowFocus]
        Position = 0
      end
      item
        Position = 1
        Width = 100
        WideText = 'X'
      end
      item
        Position = 2
        Width = 100
        WideText = 'Y'
      end
      item
        Position = 3
        Width = 100
        WideText = 'Z'
      end
      item
        Position = 4
        Width = 91
        WideText = 'D4'
      end>
  end
end

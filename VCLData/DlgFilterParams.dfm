object FormFilterParams: TFormFilterParams
  Left = 0
  Top = 0
  Caption = 'FormFilterParams'
  ClientHeight = 424
  ClientWidth = 296
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  OldCreateOrder = False
  OnCreate = FormCreate
  OnDestroy = FormDestroy
  DesignSize = (
    296
    424)
  PixelsPerInch = 96
  TextHeight = 13
  object Tree: TVirtualStringTree
    Left = 8
    Top = 8
    Width = 280
    Height = 368
    Anchors = [akLeft, akTop, akRight, akBottom]
    BorderWidth = 1
    Color = clBtnHighlight
    DragMode = dmAutomatic
    DragType = dtVCL
    Header.AutoSizeIndex = 2
    Header.MainColumn = 2
    Header.Options = [hoAutoResize, hoColumnResize, hoDrag, hoShowImages, hoShowSortGlyphs, hoVisible, hoAutoSpring]
    Header.ParentFont = True
    PopupMenu = ppM
    TabOrder = 0
    TreeOptions.AutoOptions = [toAutoDropExpand, toAutoScrollOnExpand, toAutoSpanColumns, toAutoTristateTracking, toAutoHideButtons, toAutoDeleteMovedNodes]
    TreeOptions.MiscOptions = [toAcceptOLEDrop, toFullRepaintOnResize, toInitOnSave, toToggleOnDblClick, toWheelPanning]
    TreeOptions.PaintOptions = [toHideFocusRect, toHideSelection, toHotTrack, toShowButtons, toShowDropmark, toShowHorzGridLines, toShowRoot, toShowTreeLines, toShowVertGridLines, toThemeAware, toUseBlendedImages, toFullVertGridLines]
    TreeOptions.SelectionOptions = [toDisableDrawSelection, toExtendedFocus, toMultiSelect, toSimpleDrawSelection]
    OnAfterCellPaint = TreeAfterCellPaint
    OnGetText = TreeGetText
    OnMouseDown = TreeMouseDown
    Columns = <
      item
        MaxWidth = 24
        MinWidth = 24
        Options = [coAllowClick, coDraggable, coEnabled, coParentBidiMode, coParentColor, coResizable, coShowDropMark, coVisible]
        Position = 0
        Width = 24
        WideText = #1057
      end
      item
        MaxWidth = 24
        MinWidth = 24
        Options = [coAllowClick, coDraggable, coEnabled, coParentBidiMode, coParentColor, coResizable, coShowDropMark, coVisible]
        Position = 1
        Width = 24
        WideText = #1056
      end
      item
        Position = 2
        Style = vsOwnerDraw
        Width = 226
        WideText = #1048#1084#1103
      end>
  end
  object btExit: TButton
    Left = 8
    Top = 391
    Width = 75
    Height = 25
    Anchors = [akLeft, akBottom]
    Caption = #1042#1099#1093#1086#1076
    TabOrder = 1
    OnClick = btExitClick
  end
  object btApply: TButton
    Left = 96
    Top = 391
    Width = 75
    Height = 25
    Anchors = [akLeft, akBottom]
    Caption = #1055#1088#1080#1084#1077#1085#1080#1090#1100
    Enabled = False
    TabOrder = 2
    OnClick = btApplyClick
  end
  object ppM: TPopupActionBar
    OnPopup = ppMPopup
    Left = 104
    Top = 88
    object NSet: TMenuItem
      Caption = #1042#1099#1073#1088#1072#1090#1100' '
      object NSetAll: TMenuItem
        Tag = 2
        Caption = #1042#1089#1077
        OnClick = ClickAllMenu
      end
      object NSetRow: TMenuItem
        Caption = '"'#1057#1099#1088#1099#1077'" '#1076#1072#1085#1085#1099#1077
        OnClick = ClickAllMenu
      end
      object SetTrr: TMenuItem
        Tag = 1
        Caption = #1056#1072#1089#1095#1077#1090#1085#1099#1077
        OnClick = ClickAllMenu
      end
    end
    object NDel: TMenuItem
      Caption = #1057#1085#1103#1090#1100' '#1074#1099#1076#1077#1083#1077#1085#1080#1077
      object NClrAll: TMenuItem
        Tag = 2
        Caption = #1042#1089#1077
        OnClick = ClickAllMenu
      end
      object NClrRow: TMenuItem
        Caption = '"'#1057#1099#1088#1099#1077'" '#1076#1072#1085#1085#1099#1077
        OnClick = ClickAllMenu
      end
      object NClrTrr: TMenuItem
        Tag = 1
        Caption = #1056#1072#1089#1095#1077#1090#1085#1099#1077
        OnClick = ClickAllMenu
      end
    end
    object N1: TMenuItem
      Caption = '-'
    end
    object NSetChild: TMenuItem
      Caption = #1042#1099#1073#1088#1072#1090#1100' '#1076#1086#1095#1077#1088#1085#1080#1077
      object N5: TMenuItem
        Tag = 2
        Caption = #1042#1089#1077
        OnClick = ClickAllChild
      end
      object N6: TMenuItem
        Caption = '"'#1057#1099#1088#1099#1077'" '#1076#1072#1085#1085#1099#1077
        OnClick = ClickAllChild
      end
      object N7: TMenuItem
        Tag = 1
        Caption = #1056#1072#1089#1095#1077#1090#1085#1099#1077
        OnClick = ClickAllChild
      end
    end
    object NClrChild: TMenuItem
      Caption = #1057#1085#1103#1090#1100' '#1074#1099#1076#1077#1083#1077#1085#1080#1077' '#1076#1086#1095#1077#1088#1085#1080#1093
      object N2: TMenuItem
        Tag = 2
        Caption = #1042#1089#1077
        OnClick = ClickAllChild
      end
      object N3: TMenuItem
        Caption = '"'#1057#1099#1088#1099#1077'" '#1076#1072#1085#1085#1099#1077
        OnClick = ClickAllChild
      end
      object N4: TMenuItem
        Tag = 1
        Caption = #1056#1072#1089#1095#1077#1090#1085#1099#1077
        OnClick = ClickAllChild
      end
    end
  end
end

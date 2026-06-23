object FormMetr: TFormMetr
  Left = 0
  Top = 0
  Caption = #1052#1077#1090#1088#1086#1083#1086#1075#1080#1080'  '#1056#1077#1076#1072#1082#1090#1086#1088
  ClientHeight = 583
  ClientWidth = 938
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  TextHeight = 13
  object Splitter1: TSplitter
    Left = 177
    Top = 0
    Height = 583
    ExplicitLeft = 456
    ExplicitTop = 152
    ExplicitHeight = 100
  end
  object Tree: TVirtualStringTree
    Left = 0
    Top = 0
    Width = 177
    Height = 583
    Align = alLeft
    BorderWidth = 1
    Color = clBtnHighlight
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
    Ctl3D = True
    DragMode = dmAutomatic
    DragType = dtVCL
    Header.AutoSizeIndex = -1
    Header.Height = 13
    Header.Options = [hoAutoResize, hoColumnResize, hoDrag, hoShowSortGlyphs, hoVisible, hoAutoSpring]
    ParentCtl3D = False
    PopupMenu = ppM
    TabOrder = 0
    TreeOptions.AutoOptions = [toAutoDropExpand, toAutoScroll, toAutoScrollOnExpand, toAutoSpanColumns, toAutoTristateTracking, toAutoHideButtons, toAutoDeleteMovedNodes]
    TreeOptions.PaintOptions = [toShowButtons, toShowDropmark, toShowHorzGridLines, toShowRoot, toShowTreeLines, toShowVertGridLines, toThemeAware, toUseBlendedImages, toFullVertGridLines]
    TreeOptions.SelectionOptions = [toFullRowSelect]
    OnCompareNodes = TreeCompareNodes
    OnGetText = TreeGetText
    Touch.InteractiveGestures = [igPan, igPressAndTap]
    Touch.InteractiveGestureOptions = [igoPanSingleFingerHorizontal, igoPanSingleFingerVertical, igoPanInertia, igoPanGutter, igoParentPassthrough]
    Columns = <
      item
        Options = [coAllowClick, coEnabled, coParentBidiMode, coParentColor, coResizable, coShowDropMark, coVisible, coSmartResize, coAllowFocus]
        Position = 0
        Text = #1057#1082#1088#1080#1087#1090#1099
        Width = 177
      end>
  end
  object pc: TCPageControl
    Left = 180
    Top = 0
    Width = 758
    Height = 583
    Align = alClient
    TabOrder = 1
    OnContextPopup = pcContextPopup
  end
  object ppM: TPopupActionBar
    OnPopup = ppMPopup
    Left = 88
    Top = 176
    object N3: TMenuItem
      Caption = #1060#1072#1081#1083
      object NOpen: TMenuItem
        Caption = #1054#1090#1082#1088#1099#1090#1100'...'
        OnClick = NOpenClick
      end
      object NSave: TMenuItem
        Caption = #1057#1086#1093#1088#1072#1085#1080#1090#1100' '#1082#1072#1082'...'
        OnClick = NSaveClick
      end
    end
    object N2: TMenuItem
      Caption = '-'
    end
    object NCopy: TMenuItem
      Caption = #1050#1083#1086#1085#1080#1088#1086#1074#1072#1090#1100
      OnClick = NCopyClick
    end
    object NRename: TMenuItem
      Caption = #1055#1077#1088#1077#1080#1084#1077#1085#1086#1074#1072#1090#1100'...'
      OnClick = NRenameClick
    end
    object NCat: TMenuItem
      Caption = #1059#1076#1072#1083#1080#1090#1100'...'
      OnClick = NCatClick
    end
    object N7: TMenuItem
      Caption = '-'
    end
    object NEdit: TMenuItem
      Caption = #1056#1077#1076#1072#1082#1090#1080#1088#1086#1074#1072#1090#1100
      OnClick = NEditClick
    end
    object NApply: TMenuItem
      Caption = #1057#1086#1093#1088#1072#1085#1080#1090#1100' '#1092#1072#1081#1083
      Enabled = False
      OnClick = NApplyClick
    end
  end
  object ppTab: TPopupActionBar
    OnPopup = ppTabPopup
    Left = 360
    Top = 168
    object NCompile: TMenuItem
      Caption = #1054#1090#1082#1086#1084#1087#1080#1083#1080#1088#1086#1074#1072#1090#1100
      OnClick = NCompileClick
    end
    object N1: TMenuItem
      Caption = '-'
    end
    object Nexp: TMenuItem
      Caption = #1044#1086#1073#1072#1074#1080#1090#1100' '#1085#1086#1074#1099#1081' '#1101#1082#1089#1087#1086#1088#1090
      OnClick = NexpClick
    end
    object NImp: TMenuItem
      Caption = #1044#1086#1073#1072#1074#1080#1090#1100' '#1085#1086#1074#1099#1081' '#1080#1084#1087#1086#1088#1090
      OnClick = NImpClick
    end
    object Nexe: TMenuItem
      Caption = #1042#1099#1087#1086#1083#1085#1077#1085#1080#1077
      OnClick = NexeClick
    end
    object NSetup: TMenuItem
      Caption = #1059#1089#1090#1072#1085#1086#1074#1082#1080
      OnClick = NSetupClick
    end
    object MenuItem4: TMenuItem
      Caption = '-'
    end
    object NDel: TMenuItem
      Caption = #1059#1076#1072#1083#1080#1090#1100
      Enabled = False
      OnClick = NDelClick
    end
  end
  object SaveDialog: TSaveDialog
    DefaultExt = 'xml'
    Filter = #1060#1072#1081#1083' '#1086#1087#1080#1089#1072#1085#1080#1103' '#1087#1088#1080#1073#1086#1088#1072'(*.xml)|*.xml'
    Options = [ofOverwritePrompt, ofPathMustExist, ofEnableSizing, ofForceShowHidden]
    Left = 416
    Top = 160
  end
  object OpenDialog: TOpenDialog
    DefaultExt = 'xml'
    Filter = #1060#1072#1081#1083' '#1086#1087#1080#1089#1072#1085#1080#1103' '#1087#1088#1080#1073#1086#1088#1072'(*.xml)|*.xml'
    Options = [ofReadOnly, ofPathMustExist, ofFileMustExist, ofEnableSizing, ofForceShowHidden]
    Left = 416
    Top = 208
  end
end

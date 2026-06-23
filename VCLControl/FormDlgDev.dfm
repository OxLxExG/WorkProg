object FormCreateDev: TFormCreateDev
  Left = 0
  Top = 0
  BorderStyle = bsSizeToolWin
  Caption = #1053#1086#1074#1086#1077' '#1091#1089#1090#1088#1086#1081#1089#1090#1074#1086
  ClientHeight = 420
  ClientWidth = 392
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  Position = poMainFormCenter
  OnShow = FormShow
  DesignSize = (
    392
    420)
  TextHeight = 13
  object Label1: TLabel
    Left = 8
    Top = 8
    Width = 118
    Height = 13
    Caption = #1044#1086#1089#1090#1091#1087#1085#1099#1077' '#1091#1089#1090#1088#1086#1081#1089#1090#1074#1072
  end
  object Label3: TLabel
    Left = 8
    Top = 328
    Width = 93
    Height = 13
    Anchors = [akLeft, akBottom]
    Caption = #1042#1074#1077#1076#1080#1090#1077' '#1085#1072#1079#1074#1072#1085#1080#1077
    ExplicitTop = 307
  end
  object ButtonOK: TButton
    Left = 8
    Top = 387
    Width = 75
    Height = 25
    Anchors = [akLeft, akBottom]
    Caption = 'OK'
    ModalResult = 1
    TabOrder = 0
    OnClick = ButtonOKClick
  end
  object Button1: TButton
    Left = 104
    Top = 387
    Width = 75
    Height = 25
    Anchors = [akLeft, akBottom]
    Caption = #1054#1090#1084#1077#1085#1072
    ModalResult = 2
    TabOrder = 1
  end
  object Tree: TVirtualStringTree
    Left = 8
    Top = 24
    Width = 374
    Height = 297
    Anchors = [akLeft, akTop, akRight, akBottom]
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
    Header.AutoSizeIndex = 1
    Header.Height = 13
    Header.Options = [hoAutoResize, hoColumnResize, hoDrag, hoShowSortGlyphs, hoVisible, hoAutoSpring, hoHeaderClickAutoSort]
    ParentCtl3D = False
    RootNodeCount = 10
    TabOrder = 2
    TreeOptions.AutoOptions = [toAutoDropExpand, toAutoScrollOnExpand, toAutoSpanColumns, toAutoTristateTracking, toAutoHideButtons, toAutoDeleteMovedNodes]
    TreeOptions.MiscOptions = [toAcceptOLEDrop, toCheckSupport, toFullRepaintOnResize, toInitOnSave, toToggleOnDblClick, toWheelPanning, toEditOnClick]
    TreeOptions.PaintOptions = [toShowButtons, toShowDropmark, toShowHorzGridLines, toShowRoot, toShowTreeLines, toShowVertGridLines, toThemeAware, toUseBlendedImages, toFullVertGridLines]
    TreeOptions.SelectionOptions = [toFullRowSelect, toMultiSelect]
    OnChecked = TreeChecked
    OnChecking = TreeChecking
    OnGetText = TreeGetText
    Touch.InteractiveGestures = [igPan, igPressAndTap]
    Touch.InteractiveGestureOptions = [igoPanSingleFingerHorizontal, igoPanSingleFingerVertical, igoPanInertia, igoPanGutter, igoParentPassthrough]
    Columns = <
      item
        Options = [coAllowClick, coEnabled, coParentBidiMode, coParentColor, coResizable, coShowDropMark, coVisible, coSmartResize, coAllowFocus]
        Position = 0
        Text = #1059#1089#1090#1088#1086#1081#1089#1090#1074#1086
        Width = 116
      end
      item
        Options = [coAllowClick, coEnabled, coParentBidiMode, coParentColor, coResizable, coShowDropMark, coVisible, coSmartResize, coAllowFocus, coDisableAnimatedResize]
        Position = 1
        Text = #1054#1087#1080#1089#1072#1085#1080#1077
        Width = 213
      end
      item
        Position = 2
        Text = #1040#1076#1088#1077#1089
        Width = 45
      end>
  end
  object edCaption: TEdit
    Left = 8
    Top = 347
    Width = 130
    Height = 21
    Anchors = [akLeft, akBottom]
    TabOrder = 3
  end
  object cbTree: TCheckBox
    Left = 191
    Top = 391
    Width = 89
    Height = 17
    Anchors = [akLeft, akBottom]
    Caption = #1086#1082#1085#1086' '#1076#1072#1085#1085#1099#1093
    Checked = True
    State = cbChecked
    TabOrder = 4
  end
  object btConnection: TButton
    Left = 144
    Top = 345
    Width = 238
    Height = 25
    Anchors = [akLeft, akRight, akBottom]
    Caption = #1055#1086#1076#1082#1083#1102#1095#1080#1090#1100
    TabOrder = 5
    OnClick = btConnectionClick
  end
  object ppConnection: TPopupMenu
    Left = 144
    Top = 208
  end
end

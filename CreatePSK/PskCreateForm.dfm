object FormPsk: TFormPsk
  Left = 0
  Top = 0
  Caption = #1055#1057#1050' '#1056#1077#1076#1072#1082#1090#1086#1088
  ClientHeight = 609
  ClientWidth = 938
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  TextHeight = 13
  object Splitter1: TSplitter
    Left = 249
    Top = 0
    Height = 609
    ExplicitLeft = 496
    ExplicitTop = 696
    ExplicitHeight = 100
  end
  object Panel2: TPanel
    Left = 252
    Top = 0
    Width = 686
    Height = 609
    Align = alClient
    Caption = 'Panel2'
    TabOrder = 1
    object Splitter2: TSplitter
      Left = 1
      Top = 516
      Width = 684
      Height = 3
      Cursor = crVSplit
      Align = alBottom
      ExplicitTop = 1
      ExplicitWidth = 410
    end
    object Memo: TMemo
      Left = 1
      Top = 519
      Width = 684
      Height = 89
      Align = alBottom
      Font.Charset = RUSSIAN_CHARSET
      Font.Color = clWindowText
      Font.Height = -11
      Font.Name = 'Courier New'
      Font.Style = []
      ParentFont = False
      ScrollBars = ssVertical
      TabOrder = 0
    end
    object Tree: TVirtualStringTree
      Left = 1
      Top = 1
      Width = 684
      Height = 515
      Align = alClient
      BorderWidth = 1
      EditDelay = 500
      Header.AutoSizeIndex = 5
      Header.Height = 13
      Header.Options = [hoAutoResize, hoColumnResize, hoDrag, hoShowSortGlyphs, hoVisible, hoAutoSpring, hoHeaderClickAutoSort]
      PopupMenu = ppM
      TabOrder = 1
      TreeOptions.AutoOptions = [toAutoDropExpand, toAutoScrollOnExpand, toAutoSpanColumns, toAutoTristateTracking, toAutoHideButtons, toAutoDeleteMovedNodes]
      TreeOptions.MiscOptions = [toAcceptOLEDrop, toEditable, toFullRepaintOnResize, toGridExtensions, toInitOnSave, toToggleOnDblClick, toWheelPanning, toEditOnClick, toEditOnDblClick]
      TreeOptions.PaintOptions = [toShowButtons, toShowDropmark, toShowHorzGridLines, toShowRoot, toShowTreeLines, toShowVertGridLines, toThemeAware, toUseBlendedImages, toFullVertGridLines]
      TreeOptions.SelectionOptions = [toExtendedFocus, toMultiSelect]
      OnCreateEditor = TreeCreateEditor
      OnEditing = TreeEditing
      OnFocusChanged = TreeFocusChanged
      OnGetText = TreeGetText
      Touch.InteractiveGestures = [igPan, igPressAndTap]
      Touch.InteractiveGestureOptions = [igoPanSingleFingerHorizontal, igoPanSingleFingerVertical, igoPanInertia, igoPanGutter, igoParentPassthrough]
      Columns = <
        item
          Options = [coAllowClick, coEnabled, coParentBidiMode, coParentColor, coResizable, coShowDropMark, coVisible, coSmartResize, coAllowFocus, coEditable]
          Position = 0
          Text = #1044#1077#1088#1077#1074#1086
          Width = 150
        end
        item
          Position = 1
          Text = #1058#1080#1087
          Width = 170
        end
        item
          Position = 2
          Text = #1040#1076#1088#1077#1089
          Width = 65
        end
        item
          Position = 3
          Text = #1052#1072#1089#1089#1080#1074
        end
        item
          Position = 4
          Text = #1044#1072#1090#1095#1080#1082#1072' '#1089#1084#1077#1097#1077#1085#1080#1077' '
          Width = 73
        end
        item
          Options = [coAllowClick, coDraggable, coEnabled, coParentBidiMode, coParentColor, coResizable, coShowDropMark, coVisible, coAutoSpring, coSmartResize, coAllowFocus, coEditable]
          Position = 5
          Text = #1060#1086#1088#1084#1072#1090#1080#1088#1086#1074#1072#1085#1080#1077
          Width = 176
        end>
    end
  end
  object Panel1: TPanel
    Left = 0
    Top = 0
    Width = 249
    Height = 609
    Align = alLeft
    Caption = 'Panel1'
    ShowCaption = False
    TabOrder = 0
    object Bevel1: TBevel
      Left = 7
      Top = 6
      Width = 239
      Height = 169
    end
    object Label1: TLabel
      Left = 16
      Top = 13
      Width = 219
      Height = 13
      Caption = #1053#1072#1079#1074#1072#1085#1080#1077' '#1087#1088#1080#1073#1086#1088#1072' ('#1087#1088#1086#1073#1077#1083#1099' '#1085#1077#1076#1086#1087#1091#1089#1090#1080#1084#1099')'
    end
    object Label2: TLabel
      Left = 16
      Top = 56
      Width = 94
      Height = 13
      Caption = #1054#1087#1080#1089#1072#1085#1080#1077' '#1087#1088#1080#1073#1086#1088#1072
    end
    object Label3: TLabel
      Left = 54
      Top = 119
      Width = 141
      Height = 13
      Caption = #1059#1085#1080#1082#1072#1083#1100#1085#1099#1081' '#1072#1076#1088#1077#1089' '#1087#1088#1080#1073#1086#1088#1072
    end
    object Label4: TLabel
      Left = 50
      Top = 141
      Width = 191
      Height = 13
      Caption = #1044#1077#1083#1080#1090#1077#1083#1100' '#1074#1088#1077#1084#1077#1085#1080' '#1079#1072#1076#1077#1088#1078#1082#1080' 128,256'
    end
    object Bevel2: TBevel
      Left = 8
      Top = 177
      Width = 239
      Height = 148
    end
    object Label5: TLabel
      Left = 16
      Top = 181
      Width = 97
      Height = 13
      Caption = #1056#1077#1078#1080#1084' '#1080#1085#1092#1086#1088#1084#1072#1094#1080#1080
    end
    object Label6: TLabel
      Left = 58
      Top = 203
      Width = 101
      Height = 13
      Caption = #1044#1083#1080#1085#1072' '#1082#1072#1076#1088#1072' ('#1073#1072#1081#1090')'
    end
    object Label9: TLabel
      Left = 16
      Top = 227
      Width = 75
      Height = 13
      Caption = #1058#1080#1087' '#1087#1088#1086#1090#1086#1082#1086#1083#1072
    end
    object Label8: TLabel
      Left = 58
      Top = 276
      Width = 183
      Height = 13
      Caption = #1058#1072#1081#1084#1072#1091#1090' '#1087#1086#1090#1086#1082#1086#1074#1086#1075#1086' '#1087#1088#1086#1090#1086#1082#1086#1083#1072' ('#1084#1089')'
    end
    object Label10: TLabel
      Left = 58
      Top = 303
      Width = 131
      Height = 13
      Caption = #1057#1090#1072#1088#1096#1080#1081' '#1073#1072#1081#1090' '#1057#1055' (0, 128)'
    end
    object edDEv: TEdit
      Left = 16
      Top = 32
      Width = 219
      Height = 21
      TabOrder = 0
      Text = 'DEV_name'
    end
    object edInfo: TEdit
      Left = 16
      Top = 72
      Width = 219
      Height = 21
      TabOrder = 1
      Text = #1054#1087#1080#1089#1072#1085#1080#1077' '#1087#1088#1080#1073#1086#1088#1072
    end
    object edAdr: TEdit
      Left = 14
      Top = 119
      Width = 36
      Height = 21
      TabOrder = 2
      Text = '199'
    end
    object edDevider: TEdit
      Left = 14
      Top = 138
      Width = 36
      Height = 21
      TabOrder = 3
      Text = '128'
    end
    object cbWorkTime: TCheckBox
      Left = 16
      Top = 157
      Width = 219
      Height = 17
      Caption = #1050#1086#1084#1072#1085#1076#1072' '#1091#1089#1090#1072#1085#1086#1074#1082#1080' '#1074#1088#1077#1084#1077#1085#1080' '#1088#1072#1073#1086#1090#1099
      TabOrder = 4
    end
    object PanelRam: TPanel
      Left = 8
      Top = 346
      Width = 239
      Height = 231
      BevelOuter = bvLowered
      Caption = 'PanelRam'
      ShowCaption = False
      TabOrder = 6
      object Label15: TLabel
        Left = 50
        Top = 8
        Width = 96
        Height = 13
        Caption = #1044#1083#1080#1085#1072' '#1087#1072#1084#1103#1090#1080' ('#1052#1073')'
      end
      object Label14: TLabel
        Left = 51
        Top = 120
        Width = 183
        Height = 13
        Caption = #1058#1072#1081#1084#1072#1091#1090' '#1087#1086#1090#1086#1082#1086#1074#1086#1075#1086' '#1087#1088#1086#1090#1086#1082#1086#1083#1072' ('#1084#1089')'
      end
      object Label13: TLabel
        Left = 51
        Top = 148
        Width = 131
        Height = 13
        Caption = #1057#1090#1072#1088#1096#1080#1081' '#1073#1072#1081#1090' '#1057#1055' (0, 128)'
      end
      object Label12: TLabel
        Left = 8
        Top = 56
        Width = 75
        Height = 13
        Caption = #1058#1080#1087' '#1087#1088#1086#1090#1086#1082#1086#1083#1072
      end
      object Label11: TLabel
        Left = 8
        Top = 171
        Width = 178
        Height = 13
        Caption = #1058#1080#1087' '#1074#1099#1089#1086#1082#1086#1089#1082#1086#1088#1086#1089#1090#1085#1086#1075#1086' '#1087#1088#1086#1090#1086#1082#1086#1083#1072
      end
      object Label7: TLabel
        Left = 50
        Top = 35
        Width = 101
        Height = 13
        Caption = #1044#1083#1080#1085#1072' '#1082#1072#1076#1088#1072' ('#1073#1072#1081#1090')'
      end
      object edRamSize: TEdit
        Left = 8
        Top = 5
        Width = 36
        Height = 21
        TabOrder = 0
        Text = '10'
      end
      object cbHiprotHbFirst: TCheckBox
        Left = 12
        Top = 210
        Width = 179
        Height = 17
        Caption = #1087#1077#1088#1077#1089#1090#1072#1074#1080#1090#1100' '#1073#1072#1081#1090#1099' '#1074' '#1089#1083#1086#1074#1077
        TabOrder = 1
      end
      object cbHbFirst: TCheckBox
        Left = 12
        Top = 95
        Width = 180
        Height = 17
        Caption = #1087#1077#1088#1077#1089#1090#1072#1074#1080#1090#1100' '#1073#1072#1081#1090#1099' '#1074' '#1089#1083#1086#1074#1077
        TabOrder = 2
      end
      object edRamTimeout: TEdit
        Left = 8
        Top = 117
        Width = 36
        Height = 21
        TabOrder = 3
        Text = '1024'
      end
      object edRamSP: TEdit
        Left = 8
        Top = 145
        Width = 36
        Height = 21
        TabOrder = 4
        Text = '0'
      end
      object cbRamProt: TComboBox
        Left = 8
        Top = 75
        Width = 183
        Height = 21
        Style = csDropDownList
        ItemIndex = 0
        TabOrder = 5
        Text = '1- '#1089#1090#1072#1085#1076#1072#1088#1090#1085#1099#1081' ('#1087#1086#1090#1086#1082#1086#1074#1099#1081')'
        OnChange = cbRamProtChange
        Items.Strings = (
          '1- '#1089#1090#1072#1085#1076#1072#1088#1090#1085#1099#1081' ('#1087#1086#1090#1086#1082#1086#1074#1099#1081')'
          '2- '#1040#1055' ('#1087#1086#1090#1086#1082#1086#1074#1099#1081')'
          '3 - '#1043#1083#1091#1073#1080#1085#1086#1084#1077#1088' '#1056#1055'-45')
      end
      object cbHiRamProt: TComboBox
        Left = 8
        Top = 190
        Width = 183
        Height = 21
        Style = csDropDownList
        ItemIndex = 0
        TabOrder = 6
        Text = '0- '#1053#1077#1090
        Items.Strings = (
          '0- '#1053#1077#1090
          '1- 01-FE'
          '2- 01-FE-01-01')
      end
      object edRamKadr: TEdit
        Left = 8
        Top = 32
        Width = 36
        Height = 21
        TabOrder = 7
        Text = '1024'
      end
    end
    object cbRam: TCheckBox
      Left = 8
      Top = 328
      Width = 100
      Height = 17
      Caption = #1063#1090#1077#1085#1080#1077' '#1087#1072#1084#1103#1090#1080
      Checked = True
      State = cbChecked
      TabOrder = 5
      OnClick = cbRamClick
    end
    object cbbWrkProt: TComboBox
      Left = 16
      Top = 246
      Width = 183
      Height = 21
      Style = csDropDownList
      ItemIndex = 0
      TabOrder = 7
      Text = '1- '#1089#1090#1072#1085#1076#1072#1088#1090#1085#1099#1081' ('#1087#1086#1090#1086#1082#1086#1074#1099#1081')'
      OnChange = cbbWrkProtChange
      Items.Strings = (
        '1- '#1089#1090#1072#1085#1076#1072#1088#1090#1085#1099#1081' ('#1087#1086#1090#1086#1082#1086#1074#1099#1081')'
        '2- '#1059#1057#1054
        '3 - '#1043#1083#1091#1073#1080#1085#1086#1084#1077#1088' '#1056#1055'-45'
        '4- '#1048#1050#1053'-'#1040#1052#1050
        '5- '#1043#1083#1091#1073#1080#1085#1086#1084#1077#1088' '#1047#1074#1091#1082#1086#1074#1086#1081)
    end
    object edWrkTimeout: TEdit
      Left = 16
      Top = 273
      Width = 36
      Height = 21
      TabOrder = 8
      Text = '1024'
    end
    object edWrkSP: TEdit
      Left = 16
      Top = 300
      Width = 36
      Height = 21
      TabOrder = 9
      Text = '0'
    end
    object edWrkKadr: TEdit
      Left = 16
      Top = 200
      Width = 36
      Height = 21
      TabOrder = 10
      Text = '1024'
    end
    object cbByteAddress: TCheckBox
      Left = 18
      Top = 95
      Width = 135
      Height = 18
      Caption = #1041#1072#1081#1090#1086#1074#1072#1103' '#1072#1076#1088#1077#1089#1072#1094#1080#1103
      TabOrder = 11
    end
  end
  object ppM: TPopupActionBar
    OnPopup = ppMPopup
    Left = 352
    Top = 112
    object N3: TMenuItem
      Caption = #1060#1072#1081#1083
      object NOpen: TMenuItem
        Caption = #1054#1090#1082#1088#1099#1090#1100'...'
        OnClick = NOpenClick
      end
      object NSave: TMenuItem
        Caption = #1057#1086#1093#1088#1072#1085#1080#1090#1100' '#1082#1072#1082'...'
        Enabled = False
        OnClick = NSaveClick
      end
      object N1: TMenuItem
        Caption = '-'
      end
      object NTest: TMenuItem
        Caption = #1055#1086#1089#1090#1088#1086#1080#1090#1100' '#1080' '#1087#1088#1086#1074#1077#1088#1080#1090#1100
        OnClick = NTestClick
      end
    end
    object N2: TMenuItem
      Caption = '-'
    end
    object NCopy: TMenuItem
      Caption = #1050#1086#1087#1080#1088#1086#1074#1072#1090#1100
      ShortCut = 16451
      OnClick = NCopyClick
    end
    object NCat: TMenuItem
      Caption = #1042#1099#1088#1077#1079#1072#1090#1100
      ShortCut = 16472
      OnClick = NCatClick
    end
    object NPast: TMenuItem
      Caption = #1042#1089#1090#1072#1074#1080#1090#1100
      ShortCut = 16470
      OnClick = NPastClick
    end
    object NPastAdd: TMenuItem
      Caption = #1044#1086#1073#1072#1074#1080#1090#1100' '#1074' '#1082#1086#1085#1077#1094
      OnClick = NPastAddClick
    end
    object NDel: TMenuItem
      Caption = #1059#1076#1072#1083#1080#1090#1100' '#1074#1099#1073#1088#1072#1085#1085#1099#1077' '
      OnClick = NDelClick
    end
    object N7: TMenuItem
      Caption = '-'
    end
    object NAdd: TMenuItem
      Caption = #1044#1086#1073#1072#1074#1080#1090#1100
      object NAddTree: TMenuItem
        Caption = #1042#1077#1090#1074#1100
        OnClick = NAddTreeClick
      end
      object NAddData: TMenuItem
        Caption = #1044#1072#1085#1085#1099#1077
        OnClick = NAddDataClick
      end
    end
    object upd: TMenuItem
      Caption = #1054#1073#1085#1086#1074#1080#1090#1100
      OnClick = updClick
    end
    object N4: TMenuItem
      Caption = '-'
    end
    object NewAddr: TMenuItem
      Caption = #1040#1076#1088#1077#1089#1086#1074#1072#1090#1100' '#1076#1086#1095#1077#1088#1085#1080#1077
      OnClick = NewAddrClick
    end
  end
  object OpenDialog: TOpenDialog
    DefaultExt = 'xml'
    Filter = #1060#1072#1081#1083' '#1086#1087#1080#1089#1072#1085#1080#1103' '#1087#1088#1080#1073#1086#1088#1072'(*.xml)|*.xml'
    Options = [ofHideReadOnly, ofPathMustExist, ofFileMustExist, ofEnableSizing, ofForceShowHidden]
    Left = 408
    Top = 112
  end
  object SaveDialog: TSaveDialog
    DefaultExt = 'xml'
    Filter = #1060#1072#1081#1083' '#1086#1087#1080#1089#1072#1085#1080#1103' '#1087#1088#1080#1073#1086#1088#1072'(*.xml)|*.xml'
    Options = [ofOverwritePrompt, ofHideReadOnly, ofPathMustExist, ofEnableSizing, ofForceShowHidden]
    Left = 472
    Top = 112
  end
end

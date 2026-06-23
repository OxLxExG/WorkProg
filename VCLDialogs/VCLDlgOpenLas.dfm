object DlgOpenLASDataSet: TDlgOpenLASDataSet
  Left = 0
  Top = 0
  ClientHeight = 378
  ClientWidth = 664
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  Position = poScreenCenter
  TextHeight = 13
  object Splitter2: TSplitter
    Left = 296
    Top = 0
    Height = 337
    ExplicitLeft = 304
    ExplicitTop = 352
    ExplicitHeight = 100
  end
  object pc: TPageControl
    Left = 299
    Top = 0
    Width = 365
    Height = 337
    ActivePage = tshLAS
    Align = alClient
    TabOrder = 0
    TabPosition = tpBottom
    object tshLAS: TTabSheet
      Caption = 'LAS'
      object Inspector: TJvInspector
        Left = 0
        Top = 24
        Width = 357
        Height = 287
        Style = isItemPainter
        Align = alClient
        BevelOuter = bvNone
        Divider = 254
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clWindowText
        Font.Height = -11
        Font.Name = 'Courier'
        Font.Style = []
        ItemHeight = 16
        Painter = Painter
        PopupMenu = PopupMenu
        TabStop = True
        TabOrder = 0
      end
      object Panel: TPanel
        Left = 0
        Top = 0
        Width = 357
        Height = 24
        Align = alTop
        Caption = 'Panel'
        ShowCaption = False
        TabOrder = 1
        DesignSize = (
          357
          24)
        object Label1: TLabel
          Left = 2
          Top = 3
          Width = 62
          Height = 13
          Caption = #1042#1099#1073#1088#1072#1090#1100' Y'
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clWindowText
          Font.Height = -11
          Font.Name = 'Tahoma'
          Font.Style = [fsBold]
          ParentFont = False
        end
        object cbY: TComboBox
          Left = 67
          Top = 0
          Width = 285
          Height = 21
          Style = csDropDownList
          Anchors = [akLeft, akTop, akRight]
          TabOrder = 0
        end
      end
    end
    object tshData: TTabSheet
      Caption = #1044#1072#1085#1085#1099#1077
      ImageIndex = 1
      object DBGrid1: TDBGrid
        Left = 0
        Top = 0
        Width = 357
        Height = 311
        Align = alClient
        DataSource = ds
        TabOrder = 0
        TitleFont.Charset = DEFAULT_CHARSET
        TitleFont.Color = clWindowText
        TitleFont.Height = -11
        TitleFont.Name = 'Tahoma'
        TitleFont.Style = []
      end
    end
  end
  object Panelbott: TPanel
    Left = 0
    Top = 337
    Width = 664
    Height = 41
    Align = alBottom
    Alignment = taLeftJustify
    BevelEdges = []
    BevelOuter = bvNone
    Caption = 'Panelbott'
    ShowCaption = False
    TabOrder = 1
    DesignSize = (
      664
      41)
    object btCancel: TButton
      Left = 581
      Top = 8
      Width = 75
      Height = 25
      Anchors = [akRight, akBottom]
      Caption = #1047#1072#1082#1088#1099#1090#1100
      TabOrder = 0
      OnClick = btCancelClick
    end
    object btOK: TButton
      Left = 484
      Top = 8
      Width = 75
      Height = 25
      Anchors = [akRight, akBottom]
      Caption = #1044#1086#1073#1072#1074#1080#1090#1100
      TabOrder = 1
      OnClick = btOKClick
    end
  end
  object PanelL: TPanel
    Left = 0
    Top = 0
    Width = 296
    Height = 337
    Align = alLeft
    Caption = 'PanelL'
    ShowCaption = False
    TabOrder = 2
    object Splitter1: TSplitter
      Left = 146
      Top = 20
      Height = 316
      ExplicitLeft = 168
      ExplicitTop = 72
      ExplicitHeight = 100
    end
    object DriveCombo: TDriveComboBox
      Left = 1
      Top = 1
      Width = 294
      Height = 19
      Align = alTop
      DirList = DirectoryList
      TabOrder = 0
    end
    object DirectoryList: TDirectoryListBox
      Left = 1
      Top = 20
      Width = 145
      Height = 316
      Align = alLeft
      FileList = FileList
      TabOrder = 1
    end
    object FileList: TFileListBox
      Left = 149
      Top = 20
      Width = 146
      Height = 316
      Align = alClient
      ItemHeight = 13
      Mask = '*.las'
      TabOrder = 2
      OnChange = FileListChange
    end
  end
  object ds: TDataSource
    Left = 410
    Top = 204
  end
  object PopupMenu: TPopupMenu
    Left = 466
    Top = 140
    object ANSY1: TMenuItem
      Caption = #1050#1086#1076#1080#1088#1086#1074#1082#1072' ANSY'
      Checked = True
      GroupIndex = 1
      RadioItem = True
      OnClick = EncodeClick
    end
    object NDOS: TMenuItem
      Caption = #1050#1086#1076#1080#1088#1086#1074#1082#1072' DOS'
      GroupIndex = 1
      RadioItem = True
      OnClick = EncodeClick
    end
    object UTF81: TMenuItem
      Caption = #1050#1086#1076#1080#1088#1086#1074#1082#1072' UTF8'
      GroupIndex = 1
      RadioItem = True
      OnClick = EncodeClick
    end
  end
  object Painter: TJvInspectorDotNETPainter
    CategoryFont.Charset = DEFAULT_CHARSET
    CategoryFont.Color = clBtnText
    CategoryFont.Height = -12
    CategoryFont.Name = 'Segoe UI'
    CategoryFont.Style = []
    NameFont.Charset = DEFAULT_CHARSET
    NameFont.Color = clWindowText
    NameFont.Height = -12
    NameFont.Name = 'Segoe UI'
    NameFont.Style = []
    ValueFont.Charset = DEFAULT_CHARSET
    ValueFont.Color = clWindowText
    ValueFont.Height = -12
    ValueFont.Name = 'Segoe UI'
    ValueFont.Style = []
    DrawNameEndEllipsis = False
    HideSelectFont.Charset = DEFAULT_CHARSET
    HideSelectFont.Color = clHighlightText
    HideSelectFont.Height = -12
    HideSelectFont.Name = 'Segoe UI'
    HideSelectFont.Style = []
    SelectedFont.Charset = DEFAULT_CHARSET
    SelectedFont.Color = clHighlightText
    SelectedFont.Height = -12
    SelectedFont.Name = 'Segoe UI'
    SelectedFont.Style = []
    Left = 400
    Top = 136
  end
end

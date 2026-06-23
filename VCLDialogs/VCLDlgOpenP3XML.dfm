object DlgOpenP3DataSet: TDlgOpenP3DataSet
  Left = 0
  Top = 0
  ClientHeight = 411
  ClientWidth = 647
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
    Height = 378
    ExplicitLeft = 304
    ExplicitTop = 192
    ExplicitHeight = 100
  end
  object pc: TPageControl
    Left = 299
    Top = 0
    Width = 348
    Height = 378
    ActivePage = tshSelParam
    Align = alClient
    PopupMenu = PopupMenu
    TabOrder = 0
    TabPosition = tpBottom
    object tshSelDir: TTabSheet
      Caption = #1055#1091#1090#1100
      ImageIndex = 1
      inline FrameSelectPath: TFrameSelectPath
        Left = 0
        Top = 0
        Width = 340
        Height = 352
        Align = alClient
        TabOrder = 0
        ExplicitWidth = 340
        ExplicitHeight = 352
        inherited Tree: TVirtualStringTree
          Width = 340
          Height = 352
          Header.Height = 13
          ExplicitWidth = 340
          ExplicitHeight = 352
          Columns = <
            item
              Position = 0
              Style = vsOwnerDraw
              Text = #1055#1091#1090#1100
              Width = 334
            end>
        end
      end
    end
    object tshSelParam: TTabSheet
      Caption = #1055#1072#1088#1072#1084#1077#1090#1088#1099
      object Panel: TPanel
        Left = 0
        Top = 0
        Width = 340
        Height = 24
        Align = alTop
        Caption = 'Panel'
        ShowCaption = False
        TabOrder = 0
        DesignSize = (
          340
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
          Width = 268
          Height = 21
          Style = csDropDownList
          Anchors = [akLeft, akTop, akRight]
          TabOrder = 0
        end
      end
      inline FrameSelectParam1: TFrameSelectParam
        Left = 0
        Top = 24
        Width = 340
        Height = 328
        Align = alClient
        TabOrder = 1
        ExplicitTop = 24
        ExplicitWidth = 340
        ExplicitHeight = 328
        inherited Tree: TVirtualStringTree
          Width = 340
          Height = 328
          Header.Height = 13
          ExplicitWidth = 340
          ExplicitHeight = 328
          Columns = <
            item
              MaxWidth = 24
              MinWidth = 24
              Options = [coAllowClick, coDraggable, coEnabled, coParentBidiMode, coParentColor, coResizable, coShowDropMark, coVisible]
              Position = 0
              Text = 'D'
              Width = 24
            end
            item
              MaxWidth = 24
              MinWidth = 24
              Options = [coAllowClick, coDraggable, coEnabled, coParentBidiMode, coParentColor, coResizable, coShowDropMark, coVisible]
              Position = 1
              Text = 'C'
              Width = 24
            end
            item
              Position = 2
              Text = #1048#1084#1103
              Width = 286
            end>
        end
      end
    end
    object tshData: TTabSheet
      Caption = #1057#1084#1086#1090#1088#1077#1090#1100' '#1076#1072#1085#1085#1099#1077
      ImageIndex = 1
      object DBGrid1: TDBGrid
        Left = 0
        Top = 0
        Width = 340
        Height = 352
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
    Top = 378
    Width = 647
    Height = 33
    Align = alBottom
    Alignment = taLeftJustify
    BevelEdges = []
    BevelOuter = bvNone
    Caption = 'Panelbott'
    ShowCaption = False
    TabOrder = 1
    DesignSize = (
      647
      33)
    object btCancel: TButton
      Left = 564
      Top = 8
      Width = 75
      Height = 25
      Anchors = [akRight, akBottom]
      Caption = #1047#1072#1082#1088#1099#1090#1100
      TabOrder = 0
      OnClick = btCancelClick
    end
    object btOK: TButton
      Left = 475
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
    Height = 378
    Align = alLeft
    Caption = 'PanelL'
    ShowCaption = False
    TabOrder = 2
    object Splitter1: TSplitter
      Left = 146
      Top = 20
      Height = 357
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
      Height = 357
      Align = alLeft
      FileList = FileList
      TabOrder = 1
    end
    object FileList: TFileListBox
      Left = 149
      Top = 20
      Width = 146
      Height = 357
      Align = alClient
      ItemHeight = 13
      Mask = '*.XML*'
      TabOrder = 2
      OnChange = FileListChange
    end
  end
  object ds: TDataSource
    Left = 386
    Top = 140
  end
  object PopupMenu: TPopupMenu
    Left = 466
    Top = 140
    object NObjectView: TMenuItem
      AutoCheck = True
      Caption = #1054#1073#1098#1077#1082#1090#1085#1099#1077' '#1087#1086#1083#1103
      Checked = True
    end
  end
end

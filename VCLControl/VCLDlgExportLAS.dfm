object FormExportLASP3: TFormExportLASP3
  Left = 0
  Top = 0
  ClientHeight = 465
  ClientWidth = 340
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  DesignSize = (
    340
    465)
  TextHeight = 13
  object pc: TPageControl
    Left = 8
    Top = 8
    Width = 324
    Height = 393
    ActivePage = tshSelDir
    Anchors = [akLeft, akTop, akRight, akBottom]
    TabOrder = 0
    TabPosition = tpBottom
    object tshSelDir: TTabSheet
      Caption = #1055#1091#1090#1100
      ImageIndex = 1
      inline FrameSelectPath: TSelectPathFrm
        Left = 0
        Top = 0
        Width = 316
        Height = 367
        Align = alClient
        TabOrder = 0
        ExplicitWidth = 316
        ExplicitHeight = 367
        inherited Tree: TVirtualStringTree
          Width = 316
          Height = 367
          Header.Height = 13
          ExplicitWidth = 316
          ExplicitHeight = 367
          Columns = <
            item
              Position = 0
              Style = vsOwnerDraw
              Text = #1055#1091#1090#1100
              Width = 310
            end>
        end
      end
    end
    object tshSelParam: TTabSheet
      Caption = #1055#1072#1088#1072#1084#1077#1090#1088#1099
      inline FrameSelectParam: TFrameSelectParam
        Left = 0
        Top = 0
        Width = 316
        Height = 367
        Align = alClient
        TabOrder = 0
        ExplicitWidth = 316
        ExplicitHeight = 367
        inherited Tree: TVirtualStringTree
          Width = 316
          Height = 367
          Header.Height = 13
          ExplicitWidth = 316
          ExplicitHeight = 367
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
              Text = 'Name'
              Width = 262
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
        Width = 316
        Height = 367
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
    object tshLas: TTabSheet
      Caption = #1057#1074#1086#1081#1089#1090#1074#1072' '
      ImageIndex = 3
      OnShow = tshLasShow
      DesignSize = (
        316
        367)
      object Label4: TLabel
        Left = 7
        Top = 56
        Width = 56
        Height = 13
        Caption = #1050#1086#1076#1080#1088#1086#1074#1082#1072
      end
      object Label1: TLabel
        Left = 3
        Top = 7
        Width = 26
        Height = 13
        Caption = #1060#1072#1081#1083
      end
      object Label2: TLabel
        Left = 134
        Top = 56
        Width = 122
        Height = 13
        Caption = #1058#1086#1095#1085#1086#1089#1090#1100' '#1087#1086' '#1091#1084#1086#1083#1095#1072#1085#1080#1102
      end
      object cb: TComboBox
        Left = 7
        Top = 75
        Width = 121
        Height = 22
        Style = csOwnerDrawFixed
        ItemIndex = 0
        TabOrder = 0
        Text = 'ANSI'
        Items.Strings = (
          'ANSI'
          'DOS'
          'UTF8')
      end
      object od: TJvFilenameEdit
        Left = 7
        Top = 26
        Width = 296
        Height = 21
        OnBeforeDialog = odBeforeDialog
        DialogKind = dkSave
        DefaultExt = 'bin'
        Filter = 'LAS '#1092#1072#1081#1083' (*.LAS)|*.LAS'
        DialogOptions = [ofOverwritePrompt, ofHideReadOnly, ofPathMustExist]
        DirectInput = False
        Anchors = [akLeft, akTop, akRight]
        TabOrder = 1
        Text = ''
      end
      object Memo: TMemo
        Left = 7
        Top = 255
        Width = 296
        Height = 111
        Anchors = [akLeft, akTop, akRight, akBottom]
        ScrollBars = ssVertical
        TabOrder = 2
      end
      inline RangeSelect: TFrameRangeSelect
        Left = 7
        Top = 103
        Width = 292
        Height = 122
        Anchors = [akLeft, akTop, akRight]
        AutoSize = True
        TabOrder = 3
        ExplicitLeft = 7
        ExplicitTop = 103
        ExplicitWidth = 292
        ExplicitHeight = 122
        inherited lbBegin: TLabel
          Width = 37
          Height = 13
          StyleElements = [seFont, seClient, seBorder]
          ExplicitWidth = 37
          ExplicitHeight = 13
        end
        inherited lbEnd: TLabel
          Width = 31
          Height = 13
          StyleElements = [seFont, seClient, seBorder]
          ExplicitWidth = 31
          ExplicitHeight = 13
        end
        inherited lbCnt: TLabel
          Width = 35
          Height = 13
          StyleElements = [seFont, seClient, seBorder]
          ExplicitWidth = 35
          ExplicitHeight = 13
        end
        inherited lbKaBegin: TLabel
          Height = 13
          StyleElements = [seFont, seClient, seBorder]
          ExplicitHeight = 13
        end
        inherited lbKaCnt: TLabel
          Height = 13
          StyleElements = [seFont, seClient, seBorder]
          ExplicitHeight = 13
        end
        inherited lbKaEnd: TLabel
          Height = 13
          StyleElements = [seFont, seClient, seBorder]
          ExplicitHeight = 13
        end
        inherited Label1: TLabel
          Width = 70
          Height = 13
          StyleElements = [seFont, seClient, seBorder]
          ExplicitWidth = 70
          ExplicitHeight = 13
        end
        inherited Label2: TLabel
          Width = 58
          Height = 13
          StyleElements = [seFont, seClient, seBorder]
          ExplicitWidth = 58
          ExplicitHeight = 13
        end
        inherited Label3: TLabel
          Width = 33
          Height = 13
          StyleElements = [seFont, seClient, seBorder]
          ExplicitWidth = 33
          ExplicitHeight = 13
        end
        inherited Range: TRangeSelector
          Width = 292
          ExplicitWidth = 292
        end
        inherited edOtnBegin: TMaskEdit
          StyleElements = [seFont, seClient, seBorder]
        end
        inherited edOtnEnd: TMaskEdit
          StyleElements = [seFont, seClient, seBorder]
        end
        inherited edOtnCnt: TMaskEdit
          StyleElements = [seFont, seClient, seBorder]
        end
        inherited edGlobBegin: TMaskEdit
          StyleElements = [seFont, seClient, seBorder]
        end
        inherited edGlobEnd: TMaskEdit
          StyleElements = [seFont, seClient, seBorder]
        end
      end
      object lbAq: TEdit
        Left = 195
        Top = 75
        Width = 61
        Height = 21
        TabOrder = 4
        Text = '2'
        OnExit = cbUnqClick
      end
      object lbDg: TEdit
        Left = 134
        Top = 75
        Width = 60
        Height = 21
        TabOrder = 5
        Text = '10'
        OnExit = cbUnqClick
      end
      object cbUnq: TCheckBox
        Left = 7
        Top = 232
        Width = 208
        Height = 17
        Caption = #1059#1073#1080#1088#1072#1090#1100' '#1090#1086#1083#1100#1082#1086' '#1086#1076#1080#1085#1072#1082#1086#1074#1099#1077' '#1087#1091#1090#1080
        Checked = True
        State = cbChecked
        TabOrder = 6
        OnClick = cbUnqClick
      end
      object cbKadr: TCheckBox
        Left = 221
        Top = 232
        Width = 48
        Height = 17
        Caption = #1087#1086' ID'
        TabOrder = 7
        Visible = False
        OnClick = cbUnqClick
      end
    end
  end
  object btCancel: TButton
    Left = 257
    Top = 415
    Width = 75
    Height = 25
    Anchors = [akRight, akBottom]
    Caption = #1047#1072#1082#1088#1099#1090#1100
    TabOrder = 1
    OnClick = btCancelClick
  end
  object btOK: TButton
    Left = 152
    Top = 414
    Width = 75
    Height = 25
    Anchors = [akRight, akBottom]
    Caption = #1057#1086#1079#1076#1072#1090#1100
    TabOrder = 2
    OnClick = btOKClick
  end
  object sb: TStatusBar
    Left = 0
    Top = 446
    Width = 340
    Height = 19
    Panels = <
      item
        Width = 50
      end
      item
        Width = 50
      end
      item
        Width = 50
      end
      item
        Width = 50
      end
      item
        Width = 50
      end>
  end
  object ds: TDataSource
    Left = 266
    Top = 492
  end
end

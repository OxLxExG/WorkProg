object FormAddGl1ToLAS: TFormAddGl1ToLAS
  Left = 0
  Top = 0
  Caption = 'FormAddGl1ToLAS'
  ClientHeight = 549
  ClientWidth = 479
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -12
  Font.Name = 'Segoe UI'
  Font.Style = []
  Position = poMainFormCenter
  DesignSize = (
    479
    549)
  TextHeight = 15
  object lLas: TLabel
    Left = 8
    Top = 8
    Width = 75
    Height = 15
    Caption = 'Select LAS File'
  end
  object lGl: TLabel
    Left = 8
    Top = 53
    Width = 73
    Height = 15
    Caption = 'Select GL1 file'
  end
  object ldDelta: TLabel
    Left = 8
    Top = 111
    Width = 37
    Height = 15
    Caption = 'ldDelta'
  end
  object fneLAS: TJvFilenameEdit
    Left = 8
    Top = 24
    Width = 463
    Height = 23
    OnAfterDialog = fneLASAfterDialog
    DefaultExt = 'las'
    Filter = 'LAS File (*.las)|*.las'
    DialogOptions = [ofHideReadOnly, ofPathMustExist]
    DialogTitle = 'open LAS file'
    DirectInput = False
    Anchors = [akLeft, akTop, akRight]
    TabOrder = 0
    Text = ''
  end
  object fneGL1: TJvFilenameEdit
    Left = 8
    Top = 66
    Width = 463
    Height = 23
    OnAfterDialog = fneGL1AfterDialog
    DefaultExt = 'gl1'
    Filter = 'Gl1 file (*.gl1)|*.gl1'
    DialogOptions = [ofHideReadOnly, ofPathMustExist]
    DialogTitle = 'Open GL1 file'
    DirectInput = False
    Anchors = [akLeft, akTop, akRight]
    TabOrder = 1
    Text = ''
  end
  object btRUN: TButton
    Left = 144
    Top = 131
    Width = 75
    Height = 25
    Caption = 'RUN'
    TabOrder = 2
    OnClick = btRUNClick
  end
  object pc: TPageControl
    Left = 8
    Top = 176
    Width = 463
    Height = 365
    ActivePage = tshLAS
    Anchors = [akLeft, akTop, akRight, akBottom]
    TabOrder = 3
    object tshLAS: TTabSheet
      Caption = 'LAS'
      object dbgLas: TDBGrid
        Left = 0
        Top = 0
        Width = 455
        Height = 335
        Align = alClient
        DataSource = dsLAS
        TabOrder = 0
        TitleFont.Charset = DEFAULT_CHARSET
        TitleFont.Color = clWindowText
        TitleFont.Height = -12
        TitleFont.Name = 'Segoe UI'
        TitleFont.Style = []
      end
    end
    object tshGL: TTabSheet
      Caption = 'GL1'
      ImageIndex = 1
      object dbgGl: TDBGrid
        Left = 0
        Top = 0
        Width = 455
        Height = 335
        Align = alClient
        DataSource = dsGL1
        TabOrder = 0
        TitleFont.Charset = DEFAULT_CHARSET
        TitleFont.Color = clWindowText
        TitleFont.Height = -12
        TitleFont.Name = 'Segoe UI'
        TitleFont.Style = []
      end
    end
  end
  object edDelta: TEdit
    Left = 8
    Top = 132
    Width = 121
    Height = 23
    TabOrder = 4
    Text = '0'
  end
  object dsLAS: TDataSource
    Left = 58
    Top = 332
  end
  object dsGL1: TDataSource
    Left = 106
    Top = 332
  end
end

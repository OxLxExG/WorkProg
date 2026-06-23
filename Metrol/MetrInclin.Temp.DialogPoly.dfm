object DialogPoly: TDialogPoly
  Left = 0
  Top = 0
  Caption = 'DialogPoly'
  ClientHeight = 333
  ClientWidth = 964
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -12
  Font.Name = 'Segoe UI'
  Font.Style = []
  TextHeight = 15
  object mmo: TMemo
    Left = 0
    Top = 41
    Width = 964
    Height = 292
    Align = alClient
    Font.Charset = RUSSIAN_CHARSET
    Font.Color = clWindowText
    Font.Height = -12
    Font.Name = 'Courier New'
    Font.Style = []
    ParentFont = False
    ScrollBars = ssVertical
    TabOrder = 0
  end
  object pb: TPanel
    Left = 0
    Top = 0
    Width = 964
    Height = 41
    Align = alTop
    BevelEdges = []
    BevelOuter = bvNone
    Caption = 'pb'
    ShowCaption = False
    TabOrder = 1
    DesignSize = (
      964
      41)
    object btnClose: TButton
      Left = 881
      Top = 6
      Width = 75
      Height = 25
      Anchors = [akRight]
      Caption = 'Close'
      TabOrder = 0
      OnClick = btnCloseClick
    end
    object btnLS: TButton
      Left = 39
      Top = 10
      Width = 41
      Height = 25
      Caption = 'LS'
      TabOrder = 1
      OnClick = btnLSClick
    end
    object btnRunAmp: TButton
      Left = 86
      Top = 10
      Width = 75
      Height = 25
      Caption = 'LMAmp'
      TabOrder = 2
      OnClick = btnRunAmpClick
    end
    object btnLMZU: TButton
      Left = 167
      Top = 10
      Width = 48
      Height = 25
      Caption = 'LMZU'
      TabOrder = 3
      OnClick = btnLMZUClick
    end
    object chkV: TCheckBox
      Left = 0
      Top = -1
      Width = 33
      Height = 12
      Caption = 'cV'
      TabOrder = 4
      OnClick = chkVClick
    end
    object chkZ: TCheckBox
      Left = -1
      Top = 10
      Width = 33
      Height = 17
      Caption = 'cZ'
      TabOrder = 5
      OnClick = chkZClick
    end
    object chkA: TCheckBox
      Left = -1
      Top = 24
      Width = 33
      Height = 17
      Caption = 'cM'
      TabOrder = 6
      OnClick = chkAClick
    end
    object btnClr: TButton
      Left = 830
      Top = 8
      Width = 45
      Height = 21
      Anchors = [akRight]
      Caption = 'Clear'
      TabOrder = 7
      OnClick = btnClrClick
    end
    object btnT: TButton
      Left = 215
      Top = 10
      Width = 34
      Height = 25
      Caption = 'T'
      TabOrder = 8
      OnClick = btnTClick
    end
    object btnKos: TButton
      Left = 255
      Top = 10
      Width = 34
      Height = 25
      Caption = 'Kos'
      TabOrder = 9
      OnClick = btnKosClick
    end
    object btnKosv2: TButton
      Left = 295
      Top = 10
      Width = 34
      Height = 25
      Caption = 'KsV2'
      TabOrder = 10
      OnClick = btnKosv2Click
    end
    object btnClrSe: TButton
      Left = 779
      Top = 8
      Width = 45
      Height = 21
      Anchors = [akRight]
      Caption = 'ClrSE'
      TabOrder = 11
      OnClick = btnClrSeClick
    end
  end
end

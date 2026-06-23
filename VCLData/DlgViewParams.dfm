object FormSelectViewParams: TFormSelectViewParams
  Left = 0
  Top = 0
  BorderStyle = bsSizeToolWin
  Caption = #1042#1099#1073#1088#1072#1090#1100' '#1087#1072#1088#1072#1084#1077#1090#1088#1099
  ClientHeight = 515
  ClientWidth = 200
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  OldCreateOrder = False
  DesignSize = (
    200
    515)
  PixelsPerInch = 96
  TextHeight = 13
  object btApply: TButton
    Left = 96
    Top = 482
    Width = 75
    Height = 25
    Anchors = [akLeft, akBottom]
    Caption = #1055#1088#1080#1084#1077#1085#1080#1090#1100
    Enabled = False
    TabOrder = 0
    OnClick = btApplyClick
  end
  object btExit: TButton
    Left = 8
    Top = 482
    Width = 75
    Height = 25
    Anchors = [akLeft, akBottom]
    Caption = #1042#1099#1093#1086#1076
    TabOrder = 1
    OnClick = btExitClick
  end
  object clb: TCheckListBox
    Left = 8
    Top = 8
    Width = 184
    Height = 468
    OnClickCheck = clbClickCheck
    Anchors = [akLeft, akTop, akRight, akBottom]
    ItemHeight = 13
    TabOrder = 2
  end
end

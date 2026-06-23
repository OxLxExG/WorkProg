object FormCalendar: TFormCalendar
  Left = 0
  Top = 0
  BorderStyle = bsNone
  Caption = #1059#1089#1090#1072#1085#1086#1074#1082#1072' '#1076#1072#1090#1099
  ClientHeight = 162
  ClientWidth = 162
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  OldCreateOrder = False
  OnMouseEnter = FormMouseEnter
  OnMouseLeave = FormMouseLeave
  PixelsPerInch = 96
  TextHeight = 13
  object MonthCalendar: TMonthCalendar
    Left = 0
    Top = 0
    Width = 162
    Height = 160
    Date = 41400.696975138890000000
    TabOrder = 0
    OnClick = MonthCalendarClick
    OnMouseEnter = FormMouseEnter
    OnMouseLeave = FormMouseLeave
  end
  object Timer1: TTimer
    Enabled = False
    Interval = 100
    OnTimer = Timer1Timer
    Left = 40
    Top = 40
  end
end

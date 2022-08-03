object fHostForm: TfHostForm
  Left = 0
  Top = 0
  BorderStyle = bsDialog
  Caption = 'Test'
  ClientHeight = 441
  ClientWidth = 624
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -12
  Font.Name = 'Segoe UI'
  Font.Style = []
  OnCreate = FormCreate
  OnDestroy = FormDestroy
  PixelsPerInch = 96
  TextHeight = 15
  object ProgressTimer: TTimer
    Enabled = False
    Interval = 50
    OnTimer = ProgressTimerTimer
    Left = 168
    Top = 168
  end
end

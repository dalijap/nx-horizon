object MainForm: TMainForm
  Left = 0
  Top = 0
  Caption = 'NX Horizon Basic Demo'
  ClientHeight = 480
  ClientWidth = 640
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  OldCreateOrder = True
  Position = poScreenCenter
  OnCreate = FormCreate
  OnDestroy = FormDestroy
  PixelsPerInch = 96
  TextHeight = 13
  object Panel1: TPanel
    Left = 0
    Top = 0
    Width = 640
    Height = 41
    Align = alTop
    TabOrder = 0
    object TextBtn: TButton
      Left = 104
      Top = 10
      Width = 80
      Height = 25
      Caption = 'Send Text'
      TabOrder = 1
      OnClick = TextBtnClick
    end
    object ThreadBtn: TButton
      Left = 9
      Top = 10
      Width = 80
      Height = 25
      Caption = 'Start Thread'
      TabOrder = 0
      OnClick = ThreadBtnClick
    end
  end
  object Memo1: TMemo
    Left = 0
    Top = 41
    Width = 640
    Height = 439
    Align = alClient
    ScrollBars = ssVertical
    TabOrder = 1
  end
  object Timer1: TTimer
    OnTimer = Timer1Timer
    Left = 568
    Top = 56
  end
end

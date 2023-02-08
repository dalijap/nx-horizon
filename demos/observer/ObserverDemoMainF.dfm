object MainForm: TMainForm
  Left = 2500
  Top = 400
  Caption = 'NX Horizon Observer Demo'
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
    object NewBtn: TButton
      Left = 193
      Top = 10
      Width = 110
      Height = 25
      Caption = 'New Observer'
      TabOrder = 2
      OnClick = NewBtnClick
    end
    object TextBtn: TButton
      Left = 448
      Top = 10
      Width = 75
      Height = 25
      Caption = 'Send Text'
      TabOrder = 4
      OnClick = TextBtnClick
    end
    object DataBtn: TButton
      Left = 529
      Top = 10
      Width = 75
      Height = 25
      Caption = 'Send Data'
      TabOrder = 5
      OnClick = DataBtnClick
    end
    object StartBtn: TButton
      Left = 8
      Top = 10
      Width = 75
      Height = 25
      Caption = 'Start'
      TabOrder = 0
      OnClick = StartBtnClick
    end
    object StopBtn: TButton
      Left = 89
      Top = 10
      Width = 75
      Height = 25
      Caption = 'Stop'
      TabOrder = 1
      OnClick = StopBtnClick
    end
    object ClearBtn: TButton
      Left = 309
      Top = 10
      Width = 110
      Height = 25
      Caption = 'Clear Observers'
      TabOrder = 3
      OnClick = ClearBtnClick
    end
  end
  object Panel2: TPanel
    Left = 0
    Top = 41
    Width = 640
    Height = 439
    Align = alClient
    TabOrder = 1
  end
  object Timer1: TTimer
    OnTimer = Timer1Timer
    Left = 572
    Top = 60
  end
end

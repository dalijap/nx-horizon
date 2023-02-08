unit BasicDemoMainF;

interface

uses
  System.SysUtils,
  System.Classes,
  Vcl.Graphics,
  Vcl.Controls,
  Vcl.Forms,
  Vcl.StdCtrls,
  Vcl.ExtCtrls,
  NX.Horizon;

type
  TTextEvent = type string;
  TDataEvent = type Integer;

  TMainForm = class(TForm)
    Panel1: TPanel;
    ThreadBtn: TButton;
    TextBtn: TButton;
    Timer1: TTimer;
    Memo1: TMemo;
    procedure TextBtnClick(Sender: TObject);
    procedure Timer1Timer(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure ThreadBtnClick(Sender: TObject);
  private
  public
    TextSub: INxEventSubscription;
    DataSub: INxEventSubscription;
    TimerCount: Integer;
    ThreadCount: Integer;
    procedure ProcessTextEvent(const aEvent: TTextEvent);
    procedure ProcessDataEvent(const aEvent: TDataEvent);
  end;

var
  MainForm: TMainForm;

implementation

{$R *.dfm}

procedure TMainForm.FormCreate(Sender: TObject);
begin
  // subscribe form to text and data events
  // text event can be dispatched from background thread
  // and MainAsync mode will assure that event handler
  // ProcessTextEvent runs in the context of the main thread
  TextSub := NxHorizon.Instance.Subscribe<TTextEvent>(MainAsync, ProcessTextEvent);
  DataSub := NxHorizon.Instance.Subscribe<TDataEvent>(Sync, ProcessDataEvent);
end;

procedure TMainForm.FormDestroy(Sender: TObject);
begin
  // This is asynchronous subscription and we need to
  // wait for processing of all dispatched events
  NxHorizon.Instance.WaitAndUnsubscribe(TextSub);
  // This is synchronous subscription and code that triggers it
  // runs in the context of the main thread so we
  // can just unsubscribe without waiting as event handler
  // cannot run on already destroyed form
  NxHorizon.Instance.Unsubscribe(DataSub);
end;

procedure TMainForm.TextBtnClick(Sender: TObject);
begin
  NxHorizon.Instance.Post<TTextEvent>('Text button clicked');
end;

procedure TMainForm.ThreadBtnClick(Sender: TObject);
var 
  LThreadCount: Integer;
begin
  Inc(ThreadCount);
  LThreadCount := ThreadCount;
  TThread.CreateAnonymousThread(
    procedure
    var
      i: Integer;
    begin
      NxHorizon.Instance.Post<TTextEvent>('Thread ' + LThreadCount.ToString + ' started');
      Sleep(200);
      for i := 0 to 10 do
        begin
          Sleep(100);
          NxHorizon.Instance.Post<TTextEvent>('Thread ' + LThreadCount.ToString + ' step ' + i.ToString);
        end;
      NxHorizon.Instance.Post<TTextEvent>('Thread ' + LThreadCount.ToString + ' finished');
    end).Start;
end;

procedure TMainForm.Timer1Timer(Sender: TObject);
begin
  Inc(TimerCount);
  NxHorizon.Instance.Post<TDataEvent>(TimerCount);
end;

procedure TMainForm.ProcessDataEvent(const aEvent: TDataEvent);
begin
  Memo1.Lines.Add(Integer(aEvent).ToString);
end;

procedure TMainForm.ProcessTextEvent(const aEvent: TTextEvent);
begin
  Memo1.Lines.Add(aEvent);
end;

end.

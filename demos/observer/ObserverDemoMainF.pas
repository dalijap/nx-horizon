unit ObserverDemoMainF;

interface

uses
  Winapi.Windows,
  System.SysUtils,
  System.Classes,
  System.TypInfo,
  Vcl.Graphics,
  Vcl.Controls,
  Vcl.Dialogs,
  Vcl.Forms,
  NX.Horizon,
  Vcl.StdCtrls,
  Vcl.ExtCtrls;

type
  TDataEvent = type string;
  TTextEvent = type string;

  TObservable = class
  protected
    fHorizon: INxHorizon;
  public
    constructor Create;
    destructor Destroy; override;
    property Horizon: INxHorizon read fHorizon;
  end;

  TComponentObserver = class(TPanel)
  protected
    fObservable: INxHorizon;
    fShutDownSub: INxEventSubscription;
    fDataSub: INxEventSubscription;
    fTextSub: INxEventSubscription;
  public
    destructor Destroy; override;
    procedure Observe(const aObservable: INxHorizon);
    procedure ProcessShutDownEvent(const aEvent: TNxHorizonShutDownEvent);
    procedure ProcessDataEvent(const aEvent: TDataEvent);
    procedure ProcessTextEvent(const aEvent: TTextEvent);
    procedure ProcessAsyncDataEvent(const aEvent: TDataEvent);
    procedure ProcessAsyncTextEvent(const aEvent: TTextEvent);
  end;

  TMainForm = class(TForm)
    Panel1: TPanel;
    NewBtn: TButton;
    Panel2: TPanel;
    TextBtn: TButton;
    DataBtn: TButton;
    StartBtn: TButton;
    StopBtn: TButton;
    Timer1: TTimer;
    ClearBtn: TButton;
    procedure NewBtnClick(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure TextBtnClick(Sender: TObject);
    procedure DataBtnClick(Sender: TObject);
    procedure StartBtnClick(Sender: TObject);
    procedure StopBtnClick(Sender: TObject);
    procedure Timer1Timer(Sender: TObject);
    procedure ClearBtnClick(Sender: TObject);
  private
    fObservable: TObservable;
    fData: Integer;
    fTimerCount: Integer;
  public
  end;

var
  MainForm: TMainForm;

implementation

{$R *.dfm}

constructor TObservable.Create;
begin
  fHorizon := TNxHorizonContainer.Create;
end;

destructor TObservable.Destroy;
begin
  fHorizon.ShutDown;
  inherited;
end;

{ TObserver }

destructor TComponentObserver.Destroy;
begin
  if Assigned(fObservable) then
    begin
      fObservable.Instance.WaitAndUnsubscribe(fShutDownSub);
      fObservable.Instance.WaitAndUnsubscribe(fDataSub);
      fObservable.Instance.WaitAndUnsubscribe(fTextSub);
      fObservable := nil;
    end;
  inherited;
end;

procedure TComponentObserver.Observe(const aObservable: INxHorizon);
begin
  if Assigned(fObservable) then Exit;
  fObservable := aObservable;
  fShutDownSub := fObservable.Instance.Subscribe<TNxHorizonShutDownEvent>(Sync, ProcessShutDownEvent);

// MainAsync dispatch will ensure that events are dispatched in the context of the main thread
// and event handlers don't need any synchronization code
//  fDataSub := fObservable.Instance.Subscribe<TDataEvent>(MainAsync, ProcessAsyncDataEvent);
//  fTextSub := fObservable.Instance.Subscribe<TTextEvent>(MainAsync, ProcessAsyncTextEvent);

// Async dispatch will dispatch events from background thread
// and event handlers need to synchronize with the main thread for accessing UI
  fDataSub := fObservable.Instance.Subscribe<TDataEvent>(Async, ProcessAsyncDataEvent);
  fTextSub := fObservable.Instance.Subscribe<TTextEvent>(Async, ProcessAsyncTextEvent);
  Caption := 'Observing';
end;

procedure TComponentObserver.ProcessShutDownEvent(const aEvent: TNxHorizonShutDownEvent);
begin
  // do not unsubscribe here, just clear observable and subscriptions
  fShutDownSub := nil;
// at this point it is possible that some events are dispatched
// but not yet processed
// if you need to make sure that all events are processed
// you need to wait for subscription
//  fDataSub.WaitFor;
  fDataSub := nil;
//  fTextSub.WaitFor;
  fTextSub := nil;
  fObservable := nil;
  Caption := 'ShutDown';
end;

procedure TComponentObserver.ProcessDataEvent(const aEvent: TDataEvent);
begin
  Caption := 'Data: ' + aEvent;
end;

procedure TComponentObserver.ProcessTextEvent(const aEvent: TTextEvent);
begin
  Caption := 'Text: ' + aEvent;
end;

procedure TComponentObserver.ProcessAsyncDataEvent(const aEvent: TDataEvent);
begin
  TThread.Synchronize(nil,
    procedure
    begin
      Caption := 'Data: ' + aEvent;
    end);
end;

procedure TComponentObserver.ProcessAsyncTextEvent(const aEvent: TTextEvent);
begin
  TThread.Synchronize(nil,
    procedure
    begin
      Caption := 'Text: ' + aEvent;
    end);
end;

procedure TMainForm.FormCreate(Sender: TObject);
begin
  fObservable := TObservable.Create;
  fData := 0;
  fTimerCount := 0;
  // by changing timer interval to a small value like 10 ms
  // you can more easily observe behavior and event processing
  // during shutdown
  Timer1.Interval := 1000;
end;

procedure TMainForm.FormDestroy(Sender: TObject);
begin
  FreeAndNil(fObservable);
end;

procedure TMainForm.NewBtnClick(Sender: TObject);
var
  Observer: TComponentObserver;
begin
  Observer := TComponentObserver.Create(Panel2);
  Observer.Parent := Panel2;
  Observer.Align := TAlign.alTop;
  if Assigned(fObservable) then
    Observer.Observe(fObservable.Horizon);
end;

procedure TMainForm.ClearBtnClick(Sender: TObject);
var
  i: Integer;
begin
  for i := Panel2.ControlCount - 1 downto 0 do
    Panel2.Controls[i].Free;
end;

procedure TMainForm.TextBtnClick(Sender: TObject);
begin
  if Assigned(fObservable) then
    fObservable.Horizon.Instance.Post<TTextEvent>('abc');
end;

procedure TMainForm.Timer1Timer(Sender: TObject);
begin
  inc(fTimerCount);
  if Assigned(fObservable) then
    fObservable.Horizon.Instance.Post<TTextEvent>('timer ' + fTimerCount.ToString);
end;

procedure TMainForm.StartBtnClick(Sender: TObject);
var
  i: Integer;
begin
  if not Assigned(fObservable) then
    begin
      fObservable := TObservable.Create;
      for i := 0 to Panel2.ControlCount - 1 do
        if Panel2.Controls[i] is TComponentObserver then
          TComponentObserver(Panel2.Controls[i]).Observe(fObservable.Horizon);
    end;
end;

procedure TMainForm.StopBtnClick(Sender: TObject);
begin
  FreeAndNil(fObservable);
end;

procedure TMainForm.DataBtnClick(Sender: TObject);
begin
  inc(fData);
  if Assigned(fObservable) then
    fObservable.Horizon.Instance.Post<TDataEvent>(fData.ToString);
end;

end.

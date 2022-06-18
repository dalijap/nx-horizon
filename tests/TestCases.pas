unit TestCases;

interface

uses
  TestFramework,
  System.SyncObjs,
  System.Generics.Collections,
  System.SysUtils,
  System.Types,
  System.TypInfo,
  System.Classes,
  NX.Horizon;

// supporting classes
type
  TStartEvent = type Integer;

  TStopEvent = type Integer;

  TDataEvent = type string;

  TFoo = class
  public
    Data: string;
    constructor Create(const Value: string);
  end;

  TBar = class
  public
    IntData: Integer;
    StrData: string;
    constructor Create(IntValue: Integer; const StrValue: string);
    function Combine: string;
  end;

  TSubcriber = class
  public
    Events: TStrings;
    constructor Create;
    destructor Destroy; override;
    procedure StringEvent(const aEvent: string);
    procedure IntegerEvent(const aEvent: Integer);
    procedure FooEvent(const aEvent: INxEvent<TFoo>);
    procedure BarEvent(const aEvent: INxEvent<TBar>);
  end;

// test cases
type
  TestTNxEventObjectInteger = class(TTestCase)
  published
    procedure TestNew;
  end;

  TestTNxEventObjectString = class(TTestCase)
  published
    procedure TestNew;
  end;

  TestTNxEventObjectRecord = class(TTestCase)
  published
    procedure TestNew;
  end;

  TestTNxEventObjectClass = class(TTestCase)
  published
    procedure TestNew;
  end;

  TestTNxEventInteger = class(TTestCase)
  published
    procedure TestNew;
  end;

  TestTNxEventString = class(TTestCase)
  published
    procedure TestNew;
  end;

  TestTNxEventRecord = class(TTestCase)
  published
    procedure TestNew;
  end;

  TestTNxEventSubscription = class(TTestCase)
  strict private
    sut: INxEventSubscription;
  public
    procedure SetUp; override;
    procedure TearDown; override;
  published
    procedure TestTypes;
    procedure TestBeginWork;
    procedure TestEndWork;
    procedure TestWaitFor;
    procedure TestWaitFor1;
    procedure TestCancel;
    procedure TestGetIsActive;
    procedure TestGetIsCanceled;
  end;

  TestTNxHorizon = class(TTestCase)
  strict private
    sut: TNxHorizon;
    Subscriber: TSubcriber;
  public
    procedure SetUp; override;
    procedure TearDown; override;
  published
    procedure TestSubscribeString;
    procedure TestSubscribeInteger;
    procedure TestSubscribeFoo;
    procedure TestUnsubscribe;
    procedure TestUnsubscribeAsync;
    procedure TestPostSync;
    procedure TestPostAsync;
    procedure TestPostMainSync;
    procedure TestPostMainAsync;
    procedure TestSendSync;
    procedure TestSendAsync;
    procedure TestSendMainSync;
    procedure TestSendMainAsync;
  end;

  TestNxHorizon = class(TTestCase)
  strict private
    sut: NxHorizon;
  public
    procedure TestInstance;
  end;

implementation

// ***** TFoo *****

constructor TFoo.Create(const Value: string);
begin
  Data := Value;
end;

// ***** TBar *****

constructor TBar.Create(IntValue: Integer; const StrValue: string);
begin
  IntData := IntValue;
  StrData := StrValue;
end;

function TBar.Combine: string;
begin
  Result := IntData.ToString + ' ' + StrData;
end;

// ***** TSubcriber *****

constructor TSubcriber.Create;
begin
  Events := TStringList.Create;
end;

destructor TSubcriber.Destroy;
begin
  Events.Free;
  inherited;
end;

procedure TSubcriber.StringEvent(const aEvent: string);
begin
  TMonitor.Enter(Events);
  try
    if TThread.CurrentThread.ThreadID = MainThreadID then
      Events.Add('M ' + aEvent)
    else
      Events.Add('B ' + aEvent)
  finally
    TMonitor.Exit(Events);
  end;
end;

procedure TSubcriber.IntegerEvent(const aEvent: Integer);
begin
  TMonitor.Enter(Events);
  try
    if TThread.CurrentThread.ThreadID = MainThreadID then
      Events.Add('M ' + aEvent.ToString)
    else
      Events.Add('B ' + aEvent.ToString)
  finally
    TMonitor.Exit(Events);
  end;
end;

procedure TSubcriber.FooEvent(const aEvent: INxEvent<TFoo>);
begin
  TMonitor.Enter(Events);
  try
    if TThread.CurrentThread.ThreadID = MainThreadID then
      Events.Add('M ' + aEvent.Value.Data)
    else
      Events.Add('B ' + aEvent.Value.Data)
  finally
    TMonitor.Exit(Events);
  end;
end;

procedure TSubcriber.BarEvent(const aEvent: INxEvent<TBar>);
begin
  TMonitor.Enter(Events);
  try
    if TThread.CurrentThread.ThreadID = MainThreadID then
      Events.Add('M ' + aEvent.Value.Combine)
    else
      Events.Add('B ' + aEvent.Value.Combine)
  finally
    TMonitor.Exit(Events);
  end;
end;

// ***** TestTNxEventObjectInteger *****

procedure TestTNxEventObjectInteger.TestNew;
var
  ReturnValue: INxEvent<Integer>;
  aValue: Integer;
begin
  aValue := 100;
  ReturnValue := TNxEventObject<Integer>.New(aValue);

  CheckNotNull(ReturnValue);
  CheckEquals(aValue, ReturnValue.Value);
end;

// ***** TestTNxEventObjectString *****

procedure TestTNxEventObjectString.TestNew;
var
  ReturnValue: INxEvent<string>;
  aValue: string;
begin
  aValue := 'abc';
  ReturnValue := TNxEventObject<string>.New(aValue);

  CheckNotNull(ReturnValue);
  CheckEquals(aValue, ReturnValue.Value);
end;

// ***** TestTNxEventObjectRecord *****

procedure TestTNxEventObjectRecord.TestNew;
var
  ReturnValue: INxEvent<TPoint>;
  aValue: TPoint;
begin
  aValue := TPoint.Create(100, 200);
  ReturnValue := TNxEventObject<TPoint>.New(aValue);

  CheckNotNull(ReturnValue);
  CheckEquals(aValue.X, ReturnValue.Value.X);
  CheckEquals(aValue.Y, ReturnValue.Value.Y);
end;

// ***** TestTNxEventObjectClass *****

procedure TestTNxEventObjectClass.TestNew;
var
  ReturnValue: INxEvent<TStringList>;
  aValue: TStringList;
begin
  aValue := TStringList.Create;
  aValue.Add('abc');
  aValue.Add('123');
  ReturnValue := TNxEventObject<TStringList>.New(aValue);

  CheckNotNull(ReturnValue);
  CheckEquals(aValue.Count, ReturnValue.Value.Count);
end;

// ***** TestTNxEventInteger *****

procedure TestTNxEventInteger.TestNew;
var
  ReturnValue: TNxEvent<Integer>;
  aValue: Integer;
begin
  aValue := 100;
  ReturnValue := TNxEvent<Integer>.New(aValue);

  CheckEquals(aValue, ReturnValue.Value);
end;

// ***** TestTNxEventString *****

procedure TestTNxEventString.TestNew;
var
  ReturnValue: TNxEvent<string>;
  aValue: string;
begin
  aValue := 'abc';
  ReturnValue := TNxEvent<string>.New(aValue);

  CheckEquals(aValue, ReturnValue.Value);
end;

// ***** TestTNxEventRecord *****

procedure TestTNxEventRecord.TestNew;
var
  ReturnValue: TNxEvent<TPoint>;
  aValue: TPoint;
begin
  aValue := TPoint.Create(100, 200);
  ReturnValue := TNxEvent<TPoint>.New(aValue);

  CheckEquals(aValue.X, ReturnValue.Value.X);
  CheckEquals(aValue.Y, ReturnValue.Value.Y);
end;

// ***** TestTNxEventSubscription *****

type
  PNxEventSubscription = class(TNxEventSubscription);

procedure TestTNxEventSubscription.SetUp;
begin
  inherited;
  sut := TNxEventSubscription.Create(TypeInfo(TObject), Sync, nil);
end;

procedure TestTNxEventSubscription.TearDown;
begin
  sut := nil;
  inherited;
end;

procedure TestTNxEventSubscription.TestTypes;
var 
  aEventInfo: PTypeInfo;
begin
  aEventInfo := TypeInfo(TStartEvent);
  CheckTrue(TypeInfo(TStartEvent) = aEventInfo);
  CheckFalse(TypeInfo(Integer) = aEventInfo);
  CheckFalse(TypeInfo(TStopEvent) = aEventInfo);
  CheckFalse(TypeInfo(TDataEvent) = aEventInfo);

  aEventInfo := TypeInfo(TDataEvent);
  CheckTrue(TypeInfo(TDataEvent) = aEventInfo);
  CheckFalse(TypeInfo(Integer) = aEventInfo);
  CheckFalse(TypeInfo(TStopEvent) = aEventInfo);
  CheckFalse(TypeInfo(string) = aEventInfo);

  aEventInfo := TypeInfo(INxEvent<TFoo>);
  CheckTrue(TypeInfo(INxEvent<TFoo>) = aEventInfo);
  CheckFalse(TypeInfo(INxEvent<TBar>) = aEventInfo);
  CheckFalse(TypeInfo(Integer) = aEventInfo);
  CheckFalse(TypeInfo(TStopEvent) = aEventInfo);
  CheckFalse(TypeInfo(string) = aEventInfo);
end;

procedure TestTNxEventSubscription.TestBeginWork;
var
  ReturnValue: Boolean;
begin
  ReturnValue := sut.BeginWork;
  CheckTrue(ReturnValue);

  sut.EndWork;
  ReturnValue := sut.BeginWork;
  CheckTrue(ReturnValue);

  sut.EndWork;
  sut.EndWork;
  ReturnValue := sut.BeginWork;
  CheckFalse(ReturnValue);
end;

procedure TestTNxEventSubscription.TestEndWork;
var
  Obj: TNxEventSubscription;
begin
  sut.EndWork;

  Obj := TNxEventSubscription(sut);
  CheckTrue(PNxEventSubscription(Obj).fCountdown.IsSet);
end;

// This test will deadlock if it fails
procedure TestTNxEventSubscription.TestWaitFor;
begin
  sut.WaitFor;
  CheckTrue(True);
end;

// This test will deadlock if it fails
procedure TestTNxEventSubscription.TestWaitFor1;
begin
  sut.BeginWork;
  TThread.CreateAnonymousThread(
    procedure
    begin
      Sleep(500);
      sut.EndWork;
    end).Start;
  sut.WaitFor;
  CheckTrue(True);
end;

procedure TestTNxEventSubscription.TestCancel;
begin
  sut.Cancel;

  CheckTrue(sut.IsCanceled);
  CheckFalse(sut.IsActive);
  CheckFalse(sut.BeginWork);
end;

procedure TestTNxEventSubscription.TestGetIsActive;
begin
  CheckTrue(sut.IsActive);
end;

procedure TestTNxEventSubscription.TestGetIsCanceled;
begin
  CheckFalse(sut.IsCanceled);
end;

// ***** TestTNxHorizon *****

type
  PNxHorizon = class(TNxHorizon);

procedure TestTNxHorizon.SetUp;
begin
  sut := TNxHorizon.Create;
  Subscriber := TSubcriber.Create;
end;

procedure TestTNxHorizon.TearDown;
begin
  Subscriber.Free;
  Subscriber := nil;
  sut.Free;
  sut := nil;
end;

procedure TestTNxHorizon.TestSubscribeString;
var
  ReturnValue: INxEventSubscription;
  aObserver: TNxEventMethod<string>;
  aDelivery: TNxHorizonDelivery;

  Obj: PNxEventSubscription;
  Sub: TList<INxEventSubscription>;
begin
  aDelivery := Sync;
  aObserver := Subscriber.StringEvent;

  ReturnValue := sut.Subscribe<string>(aDelivery, aObserver);

  CheckNotNull(ReturnValue);

  Obj := PNxEventSubscription(TNxEventSubscription(ReturnValue));

  CheckTrue(TypeInfo(string) = Obj.fEventInfo);
  CheckTrue(Obj.IsActive);
  CheckTrue(aDelivery = Obj.fDelivery);
  CheckEquals(TMethod(aObserver).Code, TMethod(Obj.fEventMethod).Code);
  CheckEquals(TMethod(aObserver).Data, TMethod(Obj.fEventMethod).Data);

  PNxHorizon(sut).fSubscriptions.TryGetValue(Obj.fEventInfo, Sub);
  CheckNotNull(Sub);
  CheckEquals(1, Sub.Count);
  CheckEquals(Pointer(TObject(ReturnValue)), Pointer(TObject(Sub[0])));
end;

procedure TestTNxHorizon.TestSubscribeInteger;
var
  ReturnValue: INxEventSubscription;
  aObserver: TNxEventMethod<Integer>;
  aDelivery: TNxHorizonDelivery;

  Obj: PNxEventSubscription;
  Sub: TList<INxEventSubscription>;
begin
  aDelivery := Async;
  aObserver := Subscriber.IntegerEvent;

  ReturnValue := sut.Subscribe<Integer>(aDelivery, aObserver);

  CheckNotNull(ReturnValue);

  Obj := PNxEventSubscription(TNxEventSubscription(ReturnValue));

  CheckTrue(TypeInfo(Integer) = Obj.fEventInfo);
  CheckTrue(Obj.IsActive);
  CheckTrue(aDelivery = Obj.fDelivery);
  CheckEquals(TMethod(aObserver).Code, TMethod(Obj.fEventMethod).Code);
  CheckEquals(TMethod(aObserver).Data, TMethod(Obj.fEventMethod).Data);

  PNxHorizon(sut).fSubscriptions.TryGetValue(Obj.fEventInfo, Sub);
  CheckNotNull(Sub);
  CheckEquals(1, Sub.Count);
  CheckEquals(Pointer(TObject(ReturnValue)), Pointer(TObject(Sub[0])));
end;

procedure TestTNxHorizon.TestSubscribeFoo;
var
  ReturnValue: INxEventSubscription;
  aObserver: TNxEventMethod<INxEvent<TFoo>>;
  aDelivery: TNxHorizonDelivery;

  Obj: PNxEventSubscription;
  Sub: TList<INxEventSubscription>;
begin
  aDelivery := MainAsync;
  aObserver := Subscriber.FooEvent;

  ReturnValue := sut.Subscribe<INxEvent<TFoo>>(aDelivery, aObserver);

  CheckNotNull(ReturnValue);

  Obj := PNxEventSubscription(TNxEventSubscription(ReturnValue));

  CheckTrue(TypeInfo(INxEvent<TFoo>) = Obj.fEventInfo);
  CheckTrue(Obj.IsActive);
  CheckTrue(aDelivery = Obj.fDelivery);
  CheckEquals(TMethod(aObserver).Code, TMethod(Obj.fEventMethod).Code);
  CheckEquals(TMethod(aObserver).Data, TMethod(Obj.fEventMethod).Data);

  PNxHorizon(sut).fSubscriptions.TryGetValue(Obj.fEventInfo, Sub);
  CheckNotNull(Sub);
  CheckEquals(1, Sub.Count);
  CheckEquals(Pointer(TObject(ReturnValue)), Pointer(TObject(Sub[0])));
end;

procedure TestTNxHorizon.TestUnsubscribe;
var
  aSubscription: INxEventSubscription;

  aObserver: TNxEventMethod<INxEvent<TFoo>>;
  aDelivery: TNxHorizonDelivery;

  Sub: TList<INxEventSubscription>;
begin
  aDelivery := Sync;
  aObserver := Subscriber.FooEvent;
  aSubscription := sut.Subscribe<INxEvent<TFoo>>(aDelivery, aObserver);

  PNxHorizon(sut).fSubscriptions.TryGetValue(TypeInfo(INxEvent<TFoo>), Sub);
  CheckNotNull(Sub);

  sut.Unsubscribe(aSubscription);
  CheckEquals(0, Sub.Count);
  CheckTrue(aSubscription.IsCanceled);

  aSubscription := sut.Subscribe<INxEvent<TFoo>>(aDelivery, aObserver);
  aSubscription := sut.Subscribe<INxEvent<TFoo>>(aDelivery, aObserver);

  sut.Unsubscribe(aSubscription);
  CheckEquals(1, Sub.Count);
end;

// This test will deadlock if it fails
procedure TestTNxHorizon.TestUnsubscribeAsync;
var
  aSubscription: INxEventSubscription;

  aObserver: TNxEventMethod<INxEvent<TFoo>>;
  aDelivery: TNxHorizonDelivery;

  Sub: TList<INxEventSubscription>;
begin
  aDelivery := Sync;
  aObserver := Subscriber.FooEvent;
  aSubscription := sut.Subscribe<INxEvent<TFoo>>(aDelivery, aObserver);

  PNxHorizon(sut).fSubscriptions.TryGetValue(TypeInfo(INxEvent<TFoo>), Sub);
  CheckNotNull(Sub);

  sut.UnsubscribeAsync(aSubscription);

  while Sub.Count > 0 do
    begin
      Sleep(100);
    end;
  CheckTrue(aSubscription.IsCanceled);
end;

procedure TestTNxHorizon.TestPostSync;
var
  aEvent: Integer;
begin
  sut.Subscribe<Integer>(Sync, Subscriber.IntegerEvent);
  aEvent := 5;
  sut.Post(aEvent);
  CheckEquals(Trim(Subscriber.Events.Text), 'M 5');

  Subscriber.Events.Clear;
  TThread.CreateAnonymousThread(
    procedure
    begin
      sut.Post(aEvent);
    end).Start;
  Sleep(500);
  CheckEquals(Trim(Subscriber.Events.Text), 'B 5');
end;

procedure TestTNxHorizon.TestPostAsync;
var
  aEvent: Integer;
begin
  sut.Subscribe<Integer>(Async, Subscriber.IntegerEvent);
  aEvent := 5;
  sut.Post(aEvent);
  Sleep(500);
  CheckEquals(Trim(Subscriber.Events.Text), 'B 5');
end;

procedure TestTNxHorizon.TestPostMainSync;
var
  aEvent: Integer;
begin
  sut.Subscribe<Integer>(MainSync, Subscriber.IntegerEvent);
  aEvent := 5;
  TThread.CreateAnonymousThread(
    procedure
    begin
      sut.Post(aEvent);
    end).Start;
  Sleep(100);
  CheckSynchronize;
  Sleep(100);
  CheckSynchronize;
  Sleep(100);
  CheckSynchronize;
  CheckEquals(Trim(Subscriber.Events.Text), 'M 5');
end;

procedure TestTNxHorizon.TestPostMainAsync;
var
  aEvent: INXEvent<TFoo>;
begin
  sut.Subscribe<INXEvent<TFoo>>(MainAsync, Subscriber.FooEvent);

  aEvent := TNxEventObject<TFoo>.New(TFoo.Create('abc'));
  TThread.CreateAnonymousThread(
    procedure
    begin
      sut.Post(aEvent);
      sut.Post(TNxEventObject<TBar>.New(TBar.Create(1, 'abc')));
    end).Start;
  Sleep(100);
  CheckSynchronize;
  Sleep(100);
  CheckSynchronize;
  Sleep(100);
  CheckSynchronize;
  CheckEquals(Trim(Subscriber.Events.Text), 'M abc');
end;

procedure TestTNxHorizon.TestSendSync;
var
  aDelivery: TNxHorizonDelivery;
  aEvent: Integer;
begin
  sut.Subscribe<Integer>(Async, Subscriber.IntegerEvent);

  aDelivery := Sync;
  aEvent := 5;
  sut.Send(aEvent, aDelivery);
  CheckEquals(Trim(Subscriber.Events.Text), 'M 5');

  Subscriber.Events.Clear;
  TThread.CreateAnonymousThread(
    procedure
    begin
      sut.Send(aEvent, aDelivery);
    end).Start;
  Sleep(500);
  CheckEquals(Trim(Subscriber.Events.Text), 'B 5');
end;

procedure TestTNxHorizon.TestSendAsync;
var
  aDelivery: TNxHorizonDelivery;
  aEvent: Integer;
begin
  sut.Subscribe<Integer>(Sync, Subscriber.IntegerEvent);

  aDelivery := Async;
  aEvent := 5;
  sut.Send(aEvent, aDelivery);
  Sleep(500);
  CheckEquals(Trim(Subscriber.Events.Text), 'B 5');
end;

procedure TestTNxHorizon.TestSendMainSync;
var
  aDelivery: TNxHorizonDelivery;
  aEvent: Integer;
begin
  sut.Subscribe<Integer>(Sync, Subscriber.IntegerEvent);

  aDelivery := MainSync;
  aEvent := 5;
  TThread.CreateAnonymousThread(
    procedure
    begin
      sut.Send(aEvent, aDelivery);
    end).Start;
  Sleep(100);
  CheckSynchronize;
  Sleep(100);
  CheckSynchronize;
  Sleep(100);
  CheckSynchronize;
  CheckEquals(Trim(Subscriber.Events.Text), 'M 5');
end;

procedure TestTNxHorizon.TestSendMainAsync;
var
  aDelivery: TNxHorizonDelivery;
  aEvent: Integer;
begin
  sut.Subscribe<Integer>(Sync, Subscriber.IntegerEvent);

  aDelivery := MainAsync;
  aEvent := 5;
  TThread.CreateAnonymousThread(
    procedure
    begin
      sut.Send(aEvent, aDelivery);
    end).Start;
  Sleep(100);
  CheckSynchronize;
  Sleep(100);
  CheckSynchronize;
  Sleep(100);
  CheckSynchronize;
  CheckEquals(Trim(Subscriber.Events.Text), 'M 5');
end;

// ***** TestNxHorizon *****

procedure TestNxHorizon.TestInstance;
begin
  CheckNotNull(NxHorizon.Instance);
end;


initialization

  RegisterTest(TestTNxEventObjectInteger.Suite);
  RegisterTest(TestTNxEventObjectString.Suite);
  RegisterTest(TestTNxEventObjectRecord.Suite);
  RegisterTest(TestTNxEventObjectClass.Suite);
  RegisterTest(TestTNxEventInteger.Suite);
  RegisterTest(TestTNxEventString.Suite);
  RegisterTest(TestTNxEventRecord.Suite);
  RegisterTest(TestTNxEventSubscription.Suite);
  RegisterTest(TestTNxHorizon.Suite);
  RegisterTest(TestNxHorizon.Suite);

end.

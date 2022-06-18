(*****************************************************************************
MIT License

Copyright (c) 2021-2022 Dalija Prasnikar

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
******************************************************************************)

unit NX.Horizon;

{$IF CompilerVersion >= 28.0}
  {$DEFINE DELPHI_XE7_UP}
{$ENDIF}

{$IF CompilerVersion >= 32.0}
  {$DEFINE DELPHI_TOKYO_UP}
{$ENDIF}

interface

uses
  {$IFDEF DELPHI_XE7_UP}
  System.Threading,
  {$ENDIF}
  System.SysUtils,
  System.Classes,
  System.Generics.Collections,
  System.TypInfo,
  System.SyncObjs;

type
  INxEvent<T> = interface
    function GetValue: T;
    property Value: T read GetValue;
  end;

  ///	<summary>
  ///	  Generic subscription method - event handler
  ///	</summary>
  ///	<typeparam name="T">
  ///	  Wrapped event type - supports all types
  ///	</typeparam>
  TNxEventMethod<T> = procedure(const aEvent: T) of object;

  ///	<summary>
  ///	  This is specialized method declaration that is used for storing subscription methods
  ///	  When invoking methods, event dispatching makes sure that actual event type matches
  ///	  method event type.
  ///	</summary>
  TNxEventMethod = TNxEventMethod<TObject>;

  ///	<summary>
  ///	  Event delivery options
  ///	</summary>
  ///	<remarks>
  ///	  <para>
  ///	    Sync and MainSync are BLOCKING operations and event handler will execute immediately
  ///	    in the context of the current thread or synchronized with the main thread.
  ///	  </para>
  ///	  <para>
  ///	    This will block dispatching other events using same bus instance until event handler completes. 
  ///     Don't use (or use sparingly only for short executions) on global horizon instance.
  ///	  </para>
  ///	</remarks>
  TNxHorizonDelivery = (
    ///	<summary>
    ///	  Run synchronously on current thread - BLOCKING
    ///	</summary>
    Sync,

    ///	<summary>
    ///	  Run asynchronously in random background thread
    ///	</summary>
    Async,

    ///	<summary>
    ///	  Run synchronously on main thread - BLOCKING
    ///	</summary>
    MainSync,

    ///	<summary>
    ///	  Run asynchronously on main thread
    ///	</summary>
    MainAsync
  );

  ///	<summary>
  ///	  <para>
  ///	    Public waitable subscription interface used for checking whether subscription is active 
  ///	    and canceling
  ///	  </para>
  ///	  <para>
  ///	    This interface is basically cancelation token + countdown event for protecting 
  ///     currently running event handlers
  ///	  </para>
  ///	</summary>
  INxEventSubscription = interface
  ['{15BE488F-CFE3-4EFB-A3DA-910D0C443D50}']
    function BeginWork: Boolean;
    procedure EndWork;
    procedure WaitFor;
    procedure Cancel;
    function GetIsActive: Boolean;
    function GetIsCanceled: Boolean;
    property IsActive: Boolean read GetIsActive;
    property IsCanceled: Boolean read GetIsCanceled;
  end;

  ///	<summary>
  ///	  Generic event class. Supports all types. If Value is an object it is owned and released by
  ///	  the event.
  ///	</summary>
  ///	<typeparam name="T">
  ///	  Wrapped event Value type - supports all types
  ///	</typeparam>
  TNxEventObject<T> = class(TInterfacedObject, INxEvent<T>)
  protected
    fValue: T;
    function GetValue: T;
  public
    constructor Create(const aValue: T);
    destructor Destroy; override;
    property Value: T read GetValue;
    class function New(const aValue: T): INxEvent<T>;
  end;


  ///	<summary>
  ///	  Generic event record. Supports value or managed types.
  ///	</summary>
  ///	<typeparam name="T">
  ///	  Wrapped event Value type - Supports value or managed types.
  ///	</typeparam>
  TNxEvent<T> = record
  private
    fValue: T;
    function GetValue: T;
  public
    constructor New(const aValue: T);
    property Value: T read GetValue;
  end;

  ///	<summary>
  ///	  Event subscription - public interface acts as cancelation token, protected fields hold
  ///	  private subscription data necessary for dispatching events.
  ///	</summary>
  TNxEventSubscription = class(TInterfacedObject, INxEventSubscription)
  protected
    fCountdown: TCountdownEvent;
    fEventMethod: TNxEventMethod;
    fEventInfo: PTypeInfo;
    fDelivery: TNxHorizonDelivery;
    fIsCanceled: Boolean;
    function GetIsActive: Boolean;
    function GetIsCanceled: Boolean;
  public
    constructor Create(aEventInfo: PTypeInfo; aDelivery: TNxHorizonDelivery; aObserver: TNxEventMethod);
    destructor Destroy; override;

    function BeginWork: Boolean;
    procedure EndWork;
    procedure WaitFor;

    ///	<summary>
    ///	  Cancel subscription. Can be safely called multiple times.
    ///	</summary>
    procedure Cancel;

    ///	<summary>
    ///	  Subscription method can be invoked only if subscription is active (not canceled) This
    ///	  prevents issues with asynchronous event dispatching, when subscription and its associated
    ///	  method are no longer valid (alive)
    ///	</summary>
    property IsActive: Boolean read GetIsActive;

    ///	<summary>
    ///	  Opposite of IsActive property
    ///	</summary>
    property IsCanceled: Boolean read GetIsCanceled;
  end;

  TNxHorizon = class
  protected
    ///	<summary>
    ///	  Lock for protecting fSubscriptions
    ///	</summary>
    fLock: IReadWriteSync;
    fSubscriptions: TDictionary<PTypeInfo, TList<INxEventSubscription>>;
    procedure DispatchEvent<T>(const aEvent: T; const aSubscription: INxEventSubscription; aDelivery: TNxHorizonDelivery; aObserver: TNxEventMethod);
  public
    constructor Create;
    destructor Destroy; override;

    ///	<summary>
    ///	  Subscribe observer method
    ///	</summary>
    ///	<typeparam name="T">
    ///	  Wrapped event type - supports all types
    ///	</typeparam>
    ///	<param name="aDelivery">
    ///	  Subscription delivery option
    ///	</param>
    ///	<param name="aObserver">
    ///	  Observer method
    ///	</param>
    function Subscribe<T>(aDelivery: TNxHorizonDelivery; aObserver: TNxEventMethod<T>): INxEventSubscription;

    ///	<summary>
    ///	  Unsubscribe - subscription will be automatically canceled
    ///	</summary>
    ///	<remarks>
    ///	  Unsubscribe cannot be called from synchronously dispatched events because it will modify
    ///	  collection of subscribers while it is being iterated. Use UnsubscribeAsync in such
    ///	  scenarios.
    ///	</remarks>
    procedure Unsubscribe(const aSubscription: INxEventSubscription); overload;

    ///	<summary>
    ///	  Asynchronously unsubscribe observer method
    ///	</summary>
    procedure UnsubscribeAsync(const aSubscription: INxEventSubscription); overload;

    ///	<summary>
    ///	  Post event - delivery depends on subscription delivery options
    ///	</summary>
    procedure Post<T>(const aEvent: T);

    ///	<summary>
    ///	  Send event - delivery parameter overrides subscription delivery
    ///	</summary>
    procedure Send<T>(const aEvent: T; aDelivery: TNxHorizonDelivery);
  end;

  NxHorizon = class
  protected
    class var
      fInstance: TNxHorizon;
    class constructor ClassCreate;
    class destructor ClassDestroy;
  public
    ///	<summary>
    ///	  Thread safe, default (global) Horizon instance.
    ///	</summary>
    class property Instance: TNxHorizon read fInstance;
  end;

implementation

{$IFNDEF DELPHI_TOKYO_UP}
type
  TThreadHelper = class helper for TThread
  public
    ///  <summary>
    ///    Simulate TThread.ForceQueue functionality for older versions.
    ///  </summary>
    class procedure ForceQueue(const aThread: TThread; const aThreadProc: TThreadProcedure); static;
  end;

class procedure TThreadHelper.ForceQueue(const aThread: TThread; const aThreadProc: TThreadProcedure);
begin
  // main purpose of this ForceQueue is to delay running of aTheadProc if called from main thread
  if (aThread = nil) or (CurrentThread.ThreadID = MainThreadID) then
    begin
      CreateAnonymousThread(
        procedure
        begin
          Queue(aThread, aThreadProc);
        end).Start;
    end
  else
    Queue(aThread, aThreadProc);
end;
{$ENDIF}

{ TNxEventObject<T> }

constructor TNxEventObject<T>.Create(const aValue: T);
begin
  fValue := aValue;
end;

destructor TNxEventObject<T>.Destroy;
var
  Obj: TObject;
begin
  if PTypeInfo(TypeInfo(T)).Kind = tkClass then
    begin
      PObject(@Obj)^ := PPointer(@fValue)^;
      Obj.Free;
    end;
  inherited;
end;

function TNxEventObject<T>.GetValue: T;
begin
  Result := fValue;
end;

class function TNxEventObject<T>.New(const aValue: T): INxEvent<T>;
begin
  Result := TNxEventObject<T>.Create(aValue);
end;


{ TNxEvent<T> }

constructor TNxEvent<T>.New(const aValue: T);
begin
  fValue := aValue;
end;

function TNxEvent<T>.GetValue: T;
begin
  Result := fValue;
end;

{ TNxEventSubscription }

constructor TNxEventSubscription.Create(aEventInfo: PTypeInfo; aDelivery: TNxHorizonDelivery; aObserver: TNxEventMethod);
begin
  fEventInfo := aEventInfo;
  fDelivery := aDelivery;
  fEventMethod := aObserver;
  fCountdown := TCountdownEvent.Create(1);
end;

destructor TNxEventSubscription.Destroy;
begin
  fCountdown.Free;
  inherited;
end;

function TNxEventSubscription.BeginWork: Boolean;
begin
  Result := (not fIsCanceled) and fCountdown.TryAddCount;
end;

procedure TNxEventSubscription.EndWork;
begin
  fCountdown.Signal;
end;

procedure TNxEventSubscription.WaitFor;
begin
  fIsCanceled := True;
  fCountdown.Signal;
  fCountdown.WaitFor;
end;

function TNxEventSubscription.GetIsActive: Boolean;
begin
  Result := not fIsCanceled;
end;

function TNxEventSubscription.GetIsCanceled: Boolean;
begin
  Result := fIsCanceled;
end;

procedure TNxEventSubscription.Cancel;
begin
  fIsCanceled := True;
end;

{ TNxHorizon }

constructor TNxHorizon.Create;
begin
  fLock := TMultiReadExclusiveWriteSynchronizer.Create;
  fSubscriptions := TObjectDictionary<PTypeInfo, TList<INxEventSubscription>>.Create([doOwnsValues]);
end;

destructor TNxHorizon.Destroy;
begin
  fSubscriptions.Free;
  inherited;
end;

function TNxHorizon.Subscribe<T>(aDelivery: TNxHorizonDelivery; aObserver: TNxEventMethod<T>): INxEventSubscription;
var
  SubList: TList<INxEventSubscription>;
begin
  Result := TNxEventSubscription.Create(PTypeInfo(TypeInfo(T)), aDelivery, TNxEventMethod(aObserver));
  fLock.BeginWrite;
  try
    if not fSubscriptions.TryGetValue(PTypeInfo(TypeInfo(T)), SubList) then
      begin
        SubList := TList<INxEventSubscription>.Create;
        fSubscriptions.Add(PTypeInfo(TypeInfo(T)), SubList);
      end;
    SubList.Add(Result);
  finally
    fLock.EndWrite;
  end;
end;

procedure TNxHorizon.Unsubscribe(const aSubscription: INxEventSubscription);
var
  SubList: TList<INxEventSubscription>;
begin
  aSubscription.Cancel;
  fLock.BeginWrite;
  try
    if fSubscriptions.TryGetValue(TNxEventSubscription(aSubscription).fEventInfo, SubList) then
      SubList.Remove(aSubscription);
  finally
    fLock.EndWrite;
  end;
end;

procedure TNxHorizon.UnsubscribeAsync(const aSubscription: INxEventSubscription);
var
  [unsafe] lProc: TProc;
begin
  aSubscription.Cancel;
  lProc :=
    procedure
    begin
      Unsubscribe(aSubscription);
    end;
  {$IFDEF DELPHI_XE7_UP}
  TTask.Run(lProc);
  {$ELSE}
  TThread.CreateAnonymousThread(lProc).Start;
  {$ENDIF}
end;

procedure TNxHorizon.DispatchEvent<T>(const aEvent: T; const aSubscription: INxEventSubscription; aDelivery: TNxHorizonDelivery; aObserver: TNxEventMethod);
var
  [unsafe] lProc: TProc;
begin
  lProc :=
    procedure
    begin
      if aSubscription.BeginWork then
        try
          TNxEventMethod<T>(aObserver)(aEvent);
        finally;
          aSubscription.EndWork;
        end;
    end;

  case aDelivery of
// Synchronous dispatching is done directly in Send and Post methods
//    Sync :
//      begin
//        // IsActive was already checked before entering dispatch
//        // in synchronous execution IsActive could not be changed in the meantime
//        TNxEventMethod<T>(aObserver)(aEvent);
//      end;
    Async :
      begin
        {$IFDEF DELPHI_XE7_UP}
        TTask.Run(lProc);
        {$ELSE}
        TThread.CreateAnonymousThread(lProc).Start;
        {$ENDIF}
      end;
    MainSync :
      begin
        if TThread.CurrentThread.ThreadID = MainThreadID then
          lProc
        else
          TThread.Synchronize(nil, TThreadProcedure(lProc));
      end;
    MainAsync :
      begin
        TThread.ForceQueue(nil, TThreadProcedure(lProc));
      end;
  end;
end;

procedure TNxHorizon.Post<T>(const aEvent: T);
var
  SubList: TList<INxEventSubscription>;
  Sub: TNxEventSubscription;
  i: Integer;
begin
  fLock.BeginRead;
  try
    if fSubscriptions.TryGetValue(PTypeInfo(TypeInfo(T)), SubList) then
      for i := 0 to SubList.Count - 1 do
        begin
          Sub := TNxEventSubscription(SubList.List[i]);
          if Sub.IsActive and (Sub.fEventInfo = PTypeInfo(TypeInfo(T))) then
            begin
              // check if delivery is Sync because
              // DispatchEvent has anonymous methods setup
              // that is unnecessary for synchronous execution path
              if Sub.fDelivery = Sync then
                begin
                  if Sub.BeginWork then
                    try
                      TNxEventMethod<T>(Sub.fEventMethod)(aEvent);
                    finally
                      Sub.EndWork;
                    end;
                end
              else
                DispatchEvent(aEvent, Sub, Sub.fDelivery, Sub.fEventMethod);
            end;
        end;
  finally
    fLock.EndRead;
  end;
end;

procedure TNxHorizon.Send<T>(const aEvent: T; aDelivery: TNxHorizonDelivery);
var
  SubList: TList<INxEventSubscription>;
  Sub: TNxEventSubscription;
  i: Integer;
begin
  fLock.BeginRead;
  try
    if fSubscriptions.TryGetValue(PTypeInfo(TypeInfo(T)), SubList) then
      for i := 0 to SubList.Count - 1 do
        begin
          Sub := TNxEventSubscription(SubList.List[i]);
          if Sub.IsActive and (Sub.fEventInfo = PTypeInfo(TypeInfo(T))) then
            begin
              // check if delivery is Sync because
              // DispatchEvent has anonymous methods setup
              // that is unnecessary for synchronous execution path
              if aDelivery = Sync then
                begin
                  if Sub.BeginWork then
                    try
                      TNxEventMethod<T>(Sub.fEventMethod)(aEvent);
                    finally
                      Sub.EndWork;
                    end;
                end
              else
                DispatchEvent<T>(aEvent, Sub, aDelivery, Sub.fEventMethod);
            end;
        end;
  finally
    fLock.EndRead;
  end;
end;

{ NxHorizon }

class constructor NxHorizon.ClassCreate;
begin
  fInstance := TNxHorizon.Create;
end;

class destructor NxHorizon.ClassDestroy;
begin
  fInstance.Free;
end;

end.


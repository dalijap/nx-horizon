# NX Horizon - Event Bus for Delphi

## Features

  + implements the publish/subscribe pattern, decoupling publishers and subscribers
  + events are categorized by type
  + any Delphi type can be used as an event
  + supports four types of event delivery: synchronous, asynchronous, synchronous in 
    the context of the main thread, and asynchronous in the context of the main thread
  + provides generic record and reference-counted class wrappers for easier usage and 
    management of existing types as events
  + simple in both implementation and usage
  + fast
  + full thread safety
    - `TNxHorizon` class is fully thread-safe
    - the default event bus instance, `NXHorizon.Instance`, is thread-safe and can be used 
      from any thread 

## Supported platforms

  + NX Horizon is platform-agnostic and is supported on all available platforms
  + Tested on: XE4, 10.3.3 Rio, 10.4.2 Sydney, and 11.1 Alexandria, but it should work on 
    other versions between XE4 and the current version using classic compiler.

## Basic usage

__Declare event type:__

Events are categorized by type information - `TypeInfo`. Each separate event
category requires a distinct type. 

```delphi
type
  TFoo = class
  ...
  end;

  TOtherFoo = type TFoo;

  TIntegerEvent = type Integer;
  TStringEvent = type string;
  TFooEvent = INxEvent<TFoo>;
  TOtherFooEvent = INxEvent<TOtherFoo>;
```

__Subscribe/unsubscribe to event:__

Subscribing to events can be added to any existing class.

```delphi
type
  TSubscriber = class
  protected
    // subscriptions
    fIntegerSubscription: INxEventSubscription;
    fStringSubscription: INxEventSubscription;
    // event handlers
    procedure OnIntegerEvent(const aEvent: TIntegerEvent);
    procedure OnStringEvent(const aEvent: TStringEvent);
  public
    constructor Create;
    destructor Destroy; override;
  end;

constructor TSubscriber.Create;
begin
  fIntegerSubscription := NxHorizon.Instance.Subscribe<TIntegerEvent>(Async, OnIntegerEvent);
  fStringSubscription := NxHorizon.Instance.Subscribe<TStringEvent>(Sync, OnStringEvent);
end;

destructor TSubscriber.Destroy;
begin
  fIntegerSubscription.WaitFor;
  fStringSubscription.WaitFor;
  NxHorizon.Instance.Unsubscribe(fIntegerSubscription);
  NxHorizon.Instance.Unsubscribe(fStringSubscription);
  inherited;
end;

procedure TSubscriber.OnIntegerEvent(const aEvent: TIntegerEvent);
begin
  Writeln(aEvent);
end;

procedure TSubscriber.OnStringEvent(const aEvent: TStringEvent);
begin
  Writeln(aEvent);
end;
```

__Send messages:__

```delphi
  NxHorizon.Instance.Post<TIntegerEvent>(5);
  NxHorizon.Instance.Send<TStringEvent>('abc', Async);
```

or

```delphi
var
  IntEvent: TIntegerEvent;
  StrEvent: TStringEvent;

  IntEvent := 5;
  StrEvent := 'abc';
  NxHorizon.Instance.Post(IntEvent);
  NxHorizon.Instance.Send(StrEvent, Async);
```

## Documentation

### Event handler

Event handler methods must conform to the following declaration, where `T` can
be any type. Asynchronous delivery requires types with automatic memory
management or value types. You can also use manually managed, long-lived object
instances as events, but in such cases, you must ensure that they will not be
destroyed before the already-dispatched messages are fully processed.

```delphi
procedure(const aEvent: T) of object;
```

### Delivery options

The `TNxHorizonDelivery` type declares four delivery options:

+ `Sync` - synchronous in the current thread
+ `Async` - asynchronous in a random background thread
+ `MainSync` - synchronous on the main thread
+ `MainAsync` - asynchronous on the main thread

`Sync` and `MainSync` are BLOCKING operations, and the event handler will
execute immediately in the context of the current thread, or synchronized with
the main thread. This will block dispatching other events using the same event
bus instance until the event handler completes. Don't use it (or use it
sparingly only for short executions) on the default event bus instance.

If sending events is done from the context of the main thread, `MainAsync`
delivery will use `TThread.ForceQueue` to run the event handler asynchronously
in the context of the main thread.

### Subscribing and unsubscribing

Subscribing to an event handler constructs a new `INxEventSubscription`
instance. You should store the returned instance in order to unsubscribe later
on.

There are two methods for unsubscribing: `Unsubscribe` and `UnsubscribeAsync`.

Both methods cancel the subscription and remove it from the collection of
subscriptions maintained in the event bus. This collection is being iterated
inside the `Post` and `Send` methods. Any modifications at that time are not
allowed, and could result in unexpected behavior. 

To avoid modification of the subscriber collection during iteration, if you want
to unsubscribe from code running in a synchronously dispatched event handler,
you should use `UnsubscribeAsync`, which will immediately cancel the
subscription, but delay the actual removal from the collection, running it
outside the dispatching iteration.

Asynchronously dispatched event handlers always run outside the dispatching
iteration, and they allow using the `Unsubscribe` method. However, how the
handlers are dispatched can be changed by unrelated external code, and if you
cannot absolutely guarantee asynchronous dispatching, using `UnsubscribeAsync`
is warranted.

### Canceling subscription

`Unsubscribe` and `UnsubscribeAsync` also cancel the subscription, before
removing it from the subscription collection. Usually, there is no need to
explicitly cancel the subscription before unsubscribing, but if you have some
particular reason why you want to cancel the subscription at some point before
unsubscribing, you can call its `Cancel` method. `Cancel` can safely be called
multiple times. Once a subscription is canceled, its state cannot be reverted.

### Waiting for subscription

Because of asynchronous event dispatching, it is possible to have an
already-dispatched event handler at the time when you cancel or unsubscribe a
particular subscription. If you are unsubscribing from a destructor, your
subscriber class destructor, this could cause you to access the subscriber
instance during its destruction process, or after it has been destroyed. To
prevent such a scenario, you can call `WaitFor` on the subscription, which will
immediately cancel the subscription and block until all dispatched event
handlers have finished executing.

If you call `WaitFor` from the context of the main thread, and your event
handlers run for a long time, this will cause your application to stop
responding for that period of time. 

### BeginWork/EndWork 

The `BeginWork` and `EndWork` methods are part of the subscription waiting
mechanism. If you need to run some code inside an event handler in some other
thread, and you need to make sure that code will be also waited for, you can
call `BeginWork` before you start such a thread, and `EndWork` after it
finishes. Make sure all code paths will eventually call a matching `EndWork`, as
not doing so will cause a deadlock when you call `WaitFor`. 

```delphi
procedure TSubscriber.OnLongEvent(const aEvent: TIntegerEvent);
begin
  fIntegerSubscription.BeginWork;
  try
    TTask.Run(
      procedure
      begin
        try
          ...
        finally
          fIntegerSubscription.EndWork;
        end;
      end);
  except
    fIntegerSubscription.EndWork;
    raise;
  end;
end;
```


### Posting and sending events 

```delphi
procedure Post<T>(const aEvent: T);
procedure Send<T>(const aEvent: T; aDelivery: TNxHorizonDelivery);
```

The `Post` method is used for posting events where the delivery option will
depend on the subscription delivery option set while subscribing to the event.

The `Send` method overrides the subscription delivery option, and dispatches an
event in a manner determined by the passed `aDelivery` parameter. If the
subscription specified dispatching in the context of the main thread, `Send`
method will honor that requirement, so you don't have to worry about
synchronization in those event handlers. 

Whether `Post` or `Send` will be blocking calls depends on the delivery options
used. When you use `Post`, please note that different subscriptions to the same
event type can be configured with different delivery options.

### Event bus instances

`TNxHorizon` is a manually managed, fully thread-safe class. You can create as
many separate event bus instances as you like. Instances are fully thread-safe,
and don't require any additional protection as long as you use references in
read-only mode—once you initialize the reference and start using that instance
across threads, you are not allowed to modify the reference variable itself. You
can freely call any methods on such a reference from any thread.

If you need to support different channels (additional event categorization), you
can achieve such functionality by creating a separate event bus instance for
each channel. 

### Managing lifetime of additional event bus instances

Functionality of `TNxHorizon` class cannot be directly exposed as interface
because it uses parameterized methods that are not supported for interfaces.

Besides singleton instance available through `NxHorizon.Instance` it is possible
to use separate bus instances for other purposes, with much shorter lifetime. In
order to simplify life management for those instances and avoid accessing
dangling pointers in multi-threading environment, you can use `INxHorizon` to
safely hold and share such event bus instances.

This also opens possibility to use event bus instances, which are rather
lightweight as dispatching mechanism in _observer pattern_, where observable
subject holds and exposes its `INxHorizon` reference, to which observers can
attach to. When subscribing, observers should store `INxHorizon` instance they
are subscribing to, so they can safely unsubscribe from it even if subject
itself has been released in the meantime. 

This allows using _observer pattern_ in thread-safe manner with subjects that
are not automatically managed instances. Also holding strong (thread-safe)
reference to the event bus instance instead of subject directly avoids potential
reference cycles when using managed object instances, instead of using
thread-unsafe weak references.

`INxHorizon.Instance` returns wrapped `TNxHorizon` instance which is manually
managed by a container. It can be safely used as long as subscriber holds strong
reference to its container. 

The subject needs to call `ShutDown` method on its `INxHorizon` reference during
its cleanup process. This will set `IsActive` flag to `False` and send
`TNxHorizonShutDownEvent` to its subscribers, so they can perform proper
cleanup. `TNxHorizonShutDownEvent` contains wrapped `TNxHorizon` instance, so
subscribers can use single shutdown event handler to manage multiple subjects.

Calling `ShutDown` does not have any impact on the bus ability to send and post
messages. If you need to make sure that you are not dispatching new events
during the cleanup process, you can check `IsActive` flag before calling `Post`
or `Send`.

### Dedicated thread pool support - XE7 and newer versions

This event bus utilizes `TTask` from the PPL for asynchronous dispatching of
events in XE7 and newer Delphi versions. Those tasks run on the default thread
pool. This is by design. This is based on the premise that any code using the
default thread pool should run very fast and should not cause contention. 

If you have code in event handlers or other code that uses the default pool for
long-running tasks that can cause problems, then the correct course of action is
to run that specific, long-running code on a separate, dedicated thread pool,
instead of creating multiple thread pools all over that will serve different
parts of frameworks that need to run some tasks.

For a long-running event handler, the fastest solution to the problem is using
synchronous dispatching and starting a new task inside the event handler code
that can then use some other, non-default thread pool. That way you will have
more control over your code, and the freedom to change the behavior of a
specific handler without impacting all other handlers running on the same event
bus instance:

```delphi
procedure TSubscriber.OnLongEvent(const aEvent: TLongEvent);
begin
  TTask.Run(
    procedure
    begin
    ... 
    end, DedicatedThreadPool);
end;
```

## Enhancements 

The main features of this event bus implementation are thread safety, speed, and
simplicity. Any additional features and extensions must not compromise those
original goals and intents. 

This implementation is also based on my own requirements and code, and it is
possible that some parts don't fully satisfy some other common code workflow.

Because the speed is based on the current implementation of the `Post` and
`Send` methods, I don't expect many changes in those areas. However, improving
or supporting different subscription workflows outside those two methods is
possible.

---

[https://dalija.prasnikar.info](https://dalija.prasnikar.info)


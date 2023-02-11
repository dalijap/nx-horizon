# NX Horizon Change Log

## 1.1.1 Hotfix

+ `TNxHorizonContainer.New` signature changed
  - Returns `INXHorizon` interface instead of `TNXHorizonContainer` for proper
    initialization of reference counting

## 1.1.0 Release

### Breaking changes

+ `TNxEvent<T>` record removed as it provides no value whatsoever 
  - Instead of using record wrapper, just create new type directly from the
    original type. 

+ `TNxEventObject<T>` is renamed to `TNxEvent<T>`
  - Constructing new event object is commonly done within `Post` or `Send` calls
    and shorter class name makes such code shorter and more readable.


### New features

+ `INxHorizon` interface and its implementing class `TNxHorizonContainer` that
  holds single instance of `TNxHorizon` class.


### Improvements

+ `Unsubscribe` can be safely called for `nil` subscription 

+ `WaitFor` periodically calls `CheckSynchronize` 
  - This allows using `WaitFor` on the main thread with event handlers that use
    `TThread.Synchronize` without deadlocking.

+ `Send` now honors dispatching events on main thread if required by
  subscription. If `aDelivery` specifies blocking call - `Sync`, dispatching for
  such subscriptions will be done synchronously through `TThread.Synchronize`.


## 1.0.0 Release

 + Initial release


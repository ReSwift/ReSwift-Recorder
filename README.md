[![Carthage compatible](https://img.shields.io/badge/Carthage-compatible-4BC51D.svg?style=flat)](https://github.com/Carthage/Carthage) 
[![](https://img.shields.io/badge/license-MIT-blue.svg)](https://github.com/Swift-Flow/Swift-Flow/blob/master/LICENSE.md)

⚠️ **Proof of concept. Needs a lot of love!** ⚠️

A recording store for [ReSwift](https://github.com/ReSwift/ReSwift). Enables hot-reloading and time travel for ReSwift apps.

#About ReSwiftRecorder

ReSwiftRecorder is an extension for ReSwift that allows developers to record and replay actions. ReSwiftRecorder supports serializing these actions to disk, which allows to replay recorded sessions and to restart apps at the point you left them off.

This is especially useful during development. If you run into a crash, while recording, you now have a recorded JSON file with all the actions needed to reproduce crash. If you restart your app with this recorded session, it will crash in exactly the same way every single time - this allows you to fix the underlying issue without manually navigating through the app over and over again.

The long term goal of this extension is to implement some of the most important features from [Redux Devtools](https://github.com/gaearon/redux-devtools).

**This extension is working - you can record and replay actions, but it still in a proof-of-concept state**.

##Next Steps

- Make it easier for developers to make actions serializable, ideally cutting down on some of the boilerplate code that is currently necessary.
- Improve the implementation of this extension, the current implementation is a hack.

##CocoaPods

You can install ReSwiftRecorder via CocoaPods by adding it to your `Podfile`:

	use_frameworks!

	source 'https://github.com/CocoaPods/Specs.git'
	platform :ios, '8.0'

	pod 'ReSwift'
	pod 'ReSwiftRecorder'
	
And run `pod install`.

##Carthage

You can install ReSwiftRecorder via [Carthage]() by adding the following line to your Cartfile:

	github "ReSwift/ReSwift-Recorder"

#Configuration

When creating your app's store you need to create an instance of `RecordingStore` instead of an instance of `MainStore`. You also need to provide a `typeMaps` argument that is used to deserialize actions:

```swift
RecordingMainStore(reducer: CombinedReducer([CounterReducer(), NavigationReducer()]),
    appState: AppState(), typeMaps:[counterActionTypeMap, ReSwiftRouter.typeMap], recording: "recording.json")
```
The `typeMaps` array is an array that maps type names (Strings) to action types.
The last argument `recording`, can either be `nil` or the path to a recording stored in the documents directory of the app. If you set the path to a specific recording, the store will load all actions upon launch and replay them, thereby restoring the state of the application.

For a practical example of how to use ReSwiftRecorder, check out the [Counter App Example](https://github.com/ReSwift/CounterExample-Navigation-TimeTravel).

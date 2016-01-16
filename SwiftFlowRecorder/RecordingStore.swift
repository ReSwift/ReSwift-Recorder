//
//  RecordingStore.swift
//  Meet
//
//  Created by Benjamin Encz on 12/1/15.
//  Copyright © 2015 DigiTales. All rights reserved.
//

import Foundation
import SwiftFlow

public typealias TypeMap = [String: StandardActionConvertible.Type]

public class RecordingMainStore<State: StateType>: MainStore<State> {

    typealias RecordedActions = [[String : AnyObject]]

    var recordedActions: RecordedActions = []
    var initialState: State
    var computedStates: [State] = []
    var actionsToReplay: Int?
    let recordingPath: String?
    private var typeMap: TypeMap = [:]

    /// Position of the rewind/replay control from the bottom of the screen
    /// defaults to 100
    public var rewindControlYOffset: CGFloat = 100

    var loadedActions: [Action] = [] {
        didSet {
            stateHistoryView?.statesCount = loadedActions.count
        }
    }

    var stateHistoryView: StateHistorySliderView?

    public var window: UIWindow? {
        didSet {
            if let window = window {
                let windowSize = window.bounds.size
                stateHistoryView = StateHistorySliderView(frame: CGRect(x: 0,
                    y: windowSize.height - rewindControlYOffset,
                    width: windowSize.width, height: 100))

                window.addSubview(stateHistoryView!)
                window.bringSubviewToFront(stateHistoryView!)

                stateHistoryView?.stateSelectionCallback = { [unowned self] selection in
                    self.replayToState(self.loadedActions, state: selection)
                }

                stateHistoryView?.statesCount = loadedActions.count
            }
        }
    }

    public init(reducer: AnyReducer, state: State, typeMaps: [TypeMap], recording: String? = nil) {
        self.initialState = state
        self.computedStates.append(initialState)
        self.recordingPath = recording

        super.init(reducer: reducer, state: state, middleware: [])

        // merge all typemaps into one
        typeMaps.forEach { typeMap in
            for (key, value) in typeMap {
                self.typeMap[key] = value
            }
        }

        if let recording = recording {
            loadedActions = loadActions(recording)
            self.replayToState(loadedActions, state: loadedActions.count)
        }
    }

    public required init(reducer: AnyReducer, appState: StateType, middleware: [Middleware]) {
        fatalError("The current barebones implementation of SwiftFlowRecorder does not support middleware!")
    }

    public required convenience init(reducer: AnyReducer, appState: StateType) {
        fatalError("The current Barebones implementation of SwiftFlowRecorder does not support this initializer!")
    }

    func dispatchRecorded(action: Action, callback: DispatchCallback?) {
        super.dispatch(action, callback: callback)

        recordAction(action)
    }

    public override func dispatch(action: Action, callback: DispatchCallback?) -> Any {
        if let actionsToReplay = actionsToReplay where actionsToReplay > 0 {
            // ignore actions that are dispatched during replay
            return action
        }

        super.dispatch(action) { newState in
            self.computedStates.append(newState as! State)
            callback?(newState)
        }

        if let standardAction = convertActionToStandardAction(action) {
            recordAction(standardAction)
            loadedActions.append(standardAction)
        }

        return action
    }

    func recordAction(action: Action) {
        let standardAction = convertActionToStandardAction(action)

        if let standardAction = standardAction {
            let recordedAction: [String : AnyObject] = [
                "timestamp": NSDate.timeIntervalSinceReferenceDate(),
                "action": standardAction.dictionaryRepresentation()
            ]

            recordedActions.append(recordedAction)
            storeActions(recordedActions)
        } else {
            print("SwiftFlowRecorder Warning: Could not log following action because it does not " +
                    "conform to StandardActionConvertible: \(action)")
        }
    }

    private func convertActionToStandardAction(action: Action) -> StandardAction? {

        if let standardAction = action as? StandardAction {
            return standardAction
        } else if let standardActionConvertible = action as? StandardActionConvertible {
            return standardActionConvertible.toStandardAction()
        }

        return nil
    }

    private func decodeAction(jsonDictionary: [String : AnyObject]) -> Action {
        let standardAction = StandardAction(dictionary: jsonDictionary)

        if !standardAction.isTypedAction {
            return standardAction
        } else {
            let typedActionType = self.typeMap[standardAction.type]!
            return typedActionType.init(standardAction)
        }
    }

    lazy var recordingDirectory: NSURL? = {
        let timestamp = Int(NSDate.timeIntervalSinceReferenceDate())

        let documentDirectoryURL = try? NSFileManager.defaultManager()
            .URLForDirectory(.DocumentDirectory, inDomain:
                .UserDomainMask, appropriateForURL: nil, create: true)

//        let path = documentDirectoryURL?
//            .URLByAppendingPathComponent("recording_\(timestamp).json")
        let path = documentDirectoryURL?
                    .URLByAppendingPathComponent("recording.json")

        print("Recording to path: \(path)")
        return path
    }()

    lazy var documentsDirectory: NSURL? = {
        let documentDirectoryURL = try? NSFileManager.defaultManager()
            .URLForDirectory(.DocumentDirectory, inDomain:
            .UserDomainMask, appropriateForURL: nil, create: true)

        return documentDirectoryURL
    }()

    private func storeActions(actions: RecordedActions) {
        let data = try! NSJSONSerialization.dataWithJSONObject(actions, options: .PrettyPrinted)

        if let path = recordingDirectory {
            do {
                try data.writeToURL(path, atomically: true)
            } catch {
                /* error handling here */
            }
        }
    }

    private func loadActions(recording: String) -> [Action] {
        guard let recordingPath = documentsDirectory?.URLByAppendingPathComponent(recording) else {
            return []
        }
        guard let data = NSData(contentsOfURL: recordingPath) else { return [] }

        let jsonArray = try! NSJSONSerialization.JSONObjectWithData(data,
            options: NSJSONReadingOptions(rawValue: 0)) as! Array<AnyObject>

        let actionsArray: [Action] = jsonArray.map {
            return decodeAction($0["action"] as! [String : AnyObject])
        }

        return actionsArray
    }

    private func replayToState(actions: [Action], state: Int) {
        if (state > computedStates.count - 1) {
            print("Rewind to \(state)...")
            self.state = initialState
            recordedActions = []
            actionsToReplay = state

            for i in 0..<state {
                dispatchRecorded(actions[i]) { newState in
                    self.actionsToReplay = self.actionsToReplay! - 1
                    self.computedStates.append(newState as! State)
                }
            }
        } else {
            self.state = computedStates[state]
        }

    }

}
//
//  RecordingStore.swift
//  Meet
//
//  Created by Benjamin Encz on 12/1/15.
//  Copyright © 2015 DigiTales. All rights reserved.
//

import Foundation
import ReSwift

public typealias TypeMap = [String: StandardActionConvertible.Type]

open class RecordingMainStore<State: StateType>: Store<State> {

    typealias RecordedActions = [[String : AnyObject]]

    var recordedActions: RecordedActions = []
    var initialState: State!
    var computedStates: [State] = []
    var actionsToReplay: Int?
    let recordingPath: String?
    fileprivate var typeMap: TypeMap = [:]

    /// Position of the rewind/replay control from the bottom of the screen
    /// defaults to 100
    open var rewindControlYOffset: CGFloat = 100

    var loadedActions: [Action] = [] {
        didSet {
            stateHistoryView?.statesCount = loadedActions.count
        }
    }

    var stateHistoryView: StateHistorySliderView?

    open var window: UIWindow? {
        didSet {
            if let window = window {
                let windowSize = window.bounds.size
                stateHistoryView = StateHistorySliderView(frame: CGRect(x: 0,
                    y: windowSize.height - rewindControlYOffset,
                    width: windowSize.width, height: 100))

                window.addSubview(stateHistoryView!)
                window.bringSubview(toFront: stateHistoryView!)

                stateHistoryView?.stateSelectionCallback = { [unowned self] selection in
                    self.replayToState(self.loadedActions, state: selection)
                }

                stateHistoryView?.statesCount = loadedActions.count
            }
        }
    }

    public init(
        reducer: AnyReducer,
        state: State?,
        typeMaps: [TypeMap],
        recording: String? = nil,
        middleware: [Middleware] = []
    ) {

        self.recordingPath = recording

        super.init(reducer: reducer, state: state, middleware: middleware)

        self.initialState = self.state
        self.computedStates.append(initialState)

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
        fatalError("The current barebones implementation of ReSwiftRecorder does not support this initializer!")
    }

    public required convenience init(reducer: AnyReducer, appState: StateType) {
        fatalError("The current barebones implementation of ReSwiftRecorder does not support this initializer!")
    }

    required convenience public init(reducer: AnyReducer, state: State?) {
        fatalError("init(reducer:state:) has not been implemented")
    }

    required public init(reducer: AnyReducer, state: State?, middleware: [Middleware]) {
        fatalError("init(reducer:state:middleware:) has not been implemented")
    }

    func dispatchRecorded(_ action: Action) {
        super.dispatch(action)

        recordAction(action)
    }

    @discardableResult
    open override func dispatch(_ action: Action) -> Any {
        if let actionsToReplay = actionsToReplay , actionsToReplay > 0 {
            // ignore actions that are dispatched during replay
            return action
        }

        super.dispatch(action)

        self.computedStates.append(self.state)

        if let standardAction = convertActionToStandardAction(action) {
            recordAction(standardAction)
            loadedActions.append(standardAction)
        }

        return action
    }

    func recordAction(_ action: Action) {
        let standardAction = convertActionToStandardAction(action)

        if let standardAction = standardAction {
            let recordedAction: [String : AnyObject] = [
                "timestamp": Date.timeIntervalSinceReferenceDate as AnyObject,
                "action": standardAction.dictionaryRepresentation as AnyObject
            ]

            recordedActions.append(recordedAction)
            storeActions(recordedActions)
        } else {
            print("ReSwiftRecorder Warning: Could not log following action because it does not " +
                "conform to StandardActionConvertible: \(action)")
        }
    }

    fileprivate func convertActionToStandardAction(_ action: Action) -> StandardAction? {

        if let standardAction = action as? StandardAction {
            return standardAction
        } else if let standardActionConvertible = action as? StandardActionConvertible {
            return standardActionConvertible.toStandardAction()
        }

        return nil
    }

    fileprivate func decodeAction(_ jsonDictionary: [String : AnyObject]) -> Action {
        let standardAction = StandardAction(dictionary: jsonDictionary)

        if !standardAction!.isTypedAction {
            return standardAction!
        } else {
            let typedActionType = self.typeMap[standardAction!.type]!
            return typedActionType.init(standardAction!)
        }
    }

    lazy var recordingDirectory: URL? = {
        let timestamp = Int(Date.timeIntervalSinceReferenceDate)

        let documentDirectoryURL = try? FileManager.default
            .url(for: .documentDirectory, in:
                .userDomainMask, appropriateFor: nil, create: true)

        //        let path = documentDirectoryURL?
        //            .URLByAppendingPathComponent("recording_\(timestamp).json")
        let path = documentDirectoryURL?
            .appendingPathComponent(self.recordingPath ?? "recording.json")

        print("Recording to path: \(path)")
        return path
    }()

    lazy var documentsDirectory: URL? = {
        let documentDirectoryURL = try? FileManager.default
            .url(for: .documentDirectory, in:
                .userDomainMask, appropriateFor: nil, create: true)

        return documentDirectoryURL
    }()

    fileprivate func storeActions(_ actions: RecordedActions) {
        let data = try! JSONSerialization.data(withJSONObject: actions, options: .prettyPrinted)

        if let path = recordingDirectory {
            try? data.write(to: path, options: [.atomic])
        }
    }

    fileprivate func loadActions(_ recording: String) -> [Action] {
        guard let recordingPath = documentsDirectory?.appendingPathComponent(recording) else {
            return []
        }
        guard let data = try? Data(contentsOf: recordingPath) else { return [] }

        let jsonArray = try! JSONSerialization.jsonObject(with: data,
            options: JSONSerialization.ReadingOptions(rawValue: 0)) as! Array<AnyObject>

        let actionsArray: [Action] = jsonArray.map {
            return decodeAction($0["action"] as! [String : AnyObject])
        }

        return actionsArray
    }

    fileprivate func replayToState(_ actions: [Action], state: Int) {
        if (state > computedStates.count - 1) {
            print("Rewind to \(state)...")
            self.state = initialState
            recordedActions = []
            actionsToReplay = state

            for i in 0..<state {
                dispatchRecorded(actions[i])
                self.actionsToReplay = self.actionsToReplay! - 1
                self.computedStates.append(self.state)
            }
        } else {
            self.state = computedStates[state]
        }
        
    }
    
}

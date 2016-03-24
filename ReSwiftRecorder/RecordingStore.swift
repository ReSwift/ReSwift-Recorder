import Foundation
import ReSwift
import SocketIOClientSwift

public typealias TypeMap = [String: StandardActionConvertible.Type]

public class RecordingMainStore<State: StateType>: Store<State> {

    var initialState: State!
    var actionHistory = [Action]()
    var actionCount = 0
    var socket: SocketIOClient!

    var isDispatching = false
    var reducer: AnyReducer!

    private var typeMap: TypeMap = [:]

    required public init(reducer: AnyReducer, state: State, middleware: [Middleware],
                  typeMap: TypeMap, socket: SocketIOClient) {

        initialState = state
        self.typeMap = typeMap
        self.socket = socket

        super.init(reducer: reducer, state: state, middleware: [])

        self.reducer = reducer

        socket.on("setCurrentAction") { [unowned self] (object, emitter) in
            guard let stringValue = (object as? [String])?.first else { return }
            guard let count = Int(stringValue) else { return }
            self.replayToActionCount(count)
        }

        socket.on("allActions") { [unowned self] (object, emitter) in
            print("[TARDIS]: Rewriting history...")
            guard let rawActions = (object as? [[[String: AnyObject]]])?.first else { return }
            self.actionHistory = self.convertToActions(rawActions)
            self.replayToActionCount(self.actionHistory.count)
            print("[TARDIS]: Replaced history with \(self.actionHistory.count) actions")
        }

        socket.on("reset") { [unowned self] (object, emitter) in
            print("[TARDIS]: Erasing history...")
            self.actionHistory = []
            self.actionCount = 0
            self.state = self.initialState
        }

        socket.on("connect") { (object, emitter) in
            socket.emit("getAllActions")
        }

        socket.emit("getAllActions")
    }


    // MARK: - Recording

    override public func _defaultDispatch(action: Action) -> Any {
        if isDispatching {
            // Use Obj-C exception since throwing of exceptions can be verified through tests
            NSException.raise("SwiftFlow:IllegalDispatchFromReducer", format: "Reducers may " +
                "not dispatch actions.", arguments: getVaList(["nil"]))
        }

        var oldState = state

        if actionCount != actionHistory.count {
            oldState = actionHistory.reduce(initialState) { state, action in
                // swiftlint:disable:next force_cast
                return self.reducer._handleAction(action, state: state) as! State
            }
        }

        recordAction(action)
        actionHistory.append(action)

        isDispatching = true
        // swiftlint:disable:next force_cast
        let newState = reducer._handleAction(action, state: oldState) as! State
        isDispatching = false

        state = newState
        actionCount = actionHistory.count

        return action
    }


    func recordAction(action: Action) {
        guard let standardAction = convertActionToStandardAction(action) else {
            return print("ReSwiftRecorder Warning: Could not log following action because it " +
                "does not conform to StandardActionConvertible: \(action)")
        }

        let recordedAction: [String: AnyObject] = [
            "timestamp": NSDate.timeIntervalSinceReferenceDate(),
            "action": standardAction.dictionaryRepresentation()
        ]

        socket.emit("appendAction", recordedAction)
    }

    private func convertActionToStandardAction(action: Action) -> StandardAction? {

        if let standardAction = action as? StandardAction {
            return standardAction
        } else if let standardActionConvertible = action as? StandardActionConvertible {
            return standardActionConvertible.toStandardAction()
        }

        return nil
    }

    // MARK: - Reload

    private func convertToActions(rawActions: [[String: AnyObject]]) -> [Action] {
        return rawActions.flatMap { rawAction in
            guard let action = rawAction["action"] as? [String : AnyObject] else { return nil }
            return decodeAction(action)
        }
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

    // MARK: - Replay

    private func replayToActionCount(actionCount: Int) {

        let actionCount = min(actionCount, actionHistory.count)
        self.actionCount = actionCount

        state = actionHistory[0..<actionCount].reduce(initialState) { state, action in
            // swiftlint:disable:next force_cast
            return self.reducer._handleAction(action, state: state) as! State
        }
    }

    func disconnect() {
        socket.off("setCurrentAction")
        socket.off("setAllAction")
        socket = nil
    }
}

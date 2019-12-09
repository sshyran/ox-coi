/*
 * OPEN-XCHANGE legal information
 *
 * All intellectual property rights in the Software are protected by
 * international copyright laws.
 *
 *
 * In some countries OX, OX Open-Xchange and open xchange
 * as well as the corresponding Logos OX Open-Xchange and OX are registered
 * trademarks of the OX Software GmbH group of companies.
 * The use of the Logos is not covered by the Mozilla Public License 2.0 (MPL 2.0).
 * Instead, you are allowed to use these Logos according to the terms and
 * conditions of the Creative Commons License, Version 2.5, Attribution,
 * Non-commercial, ShareAlike, and the interpretation of the term
 * Non-commercial applicable to the aforementioned license is published
 * on the web site https://www.open-xchange.com/terms-and-conditions/.
 *
 * Please make sure that third-party modules and libraries are used
 * according to their respective licenses.
 *
 * Any modifications to this package must retain all copyright notices
 * of the original copyright holder(s) for the original code used.
 *
 * After any such modifications, the original and derivative code shall remain
 * under the copyright of the copyright holder(s) and/or original author(s) as stated here:
 * https://www.open-xchange.com/legal/. The contributing author shall be
 * given Attribution for the derivative code and a license granting use.
 *
 * Copyright (C) 2016-2019 OX Software GmbH
 * Mail: info@open-xchange.com
 *
 *
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/.
 *
 * This program is distributed in the hope that it will be useful, but
 * WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
 * or FITNESS FOR A PARTICULAR PURPOSE. See the Mozilla Public License 2.0
 * for more details.
 */

// https://github.com/vrtdev/flutter_workmanager/blob/master/ios/Classes/SwiftWorkmanagerPlugin.swift

import Foundation
import BackgroundTasks
import Workmanager
import UserNotifications

extension AppDelegate: FlutterStreamHandler {
    
    private struct BGTaskIdentifier {
        static let Refresh = "me.coi.bgtask.fetch"
    }
    
    private struct BGChannel {
        static let Path = "com.transistorsoft/flutter_background_fetch"
        
        struct Name {
            static let Method = "methods"
            static let Event = "events"
        }
        
        struct Action {
            static let Configure = "configure"
            static let Start = "start"
            static let Stop = "stop"
            static let Finish = "finish"
            static let Status = "status"
            static let Register = "registerHeadlessTask"
        }
    }
    
    // MARK: - Public API
    
    func setupBackgroundTasks() {
        UserDefaults.standard.numberOfBGTaskCalls = 0
        
        _ = WorkManager.registerTask(withIdentifier: BGTaskIdentifier.Refresh) { task in
            if let task = task as? BGAppRefreshTask {
                self.handleAppRefresh(task: task)
            }
        }
        
        // Register Method-Channel
        if let flutterEngine = FlutterEngine(name: BGTaskIdentifier.Refresh, project: nil, allowHeadlessExecution: true) {
            let methodChannel = FlutterMethodChannel(name: "\(BGChannel.Path)/\(BGChannel.Name.Method)", binaryMessenger: flutterEngine.binaryMessenger)
            methodChannel.setMethodCallHandler { call, result in
                self.handle(call: call, result: result)
            }
        }
        
    }

    func scheduleAppRefreshTask() {
        let frequency: TimeInterval = 5 * 60.0
        var task = Task(periodicTaskWithIdentifier: BGTaskIdentifier.Refresh, type: .refresh, frequency: frequency)
        task.initialDelay = 120
        schedule(task: task)
    }
    
    func stopAppRefresh() {
        WorkManager.shared.cancelTask(withIdentifier: BGTaskIdentifier.Refresh)
        UserDefaults.standard.numberOfBGTaskCalls = 0
        log.info("Cancelled app refresh task with identifier: \(BGTaskIdentifier.Refresh)")
    }
    
    // MARK: - Handle Flutter Method Calls
    
    fileprivate func handle(call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
            case BGChannel.Name.Method:
                if let arguments = call.arguments as? [String: Any],
                    let callbackHandle = arguments[] as Int64 {
                    
                    result(true)
                    return
                }
                result(false)
            
            default:
                result(FlutterMethodNotImplemented)
        }
        switch (call.method, call.arguments as? [AnyHashable: Any]) {
//        case (ForegroundMethodChannel.methods.initialize.name, let .some(arguments)):
//            let isInDebug = arguments[ForegroundMethodChannel.methods.initialize.arguments.isInDebugMode.rawValue] as! Bool
//            let handle = arguments[ForegroundMethodChannel.methods.initialize.arguments.callbackHandle.rawValue] as! Int64
//            UserDefaultsHelper.storeCallbackHandle(handle)
//            UserDefaultsHelper.storeIsDebug(isInDebug)
//            result(true)
//        default:
//            result(WMPError.unhandledMethod(call.method).asFlutterError)
//            return
//        }
    }
    
    // MARK: - FlutterStreamHandler

    func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
        return nil
    }
    
    func onCancel(withArguments arguments: Any?) -> FlutterError? {
        return nil
    }

    // MARK: - Private Helper
    
    fileprivate func handleAppRefresh(task: BGAppRefreshTask) {
        DispatchQueue.main.async {
            self.showNotification()
        }

        do {
            task.expirationHandler = {
                WorkManager.shared.cancelTask(withIdentifier: task.identifier)
                task.setTaskCompleted(success: true)
            }

            try WorkManager.shared.finish(task: task, success: true)

        } catch {
            log.error("Could not finish task: \(error)")
        }
    }
    
    fileprivate func handleProcessing(task: BGProcessingTask) {
        // NOTE: Nothing to schedule atm.
    }

    fileprivate func schedule(task: Task) {
        do {
            try WorkManager.shared.schedule(task: task)
            
        } catch {
            log.error("Could not schedule app refresh: \(error)")
        }
    }
    
    // MARK: - Temp Stuff
    
    fileprivate func showNotification() {
        let content = UNMutableNotificationContent()
        content.title = "Background Task says..."
        content.body = "FooBar! [#\(UserDefaults.standard.numberOfBGTaskCalls)]"
        
        // Create the request
        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: nil)
        
        // Schedule the request with the system.
        UNUserNotificationCenter.current().add(request) { error in
            if error != nil {
                log.error("Could not schedule notification: \(String(describing: error))")
                return
            }
            log.info("** Background Push-Notification sent [#\(UserDefaults.standard.numberOfBGTaskCalls)]. **")
            UserDefaults.standard.numberOfBGTaskCalls += 1
        }
    }
    
}

// MARK: -

extension UserDefaults {

    fileprivate enum Key {
        case numberOfBGTaskCalls
        case callbackHandle
        
        var stringValue: String {
            return "\(WorkManager.identifier).\(self)"
        }
    }
    
    // MARK: - Public Properties
    
    var numberOfBGTaskCalls: Int {
        get {
            return value(for: .numberOfBGTaskCalls)!
        }
        set {
            store(value: newValue, for: .numberOfBGTaskCalls)
        }
    }
    
    var callbackHandle: Int64 {
        get {
            return value(for: .callbackHandle)!
        }
        set {
            store(value: newValue, for: .callbackHandle)
        }
    }

    // MARK: - Private Helper
    
    fileprivate func store<T>(value: T, for key: Key) {
        set(value, forKey: key.stringValue)
    }

    fileprivate func value<T>(for key: Key) -> T? {
        return value(forKey: key.stringValue) as? T
    }
}

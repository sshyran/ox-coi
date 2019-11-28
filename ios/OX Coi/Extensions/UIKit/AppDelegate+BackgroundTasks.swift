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

import Foundation
import BackgroundTasks
import Workmanager
import UserNotifications

extension AppDelegate {
    
    private struct BGTaskIdentifier {
        static let Refresh = "me.coi.bgtask.fetch"
    }
    
    // MARK: - Background Task Registration
    
    internal func setupBackgroundTasks() {
        UserDefaults.standard.numberOfBGTaskCalls = 0
        
        let registered = WorkManager.shared.registerTask(withIdentifier: BGTaskIdentifier.Refresh) { task in
            if let task = task as? BGAppRefreshTask {
                self.handleAppRefresh(task: task)
            }
        }
        log.info("BG Task Registered: \(registered ? "YES" : "NO")")
    }
    
    // MARK: - App Refresh Task
    
    private func handleAppRefresh(task: BGAppRefreshTask) {
        scheduleAppRefresh()
        
        let content = UNMutableNotificationContent()
        content.title = "Background Task says..."
        content.body = "FooBar! [#\(UserDefaults.standard.numberOfBGTaskCalls)]"
        
        UserDefaults.standard.numberOfBGTaskCalls += 1
        
        // Create the request
        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: nil)
        
        // Schedule the request with the system.
        UNUserNotificationCenter.current().add(request) { error in
            if error != nil {
                log.error("Could not schedule notification: \(String(describing: error))")
                return
            }
        }
        
        task.setTaskCompleted(success: true)
    }

    func scheduleAppRefresh() {
        do {
            let task = Task.defaultPeriodicTask(identifier: BGTaskIdentifier.Refresh,
                                                name: BGTaskIdentifier.Refresh,
                                                frequency: 3 * 60.0,
                                                type: .refresh)
            try WorkManager.shared.schedule(task: task)

        } catch {
            log.error("Could not schedule app refresh: \(error)")
        }
    }
    
}

extension UserDefaults {
    var numberOfBGTaskCalls: Int {
        get {
            return integer(forKey: "bgTaskCalls")
        }
        set {
            set(newValue, forKey: "bgTaskCalls")
        }
    }
}

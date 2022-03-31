//
//  AApp.swift
//  A
//
//  Created by Pavel Yakimenko on 30/03/2022.
//

import SwiftUI
import BackgroundTasks

let backgroundFetchTaskID = "group.io.realm.test.bgfetch"
let backgroundProcessTaskID = "group.io.realm.test.bgprocess"

@main
struct AApp: App {
    @Environment(\.scenePhase) private var scenePhase
    @State var set: Bool = true

    init() {
        BGTaskScheduler.shared.register(forTaskWithIdentifier: backgroundFetchTaskID, using: nil) { [self] task in
            handleAppRefresh(task: task as! BGAppRefreshTask)
        }
        
        BGTaskScheduler.shared.register(forTaskWithIdentifier: backgroundProcessTaskID, using: nil) { [self] task in
            handleAppProcess(task: task as! BGProcessingTask)
        }

    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .onChange(of: scenePhase) { phase in
            if phase == .background {
                print("app phase - background")
                scheduleAppRefresh()
                scheduleAppProcessIfNeeded()
            }
        }
    }
    
    func scheduleAppRefresh() {
        let request = BGAppRefreshTaskRequest(identifier: backgroundFetchTaskID)
        request.earliestBeginDate = Date(timeIntervalSinceNow: 5)
        
        do {
            try BGTaskScheduler.shared.submit(request)
        } catch {
            print("Could not schedule app refresh: \(error)")
        }
    }
    
    func scheduleAppProcessIfNeeded() {
        let request = BGProcessingTaskRequest(identifier: backgroundProcessTaskID)
        request.requiresNetworkConnectivity = false
        request.requiresExternalPower = true
        request.earliestBeginDate = Date(timeIntervalSinceNow: 5)

        do {
            try BGTaskScheduler.shared.submit(request)
        } catch {
            print("Could not schedule database cleaning: \(error)")
        }
    }

    func handleAppRefresh(task: BGAppRefreshTask) {
        scheduleAppRefresh()

        print("bg refresh")
        Base.shared.addObjects()

        task.expirationHandler = {
            print("cancel refresh operations")
        }
    }
    
    // Delete feed entries older than one day.
    func handleAppProcess(task: BGProcessingTask) {
        print("bg process")
        Base.shared.addObjects()

        task.expirationHandler = {
            print("cancel process operations")
        }
    }

}

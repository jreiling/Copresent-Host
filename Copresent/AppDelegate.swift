//
//  AppDelegate.swift
//  Copresent
//
//  Created by Jon Reiling on 1/12/21.
//

import Cocoa

@main
class AppDelegate: NSObject, NSApplicationDelegate {

    var activity: NSObjectProtocol?



    func applicationDidFinishLaunching(_ aNotification: Notification) {
        
        // Hack to keep the app responsive in the background.
        activity = ProcessInfo().beginActivity(options: .userInitiatedAllowingIdleSystemSleep, reason: "Good Reason")

        // Insert code here to initialize your application
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
    }


}


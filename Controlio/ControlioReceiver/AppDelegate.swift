//
//  AppDelegate.swift
//  ControlioReceiver
//
//  Created by Avis Luong on 10/16/25.
//

import Cocoa

class AppDelegate: NSObject, NSApplicationDelegate {
    let mc = MCManager()

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        // Insert code here to initialize your application
        mc.onStateChange = { state in
            print("MC state:", state.rawValue)
        }
        mc.onEvents = { events in
            for e in events {
                switch e.t {
                case .pm: print("pm:", e.p.dx ?? 0, e.p.dy ?? 0)
                case .sc: print("sc:", e.p.dx ?? 0, e.p.dy ?? 0)
                case .bt: print("bt:", "c:", e.p.c ?? -1, "s:", e.p.s ?? -1)
                case .gs: print("gs:", "k:", e.p.k ?? -1, "v:", e.p.v ?? -1)
                }
            }
        }
        mc.startAdvertising()
        print("Advertising. Open Trackpad on iPhone to test.")
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
    }

    func applicationSupportsSecureRestorableState(_ app: NSApplication) -> Bool {
        return true
    }


}


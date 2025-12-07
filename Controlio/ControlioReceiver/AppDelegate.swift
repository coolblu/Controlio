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
                case .ax:
                    let id = e.p.c ?? -1
                    let x  = (e.p.k ?? 0)
                    let y  = (e.p.v ?? 0)
                    print("ax:", "id:", id, "x:", x, "y:", y)
                case .rw:
                    let steer = e.p.c ?? 0
                    print("rw:", "steer:", steer, "dz:", e.p.dz ?? 0, "ht:", e.p.ht ?? 0, "tr:", e.p.tr ?? 0)
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


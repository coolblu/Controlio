//
//  EventModel.swift
//  Controlio
//
//  Created by Avis Luong on 10/16/25.
//

import Foundation

/*
 Event types
 pm = pointer move
 bt = button
 sc = scroll
 gs = gesture
 */
enum EVT: String, Codable { case pm, bt, sc, gs}

// payloads for each type
struct EPointer: Codable { let dx: Int; let dy: Int }
struct EButton:  Codable { let c: Int; let s: Int }
struct EScroll:  Codable { let dx: Int; let dy: Int }
struct EGesture: Codable { let k: Int; let v: Int }

// single event container (one obj per msg)
struct Event: Codable {
    let t: EVT
    let p: DataPayload
    
    struct DataPayload: Codable {
        let dx: Int?
        let dy: Int?
        let c: Int?
        let s: Int?
        let k: Int?
        let v: Int?
    }
}

// converts a single event to json
func encodeLine(_ event: Event) -> Data {
    let encoder = JSONEncoder()
    encoder.outputFormatting = []
    guard let jsonData = try? encoder.encode(event) else { return Data() }

    var data = jsonData
    data.append(0x0A) // newline to separate events
    return data
}

// converts data (that has json(s)) back into an array of event objects
func decodeLines(_ data: Data) -> [Event] {
    // split by newline
    let chunks = data.split(separator: 0x0A)
    var events: [Event] = []

    let decoder = JSONDecoder()
    for chunk in chunks {
        if let event = try? decoder.decode(Event.self, from: chunk) {
            events.append(event)
        }
    }

    return events
}

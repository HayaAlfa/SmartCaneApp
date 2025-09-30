//
//  SensorSignalProcessor.swift
//  SmartCane
//
//  Created by Thu Hieu Truong on 9/21/25.
//

import Foundation

class SensorSignal {
    // MARK: - Signal Types
    enum SignalType {
        case front(distance: Int)
        case left(distance: Int)
        case right(distance: Int)
        case stop
        case clear
        case battery(level: Int)
        case error(message: String)
        case unknown
    }
    
    // MARK: - Warning Formulas
    private let formulas: [String: String] = [
        "front": "There is an obstacle %d cm in front of you.",
        "left": "There is an obstacle %d cm on your left, please move right.",
        "right": "There is an obstacle %d cm on your right, please move left.",
        "stop": "Stop immediately.",
        "clear": "The path is clear.",
        "battery": "Battery level is %d%%.",
        "error": "Sensor error detected: %@"
    ]
    
    // MARK: - Public Methods
    
    /// Parse the raw signal string into a SignalType
    private func parseSignal(_ raw: String) -> SignalType {
        if raw.hasPrefix("F:") {
            let parts = raw.split(separator: ":")
            if parts.count >= 2, let dist = Int(parts[1]) {
                return .front(distance: dist)
            }
        } else if raw.hasPrefix("L:") {
            let parts = raw.split(separator: ":")
            if parts.count >= 2, let dist = Int(parts[1]) {
                return .left(distance: dist)
            }
        } else if raw.hasPrefix("R:") {
            let parts = raw.split(separator: ":")
            if parts.count >= 2, let dist = Int(parts[1]) {
                return .right(distance: dist)
            }
        } else if raw == "STOP" {
            return .stop
        } else if raw == "CLEAR" {
            return .clear
        } else if raw.hasPrefix("BAT:") {
            let parts = raw.split(separator: ":")
            if parts.count >= 2, let level = Int(parts[1]) {
                return .battery(level: level)
            }
        } else if raw.hasPrefix("ERR:") {
            let parts = raw.split(separator: ":")
            if parts.count >= 2 {
                let msg = String(parts[1])
                return .error(message: msg)
            }
        }
        return .unknown
    }
    
    /// Receive a signal and produce a warning sentence
    func receiveSignal(_ raw: String) -> String {
        let signal = parseSignal(raw)
        
        switch signal {
        case .front(let distance):
            return String(format: formulas["front"] ?? "", distance)
        case .left(let distance):
            return String(format: formulas["left"] ?? "", distance)
        case .right(let distance):
            return String(format: formulas["right"] ?? "", distance)
        case .stop:
            return formulas["stop"] ?? ""
        case .clear:
            return formulas["clear"] ?? ""
        case .battery(let level):
            return String(format: formulas["battery"] ?? "", level)
        case .error(let msg):
            return String(format: formulas["error"] ?? "", msg)
        case .unknown:
            return "Unknown signal received."
        }
    }
}


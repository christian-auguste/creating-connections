//
//  CustomCanvasView.swift
//  Creating Connections
//
//  Created by Mofei Wang on 3/12/24.
//

import UIKit
import PencilKit

class CustomCanvasView: PKCanvasView {
    // load view controller
    weak var viewController: ViewController?

    // process each touch
    func processTouch(touches: Set<UITouch>) {
        for touch in touches {
            // get distance to closest point in spiral
            let closest = pointMapper(point: touch.location(in: self))

            // get other data from apple pencil
            let location = touch.location(in: self)
            let force = round(100 * touch.force/touch.maximumPossibleForce) / 100
            let altAngle = round(100 * (touch.altitudeAngle * 180 / .pi)) / 100
            let aziAngle = round(100 * (touch.azimuthAngle(in: self) * 180 / .pi)) / 100
            let timestamp = round(100 * touch.timestamp) / 100

            let participant = viewController?.participantNameField.text?.trimmingCharacters(in: .whitespaces) ?? ""
            let trial = viewController?.i ?? 0

            // CSV row: participant,trial,x,y,distance,pressure,alt_angle,azimuth_angle,timestamp
            let log_line = "\(participant),\(trial),\(formatDouble(location.x)),\(formatDouble(location.y)),\(formatDouble(closest)),\(formatDouble(force)),\(formatDouble(altAngle)),\(formatDouble(aziAngle)),\(formatDouble(timestamp))"
            print(log_line)
            viewController?.log += log_line + "\n"

            // update labels
            viewController?.infoLabel1.text = "Location: \(location)"
            viewController?.infoLabel2.text = "Pressure: \(formatDouble(force * 100))%"
            viewController?.infoLabel3.text = "Angle: \(altAngle)°, \(aziAngle)°"
        }
    }

    // find closest point to spiral
    func pointMapper(point : CGPoint) -> Double {
        // get spiral location data
        let SPIRAL_ORIGIN = viewController?.SPIRAL_ORIGIN
        let SPIRAL_COORDS = viewController!.SPIRAL_COORDS

        // set default values
        var closeFlag = false
        var closest = 1000000000000000.0

        // loop over every point in the spiral
        for coord in SPIRAL_COORDS {
            // make a point using coordinates
            let spiral_point = CGPoint(x: SPIRAL_ORIGIN!.x + coord.first!, y: SPIRAL_ORIGIN!.y + coord.last!)
            // find distance between points
            let distance = CGPointDistance(from: point, to: spiral_point)

            // update tracker if closer
            if (distance < closest) {
                closest = distance
            }

            // check if touch is within spiral line (due to line thickness)
            if (distance < 8.0) {
                closeFlag = true
            }
        }

        // round and subtract line thickness
        closest = Double(round(100 * (closest - 8.0)) / 100)

        // update label
        if (closeFlag) {
            viewController?.infoLabel.text = "You're on the line!"
            closest = 0.00
        } else {
            viewController?.infoLabel.text = "You're \(Int(closest)) pixels away from the line"
        }

        return closest
    }

    // find distance between 2 points (squared)
    func CGPointDistanceSquared(from: CGPoint, to: CGPoint) -> CGFloat {
        return (from.x - to.x) * (from.x - to.x) + (from.y - to.y) * (from.y - to.y)
    }

    // find distance between 2 points
    func CGPointDistance(from: CGPoint, to: CGPoint) -> CGFloat {
        return sqrt(CGPointDistanceSquared(from: from, to: to))
    }

    // format double for consistency
    func formatDouble(_ number: Double) -> String {
        return String(format: "%.2f", number)
    }

    // touch begin hook
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesBegan(touches, with: event)
        viewController?.participantNameField.resignFirstResponder()

        print("~~~~~~~~~~~~~~~~~ \(viewController!.i) ~~~~~~~~~~~~~~~~~~~")
        print("------- Max Possible Force: \(touches.first!.maximumPossibleForce) -------")
        print("- participant,trial,x,y,distance,pressure,alt_angle,azimuth_angle,timestamp -")
        processTouch(touches: touches)
    }

    // touch move hook
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesMoved(touches, with: event)
        processTouch(touches: touches)
    }

    // touch end hook
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesEnded(touches, with: event)

        processTouch(touches: touches)
        print("~~~~~~~~~~~~~~~~~ \(viewController!.i) ~~~~~~~~~~~~~~~~~~~\n")

        viewController!.i += 1

        // clear labels
        viewController?.infoLabel.text = "Creating Connections"
        viewController?.infoLabel1.text = "Location:"
        viewController?.infoLabel2.text = "Pressure:"
        viewController?.infoLabel3.text = "Angle:"
    }
}

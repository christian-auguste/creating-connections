//
//  ViewController.swift
//  Creating Connections
//
//  Created by Mofei Wang on 3/4/24.
//

import UIKit
import PencilKit

class ViewController: UIViewController, PKCanvasViewDelegate {
    // app variables
    public var log = ""
    public var i = 1
    private var debug = false

    // init spiral info
    private let spiral = UIImageView(image: UIImage(named: "archimedean_spiral.png"))
    public var SPIRAL_COORDS : [[Double]] = []
    public var SPIRAL_ORIGIN = CGPoint(x: 0, y: 0)

    // struct to deserialize json
    private struct Coordinates: Decodable {
        let coords: [[Double]]
    }

    // custom canvas view to cooperate with touch hooks
    private lazy var canvasView: CustomCanvasView = {
        let canvas = CustomCanvasView()
        canvas.drawingPolicy = .anyInput
        return canvas
    }()

    // participant name field (placed in nav bar title view)
    public let participantNameField: UITextField = {
        let field = UITextField()
        field.placeholder = "Participant name"
        field.borderStyle = .none
        field.font = UIFont.systemFont(ofSize: 17, weight: .regular)
        field.autocorrectionType = .no
        field.autocapitalizationType = .words
        field.textAlignment = .center
        field.frame = CGRect(x: 0, y: 0, width: 320, height: 34)
        return field
    }()

    // info labels
    public let infoLabel: UILabel = {
        let label = UILabel()
        label.textAlignment = .center
        label.textColor = .black
        label.font = UIFont.systemFont(ofSize: 23, weight: .medium)
        return label
    }()

    public let infoLabel1: UILabel = {
        let label = UILabel()
        label.textAlignment = .center
        label.textColor = .black
        label.font = UIFont.systemFont(ofSize: 23, weight: .regular)
        return label
    }()

    public let infoLabel2: UILabel = {
        let label = UILabel()
        label.textAlignment = .center
        label.textColor = .black
        label.font = UIFont.systemFont(ofSize: 23, weight: .regular)
        return label
    }()

    public let infoLabel3: UILabel = {
        let label = UILabel()
        label.textAlignment = .center
        label.textColor = .black
        label.font = UIFont.systemFont(ofSize: 23, weight: .regular)
        return label
    }()

    // done button
    private lazy var doneButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Done", for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 26, weight: .medium)
        button.addTarget(self, action: #selector(done(_:)), for: .touchUpInside)
        return button
    }()

    // debug button
    private lazy var debugButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("D", for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 66, weight: .medium)
        button.addTarget(self, action: #selector(toggleDebug(_:)), for: .touchUpInside)
        return button
    }()

    // called after the controller's view is loaded into memory
    override func viewDidLoad() {
        super.viewDidLoad()

        // force light mode so canvas stays white and spiral stays visible
        overrideUserInterfaceStyle = .light

        // load spiral coordinates
        loadSpiralCoords()

        // participant name field lives in the nav bar — no canvas overlap in any orientation
        navigationItem.titleView = participantNameField

        // add content to view
        view.addSubview(canvasView)
        view.addSubview(doneButton)
        view.addSubview(debugButton)
        view.addSubview(spiral)

        // center spiral
        spiral.translatesAutoresizingMaskIntoConstraints = false
        spiral.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        spiral.centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: 0).isActive = true

        // position done button at bottom
        doneButton.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            doneButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -16),
            doneButton.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 16),
            doneButton.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -16),
            doneButton.heightAnchor.constraint(equalToConstant: 44)
        ])
        debugButton.translatesAutoresizingMaskIntoConstraints = false

        // button colors
        doneButton.setTitleColor(.black, for: .normal)
        debugButton.setTitleColor(.white, for: .normal) // hide

        // settings for canvas
        canvasView.viewController = self
        canvasView.delegate = self
        canvasView.tool = PKInkingTool(.pen, color: .black, width: 7)
    }

    // called when bounds change for view (such as orientation flip)
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        // get coordinate location of spiral on the screen
        let spiralFrame = spiral.superview?.convert(spiral.frame, to: nil) ?? .zero
        SPIRAL_ORIGIN = CGPoint(x: spiralFrame.minX, y: spiralFrame.minY)
        print("Spiral Location\n---------------")
        print("Top Left: \(SPIRAL_ORIGIN)")
        print("Top Right: \(CGPoint(x: spiralFrame.maxX, y: spiralFrame.minY))")
        print("Bottom Left: \(CGPoint(x: spiralFrame.minX, y: spiralFrame.maxY))")
        print("Bottom Right: \(CGPoint(x: spiralFrame.maxX, y: spiralFrame.maxY))\n")

        // set the canvas frame bounds
        canvasView.frame = view.bounds

        // set the label text and positions
        infoLabel.text = "Creating Connections"
        infoLabel.frame = CGRect(x: 0, y: 40, width: view.bounds.width, height: 50)

        infoLabel1.text = "Location:"
        infoLabel1.frame = CGRect(x: 0, y: 80, width: view.bounds.width, height: 50)

        infoLabel2.text = "Pressure:"
        infoLabel2.frame = CGRect(x: 0, y: 120, width: view.bounds.width, height: 50)

        infoLabel3.text = "Angle:"
        infoLabel3.frame = CGRect(x: 0, y: 160, width: view.bounds.width, height: 50)
    }

    // load spiral coordinate data from spiral.json
    func loadSpiralCoords() {
        do {
            if let filePath = Bundle.main.path(forResource: "spiral", ofType: "json") {
                let fileUrl = URL(fileURLWithPath: filePath)
                let data = try Data(contentsOf: fileUrl)
                let decoder = JSONDecoder()
                let jsonData = try decoder.decode(Coordinates.self, from: data)
                SPIRAL_COORDS = jsonData.coords
            }
        } catch {
            print("error: \(error)")
        }
    }

    // debug function to draw out spiral coordinates
    func drawSpiralCoords() {
        for coord in SPIRAL_COORDS {
            let x = SPIRAL_ORIGIN.x + CGFloat(coord[0])
            let y = SPIRAL_ORIGIN.y + CGFloat(coord[1])

            let dotView = UIView(frame: CGRect(x: x, y: y, width: 2, height: 2))
            dotView.backgroundColor = .black

            view.addSubview(dotView)
        }
    }

    // move all points in spiral coordinate by (x, y)
    func moveSpiralCoords(x : Double, y : Double) {
        for (i, _) in SPIRAL_COORDS.enumerated() {
            SPIRAL_COORDS[i][0] += x;
            SPIRAL_COORDS[i][1] += y;
        }
    }

    // scale spiral coordinates by factor
    func resizeSpiralCoords(factor : Double) {
        for (i, _) in SPIRAL_COORDS.enumerated() {
            SPIRAL_COORDS[i][0] *= factor;
            SPIRAL_COORDS[i][1] *= factor;
        }
    }

    // clear canvas and reset labels
    @objc func clearCanvas(_ sender: UIButton) {
        canvasView.drawing = PKDrawing()

        infoLabel.text = "Creating Connections"
        infoLabel1.text = "Location:"
        infoLabel2.text = "Pressure:"
        infoLabel3.text = "Angle:"
    }

    // done - save CSV to Documents and copy to clipboard
    @objc func done(_ sender: UIButton) {
        let name = participantNameField.text?.trimmingCharacters(in: .whitespaces) ?? ""
        let participantName = name.isEmpty ? "unknown" : name
        saveSession(participantName: participantName)
    }

    private func saveSession(participantName: String) {
        let header = "participant,trial,x,y,distance,pressure,alt_angle,azimuth_angle,timestamp\n"
        let csvData = header + log

        // copy to clipboard as fallback
        UIPasteboard.general.string = csvData

        // save to Documents directory
        let df = DateFormatter()
        df.dateFormat = "yyyyMMdd-HHmmss"
        let dateString = df.string(from: Date())
        let safeName = participantName.replacingOccurrences(of: "/", with: "-")
        let fileName = "\(safeName)_\(dateString).csv"
        if let dir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first {
            let fileURL = dir.appendingPathComponent(fileName)
            try? csvData.write(to: fileURL, atomically: true, encoding: .utf8)
        }

        log = ""
        i = 1
        clearCanvas(doneButton)
    }

    // toggle debug stats
    @objc func toggleDebug(_ sender: UIButton) {
        if (debug) {
            infoLabel.removeFromSuperview();
            infoLabel1.removeFromSuperview();
            infoLabel2.removeFromSuperview();
            infoLabel3.removeFromSuperview();
            debug = false
        } else {
            view.addSubview(infoLabel)
            view.addSubview(infoLabel1)
            view.addSubview(infoLabel2)
            view.addSubview(infoLabel3)
            debug = true
        }
    }
}

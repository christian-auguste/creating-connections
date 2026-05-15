//
//  SessionsViewController.swift
//  Creating Connections
//

import UIKit

class SessionsViewController: UITableViewController {

    private struct Session {
        let participantName: String
        let date: Date
        let fileURL: URL
    }

    private struct SectionGroup {
        let title: String
        var sessions: [Session]
    }

    private var groups: [SectionGroup] = []
    private var isSelecting = false

    // nav bar buttons
    private lazy var selectButton = UIBarButtonItem(
        title: "Select", style: .plain, target: self, action: #selector(enterSelectMode)
    )
    private lazy var exportSelectedButton: UIBarButtonItem = {
        let b = UIBarButtonItem(title: "Export Selected", style: .plain, target: self, action: #selector(exportSelected))
        b.isEnabled = false
        return b
    }()
    private lazy var cancelSelectButton = UIBarButtonItem(
        title: "Cancel", style: .plain, target: self, action: #selector(exitSelectMode)
    )
    private lazy var exportAllButton = UIBarButtonItem(
        title: "Export All", style: .plain, target: self, action: #selector(exportAll)
    )

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Sessions"
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
        setNormalModeButtons()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        loadSessions()
        tableView.reloadData()
    }

    // MARK: - Nav bar button state

    private func setNormalModeButtons() {
        navigationItem.leftBarButtonItem = nil
        navigationItem.rightBarButtonItems = [exportAllButton, selectButton]
    }

    private func setSelectModeButtons() {
        navigationItem.leftBarButtonItem = cancelSelectButton
        navigationItem.rightBarButtonItems = [exportSelectedButton]
    }

    // MARK: - Select mode

    @objc private func enterSelectMode() {
        isSelecting = true
        tableView.allowsMultipleSelection = true
        setSelectModeButtons()
        tableView.reloadData()
    }

    @objc private func exitSelectMode() {
        isSelecting = false
        tableView.allowsMultipleSelection = false
        exportSelectedButton.isEnabled = false
        setNormalModeButtons()
        tableView.reloadData()
    }

    // MARK: - Data Loading

    private func loadSessions() {
        guard let dir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
            groups = []
            return
        }

        let files = (try? FileManager.default.contentsOfDirectory(
            at: dir,
            includingPropertiesForKeys: nil
        )) ?? []

        let csvFiles = files.filter { $0.pathExtension == "csv" }

        let df = DateFormatter()
        df.dateFormat = "yyyyMMdd-HHmmss"

        let sessions: [Session] = csvFiles.compactMap { url in
            let filename = url.deletingPathExtension().lastPathComponent
            guard let underscoreRange = filename.range(of: "_", options: .backwards) else { return nil }
            let participantName = String(filename[filename.startIndex..<underscoreRange.lowerBound])
            let datePart = String(filename[underscoreRange.upperBound...])
            // support new date format (yyyyMMdd-HHmmss) and old unix timestamp
            let date: Date
            if let parsed = df.date(from: datePart) {
                date = parsed
            } else if let ts = TimeInterval(datePart) {
                date = Date(timeIntervalSince1970: ts)
            } else {
                return nil
            }
            return Session(participantName: participantName, date: date, fileURL: url)
        }
        .sorted { $0.date > $1.date }

        groups = groupSessions(sessions)
    }

    private func groupSessions(_ sessions: [Session]) -> [SectionGroup] {
        let calendar = Calendar.current
        let now = Date()

        guard let startOfToday = calendar.dateInterval(of: .day, for: now)?.start,
              let startOfYesterday = calendar.date(byAdding: .day, value: -1, to: startOfToday),
              let startOfThisWeek = calendar.dateInterval(of: .weekOfYear, for: now)?.start,
              let startOfLastWeek = calendar.date(byAdding: .weekOfYear, value: -1, to: startOfThisWeek),
              let startOfThisMonth = calendar.dateInterval(of: .month, for: now)?.start,
              let startOfLastMonth = calendar.date(byAdding: .month, value: -1, to: startOfThisMonth)
        else {
            return [SectionGroup(title: "All Sessions", sessions: sessions)]
        }

        let groupMap: [(title: String, predicate: (Date) -> Bool)] = [
            ("Today",      { $0 >= startOfToday }),
            ("Yesterday",  { $0 >= startOfYesterday && $0 < startOfToday }),
            ("This Week",  { $0 >= startOfThisWeek && $0 < startOfYesterday }),
            ("Last Week",  { $0 >= startOfLastWeek && $0 < startOfThisWeek }),
            ("This Month", { $0 >= startOfThisMonth && $0 < startOfLastWeek }),
            ("Last Month", { $0 >= startOfLastMonth && $0 < startOfThisMonth }),
            ("Older",      { $0 < startOfLastMonth })
        ]

        var result: [SectionGroup] = []
        for group in groupMap {
            let matching = sessions.filter { group.predicate($0.date) }
            if !matching.isEmpty {
                result.append(SectionGroup(title: group.title, sessions: matching))
            }
        }
        return result
    }

    // MARK: - Table View

    override func numberOfSections(in tableView: UITableView) -> Int {
        return groups.count
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return groups[section].sessions.count
    }

    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return groups[section].title
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        let session = groups[indexPath.section].sessions[indexPath.row]

        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "EEEE, MMM d 'at' h:mm a"
        let dateString = dateFormatter.string(from: session.date)

        var config = cell.defaultContentConfiguration()
        config.text = session.participantName
        config.secondaryText = dateString
        cell.contentConfiguration = config
        cell.accessoryType = isSelecting ? .none : .disclosureIndicator
        return cell
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if isSelecting {
            exportSelectedButton.isEnabled = (tableView.indexPathsForSelectedRows?.count ?? 0) > 0
            return
        }
        tableView.deselectRow(at: indexPath, animated: true)
        let session = groups[indexPath.section].sessions[indexPath.row]
        shareFile(session.fileURL, sourceIndexPath: indexPath)
    }

    override func tableView(_ tableView: UITableView, didDeselectRowAt indexPath: IndexPath) {
        if isSelecting {
            exportSelectedButton.isEnabled = (tableView.indexPathsForSelectedRows?.count ?? 0) > 0
        }
    }

    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        guard editingStyle == .delete else { return }
        let session = groups[indexPath.section].sessions[indexPath.row]
        try? FileManager.default.removeItem(at: session.fileURL)
        groups[indexPath.section].sessions.remove(at: indexPath.row)
        if groups[indexPath.section].sessions.isEmpty {
            groups.remove(at: indexPath.section)
            tableView.deleteSections(IndexSet(integer: indexPath.section), with: .automatic)
        } else {
            tableView.deleteRows(at: [indexPath], with: .automatic)
        }
    }

    // swipe-to-delete only available outside select mode
    override func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCell.EditingStyle {
        return isSelecting ? .none : .delete
    }

    // MARK: - Export

    private func shareFile(_ url: URL, sourceIndexPath: IndexPath? = nil) {
        let activity = UIActivityViewController(activityItems: [url], applicationActivities: nil)
        if let ip = sourceIndexPath, let cell = tableView.cellForRow(at: ip) {
            activity.popoverPresentationController?.sourceView = cell
            activity.popoverPresentationController?.sourceRect = cell.bounds
        } else {
            activity.popoverPresentationController?.barButtonItem = exportAllButton
        }
        present(activity, animated: true)
    }

    @objc private func exportSelected() {
        guard let selectedPaths = tableView.indexPathsForSelectedRows, !selectedPaths.isEmpty else { return }
        let selectedSessions = selectedPaths.map { groups[$0.section].sessions[$0.row] }
        exportSessions(selectedSessions)
        exitSelectMode()
    }

    @objc private func exportAll() {
        let allSessions = groups.flatMap { $0.sessions }
        guard !allSessions.isEmpty else {
            let alert = UIAlertController(title: "No Sessions", message: "There are no recorded sessions to export.", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default))
            present(alert, animated: true)
            return
        }
        exportSessions(allSessions)
    }

    private func exportSessions(_ sessions: [Session]) {
        let header = "participant,trial,x,y,distance,pressure,alt_angle,azimuth_angle,timestamp\n"
        var combined = header

        for session in sessions {
            if let content = try? String(contentsOf: session.fileURL, encoding: .utf8) {
                let lines = content.components(separatedBy: "\n").dropFirst()
                combined += lines.joined(separator: "\n")
                if !combined.hasSuffix("\n") { combined += "\n" }
            }
        }

        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent("export.csv")
        try? combined.write(to: tempURL, atomically: true, encoding: .utf8)

        let activity = UIActivityViewController(activityItems: [tempURL], applicationActivities: nil)
        activity.popoverPresentationController?.barButtonItem = exportAllButton
        present(activity, animated: true)
    }
}

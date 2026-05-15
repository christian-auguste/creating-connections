# Creating Connections

An iPad app for recording Apple Pencil interactions on an Archimedean spiral, used to collect handwriting and fine motor data from research participants.

Repository: https://github.com/christian-auguste/creating-connections

---

## Requirements

- iPad with Apple Pencil
- Mac with Xcode 15 or later
- Free Apple ID (no paid developer account needed)

---

## Installation

### 1. Clone the repository

**Via Xcode:**
1. Open Xcode → File → Clone Repository
2. Paste `https://github.com/christian-auguste/creating-connections.git` and clone

**Via terminal:**
```bash
git clone https://github.com/christian-auguste/creating-connections.git
cd creating-connections
open "Creating Connections.xcodeproj"
```

---

### 2. One-time signing setup

You only need to do this once on a new Mac.

1. In Xcode, go to **Xcode → Settings → Accounts**
2. Click **+** and sign in with your Apple ID
3. In the project navigator (left sidebar), click **Creating Connections**
4. Go to the **Signing & Capabilities** tab
5. Check **Automatically manage signing**
6. Set **Team** to your Personal Team

If a keychain prompt appears asking for a password, enter your **Mac login password** and click **Always Allow**.

---

### 3. Deploy to your iPad

1. Plug your iPad into your Mac via USB
2. On your iPad, tap **Trust** when asked "Trust This Computer?"
3. In the Xcode toolbar, click the device selector and choose your iPad
4. Click **▶ Run** (or press **⌘R**)
5. On your iPad, go to **Settings → General → VPN & Device Management** and tap **Trust** next to your Apple ID

The app will install and launch automatically.

---

### 4. Re-installing after expiry

Free Apple developer certificates expire every 7 days. If the app won't open on the iPad:

1. Plug the iPad into your Mac
2. Open the project in Xcode
3. Click **▶ Run** — Xcode re-signs and re-installs automatically

---

## Using the App

### Canvas tab — recording a session

1. Enter the participant's name in the text field at the top of the screen
2. Hand the iPad and Apple Pencil to the participant
3. Ask them to trace the grey spiral starting from the **center outward**
4. Each time the pencil lifts and touches down again, that counts as a new **trial** — recording is continuous
5. When the session is complete, tap **Done** at the bottom — this saves the session to local storage and resets the canvas

### Data tab — reviewing and exporting

All saved sessions are listed here, grouped by recency (Today, Yesterday, This Week, etc.), with the participant name and date of each session.

| Action | How |
|---|---|
| Export a single session | Tap it |
| Delete a session | Swipe left |
| Export all sessions as one CSV | Tap **Export All** (top right) |
| Export a selection of sessions | Tap **Select**, choose sessions, tap **Export Selected** |

---

## Data Format

Sessions are saved as CSV files named `<participant>_<YYYYMMDD-HHmmss>.csv`.

| Column | Description |
|---|---|
| `participant` | Name entered in the nav bar field |
| `trial` | Stroke number (increments each time the pencil lifts) |
| `x`, `y` | Touch coordinates in screen pixels |
| `distance` | Distance to nearest point on the spiral in pixels (0 = on the line) |
| `pressure` | Normalised Apple Pencil pressure (0.0–1.0) |
| `alt_angle` | Altitude angle in degrees (90° = pencil perpendicular to screen) |
| `azimuth_angle` | Azimuth angle in degrees (direction the pencil points) |
| `timestamp` | Time in seconds since device boot |

---

## Project Structure

| File | Purpose |
|---|---|
| `ViewController.swift` | Canvas UI, participant name field, Done button, CSV save logic |
| `CustomCanvasView.swift` | PencilKit touch hooks, distance-to-spiral calculation |
| `SessionsViewController.swift` | Session list, date grouping, single/batch export |
| `spiral.json` | Pre-computed Archimedean spiral coordinate points |
| `archimedean_spiral.png` | Spiral overlay image displayed on the canvas |

"""
AttendEase — Raspberry Pi Attendance Server
============================================
Flask server that runs on Raspberry Pi 4 in AP mode.
Handles attendance marking, session management, and real-time student list.

Endpoints:
  GET  /ping              → Health check
  POST /mark              → Mark attendance {uid, name, timestamp}
  GET  /attendance_list    → Get current attendance list
  POST /session/start      → Start session {classId, duration}
  POST /session/stop       → Stop current session

Usage:
  python3 attendance_server.py
  
Server runs on 0.0.0.0:5000
"""

from flask import Flask, request, jsonify
from datetime import datetime
import json
import os

app = Flask(__name__)

# ─── In-Memory Storage ────────────────────────────────────
attendance_list = []
session_active = False
session_info = {}

DATA_FILE = os.path.join(os.path.dirname(os.path.abspath(__file__)), "attendance_data.json")


def save_data():
    """Persist attendance data to JSON file."""
    try:
        with open(DATA_FILE, 'w') as f:
            json.dump(attendance_list, f, indent=2)
    except Exception as e:
        print(f"⚠️  Save error: {e}")


def load_data():
    """Load attendance data from JSON file on startup."""
    global attendance_list
    if os.path.exists(DATA_FILE):
        try:
            with open(DATA_FILE, 'r') as f:
                attendance_list = json.load(f)
            print(f"📂 Loaded {len(attendance_list)} existing records")
        except Exception as e:
            print(f"⚠️  Load error: {e}")
            attendance_list = []


# ─── Routes ───────────────────────────────────────────────

@app.route('/ping', methods=['GET'])
def ping():
    """Health check endpoint."""
    return jsonify({
        "status": "ok",
        "message": "AttendEase Pi Server is running",
        "session_active": session_active,
        "student_count": len(attendance_list),
        "timestamp": datetime.now().isoformat()
    }), 200


@app.route('/mark', methods=['POST'])
def mark_attendance():
    """Mark attendance for a student."""
    data = request.get_json()

    if not data:
        return jsonify({"error": "No JSON body provided"}), 400

    uid = data.get('uid', '').strip()
    name = data.get('name', '').strip()
    timestamp = data.get('timestamp', datetime.now().isoformat())

    if not uid or not name:
        return jsonify({"error": "uid and name are required"}), 400

    # Check for duplicate marking
    for record in attendance_list:
        if record['uid'] == uid:
            return jsonify({
                "message": f"{name} already marked",
                "status": "duplicate"
            }), 200

    # Add new record
    record = {
        "uid": uid,
        "name": name,
        "timestamp": timestamp,
        "status": "present"
    }
    attendance_list.append(record)
    save_data()

    print(f"✅ Attendance marked: {name} ({uid}) at {timestamp}")
    return jsonify({
        "message": "Attendance marked successfully",
        "status": "success"
    }), 201


@app.route('/attendance_list', methods=['GET'])
def get_attendance_list():
    """Get the current attendance list (used by teacher app for real-time polling)."""
    return jsonify({
        "students": attendance_list,
        "count": len(attendance_list),
        "session_active": session_active
    }), 200


@app.route('/session/start', methods=['POST'])
def start_session():
    """Start a new attendance session. Clears previous attendance data."""
    global session_active, session_info, attendance_list

    data = request.get_json() or {}

    # Clear previous session's attendance
    attendance_list = []
    save_data()

    session_active = True
    session_info = {
        "classId": data.get('classId', 'unknown'),
        "duration": data.get('duration', 15),
        "startTime": datetime.now().isoformat()
    }

    print(f"📢 Session started — Class: {session_info['classId']}, Duration: {session_info['duration']}min")
    return jsonify({
        "message": "Session started",
        "status": "success",
        "session": session_info
    }), 200


@app.route('/session/stop', methods=['POST'])
def stop_session():
    """Stop the current attendance session."""
    global session_active

    session_active = False
    count = len(attendance_list)

    print(f"🛑 Session stopped — {count} students marked")
    return jsonify({
        "message": "Session stopped",
        "status": "success",
        "total_marked": count
    }), 200


# ─── Main ─────────────────────────────────────────────────

if __name__ == '__main__':
    load_data()
    print("=" * 50)
    print("🚀 AttendEase Pi Server")
    print("   Running on http://0.0.0.0:5000")
    print("   Endpoints: /ping, /mark, /attendance_list")
    print("              /session/start, /session/stop")
    print("=" * 50)
    app.run(host='0.0.0.0', port=5000, debug=False)

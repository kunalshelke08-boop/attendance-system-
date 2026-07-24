# Raspberry Pi 4 Setup Guide — AttendEase

## Hardware Required
- Raspberry Pi 4 (with USB-C power supply)
- MicroSD card (16GB+) with Raspberry Pi OS installed
- Monitor + keyboard for initial setup (or SSH after first boot)

---

## Step 1: Initial Pi OS Setup

```bash
# Update system
sudo apt update && sudo apt upgrade -y

# Install Python & Flask
sudo apt install python3 python3-pip -y
pip3 install flask
```

---

## Step 2: Configure Pi as Wi-Fi Access Point (AP Mode)

This makes the Pi broadcast its own Wi-Fi network that phones connect to.

### Install AP packages
```bash
sudo apt install hostapd dnsmasq -y
sudo systemctl stop hostapd
sudo systemctl stop dnsmasq
```

### Configure static IP for wlan0
Edit `/etc/dhcpcd.conf` — add at the **bottom**:
```
interface wlan0
    static ip_address=192.168.4.1/24
    nohook wpa_supplicant
```

### Configure DHCP server
Edit `/etc/dnsmasq.conf` — replace entire contents with:
```
interface=wlan0
dhcp-range=192.168.4.2,192.168.4.50,255.255.255.0,24h
```

### Configure Wi-Fi AP
Create `/etc/hostapd/hostapd.conf`:
```
interface=wlan0
driver=nl80211
ssid=AttendEase_AP
hw_mode=g
channel=7
wmm_enabled=0
macaddr_acl=0
auth_algs=1
ignore_broadcast_ssid=0
wpa=2
wpa_passphrase=attend1234
wpa_key_mgmt=WPA-PSK
wpa_pairwise=TKIP
rsn_pairwise=CCMP
```

### Point hostapd to config
Edit `/etc/default/hostapd`, set:
```
DAEMON_CONF="/etc/hostapd/hostapd.conf"
```

### Enable and start
```bash
sudo systemctl unmask hostapd
sudo systemctl enable hostapd
sudo systemctl start hostapd
sudo systemctl restart dnsmasq
sudo reboot
```

After reboot, your Pi will broadcast:
- **SSID**: `AttendEase_AP`
- **Password**: `attend1234`
- **Pi IP**: `192.168.4.1`

---

## Step 3: Copy Server Script to Pi

Copy the `attendance_server.py` file from the `rpi_server/` folder to your Pi:

```bash
# From your PC (replace pi_ip with Pi's IP if on same network)
scp attendance_server.py pi@<pi_ip>:/home/pi/attendance_server.py

# Or use a USB drive to copy the file
```

---

## Step 4: Auto-Start Server on Boot

Create systemd service:
```bash
sudo nano /etc/systemd/system/attendance.service
```

Paste this:
```ini
[Unit]
Description=AttendEase Attendance Server
After=network.target

[Service]
ExecStart=/usr/bin/python3 /home/pi/attendance_server.py
WorkingDirectory=/home/pi
User=pi
Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target
```

Enable and start:
```bash
sudo systemctl daemon-reload
sudo systemctl enable attendance.service
sudo systemctl start attendance.service

# Check status
sudo systemctl status attendance.service
```

---

## Step 5: Verify Server

Connect a phone/laptop to `AttendEase_AP` Wi-Fi, then test:

```bash
# Health check
curl http://192.168.4.1:5000/ping

# Mark test attendance
curl -X POST http://192.168.4.1:5000/mark \
  -H "Content-Type: application/json" \
  -d '{"uid": "test123", "name": "Test User", "timestamp": "2026-07-24T10:00:00"}'

# Get attendance list
curl http://192.168.4.1:5000/attendance_list

# Start session
curl -X POST http://192.168.4.1:5000/session/start \
  -H "Content-Type: application/json" \
  -d '{"classId": "CS-A", "duration": 15}'

# Stop session
curl -X POST http://192.168.4.1:5000/session/stop
```

---

## Troubleshooting

| Problem | Solution |
|---------|----------|
| Can't see `AttendEase_AP` Wi-Fi | Run `sudo systemctl status hostapd` — check for errors |
| Server not responding | Run `sudo systemctl status attendance` — check logs |
| Phone can't connect | Check dhcpcd and dnsmasq are running |
| "Connection refused" | Make sure server runs on `0.0.0.0:5000`, not `127.0.0.1` |
| Server crashes on reboot | Check `sudo journalctl -u attendance.service` for errors |

---

## Test Flow Summary

1. Power on Pi → it auto-starts AP + server
2. Connect all phones to `AttendEase_AP` (password: `attend1234`)
3. Open AttendEase app on **Teacher phone** → Start session
4. Open app on **Student phones** → Mark attendance (biometric → sends to Pi)
5. Teacher sees students appear in real-time list
6. Teacher stops session
7. Later, connect phones to internet → data auto-syncs to Firebase

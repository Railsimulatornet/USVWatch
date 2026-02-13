# USVWatch (UGREEN NAS)

USVWatch ist ein leichtgewichtiges Monitoring-Skript für UGREEN NAS (UGOS Pro).
Es liest den Status einer USV (UPS) über **NUT** aus und versendet bei Ereignissen und Schwellwerten einen Outlook-freundlichen HTML-Report per E-Mail.

## Features

- NUT-Statusabfrage (UGOS Pro USV Dienst), Standard: localhost:3493
- Ereignisbasierte Benachrichtigungen (z.B. Stromausfall, Batteriebetrieb, Netzstrom wieder da)
- Schwellwerte für Akkuladung und verbleibende Laufzeit
- Anti-Spam: Status wird gespeichert, E-Mails nur bei Wechsel (optional Re-Send)
- Optionaler Tagesreport zu einer festen Uhrzeit
- Optional: NUT Instant Commands anzeigen und ausführen
- Python 3, nur Standardbibliothek

## Screenshots


| Stromausfall (Batteriebetrieb) | Netzstrom wieder da |
|---|---|
| ![USVWatch: Stromausfall (Batteriebetrieb)](https://github.com/Railsimulatornet/USVWatch/blob/main/Screens/USVWatchv1DE2.jpg) | ![USVWatch: Netzstrom wieder da](https://github.com/Railsimulatornet/USVWatch/blob/main/Screens/USVWatchv1DE.jpg) |

## Projektstruktur

```
usvwatch/
  usvwatch.py
  usvwatch-loop.sh
  usvwatch.env
docs/
  images/
    usvwatch-stromausfall.jpg
    usvwatch-netzstrom.jpg
USVWatch_Handbuch_Manual_DE-EN_v1.pdf
```

## Voraussetzungen

- UGREEN NAS mit aktiviertem USV/UPS Dienst (NUT)
- Python 3 verfügbar

## Installation (Quickstart)

1) Ordner auf das NAS kopieren, z.B.:
`/volumeX/docker/USVWatch/usvwatch/`

2) Konfiguration anpassen:
- Datei `usvwatch/usvwatch.env` bearbeiten
- Pflichtfelder für Mailversand:
  - `SMTP_HOST`
  - `MAIL_FROM`
  - `MAIL_TO`

3) Testmail senden:
```bash
cd /volumeX/docker/USVWatch/usvwatch
/usr/bin/python3 usvwatch.py --test-mail
```

4) Loop starten (prüft alle 10 Sekunden):
```bash
chmod +x usvwatch-loop.sh
./usvwatch-loop.sh start
```

5) Status und Log:
```bash
./usvwatch-loop.sh status
./usvwatch-loop.sh tail
```

Stop / Restart:
```bash
./usvwatch-loop.sh stop
./usvwatch-loop.sh restart
```

## CLI Optionen

```bash
python3 usvwatch.py --print-status
python3 usvwatch.py --test-mail
python3 usvwatch.py --list-commands
python3 usvwatch.py --run-cmd <CMD>
python3 usvwatch.py --run-cmd <CMD> --run-cmd-mail
```

Optional kannst du eine andere env-Datei laden:
```bash
python3 usvwatch.py --env /pfad/zur/usvwatch.env --test-mail
```

## Konfiguration (usvwatch.env)

Wichtige Variablen (Auszug):

- Sprache:
  - `USVWATCH_LANG=de`
  - `HOST_LABEL=` (optional, sonst System-Hostname)

- NUT:
  - `NUT_HOST=127.0.0.1`
  - `NUT_PORT=3493`
  - `NUT_TIMEOUT=5`
  - `NUT_UPS_NAME=` (leer lassen, wenn nur eine USV vorhanden ist)
  - Optional Auth:
    - `NUT_USERNAME=nut`
    - `NUT_PASSWORD=nut`

- SMTP:
  - `SMTP_HOST=`
  - `SMTP_PORT=587`
  - `SMTP_TLS=starttls` (starttls, ssl, none)
  - `SMTP_TLS_VERIFY=1`
  - `SMTP_USER=` / `SMTP_PASS=` (optional)
  - `MAIL_FROM=`
  - `MAIL_TO=` (kommagetrennt)
  - Optional:
    - `MAIL_CC=`
    - `MAIL_BCC=`

- Alerts:
  - `ALERT_ON_BATTERY=1`
  - `ALERT_BACK_ONLINE=1`
  - `ALERT_LOW_BATTERY=1`
  - `ALERT_CHARGE_LOW=1`
  - `ALERT_RUNTIME_LOW=1`
  - `ALERT_UNREACHABLE=1`
  - `ALERT_RECOVERED=1`

- Schwellwerte:
  - `CHARGE_THRESHOLD_PERCENT=20`
  - `RUNTIME_THRESHOLD_MIN=10`

- Re-Send (Minuten, 0 = nie):
  - `THRESHOLD_RESEND_MIN=60`
  - `UNREACHABLE_RESEND_MIN=120`

- Tagesreport:
  - `ENABLE_DAILY_REPORT=0`
  - `DAILY_REPORT_TIME=09:00`

## Dokumentation

- Handbuch (PDF): `USVWatch_Handbuch_Manual_DE-EN_v1.pdf`

## Sicherheit (wichtig)

Bitte keine echten SMTP-Zugangsdaten in GitHub committen.
Empfehlung: `usvwatch.env` im Repo als Template belassen und Zugangsdaten nur lokal auf dem NAS setzen.

## Autor

Copyright (c) 2026 Roman Glos

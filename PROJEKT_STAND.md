# Reiseroute – Projektstand für Claude Code

## Kontext
Diese App wurde ursprünglich als Claude.ai Artifact (einzelne HTML-Datei) entwickelt und
getestet. `app.html` ist dieser ursprüngliche, getestete Stand und bleibt als Referenz/Backup
im Repo — die aktive App ist jetzt **`index.html`** (PWA-Umbau, siehe unten).

## Was die App aktuell kann
- Reisen anlegen: Land/Länder (kommagetrennt, ersetzt "Name der Reise"), Von/Bis-Datum, Notizen
- Pro Reise: **Orte** anlegen (Name, optionale Ankunft/Abreise, optionale Notiz), jeder Ort kann
  mehrere **Aktivitäten** enthalten (Titel + optionale mehrzeilige Bemerkung). Orte werden als
  Liste angezeigt, sortiert nach Ankunftsdatum (Orte ohne Datum stehen am Ende). Frühere
  Tages-Gliederung (Tag 1, Tag 2, …) wurde durch dieses Orte/Aktivitäten-Modell ersetzt.
- Marker auf Karte (Leaflet + OpenStreetMap) sind pro Ort OPTIONAL — Ort kann ohne Position
  gespeichert und später über einen Button nachträglich platziert werden
- Marker sind eigene Inline-SVG-Pins (kein externes Icon-Bild, das war ein früherer Bug)
- Orte und Aktivitäten bearbeitbar, Reisen bearbeitbar (Länder/Daten/Notizen)
- Zwei Tabs: "Reisen" (Liste + Detail) und "Besuchte Länder" (aggregiert aus trip.countries,
  zeigt Datum der jeweils AKTUELLSTEN Reise pro Land, Gesamtzahl der Länder)
- Übersichtskarte auf der Startseite: alle Reisen, unterschiedliche Farbe pro Reise, nur Ansicht
  (nicht editierbar, kein Klick-Handler)
- Passwortschutz: Login-Screen vor der App, Passwort "Jackyy", nach korrekter Eingabe merkt sich
  das Gerät den Zugang

### Datenmodell (index.html)
```
Trip { id, name, dateFrom, dateTo, notes, countries[], places: [Place] }
Place { id, name, arrival (Datum|null), departure (Datum|null), note, lat, lng, activities: [Activity] }
Activity { id, title, note }
```
Alte, bereits gespeicherte Reisen im Vorgänger-Format (`trip.days = {date: [Station]}`) werden
beim Laden automatisch nach `trip.places` migriert (`migrateTripIfNeeded()` in `index.html`) —
keine Daten gehen dabei verloren, jede Station wird zu einem Ort mit einer Aktivität.

## PWA-Umbau — Status: fertig, lokal getestet
Ziel-Architektur (mit Nutzer abgestimmt): Alle Daten NUR lokal auf dem iPhone (kein Server,
kein Backend, keine Cloud), installierbar als Homescreen-Icon, läuft komplett offline.

Umgesetzt:
1. **Datenspeicherung**: `window.storage` (Claude.ai-spezifisch, existiert außerhalb von
   Artifacts nicht) ersetzt durch echten IndexedDB-Wrapper in `index.html`
   (DB `reiseroute-db`, Store `kv`, gleiche Keys `trips`/`access_unlocked` wie vorher).
2. **Leaflet lokal eingebunden**: `vendor/leaflet/` (JS, CSS, Marker-/Layer-Bilder) statt
   CDN-Links — nötig, damit die Karten-Library auch offline aus dem Service-Worker-Cache kommt.
   Hinweis: Die Kartenkacheln selbst (OpenStreetMap-Tiles) kommen weiterhin aus dem Internet;
   bereits angesehene Kachel-Ausschnitte werden vom Service Worker zusätzlich gecacht, aber die
   Weltkarte kann nicht komplett offline vorgehalten werden — das ist normal für Kartenapps.
3. **`manifest.json`**: Name, Icons, `display: standalone`, Theme-Farben — macht die App
   "Zum Home-Bildschirm hinzufügen"-fähig.
4. **App-Icons**: `icons/icon-192.png`, `icon-512.png`, `icon-maskable-512.png`,
   `apple-touch-icon.png` — generiert per `scripts/make-icons.ps1` (Kompass-Motiv, passend zum
   App-Design). Skript kann bei Bedarf erneut ausgeführt werden, falls Icons angepasst werden
   sollen.
5. **`service-worker.js`**: Cached die komplette App-Hülle (HTML, CSS, JS, Icons, Leaflet)
   beim ersten Aufruf; App-Shell wird danach "cache-first" ausgeliefert und läuft dadurch
   komplett offline. Bei Code-Änderungen an der App: `CACHE_VERSION` in `service-worker.js`
   hochzählen, damit Nutzer:innen die neue Version bekommen.

Automatisiert getestet (Headless-Chrome via Playwright): Login, IndexedDB-Persistenz über
Reload hinweg, Service-Worker-Aktivierung, und vollständiger Offline-Reload (Service Worker
liefert App-Hülle ohne Netzwerk, IndexedDB-Session bleibt erhalten, keine JS-Fehler).

## Bekannte gelöste Bugs (nicht wiederholen)
- Zeitzonen-Bug bei Tagesberechnung: NIE `new Date(iso+'T00:00:00').toISOString()` mischen
  (lokale Zeit + UTC-Konvertierung verschiebt Datum um 1 Tag bei UTC+2). Immer mit
  `Date.UTC(y,m-1,d)` rechnen und konsistent UTC-Methoden nutzen.
- Leaflet-Marker-Icons von CDN-Bildpfaden laden in Sandbox-Umgebungen oft nicht → eigene
  Inline-SVG-Icons verwenden (siehe `pinIcon()` Funktion in index.html)
- z-index-Konflikt: Leaflet-Karten-Panes können Dialoge/Overlays überlagern → Dialog-Overlay
  muss deutlich höheren z-index haben (aktuell 2000) als Kartencontainer (z-index 1)

## Projektstruktur
```
index.html            aktive App (PWA-Entry-Point, für GitHub Pages)
app.html               alter Claude.ai-Artifact-Stand (Backup/Referenz, nicht mehr aktiv)
manifest.json          Web App Manifest
service-worker.js      Offline-Caching
vendor/leaflet/        lokal eingebundene Leaflet-Library (JS/CSS/Bilder)
icons/                 App-Icons in versch. Größen
scripts/make-icons.ps1 Icon-Generator (PowerShell/System.Drawing)
```

## Nächster Schritt: GitHub Pages Deploy
Git-Repo ist lokal eingerichtet. Für den Deploy braucht es einmalig manuelle Schritte mit
GitHub-Zugangsdaten des Nutzers (kann nicht automatisiert werden, da Kontoerstellung/Login
nötig ist):
1. Auf github.com ein neues, leeres Repository anlegen (z.B. "reiseroute").
2. Von Claude Code aus lokalen Branch pushen (Remote-URL wird dann eingerichtet).
3. In den Repo-Einstellungen unter "Pages" → "Deploy from a branch" → Branch `main`, Ordner
   `/ (root)` auswählen.
4. Nach ein paar Minuten ist die App unter `https://<username>.github.io/<repo-name>/`
   erreichbar → dort auf dem iPhone in Safari öffnen → Teilen-Button → "Zum Home-Bildschirm".

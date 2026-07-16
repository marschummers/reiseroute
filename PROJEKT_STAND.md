# Reiseroute – Projektstand für Claude Code

## Kontext
Diese App wurde ursprünglich als Claude.ai Artifact (einzelne HTML-Datei) entwickelt und
getestet. `app.html` ist dieser ursprüngliche, getestete Stand und bleibt als Referenz/Backup
im Repo — die aktive App ist jetzt **`index.html`** (PWA-Umbau, siehe unten).

## Was die App aktuell kann
- Reisen anlegen: Land/Länder über Autocomplete-Suche mit Flaggen-Emoji (Freitext als Fallback
  möglich, falls ein Land nicht in der Liste ist), Von/Bis-Datum, Notizen
- Pro Reise: **Orte** anlegen (Name, optionale Ankunft/Abreise, optionale Notiz), jeder Ort kann
  mehrere **Aktivitäten** enthalten (Name + optionales Datum/Uhrzeit + optionale Bemerkung). Orte
  werden als Liste angezeigt, sortiert nach Ankunftsdatum (Orte ohne Datum stehen am Ende).
  Frühere Tages-Gliederung (Tag 1, Tag 2, …) wurde durch dieses Orte/Aktivitäten-Modell ersetzt.
- Pro Ort: **Fotos** anhängen (Kamera/Fotomediathek über den nativen iOS-Dialog), werden lokal in
  IndexedDB gespeichert (nicht im Trips-JSON) und beim Hochladen automatisch verkleinert.
- Marker auf Karte (Leaflet + OpenStreetMap) sind pro Ort OPTIONAL — Ort kann ohne Position
  gespeichert und später über einen Button nachträglich platziert werden
- Marker sind eigene Inline-SVG-Pins (kein externes Icon-Bild, das war ein früherer Bug)
- **Ortssuche beim Namen-Eintippen** (Anlegen und Bearbeiten eines Orts): Vorschlagsliste per
  Nominatim/OpenStreetMap-Geocoding (z.B. "Seefeld" → "Seefeld in Tirol" zur Auswahl), Auswahl
  übernimmt Name UND Position direkt — kein Antippen der Karte mehr nötig. Freitext ohne
  Vorschlags-Auswahl funktioniert weiterhin (Fallback: Position später manuell auf der Karte
  setzen). Braucht Internet im Moment der Suche (wie die Kartenkacheln selbst).
- Orte und Aktivitäten bearbeitbar, Reisen bearbeitbar (Länder/Daten/Notizen)
- Reisen löschbar per Swipe-nach-links auf der Reisen-Karte (iOS-Standardmuster wie bei
  Mail/Erinnerungen), mit Bestätigungsabfrage — löscht auch alle Orte, Aktivitäten und Fotos
  dieser Reise mit (inkl. Aufräumen verwaister Foto-Blobs in IndexedDB)
- **Wunschliste**: separate Sammlung von Ländern (+ optionale Stichwort-Orte, + optionale Notiz),
  bewusst OHNE Datum — für "das will ich irgendwann noch bereisen", getrennt von den konkret
  geplanten/vergangenen Reisen mit Datum.
- Drei Tabs: "Reisen" (Liste + Detail), "Wunschliste", "Statistiken" (früher "Besuchte Länder" —
  Kacheln für Reisen/Länder/gereiste Tage gesamt, Weltkarte mit in Messing eingefärbten besuchten
  Ländern, Reisen-pro-Jahr-Übersicht, Länderliste mit Datum der jeweils AKTUELLSTEN Reise pro
  Land, plus der Datensicherungs-Bereich siehe unten)
- **Datensicherung**: Export/Import als JSON-Datei (inkl. aller Fotos), auf der Statistiken-Seite.
  Export nutzt die iOS-Teilen-Funktion (Sichern in Dateien-App, AirDrop, Mail, iCloud Drive …),
  mit Direkt-Download als Fallback, falls Web-Share nicht verfügbar ist (z.B. Desktop-Browser).
  Import ersetzt nach Bestätigung alle aktuellen Daten — das ist auch der Weg für einen
  Geräte-Wechsel: auf dem alten Gerät exportieren, auf dem neuen importieren.
- **Suche** (🔍-Button im Header auf Reisen/Wunschliste/Statistiken): Volltextsuche über
  Reise-Länder, Orte und Aktivitäten (inkl. deren Notiz-Texte), gruppierte Ergebnisliste, Tippen
  auf ein Ergebnis öffnet die passende Reise (bei Orten/Aktivitäten direkt mit aufgeklapptem Ort).
  Rein lokal, kein Netzwerk nötig.
- Übersichtskarte auf der Startseite: alle Reisen, unterschiedliche Farbe pro Reise, nur Ansicht
  (nicht editierbar, kein Klick-Handler)
- **Titelfoto** je Reise in der Reisenliste (automatisch das erste Foto des ersten Orts mit
  Fotos, sortiert nach Ankunftsdatum — keine manuelle Auswahl, keine zusätzliche UI dafür)
- **Nächste-Reise-Hinweis**: Banner ganz oben auf der Startseite, zeigt entweder eine gerade
  laufende Reise ("Du bist gerade unterwegs") oder einen Countdown zur zeitlich nächsten
  anstehenden Reise ("Noch 15 Tage bis …"), antippen öffnet die jeweilige Reise
- **Gereiste Distanz** auf der Statistiken-Seite: Luftlinien-Summe zwischen den platzierten Orten
  je Reise (Haversine-Formel), mit spielerischem Vergleich zur Erdumrundung (40.075 km)
- Kein Passwortschutz (mehr) — die App wurde ursprünglich mit einem simplen Passwort-Gate
  ausgeliefert, das aber ohnehin keine echte Sicherheit bot (Passwort stand im Klartext im
  JS-Quelltext). Da alle Daten sowieso nur lokal auf dem Gerät liegen, wurde der Login-Screen auf
  Wunsch entfernt — die App öffnet jetzt direkt in der Reisenliste.

### Datenmodell (index.html)
```
Trip { id, name, dateFrom, dateTo, notes, countries[], places: [Place] }
Place { id, name, arrival (Datum|null), departure (Datum|null), note, lat, lng,
        activities: [Activity], photoIds: [string] }
Activity { id, name, date (Datum|null), time (Uhrzeit|null), note }
WishlistItem { id, countries[], places: [string], note }   // eigener Storage-Key 'wishlist'
```
Gedachte Nutzung: Der Ort trägt das grobe Datum (z.B. für alte Reisen, wo man nur noch weiß
"Anfang der Mexiko-Reise 2024 war ich in Tulum"). Die Aktivität kann zusätzlich ein präzises
Datum/Uhrzeit bekommen (z.B. "Whale Watching Tour am 3.10. um 9 Uhr") — das Aktivitäts-Datum
wird beim Speichern validiert und muss innerhalb der Ankunft/Abreise des zugehörigen Orts liegen
(falls dieser welche hat). Orte werden nach Ankunftsdatum sortiert, Aktivitäten innerhalb eines
Orts nach Datum/Uhrzeit (undatierte jeweils ans Ende).

Alte, bereits gespeicherte Reisen (egal ob im ursprünglichen Tages-Format `trip.days`, im
zwischenzeitlichen Orte-Format mit `activity.title` statt `activity.name`, oder ohne
`place.photoIds`) werden beim Laden automatisch verlustfrei auf die aktuelle Struktur migriert
(`migrateTripIfNeeded()` in `index.html`).

### Fotos
Fotos liegen NICHT im `trips`-JSON (das würde bei jeder Kleinigkeit den kompletten, dann
riesigen Blob neu schreiben), sondern in einem eigenen IndexedDB-Objectstore `photos`
(`DB_VERSION = 2` in `index.html`, Store hält `{id, placeId, blob, createdAt}`). Ein Ort
referenziert seine Fotos nur über `place.photoIds` (Array von IDs). Vor dem Speichern werden
Fotos über `resizeImageToBlob()` verkleinert (längste Kante max. 1600px, JPEG ~82% Qualität) —
Kamerafotos vom iPhone sind sonst oft 3–8 MB groß. `createImageBitmap(file, {imageOrientation:
'from-image'})` sorgt dafür, dass hochkant aufgenommene Fotos nicht gedreht landen (Canvas
ignoriert EXIF-Rotation sonst).

Anzeige: In der Ort-Karte steht nur eine kompakte Vorschau (max. 3 Thumbnails + "+",
`photoPreviewHtml()`), die auf die vollständige Galerie verweist (`openPhotoGallery()`, als
Sheet). Erst dort werden alle Fotos geladen (`renderGalleryPhotos()`), Fotos einzeln entfernt
(`removePhotoFromGallery()`) oder groß angesehen (Lightbox). Bild-Blob-URLs werden in
`photoObjectUrls` gecacht (`getPhotoUrl()`) und bewusst nicht laufend wieder freigegeben — bei
den paar Dutzend Fotos, die realistisch in einer Sitzung angesehen werden, ist das
vernachlässigbar, und der Browser räumt beim Neuladen ohnehin auf.

### Länder-Autocomplete
`data/countries.js` enthält eine lokal generierte Liste aller ~250 Länder (deutscher Name +
ISO-3166-1-Alpha-2-Code, keine Laufzeit-Abhängigkeit von einer API). Flaggen-Emoji werden aus
dem Code berechnet (`codeToFlag()` in `index.html`, Standard-Unicode-Regional-Indicator-Technik).
Bei der Länder-Eingabe (neue/bearbeitete Reise) tippt man z.B. "Süd" und bekommt passende
Vorschläge inkl. Flagge; ausgewählte Länder werden als Chips angezeigt. Freitext-Eingaben (Land
nicht in der Liste) funktionieren weiterhin als Fallback, bekommen dann aber keine Flagge.
Hinweis: Flaggen-Emoji werden auf iPhone/Safari korrekt als Bild dargestellt; auf Windows kann es
je nach Schriftart/Browser sein, dass nur die zwei Buchstaben des Ländercodes angezeigt werden —
das ist eine Windows-Einschränkung, kein Bug.

### Weltkarte ("Besuchte Länder")
`data/world-map.js` enthält Länderumrisse als SVG-Pfade (Schlüssel = ISO-Code), extrahiert aus
`neveldo/jQuery-Mapael` (MIT-Lizenz, ursprünglich abgeleitet von Wikimedia Commons
"BlankMap-World6-Equirectangular.svg"), 176 Länder, keine Laufzeit-Abhängigkeit. `worldMapHtml()`
in `index.html` baut daraus ein statisches (nicht zoombares) Inline-SVG und färbt die Pfade, deren
Code zu einem besuchten Land passt, in Messing ein. Länder, die nur per Freitext erfasst wurden
(nicht in `data/countries.js`), bleiben auf der Karte ungefärbt, tauchen aber ganz normal in der
Liste darunter auf.

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
- Header/Zurück-Button lag auf iPhones mit Notch/Dynamic Island unter der Statusleiste und war
  nicht klickbar → `padding-top` des Headers (und die Position des Platzierungs-Banners)
  müssen `env(safe-area-inset-top)` einrechnen (nur sichtbar auf echtem Gerät, nicht im
  Chrome-Test unter Windows, da dort kein Notch simuliert wird)

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

## Deploy
Live unter **https://marschummers.github.io/reiseroute/** (GitHub Pages, Branch `main`,
Ordner `/ (root)`). Auf dem iPhone in Safari öffnen → Teilen-Button → "Zum Home-Bildschirm", dann
läuft die App als eigenständige, offline-fähige App vom Homescreen.

Workflow für Änderungen: lokal in `index.html`/`service-worker.js`/etc. ändern, mit
`npx http-server -p 5173 -c-1 .` lokal auf `http://localhost:5173/` testen, `CACHE_VERSION` in
`service-worker.js` hochzählen, committen & pushen (`git push origin main`) — GitHub Pages baut
automatisch neu (dauert ~1–2 Min). Auf dem iPhone wird die neue Version aktiv, sobald die App bei
bestehender Internetverbindung einmal (ggf. zweimal) komplett geschlossen und neu geöffnet wird.

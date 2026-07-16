// Bei jeder inhaltlichen Änderung an der App die Versionsnummer erhöhen,
// damit Nutzer:innen die neue Version bekommen (alte Caches werden dann verworfen).
const CACHE_VERSION = 'v9';
const APP_CACHE = `reiseroute-app-${CACHE_VERSION}`;
const TILE_CACHE = 'reiseroute-tiles';

const APP_SHELL = [
  './',
  './index.html',
  './manifest.json',
  './data/countries.js',
  './vendor/leaflet/leaflet.css',
  './vendor/leaflet/leaflet.js',
  './vendor/leaflet/images/marker-icon.png',
  './vendor/leaflet/images/marker-icon-2x.png',
  './vendor/leaflet/images/marker-shadow.png',
  './vendor/leaflet/images/layers.png',
  './vendor/leaflet/images/layers-2x.png',
  './icons/icon-192.png',
  './icons/icon-512.png',
  './icons/icon-maskable-512.png',
  './icons/apple-touch-icon.png'
];

self.addEventListener('install', (event) => {
  event.waitUntil(
    caches.open(APP_CACHE)
      .then((cache) => cache.addAll(APP_SHELL))
      .then(() => self.skipWaiting())
  );
});

self.addEventListener('activate', (event) => {
  event.waitUntil(
    caches.keys().then((keys) =>
      Promise.all(
        keys
          .filter((key) => key !== APP_CACHE && key !== TILE_CACHE)
          .map((key) => caches.delete(key))
      )
    ).then(() => self.clients.claim())
  );
});

self.addEventListener('fetch', (event) => {
  const req = event.request;
  if (req.method !== 'GET') return;

  const url = new URL(req.url);

  // Kartenkacheln (OpenStreetMap): Netzwerk zuerst, sonst zuletzt gesehene Kachel
  // aus dem Cache — Karten brauchen ohnehin meist Internet, aber bereits
  // angesehene Ausschnitte bleiben so auch offline sichtbar.
  if (url.hostname.endsWith('tile.openstreetmap.org')) {
    event.respondWith(
      fetch(req)
        .then((res) => {
          const copy = res.clone();
          caches.open(TILE_CACHE).then((cache) => cache.put(req, copy));
          return res;
        })
        .catch(() => caches.match(req))
    );
    return;
  }

  // App-Shell und alle sonstigen Assets: Cache zuerst (funktioniert komplett
  // offline), im Hintergrund aktualisieren, wenn Netzwerk verfügbar ist.
  event.respondWith(
    caches.match(req).then((cached) => {
      const fetchPromise = fetch(req)
        .then((res) => {
          if (res && res.ok) {
            const copy = res.clone();
            caches.open(APP_CACHE).then((cache) => cache.put(req, copy));
          }
          return res;
        })
        .catch(() => cached);
      return cached || fetchPromise;
    })
  );
});

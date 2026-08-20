// Service Worker do Ministral — injetado pelo vite-plugin-pwa (injectManifest).
// O workbox injeta a lista de precache em self.__WB_MANIFEST.
// Este arquivo mantém o handler de PUSH (notificações no dispositivo), o
// precache e a navegação offline.

const CACHE_NAME = 'gestao-escala-pwa-__SW_CACHE_VERSION__';

// Manifest de precache injetado pelo build (workbox injectManifest).
// OBS: o workbox exige UMA ÚNICA ocorrência de `self.__WB_MANIFEST` (ponto de injeção).
const PRECACHE_URLS = self.__WB_MANIFEST || [];

// Instalação: precache dos assets do build
self.addEventListener('install', (event) => {
  self.skipWaiting();
  event.waitUntil(
    caches.open(CACHE_NAME).then((cache) => {
      const urls = PRECACHE_URLS
        .map((entry) => (typeof entry === 'string' ? entry : entry.url))
        .filter(Boolean);
      return cache.addAll(urls).catch((err) => {
        console.warn('Falha no precache não crítico:', err);
      });
    })
  );
});

// Ativação e Limpeza de Caches Antigos
self.addEventListener('activate', (event) => {
  event.waitUntil(
    caches.keys().then((cacheNames) => {
      return Promise.all(
        cacheNames.map((cacheName) => {
          if (cacheName !== CACHE_NAME) {
            console.log('Removendo cache antigo:', cacheName);
            return caches.delete(cacheName);
          }
        })
      );
    })
  );
  return self.clients.claim();
});

// Interceptação de Rede
self.addEventListener('fetch', (event) => {
  if (!event.request.url.startsWith('http')) return;

  // 1. Navegação (HTML)
  if (event.request.mode === 'navigate') {
    event.respondWith(
      fetch(event.request).catch(() => {
        return caches.match('/')
          .then((response) => response || caches.match('/index.html'));
      })
    );
    return;
  }

  // 2. Assets Estáticos (Cache First / Stale-While-Revalidate)
  if (['script', 'style', 'image', 'font', 'manifest'].includes(event.request.destination)) {
    event.respondWith(
      caches.match(event.request).then((cachedResponse) => {
        const fetchPromise = fetch(event.request).then((networkResponse) => {
          if (networkResponse && networkResponse.status === 200) {
            const responseClone = networkResponse.clone();
            caches.open(CACHE_NAME).then((cache) => cache.put(event.request, responseClone));
          }
          return networkResponse;
        }).catch(() => {});
        return cachedResponse || fetchPromise;
      })
    );
    return;
  }

  // 3. Requisições Supabase (GET): Network First com Cache Dinâmico
  if (event.request.method === 'GET' && (event.request.url.includes('/rest/v1/') || event.request.url.includes('.supabase.co'))) {
    event.respondWith(
      fetch(event.request)
        .then((networkResponse) => {
          if (networkResponse && networkResponse.status === 200) {
            const responseClone = networkResponse.clone();
            caches.open(CACHE_NAME).then((cache) => {
              cache.put(event.request, responseClone);
            });
          }
          return networkResponse;
        })
        .catch(() => {
          return caches.match(event.request);
        })
    );
    return;
  }

  // 4. Outras requisições: Network First padrão
  event.respondWith(
    fetch(event.request).catch(() => caches.match(event.request))
  );
});

// --- PUSH NOTIFICATIONS (Background & Closed App) ---

self.addEventListener('push', function (event) {
  if (!event.data) return;

  let data;
  try {
    data = event.data.json();
  } catch (e) {
    data = { title: 'Nova Notificação', body: event.data.text() };
  }

  const options = {
    body: data.body,
    icon: data.icon || '/branding/icon-light.png',
    badge: '/branding/favicon-light.png',
    vibrate: [100, 50, 100],
    data: {
      url: data.data?.url || '/',
      dateOfArrival: Date.now(),
    },
    actions: [
      { action: 'open', title: 'Ver Agora' }
    ],
    // SEM tag fixa: cada notificação é independente (escala, troca, aviso,
    // janela de disponibilidade...). Tag fixa faria a nova SUBSTITUIR a anterior.
    renotify: false
  };

  event.waitUntil(
    self.registration.showNotification(data.title, options)
  );
});

self.addEventListener('notificationclick', function (event) {
  event.notification.close();

  const urlToOpen = new URL(event.notification.data?.url || '/', self.location.origin).href;

  event.waitUntil(
    clients.matchAll({ type: 'window', includeUncontrolled: true }).then(function (clientList) {
      for (let i = 0; i < clientList.length; i++) {
        const client = clientList[i];
        if (client.url.startsWith(self.location.origin) && 'focus' in client) {
          return client.focus().then((c) => {
            if (c && 'navigate' in c) {
              return c.navigate(urlToOpen);
            }
          });
        }
      }
      if (clients.openWindow) {
        return clients.openWindow(urlToOpen);
      }
    })
  );
});

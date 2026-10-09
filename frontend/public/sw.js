/* eslint-disable no-restricted-globals */

// Nombre del cache
const CACHE_NAME = 'cartagena-segura-v1';

// Instalación del Service Worker
self.addEventListener('install', (event) => {
  console.log('[SW] Instalado');
  self.skipWaiting();
});

// Activación
self.addEventListener('activate', (event) => {
  console.log('[SW] Activado');
  event.waitUntil(self.clients.claim());
});

// Escuchar eventos Push (Cuando el backend envíe mensajes reales)
self.addEventListener('push', (event) => {
  let data = { title: 'Cartagena Segura', message: 'Nueva notificación' };
  
  if (event.data) {
    try {
      data = event.data.json();
    } catch (e) {
      data = { title: 'Cartagena Segura', message: event.data.text() };
    }
  }

  const options = {
    body: data.message,
    icon: '/AppIcon.png',
    badge: '/AppIcon.png',
    vibrate: [100, 50, 100],
    data: data,
    tag: 'cartagena-segura-notif',
    renotify: true
  };

  event.waitUntil(
    self.registration.showNotification(data.title, options)
  );
});

// Escuchar clics en la notificación
self.addEventListener('notificationclick', (event) => {
  event.notification.close();
  
  const urlToOpen = new URL('/', self.location.origin).href;

  event.waitUntil(
    self.clients.matchAll({ type: 'window', includeUncontrolled: true }).then((windowClients) => {
      for (let i = 0; i < windowClients.length; i++) {
        const client = windowClients[i];
        if (client.url === urlToOpen && 'focus' in client) {
          return client.focus();
        }
      }
      if (self.clients.openWindow) {
        return self.clients.openWindow(urlToOpen);
      }
    })
  );
});

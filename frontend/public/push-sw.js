self.addEventListener('push', event => {
  let data = { title: 'Cartagena Segura', message: 'Nueva notificación' }

  if (event.data) {
    try {
      data = event.data.json()
    } catch {
      data = { title: 'Cartagena Segura', message: event.data.text() }
    }
  }

  event.waitUntil(
    self.registration.showNotification(data.title, {
      body: data.message,
      icon: '/app-icon-192.png',
      badge: '/app-icon-192.png',
      vibrate: [100, 50, 100],
      data,
      tag: 'cartagena-segura-notif',
      renotify: true,
    }),
  )
})

self.addEventListener('notificationclick', event => {
  event.notification.close()
  const urlToOpen = new URL('/', self.location.origin).href

  event.waitUntil(
    self.clients.matchAll({ type: 'window', includeUncontrolled: true }).then(windowClients => {
      for (const client of windowClients) {
        if (client.url === urlToOpen && 'focus' in client) {
          return client.focus()
        }
      }

      return self.clients.openWindow?.(urlToOpen)
    }),
  )
})

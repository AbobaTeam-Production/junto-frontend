// Service worker for Web Push delivery (FCM).
//
// Loaded by the browser at /firebase-messaging-sw.js when firebase_messaging
// requests a token. The compat SDK is used so the SW runs in older browsers
// without ES-module SW support.
//
// Foreground messages are handled directly in fcm_provider.dart; this SW
// only catches the BACKGROUND case (browser tab not focused). The default
// FCM behaviour — auto-show notification from `notification` payload — is
// good enough for our friend_request / friend_accepted flows, so we don't
// override `onBackgroundMessage` unless we need custom click routing.

importScripts('https://www.gstatic.com/firebasejs/10.13.0/firebase-app-compat.js');
importScripts('https://www.gstatic.com/firebasejs/10.13.0/firebase-messaging-compat.js');

firebase.initializeApp({
  apiKey: 'AIzaSyAktd4ktbSTZt_9DCgXrwc8UrhiRRPnquI',
  authDomain: 'junto-a622c.firebaseapp.com',
  projectId: 'junto-a622c',
  storageBucket: 'junto-a622c.firebasestorage.app',
  messagingSenderId: '224137779408',
  appId: '1:224137779408:web:40ab4aac1f2918c5b2a6d5',
});

const messaging = firebase.messaging();

// Custom notification click → open the app at /friends. Without this the
// SW would just focus an existing tab without navigating.
self.addEventListener('notificationclick', (event) => {
  event.notification.close();
  event.waitUntil((async () => {
    const data = event.notification?.data || {};
    const path = data.type === 'friend_request' || data.type === 'friend_accepted'
      ? '/friends'
      : '/';
    const clients = await self.clients.matchAll({ type: 'window', includeUncontrolled: true });
    for (const client of clients) {
      if ('focus' in client) {
        client.postMessage({ type: 'fcm_navigate', path });
        return client.focus();
      }
    }
    if (self.clients.openWindow) {
      return self.clients.openWindow(path);
    }
  })());
});

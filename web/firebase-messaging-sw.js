importScripts("https://www.gstatic.com/firebasejs/10.12.2/firebase-app-compat.js");
importScripts("https://www.gstatic.com/firebasejs/10.12.2/firebase-messaging-compat.js");

firebase.initializeApp({
  apiKey: "AIzaSyDjd8eiCDbwt9Qb2qEPdCyE_dWoOLYtlfY", // Get this from lib/firebase_options.dart
  authDomain: "sign-up-app-227a0.firebaseapp.com",
  projectId: "sign-up-app-227a0",
  storageBucket: "sign-up-app-227a0.appspot.com",
  messagingSenderId: "303868688064",
  appId: "1:303868688064:web:1221b9c40981978f745f25" // Get this from lib/firebase_options.dart
});

const messaging = firebase.messaging();
messaging.usePublicVapidKey("BGoCuRuvSPmZak6PIX4zR4iXmUcgCWNgX0HQlecb8bJw6aUVYbRZYD79JEhkuGWYbn0cx9hghkuiaW5doubUHzM");
messaging.onBackgroundMessage((payload) => {
  console.log('[firebase-messaging-sw.js] Received background message ', payload);
  
  const notificationTitle = payload.notification.title || 'New Notification';
  const notificationOptions = {
    body: payload.notification.body || 'You have a new message.',
    icon: '/icons/Icon-192.png',
  };

  self.registration.showNotification(notificationTitle, notificationOptions);
});
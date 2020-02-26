importScripts(
  "https://storage.googleapis.com/workbox-cdn/releases/3.2.0/workbox-sw.js"
);

workbox.clientsClaim();
workbox.skipWaiting();

workbox.precaching.precacheAndRoute([]);

workbox.routing.registerNavigationRoute("__PUBLIC/index.html");

workbox.routing.registerRoute(
  /http:\/\/cors-anywhere.herokuapp.com\/http:\/\/tycho.usno.navy.mil\/cgi-bin\/time.pl/i,
  workbox.strategies.networkFirst()
);
workbox.routing.registerRoute(
  "https://cdn.rawgit.com/parcel-bundler/website/01a1f7dd/src/assets/parcel%403x.png",
  workbox.strategies.cacheFirst()
);

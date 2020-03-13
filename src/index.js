import { Elm } from "./Main.elm";
const swName = "/sw.js";

var app = Elm.Main.init({
  node: document.querySelector("main#app"),
  flags: Number(localStorage.getItem("date")) || Date.now()
});

app.ports.cache.subscribe(function(data) {
  localStorage.setItem("date", String(data));
  console.log("Date saved to localStorage: ", String(data));
});

if ("serviceWorker" in navigator) {
  navigator.serviceWorker
    .register(swName)
    .then(function(registration) {
      console.log("Registration successful, scope is:", registration.scope);
    })
    .catch(function(error) {
      console.log("Service worker registration failed, error:", error);
    });
}

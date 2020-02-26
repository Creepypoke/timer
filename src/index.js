import { Elm } from "./Main.elm";
const swName = "/sw.js";

Elm.Main.init({
  node: document.querySelector("main#app")
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

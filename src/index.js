require("./main.scss");
var { Elm } = require("./Main.elm");

var TRELMO = "trelmo";

try {
  var initialState = localStorage.getItem(TRELMO);
} catch (error) {
  console.error("Failed to load state: ", error.message);
}

var app = Elm.Main.init({
  node: document.getElementById("root"),
  flags: initialState,
});

app.ports.setStorage.subscribe(function(state) {
  try {
    localStorage.setItem(TRELMO, JSON.stringify(state));
  } catch (error) {
    console.error("Failed to save state: ", error.message);
  }
});

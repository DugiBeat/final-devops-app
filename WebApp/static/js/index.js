console.log("hello");

const addNameLabel = document.getElementById("addNameLabel");
const nameInput = document.getElementById("addName");
nameInput?.addEventListener("focus", () => {
  addNameLabel.style.fontWeight = "bold";
});
nameInput?.addEventListener("blur", () => {
  addNameLabel.style.fontWeight = "normal";
});

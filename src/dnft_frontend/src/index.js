import {createActor, dnft_backend} from "../../declarations/dnft_backend";

let actor = dnft_backend;

// const greetButton = document.getElementById("greet");
// greetButton.onclick = async (e) => {
//     e.preventDefault();

//     greetButton.setAttribute("disabled", true);

//     // Interact with backend actor, calling the greet method
//     const greeting = await actor.greet();

//     greetButton.removeAttribute("disabled");

//     document.getElementById("greeting").innerText = greeting;

//     return false;
// };

const createButton = document.getElementById("create");
createButton.onclick = async (e) => {
    e.preventDefault();

    const inputField = document.getElementById("link");
    const inputValue = inputField.value;

    createButton.setAttribute("disabled", true);

    // Interact with backend actor, calling the create method
    const res = await actor.mintNFTWithLinkWithoutTo(inputValue);

    createButton.removeAttribute("disabled");
    const receipt = res.Ok;

    document.getElementById("result").innerText = `Dynamic NFT successfully created,\n Token ID: ${receipt.token_id}, Transaction ID: ${receipt.id}`;

    return false;
};

var logo = document.getElementById("logo");
if (logo) {
  logo.addEventListener("click", function () {
    window.open("http://avaVerificationLink");
  });
}

var button = document.getElementById("button");
if (button) {
  button.addEventListener("click", function () {
    window.open("https://nftLink");
  });
}

var button1 = document.getElementById("button1");
if (button1) {
  button1.addEventListener("click", function () {
    window.open("https://dNftLink");
  });
}

var button2 = document.getElementById("button2");
if (button2) {
  button2.addEventListener("click", function () {
    window.open("https://login");
  });
}

// var button3 = document.getElementById("button3");
// if (button3) {
//   button3.addEventListener("click", function () {
//     window.location.href = "responseFromDNFT";
//   });
// }

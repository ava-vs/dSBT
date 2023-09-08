import {createActor, dnft_backend} from "../../declarations/dnft_backend";

let actor = dnft_backend;
let actorICRC = icrc_backend;

const createButton = document.getElementById("create");
createButton.onclick = async (e) => {
    e.preventDefault();

    const inputField = document.getElementById("link");
    const inputValue = inputField.value;

    createButton.setAttribute("disabled", true);

    // Interact with backend actor, calling the create method
    const res = await actor.mintNFTWithLinkWithoutTo(inputValue);

    // Interact with ICRC7 actor
    const resICRC7 = await actorICRC.mint(inputValue);

    createButton.removeAttribute("disabled");
    const receipt = res.Ok;
    const receiptICRC = resICRC7.Ok;

    document.getElementById("result").innerText = `Your Dynamic NFT:\n\n`;

const card = document.createElement('div');
card.innerHTML = `
  <div class="card">
    <div class="card-image">
      <img src="image_rep.svg" alt="Minted NFT"> 
    </div>
    <div class="card-content">
      <h1 class="card-title">Minted NFT</h1>
      <div class="card-info">
        <div class="info-item">
          <span class="info-label">Token ID:</span>
          <span class="info-value">${receipt.token_id}</span> 
        </div>
        <div class="info-item">
          <span class="info-label">Owner:</span>
          <span class="info-value">${receipt.owner}</span>
        </div>
        <div class="info-item">
          <span class="info-label">Link:</span>
          <span class="info-value">${receipt.link}</span>
        </div>
      </div>
      <a href="http://ava.capetown/en" target="_blank"><button class="ava-button">aVa</button></a>
    </div>
  </div>
`;

document.getElementById('result').appendChild(card);

//
const cardICRC7 = document.createElement('div');
cardICRC7.innerHTML = `
  <div class="card">
    <div class="card-image">
      <img src="image_rep.svg" alt="Minted NFT"> 
    </div>
    <div class="card-content">
      <h1 class="card-title">Minted NFT</h1>
      <div class="card-info">
        <div class="info-item">
          <span class="info-label">Token ID:</span>
          <span class="info-value">${receiptICRC.token_id}</span> 
        </div>
        <div class="info-item">
          <span class="info-label">Owner:</span>
          <span class="info-value">${receiptICRC.owner}</span>
        </div>
        <div class="info-item">
          <span class="info-label">Link:</span>
          <span class="info-value">${receiptICRC.link}</span>
        </div>
      </div>
      <a href="http://ava.capetown/en" target="_blank"><button class="ava-button">aVa</button></a>
    </div>
  </div>
`;

document.getElementById('result2').appendChild(cardICRC7);

    return false;
};

// For menu and logo

var logo = document.getElementById("logo");
if (logo) {
  logo.addEventListener("click", function () {
    window.open("http://ava.capetown/en");
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

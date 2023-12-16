import { createActor, dsbt_backend } from "../../declarations/dsbt_backend";
// import { icrc_backend } from "../../declarations/dsbt_backend";

let actor = dsbt_backend;

function addMetadataField() {
  var container = document.getElementById('metadataContainer');
  var newField = document.createElement('div');
  newField.classList.add('metadataEntry');
  newField.innerHTML = '<input type="text" class="metadataKey" placeholder="Key">' +
    '<input type="text" class="metadataValue" placeholder="Value">';
  container.appendChild(newField);
}


// New certificate form
// Assuming you have a form with id 'certificateForm'
const certificateForm = document.getElementById('certificateForm');

certificateForm.onsubmit = async (e) => {
  e.preventDefault();

  // Construct the metadata array from the form's metadata entries
  const metadataEntries = document.querySelectorAll('.metadataEntry');
  const metadata = Array.from(metadataEntries).map(entry => {
    const key = entry.querySelector('.metadataKey').value;
    const value = entry.querySelector('.metadataValue').value;
    return [key, value];
  });

  // Construct the reputation object
  const reputation = {
    reviewer: document.getElementById('reviewer').value,
    category: document.getElementById('category').value,
    value: parseInt(document.getElementById('value').value, 10) // Convert to Nat8
  };

  // Construct the RequestType object
  const requestType = {
    "Certficate": {
      eventType: document.getElementById('eventType').value,
      number: document.getElementById('number').value,
      image: document.getElementById('image').value,
      publisher: document.getElementById('publisher').value,
      graduate: document.getElementById('graduate').value || null, // Convert empty string to null
      username: document.getElementById('username').value,
      subject: document.getElementById('subject').value,
      date: document.getElementById('date').value,
      expire_at: document.getElementById('expire_at').value || null, // Convert empty string to null
      metadata: metadata,
      reputation: reputation
    }
  };

  // Disable the submit button to prevent multiple submissions
  const submitButton = document.querySelector('input[type="submit"]');
  submitButton.setAttribute('disabled', true);

  try {
    // Call the issueToken method on the actor
    const badgeReceipt = await actor.test(); // await actor.issueToken(requestType);

    // Handle the BadgeReceipt response
    if ('Ok' in badgeReceipt) {
      // Success - handle the successful response
      console.log('Token issued successfully:', badgeReceipt.Ok);
    } else {
      // Error - handle the error response
      console.error('Error issuing token:', badgeReceipt.Err);
    }
  } catch (error) {
    // Handle any network or unexpected errors
    console.error('An error occurred:', error);
  } finally {
    // Re-enable the submit button
    submitButton.removeAttribute('disabled');
  };
  const receipt = badgeReceipt.Ok;
  const card = document.createElement('div');
  card.classList.add('card');
  card.innerHTML = `
  
    <div class="card-image">
      <img src="image_rep.svg" alt="Dynamic Soulbound Token"> 
    </div>
    <div class="card-content">
      <h1 class="card-title">Minted SBT</h1>
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
          <span class="info-label">Value:</span>
          <span class="info-value" id="dip-link">${receipt.reputation.value}</span>
        </div>
        <div class="info-item">
        <span class="info-label">Category:</span>
        <span class="info-value" id="category">${receipt.reputation.category}</span>
      </div>
      </div>
      <a href="http://ava.capetown/en" target="_blank"><button class="ava-button">aVa</button></a>
    </div>
`;

  document.getElementById('result').appendChild(card);
};

//Old code

const createButton = document.getElementById("create");
createButton.onclick = async (e) => {
  e.preventDefault();



  const inputField = document.getElementById("link");
  const inputValue = inputField.value;

  createButton.setAttribute("disabled", true);

  // Interact with backend actor, calling the create method
  const res = await actor.mintNFTWithLinkWithoutTo(inputValue);

  // // Interact with ICRC7 actor
  // const resICRC7 = await actorICRC.mintDemo(inputValue);

  createButton.removeAttribute("disabled");
  const receipt = res.Ok;
  // const receiptICRC = resICRC7.Ok;

  document.getElementById("resultcontainer").innerText = `Your Dynamic SBT:\n\n`;

  const card = document.createElement('div');
  card.classList.add('card');
  card.innerHTML = `
  
    <div class="card-image">
      <img src="image_rep.svg" alt="Dynamic Soulbound Token"> 
    </div>
    <div class="card-content">
      <h1 class="card-title">Minted SBT</h1>
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
          <span class="info-value" id="dip-link">${receipt.link}</span>
        </div>
      </div>
      <a href="http://ava.capetown/en" target="_blank"><button class="ava-button">aVa</button></a>
    </div>
`;

  document.getElementById('result').appendChild(card);

  // document.getElementById(`update-btn-dip`).addEventListener('click', async function() {

  //   const res = await actor.updateMetaDemo(receipt.token_id,"updated_link");
  //   const newData = res.Ok;

  //   document.getElementById(`dip-link`).innerText = newData.link;

  // });

  // ICRC7
  const cardICRC7 = document.createElement('div');
  cardICRC7.classList.add('card');
  cardICRC7.innerHTML = `
  
    <div class="card-image">
      <img src="image_rep.svg" alt="reputation NFT"> 
    </div>
    <div class="card-content">
      <h1 class="card-title">ICRC7 NFT</h1>
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
          <span class="info-value" id="icrc-link">${receiptICRC.link}</span>
        </div>
      </div>
      <a href="http://ava.capetown/en" target="_blank"><button class="ava-button">aVa</button></a>
    </div>
    <div class="card-footer">
    <button class="update-button" id="update-btn-icrc">Update</button>
  </div>
`;

  document.getElementById('result2').appendChild(cardICRC7);
  document.getElementById(`update-btn-icrc`).addEventListener('click', async function () {

    const res = await actorICRC.updateMetaDemo(receipt.token_id, "updated_link");
    const newData = res.Ok;

    document.getElementById(`icrc-link`).innerText = newData.link;

  });

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
    window.open("http://127.0.0.1:8000/?canisterId=br5f7-7uaaa-aaaaa-qaaca-cai&id=bkyz2-fmaaa-aaaaa-qaaaq-cai");
  });
}

var button1 = document.getElementById("button1");
if (button1) {
  button1.addEventListener("click", function () {
    window.open("http://127.0.0.1:8000/?canisterId=br5f7-7uaaa-aaaaa-qaaca-cai&id=be2us-64aaa-aaaaa-qaabq-cai");
  });
}

var button2 = document.getElementById("button2");
if (button2) {
  button2.addEventListener("click", function () {
    window.open("https://login");
  });
}

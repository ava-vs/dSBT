import { dsbt_backend } from "../../declarations/dsbt_backend";

let actor = dsbt_backend;

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

    document.getElementById("resultcontainer").innerText = `Your Dynamic SBT:\n\n`;

    document.getElementById('result').appendChild(card);
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

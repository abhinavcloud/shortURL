/**
* CONFIGURATION
* Replace these with your AWS values
*/
const CONFIG = {
   API_URL: 'https://YOUR_API_ID.execute-api.region.amazonaws.com/prod/create',
   COGNITO_DOMAIN: 'https://YOUR_AUTH_DOMAIN.auth.region.amazoncognito.com',
   CLIENT_ID: 'YOUR_COGNITO_CLIENT_ID',
   REDIRECT_URI: window.location.origin // Matches your Cognito setup
};

// --- DOM Elements ---
const views = {
   login: document.getElementById('view-login'),
   home: document.getElementById('view-home')
};
const el = {
   authStatus: document.getElementById('auth-status'),
   longUrlInput: document.getElementById('longUrl'),
   btnShorten: document.getElementById('btn-shorten'),
   btnCopy: document.getElementById('btn-copy'),
   resultArea: document.getElementById('result-area'),
   shortUrlLink: document.getElementById('display-short-url'),
   errorMsg: document.getElementById('error-msg')
};

// --- Initialization ---
window.addEventListener('DOMContentLoaded', () => {
   checkAuthentication();
   setupListeners();
});

/**
* PHASE 1: Authentication Logic
* Checks if we have a token in the URL (returning from login) or in storage.
*/
function checkAuthentication() {
   const hash = window.location.hash;

   if (hash.includes('id_token=')) {
       const params = new URLSearchParams(hash.replace('#', '?'));
       const token = params.get('id_token');
       localStorage.setItem('id_token', token);
       window.history.replaceState({}, document.title, "/"); // Clean the URL
   }

   const token = localStorage.getItem('id_token');
   if (token) {
       el.authStatus.innerText = "● Connected";
       el.authStatus.classList.add('connected');
       views.home.classList.remove('hidden');
   } else {
       el.authStatus.innerText = "○ Not Signed In";
       views.login.classList.remove('hidden');
   }
}

/**
* PHASE 2: Shortening Logic
* The core flow: Validate -> Send to Lambda -> Display
*/
async function handleShorten() {
   const longUrl = el.longUrlInput.value.trim();
   const token = localStorage.getItem('id_token');

   // 1. Basic Validation
   if (!longUrl || !longUrl.startsWith('http')) {
       showError("Please enter a valid URL (starting with http/https)");
       return;
   }

   setLoading(true);
   hideError();

   try {
       // 2. Fetch call to your API Gateway
       // API Gateway and Lambda will handle the "Check DB/Cache" logic
       const response = await fetch(CONFIG.API_URL, {
           method: 'POST',
           headers: {
               'Content-Type': 'application/json',
               'Authorization': `Bearer ${token}` // Cognito JWT Token
           },
           body: JSON.stringify({ long_url: longUrl })
       });

       const data = await response.json();

       if (response.ok) {
           displayResult(data.short_url);
       } else {
           showError(data.error || "Failed to shorten URL");
       }
   } catch (err) {
       showError("Network error. Please try again later.");
   } finally {
       setLoading(false);
   }
}

// --- Helper Functions ---

function setupListeners() {
   document.getElementById('btn-login').onclick = () => {
       window.location.href = `${CONFIG.COGNITO_DOMAIN}/login?client_id=${CONFIG.CLIENT_ID}&response_type=token&scope=email+openid&redirect_uri=${CONFIG.REDIRECT_URI}`;
   };
   el.btnShorten.onclick = handleShorten;
   el.btnCopy.onclick = () => {
       navigator.clipboard.writeText(el.shortUrlLink.innerText);
       el.btnCopy.innerText = "Copied!";
       setTimeout(() => el.btnCopy.innerText = "Copy", 2000);
   };
}

function displayResult(url) {
   el.resultArea.classList.remove('hidden');
   el.shortUrlLink.innerText = url;
   el.shortUrlLink.href = url;
}

function setLoading(state) {
   el.btnShorten.disabled = state;
   el.btnShorten.innerText = state ? "Working..." : "Shorten URL";
}

function showError(msg) {
   el.errorMsg.innerText = msg;
}

function hideError() {
   el.errorMsg.innerText = "";
}

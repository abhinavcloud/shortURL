/**
 * CONFIGURATION
 * Values are generated during CI/CD into config.js
 * and exposed on window.APP_CONFIG
 */
const CONFIG = window.APP_CONFIG;

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
  errorMsg: document.getElementById('error-msg'),
  btnLogout: document.getElementById('btn-logout'),
  spinner: document.getElementById('loading-spinner')

};

// --- Initialization ---
window.addEventListener('DOMContentLoaded', () => {
  handleAuthCallbackIfPresent();  // handles /auth/callback#id_token=...
  checkAuthentication();
  setupListeners();
});

/**
 * Handles the Hosted UI redirect for implicit flow:
 * Cognito redirects back to REDIRECT_URI with tokens in the URL hash.
 * (Allowed because your user pool client enables "implicit") [3](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cognito_user_pool_client)
 */
function handleAuthCallbackIfPresent() {
  const hash = window.location.hash;

  if (hash && hash.includes('id_token=')) {
    const params = new URLSearchParams(hash.replace('#', '?'));
    const idToken = params.get('id_token');
    const accessToken = params.get('access_token');

    if (idToken) localStorage.setItem('id_token', idToken);
    if (accessToken) localStorage.setItem('access_token', accessToken);

    // Clean URL (remove hash) and send user to home page
    window.history.replaceState({}, document.title, window.location.origin + "/");
  }
}

/**
 * Updates UI based on whether token exists.
 */
function checkAuthentication() {
  const token = localStorage.getItem('access_token');

  if (token) {
    const userDisplay = getUserDisplayFromToken(token);

    el.authStatus.innerText = userDisplay
      ? `● Connected • ${userDisplay}`
      : "● Connected";

    el.authStatus.classList.add('connected');
    views.home.classList.remove('hidden');
    views.login.classList.add('hidden');

    const btnLogout = document.getElementById('btn-logout');
    if (btnLogout) btnLogout.classList.remove('hidden');
  } else {
    el.authStatus.innerText = "○ Not Signed In";
    el.authStatus.classList.remove('connected');
    views.login.classList.remove('hidden');
    views.home.classList.add('hidden');

    const btnLogout = document.getElementById('btn-logout');
    if (btnLogout) btnLogout.classList.add('hidden');
  }
}

/**
 * Redirects the browser to Cognito Hosted UI authorize endpoint.
 * Hosted UI endpoints are on the user pool domain. [1](https://docs.aws.amazon.com/cognito/latest/developerguide/cognito-user-pools-assign-domain.html)[2](https://registry.terraform.io/providers/-/aws/6.0.0/docs/resources/cognito_user_pool_domain)
 */
function loginWithGoogle() {
  // Optional: force Google directly (skip IdP chooser)
  const identityProvider = "Google";

  const authorizeUrl =
    `${CONFIG.COGNITO_DOMAIN}/oauth2/authorize` +
    `?client_id=${encodeURIComponent(CONFIG.CLIENT_ID)}` +
    `&response_type=token` +
    `&scope=${encodeURIComponent(CONFIG.SCOPES || "openid email")}` +
    `&redirect_uri=${encodeURIComponent(CONFIG.REDIRECT_URI)}` +
    `&identity_provider=${encodeURIComponent(identityProvider)}`;

  window.location.href = authorizeUrl;
}

/**
 * Hosted UI logout
 * logout_uri MUST match one of logout_urls in your user pool client. [3](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cognito_user_pool_client)
 */
function logout() {
  localStorage.removeItem('id_token');
  localStorage.removeItem('access_token');
  localStorage.removeItem('refresh_token');

  const logoutUrl =
    `${CONFIG.COGNITO_DOMAIN}/logout` +
    `?client_id=${encodeURIComponent(CONFIG.CLIENT_ID)}` +
    `&logout_uri=${encodeURIComponent(window.location.origin)}`;

  window.location.href = logoutUrl;
}


/**
 * Decode JWT payload without verifying signature (display-only).
 * JWT format: header.payload.signature (base64url-encoded)
 */
function decodeJwtPayload(token) {
  try {
    const parts = token.split('.');
    if (parts.length < 2) return null;

    const base64Url = parts[1];
    const base64 = base64Url.replace(/-/g, '+').replace(/_/g, '/');
    const padded = base64 + '='.repeat((4 - (base64.length % 4)) % 4);

    const json = decodeURIComponent(
      atob(padded)
        .split('')
        .map(c => '%' + c.charCodeAt(0).toString(16).padStart(2, '0'))
        .join('')
    );

    return JSON.parse(json);
  } catch (e) {
    return null;
  }
}

/**
 * Returns a nice display name/email from token claims
 */
function getUserDisplayFromToken(idToken) {
  const payload = decodeJwtPayload(idToken);
  if (!payload) return null;

  return (
    payload.email ||
    payload.preferred_username ||
    payload['cognito:username'] ||
    payload.username ||
    null
  );
}


/**
 * Shortening Logic (Backend not implemented yet)
 */
async function handleShorten() {
  const longUrl = el.longUrlInput.value.trim();
  const token = localStorage.getItem('id_token');

  if (!token) {
    showError("Please sign in first.");
    return;
  }

  // Backend not ready yet: show clean message
  if (!CONFIG.API_URL || CONFIG.API_URL.startsWith("DUMMY")) {
    showError("API not implemented yet. Auth is working ✅");
    return;
  }

  if (!longUrl || !longUrl.startsWith('http')) {
    showError("Please enter a valid URL (starting with http/https)");
    return;
  }

  setLoading(true);
  hideError();

  try {
    const response = await fetch(CONFIG.API_URL, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'Authorization': `Bearer ${token}`
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
  document.getElementById('btn-login').onclick = loginWithGoogle;

  // Optional logout button (add in HTML if you want)
  const btnLogout = document.getElementById('btn-logout');
  if (btnLogout) btnLogout.onclick = logout;

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
  if (el.spinner) el.spinner.classList.toggle('hidden', !state);
}

function showError(msg) {
  el.errorMsg.innerText = msg;
}

function hideError() {
  el.errorMsg.innerText = "";
}

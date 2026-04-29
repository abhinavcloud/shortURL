/**
 * CONFIGURATION
 * Replace these with your AWS values
 */
const CONFIG = {
  API_URL: 'https://YOUR_API_ID.execute-api.region.amazonaws.com/prod/create',

  // From aws_cognito_user_pool_domain: https://<prefix>.auth.<region>.amazoncognito.com
  COGNITO_DOMAIN: 'https://YOUR_AUTH_DOMAIN.auth.region.amazoncognito.com',

  // From aws_cognito_user_pool_client.google_client.id
  CLIENT_ID: 'YOUR_COGNITO_CLIENT_ID',

  // MUST match callback_urls in Cognito client (you configured /auth/callback)
  REDIRECT_URI: `${window.location.origin}/auth/callback`,

  // Scopes must align with allowed_oauth_scopes = ["email","openid"]
  SCOPES: 'openid email'
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
window.addEventListener('DOMContentLoaded', async () => {
  await handleOAuthCallbackIfPresent();   // handles ?code=... on /auth/callback
  checkAuthentication();
  setupListeners();
});

/**
 * ==============
 * AUTH: Code Flow with PKCE
 * ==============
 *
 * Flow:
 * 1) Login button -> redirect to /oauth2/authorize with response_type=code + PKCE challenge
 * 2) Cognito redirects back to REDIRECT_URI with ?code=...
 * 3) JS exchanges code at /oauth2/token to obtain tokens
 * 4) Store tokens in localStorage
 */

// ---------- PKCE helpers ----------
function base64UrlEncode(buffer) {
  return btoa(String.fromCharCode(...new Uint8Array(buffer)))
    .replace(/\+/g, '-').replace(/\//g, '_').replace(/=+$/, '');
}

function randomString(length = 64) {
  const charset = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-._~';
  const randomValues = crypto.getRandomValues(new Uint8Array(length));
  return Array.from(randomValues).map(v => charset[v % charset.length]).join('');
}

async function sha256(plain) {
  const encoder = new TextEncoder();
  const data = encoder.encode(plain);
  return await crypto.subtle.digest('SHA-256', data);
}

async function createPkcePair() {
  const verifier = randomString(64);
  const challenge = base64UrlEncode(await sha256(verifier));
  return { verifier, challenge };
}

// ---------- Step 2: Handle callback ----------
async function handleOAuthCallbackIfPresent() {
  const url = new URL(window.location.href);

  // We expect /auth/callback?code=... for code flow
  const code = url.searchParams.get('code');
  const error = url.searchParams.get('error');

  if (error) {
    showError(`Login failed: ${error}`);
    return;
  }

  if (!code) return;

  // Exchange code for tokens
  try {
    const verifier = localStorage.getItem('pkce_verifier');
    if (!verifier) throw new Error('Missing PKCE verifier in storage');

    const tokenEndpoint = `${CONFIG.COGNITO_DOMAIN}/oauth2/token`;

    const body = new URLSearchParams({
      grant_type: 'authorization_code',
      client_id: CONFIG.CLIENT_ID,
      code,
      redirect_uri: CONFIG.REDIRECT_URI,
      code_verifier: verifier
    });

    const resp = await fetch(tokenEndpoint, {
      method: 'POST',
      headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
      body
    });

    const tokenData = await resp.json();
    if (!resp.ok) throw new Error(tokenData.error || 'Token exchange failed');

    // Store tokens
    localStorage.setItem('id_token', tokenData.id_token);
    localStorage.setItem('access_token', tokenData.access_token);
    if (tokenData.refresh_token) localStorage.setItem('refresh_token', tokenData.refresh_token);

    // Cleanup: remove code from URL and PKCE verifier
    localStorage.removeItem('pkce_verifier');
    window.history.replaceState({}, document.title, window.location.origin + '/');
  } catch (e) {
    showError(e.message || 'Login callback handling failed');
  }
}

// ---------- Step 3: Use stored token to set UI ----------
function checkAuthentication() {
  const token = localStorage.getItem('id_token');

  if (token) {
    el.authStatus.innerText = "● Connected";
    el.authStatus.classList.add('connected');
    views.home.classList.remove('hidden');
    views.login.classList.add('hidden');
  } else {
    el.authStatus.innerText = "○ Not Signed In";
    views.login.classList.remove('hidden');
    views.home.classList.add('hidden');
  }
}

// ---------- Login & Logout ----------
async function startLogin() {
  const { verifier, challenge } = await createPkcePair();
  localStorage.setItem('pkce_verifier', verifier);

  const authorizeUrl =
    `${CONFIG.COGNITO_DOMAIN}/oauth2/authorize` +
    `?client_id=${encodeURIComponent(CONFIG.CLIENT_ID)}` +
    `&response_type=code` +
    `&scope=${encodeURIComponent(CONFIG.SCOPES)}` +
    `&redirect_uri=${encodeURIComponent(CONFIG.REDIRECT_URI)}` +
    `&code_challenge=${encodeURIComponent(challenge)}` +
    `&code_challenge_method=S256`;

  // If you want to force Google specifically (optional), you can append:
  // + `&identity_provider=Google`
  // Your client already supports Google. [1](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cognito_user_pool_client)

  window.location.href = authorizeUrl;
}

function logout() {
  localStorage.removeItem('id_token');
  localStorage.removeItem('access_token');
  localStorage.removeItem('refresh_token');

  // Cognito hosted UI logout endpoint (works because you configured logout_urls)
  const logoutUrl =
    `${CONFIG.COGNITO_DOMAIN}/logout` +
    `?client_id=${encodeURIComponent(CONFIG.CLIENT_ID)}` +
    `&logout_uri=${encodeURIComponent(window.location.origin + '/')}`;

  window.location.href = logoutUrl;
}

// --- Shortening Logic (unchanged, but uses token) ---
async function handleShorten() {
  const longUrl = el.longUrlInput.value.trim();
  const token = localStorage.getItem('id_token');

  if (!token) {
    showError("Please sign in first.");
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
  document.getElementById('btn-login').onclick = startLogin;

  // Optional: add a logout button in HTML with id="btn-logout"
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
}

function showError(msg) {
  el.errorMsg.innerText = msg;
}

function hideError() {
  el.errorMsg.innerText = "";
}
``
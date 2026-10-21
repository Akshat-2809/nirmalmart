// A tab left open across a deploy keeps running the old code. We quietly check whether a newer
// build is live (when the tab regains focus, and every few minutes) and, if so, load it fully on
// the shopper's next page change — so links and pages added since never appear "broken".
const current = document.querySelector('script[type="module"][src*="/assets/index-"]')?.getAttribute('src');
let stale = false;
let lastCheck = 0;

// Page changes are throttled; returning to the tab always checks
async function check(force = false) {
  if (!current || stale || (!force && Date.now() - lastCheck < 30_000)) return;
  lastCheck = Date.now();
  try {
    const html = await (await fetch('/', { cache: 'no-store' })).text();
    const live = html.match(/\/assets\/index-[\w-]+\.js/)?.[0];
    if (live && live !== current) stale = true;
  } catch { /* offline — try again later */ }
}

export function watchForNewVersion() {
  if (!current) return; // dev server
  document.addEventListener('visibilitychange', () => document.visibilityState === 'visible' && check(true));
  setInterval(() => check(true), 5 * 60_000);
  // A lazy page from the old build can no longer be fetched: load the new build once
  window.addEventListener('vite:preloadError', (e) => {
    try {
      if (sessionStorage.getItem('nm-reloaded') === current) return;
      sessionStorage.setItem('nm-reloaded', current);
    } catch { /* storage blocked */ }
    e.preventDefault();
    window.location.reload();
  });
}

/** Called on every page change: resolves true when a newer build is live and the page should be fully reloaded. */
export async function newVersionReady() {
  await check();
  return stale;
}

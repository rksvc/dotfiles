// ==UserScript==
// @name        redirect.user.js
// @run-at      document-start
// @match       *://*/*
// @version     1.0
// ==/UserScript==

switch (location.host) {
  case 'x.com':
  case 'twitter.com':
    location.host = 'xcancel.com'
    break
  case 'www.reddit.com':
    location.host = 'redlib.catsarch.com'
    break
}

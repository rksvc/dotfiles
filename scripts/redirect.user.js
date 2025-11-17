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
		location.host = 'redlib.perennialte.ch'
		break
	case 'jump.bdimg.com':
	case 'jump2.bdimg.com':
		location.host = 'tieba.baidu.com'
}

// ==UserScript==
// @name        rss.user.js
// @match       *://*/*
// @grant       GM.openInTab
// @grant       GM.registerMenuCommand
// @version     1.0
// ==/UserScript==

{
	// https://github.com/DIYgod/RSSHub-Radar/blob/1477c8cc075d8230a9617e438a6f466c6a95dbfe/src/lib/rss.ts#L66
	const types = [
		'application/rss+xml',
		'application/atom+xml',
		'application/rdf+xml',
		'application/rss',
		'application/atom',
		'application/rdf',
		'text/rss+xml',
		'text/atom+xml',
		'text/rdf+xml',
		'text/rss',
		'text/atom',
		'text/rdf',
		'application/feed+json',
	]

	for (const elem of document.querySelectorAll('link[type]')) {
		if (types.includes(elem.getAttribute('type'))) {
			const href = elem.getAttribute('href')
			if (href)
				GM.registerMenuCommand(elem.getAttribute('title') || href, () =>
					GM.openInTab(new URL(href, location.href).href),
				)
		}
	}
}

// ==UserScript==
// @name        radar.user.js
// @run-at      document-start
// @match       *://*/*
// @grant       GM.getValue
// @grant       GM.setValue
// @grant       GM.openInTab
// @grant       GM.xmlHttpRequest
// @grant       GM.registerMenuCommand
// @version     1.0
// ==/UserScript==

;(async () => {
	const RSSHUB = 'https://rsshub.rssforever.com'
	const KEY_LAST_REFRESHED = 'lastRefreshed'
	const KEY_RULES = 'rules'

	const find = radar => {
		for (const item of radar[location.hostname] ?? []) {
			for (const source of item.source) {
				const dynamicReplacer = (_, name, optional) => `(?<${name}>[^/]+)${optional ? '?' : ''}`
				const starReplacer = (_, name) => (name ? `(?:/(?<${name}>.+?)(?=$|/))?` : '(?:/.+?(?=$|/))?')
				const re = `^${source.replaceAll(/:(\w+)(\?)?/g, dynamicReplacer).replaceAll(/\/\*(\w*)/g, starReplacer)}/?$`
				const match = location.pathname.match(new RegExp(re))
				if (match) {
					const target = item.target
						.replaceAll(/(\/:\w+)\{[^}]*\}/g, '$1')
						.replaceAll(/\/(?::|\*)(\w+)\??/g, (_, name) => (match.groups?.[name] ? `/${match.groups[name]}` : ''))
					GM.registerMenuCommand(`${item.title} (${target})`, () => GM.openInTab(`${RSSHUB}${target}`))
				}
			}
		}
	}

	const lastRefreshed = await GM.getValue(KEY_LAST_REFRESHED)
	if (!lastRefreshed || Date.now() - new Date(lastRefreshed) > 24 * 60 * 60 * 1000)
		GM.xmlHttpRequest({
			url: `${RSSHUB}/api/radar/rules`,
			responseType: 'json',
			onload: async response => {
				const radar = {}
				for (const domain in response.response) {
					const rules = response.response[domain]
					for (const subdomain in rules) {
						if (subdomain !== '_name') {
							const items = rules[subdomain]
							const subdomains = subdomain === '.' || subdomain === 'www' ? ['', 'www.'] : [`${subdomain}.`]
							for (const subdomain of subdomains) radar[`${subdomain}${domain}`] = items
						}
					}
				}
				await GM.setValue(KEY_RULES, JSON.stringify(radar))
				await GM.setValue(KEY_LAST_REFRESHED, Date.now())
				if (!lastRefreshed) find(radar)
			},
		})
	if (lastRefreshed) find(JSON.parse(await GM.getValue(KEY_RULES)))
})()

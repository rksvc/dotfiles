// ==UserScript==
// @name        align-kiss.user.js
// @match       *://*/*
// @grant       GM_addStyle
// @version     1.0
// ==/UserScript==

;(() => {
  /**
   * @param {Node} node
   */
  function isKISS(node) {
    return node.nodeType === Node.ELEMENT_NODE && node.tagName === 'KISS-TRANSLATOR'
  }

  /**
   * @param {Element} elem
   * @param {Array} list
   * @param {Element?} stop
   */
  function walk(elem, list, stop) {
    for (const child of elem.childNodes) {
      if (child === stop) {
        break
      } else if (child.nodeType === Node.TEXT_NODE) {
        list.push(child)
      } else if (child.nodeType === Node.ELEMENT_NODE) {
        // [<p>, <kiss>, <p>, <kiss>]
        //               ^target
        if (isKISS(child)) list.length = 0
        else walk(child, list, stop)
      }
    }
  }

  const segmenters = new Map()
  const meta = new Map()
  const pairs = new Map()

  const build = node => {
    if (node.parentNode == null) return
    const tgts = []
    walk(node, tgts)
    const tgt = tgts.map(tgt => tgt.nodeValue).join('')
    if (tgt.trim() === '') return

    const srcs = []
    walk(node.parentNode, srcs, node)
    const src = srcs.map(src => src.nodeValue).join('')

    const srcLang = document.documentElement.lang || 'en'
    const tgtLang = node.querySelector('[lang]').getAttribute('lang')
    const getSegments = (lang, text) => {
      let segmenter = segmenters.get(lang)
      if (!segmenter) {
        segmenters.set(lang, (segmenter = new Intl.Segmenter(lang, { granularity: 'sentence' })))
      }
      return [...segmenter.segment(text)]
    }
    const srcSegments = getSegments(srcLang, src)
    const tgtSegments = getSegments(tgtLang, tgt)
    if (srcSegments.length !== tgtSegments.length) return

    const srcRngs = []
    const tgtRngs = []
    const setRange = (these, start, sentence, theseRngs) => {
      let accLength = 0
      for (let i = 0; i < these.length; ++i) {
        const ths = these[i]
        if (accLength + ths.nodeValue.length > start) {
          start -= accLength
          const range = new Range()
          range.setStart(ths, start)
          let end = start + sentence.length
          while (i < these.length && end > these[i].nodeValue.length) {
            end -= these[i].nodeValue.length
            ++i
          }
          range.setEnd(these[i], end)
          const actualSentence = range.toString()
          console.assert(actualSentence === sentence, `"${actualSentence}" != "${sentence}"`)
          theseRngs.push(range)
          break
        }
        accLength += ths.nodeValue.length
      }
    }
    for (const { segment, index } of srcSegments) setRange(srcs, index, segment, srcRngs)
    for (const { segment, index } of tgtSegments) setRange(tgts, index, segment, tgtRngs)

    if (meta.has(node)) pairs.set(node, [srcRngs, tgtRngs])
  }

  const observer = new MutationObserver(mutationList => {
    for (const mutation of mutationList) {
      for (const node of mutation.addedNodes) {
        if (isKISS(node)) {
          const subtree = new MutationObserver(() => build(node))
          subtree.observe(node, { subtree: true, childList: true, characterData: true })
          meta.set(node, { observer: subtree })
          build(node)
        }
      }
      for (const node of mutation.removedNodes) {
        if (isKISS(node)) {
          const m = meta.get(node)
          m.observer.disconnect()
          meta.delete(node)
          pairs.delete(node)
        }
      }
    }
  })
  observer.observe(document.body, { subtree: true, childList: true })

  document.addEventListener('mousemove', evt => {
    const highlight = (theseRngs, thoseRngs) => {
      for (const [i, range] of theseRngs.entries()) {
        if (
          [...range.getClientRects()].some(
            range =>
              evt.clientX >= range.left &&
              evt.clientX <= range.right &&
              evt.clientY >= range.top &&
              evt.clientY <= range.bottom,
          )
        ) {
          CSS.highlights.set('align-hl', new Highlight(range, thoseRngs[i]))
          return true
        }
      }
    }

    CSS.highlights.delete('align-hl')
    for (const [srcRngs, tgtRngs] of pairs.values())
      if (highlight(srcRngs, tgtRngs) || highlight(tgtRngs, srcRngs)) break
  })
})()

GM_addStyle(`
::highlight(align-hl) {
  color: black;
  background: yellow;
}`)

/* Inline vectors avoid Android emoji glyphs and external icon dependencies. */
const iconPaths={
 home:'<path d="m3 10 9-7 9 7v10H5V10M9 20v-7h6v7"/>',
 book:'<path d="M12 5c-3-2-6-2-10-1v15c4-1 7-1 10 1 3-2 6-2 10-1V4c-4-1-7-1-10 1Zm0 0v15"/>',
 prayer:'<path d="M7 21V10a5 5 0 0 1 10 0v11M4 21h16M12 2v3M9 13h6M12 13v8"/>',
 beads:'<circle cx="12" cy="10" r="7"/><path d="M12 17v5m-3-2h6"/><circle cx="12" cy="3" r="1"/><circle cx="5" cy="10" r="1"/><circle cx="19" cy="10" r="1"/>',
 dua:'<path d="m3 8 3 2 2 6 3 2V8c0-3-3-3-3 0v4M21 8l-3 2-2 6-3 2V8c0-3 3-3 3 0v4M5 16l2 5h10l2-5"/>',
 quiz:'<circle cx="12" cy="12" r="9"/><path d="M9.5 8.5a2.5 2.5 0 0 1 5 0c0 2-2.5 2-2.5 4M12 17h.01"/>',
 sun:'<circle cx="12" cy="12" r="4"/><path d="M12 2v2m0 16v2M2 12h2m16 0h2M5 5l1.5 1.5m11 11L19 19M5 19l1.5-1.5m11-11L19 5"/>',
 sunset:'<path d="M3 17h18M5 21h14M6 17a6 6 0 0 1 12 0M12 3v3M4 8l2 2m12 0 2-2"/>',
 moon:'<path d="M20.5 14A9 9 0 0 1 10 3.5 9 9 0 1 0 20.5 14Z"/>',
 compass:'<circle cx="12" cy="12" r="9"/><path d="m16 8-3 5-5 3 3-5 5-3Z"/>',
 check:'<path d="m5 12 4 4L19 6"/>',chart:'<path d="M4 20h17M6 16v-5m6 5V5m6 11V9"/>',
 bell:'<path d="M5 17h14l-2-4V9a5 5 0 0 0-10 0v4l-2 4ZM10 21h4M12 2v2"/>',
 globe:'<circle cx="12" cy="12" r="9"/><path d="M3 12h18M12 3c5 5 5 13 0 18-5-5-5-13 0-18Z"/>',
 phone:'<rect x="6" y="2" width="12" height="20" rx="3"/><path d="M10 18h4"/>',
 palette:'<circle cx="8" cy="8" r=".6"/><circle cx="12" cy="6" r=".6"/><circle cx="16" cy="9" r=".6"/><path d="M21 12c0 6-4 1-6 4-1 1 2 5-3 5a9 9 0 1 1 9-9Z"/>',
 heart:'<path d="M20 5c-2-3-6-2-8 1-2-3-6-4-8-1-5 6 8 15 8 15S25 11 20 5Z"/>',
 more:'<circle cx="5" cy="12" r="1"/><circle cx="12" cy="12" r="1"/><circle cx="19" cy="12" r="1"/>',
 share:'<circle cx="18" cy="5" r="3"/><circle cx="6" cy="12" r="3"/><circle cx="18" cy="19" r="3"/><path d="m8.6 10.5 6.8-4m-6.8 7 6.8 4"/>',
 location:'<path d="M19 9c0 6-7 12-7 12S5 15 5 9a7 7 0 1 1 14 0Z"/><circle cx="12" cy="9" r="2"/>',
 search:'<circle cx="10" cy="10" r="6"/><path d="m15 15 6 6"/>',
 left:'<path d="m15 5-7 7 7 7"/>',right:'<path d="m9 5 7 7-7 7"/>',up:'<path d="m5 15 7-7 7 7"/>',down:'<path d="m5 9 7 7 7-7"/>',
 arrow:'<path d="M4 12h16m-6-6 6 6-6 6"/>',external:'<path d="M14 3h7v7m0-7L10 14M10 5H4v15h15v-6"/>',
 refresh:'<path d="M20 8a8 8 0 1 0 0 8M20 3v5h-5"/>',close:'<path d="m6 6 12 12M18 6 6 18"/>',plus:'<path d="M12 4v16M4 12h16"/>',
 play:'<path d="m8 4 12 8-12 8V4Z"/>',pause:'<path d="M8 4v16M16 4v16"/>',download:'<path d="M12 3v12m-5-5 5 5 5-5M4 16v5h16v-5"/>',
 settings:'<circle cx="12" cy="12" r="3"/><path d="m10 2-.5 3-2 .8-2.5-1.5-2 3.4 2.5 1.8-.3 2.2L2.5 13l1 3.8 3-.1 1.5 1.6-.1 3h4l1-2.8 2-.7 2.5 1.5 2-3.4-2.5-1.8.3-2.2L21.5 11l-1-3.8-3 .1L16 5.7l.1-3Z"/>',
 lock:'<rect x="5" y="10" width="14" height="11" rx="2"/><path d="M8 10V6a4 4 0 0 1 8 0v4M12 14v3"/>',badge:'<path d="m12 3 3 3 4 .5.5 4 2 3-3 3-.5 4-4 .5L12 23l-3-3-4-.5-.5-4L2 12l3-3 .5-4 4-.5L12 3Z"/><path d="m8 12 3 3 5-6"/>',
 kaaba:'<path d="m3 7 9-4 9 4v13H3V7Zm0 0 9 4 9-4M12 11v9M3 12l9 4 9-4"/>',clock:'<circle cx="12" cy="12" r="9"/><path d="M12 6v6l4 2"/>'
};
function uiIcon(name){return `<svg class="ui-icon" xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" width="24" height="24" fill="none" stroke="currentColor" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true" focusable="false">${iconPaths[name]||iconPaths.book}</svg>`}
const routeIconNames={home:'home',quran:'book',learn:'prayer',tasbih:'beads',duas:'dua',collection:'heart',quiz:'quiz',asma:'sun',ramadan:'moon',fasting:'moon',qibla:'compass',tracker:'check',stats:'chart',prayers:'sun',notifications:'bell',pro:'lock',language:'globe',mobile:'phone',themes:'palette',share:'share',special:'moon',account:'phone',cloudadmin:'settings',more:'more'};
const glyphIcons={'⌂':'home','▥':'book','♧':'prayer','◉':'beads','◈':'compass','✓':'check','☼':'sun','☀':'sun','☾':'moon','◒':'sunset','♡':'heart','♥':'heart','◎':'globe','▯':'phone','◐':'palette','⚙':'settings','↗':null,'⌖':'location','⌕':'search','‹':'left','❮':'left','›':'right','❯':'right','→':'arrow','←':'left','↻':'refresh','↶':'refresh','＋':'plus','✕':'close','×':'close','▶':'play','▷':'play','Ⅱ':'pause','↓':'download','⌄':'down','▣':'kaaba','◷':'clock','♧':'dua'};
glyphIcons['🔒']='lock';
const glyphPattern=/[⌂▥♧◉◈✓☼☀☾◒♡♥◎▯◐⚙↗⌖⌕‹❮›❯→←↻↶＋✕×▶▷Ⅱ↓⌄▣◷✦✧✨🔒]/gu;
function normalizeUiIcons(){if(typeof document.createTreeWalker!=='function')return;
 if(typeof paintModuleBadges==='function')paintModuleBadges();
 for(const e of document.querySelectorAll('.share-header'))if(e.getAttribute('data-vector')!=='share'){e.innerHTML=uiIcon('share');e.setAttribute('data-vector','share')}
 for(const e of document.querySelectorAll('button.row[onclick],button.tool-tile[onclick]')){const match=e.getAttribute('onclick')?.match(/go\('([^']+)'\)/),name=routeIconNames[match?.[1]],slot=e.querySelector('.symbol,i,.sun');if(name&&slot&&slot.getAttribute('data-vector')!==name){slot.innerHTML=uiIcon(name);slot.setAttribute('data-vector',name)}}
 for(const a of document.querySelectorAll('.navitem[href]')){const name=routeIconNames[(a.getAttribute('href')||'').replace(/^#/,'')],slot=a.querySelector('span');if(name&&slot&&!slot.querySelector('svg'))slot.innerHTML=uiIcon(name)}
 for(const e of document.querySelectorAll('.home-slide button[onclick] i')){const parent=e.parentElement,match=parent.getAttribute('onclick')?.match(/go\('([^']+)'\)/);const name=routeIconNames[match?.[1]];if(name&&!e.querySelector('svg'))e.innerHTML=uiIcon(name)}
 const walk=document.createTreeWalker(document.body,4),nodes=[];let n;while(n=walk.nextNode()){if(n.parentElement?.closest('script,style,svg,textarea,option,.arabic,.translit,.book-full,.meaning p,.step-body,.share-dua-body,.policy-help,.cloud-log'))continue;if(glyphPattern.test(n.nodeValue)){nodes.push(n)}glyphPattern.lastIndex=0}
 for(const node of nodes){const text=node.nodeValue,parts=[],regex=new RegExp(glyphPattern.source,'gu');let at=0,match;while(match=regex.exec(text)){if(match.index>at)parts.push(document.createTextNode(text.slice(at,match.index)));const name=glyphIcons[match[0]];if(name){const control=node.parentElement?.closest('button,a');if(control&&!control.hasAttribute('aria-label')&&control.textContent.trim().replace(/[\uFE0E\uFE0F]/g,'')===match[0]){const labels={left:tr('Əvvəlki'),right:tr('Növbəti'),refresh:pw('retry'),close:ml('close'),plus:ml('add'),play:sw('azan'),pause:sw('pause'),share:ds('share')};control.setAttribute('aria-label',labels[name]||tr('Ətraflı bax'))}const slot=document.createElement('span');slot.className='icon-slot';slot.innerHTML=uiIcon(name);parts.push(slot)}at=regex.lastIndex;if(/[\uFE0E\uFE0F]/.test(text[at]||''))at++;}if(at<text.length)parts.push(document.createTextNode(text.slice(at)));node.replaceWith(...parts)}
 for(const label of document.querySelectorAll('.daily-dua>span:first-child,.category-grid button>span:first-child'))if(!label.querySelector('svg')&&!label.textContent.trim())label.innerHTML=uiIcon('dua');
}
function initializeIconSystem(){if(typeof MutationObserver!=='function')return;let pending=false;const observer=new MutationObserver(()=>{if(pending)return;pending=true;queueMicrotask(()=>{pending=false;normalizeUiIcons()})});observer.observe(document.body,{childList:true,subtree:true,characterData:true})}

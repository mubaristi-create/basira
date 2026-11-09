/* Native owns system/IME insets; web layout owns only its own changing navigation height. */
function initializeSafeLayout(){
 if(!/SHAMS\//.test(navigator.userAgent||''))return;
 document.documentElement.dataset.shell='android';
 const nav=document.querySelector('#bottomNav');if(!nav)return;
 const measure=()=>{const height=Math.ceil(nav.getBoundingClientRect().height);document.documentElement.style.setProperty('--native-nav-height',height+'px')};
 if(typeof ResizeObserver!=='undefined'){const observer=new ResizeObserver(measure);observer.observe(nav)}
 else if(typeof MutationObserver!=='undefined'){const observer=new MutationObserver(measure);observer.observe(nav,{childList:true,subtree:true})}
 window.addEventListener('resize',measure);measure();
}

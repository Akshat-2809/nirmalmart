import json, os, random
OUT = "/home/claude/nm/project"
W, H = 390, 844
C = dict(BRAND="#317239", BSOFT="#E9F3EB", INK="#111217", SOFT="#4C4F5C", FAINT="#5F6270", LINE="#E5E5E0",
         MUTED="#F3F3F0", BG="#FAFAF8", DEAL="#B92418", GOLD="#D8AB54", MAROON="#46080C", GREEN="#15803D", DARKG="#1E4D25")
FONT = "Inter, 'Noto Sans Devanagari', system-ui, sans-serif"

def T(s, **kw):
    m = dict(C); m.update({k: str(v) for k, v in kw.items()})
    for k, v in m.items():
        s = s.replace("[[" + k + "]]", v)
    return s

P = {
 'search':'<circle cx="11" cy="11" r="7"/><path d="m20 20-3.5-3.5"/>',
 'heart':'<path d="M12 20s-7-4.4-7-10a4 4 0 0 1 7-2.6A4 4 0 0 1 19 10c0 5.6-7 10-7 10z"/>',
 'bag':'<path d="M6 7h12l1 13H5L6 7z"/><path d="M9 7a3 3 0 0 1 6 0"/>',
 'home':'<path d="M4 11l8-7 8 7v9H4z"/><path d="M10 20v-5h4v5"/>',
 'grid':'<rect x="4" y="4" width="6" height="6" rx="1"/><rect x="14" y="4" width="6" height="6" rx="1"/><rect x="4" y="14" width="6" height="6" rx="1"/><rect x="14" y="14" width="6" height="6" rx="1"/>',
 'tag':'<path d="M3 12V4h8l9 9-8 8-9-9z"/><circle cx="7.5" cy="7.5" r="1.5"/>',
 'user':'<circle cx="12" cy="8" r="4"/><path d="M4 21c1-4 4-6 8-6s7 2 8 6"/>',
 'chevL':'<path d="M15 5l-7 7 7 7"/>', 'chevR':'<path d="M9 5l7 7-7 7"/>', 'chevD':'<path d="M6 9l6 6 6-6"/>', 'chevU':'<path d="M6 15l6-6 6 6"/>',
 'arrowL':'<path d="M20 12H5"/><path d="M11 6l-6 6 6 6"/>', 'arrowR':'<path d="M4 12h15"/><path d="M13 6l6 6-6 6"/>',
 'shareI':'<path d="M12 3v12"/><path d="M8 7l4-4 4 4"/><path d="M5 12v8h14v-8"/>',
 'shareA':'<circle cx="18" cy="5" r="2.5"/><circle cx="6" cy="12" r="2.5"/><circle cx="18" cy="19" r="2.5"/><path d="M8.2 10.8l7.6-4.6M8.2 13.2l7.6 4.6"/>',
 'pin':'<path d="M12 21s-6-6-6-11a6 6 0 0 1 12 0c0 5-6 11-6 11z"/><circle cx="12" cy="10" r="2"/>',
 'truck':'<path d="M3 6h11v10H3z"/><path d="M14 10h4l3 3v3h-7"/><circle cx="7" cy="17" r="2"/><circle cx="17" cy="17" r="2"/>',
 'ret':'<path d="M4 9h11a5 5 0 0 1 0 10H8"/><path d="M8 5L4 9l4 4"/>',
 'shield':'<path d="M12 3l8 3v6c0 5-4 8-8 9-4-1-8-4-8-9V6z"/><path d="M9 12l2 2 4-4"/>',
 'plus':'<path d="M12 5v14M5 12h14"/>', 'minus':'<path d="M5 12h14"/>', 'x':'<path d="M6 6l12 12M18 6L6 18"/>',
 'trash':'<path d="M4 7h16"/><path d="M9 7V4h6v3"/><path d="M6 7l1 13h10l1-13"/>',
 'sort':'<path d="M7 4v16M3 16l4 4 4-4M17 20V4M13 8l4-4 4 4"/>',
 'check':'<path d="M5 12l5 5 9-10"/>',
 'bell':'<path d="M6 16V11a6 6 0 0 1 12 0v5l2 2H4z"/><path d="M10 20a2 2 0 0 0 4 0"/>',
 'lock':'<rect x="5" y="11" width="14" height="10" rx="2"/><path d="M8 11V7a4 4 0 0 1 8 0v4"/>',
 'upi':'<path d="M7 4l5 16M12 4l5 16"/>',
 'card':'<rect x="3" y="6" width="18" height="13" rx="2"/><path d="M3 10h18"/>',
 'bank':'<path d="M3 10l9-6 9 6"/><path d="M5 10v8M10 10v8M14 10v8M19 10v8M3 20h18"/>',
 'clock':'<circle cx="12" cy="12" r="9"/><path d="M12 7v5l3 2"/>',
 'mic':'<rect x="9" y="3" width="6" height="11" rx="3"/><path d="M5 11a7 7 0 0 0 14 0M12 18v3"/>',
 'box':'<path d="M3 7l9-4 9 4v10l-9 4-9-4z"/><path d="M3 7l9 4 9-4M12 11v10"/>',
 'moon':'<path d="M20 14A8 8 0 1 1 10 4a6 6 0 0 0 10 10z"/>',
 'globe':'<circle cx="12" cy="12" r="9"/><path d="M3 12h18M12 3a14 14 0 0 1 0 18M12 3a14 14 0 0 0 0 18"/>',
 'help':'<circle cx="12" cy="12" r="9"/><path d="M9.5 9a2.5 2.5 0 1 1 3.5 2.3c-.6.3-1 .9-1 1.6V14"/><path d="M12 17h.01"/>',
 'chat':'<path d="M4 5h16v11H9l-5 4z"/>',
 'logout':'<path d="M15 4h4v16h-4"/><path d="M10 8l-4 4 4 4M6 12h10"/>',
 'star':'<path d="M12 3l2.7 5.6 6.1.9-4.4 4.3 1 6.1L12 17l-5.4 2.9 1-6.1L3.2 9.5l6.1-.9z"/>',
 'sliders':'<path d="M4 7h10M18 7h2M4 17h4M12 17h8"/><circle cx="16" cy="7" r="2"/><circle cx="10" cy="17" r="2"/>',
 'edit':'<path d="M4 20h4L19 9l-4-4L4 16z"/>',
 'car':'<path d="M4 16v-4l2.5-5h11L20 12v4z"/><circle cx="8" cy="16.5" r="2"/><circle cx="16" cy="16.5" r="2"/><path d="M4 12h16"/>',
 'kitchen':'<path d="M4 10h16v4a6 6 0 0 1-6 6h-4a6 6 0 0 1-6-6z"/><path d="M2 10h20"/><path d="M9 7c0-1 1-2 1-3M14 7c0-1 1-2 1-3"/>',
 'clean':'<path d="M8 9h6v12H8z"/><path d="M9 9V6h4l3-2"/><path d="M18 7h2M18 10h2"/>',
 'bath':'<path d="M12 3s6 7 6 11a6 6 0 0 1-12 0c0-4 6-11 6-11z"/>',
 'tools':'<path d="M15 4a4 4 0 0 0-4 5l-7 7 3 3 7-7a4 4 0 0 0 5-4l-3 1-2-2z"/>',
 'kids':'<path d="M4 20l4-1 11-11-3-3L5 16z"/><path d="M14 7l3 3"/>',
 'bottle':'<path d="M10 3h4v3l2 3v12H8V9l2-3z"/><path d="M8 13h8"/>',
 'health':'<path d="M3 12h4l2-4 4 8 2-4h6"/>',
 'bolt':'<path d="M13 3L5 14h6l-1 7 8-11h-6z"/>',
 'fire':'<path d="M12 21a6 6 0 0 0 6-6c0-4-3-6-4-10-2 2-3 4-3 6-1-1-2-2-2-3-2 2-3 4-3 7a6 6 0 0 0 6 6z"/>',
}
def ic(name, size=22, color="currentColor", sw=1.8, label=None, fill="none", cls=""):
    a = f'role="img" aria-label="{label}"' if label else 'aria-hidden="true"'
    c = f' class="{cls}"' if cls else ''
    return f'<svg{c} {a} width="{size}" height="{size}" viewBox="0 0 24 24" fill="{fill}" stroke="{color}" stroke-width="{sw}" stroke-linecap="round" stroke-linejoin="round" style="display: block; flex-shrink: 0">{P[name]}</svg>'

ICONSET = ['car','bolt','bottle','kitchen','clean','bath','kids']
def phd(var="item", h="100%", radius=12, size=40, bg=None):
    bg = bg or C['MUTED']
    inner = "".join(f'<sc-if value="{{{{ {var}.ic_{k} }}}}" hint-placeholder-val="{{{{ {"true" if k=="car" else "false"} }}}}">{ic(k,size,sw=1.4,label="Product photo")}</sc-if>' for k in ICONSET)
    return f'<div style="width: 100%; height: {h}; background: {bg}; border-radius: {radius}px; display: flex; align-items: center; justify-content: center; color: {C["BRAND"]}">{inner}</div>'

def heart_btn(var="item", size=32, top=8, right=8):
    return T(f'''<button type="button" class="nm-press" aria-label="Wishlist" onClick="{{{{ {var}.wish }}}}" style="position: absolute; top: {top}px; right: {right}px; width: {size}px; height: {size}px; border-radius: 999px; border: none; background: rgba(255,255,255,0.94); box-shadow: 0 1px 4px rgba(0,0,0,0.08); color: [[INK]]; display: flex; align-items: center; justify-content: center; padding: 0; cursor: pointer">
<sc-if value="{{{{ {var}.wished }}}}" hint-placeholder-val="{{{{ false }}}}">{ic("heart",18,C["DEAL"],1.8,fill=C["DEAL"],cls="nm-pop")}</sc-if>
<sc-if value="{{{{ {var}.notWished }}}}" hint-placeholder-val="{{{{ true }}}}">{ic("heart",18)}</sc-if>
</button>''')

CSS = T('''body{margin:0}
a{color:[[BRAND]];text-decoration:none}a:hover{color:#245a2b}
.nm-scroll{scrollbar-width:none}.nm-scroll::-webkit-scrollbar{display:none}
@keyframes nmUp{from{opacity:0;transform:translateY(16px)}to{opacity:1;transform:none}}
.nm-up{animation:nmUp .55s cubic-bezier(.2,.8,.2,1) both}
@keyframes nmFade{from{opacity:0}to{opacity:1}}
.nm-fade{animation:nmFade .3s ease both}
@keyframes nmPop{0%{transform:scale(.6)}50%{transform:scale(1.3)}100%{transform:scale(1)}}
.nm-pop{animation:nmPop .45s cubic-bezier(.2,.8,.2,1)}
@keyframes nmBA{0%{transform:scale(1)}40%{transform:scale(1.45)}100%{transform:scale(1)}}
@keyframes nmBB{0%{transform:scale(1)}40%{transform:scale(1.45)}100%{transform:scale(1)}}
.nm-ba{animation:nmBA .5s ease}.nm-bb{animation:nmBB .5s ease}
@keyframes nmShimmer{from{background-position:-300px 0}to{background-position:300px 0}}
.nm-sk{background:linear-gradient(90deg,#EEEEEA 0,#F8F8F5 50%,#EEEEEA 100%);background-size:600px 100%;animation:nmShimmer 1.2s linear infinite}
.nm-press{transition:transform .15s ease,background-color .25s ease,color .25s ease}.nm-press:active{transform:scale(.95)}
@keyframes nmSheet{from{transform:translateY(100%)}to{transform:none}}
.nm-sheet{animation:nmSheet .38s cubic-bezier(.2,.9,.25,1) both}
@keyframes nmDraw{to{stroke-dashoffset:0}}
@keyframes nmConf{0%{transform:translateY(-60px) rotate(0);opacity:1}100%{transform:translateY(640px) rotate(620deg);opacity:0}}
@keyframes nmFloat{0%,100%{transform:translateY(0) rotate(var(--r,6deg))}50%{transform:translateY(-12px) rotate(var(--r,6deg))}}
.nm-float{animation:nmFloat 4s ease-in-out infinite}
@keyframes nmFly{0%{transform:translate(0,0) scale(1);opacity:1}80%{opacity:1}100%{transform:translate(118px,-700px) scale(.25);opacity:0}}
.nm-fly{animation:nmFly .75s cubic-bezier(.5,0,.75,.4) forwards}
@keyframes nmRing{0%{box-shadow:0 0 0 0 rgba(49,114,57,.45)}100%{box-shadow:0 0 0 14px rgba(49,114,57,0)}}
.nm-ring{animation:nmRing 1.4s ease-out infinite}
@keyframes nmDrive{0%,100%{transform:translateX(0)}50%{transform:translateX(5px)}}
.nm-drive{animation:nmDrive 1.2s ease-in-out infinite}
@keyframes nmSpin{to{transform:rotate(360deg)}}
@keyframes nmToast{0%{opacity:0;transform:translate(-50%,20px)}12%{opacity:1;transform:translate(-50%,0)}85%{opacity:1;transform:translate(-50%,0)}100%{opacity:0;transform:translate(-50%,10px)}}
.nm-toast{animation:nmToast 2.2s ease both}
@keyframes nmScaleIn{from{opacity:0;transform:scale(.4) rotate(-12deg)}to{opacity:1;transform:none}}
.nm-scalein{animation:nmScaleIn .7s cubic-bezier(.2,1.4,.4,1) both}
@keyframes nmGrow{from{transform:scaleY(0)}to{transform:scaleY(1)}}
@keyframes nmTick{0%{transform:translateY(-6px);opacity:0}100%{transform:none;opacity:1}}
@media (prefers-reduced-motion:reduce){*{animation-duration:.01ms!important;animation-iteration-count:1!important;transition:none!important}}''')

PRODUCTS = [
 dict(id='vac',name='Vacuum Cleaner',mr='व्हॅक्यूम क्लीनर',price=1000,mrp=2100,icon='car',cat='car'),
 dict(id='washer',name='Portable Washer Gun',mr='पोर्टेबल वॉशर गन',price=1500,mrp=2000,icon='car',cat='car'),
 dict(id='pump',name='Mini Foot Pump',mr='मिनी फूट पंप',price=400,mrp=599,icon='car',cat='car'),
 dict(id='holder',name='Bike Mobile Holder',mr='बाईक मोबाईल होल्डर',price=250,mrp=399,icon='car',cat='car'),
 dict(id='org',name='Car Back Seat Organizer',mr='कार बॅक सीट ऑर्गनायझर',price=150,mrp=180,icon='car',cat='car'),
 dict(id='torch',name='LM 7703 Torch',mr='LM 7703 टॉर्च',price=450,mrp=599,icon='bolt',cat='tools'),
 dict(id='mz',name='Rechargeable Torch (MZ M035)',mr='रिचार्जेबल टॉर्च',price=400,mrp=800,icon='bolt',cat='tools'),
 dict(id='solar',name='Camera Shape Solar Light',mr='कॅमेरा आकाराचा सोलर लाईट',price=400,mrp=700,icon='bolt',cat='tools'),
 dict(id='bottle',name='Steel Bottle',mr='स्टील बाटली',price=200,mrp=400,icon='bottle',cat='kitchen'),
 dict(id='grinder',name='Electric Grinder',mr='इलेक्ट्रिक ग्राइंडर',price=400,mrp=700,icon='kitchen',cat='kitchen'),
 dict(id='plate',name='Leaf Shape Chutney Plate Pack of 10',mr='पानाच्या आकाराची चटणी प्लेट (१० नग)',price=100,mrp=150,icon='kitchen',cat='kitchen'),
 dict(id='divider',name='Refrigerator Adjustable Divider Pack of 5',mr='फ्रिज डिव्हायडर (५ नग)',price=50,mrp=75,icon='kitchen',cat='kitchen'),
 dict(id='duster',name='Microfiber Feather Duster',mr='मायक्रोफायबर फेदर डस्टर',price=200,mrp=300,icon='clean',cat='clean'),
 dict(id='rope',name='Clothes Rope with Hooks',mr='हुकसह कपड्यांची दोरी',price=100,mrp=150,icon='clean',cat='clean'),
 dict(id='mop',name='Feather Mop',mr='फेदर मॉप',price=120,mrp=150,icon='clean',cat='clean'),
 dict(id='clip',name='Toothbrush Cover Clip Pack Of 10',mr='टूथब्रश कव्हर क्लिप 10 नगांचा संच',price=100,mrp=200,icon='bath',cat='bath'),
 dict(id='soap',name='Wall Mounted Soap Rack (Pack of 04)',mr='भिंतीवर लावण्यासाठी साबणाचा ट्रे (०४ नग)',price=100,mrp=130,icon='bath',cat='bath'),
 dict(id='tablet',name='LCD Writing Tablet',mr='एलसीडी रायटिंग टॅब्लेट',price=100,mrp=150,icon='kids',cat='kids'),
]
COMMON_JS = '''get P(){ if(!this._P){ this._P = ''' + json.dumps(PRODUCTS, ensure_ascii=False) + '''; } return this._P; }
fmt(n){ return '\\u20B9' + Number(n).toLocaleString('en-IN'); }
prod(id){ return this.P.find(function(p){ return p.id === id; }); }
item(p, extra){
const o = Object.assign({}, p, { priceTxt: this.fmt(p.price), mrpTxt: this.fmt(p.mrp), off: Math.round((1 - p.price / p.mrp) * 100) }, extra || {});
['car','bolt','bottle','kitchen','clean','bath','kids'].forEach(function(k){ o['ic_' + k] = p.icon === k; });
return o;
}
later(fn, ms){ this._t = this._t || []; this._t.push(setTimeout(fn, ms)); }
componentWillUnmount(){ (this._t || []).forEach(clearTimeout); (this._i || []).forEach(clearInterval); }
every(fn, ms){ this._i = this._i || []; this._i.push(setInterval(fn, ms)); }'''

CUR = {"ios": True}
def page(title, body, state, methods, vals, lang="en"):
    methods = methods + "\nget isIOS(){ return " + ("true" if CUR["ios"] else "false") + "; }"
    js = f'''class Component extends DCLogic {{
constructor(props){{ super(props); this.state = {state}; }}
{COMMON_JS}
{methods}
renderVals() {{
const s = this.state; const self = this;
{vals}
}}
}}'''
    return f'''<!doctype html>
<html lang="{lang}">
<head>
<meta charset="utf-8">
<title>{title}</title>
<script src="./support.js"></script>
</head>
<body>
<x-dc>
<helmet>
<link rel="preconnect" href="https://fonts.googleapis.com">
<link rel="stylesheet" href="https://fonts.googleapis.com/css2?family=Inter:wght@400;500;600;700;800&amp;family=Noto+Sans+Devanagari:wght@400;500;600;700&amp;display=swap">
<style>
{CSS}
</style>
</helmet>
<div style="width: {W}px; height: {H}px; position: relative; overflow: hidden; background: {C['BG']}; color: {C['INK']}; font-family: {FONT}; box-sizing: border-box">
{body}
</div>
</x-dc>
<script type="text/x-dc" data-dc-script data-props='{{"$preview":{{"width":{W},"height":{H}}}}}'>
{js}
</script>
</body>
</html>
'''

class Plat:
    def __init__(s, kind):
        s.ios = kind == "ios"
    def f(s, screen):
        if screen == "Home": return "Main.dc.html" if s.ios else "Android-Home.dc.html"
        return ("iOS-" if s.ios else "Android-") + screen + ".dc.html"
    @property
    def r(s): return 14 if s.ios else 12
    @property
    def top(s): return 54 if s.ios else 36
    @property
    def pad(s): return 20 if s.ios else 16
    @property
    def tabH(s): return 83 if s.ios else 96
    @property
    def barBottom(s): return 34 if s.ios else 28

def wordmark(light=False):
    ink = "#fff" if light else C['INK']; acc = C['GOLD'] if light else C['BRAND']
    box = "#fff" if light else C['BRAND']; boxc = C['BRAND'] if light else "#fff"
    return f'''<div style="display: flex; align-items: center; gap: 8px">
<div style="width: 32px; height: 32px; border-radius: 9px; background: {box}; color: {boxc}; display: flex; align-items: center; justify-content: center; font-weight: 800; font-size: 17px">M</div>
<div style="font-weight: 800; font-size: 18px; letter-spacing: 0.2px; color: {ink}">NIRMAL <span style="color: {acc}">MART</span></div>
</div>'''

def iconbtn(name, label, href=None, size=40, bg="transparent", badge_hole=None, onclick=None, color=None, iconsize=22):
    col = color or C['INK']
    b = ''
    if badge_hole:
        b = f'<sc-if value="{{{{ hasBag }}}}" hint-placeholder-val="{{{{ true }}}}"><span class="{{{{ badgeCls }}}}" style="position: absolute; top: 2px; right: 0px; min-width: 18px; height: 18px; padding: 0 5px; box-sizing: border-box; border-radius: 9px; background: {C["DEAL"]}; color: #fff; font-size: 11px; font-weight: 700; display: flex; align-items: center; justify-content: center">{{{{ {badge_hole} }}}}</span></sc-if>'
    st = f'position: relative; width: {size}px; height: {size}px; border-radius: 999px; background: {bg}; border: none; display: flex; align-items: center; justify-content: center; color: {col}; padding: 0; cursor: pointer; box-sizing: border-box; flex-shrink: 0'
    if href:
        return f'<a href="{href}" aria-label="{label}" class="nm-press" style="{st}">{ic(name, iconsize)}{b}</a>'
    oc = f' onClick="{{{{ {onclick} }}}}"' if onclick else ''
    return f'<button type="button" aria-label="{label}" class="nm-press"{oc} style="{st}">{ic(name, iconsize)}{b}</button>'

def tabbar(p, active):
    items = [("home","Home","Home"),("grid","Shop","Shop"),("heart","Wishlist","Wishlist"),("user","Account","Account")]
    out = []
    for icn, lab, scr in items:
        on = lab == active
        href = p.f(scr)
        if p.ios:
            col = C['BRAND'] if on else C['FAINT']
            out.append(f'<a href="{href}" class="nm-press" style="flex: 1; display: flex; flex-direction: column; align-items: center; gap: 3px; padding-top: 7px; color: {col}; font-size: 10px; font-weight: {600 if on else 500}">{ic(icn,26,sw=2 if on else 1.7, fill=(C["BRAND"] if on and icn in ("heart","home") else "none"))}<span>{lab}</span></a>')
        else:
            pill = f"background: {C['BSOFT']}; color: {C['BRAND']}; " if on else f"color: {C['SOFT']}; "
            out.append(f'<a href="{href}" class="nm-press" style="flex: 1; display: flex; flex-direction: column; align-items: center; gap: 4px; padding-top: 12px; color: {C["INK"] if on else C["SOFT"]}; font-size: 12px; font-weight: {700 if on else 500}"><span style="width: 64px; height: 32px; border-radius: 16px; {pill}display: flex; align-items: center; justify-content: center">{ic(icn,24,sw=2 if on else 1.7)}</span><span>{lab}</span></a>')
    if p.ios:
        return f'<nav aria-label="Main" style="position: absolute; left: 0; right: 0; bottom: 0; height: 83px; background: rgba(250,250,248,0.9); backdrop-filter: blur(20px); -webkit-backdrop-filter: blur(20px); border-top: 1px solid {C["LINE"]}; display: flex; box-sizing: border-box; padding: 0 8px; z-index: 5">{"".join(out)}</nav>'
    return f'<nav aria-label="Main" style="position: absolute; left: 0; right: 0; bottom: 0; height: 96px; background: #F1F3EE; display: flex; box-sizing: border-box; padding: 0 8px 16px; z-index: 5">{"".join(out)}</nav>'

def header(p, title, back_href=None, back_label="Back", right="", mr=None, large=False):
    """iOS: nav bar w/ centered title (or large title below). Android: top app bar."""
    if p.ios:
        left = f'<a href="{back_href}" class="nm-press" style="display: flex; align-items: center; gap: 2px; font-size: 17px; margin-left: -6px; min-width: 70px">{ic("chevL",24,sw=2.2)}{back_label}</a>' if back_href else '<span style="min-width: 70px"></span>'
        center = '' if large else f'<div style="font-size: 17px; font-weight: 700">{title}</div>'
        bar = f'<div style="padding: {p.top}px 16px 0; height: 44px; box-sizing: content-box; display: flex; align-items: center; justify-content: space-between">{left}{center}<div style="display: flex; gap: 2px; min-width: 70px; justify-content: flex-end">{right}</div></div>'
        if large:
            m = f'<div lang="mr" style="font-size: 14px; color: {C["FAINT"]}">{mr}</div>' if mr else ''
            bar += f'<div style="padding: 4px 20px 0"><h1 style="margin: 0; font-size: 32px; font-weight: 800; letter-spacing: -0.6px; line-height: 1.12">{title}</h1>{m}</div>'
        return bar
    back = iconbtn("arrowL","Back",back_href,size=48) if back_href else '<span style="width: 12px"></span>'
    m = f'<div lang="mr" style="font-size: 12px; color: {C["FAINT"]}">{mr}</div>' if mr else ''
    return f'<div style="padding: {p.top}px 4px 0; height: 64px; box-sizing: content-box; display: flex; align-items: center; gap: 4px">{back}<div style="flex: 1; min-width: 0"><h1 style="margin: 0; font-size: 22px; font-weight: 700; line-height: 1.2">{title}</h1>{m}</div>{right}</div>'

def btn_primary(p, inner, href=None, onclick=None, flex="flex: 1", extra=""):
    if p.ios:
        st = f"{flex}; height: 50px; border-radius: 14px; background: {C['BRAND']}; color: #fff; font-size: 17px; font-weight: 700; display: flex; align-items: center; justify-content: center; gap: 8px; border: none; cursor: pointer; font-family: inherit; {extra}"
    else:
        st = f"{flex}; height: 56px; border-radius: 28px; background: {C['BRAND']}; color: #fff; font-size: 16px; font-weight: 700; display: flex; align-items: center; justify-content: center; gap: 8px; border: none; cursor: pointer; font-family: inherit; box-shadow: 0 2px 6px rgba(49,114,57,0.3); {extra}"
    if href: return f'<a href="{href}" class="nm-press" style="{st}">{inner}</a>'
    return f'<button type="button" class="nm-press" onClick="{{{{ {onclick} }}}}" style="{st}">{inner}</button>'

def bottom_bar(p, inner):
    if p.ios:
        st = f"background: rgba(255,255,255,0.94); backdrop-filter: blur(20px); -webkit-backdrop-filter: blur(20px); border-top: 1px solid {C['LINE']}; padding: 12px 20px 34px"
    else:
        st = "background: #F1F3EE; padding: 12px 16px 28px"
    return f'<div style="position: absolute; left: 0; right: 0; bottom: 0; {st}; display: flex; align-items: center; gap: 14px; z-index: 5">{inner}</div>'

def scroll(p, inner, bottom):
    return f'<div class="nm-scroll" style="position: absolute; top: 0; left: 0; right: 0; bottom: {bottom}px; overflow-y: auto; overflow-x: hidden">{inner}</div>'

def switch(p, var):
    if p.ios:
        return f'<button type="button" role="switch" aria-checked="{{{{ {var}.on }}}}" aria-label="{{{{ {var}.label }}}}" onClick="{{{{ {var}.toggle }}}}" style="width: 51px; height: 31px; border-radius: 16px; border: none; padding: 2px; background: {{{{ {var}.track }}}}; cursor: pointer; transition: background-color .25s ease; flex-shrink: 0"><span style="display: block; width: 27px; height: 27px; border-radius: 999px; background: #fff; box-shadow: 0 2px 4px rgba(0,0,0,0.2); transform: translateX({{{{ {var}.x }}}}px); transition: transform .25s cubic-bezier(.3,1.3,.5,1)"></span></button>'
    return f'<button type="button" role="switch" aria-checked="{{{{ {var}.on }}}}" aria-label="{{{{ {var}.label }}}}" onClick="{{{{ {var}.toggle }}}}" style="width: 52px; height: 32px; border-radius: 16px; border: 2px solid {{{{ {var}.border }}}}; padding: 0 4px; background: {{{{ {var}.track }}}}; cursor: pointer; transition: background-color .25s ease; flex-shrink: 0; box-sizing: border-box; display: flex; align-items: center"><span style="display: block; width: {{{{ {var}.knob }}}}px; height: {{{{ {var}.knob }}}}px; border-radius: 999px; background: {{{{ {var}.knobBg }}}}; transform: translateX({{{{ {var}.ax }}}}px); transition: all .25s ease"></span></button>'

SWITCH_JS = '''sw(on, label, toggle){ return { on: on ? 'true' : 'false', label: label, toggle: toggle, track: on ? '#317239' : (this.isIOS ? '#E2E2DC' : '#E3E5DE'), x: on ? 20 : 0, border: on ? '#317239' : '#72766C', knob: on ? 24 : 16, knobBg: on ? '#fff' : '#72766C', ax: on ? 16 : 0 }; }'''

def bagbadge_js():
    return "hasBag: s.bag > 0, bag: s.bag, badgeCls: s.bump ? 'nm-ba' : 'nm-bb',"

# ======================= SCREENS =======================
def welcome(p):
    langs = f'''<sc-for list="{{{{ langs }}}}" as="l" hint-placeholder-count="2">
<button type="button" class="nm-press" onClick="{{{{ l.pick }}}}" style="flex: 1; height: 64px; border-radius: {p.r}px; border: 2px solid {{{{ l.border }}}}; background: {{{{ l.bg }}}}; color: #fff; font: inherit; display: flex; align-items: center; justify-content: space-between; padding: 0 16px; cursor: pointer">
<span style="text-align: left"><span style="display: block; font-size: 17px; font-weight: 700">{{{{ l.name }}}}</span><span style="display: block; font-size: 12px; opacity: 0.8">{{{{ l.sub }}}}</span></span>
<span style="width: 22px; height: 22px; border-radius: 999px; border: 2px solid #fff; display: flex; align-items: center; justify-content: center; box-sizing: border-box"><sc-if value="{{{{ l.on }}}}" hint-placeholder-val="{{{{ false }}}}"><span class="nm-pop" style="width: 10px; height: 10px; border-radius: 999px; background: #fff"></span></sc-if></span>
</button>
</sc-for>'''
    tiles = ""
    for (x, y, sz, icn, rot, d, bg) in [(36,120,96,"car","-8deg",0,"#fff"),(250,96,110,"bolt","7deg",0.6,"#fff"),(150,236,84,"kitchen","4deg",1.2,"#F3D9A4"),(268,290,70,"bottle","-6deg",1.8,"#fff"),(40,300,70,"clean","10deg",0.9,"#E9F3EB")]:
        tiles += f'<div class="nm-float" style="--r: {rot}; animation-delay: {d}s; position: absolute; left: {x}px; top: {y}px; width: {sz}px; height: {sz}px; border-radius: {sz//4}px; background: {bg}; box-shadow: 0 12px 30px rgba(0,0,0,0.18); display: flex; align-items: center; justify-content: center; color: {C["BRAND"]}">{ic(icn, sz//2, sw=1.3, label="Product photo")}</div>'
    body = f'''<div style="position: absolute; inset: 0; background: {C['BRAND']}; color: #fff">
<div style="position: absolute; top: 0; left: 0; right: 0; height: 430px">{tiles}</div>
<div style="position: absolute; left: 0; right: 0; bottom: 0; padding: 0 {p.pad}px {p.barBottom + 8}px; display: flex; flex-direction: column; gap: 14px">
<div class="nm-scalein" style="animation-delay: .1s">{wordmark(True)}</div>
<h1 class="nm-up" style="animation-delay: .25s; margin: 0; font-size: 32px; font-weight: 800; letter-spacing: -0.6px; line-height: 1.1">Trending gadgets &amp; everyday essentials</h1>
<div class="nm-up" lang="mr" style="animation-delay: .35s; font-size: 15px; opacity: 0.9">ट्रेंडिंग गॅझेट्स आणि रोजच्या गरजेच्या वस्तू</div>
<div class="nm-up" style="animation-delay: .45s; display: flex; align-items: center; gap: 8px; font-size: 14px; color: #F3D9A4; font-weight: 600">{ic("truck",18)}Delivered across Maharashtra</div>
<div class="nm-up" style="animation-delay: .55s; font-size: 13px; font-weight: 600; opacity: 0.85; margin-top: 6px">Choose your language · भाषा निवडा</div>
<div class="nm-up" style="animation-delay: .6s; display: flex; gap: 10px">{langs}</div>
<a href="{p.f('Login')}" class="nm-press nm-up" style="animation-delay: .7s; height: {50 if p.ios else 56}px; border-radius: {14 if p.ios else 28}px; background: #fff; color: {C['INK']}; font-size: 17px; font-weight: 700; display: flex; align-items: center; justify-content: center; gap: 8px">{{{{ cta }}}} {ic("arrowR",20,sw=2.2)}</a>
<a href="{p.f('Home')}" class="nm-up" style="animation-delay: .8s; text-align: center; color: #fff; font-size: 15px; font-weight: 600; padding: 6px">{{{{ guest }}}}</a>
</div>
</div>'''
    state = "{ lang: 'en' }"
    vals = '''const L = [{id:'en', name:'English', sub:'Continue in English'}, {id:'mr', name:'मराठी', sub:'मराठीत सुरू ठेवा'}];
return { langs: L.map(function(l){ const on = s.lang === l.id; return Object.assign({}, l, { on: on, border: on ? '#fff' : 'rgba(255,255,255,0.35)', bg: on ? 'rgba(255,255,255,0.16)' : 'transparent', pick: function(){ self.setState({ lang: l.id }); } }); }),
cta: s.lang === 'mr' ? 'पुढे चला' : 'Get started', guest: s.lang === 'mr' ? 'लॉगिन न करता ब्राउझ करा' : 'Browse as guest' };'''
    return page("Welcome", body, state, "", vals)

def login(p):
    P['eye'] = '<path d="M2 12s3.6-7 10-7 10 7 10 7-3.6 7-10 7S2 12 2 12z"/><circle cx="12" cy="12" r="3"/>'
    P['eyeOff'] = '<path d="M3 3l18 18"/><path d="M10.6 5.1A10 10 0 0 1 12 5c6.4 0 10 7 10 7a17 17 0 0 1-3.2 4.1M6.6 6.6C3.8 8.3 2 12 2 12s3.6 7 10 7a9.8 9.8 0 0 0 5.4-1.6"/><path d="M9.9 9.9a3 3 0 0 0 4.2 4.2"/>'
    P['mail'] = '<rect x="3" y="5" width="18" height="14" rx="2"/><path d="M3 7l9 6 9-6"/>'
    def field(label, inner_input, lead=None, trail=""):
        if p.ios:
            return f'<label style="display: flex; flex-direction: column; gap: 6px"><span style="font-size: 13px; font-weight: 600; color: {C["SOFT"]}">{label}</span><span style="height: 50px; border: 1.5px solid {C["LINE"]}; border-radius: 12px; background: #fff; display: flex; align-items: center; gap: 8px; padding: 0 6px 0 14px; color: {C["FAINT"]}">{lead or ""}{inner_input}{trail}</span></label>'
        return f'<label style="position: relative; display: block"><span style="position: absolute; top: -8px; left: 12px; background: {C["BG"]}; padding: 0 4px; font-size: 12px; color: {C["SOFT"]}; z-index: 1">{label}</span><span style="height: 56px; border: 1px solid #8A8D84; border-radius: 4px; display: flex; align-items: center; gap: 10px; padding: 0 6px 0 16px; color: {C["SOFT"]}">{lead or ""}{inner_input}{trail}</span></label>'
    inp = lambda typ, ph, val, onc, mode="text", ac="": f'<input type="{typ}" inputmode="{mode}" autocomplete="{ac}" placeholder="{ph}" value="{{{{ {val} }}}}" onChange="{{{{ {onc} }}}}" style="flex: 1; min-width: 0; border: none; outline: none; background: transparent; font: inherit; font-size: 16px; color: {C["INK"]}">'
    eye = f'<button type="button" aria-label="{{{{ eyeLabel }}}}" onClick="{{{{ toggleShow }}}}" style="width: 40px; height: 40px; border: none; background: none; color: {C["FAINT"]}; display: flex; align-items: center; justify-content: center; padding: 0; cursor: pointer"><sc-if value="{{{{ show }}}}" hint-placeholder-val="{{{{ false }}}}"><span class="nm-pop" style="display: flex">{ic("eyeOff",20)}</span></sc-if><sc-if value="{{{{ hide }}}}" hint-placeholder-val="{{{{ true }}}}"><span class="nm-pop" style="display: flex">{ic("eye",20)}</span></sc-if></button>'
    pw = f'<input type="{{{{ pwType }}}}" autocomplete="{{{{ pwAc }}}}" placeholder="{{{{ pwPh }}}}" value="{{{{ pw }}}}" onChange="{{{{ onPw }}}}" style="flex: 1; min-width: 0; border: none; outline: none; background: transparent; font: inherit; font-size: 16px; color: {C["INK"]}">'
    if p.ios:
        seg = f'''<div role="tablist" style="background: #EEEEEA; border-radius: 10px; padding: 2px; display: flex; position: relative"><span style="position: absolute; top: 2px; bottom: 2px; left: 2px; width: calc(50% - 2px); border-radius: 8px; background: #fff; box-shadow: 0 1px 3px rgba(0,0,0,0.12); transform: translateX({{{{ segX }}}}%); transition: transform .3s cubic-bezier(.3,1.2,.5,1)"></span><button type="button" role="tab" aria-selected="{{{{ inSel }}}}" onClick="{{{{ toIn }}}}" style="flex: 1; height: 34px; border: none; background: transparent; font: inherit; font-size: 14px; font-weight: 600; position: relative; cursor: pointer; color: {C['INK']}">Sign in</button><button type="button" role="tab" aria-selected="{{{{ upSel }}}}" onClick="{{{{ toUp }}}}" style="flex: 1; height: 34px; border: none; background: transparent; font: inherit; font-size: 14px; font-weight: 600; position: relative; cursor: pointer; color: {C['INK']}">Create account</button></div>'''
    else:
        seg = f'''<div role="tablist" style="display: flex; border: 1px solid #8A8D84; border-radius: 20px; overflow: hidden; height: 40px"><button type="button" role="tab" aria-selected="{{{{ inSel }}}}" onClick="{{{{ toIn }}}}" style="flex: 1; border: none; border-right: 1px solid #8A8D84; background: {{{{ inBg }}}}; font: inherit; font-size: 14px; font-weight: 600; color: {C['INK']}; display: flex; align-items: center; justify-content: center; gap: 6px; cursor: pointer; transition: background-color .25s ease"><sc-if value="{{{{ isIn }}}}" hint-placeholder-val="{{{{ true }}}}"><span class="nm-pop" style="display: flex">{ic("check",16,sw=2.4)}</span></sc-if>Sign in</button><button type="button" role="tab" aria-selected="{{{{ upSel }}}}" onClick="{{{{ toUp }}}}" style="flex: 1; border: none; background: {{{{ upBg }}}}; font: inherit; font-size: 14px; font-weight: 600; color: {C['INK']}; display: flex; align-items: center; justify-content: center; gap: 6px; cursor: pointer; transition: background-color .25s ease"><sc-if value="{{{{ isUp }}}}" hint-placeholder-val="{{{{ false }}}}"><span class="nm-pop" style="display: flex">{ic("check",16,sw=2.4)}</span></sc-if>Create account</button></div>'''
    perks = "".join(f'<div class="nm-up" style="animation-delay: {0.3 + i*0.08:.2f}s; display: flex; align-items: center; gap: 10px; font-size: 13.5px; color: {C["SOFT"]}"><span style="width: 30px; height: 30px; border-radius: 9px; background: {C["BSOFT"]}; color: {C["BRAND"]}; display: flex; align-items: center; justify-content: center; flex-shrink: 0">{ic(a,16)}</span>{b}</div>' for i, (a, b) in enumerate([("truck","Free delivery on orders above ₹499"),("heart","Save favourites to your wishlist"),("box","Track every order in real time")]))
    cta_st = f"height: {50 if p.ios else 56}px; border-radius: {14 if p.ios else 28}px; background: {C['BRAND']}; color: #fff; font-size: 17px; font-weight: 700; display: flex; align-items: center; justify-content: center; gap: 8px; opacity: {{{{ ctaOpacity }}}}; transition: opacity .25s ease"
    inner = f'''{header(p, "", p.f("Welcome"), "Back", right=f'<a href="{p.f("Home")}" style="font-size: 15px; font-weight: 600; padding: {"8px 4px" if p.ios else "12px 16px"}">Skip</a>')}
<div style="padding: 8px {p.pad}px 30px; display: flex; flex-direction: column; gap: 18px">
<div><h1 key="{{{{ mode }}}}" class="nm-up" style="margin: 0; font-size: 30px; font-weight: 800; letter-spacing: -0.5px">{{{{ title }}}}</h1><div key="{{{{ mode }}}}s" class="nm-up" style="animation-delay: .05s; font-size: 15px; color: {C['SOFT']}; margin-top: 6px">{{{{ sub }}}}</div><div lang="mr" style="font-size: 13px; color: {C['FAINT']}; margin-top: 2px">ट्रेंडिंग गॅझेट्स, उत्तम किमतीत</div></div>
{seg}
<sc-if value="{{{{ isUp }}}}" hint-placeholder-val="{{{{ false }}}}"><div class="nm-up">{field("Full name", inp("text","Your name","name","onName",ac="name"), ic("user",20))}</div></sc-if>
<div>{field("{{ emailLabel }}", inp("email","you@example.com","email","onEmail","email","username"), ic("mail",20))}</div>
<sc-if value="{{{{ isUp }}}}" hint-placeholder-val="{{{{ false }}}}"><div class="nm-up" style="animation-delay: .05s">{field("Mobile number", inp("tel","10-digit number","mobile","onMobile","numeric","tel"), f'<span style="font-size: 16px; font-weight: 600; color: {C["INK"]}">+91</span>')}</div></sc-if>
<div>{field("Password", pw, ic("lock",20), eye)}</div>
<sc-if value="{{{{ isIn }}}}" hint-placeholder-val="{{{{ true }}}}"><a href="#" style="align-self: flex-end; margin-top: -8px; font-size: 14px; font-weight: 600">Forgot password?</a></sc-if>
<a href="{p.f('Home')}" class="nm-press" style="{cta_st}">{{{{ cta }}}} {ic("arrowR",20,"#fff",2.2)}</a>
<div style="text-align: center; font-size: 14px; color: {C['SOFT']}">{{{{ switchQ }}}} <button type="button" onClick="{{{{ flip }}}}" style="border: none; background: none; color: {C['BRAND']}; font: inherit; font-weight: 700; padding: 4px; cursor: pointer">{{{{ switchA }}}}</button></div>
<sc-if value="{{{{ isIn }}}}" hint-placeholder-val="{{{{ true }}}}"><div style="display: flex; flex-direction: column; gap: 10px; padding-top: 6px; border-top: 1px solid {C['LINE']}; margin-top: 4px; padding-top: 18px">{perks}</div></sc-if>
<sc-if value="{{{{ isUp }}}}" hint-placeholder-val="{{{{ false }}}}"><div style="font-size: 12px; color: {C['FAINT']}; line-height: 1.5; text-align: center">By creating an account you agree to Nirmal Mart’s Terms and Privacy Policy.</div></sc-if>
</div>'''
    body = scroll(p, inner, 0)
    state = "{ mode: 'in', show: false, name: '', email: '', mobile: '', pw: '' }"
    vals = '''const up = s.mode === 'up';
const ready = up ? (s.name && s.email && s.mobile.length === 10 && s.pw.length >= 6) : (s.email && s.pw);
const set = function(k, f){ return function(e){ const o = {}; o[k] = f ? f(e.target.value) : e.target.value; self.setState(o); }; };
return { mode: s.mode, isIn: !up, isUp: up, inSel: up ? 'false' : 'true', upSel: up ? 'true' : 'false', segX: up ? 100 : 0,
inBg: up ? 'transparent' : '#E9F3EB', upBg: up ? '#E9F3EB' : 'transparent',
toIn: function(){ self.setState({ mode: 'in' }); }, toUp: function(){ self.setState({ mode: 'up' }); }, flip: function(){ self.setState({ mode: up ? 'in' : 'up' }); },
title: up ? 'Create your account' : 'Welcome back', sub: up ? 'It takes less than a minute.' : 'Sign in to continue shopping.',
emailLabel: up ? 'Email' : 'Email or username', cta: up ? 'Create account' : 'Sign in',
switchQ: up ? 'Already have an account?' : 'New to NirmalMart?', switchA: up ? 'Sign in' : 'Create an account',
name: s.name, email: s.email, mobile: s.mobile, pw: s.pw,
onName: set('name'), onEmail: set('email'), onMobile: set('mobile', function(v){ return v.replace(/\\D/g, '').slice(0, 10); }), onPw: set('pw'),
show: s.show, hide: !s.show, pwType: s.show ? 'text' : 'password', pwAc: up ? 'new-password' : 'current-password', pwPh: up ? 'At least 6 characters' : 'Your password',
eyeLabel: s.show ? 'Hide password' : 'Show password', toggleShow: function(){ self.setState({ show: !s.show }); },
ctaOpacity: ready ? 1 : 0.5 };'''
    return page("Sign in", body, state, "", vals)

def prod_card_h(p, href, w=150):
    return f'''<div class="nm-up" style="animation-delay: {{{{ item.delay }}}}ms; position: relative; width: {w}px; flex-shrink: 0; background: #fff; border: 1px solid {C['LINE']}; border-radius: {p.r}px; padding: 8px; box-sizing: border-box; display: flex; flex-direction: column; gap: 5px">
<a href="{href}" style="color: {C['INK']}; display: flex; flex-direction: column; gap: 5px">
<div style="position: relative; height: 128px">{phd("item","128px",p.r-4,44)}<span style="position: absolute; top: 6px; left: 6px; background: {C['DEAL']}; color: #fff; font-size: 11px; font-weight: 700; padding: 3px 7px; border-radius: 6px">-{{{{ item.off }}}}%</span></div>
<div style="font-size: 13px; font-weight: 600; line-height: 1.3; height: 34px; overflow: hidden">{{{{ item.name }}}}</div>
<div style="display: flex; align-items: baseline; gap: 5px"><span style="font-size: 16px; font-weight: 800">{{{{ item.priceTxt }}}}</span><span style="font-size: 11.5px; color: {C['FAINT']}; text-decoration: line-through">{{{{ item.mrpTxt }}}}</span></div>
</a>
{add_btn(p)}
{heart_btn("item",30,14,14)}
</div>'''

def add_btn(p, label="Add"):
    r = 10 if p.ios else 18
    return f'''<button type="button" class="nm-press" onClick="{{{{ item.add }}}}" aria-label="Add {{{{ item.name }}}} to bag" style="height: 34px; border-radius: {r}px; border: {'none' if p.ios else '1px solid #C9CCC4'}; background: {{{{ item.addBg }}}}; color: {{{{ item.addFg }}}}; font: inherit; font-size: 13px; font-weight: 700; display: flex; align-items: center; justify-content: center; gap: 4px; cursor: pointer">
<sc-if value="{{{{ item.added }}}}" hint-placeholder-val="{{{{ false }}}}"><span class="nm-pop" style="display: flex">{ic("check",16,sw=2.6)}</span>Added</sc-if>
<sc-if value="{{{{ item.notAdded }}}}" hint-placeholder-val="{{{{ true }}}}">{ic("plus",16,sw=2.4)}{label}</sc-if>
</button>'''

ITEM_JS = '''mk(p, i){ const self = this; const st = this.state; const added = !!st.added[p.id]; const wished = !!st.wish[p.id];
return this.item(p, { delay: 60 * i, added: added, notAdded: !added, wished: wished, notWished: !wished,
addBg: added ? '#317239' : (this.isIOS ? '#E9F3EB' : 'transparent'), addFg: added ? '#fff' : '#317239',
add: function(){ if (added) return; self.setState(function(s){ const a = Object.assign({}, s.added); a[p.id] = true; return { added: a, bag: s.bag + 1, bump: !s.bump }; }); },
wish: function(){ self.setState(function(s){ const w = Object.assign({}, s.wish); w[p.id] = !w[p.id]; return { wish: w }; }); } }); }'''

def home(p):
    pad = p.pad
    slides_data = [
        (C['BRAND'], "#fff", "TRENDING NOW", "Trending<br>Gadgets", "ट्रेंडिंग गॅझेट्स", "Up to 52% off", "#F3D9A4", ["car","bolt"]),
        (C['MAROON'], "#fff", "EVERYDAY ESSENTIALS", "Home &amp;<br>Kitchen", "घर आणि स्वयंपाकघर", "Shop the range", "#F3D9A4", ["kitchen","bottle"]),
        (C['INK'], "#fff", "FOR YOUR RIDE", "Car &amp; Bike<br>Care", "कार आणि बाईक केअर", "Vacuums, holders &amp; more", C['GOLD'], ["car","tools"]),
        (C['GOLD'], C['INK'], "EVERY ORDER", "Free delivery<br>above ₹499", "₹४९९ वरील ऑर्डरवर मोफत डिलिव्हरी", "+ 5-day return / exchange", C['MAROON'], ["truck","ret"]),
    ]
    slides = ""
    for bg, fg, kicker, title, mr, sub, subc, icons in slides_data:
        btnbg = "#fff" if fg == "#fff" else C['INK']; btnfg = C['INK'] if fg == "#fff" else "#fff"
        slides += f'''<a href="{p.f('Shop')}" style="width: 100%; flex-shrink: 0; height: 176px; background: {bg}; color: {fg}; display: flex; position: relative; overflow: hidden; box-sizing: border-box">
<div style="padding: 18px 0 18px 18px; display: flex; flex-direction: column; gap: 4px; flex: 1; z-index: 1">
<span style="align-self: flex-start; background: rgba(255,255,255,0.18); border-radius: 999px; padding: 4px 10px; font-size: 10.5px; font-weight: 700; letter-spacing: 0.6px">{kicker}</span>
<div style="font-size: 25px; font-weight: 800; line-height: 1.05; margin-top: 6px; letter-spacing: -0.5px">{title}</div>
<div lang="mr" style="font-size: 12.5px; opacity: 0.9">{mr}</div>
<div style="font-size: 13.5px; font-weight: 700; color: {subc}">{sub}</div>
<span style="margin-top: auto; align-self: flex-start; background: {btnbg}; color: {btnfg}; font-size: 13px; font-weight: 700; padding: 8px 14px; border-radius: {12 if p.ios else 999}px; display: flex; align-items: center; gap: 4px">Shop now {ic("chevR",14,sw=2.4)}</span>
</div>
<div style="width: 140px; position: relative">
<div class="nm-float" style="--r: 6deg; position: absolute; top: 18px; right: 16px; width: 100px; height: 100px; background: #fff; border-radius: 18px; display: flex; align-items: center; justify-content: center; color: {C['BRAND']}">{ic(icons[0],46,sw=1.3,label="Product photo")}</div>
<div class="nm-float" style="--r: -8deg; animation-delay: .8s; position: absolute; top: 88px; right: 76px; width: 70px; height: 70px; background: #F7F7F4; border-radius: 14px; display: flex; align-items: center; justify-content: center; color: {C['BRAND']}">{ic(icons[1],32,sw=1.3,label="Product photo")}</div>
</div>
</a>'''
    cats = [("fire","Trending","ट्रेंडिंग"),("kitchen","Kitchen","स्वयंपाकघर"),("clean","Cleaning","स्वच्छता"),("bath","Bathroom","बाथरूम"),("tools","Tools","टूल्स"),("car","Car &amp; Bike","कार-बाईक"),("kids","Kids","मुले"),("bottle","Bottles","बाटल्या")]
    catgrid = "".join(f'''<a href="{p.f('Shop')}" class="nm-press nm-up" style="animation-delay: {0.25 + i*0.05:.2f}s; display: flex; flex-direction: column; align-items: center; gap: 5px; color: {C['INK']}">
<span style="width: 60px; height: 60px; border-radius: {'999px' if p.ios else '18px'}; background: {('#FBEFE0' if i==0 else '#fff')}; border: 1px solid {C['LINE']}; display: flex; align-items: center; justify-content: center; color: {(C['DEAL'] if i==0 else C['BRAND'])}">{ic(c[0],26,sw=1.6)}</span>
<span style="font-size: 11.5px; font-weight: 600; text-align: center; line-height: 1.15">{c[1]}</span>
<span lang="mr" style="font-size: 10px; color: {C['FAINT']}; margin-top: -3px">{c[2]}</span></a>''' for i, c in enumerate(cats))
    if p.ios:
        head = f'''<div style="padding: {p.top}px 20px 0; display: flex; align-items: center; justify-content: space-between">{wordmark()}<div style="display: flex; gap: 2px">{iconbtn("bell","Notifications")}{iconbtn("bag","Bag",p.f("Bag"),badge_hole="bag")}</div></div>
<a href="{p.f('Search')}" class="nm-press" style="margin: 12px 20px 0; height: 44px; border-radius: 12px; background: #EEEEEA; display: flex; align-items: center; gap: 8px; padding: 0 12px; color: {C['FAINT']}; font-size: 16px">{ic("search",18)}<span style="flex: 1">Search products, brands…</span>{ic("mic",18)}</a>
<button type="button" style="margin: 10px 20px 0; padding: 0; border: none; background: none; display: flex; align-items: center; gap: 6px; color: {C['SOFT']}; font-size: 13px; font-family: inherit; cursor: pointer">{ic("pin",16)}<span>Deliver to <b style="color: {C['INK']}">Add pincode</b></span>{ic("chevD",14)}</button>'''
    else:
        head = f'''<div style="padding: {p.top}px 8px 0 16px; height: 64px; box-sizing: content-box; display: flex; align-items: center; justify-content: space-between">{wordmark()}<div style="display: flex">{iconbtn("bell","Notifications",size=48)}{iconbtn("bag","Bag",p.f("Bag"),size=48,badge_hole="bag")}</div></div>
<a href="{p.f('Search')}" class="nm-press" style="margin: 4px 16px 0; height: 56px; border-radius: 28px; background: #ECEFE8; display: flex; align-items: center; gap: 12px; padding: 0 18px; color: {C['SOFT']}; font-size: 16px">{ic("search",22)}<span style="flex: 1">Search Nirmal Mart</span>{ic("mic",22)}</a>
<button type="button" style="margin: 12px 16px 0; padding: 0 12px; height: 32px; border: 1px solid {C['LINE']}; border-radius: 8px; background: #fff; display: flex; align-items: center; gap: 6px; color: {C['SOFT']}; font-size: 13px; font-family: inherit; cursor: pointer">{ic("pin",16)}<span>Deliver to <b style="color: {C['INK']}">Add pincode</b></span>{ic("chevD",14)}</button>'''
    timer = "".join(f'<span style="min-width: 28px; height: 28px; padding: 0 4px; box-sizing: border-box; border-radius: 7px; background: {C["INK"]}; color: #fff; font-size: 14px; font-weight: 800; display: flex; align-items: center; justify-content: center; font-variant-numeric: tabular-nums">{{{{ {k} }}}}</span>' + ('<span style="font-weight: 800; color: ' + C['INK'] + '">:</span>' if k != 'ss' else '') for k in ('hh','mm','ss'))
    inner = f'''{head}
<div style="margin: 14px {pad}px 0; border-radius: {20 if p.ios else 24}px; overflow: hidden; position: relative" class="nm-up">
<div style="display: flex; transform: translateX(-{{{{ slideX }}}}%); transition: transform .7s cubic-bezier(.6,0,.2,1)">{slides}</div>
</div>
<div style="display: flex; justify-content: center; gap: 6px; margin-top: 10px"><sc-for list="{{{{ dots }}}}" as="d" hint-placeholder-count="4"><button type="button" aria-label="Offer {{{{ d.n }}}}" onClick="{{{{ d.go }}}}" style="width: {{{{ d.w }}}}px; height: 6px; border-radius: 3px; border: none; padding: 0; background: {{{{ d.bg }}}}; transition: all .4s ease; cursor: pointer"></button></sc-for></div>
<div style="display: grid; grid-template-columns: repeat(4, minmax(0, 1fr)); gap: 14px 6px; padding: 18px {pad - 4}px 0">{catgrid}</div>
<div style="margin: 22px {pad}px 0; background: #FFF6F4; border: 1px solid #F6D9D4; border-radius: {p.r + 4}px; padding: 14px 0 14px">
<div style="display: flex; align-items: center; justify-content: space-between; padding: 0 14px">
<div><div style="display: flex; align-items: center; gap: 6px; font-size: 19px; font-weight: 800; color: {C['DEAL']}">{ic("bolt",20,C['DEAL'],2,fill=C['DEAL'])}Today’s Deals</div><div lang="mr" style="font-size: 11.5px; color: {C['FAINT']}">आजच्या ऑफर्स</div></div>
<div style="display: flex; align-items: center; gap: 4px"><span style="font-size: 11px; color: {C['FAINT']}; margin-right: 2px">Ends in</span>{timer}</div>
</div>
<div class="nm-scroll" style="display: flex; gap: 10px; overflow-x: auto; padding: 12px 14px 2px">
<sc-for list="{{{{ deals }}}}" as="item" hint-placeholder-count="4">{prod_card_h(p, p.f('Product'))}</sc-for>
</div>
</div>
<div style="display: flex; align-items: baseline; justify-content: space-between; padding: 22px {pad}px 10px"><div><div style="font-size: 19px; font-weight: 800">Home &amp; Kitchen picks</div><div lang="mr" style="font-size: 11.5px; color: {C['FAINT']}">घर आणि स्वयंपाकघर</div></div><a href="{p.f('Shop')}" style="font-size: 14px; font-weight: 600">See all</a></div>
<div class="nm-scroll" style="display: flex; gap: 10px; overflow-x: auto; padding: 0 {pad}px 2px">
<sc-for list="{{{{ kitchen }}}}" as="item" hint-placeholder-count="4">{prod_card_h(p, p.f('Product'))}</sc-for>
</div>
<div style="display: flex; gap: 8px; margin: 22px {pad}px 24px">
{"".join(f'<div style="flex: 1; background: #fff; border: 1px solid {C["LINE"]}; border-radius: {p.r}px; padding: 10px 6px; display: flex; flex-direction: column; align-items: center; gap: 5px; text-align: center; font-size: 11px; font-weight: 600; color: {C["SOFT"]}"><span style="color: {C["BRAND"]}">{ic(a,22)}</span>{b}</div>' for a, b in [("truck","Free delivery above ₹499"),("ret","5-day return / exchange"),("shield","Secure UPI &amp; card payments")])}
</div>'''
    body = scroll(p, inner, 0) + tabbar(p, "Home")
    body = body.replace('bottom: 0px; overflow-y', f'bottom: 0px; padding-bottom: {p.tabH}px; box-sizing: border-box; overflow-y')
    state = "{ slide: 0, now: Date.now(), wish: {}, added: {}, bag: 3, bump: false }"
    methods = ITEM_JS + '''
componentDidMount(){ const self = this; this.every(function(){ self.setState(function(s){ return { slide: (s.slide + 1) % 4 }; }); }, 3800); this.every(function(){ self.setState({ now: Date.now() }); }, 1000); }'''
    vals = '''const end = new Date(s.now); end.setHours(24, 0, 0, 0); let left = Math.max(0, Math.floor((end - s.now) / 1000));
const pad2 = function(n){ return String(n).padStart(2, '0'); };
const deals = this.P.slice().sort(function(a, b){ return (b.mrp - b.price) / b.mrp - (a.mrp - a.price) / a.mrp; }).slice(0, 6);
const kitchen = this.P.filter(function(x){ return x.cat === 'kitchen'; });
return Object.assign({ slideX: s.slide * 100,
dots: [0,1,2,3].map(function(i){ return { n: i + 1, w: i === s.slide ? 20 : 6, bg: i === s.slide ? '#317239' : '#CFCFC8', go: function(){ self.setState({ slide: i }); } }; }),
hh: pad2(Math.floor(left / 3600)), mm: pad2(Math.floor(left % 3600 / 60)), ss: pad2(left % 60),
deals: deals.map(function(x, i){ return self.mk(x, i); }), kitchen: kitchen.map(function(x, i){ return self.mk(x, i); }) }, { ''' + bagbadge_js() + ''' });'''
    return page("Home", body, state, methods, vals)

def search(p):
    pad = p.pad
    if p.ios:
        bar = f'''<div style="padding: {p.top}px 16px 0; display: flex; align-items: center; gap: 10px">
<label style="flex: 1; height: 40px; border-radius: 12px; background: #EEEEEA; display: flex; align-items: center; gap: 8px; padding: 0 10px; color: {C['FAINT']}">{ic("search",18)}<input type="search" autofocus placeholder="Search products, brands…" aria-label="Search" value="{{{{ q }}}}" onChange="{{{{ onQ }}}}" style="border: none; background: transparent; outline: none; font: inherit; font-size: 16px; color: {C['INK']}; flex: 1; min-width: 0"><sc-if value="{{{{ hasQ }}}}" hint-placeholder-val="{{{{ false }}}}"><button type="button" aria-label="Clear" onClick="{{{{ clear }}}}" style="width: 20px; height: 20px; border-radius: 999px; border: none; background: #B8B8B2; color: #fff; display: flex; align-items: center; justify-content: center; padding: 0; cursor: pointer">{ic("x",12,"#fff",3)}</button></sc-if></label>
<a href="{p.f('Home')}" style="font-size: 16px">Cancel</a></div>'''
    else:
        bar = f'''<div style="padding: {p.top + 8}px 16px 0"><label style="height: 56px; border-radius: 28px; background: #ECEFE8; display: flex; align-items: center; gap: 4px; padding: 0 8px 0 4px; color: {C['SOFT']}">{iconbtn("arrowL","Back",p.f("Home"),size=48)}<input type="search" autofocus placeholder="Search Nirmal Mart" aria-label="Search" value="{{{{ q }}}}" onChange="{{{{ onQ }}}}" style="border: none; background: transparent; outline: none; font: inherit; font-size: 16px; color: {C['INK']}; flex: 1; min-width: 0"><sc-if value="{{{{ hasQ }}}}" hint-placeholder-val="{{{{ false }}}}">{iconbtn("x","Clear",size=40,onclick="clear")}</sc-if><sc-if value="{{{{ noQ }}}}" hint-placeholder-val="{{{{ true }}}}">{iconbtn("mic","Voice search",size=40)}</sc-if></label></div>'''
    chip_r = 999 if p.ios else 8
    idle = f'''<sc-if value="{{{{ noQ }}}}" hint-placeholder-val="{{{{ true }}}}"><div class="nm-fade">
<sc-if value="{{{{ hasRecent }}}}" hint-placeholder-val="{{{{ true }}}}">
<div style="display: flex; align-items: center; justify-content: space-between; padding: 20px {pad}px 10px"><div style="font-size: 17px; font-weight: 800">Recent searches</div><button type="button" onClick="{{{{ clearRecent }}}}" style="border: none; background: none; color: {C['BRAND']}; font: inherit; font-size: 14px; font-weight: 600; cursor: pointer; padding: 4px">Clear</button></div>
<div style="display: flex; flex-wrap: wrap; gap: 8px; padding: 0 {pad}px"><sc-for list="{{{{ recent }}}}" as="r" hint-placeholder-count="3"><button type="button" class="nm-press" onClick="{{{{ r.use }}}}" style="height: 34px; padding: 0 12px; border-radius: {chip_r}px; border: 1px solid {C['LINE']}; background: #fff; font: inherit; font-size: 14px; color: {C['INK']}; display: flex; align-items: center; gap: 6px; cursor: pointer">{ic("clock",15)}{{{{ r.t }}}}</button></sc-for></div>
</sc-if>
<div style="padding: 24px {pad}px 6px; font-size: 17px; font-weight: 800">Trending searches</div>
<div style="padding: 0 {pad}px"><sc-for list="{{{{ trending }}}}" as="r" hint-placeholder-count="5"><button type="button" class="nm-up" onClick="{{{{ r.use }}}}" style="animation-delay: {{{{ r.delay }}}}ms; width: 100%; height: 48px; border: none; border-bottom: 1px solid {C['LINE']}; background: none; font: inherit; font-size: 15px; color: {C['INK']}; display: flex; align-items: center; gap: 12px; padding: 0; cursor: pointer; text-align: left"><span style="width: 24px; font-weight: 800; color: {C['DEAL']}">{{{{ r.n }}}}</span><span style="flex: 1">{{{{ r.t }}}}</span>{ic("fire",16,C['DEAL'])}</button></sc-for></div>
<div style="padding: 24px {pad}px 10px; font-size: 17px; font-weight: 800">Browse categories</div>
<div style="display: grid; grid-template-columns: repeat(2, minmax(0, 1fr)); gap: 10px; padding: 0 {pad}px 30px">
{"".join(f'<a href="{p.f("Shop")}" class="nm-press" style="height: 60px; border-radius: {p.r}px; background: #fff; border: 1px solid {C["LINE"]}; display: flex; align-items: center; gap: 10px; padding: 0 12px; color: {C["INK"]}; font-size: 14px; font-weight: 600"><span style="width: 36px; height: 36px; border-radius: 10px; background: {C["BSOFT"]}; color: {C["BRAND"]}; display: flex; align-items: center; justify-content: center">{ic(a,20)}</span>{b}</a>' for a, b in [("kitchen","Home &amp; Kitchen"),("clean","Cleaning &amp; Laundry"),("bath","Bathroom"),("tools","Tools &amp; Outdoor"),("car","Car &amp; Bike Care"),("kids","Kids &amp; School")])}
</div></div></sc-if>'''
    results = f'''<sc-if value="{{{{ hasResults }}}}" hint-placeholder-val="{{{{ false }}}}"><div style="padding: 12px {pad}px 30px">
<div style="font-size: 13px; color: {C['FAINT']}; padding: 4px 0 8px">{{{{ countTxt }}}}</div>
<sc-for list="{{{{ results }}}}" as="item" hint-placeholder-count="4"><a href="{p.f('Product')}" class="nm-up" style="animation-delay: {{{{ item.delay }}}}ms; display: flex; align-items: center; gap: 12px; padding: 10px 0; border-bottom: 1px solid {C['LINE']}; color: {C['INK']}">
<div style="width: 56px; height: 56px; flex-shrink: 0">{phd("item","56px",10,26)}</div>
<div style="flex: 1; min-width: 0"><div style="font-size: 14.5px; font-weight: 600; white-space: nowrap; overflow: hidden; text-overflow: ellipsis">{{{{ item.name }}}}</div><div lang="mr" style="font-size: 11.5px; color: {C['FAINT']}">{{{{ item.mr }}}}</div><div style="display: flex; gap: 6px; align-items: baseline; margin-top: 2px"><span style="font-size: 14px; font-weight: 800">{{{{ item.priceTxt }}}}</span><span style="font-size: 12px; font-weight: 700; color: {C['GREEN']}">{{{{ item.off }}}}% off</span></div></div>
{ic("chevR",18,C['FAINT'])}</a></sc-for>
</div></sc-if>
<sc-if value="{{{{ empty }}}}" hint-placeholder-val="{{{{ false }}}}"><div class="nm-up" style="padding: 70px 40px; text-align: center; display: flex; flex-direction: column; align-items: center; gap: 10px"><span style="width: 72px; height: 72px; border-radius: 999px; background: {C['MUTED']}; color: {C['FAINT']}; display: flex; align-items: center; justify-content: center">{ic("search",32)}</span><div style="font-size: 18px; font-weight: 800">No results for “{{{{ q }}}}”</div><div style="font-size: 14px; color: {C['FAINT']}; line-height: 1.5">Check the spelling or try a broader word like “torch” or “bottle”.</div></div></sc-if>'''
    body = scroll(p, bar + idle + results, 0)
    state = "{ q: '', recent: ['torch', 'steel bottle', 'vacuum'] }"
    vals = '''const q = s.q.trim().toLowerCase();
const res = q ? this.P.filter(function(x){ return (x.name + ' ' + x.mr).toLowerCase().indexOf(q) >= 0; }) : [];
const use = function(t){ return function(){ self.setState({ q: t }); }; };
const T = ['Torch', 'Vacuum cleaner', 'Steel bottle', 'Solar light', 'Mop'];
return { q: s.q, hasQ: !!q, noQ: !q, onQ: function(e){ self.setState({ q: e.target.value }); }, clear: function(){ self.setState({ q: '' }); },
hasRecent: s.recent.length > 0, recent: s.recent.map(function(t){ return { t: t, use: use(t) }; }), clearRecent: function(){ self.setState({ recent: [] }); },
trending: T.map(function(t, i){ return { t: t, n: i + 1, delay: i * 50, use: use(t) }; }),
hasResults: res.length > 0, empty: !!q && res.length === 0, countTxt: res.length + (res.length === 1 ? ' product' : ' products'),
results: res.map(function(x, i){ return self.item(x, { delay: i * 40 }); }) };'''
    return page("Search", body, state, "", vals)

def shop(p):
    pad = 16
    if p.ios:
        chip = f'''<button type="button" class="nm-press" onClick="{{{{ c.pick }}}}" style="flex-shrink: 0; height: 34px; padding: 0 14px; border-radius: 999px; border: none; background: {{{{ c.bg }}}}; color: {{{{ c.fg }}}}; font: inherit; font-size: 14px; font-weight: 600; cursor: pointer">{{{{ c.name }}}}</button>'''
        fchip = lambda lab, hole, onc, extra="": f'<button type="button" class="nm-press" onClick="{{{{ {onc} }}}}" style="flex-shrink: 0; height: 32px; padding: 0 12px; border-radius: 999px; border: 1px solid {{{{ {hole}.bd }}}}; background: {{{{ {hole}.bg }}}}; color: {{{{ {hole}.fg }}}}; font: inherit; font-size: 13px; font-weight: 600; display: flex; align-items: center; gap: 6px; cursor: pointer">{extra}{lab}</button>'
    else:
        chip = f'''<button type="button" class="nm-press" onClick="{{{{ c.pick }}}}" style="flex-shrink: 0; height: 32px; padding: 0 14px; border-radius: 8px; border: 1px solid {{{{ c.bd }}}}; background: {{{{ c.bgA }}}}; color: {{{{ c.fgA }}}}; font: inherit; font-size: 14px; font-weight: 600; cursor: pointer">{{{{ c.name }}}}</button>'''
        fchip = lambda lab, hole, onc, extra="": f'<button type="button" class="nm-press" onClick="{{{{ {onc} }}}}" style="flex-shrink: 0; height: 32px; padding: 0 12px; border-radius: 8px; border: 1px solid {{{{ {hole}.bd }}}}; background: {{{{ {hole}.bg }}}}; color: {{{{ {hole}.fg }}}}; font: inherit; font-size: 14px; font-weight: 500; display: flex; align-items: center; gap: 6px; cursor: pointer">{extra}{lab}</button>'
    card = f'''<div class="nm-up" style="animation-delay: {{{{ item.delay }}}}ms; position: relative; background: #fff; border: 1px solid {C['LINE']}; border-radius: {p.r}px; padding: 8px; box-sizing: border-box; display: flex; flex-direction: column; gap: 4px">
<a href="{p.f('Product')}" style="color: {C['INK']}; display: flex; flex-direction: column; gap: 4px">
<div style="height: 148px; position: relative">{phd("item","148px",p.r-4,48)}<span style="position: absolute; top: 6px; left: 6px; background: {C['DEAL']}; color: #fff; font-size: 11px; font-weight: 700; padding: 3px 7px; border-radius: 6px">-{{{{ item.off }}}}%</span></div>
<div style="font-size: 13.5px; font-weight: 600; line-height: 1.3; margin-top: 4px; height: 35px; overflow: hidden">{{{{ item.name }}}}</div>
<div lang="mr" style="font-size: 11px; color: {C['FAINT']}; white-space: nowrap; overflow: hidden; text-overflow: ellipsis">{{{{ item.mr }}}}</div>
<div style="display: flex; align-items: baseline; gap: 6px; margin-top: 2px"><span style="font-size: 16px; font-weight: 800">{{{{ item.priceTxt }}}}</span><span style="font-size: 12px; color: {C['FAINT']}; text-decoration: line-through">{{{{ item.mrpTxt }}}}</span></div>
</a>
{add_btn(p)}
{heart_btn("item",32,14,14)}
</div>'''
    skel = "".join(f'<div style="background: #fff; border: 1px solid {C["LINE"]}; border-radius: {p.r}px; padding: 8px; display: flex; flex-direction: column; gap: 8px"><div class="nm-sk" style="height: 148px; border-radius: {p.r-4}px"></div><div class="nm-sk" style="height: 12px; border-radius: 6px; width: 85%"></div><div class="nm-sk" style="height: 12px; border-radius: 6px; width: 55%"></div><div class="nm-sk" style="height: 34px; border-radius: 10px"></div></div>' for _ in range(4))
    sheet_r = 14 if p.ios else 28
    sheet = f'''<sc-if value="{{{{ sheet }}}}" hint-placeholder-val="{{{{ false }}}}">
<button type="button" aria-label="Close" class="nm-fade" onClick="{{{{ closeSheet }}}}" style="position: absolute; inset: 0; border: none; background: rgba(17,18,23,0.42); z-index: 20; cursor: pointer"></button>
<div class="nm-sheet" role="dialog" aria-label="Sort by" style="position: absolute; left: 0; right: 0; bottom: 0; background: {'#fff' if p.ios else '#F7F9F3'}; border-radius: {sheet_r}px {sheet_r}px 0 0; padding: 10px {p.pad}px {p.barBottom}px; z-index: 21">
<div style="width: {36 if p.ios else 32}px; height: {5 if p.ios else 4}px; border-radius: 3px; background: #CFCFC8; margin: 0 auto 14px"></div>
<div style="font-size: {18 if p.ios else 22}px; font-weight: {800 if p.ios else 600}; margin-bottom: 6px">Sort by</div>
<sc-for list="{{{{ sorts }}}}" as="o" hint-placeholder-count="4"><button type="button" onClick="{{{{ o.pick }}}}" style="width: 100%; height: 52px; border: none; border-bottom: 1px solid {C['LINE']}; background: none; font: inherit; font-size: 16px; color: {C['INK']}; display: flex; align-items: center; justify-content: space-between; padding: 0; cursor: pointer; text-align: left">{{{{ o.label }}}}<span style="width: 22px; height: 22px; border-radius: 999px; border: 2px solid {{{{ o.ring }}}}; box-sizing: border-box; display: flex; align-items: center; justify-content: center"><sc-if value="{{{{ o.on }}}}" hint-placeholder-val="{{{{ false }}}}"><span class="nm-pop" style="width: 10px; height: 10px; border-radius: 999px; background: {C['BRAND']}"></span></sc-if></span></button></sc-for>
</div>
</sc-if>'''
    right = iconbtn("search","Search",p.f("Search"),size=40 if p.ios else 48) + iconbtn("bag","Bag",p.f("Bag"),size=40 if p.ios else 48,badge_hole="bag")
    head = header(p, "{{ catTitle }}", p.f("Home"), "Home", right=right, mr="{{ catMr }}", large=True)
    inner = f'''{head}
<div class="nm-scroll" style="display: flex; gap: 8px; overflow-x: auto; padding: 14px {pad}px 0"><sc-for list="{{{{ cats }}}}" as="c" hint-placeholder-count="5">{chip}</sc-for></div>
<div class="nm-scroll" style="display: flex; gap: 8px; overflow-x: auto; padding: 10px {pad}px 0">
{fchip("{{ sortLabel }}", "fSort", "openSheet", ic("sort",15))}
{fchip("30%+ off", "fDeal", "toggleDeal")}
{fchip("Under ₹500", "fCheap", "toggleCheap")}
</div>
<div style="padding: 12px {pad}px 0; font-size: 13px; color: {C['FAINT']}">{{{{ countTxt }}}}</div>
<sc-if value="{{{{ loading }}}}" hint-placeholder-val="{{{{ false }}}}"><div style="display: grid; grid-template-columns: repeat(2, minmax(0, 1fr)); gap: 10px; padding: 8px {pad}px 20px">{skel}</div></sc-if>
<sc-if value="{{{{ ready }}}}" hint-placeholder-val="{{{{ true }}}}"><div style="display: grid; grid-template-columns: repeat(2, minmax(0, 1fr)); gap: 10px; padding: 8px {pad}px 20px"><sc-for list="{{{{ list }}}}" as="item" hint-placeholder-count="4">{card}</sc-for></div></sc-if>
<sc-if value="{{{{ none }}}}" hint-placeholder-val="{{{{ false }}}}"><div class="nm-up" style="padding: 40px; text-align: center; color: {C['FAINT']}; font-size: 14px">No products match these filters.</div></sc-if>'''
    body = scroll(p, inner, 0).replace('bottom: 0px; overflow-y', f'bottom: 0px; padding-bottom: {p.tabH}px; box-sizing: border-box; overflow-y') + tabbar(p, "Shop") + sheet
    state = "{ cat: 'car', sort: 'pop', sheet: false, deal: false, cheap: false, loading: false, wish: {}, added: {}, bag: 3, bump: false }"
    methods = ITEM_JS
    vals = '''const CATS = [{id:'all',name:'All',t:'All products',mr:'सर्व उत्पादने'},{id:'car',name:'Car & Bike',t:'Car & Bike Care',mr:'कार आणि बाईक केअर'},{id:'kitchen',name:'Home & Kitchen',t:'Home & Kitchen',mr:'घर आणि स्वयंपाकघर'},{id:'clean',name:'Cleaning',t:'Cleaning & Laundry',mr:'स्वच्छता आणि कपडे धुणे'},{id:'bath',name:'Bathroom',t:'Bathroom',mr:'बाथरूम'},{id:'tools',name:'Tools',t:'Tools & Outdoor',mr:'टूल्स आणि आउटडोअर'},{id:'kids',name:'Kids',t:'Kids & School',mr:'मुले आणि शाळा'}];
const SORTS = [{id:'pop',label:'Popularity',short:'Sort'},{id:'low',label:'Price: low to high',short:'Price ↑'},{id:'high',label:'Price: high to low',short:'Price ↓'},{id:'disc',label:'Biggest discount',short:'Discount'}];
const cur = CATS.find(function(c){ return c.id === s.cat; });
let list = this.P.filter(function(x){ return s.cat === 'all' || x.cat === s.cat; });
if (s.deal) list = list.filter(function(x){ return (1 - x.price / x.mrp) >= 0.3; });
if (s.cheap) list = list.filter(function(x){ return x.price < 500; });
list = list.slice();
if (s.sort === 'low') list.sort(function(a, b){ return a.price - b.price; });
if (s.sort === 'high') list.sort(function(a, b){ return b.price - a.price; });
if (s.sort === 'disc') list.sort(function(a, b){ return (b.mrp - b.price) / b.mrp - (a.mrp - a.price) / a.mrp; });
const ios = this.isIOS;
const fc = function(on){ return ios ? { bd: on ? '#111217' : '#E5E5E0', bg: on ? '#111217' : '#fff', fg: on ? '#fff' : '#111217' } : { bd: on ? '#E9F3EB' : '#C9CCC4', bg: on ? '#E9F3EB' : 'transparent', fg: on ? '#1E4D25' : '#4C4F5C' }; };
const reload = function(patch){ self.setState(Object.assign({ loading: true }, patch)); self.later(function(){ self.setState({ loading: false }); }, 650); };
const sortCur = SORTS.find(function(o){ return o.id === s.sort; });
return Object.assign({ catTitle: cur.t, catMr: cur.mr,
cats: CATS.map(function(c){ const on = c.id === s.cat; return { name: c.name, bg: on ? '#111217' : '#EEEEEA', fg: on ? '#fff' : '#111217', bd: on ? '#E9F3EB' : '#C9CCC4', bgA: on ? '#E9F3EB' : 'transparent', fgA: on ? '#1E4D25' : '#4C4F5C', pick: function(){ if (!on) reload({ cat: c.id }); } }; }),
sortLabel: sortCur.short, fSort: fc(s.sort !== 'pop'), fDeal: fc(s.deal), fCheap: fc(s.cheap),
openSheet: function(){ self.setState({ sheet: true }); }, closeSheet: function(){ self.setState({ sheet: false }); }, sheet: s.sheet,
toggleDeal: function(){ reload({ deal: !s.deal }); }, toggleCheap: function(){ reload({ cheap: !s.cheap }); },
sorts: SORTS.map(function(o){ const on = o.id === s.sort; return { label: o.label, on: on, ring: on ? '#317239' : '#B8B8B2', pick: function(){ self.setState({ sheet: false }); reload({ sort: o.id }); } }; }),
countTxt: list.length + (list.length === 1 ? ' product' : ' products'), loading: s.loading, ready: !s.loading && list.length > 0, none: !s.loading && list.length === 0,
list: list.map(function(x, i){ return self.mk(x, i); }) }, { ''' + bagbadge_js() + ''' });'''
    return page("Shop", body, state, methods, vals)

def product(p):
    pad = p.pad
    circ = "rgba(255,255,255,0.94)"
    gal = "".join(f'<div style="width: 100%; flex-shrink: 0; height: 380px; background: {bg}; display: flex; align-items: center; justify-content: center; color: {C["BRAND"]}">{ic(icn,110,sw=0.9,label=lab)}</div>' for bg, icn, lab in [("#fff","car","Product photo 1"),(C['MUTED'],"tools","Product photo 2: attachments"),(C['BSOFT'],"car","Product photo 3")])
    if p.ios:
        tabs = f'''<div role="tablist" style="margin: 20px {pad}px 0; background: #EEEEEA; border-radius: 10px; padding: 2px; display: flex; position: relative">
<span style="position: absolute; top: 2px; bottom: 2px; left: 2px; width: calc((100% - 4px) / 3); border-radius: 8px; background: #fff; box-shadow: 0 1px 3px rgba(0,0,0,0.12); transform: translateX({{{{ tabX }}}}%); transition: transform .3s cubic-bezier(.3,1.2,.5,1)"></span>
<sc-for list="{{{{ tabs }}}}" as="t" hint-placeholder-count="3"><button type="button" role="tab" aria-selected="{{{{ t.sel }}}}" onClick="{{{{ t.pick }}}}" style="flex: 1; height: 32px; border: none; background: transparent; font: inherit; font-size: 13px; font-weight: 600; color: {C['INK']}; position: relative; cursor: pointer">{{{{ t.label }}}}</button></sc-for></div>'''
    else:
        tabs = f'''<div role="tablist" style="margin: 20px 0 0; display: flex; border-bottom: 1px solid {C['LINE']}; position: relative">
<span style="position: absolute; bottom: 0; left: 0; width: 33.333%; height: 3px; display: flex; justify-content: center; transform: translateX({{{{ tabX }}}}%); transition: transform .3s ease"><span style="width: 60%; height: 3px; border-radius: 3px 3px 0 0; background: {C['BRAND']}"></span></span>
<sc-for list="{{{{ tabs }}}}" as="t" hint-placeholder-count="3"><button type="button" role="tab" aria-selected="{{{{ t.sel }}}}" onClick="{{{{ t.pick }}}}" style="flex: 1; height: 48px; border: none; background: transparent; font: inherit; font-size: 14px; font-weight: 600; color: {{{{ t.color }}}}; cursor: pointer">{{{{ t.label }}}}</button></sc-for></div>'''
    sim = f'''<sc-for list="{{{{ similar }}}}" as="item" hint-placeholder-count="4"><a href="{p.f('Product')}" class="nm-press" style="width: 132px; flex-shrink: 0; color: {C['INK']}; display: flex; flex-direction: column; gap: 4px"><div style="height: 120px">{phd("item","120px",p.r,40)}</div><div style="font-size: 12.5px; font-weight: 600; line-height: 1.3; height: 32px; overflow: hidden">{{{{ item.name }}}}</div><div style="display: flex; gap: 5px; align-items: baseline"><span style="font-size: 14px; font-weight: 800">{{{{ item.priceTxt }}}}</span><span style="font-size: 11.5px; font-weight: 700; color: {C['GREEN']}">{{{{ item.off }}}}% off</span></div></a></sc-for>'''
    stepper_r = 12 if p.ios else 999
    inner = f'''<div style="position: relative; overflow: hidden">
<div style="display: flex; transform: translateX(-{{{{ imgX }}}}%); transition: transform .5s cubic-bezier(.6,0,.2,1)">{gal}</div>
<button type="button" aria-label="Previous photo" onClick="{{{{ prev }}}}" style="position: absolute; left: 0; top: 80px; bottom: 60px; width: 30%; border: none; background: transparent; cursor: pointer"></button>
<button type="button" aria-label="Next photo" onClick="{{{{ next }}}}" style="position: absolute; right: 0; top: 80px; bottom: 60px; width: 30%; border: none; background: transparent; cursor: pointer"></button>
<span style="position: absolute; bottom: 14px; right: 14px; background: rgba(17,18,23,0.7); color: #fff; font-size: 12px; font-weight: 600; padding: 4px 10px; border-radius: 999px">{{{{ imgN }}}} / 3</span>
<div style="position: absolute; bottom: 18px; left: 0; right: 0; display: flex; justify-content: center; gap: 6px; pointer-events: none"><sc-for list="{{{{ dots }}}}" as="d" hint-placeholder-count="3"><span style="width: {{{{ d.w }}}}px; height: 6px; border-radius: 3px; background: {{{{ d.bg }}}}; transition: all .35s ease"></span></sc-for></div>
</div>
<div style="padding: 16px {pad}px 0">
<div class="nm-up" style="display: flex; align-items: center; gap: 8px"><span style="font-size: 12px; font-weight: 700; color: {C['BRAND']}; letter-spacing: 0.3px">CAR &amp; BIKE CARE</span><span style="font-size: 11px; font-weight: 700; color: {C['DEAL']}; background: #FDECEA; padding: 3px 8px; border-radius: 6px; display: flex; align-items: center; gap: 4px">{ic("fire",12,C['DEAL'],2)}Trending</span></div>
<h1 class="nm-up" style="animation-delay: .05s; margin: 6px 0 0; font-size: 26px; font-weight: 800; letter-spacing: -0.4px; line-height: 1.15">Vacuum Cleaner</h1>
<div class="nm-up" lang="mr" style="animation-delay: .08s; font-size: 15px; color: {C['SOFT']}">व्हॅक्यूम क्लीनर</div>
<div class="nm-up" style="animation-delay: .12s; display: flex; align-items: baseline; gap: 8px; margin-top: 10px"><span style="font-size: 28px; font-weight: 800">₹1,000</span><span style="font-size: 15px; color: {C['FAINT']}; text-decoration: line-through">₹2,100</span><span style="font-size: 15px; font-weight: 700; color: {C['GREEN']}">52% off</span></div>
<div style="font-size: 12.5px; color: {C['FAINT']}; margin-top: 2px">Inclusive of all taxes · You save ₹1,100</div>
<div style="margin-top: 16px; background: #fff; border: 1px solid {C['LINE']}; border-radius: {p.r}px; padding: 12px">
<div style="display: flex; align-items: center; gap: 8px; font-size: 14px; font-weight: 700; margin-bottom: 8px">{ic("truck",18,C['BRAND'])}Check delivery</div>
<label style="height: 46px; border: 1.5px solid {{{{ pinBorder }}}}; border-radius: {10 if p.ios else 8}px; display: flex; align-items: center; gap: 8px; padding: 0 4px 0 12px; color: {C['FAINT']}; transition: border-color .2s ease">{ic("pin",18)}<input inputmode="numeric" maxlength="6" placeholder="Enter pincode" aria-label="Delivery pincode" value="{{{{ pin }}}}" onChange="{{{{ onPin }}}}" style="border: none; outline: none; background: transparent; font: inherit; font-size: 16px; letter-spacing: 1px; color: {C['INK']}; flex: 1; min-width: 0"><button type="button" class="nm-press" onClick="{{{{ check }}}}" style="height: 36px; padding: 0 14px; border: none; border-radius: {8 if p.ios else 18}px; background: {C['BSOFT']}; color: {C['BRAND']}; font: inherit; font-size: 14px; font-weight: 700; cursor: pointer">Check</button></label>
<sc-if value="{{{{ pinOk }}}}" hint-placeholder-val="{{{{ false }}}}"><div class="nm-up" style="display: flex; gap: 8px; align-items: flex-start; margin-top: 10px; font-size: 13px; color: {C['GREEN']}; font-weight: 600; line-height: 1.4">{ic("check",18,C['GREEN'],2.4)}<span>We deliver to {{{{ pin }}}}. Free delivery on orders above ₹499.</span></div></sc-if>
<sc-if value="{{{{ pinBad }}}}" hint-placeholder-val="{{{{ false }}}}"><div class="nm-up" style="margin-top: 10px; font-size: 13px; color: {C['DEAL']}; font-weight: 600; line-height: 1.4">{{{{ pinMsg }}}}</div></sc-if>
</div>
<div style="display: flex; gap: 8px; margin-top: 12px">{"".join(f'<div style="flex: 1; background: #fff; border: 1px solid {C["LINE"]}; border-radius: {p.r}px; padding: 10px 6px; display: flex; flex-direction: column; align-items: center; gap: 6px; text-align: center; font-size: 11px; font-weight: 600; color: {C["SOFT"]}; line-height: 1.25"><span style="color: {C["BRAND"]}">{ic(a,22)}</span>{b}</div>' for a, b in [("truck","Free delivery above ₹499"),("ret","5-day return / exchange"),("shield","Secure checkout")])}</div>
</div>
{tabs}
<div style="padding: 14px {pad}px 0; min-height: 110px">
<sc-if value="{{{{ tDesc }}}}" hint-placeholder-val="{{{{ true }}}}"><div class="nm-fade" style="font-size: 14px; line-height: 1.6; color: {C['SOFT']}">4-in-1 car vacuum cleaner with 6 attachments and a blower — for home, office, car, keyboard, travel and sofa.<div lang="mr" style="margin-top: 8px">कार व्हॅक्यूम क्लीनर ४ इन १, ६ अटॅचमेंट आणि ब्लोअरसह | घर/ऑफिस/कार/कीबोर्ड/प्रवास/सोफा साठी उपयुक्त.</div></div></sc-if>
<sc-if value="{{{{ tSpec }}}}" hint-placeholder-val="{{{{ false }}}}"><div class="nm-fade" style="font-size: 14px">{"".join(f'<div style="display: flex; padding: 10px 0; border-bottom: 1px solid {C["LINE"]}"><span style="width: 120px; color: {C["FAINT"]}">{a}</span><span style="flex: 1; font-weight: 600">{b}</span></div>' for a, b in [("SKU","NM-TG-005"),("Category","Car &amp; Bike Care"),("Type","4-in-1 vacuum + blower"),("Attachments","6")])}</div></sc-if>
<sc-if value="{{{{ tRev }}}}" hint-placeholder-val="{{{{ false }}}}"><div class="nm-fade" style="display: flex; flex-direction: column; align-items: center; gap: 8px; padding: 10px 0; text-align: center"><div style="display: flex; gap: 4px; color: {C['GOLD']}">{ic("star",22,C['GOLD'])*5}</div><div style="font-size: 15px; font-weight: 700">No reviews yet</div><div style="font-size: 13px; color: {C['FAINT']}">Bought this? Be the first to review it.</div><button type="button" class="nm-press" style="height: 40px; padding: 0 18px; border-radius: {10 if p.ios else 20}px; border: 1px solid {C['LINE']}; background: #fff; font: inherit; font-size: 14px; font-weight: 700; color: {C['BRAND']}; cursor: pointer">Write a review</button></div></sc-if>
</div>
<div style="padding: 18px {pad}px 10px; font-size: 18px; font-weight: 800">You may also like</div>
<div class="nm-scroll" style="display: flex; gap: 12px; overflow-x: auto; padding: 0 {pad}px 24px">{sim}</div>'''
    topbar = f'''<div style="position: absolute; top: {p.top}px; left: 12px; right: 12px; display: flex; justify-content: space-between; z-index: 6"><div>{iconbtn("chevL" if p.ios else "arrowL","Back",p.f("Shop"),bg=circ)}</div><div style="display: flex; gap: 8px">{iconbtn("shareI" if p.ios else "shareA","Share",bg=circ)}
<button type="button" class="nm-press" aria-label="Wishlist" onClick="{{{{ wishT }}}}" style="width: 40px; height: 40px; border-radius: 999px; border: none; background: {circ}; display: flex; align-items: center; justify-content: center; padding: 0; color: {C['INK']}; cursor: pointer"><sc-if value="{{{{ wished }}}}" hint-placeholder-val="{{{{ false }}}}">{ic("heart",22,C['DEAL'],fill=C['DEAL'],cls="nm-pop")}</sc-if><sc-if value="{{{{ notWished }}}}" hint-placeholder-val="{{{{ true }}}}">{ic("heart",22)}</sc-if></button>
{iconbtn("bag","Bag",p.f("Bag"),bg=circ,badge_hole="bag")}</div></div>'''
    step = f'''<div style="display: flex; align-items: center; border: 1px solid {C['LINE']}; border-radius: {stepper_r}px; background: #fff; height: {50 if p.ios else 56}px; flex-shrink: 0"><button type="button" aria-label="Decrease quantity" onClick="{{{{ dec }}}}" style="width: 40px; height: 100%; border: none; background: none; color: {C['INK']}; display: flex; align-items: center; justify-content: center; padding: 0; cursor: pointer">{ic("minus",18,sw=2.2)}</button><span key="{{{{ qty }}}}" style="min-width: 20px; text-align: center; font-size: 16px; font-weight: 800; animation: nmTick .25s ease">{{{{ qty }}}}</span><button type="button" aria-label="Increase quantity" onClick="{{{{ inc }}}}" style="width: 40px; height: 100%; border: none; background: none; color: {C['BRAND']}; display: flex; align-items: center; justify-content: center; padding: 0; cursor: pointer">{ic("plus",18,sw=2.2)}</button></div>'''
    cta = f'''<sc-if value="{{{{ notAdded }}}}" hint-placeholder-val="{{{{ true }}}}">{btn_primary(p, ic("bag",20,"#fff",2) + "Add to bag", onclick="add")}</sc-if>
<sc-if value="{{{{ added }}}}" hint-placeholder-val="{{{{ false }}}}"><a href="{p.f('Bag')}" class="nm-press nm-fade" style="flex: 1; height: {50 if p.ios else 56}px; border-radius: {14 if p.ios else 28}px; background: {C['INK']}; color: #fff; font-size: 16px; font-weight: 700; display: flex; align-items: center; justify-content: center; gap: 8px">{ic("check",18,"#fff",2.6)}Added · Go to bag</a></sc-if>'''
    fly = f'<sc-if value="{{{{ flying }}}}" hint-placeholder-val="{{{{ false }}}}"><span class="nm-fly" style="position: absolute; left: 236px; bottom: 60px; width: 34px; height: 34px; border-radius: 999px; background: {C["BRAND"]}; color: #fff; display: flex; align-items: center; justify-content: center; z-index: 30; box-shadow: 0 4px 12px rgba(49,114,57,.4)">{ic("bag",18,"#fff",2)}</span></sc-if>'
    body = scroll(p, inner, 96 if p.ios else 96) + topbar + bottom_bar(p, step + cta) + fly
    state = "{ img: 0, wished: false, qty: 1, tab: 0, pin: '', pinState: '', added: false, flying: false, bag: 3, bump: false }"
    vals = '''const TABS = ['Description', 'Specifications', 'Reviews (0)'];
const sim = ['washer', 'pump', 'holder', 'org', 'torch'].map(function(id, i){ return self.item(self.prod(id), { delay: i * 50 }); });
return Object.assign({ imgX: s.img * 100, imgN: s.img + 1,
prev: function(){ self.setState({ img: (s.img + 2) % 3 }); }, next: function(){ self.setState({ img: (s.img + 1) % 3 }); },
dots: [0,1,2].map(function(i){ return { w: i === s.img ? 18 : 6, bg: i === s.img ? '#317239' : '#CFCFC8' }; }),
wished: s.wished, notWished: !s.wished, wishT: function(){ self.setState({ wished: !s.wished }); },
pin: s.pin, onPin: function(e){ self.setState({ pin: e.target.value.replace(/\\D/g, '').slice(0, 6), pinState: '' }); },
check: function(){ const v = s.pin; let st = 'bad'; if (/^\\d{6}$/.test(v) && /^4[0-4]/.test(v)) st = 'ok'; self.setState({ pinState: st }); },
pinOk: s.pinState === 'ok', pinBad: s.pinState === 'bad', pinBorder: s.pinState === 'ok' ? '#15803D' : (s.pinState === 'bad' ? '#B92418' : '#E5E5E0'),
pinMsg: s.pin.length !== 6 ? 'Enter a valid 6-digit pincode.' : 'Sorry, we currently deliver only within Maharashtra.',
tabX: s.tab * 100, tabs: TABS.map(function(l, i){ return { label: l, sel: i === s.tab ? 'true' : 'false', color: i === s.tab ? '#317239' : '#4C4F5C', pick: function(){ self.setState({ tab: i }); } }; }),
tDesc: s.tab === 0, tSpec: s.tab === 1, tRev: s.tab === 2,
qty: s.qty, dec: function(){ self.setState({ qty: Math.max(1, s.qty - 1) }); }, inc: function(){ self.setState({ qty: Math.min(10, s.qty + 1) }); },
added: s.added, notAdded: !s.added, flying: s.flying,
add: function(){ self.setState({ flying: true }); self.later(function(){ self.setState(function(st){ return { flying: false, added: true, bag: st.bag + st.qty, bump: !st.bump }; }); }, 720); },
similar: sim }, { ''' + bagbadge_js() + ''' });'''
    return page("Product · Vacuum Cleaner", body, state, "", vals)

def bag(p):
    pad = p.pad
    stepr = 10 if p.ios else 999
    row = f'''<div class="nm-up" style="animation-delay: {{{{ item.delay }}}}ms; display: flex; gap: 12px; padding: 14px 0; border-bottom: 1px solid {C['LINE']}">
<div style="width: 84px; height: 84px; flex-shrink: 0">{phd("item","84px",p.r-2,34)}</div>
<div style="flex: 1; min-width: 0; display: flex; flex-direction: column; gap: 2px">
<div style="font-size: 14px; font-weight: 600; line-height: 1.3">{{{{ item.name }}}}</div>
<div lang="mr" style="font-size: 11px; color: {C['FAINT']}">{{{{ item.mr }}}}</div>
<div style="display: flex; align-items: baseline; gap: 6px; margin-top: 2px"><span style="font-size: 15px; font-weight: 800">{{{{ item.lineTxt }}}}</span><span style="font-size: 12px; color: {C['FAINT']}; text-decoration: line-through">{{{{ item.lineMrpTxt }}}}</span></div>
<div style="display: flex; align-items: center; justify-content: space-between; margin-top: 6px">
<div style="display: flex; align-items: center; border: 1px solid {C['LINE']}; border-radius: {stepr}px; background: #fff; height: 34px">
<button type="button" aria-label="Decrease quantity" onClick="{{{{ item.dec }}}}" style="width: 36px; height: 34px; border: none; background: none; color: {C['INK']}; display: flex; align-items: center; justify-content: center; padding: 0; cursor: pointer">{ic("minus",16,sw=2.2)}</button>
<span style="min-width: 22px; text-align: center; font-size: 14px; font-weight: 700">{{{{ item.q }}}}</span>
<button type="button" aria-label="Increase quantity" onClick="{{{{ item.inc }}}}" style="width: 36px; height: 34px; border: none; background: none; color: {C['BRAND']}; display: flex; align-items: center; justify-content: center; padding: 0; cursor: pointer">{ic("plus",16,sw=2.2)}</button>
</div>
<div style="display: flex; align-items: center">
<button type="button" onClick="{{{{ item.save }}}}" style="height: 40px; border: none; background: none; color: {C['BRAND']}; font: inherit; font-size: 13px; font-weight: 600; padding: 0 8px; cursor: pointer">Save for later</button>
<button type="button" aria-label="Remove {{{{ item.name }}}}" onClick="{{{{ item.remove }}}}" style="width: 40px; height: 40px; border: none; background: none; color: {C['FAINT']}; display: flex; align-items: center; justify-content: center; padding: 0; cursor: pointer">{ic("trash",18)}</button>
</div></div></div></div>'''
    full = f'''<sc-if value="{{{{ has }}}}" hint-placeholder-val="{{{{ true }}}}">
<div style="margin: 10px {pad}px 0; background: {{{{ fdBg }}}}; border-radius: {p.r}px; padding: 12px 14px; display: flex; flex-direction: column; gap: 8px; transition: background-color .3s ease">
<div style="display: flex; align-items: center; gap: 8px; font-size: 13.5px; font-weight: 600; color: {C['DARKG']}">{ic("truck",20,C['BRAND'])}{{{{ fdText }}}}</div>
<div style="height: 6px; border-radius: 3px; background: #DCE7DD; overflow: hidden"><div style="width: {{{{ fdPct }}}}%; height: 6px; border-radius: 3px; background: {C['BRAND']}; transition: width .6s cubic-bezier(.3,.9,.3,1)"></div></div>
</div>
<div style="padding: 0 {pad}px"><sc-for list="{{{{ items }}}}" as="item" hint-placeholder-count="3">{row}</sc-for></div>
<button type="button" class="nm-press" style="margin: 16px {pad}px 0; width: calc(100% - {pad*2}px); height: 52px; border: 1px dashed #B9C9BB; border-radius: {p.r}px; background: #fff; display: flex; align-items: center; gap: 10px; padding: 0 14px; font: inherit; font-size: 14px; font-weight: 600; color: {C['INK']}; cursor: pointer">{ic("tag",20,C['BRAND'])}<span style="flex: 1; text-align: left">Apply coupon</span><span style="color: {C['BRAND']}">View offers</span>{ic("chevR",16,C['FAINT'])}</button>
<div style="margin: 16px {pad}px 24px; background: #fff; border: 1px solid {C['LINE']}; border-radius: {p.r}px; padding: 14px 16px; display: flex; flex-direction: column; gap: 8px; font-size: 14px">
<div style="font-size: 15px; font-weight: 700">Price details</div>
<div style="display: flex; justify-content: space-between; color: {C['SOFT']}"><span>MRP ({{{{ countTxt }}}})</span><span>{{{{ mrpTxt }}}}</span></div>
<div style="display: flex; justify-content: space-between; color: {C['SOFT']}"><span>Discount</span><span style="color: {C['GREEN']}">−{{{{ saveTxt }}}}</span></div>
<div style="display: flex; justify-content: space-between; color: {C['SOFT']}"><span>Delivery</span><span style="color: {{{{ delColor }}}}; font-weight: 600">{{{{ delTxt }}}}</span></div>
<div style="height: 1px; background: {C['LINE']}"></div>
<div style="display: flex; justify-content: space-between; font-weight: 800; font-size: 16px"><span>Total</span><span>{{{{ totalTxt }}}}</span></div>
</div>
</sc-if>
<sc-if value="{{{{ empty }}}}" hint-placeholder-val="{{{{ false }}}}"><div class="nm-up" style="padding: 90px 40px 0; display: flex; flex-direction: column; align-items: center; gap: 12px; text-align: center">
<span class="nm-scalein" style="width: 110px; height: 110px; border-radius: 999px; background: {C['BSOFT']}; color: {C['BRAND']}; display: flex; align-items: center; justify-content: center">{ic("bag",52,sw=1.4)}</span>
<div style="font-size: 22px; font-weight: 800">Your bag is empty</div><div lang="mr" style="font-size: 13px; color: {C['FAINT']}">तुमची बॅग रिकामी आहे</div>
<div style="font-size: 14px; color: {C['FAINT']}; line-height: 1.5">Trending gadgets and home essentials are waiting.</div>
<a href="{p.f('Shop')}" class="nm-press" style="margin-top: 8px; height: 48px; padding: 0 28px; border-radius: {14 if p.ios else 24}px; background: {C['BRAND']}; color: #fff; font-size: 16px; font-weight: 700; display: flex; align-items: center">Start shopping</a>
</div></sc-if>'''
    inner = header(p, "{{ title }}", p.f("Product"), "Back") + full
    bar = f'<sc-if value="{{{{ has }}}}" hint-placeholder-val="{{{{ true }}}}">' + bottom_bar(p, f'<div><div style="font-size: 20px; font-weight: 800">{{{{ totalTxt }}}}</div><div style="font-size: 12px; font-weight: 600; color: {C["GREEN"]}">You save {{{{ saveTxt }}}}</div></div>' + btn_primary(p, "Checkout " + ic("arrowR",18,"#fff",2.4), href=p.f("Checkout"))) + '</sc-if>'
    toast = f'<sc-if value="{{{{ toast }}}}" hint-placeholder-val="{{{{ false }}}}"><div key="{{{{ toastKey }}}}" class="nm-toast" role="status" style="position: absolute; left: 50%; bottom: 120px; background: {C["INK"]}; color: #fff; font-size: 14px; font-weight: 600; padding: 12px 16px; border-radius: {12 if p.ios else 8}px; display: flex; align-items: center; gap: 8px; white-space: nowrap; z-index: 30">{ic("heart",16,"#fff",fill="#fff")}{{{{ toast }}}}</div></sc-if>'
    body = scroll(p, inner, 100) + bar + toast
    state = "{ items: [{ id: 'torch', q: 1 }, { id: 'bottle', q: 1 }, { id: 'clip', q: 1 }], toast: '', toastKey: 0 }"
    vals = '''const its = s.items.map(function(it){ return Object.assign({}, self.prod(it.id), { q: it.q }); });
const sub = its.reduce(function(a, x){ return a + x.price * x.q; }, 0); const mrp = its.reduce(function(a, x){ return a + x.mrp * x.q; }, 0);
const n = its.reduce(function(a, x){ return a + x.q; }, 0); const free = sub >= 499;
const upd = function(id, d){ self.setState(function(st){ return { items: st.items.map(function(it){ return it.id === id ? { id: it.id, q: Math.max(1, Math.min(10, it.q + d)) } : it; }) }; }); };
const drop = function(id, msg){ self.setState(function(st){ return { items: st.items.filter(function(it){ return it.id !== id; }), toast: msg, toastKey: st.toastKey + 1 }; }); self.later(function(){ self.setState({ toast: '' }); }, 2300); };
return { title: n ? 'Bag (' + n + ')' : 'Bag', has: its.length > 0, empty: its.length === 0, countTxt: n + (n === 1 ? ' item' : ' items'),
fdText: free ? 'You’ve unlocked free delivery' : 'Add ' + this.fmt(499 - sub) + ' more for free delivery', fdPct: Math.min(100, Math.round(sub / 499 * 100)), fdBg: free ? '#E9F3EB' : '#FFF6E8',
mrpTxt: this.fmt(mrp), saveTxt: this.fmt(mrp - sub), totalTxt: this.fmt(sub), delTxt: free ? 'FREE' : 'Calculated at checkout', delColor: free ? '#15803D' : '#4C4F5C',
toast: s.toast, toastKey: s.toastKey,
items: its.map(function(x, i){ return self.item(x, { delay: i * 70, q: x.q, lineTxt: self.fmt(x.price * x.q), lineMrpTxt: self.fmt(x.mrp * x.q),
dec: function(){ upd(x.id, -1); }, inc: function(){ upd(x.id, 1); }, remove: function(){ drop(x.id, 'Removed from bag'); }, save: function(){ drop(x.id, 'Saved to your wishlist'); } }); }) };'''
    return page("Bag", body, state, "", vals)

def checkout(p):
    pad = p.pad
    def field(label, ph_, mode="text", w="100%"):
        if p.ios:
            return f'<label style="display: flex; flex-direction: column; gap: 4px; width: {w}; min-width: 0"><span style="font-size: 12px; font-weight: 600; color: {C["SOFT"]}">{label}</span><input inputmode="{mode}" placeholder="{ph_}" style="height: 44px; border: 1px solid {C["LINE"]}; border-radius: 10px; background: #fff; padding: 0 12px; font: inherit; font-size: 16px; color: {C["INK"]}; outline: none; box-sizing: border-box; width: 100%"></label>'
        return f'<label style="position: relative; display: block; width: {w}; min-width: 0"><span style="position: absolute; top: -8px; left: 12px; background: {C["BG"]}; padding: 0 4px; font-size: 12px; color: {C["SOFT"]}">{label}</span><input inputmode="{mode}" placeholder="{ph_}" style="height: 52px; border: 1px solid #8A8D84; border-radius: 4px; background: transparent; padding: 0 16px; font: inherit; font-size: 16px; color: {C["INK"]}; outline: none; box-sizing: border-box; width: 100%"></label>'
    if p.ios:
        mark = f'<span style="width: 22px; height: 22px; border-radius: 999px; border: 1.5px solid {{{{ o.ring }}}}; background: {{{{ o.fill }}}}; box-sizing: border-box; display: flex; align-items: center; justify-content: center; transition: all .2s ease"><sc-if value="{{{{ o.on }}}}" hint-placeholder-val="{{{{ false }}}}"><span class="nm-pop" style="display: flex">{ic("check",13,"#fff",3)}</span></sc-if></span>'
    else:
        mark = f'<span style="width: 20px; height: 20px; border-radius: 999px; border: 2px solid {{{{ o.ring }}}}; box-sizing: border-box; display: flex; align-items: center; justify-content: center"><sc-if value="{{{{ o.on }}}}" hint-placeholder-val="{{{{ false }}}}"><span class="nm-pop" style="width: 10px; height: 10px; border-radius: 999px; background: {C["BRAND"]}"></span></sc-if></span>'
    payicons = "".join(f'<sc-if value="{{{{ o.ic_{k} }}}}" hint-placeholder-val="{{{{ false }}}}">{ic(k,20)}</sc-if>' for k in ("upi","card","bank"))
    pay = f'''<sc-for list="{{{{ pays }}}}" as="o" hint-placeholder-count="3"><button type="button" class="nm-press" role="radio" aria-checked="{{{{ o.sel }}}}" onClick="{{{{ o.pick }}}}" style="width: 100%; display: flex; align-items: center; gap: 12px; padding: 12px 14px; border-radius: {p.r}px; border: 1.5px solid {{{{ o.bd }}}}; background: {{{{ o.bg }}}}; font: inherit; color: {C['INK']}; cursor: pointer; text-align: left; transition: all .2s ease">
<span style="width: 36px; height: 36px; border-radius: 10px; background: {C['MUTED']}; color: {C['BRAND']}; display: flex; align-items: center; justify-content: center">{payicons}</span>
<span style="flex: 1"><span style="display: block; font-size: 14.5px; font-weight: 700">{{{{ o.t }}}}</span><span style="display: block; font-size: 12px; color: {C['FAINT']}">{{{{ o.d }}}}</span></span>{mark}</button></sc-for>'''
    stepdot = lambda n, t, on: f'<div style="display: flex; align-items: center; gap: 6px; font-size: 13px; font-weight: {700 if on else 500}; color: {C["INK"] if on else C["FAINT"]}"><span style="width: 22px; height: 22px; border-radius: 999px; background: {C["BRAND"] if on else C["MUTED"]}; color: {"#fff" if on else C["FAINT"]}; font-size: 12px; font-weight: 700; display: flex; align-items: center; justify-content: center">{n}</span>{t}</div>'
    gap = 12 if p.ios else 18
    summary = f'''<div style="margin: 20px {pad}px 24px; background: #fff; border: 1px solid {C['LINE']}; border-radius: {p.r}px; overflow: hidden">
<button type="button" onClick="{{{{ toggleSum }}}}" aria-expanded="{{{{ sumOpen }}}}" style="width: 100%; height: 52px; border: none; background: none; font: inherit; display: flex; align-items: center; gap: 10px; padding: 0 14px; cursor: pointer; color: {C['INK']}">{ic("box",20,C['BRAND'])}<span style="flex: 1; text-align: left; font-size: 14.5px; font-weight: 700">Order summary · 3 items</span><span style="font-weight: 800">₹750</span><span style="display: flex; transform: rotate({{{{ chevRot }}}}deg); transition: transform .3s ease">{ic("chevD",18)}</span></button>
<sc-if value="{{{{ isOpen }}}}" hint-placeholder-val="{{{{ false }}}}"><div class="nm-up" style="padding: 0 14px 12px; font-size: 13.5px; color: {C['SOFT']}; display: flex; flex-direction: column; gap: 8px">
{"".join(f'<div style="display: flex; justify-content: space-between"><span>{a}</span><span style="font-weight: 600; color: {C["INK"]}">{b}</span></div>' for a, b in [("LM 7703 Torch × 1","₹450"),("Steel Bottle × 1","₹200"),("Toothbrush Cover Clip Pack Of 10 × 1","₹100"),("Delivery","FREE")])}
</div></sc-if></div>'''
    inner = header(p, "Checkout", p.f("Bag"), "Bag") + f'''
<div style="display: flex; align-items: center; gap: 10px; padding: 12px {pad}px 0">{stepdot(1,"Address",True)}<span style="flex: 1; height: 2px; background: {C['BRAND']}; border-radius: 1px"></span>{stepdot(2,"Payment",True)}<span style="flex: 1; height: 2px; background: {C['LINE']}"></span>{stepdot(3,"Done",False)}</div>
<div class="nm-up" style="padding: 20px {pad}px 0; display: flex; flex-direction: column; gap: {gap}px">
<div style="display: flex; align-items: baseline; justify-content: space-between"><div style="font-size: 17px; font-weight: 800">Delivery address</div><span style="font-size: 12px; color: {C['FAINT']}; display: flex; align-items: center; gap: 4px">{ic("pin",13)}Maharashtra only</span></div>
<div style="display: flex; gap: 10px">{field("Full name","Your name")}{field("Mobile","10-digit number","tel")}</div>
<div style="display: flex; gap: 10px">{field("Pincode","6 digits","numeric")}{field("City / Town","City")}</div>
{field("Flat, building, area","House no., street, landmark")}
<div style="display: flex; align-items: center; justify-content: space-between; font-size: 14px; font-weight: 600">Save as my default address{switch(p, "saveSw")}</div>
</div>
<div class="nm-up" style="animation-delay: .1s; padding: 22px {pad}px 0; display: flex; flex-direction: column; gap: 10px">
<div style="font-size: 17px; font-weight: 800">Payment method</div>
{pay}
<div style="display: flex; align-items: center; gap: 6px; font-size: 12px; color: {C['FAINT']}">{ic("lock",14)}Payments are encrypted and processed securely.</div>
</div>
{summary}'''
    body = scroll(p, inner, 100) + bottom_bar(p, f'<div><div style="font-size: 12px; color: {C["FAINT"]}">Total · 3 items</div><div style="font-size: 20px; font-weight: 800">₹750</div></div>' + btn_primary(p, ic("lock",18,"#fff",2) + "{{ payLabel }}", href=p.f("Success")))
    state = "{ pay: 'upi', save: true, open: false }"
    methods = SWITCH_JS
    vals = '''const PAYS = [{id:'upi', t:'UPI', d:'Pay with any UPI app'}, {id:'card', t:'Credit / Debit card', d:'Visa, Mastercard, RuPay'}, {id:'bank', t:'Net banking', d:'All major banks'}];
return { pays: PAYS.map(function(o){ const on = s.pay === o.id; return { t: o.t, d: o.d, on: on, sel: on ? 'true' : 'false', ic_upi: o.id === 'upi', ic_card: o.id === 'card', ic_bank: o.id === 'bank',
bd: on ? '#317239' : '#E5E5E0', bg: on ? '#F6FAF6' : '#fff', ring: on ? '#317239' : '#B8B8B2', fill: on ? '#317239' : 'transparent', pick: function(){ self.setState({ pay: o.id }); } }; }),
payLabel: s.pay === 'upi' ? 'Pay ₹750 with UPI' : 'Pay ₹750',
saveSw: this.sw(s.save, 'Save as default address', function(){ self.setState({ save: !s.save }); }),
toggleSum: function(){ self.setState({ open: !s.open }); }, isOpen: s.open, sumOpen: s.open ? 'true' : 'false', chevRot: s.open ? 180 : 0 };'''
    return page("Checkout", body, state, methods, vals)

def success(p):
    random.seed(7 if p.ios else 11)
    cols = [C['BRAND'], C['GOLD'], C['DEAL'], "#7FB685", C['MAROON']]
    conf = "".join(f'<span style="position: absolute; top: 0; left: {random.randint(5,380)}px; width: {random.choice([6,8,10])}px; height: {random.choice([10,14,6])}px; background: {random.choice(cols)}; border-radius: {random.choice([2,999])}px; animation: nmConf {random.uniform(2.2,3.6):.2f}s {random.uniform(0,0.9):.2f}s cubic-bezier(.3,.6,.5,1) both"></span>' for _ in range(34))
    inner = f'''<div aria-hidden="true" style="position: absolute; inset: 0; overflow: hidden; pointer-events: none">{conf}</div>
<div style="position: absolute; inset: 0; padding: 130px {p.pad}px 0; display: flex; flex-direction: column; align-items: center; text-align: center">
<svg role="img" aria-label="Order placed" width="120" height="120" viewBox="0 0 120 120" class="nm-scalein"><circle cx="60" cy="60" r="56" fill="{C['BSOFT']}"/><circle cx="60" cy="60" r="44" fill="none" stroke="{C['BRAND']}" stroke-width="6" stroke-dasharray="277" stroke-dashoffset="277" style="animation: nmDraw .7s .2s ease forwards" transform="rotate(-90 60 60)"/><path d="M40 61l14 14 27-29" fill="none" stroke="{C['BRAND']}" stroke-width="7" stroke-linecap="round" stroke-linejoin="round" stroke-dasharray="70" stroke-dashoffset="70" style="animation: nmDraw .45s .8s ease forwards"/></svg>
<h1 class="nm-up" style="animation-delay: .9s; margin: 22px 0 0; font-size: 30px; font-weight: 800; letter-spacing: -0.5px">Order placed!</h1>
<div class="nm-up" lang="mr" style="animation-delay: .95s; font-size: 15px; color: {C['SOFT']}">तुमची ऑर्डर यशस्वीरित्या दिली गेली</div>
<div class="nm-up" style="animation-delay: 1s; font-size: 14px; color: {C['FAINT']}; margin-top: 10px; line-height: 1.5">Order #NM-XXXXXX · We’ve emailed you the order details.</div>
<div class="nm-up" style="animation-delay: 1.1s; width: 100%; margin-top: 26px; background: #fff; border: 1px solid {C['LINE']}; border-radius: {p.r}px; padding: 4px 16px; text-align: left; box-sizing: border-box">
{"".join(f'<div style="display: flex; align-items: center; gap: 12px; padding: 12px 0; {"border-bottom: 1px solid " + C["LINE"] if i < 2 else ""}"><span style="width: 36px; height: 36px; border-radius: 10px; background: {C["BSOFT"]}; color: {C["BRAND"]}; display: flex; align-items: center; justify-content: center">{ic(a,20)}</span><span style="flex: 1"><span style="display: block; font-size: 14px; font-weight: 700">{b}</span><span style="display: block; font-size: 12.5px; color: {C["FAINT"]}">{c}</span></span></div>' for i, (a, b, c) in enumerate([("upi","Paid ₹750","UPI · 3 items"),("truck","Delivering across Maharashtra","We’ll message you when it ships"),("ret","5-day return / exchange","Easy returns from your Orders page")]))}
</div>
<div class="nm-up" style="animation-delay: 1.25s; width: 100%; display: flex; flex-direction: column; gap: 10px; margin-top: 24px">
{btn_primary(p, ic("truck",20,"#fff",2) + "Track order", href=p.f("Orders"), flex="width: 100%")}
<a href="{p.f('Home')}" class="nm-press" style="height: {50 if p.ios else 56}px; border-radius: {14 if p.ios else 28}px; border: 1px solid {C['LINE']}; background: #fff; color: {C['INK']}; font-size: 16px; font-weight: 700; display: flex; align-items: center; justify-content: center">Continue shopping</a>
</div></div>'''
    return page("Order placed", inner, "{}", "", "return {};")

def orders(p):
    pad = p.pad
    steps = [("Order placed","check",True,False),("Packed","box",True,False),("Shipped","truck",False,True),("Out for delivery","pin",False,False),("Delivered","home",False,False)]
    tl = ""
    for i, (t, icn, done, cur) in enumerate(steps):
        dot_bg = C['BRAND'] if done else ("#fff" if cur else C['MUTED'])
        dot_bd = C['BRAND'] if (done or cur) else C['LINE']
        col = "#fff" if done else (C['BRAND'] if cur else C['FAINT'])
        ring = ' class="nm-ring"' if cur else ''
        line = ''
        if i < len(steps) - 1:
            fill = C['BRAND'] if done else C['LINE']
            anim = f'transform-origin: top; animation: nmGrow .5s {0.3 + i*0.35:.2f}s ease both;' if done else ''
            line = f'<span style="position: absolute; left: 15px; top: 34px; width: 2px; height: 30px; background: {C["LINE"]}"><span style="display: block; width: 2px; height: 30px; background: {fill}; {anim}"></span></span>'
        extra = f'<span class="nm-drive" style="display: inline-flex; margin-left: 6px; color: {C["BRAND"]}">{ic("truck",16,C["BRAND"],2)}</span>' if cur else ''
        sub = {0:"Confirmed",1:"Ready to ship",2:"On the way",3:"Coming soon",4:"—"}[i]
        tl += f'<div class="nm-up" style="animation-delay: {0.15 + i*0.12:.2f}s; position: relative; display: flex; gap: 12px; align-items: flex-start; height: 64px"><span{ring} style="width: 32px; height: 32px; border-radius: 999px; background: {dot_bg}; border: 2px solid {dot_bd}; box-sizing: border-box; color: {col}; display: flex; align-items: center; justify-content: center; flex-shrink: 0">{ic(icn,16,col,2.2)}</span>{line}<div style="padding-top: 5px"><div style="font-size: 14.5px; font-weight: {700 if (done or cur) else 500}; color: {C["INK"] if (done or cur) else C["FAINT"]}; display: flex; align-items: center">{t}{extra}</div><div style="font-size: 12px; color: {C["FAINT"]}">{sub}</div></div></div>'
    thumbs = "".join(f'<div style="width: 48px; height: 48px; border-radius: 10px; background: {C["MUTED"]}; color: {C["BRAND"]}; display: flex; align-items: center; justify-content: center">{ic(k,22,sw=1.5,label="Product photo")}</div>' for k in ("bolt","bottle","bath"))
    if p.ios:
        seg = f'''<div role="tablist" style="margin: 14px {pad}px 0; background: #EEEEEA; border-radius: 10px; padding: 2px; display: flex; position: relative"><span style="position: absolute; top: 2px; bottom: 2px; left: 2px; width: calc(50% - 2px); border-radius: 8px; background: #fff; box-shadow: 0 1px 3px rgba(0,0,0,0.12); transform: translateX({{{{ segX }}}}%); transition: transform .3s cubic-bezier(.3,1.2,.5,1)"></span><button type="button" role="tab" onClick="{{{{ showA }}}}" style="flex: 1; height: 32px; border: none; background: transparent; font: inherit; font-size: 13px; font-weight: 600; position: relative; cursor: pointer; color: {C['INK']}">Active (1)</button><button type="button" role="tab" onClick="{{{{ showP }}}}" style="flex: 1; height: 32px; border: none; background: transparent; font: inherit; font-size: 13px; font-weight: 600; position: relative; cursor: pointer; color: {C['INK']}">Past</button></div>'''
    else:
        seg = f'''<div role="tablist" style="margin: 8px 0 0; display: flex; border-bottom: 1px solid {C['LINE']}; position: relative"><span style="position: absolute; bottom: 0; left: 0; width: 50%; height: 3px; display: flex; justify-content: center; transform: translateX({{{{ segX }}}}%); transition: transform .3s ease"><span style="width: 50%; height: 3px; border-radius: 3px 3px 0 0; background: {C['BRAND']}"></span></span><button type="button" role="tab" onClick="{{{{ showA }}}}" style="flex: 1; height: 48px; border: none; background: transparent; font: inherit; font-size: 14px; font-weight: 600; color: {{{{ aCol }}}}; cursor: pointer">Active (1)</button><button type="button" role="tab" onClick="{{{{ showP }}}}" style="flex: 1; height: 48px; border: none; background: transparent; font: inherit; font-size: 14px; font-weight: 600; color: {{{{ pCol }}}}; cursor: pointer">Past</button></div>'''
    card_r = p.r + 2
    active = f'''<sc-if value="{{{{ isA }}}}" hint-placeholder-val="{{{{ true }}}}"><div class="nm-fade" style="margin: 16px {pad}px 24px; background: #fff; border: 1px solid {C['LINE']}; border-radius: {card_r}px; overflow: hidden">
<div style="padding: 14px 16px; background: {C['BSOFT']}; display: flex; align-items: center; justify-content: space-between"><div><div style="font-size: 12px; color: {C['DARKG']}; font-weight: 600">ORDER #NM-XXXXXX</div><div style="font-size: 16px; font-weight: 800; margin-top: 2px">Shipped · on the way</div></div><span style="font-size: 15px; font-weight: 800">₹750</span></div>
<div style="padding: 16px 16px 4px">{tl}</div>
<div style="padding: 0 16px 14px; display: flex; align-items: center; gap: 8px">{thumbs}<span style="font-size: 13px; color: {C['FAINT']}; margin-left: 4px">3 items</span></div>
<div style="display: flex; border-top: 1px solid {C['LINE']}"><button type="button" class="nm-press" style="flex: 1; height: 50px; border: none; background: none; font: inherit; font-size: 14px; font-weight: 700; color: {C['BRAND']}; display: flex; align-items: center; justify-content: center; gap: 6px; cursor: pointer">{ic("chat",18)}Need help?</button><span style="width: 1px; background: {C['LINE']}"></span><button type="button" class="nm-press" style="flex: 1; height: 50px; border: none; background: none; font: inherit; font-size: 14px; font-weight: 700; color: {C['INK']}; cursor: pointer">Order details</button></div>
</div></sc-if>'''
    past_items = [("vac","Vacuum Cleaner","₹1,000","Delivered","car"),("duster","Microfiber Feather Duster + 1","₹300","Delivered","clean")]
    past = f'''<sc-if value="{{{{ isP }}}}" hint-placeholder-val="{{{{ false }}}}"><div style="padding: 16px {pad}px 24px; display: flex; flex-direction: column; gap: 12px">
{"".join(f'<div class="nm-up" style="animation-delay: {i*0.08:.2f}s; background: #fff; border: 1px solid {C["LINE"]}; border-radius: {card_r}px; padding: 14px"><div style="display: flex; gap: 12px; align-items: center"><div style="width: 60px; height: 60px; border-radius: 12px; background: {C["MUTED"]}; color: {C["BRAND"]}; display: flex; align-items: center; justify-content: center">{ic(icn,28,sw=1.4,label="Product photo")}</div><div style="flex: 1"><div style="font-size: 12px; font-weight: 700; color: {C["GREEN"]}; display: flex; align-items: center; gap: 4px">{ic("check",14,C["GREEN"],2.6)}{st}</div><div style="font-size: 14.5px; font-weight: 700; margin-top: 2px">{nm}</div><div style="font-size: 12.5px; color: {C["FAINT"]}">Order #NM-XXXXXX · {pr}</div></div></div><div style="display: flex; gap: 8px; margin-top: 12px"><button type="button" class="nm-press" style="flex: 1; height: 40px; border-radius: {10 if p.ios else 20}px; border: 1px solid {C["LINE"]}; background: #fff; font: inherit; font-size: 13.5px; font-weight: 700; color: {C["INK"]}; display: flex; align-items: center; justify-content: center; gap: 6px; cursor: pointer">{ic("ret",16)}Return / exchange</button><a href="{p.f("Product")}" class="nm-press" style="flex: 1; height: 40px; border-radius: {10 if p.ios else 20}px; background: {C["BSOFT"]}; font-size: 13.5px; font-weight: 700; color: {C["BRAND"]}; display: flex; align-items: center; justify-content: center">Buy again</a></div></div>' for i, (_, nm, pr, st, icn) in enumerate(past_items))}
<div style="font-size: 12.5px; color: {C['FAINT']}; text-align: center; padding-top: 4px">Returns and exchanges are open for 5 days after delivery.</div>
</div></sc-if>'''
    inner = header(p, "My orders", p.f("Account"), "Account", mr="माझ्या ऑर्डर्स" if not p.ios else None, large=p.ios) + seg + active + past
    body = scroll(p, inner, 0)
    state = "{ tab: 'a' }"
    vals = '''return { isA: s.tab === 'a', isP: s.tab === 'p', segX: s.tab === 'a' ? 0 : 100, aCol: s.tab === 'a' ? '#317239' : '#4C4F5C', pCol: s.tab === 'p' ? '#317239' : '#4C4F5C',
showA: function(){ self.setState({ tab: 'a' }); }, showP: function(){ self.setState({ tab: 'p' }); } };'''
    return page("My orders", body, state, "", vals)

def wishlist(p):
    pad = 16
    card = f'''<div class="nm-up" style="animation-delay: {{{{ item.delay }}}}ms; position: relative; background: #fff; border: 1px solid {C['LINE']}; border-radius: {p.r}px; padding: 8px; display: flex; flex-direction: column; gap: 4px">
<a href="{p.f('Product')}" style="color: {C['INK']}; display: flex; flex-direction: column; gap: 4px"><div style="height: 148px">{phd("item","148px",p.r-4,48)}</div>
<div style="font-size: 13.5px; font-weight: 600; line-height: 1.3; margin-top: 4px; height: 35px; overflow: hidden">{{{{ item.name }}}}</div>
<div style="display: flex; align-items: baseline; gap: 6px"><span style="font-size: 16px; font-weight: 800">{{{{ item.priceTxt }}}}</span><span style="font-size: 12px; color: {C['FAINT']}; text-decoration: line-through">{{{{ item.mrpTxt }}}}</span><span style="font-size: 12px; font-weight: 700; color: {C['GREEN']}">{{{{ item.off }}}}%</span></div></a>
<button type="button" class="nm-press" onClick="{{{{ item.move }}}}" style="height: 34px; border-radius: {10 if p.ios else 18}px; border: none; background: {C['BRAND']}; color: #fff; font: inherit; font-size: 13px; font-weight: 700; display: flex; align-items: center; justify-content: center; gap: 6px; margin-top: 4px; cursor: pointer">{ic("bag",16,"#fff",2)}Move to bag</button>
<button type="button" class="nm-press" aria-label="Remove from wishlist" onClick="{{{{ item.remove }}}}" style="position: absolute; top: 14px; right: 14px; width: 32px; height: 32px; border-radius: 999px; border: none; background: rgba(255,255,255,0.94); display: flex; align-items: center; justify-content: center; padding: 0; cursor: pointer">{ic("heart",18,C['DEAL'],fill=C['DEAL'])}</button>
</div>'''
    right = iconbtn("bag","Bag",p.f("Bag"),size=40 if p.ios else 48,badge_hole="bag")
    inner = header(p, "Wishlist", None, right=right, mr="विशलिस्ट", large=True) + f'''
<sc-if value="{{{{ has }}}}" hint-placeholder-val="{{{{ true }}}}"><div style="padding: 10px {pad}px 0; font-size: 13px; color: {C['FAINT']}">{{{{ countTxt }}}}</div><div style="display: grid; grid-template-columns: repeat(2, minmax(0, 1fr)); gap: 10px; padding: 10px {pad}px 20px"><sc-for list="{{{{ list }}}}" as="item" hint-placeholder-count="4">{card}</sc-for></div></sc-if>
<sc-if value="{{{{ empty }}}}" hint-placeholder-val="{{{{ false }}}}"><div class="nm-up" style="padding: 80px 40px 0; display: flex; flex-direction: column; align-items: center; gap: 12px; text-align: center"><span class="nm-scalein" style="width: 110px; height: 110px; border-radius: 999px; background: #FDECEA; color: {C['DEAL']}; display: flex; align-items: center; justify-content: center">{ic("heart",50,sw=1.4)}</span><div style="font-size: 22px; font-weight: 800">Nothing saved yet</div><div style="font-size: 14px; color: {C['FAINT']}; line-height: 1.5">Tap the heart on any product to save it here.</div><a href="{p.f('Shop')}" class="nm-press" style="margin-top: 8px; height: 48px; padding: 0 28px; border-radius: {14 if p.ios else 24}px; background: {C['BRAND']}; color: #fff; font-size: 16px; font-weight: 700; display: flex; align-items: center">Explore products</a></div></sc-if>'''
    toast = f'<sc-if value="{{{{ toast }}}}" hint-placeholder-val="{{{{ false }}}}"><div key="{{{{ toastKey }}}}" class="nm-toast" role="status" style="position: absolute; left: 50%; bottom: {p.tabH + 16}px; background: {C["INK"]}; color: #fff; font-size: 14px; font-weight: 600; padding: 12px 16px; border-radius: {12 if p.ios else 8}px; display: flex; align-items: center; gap: 8px; white-space: nowrap; z-index: 30">{ic("check",16,"#fff",2.6)}{{{{ toast }}}}</div></sc-if>'
    body = scroll(p, inner, 0).replace('bottom: 0px; overflow-y', f'bottom: 0px; padding-bottom: {p.tabH}px; box-sizing: border-box; overflow-y') + tabbar(p, "Wishlist") + toast
    state = "{ ids: ['vac', 'grinder', 'solar', 'duster'], bag: 3, bump: false, toast: '', toastKey: 0 }"
    vals = '''const drop = function(id, msg, addBag){ self.setState(function(st){ return { ids: st.ids.filter(function(x){ return x !== id; }), bag: st.bag + (addBag ? 1 : 0), bump: addBag ? !st.bump : st.bump, toast: msg, toastKey: st.toastKey + 1 }; }); self.later(function(){ self.setState({ toast: '' }); }, 2300); };
const list = s.ids.map(function(id, i){ const x = self.prod(id); return self.item(x, { delay: i * 70, move: function(){ drop(id, 'Moved to bag', true); }, remove: function(){ drop(id, 'Removed from wishlist', false); } }); });
return Object.assign({ list: list, has: list.length > 0, empty: list.length === 0, countTxt: list.length + (list.length === 1 ? ' item saved' : ' items saved'), toast: s.toast, toastKey: s.toastKey }, { ''' + bagbadge_js() + ''' });'''
    return page("Wishlist", body, state, "", vals)

def account(p):
    pad = p.pad
    row = lambda icn, key, right="chev", href=None: (
        f'<{"a href=" + chr(34) + href + chr(34) if href else "div"} style="display: flex; align-items: center; gap: 12px; min-height: 52px; padding: 0 14px; border-bottom: 1px solid {{{{ th.line }}}}; color: {{{{ th.ink }}}}">'
        f'<span style="width: 32px; height: 32px; border-radius: 9px; background: {{{{ th.chip }}}}; color: {{{{ th.acc }}}}; display: flex; align-items: center; justify-content: center; transition: background-color .3s ease">{ic(icn,18)}</span>'
        f'<span style="flex: 1; font-size: 15px; font-weight: 500">{{{{ L.{key} }}}}</span>'
        + (f'<span style="color: {{{{ th.faint }}}}">{ic("chevR",18)}</span>' if right == "chev" else right)
        + f'</{"a" if href else "div"}>')
    lang_seg = f'<div style="display: flex; background: {{{{ th.seg }}}}; border-radius: {8 if p.ios else 999}px; padding: 2px; position: relative"><span style="position: absolute; top: 2px; bottom: 2px; left: 2px; width: calc(50% - 2px); border-radius: {7 if p.ios else 999}px; background: {{{{ th.segOn }}}}; transform: translateX({{{{ langX }}}}%); transition: transform .3s cubic-bezier(.3,1.2,.5,1)"></span><button type="button" onClick="{{{{ toEn }}}}" style="position: relative; width: 58px; height: 28px; border: none; background: none; font: inherit; font-size: 13px; font-weight: 700; color: {{{{ enCol }}}}; cursor: pointer">EN</button><button type="button" onClick="{{{{ toMr }}}}" style="position: relative; width: 58px; height: 28px; border: none; background: none; font: inherit; font-size: 13px; font-weight: 700; color: {{{{ mrCol }}}}; cursor: pointer">मराठी</button></div>'
    card = lambda inner: f'<div style="margin: 0 {pad}px; background: {{{{ th.card }}}}; border: 1px solid {{{{ th.line }}}}; border-radius: {p.r}px; overflow: hidden; transition: background-color .3s ease">{inner}</div>'
    sect = lambda key: f'<div style="padding: 22px {pad + 4}px 8px; font-size: 13px; font-weight: 700; letter-spacing: 0.3px; color: {{{{ th.faint }}}}; text-transform: uppercase">{{{{ L.{key} }}}}</div>'
    tiles = "".join(f'<a href="{href}" class="nm-press nm-up" style="animation-delay: {i*0.06:.2f}s; background: {{{{ th.card }}}}; border: 1px solid {{{{ th.line }}}}; border-radius: {p.r}px; padding: 14px 8px; display: flex; flex-direction: column; align-items: center; gap: 8px; color: {{{{ th.ink }}}}; font-size: 12.5px; font-weight: 600; text-align: center; transition: background-color .3s ease"><span style="width: 40px; height: 40px; border-radius: 12px; background: {{{{ th.chip }}}}; color: {{{{ th.acc }}}}; display: flex; align-items: center; justify-content: center">{ic(icn,22)}</span>{{{{ L.{key} }}}}</a>' for i, (icn, key, href) in enumerate([("box","orders",p.f("Orders")),("heart","wishlist",p.f("Wishlist")),("pin","addresses","#"),("bag","bag",p.f("Bag"))]))
    inner = f'''<div style="padding: {p.top + 8}px {pad}px 0; display: flex; align-items: center; gap: 14px">
<span class="nm-scalein" style="width: 60px; height: 60px; border-radius: 999px; background: {C['BRAND']}; color: #fff; display: flex; align-items: center; justify-content: center">{ic("user",30,"#fff",1.8)}</span>
<div style="flex: 1"><div style="font-size: 24px; font-weight: 800; color: {{{{ th.ink }}}}; transition: color .3s ease">{{{{ L.hello }}}}</div><div style="font-size: 14px; color: {{{{ th.faint }}}}">you@example.com</div></div>
<button type="button" aria-label="Edit profile" class="nm-press" style="width: 40px; height: 40px; border-radius: 999px; border: 1px solid {{{{ th.line }}}}; background: {{{{ th.card }}}}; color: {{{{ th.ink }}}}; display: flex; align-items: center; justify-content: center; padding: 0; cursor: pointer">{ic("edit",18)}</button>
</div>
<div style="display: grid; grid-template-columns: repeat(4, minmax(0, 1fr)); gap: 8px; padding: 18px {pad}px 0">{tiles}</div>
{sect("settings")}
{card(row("globe","language",lang_seg) + row("moon","dark",switch(p,"darkSw")) + row("bell","updates",switch(p,"notifSw")))}
{sect("help")}
{card(row("truck","shipping") + row("ret","returns") + row("help","faq") + row("chat","contact"))}
{sect("follow")}
{card(row("star","instagram") + row("star","facebook") + row("star","youtube"))}
<button type="button" class="nm-press" style="margin: 22px {pad}px 0; width: calc(100% - {pad*2}px); height: 50px; border-radius: {p.r}px; border: 1px solid {{{{ th.line }}}}; background: {{{{ th.card }}}}; color: {C['DEAL']}; font: inherit; font-size: 15px; font-weight: 700; display: flex; align-items: center; justify-content: center; gap: 8px; cursor: pointer">{ic("logout",18)}{{{{ L.signout }}}}</button>
<div style="padding: 16px 0 24px; text-align: center; font-size: 12px; color: {{{{ th.faint }}}}">Secure payments · UPI · Cards · Net banking</div>'''
    sc = scroll(p, inner, 0).replace('bottom: 0px; overflow-y', f'bottom: 0px; padding-bottom: {p.tabH}px; box-sizing: border-box; overflow-y')
    body = f'<div style="position: absolute; inset: 0; background: {{{{ th.bg }}}}; transition: background-color .35s ease">{sc}</div>' + tabbar(p, "Account")
    state = "{ dark: false, lang: 'en', notif: true }"
    methods = SWITCH_JS
    vals = '''const EN = { hello: 'Hello!', orders: 'My orders', wishlist: 'Wishlist', addresses: 'Addresses', bag: 'Bag', settings: 'Settings', language: 'Language', dark: 'Dark mode', updates: 'Order updates', help: 'Help', shipping: 'Shipping', returns: 'Returns & exchange', faq: 'FAQs', contact: 'Contact us', follow: 'Follow Nirmal Mart', instagram: 'Instagram', facebook: 'Facebook', youtube: 'YouTube', signout: 'Sign out' };
const MR = { hello: 'नमस्कार!', orders: 'माझ्या ऑर्डर्स', wishlist: 'विशलिस्ट', addresses: 'पत्ते', bag: 'बॅग', settings: 'सेटिंग्ज', language: 'भाषा', dark: 'डार्क मोड', updates: 'ऑर्डर अपडेट्स', help: 'मदत', shipping: 'शिपिंग', returns: 'परतावा आणि बदल', faq: 'प्रश्नोत्तरे', contact: 'संपर्क करा', follow: 'निर्मल मार्ट फॉलो करा', instagram: 'Instagram', facebook: 'Facebook', youtube: 'YouTube', signout: 'साइन आउट' };
const d = s.dark;
const th = d ? { bg: '#111217', card: '#1B1D22', line: '#2A2D33', ink: '#F3F3F0', faint: '#A3A6AE', chip: '#22352A', acc: '#8FCB98', seg: '#2A2D33', segOn: '#3A3E45' }
             : { bg: '#FAFAF8', card: '#FFFFFF', line: '#E5E5E0', ink: '#111217', faint: '#5F6270', chip: '#E9F3EB', acc: '#317239', seg: '#EEEEEA', segOn: '#FFFFFF' };
const en = s.lang === 'en';
return { th: th, L: en ? EN : MR, langX: en ? 0 : 100, enCol: en ? th.ink : th.faint, mrCol: en ? th.faint : th.ink,
toEn: function(){ self.setState({ lang: 'en' }); }, toMr: function(){ self.setState({ lang: 'mr' }); },
darkSw: this.sw(d, 'Dark mode', function(){ self.setState({ dark: !d }); }),
notifSw: this.sw(s.notif, 'Order updates', function(){ self.setState({ notif: !s.notif }); }) };'''
    return page("Account", body, state, methods, vals)

SCREENS = [("Welcome", welcome), ("Login", login), ("Home", home), ("Search", search), ("Shop", shop), ("Product", product),
           ("Bag", bag), ("Checkout", checkout), ("Success", success), ("Orders", orders), ("Wishlist", wishlist), ("Account", account)]
LABELS = {"Welcome":"Welcome","Login":"Sign in","Home":"Home","Search":"Search","Shop":"Shop","Product":"Product","Bag":"Bag","Checkout":"Checkout","Success":"Order placed","Orders":"Orders & tracking","Wishlist":"Wishlist","Account":"Account"}

files = {}
for kind in ("ios", "android"):
    p = Plat(kind); CUR["ios"] = p.ios
    for name, fn in SCREENS:
        files[p.f(name)] = fn(p)
for n, c in files.items():
    open(os.path.join(OUT, n), "w").write(c)

boards = {}; order = []
ROW2 = 844 + 420
for kind, y, rad in (("ios", 0, 44), ("android", ROW2, 28)):
    p = Plat(kind)
    for i, (name, _) in enumerate(SCREENS):
        f = p.f(name)
        boards[f] = {"x": i * 470, "y": y, "w": 390, "h": 844, "title": f"{'iOS' if p.ios else 'Android'} · {LABELS[name]}", "is_interactive": True, "radius": rad}
        order.append(f)
order.remove("Main.dc.html"); order.insert(0, "Main.dc.html")
rowW = 12 * 390 + 11 * 80
canvas = json.load(open(os.path.join(OUT, "canvas.json")))
canvas["boards"] = boards; canvas["order"] = order
canvas["notes"]["ios"].update({"maxW": rowW, "text": "iOS — Cupertino patterns"})
canvas["notes"]["android"].update({"maxW": rowW, "text": "Android — Material 3"})
canvas["launch"] = {"view": "canvas"}
open(os.path.join(OUT, "canvas.json"), "w").write(json.dumps(canvas, indent=1, ensure_ascii=False))
print(len(files), sum(len(c) for c in files.values()))

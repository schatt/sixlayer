"""Scale-relative seven-segment reader prototype (diagnostic only)."""
import numpy as np, sys
from PIL import Image
from scipy import ndimage as ndi
from skimage.filters import threshold_otsu

SEG = {'abcdef':'0','bc':'1','abdeg':'2','abcdg':'3','bcfg':'4','acdfg':'5','acdefg':'6',
       'abc':'7','abcdefg':'8','abcdfg':'9','g':'-','fabc':'7','abcf':'7','cdefg':'6','acdefg ':'6','abcdf g':'9'}
TEMPL = {k:v for k,v in SEG.items() if ' ' not in k}

def load(p):
    with open(p,'rb') as f: d=f.read()
    parts=d.split(b'\n',3); w,h=map(int,parts[1].split()); return np.frombuffer(parts[3][:w*h],np.uint8).reshape(h,w)

def ink_mask(g, H):
    g = g.astype(float)
    k = max(15, H//6) | 1
    bg = ndi.grey_closing(g, size=(k, k))            # glass level under dark ink
    bg = ndi.uniform_filter(bg, k)                   # smooth
    diff = np.clip((bg - g) / np.maximum(bg, 1), 0, 1)
    t = threshold_otsu(diff[diff > 0.02]) if (diff > 0.02).sum() > 100 else 0.2
    return diff > max(t, 0.12), diff

def clean(m, H):
    lab, n = ndi.label(m)
    out = np.zeros_like(m)
    objs = ndi.find_objects(lab)
    h, w = m.shape
    keep = []
    for i, sl in enumerate(objs, 1):
        ys, xs = sl
        bh, bw = ys.stop-ys.start, xs.stop-xs.start
        area = (lab[sl] == i).sum()
        if area < (H*0.012)**2: continue                    # speck
        if ys.start == 0 or xs.start == 0 or ys.stop == h or xs.stop == w: continue  # bezel / edge
        if bh > 0.8*h or bw > 0.5*w: continue                 # frame / big reflection
        fill = area / (bh*bw)
        if fill < 0.25 and max(bh,bw) > H*0.1: continue      # scribble / reflection outline
        keep.append(i)
    out = np.isin(lab, keep)
    return out

def best_shear(m):
    ys, xs = np.nonzero(m); h, w = m.shape
    best = (0, -1)
    for deg in np.arange(-2, 14.1, 0.5):
        t = np.tan(np.radians(deg))
        x2 = np.round(xs + (ys - h/2)*t).astype(int)
        x2 = x2[(x2 >= 0) & (x2 < w)]
        prof = np.bincount(x2, minlength=w)
        score = (prof == 0).sum()     # empty columns = clean inter-digit gaps
        if score > best[1]: best = (deg, score)
    return best[0]

def stem_shear(m, H):
    lab, n = ndi.label(m); angs = []; wts = []
    for i, sl in enumerate(ndi.find_objects(lab), 1):
        bh = sl[0].stop-sl[0].start; bw = sl[1].stop-sl[1].start
        if bh < H*0.06 or bh < 2.2*bw: continue
        ys, xs = np.nonzero(lab[sl] == i)
        a = np.polyfit(ys, xs, 1)[0]
        angs.append(np.degrees(np.arctan(-a))); wts.append(len(ys))
    if len(angs) < 2: return 0.0
    o = np.argsort(angs); c = np.cumsum(np.array(wts)[o]); return float(np.array(angs)[o][np.searchsorted(c, c[-1]/2)])

def deshear(m, deg):
    h, w = m.shape; t = np.tan(np.radians(deg))
    out = np.zeros_like(m); ys, xs = np.nonzero(m)
    x2 = np.round(xs + (ys - h/2)*t).astype(int); ok = (x2 >= 0) & (x2 < w)
    out[ys[ok], x2[ok]] = True
    return ndi.binary_closing(out, iterations=1)

def runs(v, floor=0):
    on = v > floor; r = []; s = None
    for i, x in enumerate(list(on)+[False]):
        if x and s is None: s = i
        if not x and s is not None: r.append((s, i)); s = None
    return r

def read_digit(m, x0, x1, y0, y1):
    h = y1-y0; w = x1-x0
    def frac(fx0, fx1, fy0, fy1):
        sub = m[y0+int(fy0*h):y0+max(int(fy1*h), int(fy0*h)+1), x0+int(fx0*w):x0+max(int(fx1*w), int(fx0*w)+1)]
        return sub.mean() if sub.size else 0
    r = {'a':frac(.3,.7,0,.15),'d':frac(.3,.7,.85,1),'g':frac(.3,.7,.42,.58),
         'f':frac(0,.3,.15,.4),'b':frac(.7,1,.15,.4),'e':frac(0,.3,.6,.85),'c':frac(.7,1,.6,.85)}
    on = ''.join(k for k in 'abcdefg' if r[k] > 0.3)
    if on in TEMPL: return TEMPL[on]
    # nearest template by Hamming
    best = min(TEMPL, key=lambda t: len(set(t) ^ set(on)))
    return TEMPL[best] if len(set(best) ^ set(on)) <= 1 else '_'

def read(path, show=False):
    g = load(path); H0 = g.shape[0]
    scale = 400 / H0
    g = np.asarray(Image.fromarray(g).resize((round(g.shape[1]*scale), 400), Image.BOX))
    H = 400
    m, diff = ink_mask(g, H)
    m = clean(m, H)
    # rotation: sharpest row profile
    def rowscore(a):
        r = ndi.rotate(m.astype(float), a, reshape=False, order=0) > 0.5
        p = r.sum(1).astype(float); return (p**2).sum()/max(1,p.sum())**2
    base = rowscore(0); best=(0,base)
    for a in np.arange(-12,12.1,0.5):
        sc = rowscore(a)
        if sc > best[1]: best=(a,sc)
    rot = best[0] if best[1] > base*1.15 else 0
    if rot:
        m = ndi.rotate(m.astype(float), rot, reshape=True, order=0) > 0.5
    deg = stem_shear(m, H)
    m = deshear(m, deg)
    rowsum = m.sum(1)
    bands = [b for b in runs(ndi.uniform_filter1d(rowsum.astype(float), 3), rowsum.max()*0.04) if b[1]-b[0] > H*0.08]
    lines = []
    for (y0, y1) in bands:
        band = m[y0:y1]
        dh = y1 - y0
        cols = runs(ndi.binary_dilation(band.any(0), iterations=max(1, dh//40)))
        out = ''
        for (x0, x1) in cols:
            sub = band[:, x0:x1]; yy = np.nonzero(sub.any(1))[0]
            cy0, cy1 = yy[0], yy[-1]+1; ch = cy1-cy0; cw = x1-x0
            if ch < 0.3*dh:
                if cy0 > 0.6*dh and cw < 0.35*dh: out += '.'
                continue
            if cw < 0.3*dh: out += '1'; continue
            out += read_digit(band, x0, x1, 0, dh)
        lines.append(out)
    return (rot,deg), '/'.join(lines), m
if __name__ == '__main__':
    for p in sys.argv[1:]:
        deg, txt, m = read(p)
        print(f'{p.split("/")[-1]:20s} rot {deg[0]:5.1f}° shear {deg[1]:4.1f}°  -> {txt}')
        Image.fromarray((~m*255).astype(np.uint8)).save(p.split('/')[-1].replace('.pgm', '_proto.png'))

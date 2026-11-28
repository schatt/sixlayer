import numpy as np, sys
from PIL import Image
SEG={'0':'abcdef','1':'bc','2':'abdeg','3':'abcdg','4':'bcfg','5':'acdfg','6':'acdefg','7':'abc','8':'abcdefg','9':'abcdfg'}
def render(rows, cellW=50, cellH=90, stroke=12, intra=8, pad=16, rowGap=64, bg=214, ink=22,
           shear=0.0, seggap=0, scale=1, blur=0, noise=0, ghost=None, gradient=0, seed=0):
    W=pad*2+max(sum((cellW if c!='.' else stroke)+intra for c in r) for r in rows)
    H=pad*2+len(rows)*cellH+(len(rows)-1)*rowGap
    m=np.zeros((H,W),bool); g=np.zeros((H,W),bool)
    def rect(M,x,y,w,h): M[max(0,y):y+h, max(0,x):x+w]=True
    y=pad
    for r in rows:
        x=pad
        for c in r:
            if c=='.':
                rect(m,x,y+cellH-stroke,stroke,stroke); x+=stroke+intra; continue
            s=SEG[c]; hs=seggap
            parts={'a':(x+hs,y,cellW-2*hs,stroke),'d':(x+hs,y+cellH-stroke,cellW-2*hs,stroke),
                   'g':(x+hs,y+cellH//2-stroke//2,cellW-2*hs,stroke),
                   'f':(x,y+hs,stroke,cellH//2-2*hs),'b':(x+cellW-stroke,y+hs,stroke,cellH//2-2*hs),
                   'e':(x,y+cellH//2+hs,stroke,cellH//2-2*hs),'c':(x+cellW-stroke,y+cellH//2+hs,stroke,cellH//2-2*hs)}
            for k,v in parts.items():
                rect(m if k in s else g,*v)
            x+=cellW+intra
        y+=cellH+rowGap
    img=np.full((H,W),float(bg))
    if gradient: img+=np.linspace(-gradient,gradient,W)[None,:]
    if ghost is not None: img[g]=ghost
    img[m]=ink
    pil=Image.fromarray(np.clip(img,0,255).astype(np.uint8))
    if scale!=1: pil=pil.resize((W*scale,H*scale),Image.NEAREST)
    if shear:
        Wn,Hn=pil.size; t=np.tan(np.radians(shear)); extra=int(Hn*t)+2
        # x_src = x_dst - (Hn - y)*t  => top leans right
        pil=pil.transform((Wn+extra,Hn),Image.AFFINE,(1,t,-extra+ (0),0,1,0),resample=Image.BILINEAR,fillcolor=bg)
    a=np.asarray(pil,float)
    if blur:
        from scipy import ndimage as ndi; a=ndi.gaussian_filter(a,blur)
    if noise: a=a+np.random.default_rng(seed).normal(0,noise,a.shape)
    return np.clip(a,0,255).astype(np.uint8)
def save(a,path):
    with open(path,'wb') as f: f.write(b'P5\n%d %d\n255\n'%(a.shape[1],a.shape[0])); f.write(a.tobytes())
if __name__=='__main__':
    import json; kw=json.loads(sys.argv[2]) if len(sys.argv)>2 else {}
    rows=sys.argv[1].split('/')
    save(render(rows,**kw),sys.argv[3] if len(sys.argv)>3 else 'syn.pgm')

// Landing scenery: boxes drifting behind the hero at three depths (each depth scrolls at its own speed),
// and the corrugated kraft shader behind the footer. Both respect prefers-reduced-motion.
(() => {
  const still = matchMedia('(prefers-reduced-motion: reduce)').matches;

  const sky = document.querySelector('.sky');
  if (sky) {
    let seed = 11;
    const rnd = () => (seed = (seed * 16807) % 2147483647) / 2147483647;
    // far boxes lag the page most; near ones nearly keep up
    const depths = [{ n: 12, size: 18, lag: 0.6, o: 0.35 }, { n: 9, size: 30, lag: 0.4, o: 0.6 }, { n: 6, size: 48, lag: 0.2, o: 0.9 }];
    const layers = depths.map(d => {
      const layer = document.createElement('div');
      layer.className = 'layer';
      for (let i = 0; i < d.n; i++) {
        let x = rnd() * 100;
        if (x > 32 && x < 68) x = x < 50 ? x - 32 : x + 32;  // keep the middle clear for the title
        const b = document.createElementNS('http://www.w3.org/2000/svg', 'svg');
        b.setAttribute('class', 'b');
        b.innerHTML = '<use href="#bx"/>';
        b.style.cssText = `left:${x.toFixed(1)}%;top:${(rnd() * 92).toFixed(1)}%;width:${d.size}px;opacity:${d.o};` +
          `animation-duration:${(5 + rnd() * 5).toFixed(1)}s;animation-delay:${(-rnd() * 10).toFixed(1)}s;--r:${Math.round(rnd() * 40 - 20)}deg`;
        layer.append(b);
      }
      sky.append(layer);
      return { layer, lag: d.lag };
    });
    if (!still) {
      let queued = false;
      addEventListener('scroll', () => {
        if (queued) return;
        queued = true;
        requestAnimationFrame(() => {
          queued = false;
          const y = scrollY;
          if (y > 1400) return;
          for (const { layer, lag } of layers) layer.style.transform = `translate3d(0,${(y * lag).toFixed(1)}px,0)`;
        });
      }, { passive: true });
    }
  }

  const canvas = document.querySelector('.big canvas');
  const gl = canvas && canvas.getContext('webgl', { antialias: false, alpha: false });
  if (!gl) return;  // the footer's CSS gradient stays as the fallback

  const frag = `precision mediump float;
uniform vec2 r; uniform float t;
float h(vec2 p) { return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453); }
float n(vec2 p) { vec2 i = floor(p), f = fract(p); f = f * f * (3. - 2. * f);
  return mix(mix(h(i), h(i + vec2(1, 0)), f.x), mix(h(i + vec2(0, 1)), h(i + 1.), f.x), f.y); }
float fbm(vec2 p) { float v = 0., a = .5; for (int i = 0; i < 5; i++) { v += a * n(p); p *= 2.02; a *= .5; } return v; }
void main() {
  vec2 uv = gl_FragCoord.xy / r.y;
  vec2 q = vec2(fbm(uv * 1.4 + t * .05), fbm(uv * 1.4 + vec2(5.2, 1.3) - t * .04));
  float f = fbm(uv * 2. + q * 1.8 + t * .03);
  float flute = .5 + .5 * sin((uv.x + q.y * .12) * 110.);   // corrugation
  vec3 c = mix(vec3(.20, .11, .05), vec3(.55, .35, .17), smoothstep(.25, .78, f));
  c = mix(c, vec3(.91, .74, .53), smoothstep(.68, .98, f) * .35);
  c *= .94 + .06 * flute;
  gl_FragColor = vec4(c, 1.);
}`;
  const shader = (type, src) => { const s = gl.createShader(type); gl.shaderSource(s, src); gl.compileShader(s); return s; };
  const prog = gl.createProgram();
  gl.attachShader(prog, shader(gl.VERTEX_SHADER, 'attribute vec2 p; void main() { gl_Position = vec4(p, 0., 1.); }'));
  gl.attachShader(prog, shader(gl.FRAGMENT_SHADER, frag));
  gl.linkProgram(prog);
  if (!gl.getProgramParameter(prog, gl.LINK_STATUS)) return;
  gl.useProgram(prog);
  gl.bindBuffer(gl.ARRAY_BUFFER, gl.createBuffer());
  gl.bufferData(gl.ARRAY_BUFFER, new Float32Array([-1, -1, 3, -1, -1, 3]), gl.STATIC_DRAW);
  gl.enableVertexAttribArray(0);
  gl.vertexAttribPointer(0, 2, gl.FLOAT, false, 0, 0);
  const uR = gl.getUniformLocation(prog, 'r'), uT = gl.getUniformLocation(prog, 't');

  const size = () => {
    const k = Math.min(devicePixelRatio, 1.5);
    canvas.width = Math.round(canvas.clientWidth * k);
    canvas.height = Math.round(canvas.clientHeight * k);
    gl.viewport(0, 0, canvas.width, canvas.height);
    gl.uniform2f(uR, canvas.width, canvas.height);
  };
  const draw = ms => { gl.uniform1f(uT, 20 + ms / 1000); gl.drawArrays(gl.TRIANGLES, 0, 3); };
  size();
  draw(0);
  addEventListener('resize', () => { size(); draw(performance.now()); });
  if (still) return;

  let on = false;
  const loop = ms => { if (!on) return; draw(ms); requestAnimationFrame(loop); };
  new IntersectionObserver(([e]) => { const was = on; on = e.isIntersecting; if (on && !was) requestAnimationFrame(loop); }).observe(canvas);
})();

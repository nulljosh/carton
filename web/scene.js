// Landing scenery: boxes drifting behind the hero at three depths (each depth scrolls at its own speed),
// and the corrugated kraft shader behind the footer. Both respect prefers-reduced-motion.
(() => {
  const still = matchMedia('(prefers-reduced-motion: reduce)').matches;

  const sky = document.querySelector('.sky');
  if (sky) {
    let seed = 11;
    const rnd = () => (seed = (seed * 16807) % 2147483647) / 2147483647;
    const few = innerWidth < 600;  // phones get half the boxes
    // far boxes lag the page most and blur a little; near ones nearly keep up and cast a shadow
    const depths = [
      { cls: 'far', n: 12, size: 18, lag: 0.6, o: 0.35, tilt: 6 },
      { cls: 'mid', n: 9, size: 30, lag: 0.4, o: 0.6, tilt: 12 },
      { cls: 'near', n: 6, size: 48, lag: 0.2, o: 0.9, tilt: 22 },
    ];
    const layers = depths.map(d => {
      const layer = document.createElement('div');
      layer.className = 'layer ' + d.cls;
      const n = few ? (d.cls === 'near' ? 0 : Math.ceil(d.n / 2)) : d.n;  // big boxes crowd a phone's single column
      for (let i = 0; i < n; i++) {
        let x = rnd() * 100;
        if (x > 32 && x < 68) x = x < 50 ? x - 32 : x + 32;  // keep the middle clear for the title
        const b = document.createElementNS('http://www.w3.org/2000/svg', 'svg');
        b.setAttribute('class', 'b');
        b.innerHTML = `<use href="#${rnd() < 0.35 ? 'bxl' : 'bx'}"/>`;  // about a third carry a shipping label
        b.style.cssText = `left:${x.toFixed(1)}%;top:${(rnd() * 92).toFixed(1)}%;width:${d.size}px;opacity:${d.o};` +
          `animation-duration:${(5 + rnd() * 5).toFixed(1)}s;animation-delay:${(-rnd() * 10).toFixed(1)}s;--r:${Math.round(rnd() * 40 - 20)}deg`;
        layer.append(b);
      }
      sky.append(layer);
      return { layer, lag: d.lag, tilt: d.tilt };
    });
    if (!still) {
      // eased toward the target each frame, so a flick of the wheel glides instead of stepping
      const now = { y: scrollY, px: 0, py: 0 }, goal = { y: scrollY, px: 0, py: 0 };
      let running = false;
      const frame = () => {
        let moving = false;
        for (const k in now) {
          const d = goal[k] - now[k];
          now[k] = Math.abs(d) < 0.05 ? goal[k] : now[k] + d * 0.12;
          if (now[k] !== goal[k]) moving = true;
        }
        if (now.y < 1400) for (const { layer, lag, tilt } of layers)
          layer.style.transform = `translate3d(${(now.px * tilt).toFixed(2)}px,${(now.y * lag + now.py * tilt * 0.6).toFixed(2)}px,0)`;
        running = moving;
        if (moving) requestAnimationFrame(frame);
      };
      const kick = () => { if (!running) { running = true; requestAnimationFrame(frame); } };
      addEventListener('scroll', () => { goal.y = scrollY; kick(); }, { passive: true });
      // the sky leans away from the pointer on desktop; touch screens skip it
      if (matchMedia('(pointer: fine)').matches) addEventListener('pointermove', e => {
        goal.px = -(e.clientX / innerWidth - 0.5) * 2;
        goal.py = -(e.clientY / innerHeight - 0.5) * 2;
        kick();
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

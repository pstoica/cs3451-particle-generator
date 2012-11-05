import java.util.*;

class ParticleGenerator {
  ArrayList<pt> P;
  ArrayList<vec> V;
  ArrayList<Integer> colors;
  pt origin;

  pt earth;
  float earthR;
  
  Curve C;
  float radius, particleRadius = 3, blend = 0.5, gravity = 100;
  ParticleGenerator(Curve c, int r) {
    C = c;
    origin = P(C.first().x, C.first().y, C.first().z);
    radius = r;
    P = new ArrayList<pt>();
    V = new ArrayList<vec>();
    colors = new ArrayList<Integer>();
  }
  void dragOrigin(vec V) {
    origin.add(V);
  }
  void setEarth(pt loc, float r){
    earthR=r;
    earth=loc;
  }
  void generate(int count) {
    for (int i = 0; i < count;) {
      float x = random(-1, 1),
            y = random(-1, 1),
            z = random(-1, 1);
      float dx = x - origin.x,
            dy = y - origin.y,
            dz = z - origin.z;
      if (x*x + y*y + z*z > radius) continue;
      float mag = (float) Math.sqrt(x*x + y*y + z*z);

      x = x/mag * radius;
      y = y/mag * radius;
      z = z/mag * radius;
      pt particle = P(origin.x + x, origin.y + y, origin.z + z);
      P.add(particle);
      V.add(C.velocityFrom(particle));
      colors.add(color(random(255), random(255), random(255)));
      i++;
    }
  }
  void setRadius(float r) {
    radius = r;
  }
  void drawParticles() {
    stroke(black);
    show(origin, radius);
    noStroke();
    for (int i = 0; i < P.size(); i++) {
      pt particle = P.get(i);
      vec PE = V(particle, earth);
      fill(colors.get(i));
      show(particle, particleRadius);
      particle.add(V.get(i));
      V.set(i, V(V.get(i), blend, V(C.velocityFrom(particle), V(gravity/d2(particle, earth), PE))));
      if (C.nearLast(particle)) {
        P.remove(i);
        V.remove(i);
        colors.remove(i);
      }
    }
    renderGlobe(earth, earthR);
  }
}

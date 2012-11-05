import java.util.*;

class ParticleGenerator {
  ArrayList<pt> P;
  ArrayList<vec> V;
  pt origin;
  Curve C;
  int max = 50;
  float radius, particleRadius = 3, blend = 0.5;
  ParticleGenerator(Curve c) {
    C = c;
    origin = P(C.first().x, C.first().y, C.first().z);
    radius = 100;
    P = new ArrayList<pt>();
    V = new ArrayList<vec>();
  }
  void updateVelocity(int i) {

  }
  void generate(int count) {
    if (P.size() > max) return;
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
      i++;
    }
  }
  void setRadius(float r) {
    radius = r;
  }
  void drawParticles() {
    stroke(blue);
    show(origin, radius);
    stroke(red);
    for (int i = 0; i < P.size(); i++) {
      pt particle = P.get(i);
      show(particle, particleRadius);
      particle.add(V.get(i));
      V.set(i, V(V.get(i), blend, C.velocityFrom(particle)));
      if (C.nearLast(particle)) {
        P.remove(i);
        V.remove(i);
      }
    }
  }
}
import java.util.*;

class ParticleGenerator {
  ArrayList<pt> P;
  ArrayList<vec> V;
  ArrayList<Integer> colors;
  ArrayList<Integer> previousClosest;
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
    previousClosest = new ArrayList<Integer>();
  }
  void dragOrigin(vec V) {
    origin.add(V);
  }
  void dragEarth(vec V) {
    earth.add(V);
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
      if (x*x + y*y + z*z > radius) continue;
      float mag = (float) Math.sqrt(x*x + y*y + z*z);

      x = x/mag * radius;
      y = y/mag * radius;
      z = z/mag * radius;
      pt particle = P(origin.x + x, origin.y + y, origin.z + z);
      if (collision && collides(particle, 2 * particleRadius)) continue;
      P.add(particle);
      V.add(C.velocityFrom(particle));
      previousClosest.add(C.closestVertexID(particle));
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
      int closest = previousClosest.get(i);
      vec PE = V(particle, earth);
      fill(colors.get(i));
      show(particle, particleRadius);
      if (!paused) {
        V.set(i, V(V(gravity/d2(particle, earth), PE),
                   V(1 - blend, V.get(i),
                     blend, V(C.velocityFrom(particle, closest)))));
        previousClosest.set(i, C.closestVertexID(particle, previousClosest.get(i)));
        if (previousClosest.get(i) == C.n - 1) {
          P.remove(i);
          V.remove(i);
          previousClosest.remove(i);
          colors.remove(i);
        }
      }
    }
    renderGlobe(earth, earthR);
  }
  void checkC(){
    for (int i = 0; i < P.size(); i++) {
      for (int j=i+1; j < P.size(); j++){
        vec n = V(P.get(i),P.get(j));
        if (n.norm()<2*particleRadius){
          n = n.normalize();
          n=n.mul(2*d(V.get(i),n));
          V.get(i).sub(n);
          
          n = n.normalize();
          n=n.mul(2*d(V.get(j),n));
          V.get(j).sub(n);
        }
        
      }
      
      vec nE = V(P.get(i),earth);
      if (nE.norm()<particleRadius+earthR){
        nE = nE.normalize();
        nE=nE.mul(2*d(V.get(i),nE));
        V.get(i).sub(nE);
      }
    }
  }

  void checkCollisions(){
    if (!paused) {
      if (collision) checkCollisions(1.0);
      else{
        for (int i = 0; i < P.size(); i++) {
          P.get(i).add(1,V.get(i));
        }
      }
    }
  }

  void checkCollisions(float time){
    float t=9999;
    int hit1=0;
    int hit2=0;
    for (int i=0; i<P.size(); i++){
      float t1 = getCollision(P.get(i),earth,V.get(i),new vec(0,0,0), earthR + particleRadius);
      if (t1>0){
        if (t1<t){
          hit1=i;
          hit2=-1;
          t=t1;
        }
      }
      for (int j=i+1; j<P.size(); j++){
        t1 = getCollision(P.get(i),P.get(j),V.get(i),V.get(j), 2* particleRadius);
        if (t1>0){
          if (t1<t){
            hit1=i;
            hit2=j;
            t=t1;
          }
        }
      }
    }
    if (t<time){
      for (int i = 0; i < P.size(); i++) {
        P.get(i).add(t,V.get(i));
      }
      
      if (hit2==-1){
        vec n = V(P.get(hit1),earth);
        n=n.normalize();
        n=n.mul(2*d(V.get(hit1),n));
        V.set(hit1,V.get(hit1).sub(n));
      }
      else{
        vec n = V(P.get(hit1),P.get(hit2));
        n = n.normalize();
        n=n.mul(2*d(V.get(hit1),n));
        V.set(hit1,V.get(hit1).sub(n));
        
        n = n.normalize();
        n=n.mul(2*d(V.get(hit2),n));
        V.set(hit2,V.get(hit2).sub(n));
      }
      
      checkCollisions(time-t);
    }
    else{
      for (int i = 0; i < P.size(); i++) {
        P.get(i).add(time,V.get(i));
      }
    }
  }
 
  float getCollision(pt P1, pt P2, vec V1, vec V2, float distance){
    distance+=.5; //safety
    if ( d(P1,P2) < distance) return 0;
    float a = n2(M(V1,V2));
    float b = 2 * d( V(P1,P2), M(V2,V1) );
    float c = d2(P1,P2) - distance * distance;
    if (b*b-4*a*c < 0) return -1;
    return (-b-sqrt(b*b-4*a*c))/(2*a);
  }

  boolean collides(pt P1, float distance) {
    distance+=.5; //safety
    pt P2;
    for (int i = 0; i < P.size(); i++) {
      P2 = P.get(i);
      if (d(P1,P2) < distance) return true;
    }
    return false;
  }
}

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
      particle.add(V.get(i));
      V.set(i, V(1 - blend, V.get(i), blend, V(C.velocityFrom(particle, closest), V(gravity/d2(particle, earth), PE))));
      previousClosest.set(i, C.closestVertexID(particle, previousClosest.get(i)));
      System.out.println("near last: " + C.nearLast(particle));
      if (previousClosest.get(i) == C.n - 1) {
        P.remove(i);
        V.remove(i);
        previousClosest.remove(i);
        colors.remove(i);
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
  void checkCollision(){
    checkCollision(1);
  }
  void checkCollision(float time){
    float t=99999;
    int hit1=-1, hit2=-1;
    
    for (int i = 0; i < P.size(); i++) {
      for (int j=i+1; j < P.size(); j++){
        pt particle1 = P.get(i);
        pt particle2 = P.get(j);
        vec v1 = V.get(i);
        vec v2 = V.get(j);
        
        vec p1 = new vec(particle1.x, particle1.y, particle1.z);
        vec p2 = new vec(particle2.x, particle2.y, particle2.z);
       
        //gettting terms for quadratic
        float a = d(v1,v2);
        float b = d(v1,p2)+d(v2,p1);
        float c = d(p1,p2) - 4 * particleRadius*particleRadius;
        
        float term = b*b-4*a*c;
        if (term>0){
          float t1 = (-b + sqrt(term))/(2*a);
          float t2 = (-b - sqrt(term))/(2*a);
          if (t1>0.0001 && t1<t){
            t=t1;
            hit1=i;
            hit2=j;
          }
          if (t2>0.0001 && t2<t){
            t=t2;
            hit1=i;
            hit2=j;
          }
        }
      } 
    }
    
    
    if (t<=time){
      for (int i = 0; i < P.size(); i++) {
        P.get(i).add(t,V.get(i));
      }
      if (hit1<0 || hit2<0) return;
      println("HIT: " + hit1 + " " + hit2);
      println("a+b: " + particleRadius * 2 + " d: " +d(P.get(hit2),P.get(hit1)));
      
      //update velocities
      
      vec n = V(P.get(hit1),P.get(hit2));
      //if (hit2<P.size()) n = V(P.get(hit1),P.get(hit2));
      
      //update first particle
      n=n.normalize();
      n=n.mul(2*d(V.get(hit1),n));
      V.set(hit1,V.get(hit1).sub(n));

      //update second particle
      n=n.normalize();
      n=n.mul(2*d(V.get(hit2),n));
      V.get(hit2).sub(n);
      
      
      checkCollision(time-t);      
    }
    else{
      for (int i = 0; i < P.size(); i++) {
        P.get(i).add(time,V.get(i));
      }
    }
  }
  
  void checkCollisions(){checkCollisions(1.0);}

  void checkCollisions(float time){
    float t=9999;
    int hit1=0;
    for (int i=0; i<P.size(); i++){
      vec dP = V(P.get(i),earth);
      vec dV = V.get(i);
      
      float a = d(dV,dV);
      float b = 2*d(dV,dP);
      float c = d(dP,dP) - (earthR+particleRadius)*(earthR+particleRadius);
      float term = b*b-4*a*c;

      if (term>=0){
        float t1 = (-b+sqrt(b*b-4*a*c))/(2*a);
        float t2 = (-b-sqrt(b*b-4*a*c))/(2*a);
        if (t1>0.000001){
          if(t1<t){
            t=t1;
            hit1=i;
          }
        }
            
        /*if (t2>0.000001){
          if(t2<t){
            t=t2;
            hit1=i;
          }
        }*/
      }
    }
    if (t<time){
      for (int i = 0; i < P.size(); i++) {
        P.get(i).add(t,V.get(i));
      }
      
      println("a+b: " + particleRadius + earthR + " d: " +d(earth,P.get(hit1)));
      vec n = V(P.get(hit1),earth);
      n=n.normalize();
      n=n.mul(2*d(V.get(hit1),n));
      V.set(hit1,V.get(hit1).sub(n));
      //V.set(hit1,new vec(0,0,-10));
      
      checkCollisions(time-t);
    }
    else{
      for (int i = 0; i < P.size(); i++) {
        P.get(i).add(time,V.get(i));
      }
    }
  }
  
}

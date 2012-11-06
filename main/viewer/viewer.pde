//*********************************************************************
//**                            Project 4                            **
//**                 Patrick Stoica and Owen Cox, Oct  2012          **   
//*********************************************************************
import processing.opengl.*;                // load OpenGL libraries and utilities
import javax.media.opengl.*; 
import javax.media.opengl.glu.*; 
import java.nio.*;
import controlP5.*;

GL gl;
GLU glu;
ControlP5 cp5;
RadioButton buttons;
Textlabel fr;

// ****************************** GLOBAL VARIABLES FOR DISPLAY OPTIONS *********************************
Boolean 
  translucent=false,   
  showSilhouette=true, 
  showNMBE=true,
  showSpine=true,
  showControl=true,
  showTube=true,
  showFrenetQuads=true,
  showFrenetNormal=false,
  filterFrenetNormal=true,
  showTwistFreeNormal=false, 
  showHelpText=false,
  paused=false,
  collision=true;

final int INSERT_POINT = 1,
          ADD_POINT = 2,
          DELETE_POINT = 3,
          MOVE_POINT = 4,
          MOVE_PG = 5,
          MOVE_EARTH = 6;

// ****************************** VIEW PARAMETERS *******************************************************
pt F = P(0,0,0); pt T = P(0,0,0); pt E; vec U=V(0,1,0); pt mouse, picked; // focus  set with mouse when pressing ';', eye, and up vector
pt Q=P(0,0,0); vec I=V(1,0,0); vec J=V(0,1,0); vec K=V(0,0,1); // picked surface point Q and screen aligned vectors {I,J,K} set when picked
void initView() {Q=P(0,0,0); I=V(1,0,0); J=V(0,1,0); K=V(0,0,1); F = P(0,0,0); E = P(800,800,800); U=V(0,-1,0); } // declares the local frames

// ******************************** CURVES & SPINES ***********************************************
Curve C0 = new Curve(5), S0 = new Curve(), C1 = new Curve(5), S1 = new Curve();  // control points and spines 0 and 1
Curve C= new Curve(11,130,P());
ParticleGenerator pg;
int nsteps=250; // number of smaples along spine
float sampleDistance=10; // sample distance for spine
pt sE = P(), sF = P(); vec sU=V(); //  view parameters (saved with 'j'
float t = 0;
int particlesPerSecond = 0;
float oneSecond = 10.0;
int particleRadius = 3;
int pgRadius = 100;
int earthRadius = 50;
float pgGravity = 0;
float velocityBlend = 0.5;

// *******************************************************************************************************************    SETUP
void setup() {
  size(800, 800, OPENGL);
  frameRate(30);  
  setColors(); sphereDetail(6); 
  PFont font = loadFont("GillSans-24.vlw"); textFont(font, 20);  // font for writing labels on //  PFont font = loadFont("Courier-14.vlw"); textFont(font, 12); 
  // ***************** OpenGL and View setup
  glu = ((PGraphicsOpenGL) g).glu;  PGraphicsOpenGL pgl = (PGraphicsOpenGL) g;  gl = pgl.beginGL();  pgl.endGL();
  initView(); // declares the local frames for 3D GUI

  // ***************** GUI
  cp5 = new ControlP5(this);
  cp5.addSlider("particlesPerSecond")
    .setPosition(10,10)
    .setRange(0,50)
    .setCaptionLabel("Particles Per Second")
    .setColorCaptionLabel(0x000);

  cp5.addSlider("particleRadius")
    .setPosition(10,30)
    .setRange(1,20)
    .setCaptionLabel("Particle Radius")
    .setColorCaptionLabel(0x000);

  cp5.addSlider("velocityBlend")
    .setPosition(10,50)
    .setRange(0,1.0)
    .setCaptionLabel("Velocity Blend")
    .setColorCaptionLabel(0x000);

  cp5.addSlider("pgRadius")
    .setPosition(10,70)
    .setRange(10,500)
    .setCaptionLabel("Particle Generator Radius")
    .setColorCaptionLabel(0x000);

  cp5.addSlider("earthRadius")
    .setPosition(10,90)
    .setRange(10,200)
    .setCaptionLabel("Earth Radius")
    .setColorCaptionLabel(0x000);

  cp5.addSlider("pgGravity")
    .setPosition(10,110)
    .setRange(0,300)
    .setCaptionLabel("Gravity")
    .setColorCaptionLabel(0x000);

  buttons = cp5.addRadioButton("radioButton")
            .setPosition(10,130)
            .setSize(40,20)
            .setColorForeground(color(120))
            .setColorActive(color(140))
            .setColorLabel(color(0))
            .setItemsPerRow(1)
            .setSpacingColumn(50)
            .addItem("Insert Control Point", 1)
            .addItem("Add Control Point", 2)
            .addItem("Delete Control Point", 3)
            .addItem("Move Control Point (x, y, z)", 4)
            .addItem("Move Particle Generator (x, y, z)", 5)
            .addItem("Move Earth (x, y, z)", 6);

  cp5.addTextlabel("label1")
    .setText("r and m: rotate")
    .setPosition(10,270)
    .setColorValue(color(0));

  cp5.addTextlabel("label2")
    .setText("n: zoom")
    .setPosition(10,290)
    .setColorValue(color(0));

  cp5.addTextlabel("label3")
    .setText("p: pause")
    .setPosition(10,310)
    .setColorValue(color(0));

  cp5.addTextlabel("label4")
    .setText("c: collisions")
    .setPosition(10,330)
    .setColorValue(color(0));

  fr = cp5.addTextlabel("frameRate")
    .setText("framerate: " + frameRate)
    .setPosition(10,350)
    .setColorValue(color(0));

  // ***************** Load Curve
  C.loadPts();
  S0.cloneFrom(C);
  pg = new ParticleGenerator(S0, pgRadius);
  pg.setEarth(new pt(200,300,400),earthRadius);
  
  texmap = loadImage("world32k.jpg");    
  initializeSphere(sDetail);
  }

void radioButton(int a) {
  picked = null;
}
  
// ******************************************************************************************************************* DRAW      
void draw() {  
  fr.setText("framerate: " + frameRate);

  background(white);
  // -------------------------------------------------------- Help ----------------------------------
  if(showHelpText) {
    camera(); // 2D display to show cutout
    lights();
    fill(black); writeHelp();
    return;
  }

  mouse = P(mouseX, mouseY, 0);
    
  // -------------------------------------------------------- 3D display : set up view ----------------------------------
  camera(E.x, E.y, E.z, F.x, F.y, F.z, U.x, U.y, U.z); // defines the view : eye, ctr, up
  vec Li=U(A(V(E,F),0.1*d(E,F),J));   // vec Li=U(A(V(E,F),-d(E,F),J)); 
  directionalLight(255,255,255,Li.x,Li.y,Li.z); // direction of light: behind and above the viewer
  specular(255,255,0); shininess(5);
  
  // -------------------------- display and edit control points of the spines and box ----------------------------------   
  if(buttons.getValue() == INSERT_POINT) {
    picked = S0.ClosestVertex2D(mouse);
    stroke(orange);
    noFill();
    show(picked, 10);
  } else if(buttons.getValue() == ADD_POINT) {
    picked = P(C.last(), V(100, 100, 100));
    stroke(orange);
    noFill();
    show(picked, 10);
  } else if(buttons.getValue() == DELETE_POINT || buttons.getValue() == MOVE_POINT) {
    if (!mousePressed) {
      picked = C.ClosestVertex2D(mouse);
      C.pick(picked);
    }
    stroke(orange);
    noFill();
    show(C.cP(), 10);
  } else {
    picked = null;
  }
     
  // -------------------------------------------------------- create control curves  ----------------------------------   
   //C0.empty().append(C.Pof(0)).append(C.Pof(1)).append(C.Pof(2)).append(C.Pof(3)).append(C.Pof(4)); 

   // -------------------------------------------------------- create and show spines  ----------------------------------   
   S0.cloneFrom(C);
   S0.setNV(200);
   stroke(blue); noFill();
   if(showSpine) {
    S0.drawEdges();
    stroke(0, 0, 0, 100); //S0.drawShadows();
   }
   
   // -------------------------------------------------------- compute spine normals  ----------------------------------   
   //S0.prepareSpine(0);
   if (!paused) {
    if (t > oneSecond) {
      pg.generate(particlesPerSecond);
      t = 0;
    }
    t += 0.2;
   }

   pg.drawParticles();
  
   // -------------------------------------------------------- show tube ----------------------------------   
   //if(showTube) S0.showTube(10,4,10,orange); 

 
  // -------------------------------------------------------- graphic picking on surface and view control ----------------------------------   
  if (keyPressed&&key==' ') T.set(Pick()); // sets point T on the surface where the mouse points. The camera will turn toward's it when the ';' key is released
  SetFrame(Q,I,J,K);
   //showFrame(Q,I,J,K,30);  // sets frame from picked points and screen axes
   showAxes(50);
  // rotate view 
  if(keyPressed&&key=='m'&&mousePressed) {E=R(E,  PI*float(mouseX-pmouseX)/width,I,K,F); E=R(E,-PI*float(mouseY-pmouseY)/width,J,K,F); } // rotate E around F 
  if(keyPressed&&key=='n'&&mousePressed) {E=P(E,-float(mouseY-pmouseY),K); }  //   Moves E forward/backward
  if(keyPressed&&key=='r'&&mousePressed) {U=R(U, -PI*float(mouseX-pmouseX)/width,I,J); }//   Rotates around (F,Y)
   
  // -------------------------------------------------------- Disable z-buffer to display occluded silhouettes and other things ---------------------------------- 
  hint(DISABLE_DEPTH_TEST);  // show on top
  stroke(black); if(showControl) {
    C.showSamples(2);
    stroke(white);
    //C.showShadowSamples(1);
  }
  camera(); // 2D view to write help text
  writeFooterHelp();
  hint(ENABLE_DEPTH_TEST); // show silouettes

  // -------------------------------------------------------- SNAP PICTURE ---------------------------------- 
   if(snapping) snapPicture(); // does not work for a large screen
    pressed=false;

  pg.radius = pgRadius;
  pg.earthR = earthRadius;
  pg.gravity = pgGravity;
  pg.particleRadius = particleRadius;
  pg.blend = velocityBlend;

 } // end draw
 
 
 // ****************************************************************************************************************************** INTERRUPTS
Boolean pressed=false;

void mousePressed() {pressed=true; }
  
void mouseDragged() {
  //if(keyPressed&&key=='a') {C.dragPoint( V(.5*(mouseX-pmouseX),I,.5*(mouseY-pmouseY),K) ); } // move selected vertex of curve C in screen plane
  //if(keyPressed&&key=='s') {C.dragPoint( V(.5*(mouseX-pmouseX),I,-.5*(mouseY-pmouseY),J) ); } // move selected vertex of curve C in screen plane
  if(keyPressed&&key=='x') {
    vec V = V((mouseX-pmouseX), I, (mouseY-pmouseY), I);
    V.y = 0;
    V.z = 0;
    if (buttons.getValue() == MOVE_POINT) C.dragPoint(V);
    if (buttons.getValue() == MOVE_PG) pg.dragOrigin(V);
    if (buttons.getValue() == MOVE_EARTH) pg.dragEarth(V);
  }
  if(keyPressed&&key=='y') {
    vec V = V(-1*(mouseX-pmouseX), J, -1*(mouseY-pmouseY), J);
    V.x = 0;
    V.z = 0;
    if (buttons.getValue() == MOVE_POINT) C.dragPoint(V);
    if (buttons.getValue() == MOVE_PG) pg.dragOrigin(V);
    if (buttons.getValue() == MOVE_EARTH) pg.dragEarth(V);
  }
  if(keyPressed&&key=='z') {
    vec V = V((mouseX-pmouseX), K, (mouseY-pmouseY), K);
    V.x = 0;
    V.y = 0;
    if (buttons.getValue() == MOVE_POINT) C.dragPoint(V);
    if (buttons.getValue() == MOVE_PG) pg.dragOrigin(V);
    if (buttons.getValue() == MOVE_EARTH) pg.dragEarth(V);
  }
  if(keyPressed&&key=='b') {C.dragAll(V(.5*(mouseX-pmouseX),I,.5*(mouseY-pmouseY),K) ); } // move selected vertex of curve C in screen plane
  if(keyPressed&&key=='v') {C.dragAll(V(.5*(mouseX-pmouseX),I,-.5*(mouseY-pmouseY),J) ); } // move selected vertex of curve Cb in XZ
  }

void mouseReleased() {
     U.set(M(J)); // reset camera up vector
    }
  
void keyReleased() {
   if(key==' ') F=P(T);                           //   if(key=='c') M0.moveTo(C.Pof(10));
   U.set(M(J)); // reset camera up vector
}

void mouseClicked() {
  if (picked != null) {
    if (buttons.getValue() == INSERT_POINT) {
        C.insert(picked);
    }
    if (buttons.getValue() == ADD_POINT) {
      C.append(picked);
    }
    if (buttons.getValue() == DELETE_POINT && C.n > 2) {
      C.delete();
    }
  }
}

void keyPressed() {
  if(key=='a') {} // drag curve control point in xz (mouseDragged)
  if(key=='b') {}  // move S2 in XZ
  if(key=='c') {collision = !collision;}
  if(key=='d') {} 
  if(key=='e') {}
  if(key=='f') {filterFrenetNormal=!filterFrenetNormal; if(filterFrenetNormal) println("Filtering"); else println("not filtering");}
  if(key=='g') {} // change global twist w (mouseDrag)
  if(key=='h') {} // hide picked vertex (mousePressed)
  if(key=='x') {}
  if(key=='k') {}
  if(key=='l') {}
  if(key=='n') {showNMBE=!showNMBE;}
  if(key=='o') {}
  if(key=='p') {}
  if(key=='q') {}
  if(key=='r') {}
  if(key=='t') {showTube=!showTube;}
  if(key=='u') {}
  if(key=='v') {} // move S2
  if(key=='w') {}
  if(key=='y') {}
   
  if(key=='A') {C.savePts();}
  if(key=='B') {}
  if(key=='C') {C.loadPts();} // load curve
  if(key=='F') {}
  if(key=='G') {}
  if(key=='H') {}
  if(key=='I') {}
  if(key=='J') {}
  if(key=='K') {}
  if(key=='M') {}
  if(key=='O') {}
  if(key=='p') {paused = !paused;}
  if(key=='Q') {exit();}
  if(key=='R') {}
  if(key=='T') {}
  if(key=='U') {}
  if(key=='V') {} 

  if(key=='~') {showSpine=!showSpine;}
  if(key=='!') {snapping=true;}
  if(key=='@') {}
  if(key=='#') {}
  if(key=='%') {}
  if(key=='&') {}
  if(key=='*') {sampleDistance*=2;}
  if(key=='(') {}
  if(key==')') {showSilhouette=!showSilhouette;}
  if(key=='=') {C.P[5].set(C.P[0]); C.P[6].set(C.P[1]); C.P[7].set(C.P[2]); C.P[8].set(C.P[3]); C.P[9].set(C.P[4]);}
  if(key=='{') {showFrenetQuads=!showFrenetQuads;}
  if(key=='}') {}
  if(key=='|') {}
  if(key==':') {translucent=!translucent;}
  if(key==';') {showControl=!showControl;}
  if(key=='<') {}
  if(key=='>') {if (shrunk==0) shrunk=1; else shrunk=0;}
  if(key=='?') {showHelpText=!showHelpText;}
  if(key=='.') {} // pick corner
  if(key==',') {}
  if(key=='^') {} 
  if(key=='/') {} 
  //if(key==' ') {} // pick focus point (will be centered) (draw & keyReleased)

  if(key=='0') {w=0;}
//  for(int i=0; i<10; i++) if (key==char(i+48)) vis[i]=!vis[i];
  
  } //------------------------------------------------------------------------ end keyPressed

float [] Volume = new float [3];
float [] Area = new float [3];
float dis = 0;
  
Boolean prev=false;

void showGrid(float s) {
  for (float x=0; x<width; x+=s*20) line(x,0,x,height);
  for (float y=0; y<height; y+=s*20) line(0,y,width,y);
  }
  
  // Snapping PICTURES of the screen
PImage myFace; // picture of author's face, read from file pic.jpg in data folder
int pictureCounter=0;
Boolean snapping=false; // used to hide some text whil emaking a picture
void snapPicture() {saveFrame("PICTURES/P"+nf(pictureCounter++,3)+".jpg"); snapping=false;}

 


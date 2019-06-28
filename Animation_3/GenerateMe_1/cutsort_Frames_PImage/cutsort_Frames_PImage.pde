// Cut and sort + revert. Image glitch compressing tool with recover mode
// Tomasz Sulej, generateme.blog@gmail.com, http://generateme.tumblr.com
// Licence: http://unlicense.org/

// How it works (session with sketch):
//  Encode (e):
//   * take image
//   * randomly cut lines
//   * optionaly sort pixels in line
//   * sort lines using channel data
//   * save as encoded image
//  Process:
//    Do whatever you want with the image: recompress, glitch, change colors, etc...
//    Don't forget to update image from disc ('u')
//    You can filter
//  Decode:
//   * unsort lines
//   * display decoded image

// Usage:

//   * press E to encode
//   * press D to decode - you need to encode first!
//   * press U to update encoded image from disc
//   * click to random parameters


///Modified by Adrion T. Kelley



//
import com.google.gson.reflect.TypeToken;
import com.google.gson.*;

import java.io.OutputStreamWriter;
import java.io.BufferedWriter;

import java.io.InputStreamReader;
import java.io.BufferedReader;

import java.util.Collections;




int max_display_size = 1000; // viewing window size (regardless image size)

float line_len = 60; // 1 and above
boolean sort_line = true; // sort line or not
int swap_cnt = 100; // set number of swaps, less then height
int stat_channel = BRIGHTNESS; // channel used to encode image
boolean do_filter = true; // filter image
int filter = BLUR;
int filter_param = 5;

// working buffer
PGraphics buffer;


int count  = 0;
int numFrames = 11;  // The number of frames in the animation
int currentFrame = 0;
PImage[] images = new PImage[numFrames];
String imageName;


// image
PImage img, enci;

String sessionid;

public class Slice {
    public int pos, len;
}

public class SliceWithContent extends Slice implements Comparable {
  public color[] sl;
  float stat;
  
  public void doStats() {
    stat = 0;
    for(int i=0;i<sl.length;i++) stat += getChannel(sl[i],stat_channel);
    stat /= sl.length;
  }
  
  public int compareTo(Object _s) {
    SliceWithContent s = (SliceWithContent)_s;
    return this.stat<s.stat?-1:this.stat>s.stat?1:0;
  }
}

ArrayList<SliceWithContent> slices = new ArrayList<SliceWithContent>();
ArrayList<Slice>slices2save = new ArrayList<Slice>();

void setup() {
  frameRate(6);
  
  
  sessionid = hex((int)random(0xffff),4);
  //img = loadImage(foldername+filename+fileext);
  
  
  for (int i = 1; i < numFrames; i++) {
        imageName = "Art_" + nf(i, 4) + ".png";
        images[i] = loadImage(imageName);

          println(imageName);
        //delay(1000);
       }
  
  
 
  
  img = new PImage(568,320);
  
  
  buffer = createGraphics(img.width, img.height);
  buffer.beginDraw();
  buffer.noStroke();
  buffer.smooth(8);
  buffer.background(0);
  buffer.image(img,0,0);
  buffer.endDraw();
  
  // calculate window size
  float ratio = (float)img.width/(float)img.height;
  int neww, newh;
  if(ratio < 1.0) {
    neww = (int)(max_display_size * ratio);
    newh = max_display_size;
  } else {
    neww = max_display_size;
    newh = (int)(max_display_size / ratio);
  }

  size(568,320);
  
  //processImage();
}

void draw() {
  // fill for iterative processing
  
  count++;
       if(count == images.length) count = 1;
    img.copy(images[count], 0, 0, images[count].width, images[count].height, 
        0, 0, img.width, img.height);
  
  
  
  
  
  
  processImage();
  //saveFrame("output/Art_####.png");
  encode();
  decode();
  updateEncoded();
 
  
  
}

void processImage() {
  image(buffer,0,0,width,height);
}

final static int[] fltrs = {BLUR,POSTERIZE,ERODE,DILATE};

void mouseClicked() {
  line_len = random(1,img.width/8);
  sort_line = random(1)<0.8;
  swap_cnt = random(1)<0.3?0:(int)random(img.height);
  stat_channel = (int)random(12);
  do_filter = random(1)<0.8;
  filter = fltrs[(int)random(fltrs.length)];
  filter_param = filter==BLUR?(int)random(1,5):(int)random(2,20);
  encode();
  decode();
}

void keyPressed() {
  // SPACE to save
  if(keyCode == 32) {
    //String fn = foldername + filename + "/res_" + sessionid + hex((int)random(0xffff),4)+"_"+filename+fileext;
    //buffer.save(fn);
    //println("Image "+ fn + " saved");
  } else if(key == 'e' || key == 'E') {
    encode();
    //println("Image "+imageName+" encoded");
  } else if(key == 'd' || key == 'D') {
    decode();
    //println("Image "+imageName+" decoded");
  } else if(key == 'u' || key == 'U') {
    updateEncoded();
    decode();
    //println("Image "+imageName+" updated");
  }
  
}

void decode() {
  try {
  
       
  BufferedReader re = new BufferedReader(new InputStreamReader(createInput("./" + imageName + "/" + imageName + "_data" + sessionid +".json")));
  
  Gson g = new Gson();
  slices = g.fromJson(re,new TypeToken<ArrayList<Slice>>() {}.getType());  
  
  enci.loadPixels(); 
  buffer.loadPixels();
  int y = 0;
  for(Slice sl : slices) {
    try {
      arrayCopy(enci.pixels,y,buffer.pixels,sl.pos,sl.len);
    } catch (Exception e) {}
    y+=sl.len;
  }
  buffer.updatePixels();
  
  image(buffer,0,0,width,height);
  
  re.close();
  } catch(Exception e) { e.printStackTrace(); }
  

}

void updateEncoded() {
  enci = loadImage("./" + imageName + "/" + imageName + "_encoded" + sessionid + ".png");
}

void encode() {
  slices.clear();
  slices2save.clear();
  try {
  
  BufferedWriter w = new BufferedWriter(new OutputStreamWriter(createOutput("./" + imageName + "/" + imageName + "_data" + sessionid +".json")));
    
  int y = 0 ;
  while(y<img.pixels.length) {
    int r = (int)(1+abs(randomGaussian()*line_len));
    if(r+y>=img.pixels.length) {
      r = img.pixels.length-y;
    } 
    
      SliceWithContent sl = new SliceWithContent();
      sl.pos = y;
      sl.len = r;
      sl.sl = new color[r];
      arrayCopy(img.pixels,y,sl.sl,0,r);
      if(sort_line) sl.sl = sort(sl.sl);
      sl.doStats();
      slices.add(sl);
    
    y+=r;
  }
  
  // glitch a little
  for(int i=0;i<swap_cnt;i++) {
    int r1 = (int)random(slices.size());
    int r2 = (int)random(1,2);
    if(r1+r2<slices.size()) {
      Slice s1 = slices.get(r1);
      Slice s2 = slices.get(r1+r2);
      int tmp = s1.pos;
      s1.pos = s2.pos;
      s2.pos = tmp;
    }
  }
  
  Collections.sort(slices);
  
  buffer.loadPixels();
  y = 0;
  for(SliceWithContent sl : slices) {
    arrayCopy(sl.sl,0,buffer.pixels,y,sl.len);
    y+=sl.len;
    Slice s = new Slice();
    s.len = sl.len;
    s.pos = sl.pos;
    slices2save.add(s);
  }
  
  buffer.updatePixels();
  
  Gson g = new Gson();
  g.toJson(slices2save,w);
  
  w.flush();
  w.close();
  
  if(do_filter) {
    if(filter == POSTERIZE || filter == BLUR) buffer.filter(filter,filter_param);
    else buffer.filter(filter);
  }
  
  image(buffer,0,0,width,height);
  saveBuffer();
  enci = buffer.get();
  
  } catch(Exception e) { e.printStackTrace(); }
}
//

void saveBuffer() {
  buffer.save("./" + imageName + "/" + imageName + "_encoded" + sessionid + ".png");
}

// ALL Channels, Nxxx stand for negative (255-value)
// channels to work with
final static int RED = 0;
final static int GREEN = 1;
final static int BLUE = 2;
final static int HUE = 3;
final static int SATURATION = 4;
final static int BRIGHTNESS = 5;
final static int NRED = 6;
final static int NGREEN = 7;
final static int NBLUE = 8;
final static int NHUE = 9;
final static int NSATURATION = 10;
final static int NBRIGHTNESS = 11;

float getChannel(color c, int channel) {
  int ch = channel>5?channel-6:channel;
  float cc;
  
  switch(ch) {
    case RED: cc = red(c); break;
    case GREEN: cc = green(c); break;
    case BLUE: cc = blue(c); break;
    case HUE: cc = hue(c); break;
    case SATURATION: cc = saturation(c); break;
    default: cc= brightness(c); break;
  }
  
  return channel>5?255-cc:cc;
}
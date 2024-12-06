import processing.sound.*;

AudioIn input;         // Audio input
FFT fft;               // FFT for frequency analysis
float[] vertexOffsets; // Array to store offsets for each vertex
float timeOffset = 0;  // Time offset for noise animation
int numBands = 16;     // Number of frequency bands (matches the number of vertices)
PImage img;

// Class to hold Bézier curve data with opacity
class BezierCurve {
  float[] x1, y1, x2, y2, cx1, cy1, cx2, cy2; // Control points and vertices
  float opacity; // Opacity (alpha)
  BezierCurve(float[] x1, float[] y1, float[] x2, float[] y2, float[] cx1, float[] cy1, float[] cx2, float[] cy2, float opacity) {
    this.x1 = x1;
    this.y1 = y1;
    this.x2 = x2;
    this.y2 = y2;
    this.cx1 = cx1;
    this.cy1 = cy1;
    this.cx2 = cx2;
    this.cy2 = cy2;
    this.opacity = opacity;
  }
}

ArrayList<BezierCurve> bezierHistory = new ArrayList<BezierCurve>(); // To store the history of Bézier curves

void setup() {
  size(800, 800,P3D);
  noFill();
  stroke(0);
  strokeWeight(2);
 img =loadImage("there_is_no_circle-01.png");


  // Initialize Sound library components
  input = new AudioIn(this, 0); // Audio input (default device)
  fft = new FFT(this, 512);    // FFT with 512 frequency bands

  // Start audio input and connect to FFT
  input.start();
  fft.input(input);

  // Initialize vertex offsets
  vertexOffsets = new float[numBands];
}

void draw() {
  background(255); // Clear the screen


   image(img, 0, 0);
  // Center and radius of the circle
  float centerX = width / 2;
  float centerY = height / 2;
  float radius = 200;

  // Number of segments
  int numSegments = numBands; // Same as the number of frequency bands
  float angleStep = TWO_PI / numSegments;

  // Control point factor for smooth curve approximation
  float controlFactor = 4 * (sqrt(2) - 1) / 3;

  // Analyze the frequency spectrum
  fft.analyze();

  // Total number of bands in the spectrum
  int spectrumSize = fft.spectrum.length;

  // Use FFT data to modulate vertex offsets
  for (int i = 0; i < numSegments; i++) {
    // Get the average value for the corresponding FFT bands
    int startBin = i * (spectrumSize / numBands);
    int endBin = (i + 1) * (spectrumSize / numBands);
    float bandAmplitude = 0;
    for (int j = startBin; j < endBin; j++) {
      bandAmplitude += fft.spectrum[j];
    }
    bandAmplitude /= (endBin - startBin); // Average the amplitude in this band

    // Map the band amplitude to a useful range for vertex movement
    vertexOffsets[i] = map(bandAmplitude, 0, 0.1, 0, 300) + noise(i * 0.1, timeOffset) * 300 - 150;
  }

  // Store the current Bézier curve with its opacity
  float[] x1 = new float[numSegments];
  float[] y1 = new float[numSegments];
  float[] x2 = new float[numSegments];
  float[] y2 = new float[numSegments];
  float[] cx1 = new float[numSegments];
  float[] cy1 = new float[numSegments];
  float[] cx2 = new float[numSegments];
  float[] cy2 = new float[numSegments];
  
  beginShape();
  for (int i = 0; i < numSegments; i++) {
    // Current, previous, and next points
    int prevIndex = (i - 1 + numSegments) % numSegments;
    int nextIndex = (i + 1) % numSegments;

    float angle1 = i * angleStep;
    float noisyRadius = radius + vertexOffsets[i];
    
    x1[i] = centerX + cos(angle1) * noisyRadius;
    y1[i] = centerY + sin(angle1) * noisyRadius;

    float angle2 = (i + 1) * angleStep;
    float noisyRadius2 = radius + vertexOffsets[nextIndex];

    x2[i] = centerX + cos(angle2) * noisyRadius2;
    y2[i] = centerY + sin(angle2) * noisyRadius2;

    // Control points
    cx1[i] = x1[i] - sin(angle1) * noisyRadius * controlFactor;
    cy1[i] = y1[i] + cos(angle1) * noisyRadius * controlFactor;

    cx2[i] = x2[i] + sin(angle2) * noisyRadius2 * controlFactor;
    cy2[i] = y2[i] - cos(angle2) * noisyRadius2 * controlFactor;

    if (i == 0) {
      // Ensure we have a starting vertex before bezierVertex() calls
      vertex(x1[i], y1[i]);
    }
    bezierVertex(cx1[i], cy1[i], cx2[i], cy2[i], x2[i], y2[i]);
  }
  endShape(CLOSE);

  // Add the current Bézier curve to history with decreasing opacity
  bezierHistory.add(new BezierCurve(x1, y1, x2, y2, cx1, cy1, cx2, cy2, 255));

  // Decrease opacity for each Bézier curve in history
  for (int i = bezierHistory.size() - 1; i >= 0; i--) {
    BezierCurve curve = bezierHistory.get(i);
    curve.opacity -= 2; // Gradually decrease opacity

    if (curve.opacity <= 0) {
      bezierHistory.remove(i); // Remove the curve if opacity is 0 or less
    } else {
      // Draw the Bézier curve with the current opacity
      stroke(0, curve.opacity); // Set the opacity for this curve
      beginShape();
      vertex(curve.x1[0], curve.y1[0]); // Ensure we start the shape with the first vertex
      for (int j = 0; j < numSegments; j++) {
        bezierVertex(curve.cx1[j], curve.cy1[j], curve.cx2[j], curve.cy2[j], curve.x2[j], curve.y2[j]);
      }
      endShape(CLOSE);
    }
  }

  // Increment the time offset for noise evolution
  timeOffset += 0.01;
}

void stop() {
  input.stop();
  super.stop();
}

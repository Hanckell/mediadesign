int nc = 40;
float[] cx = new float[nc];
float[] vx = new float[nc];
float[] cy = new float[nc];
float[] vy = new float[nc];

int dir = -1;

void setup()
{
  size(800,600);
  surface.setResizable(true);
  for(int i = 0; i < nc; i++)
  {
  cx[i] = width / 2;
  cy[i] = height / 2;
  vx[i] = random(1,15);
  vy[i] = random(1,13);
  }
}


void draw()
{
  background(0);
  for(int i = 0; i < nc; i++)
  {
    println(cy[i]);
    circle(cx[i],cy[i],40);
    cx[i] = cx[i] + vx[i];
    cy[i] = cy[i] + vy[i];
    if(cx[i] > width || cx[i] < 0) vx[i] = vx[i]*dir;
    if(cy[i] > width || cy[i] < 0) vy[i] = vy[i]*dir;
  }
}

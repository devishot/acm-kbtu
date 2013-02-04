#include <iostream>
#include <cstdlib>
#include <cstdio>
#include <cmath>

using namespace std;

double get(double ax, double ay, double bx, double by)
{
	return sqrt((ax-bx)*(ax-bx) + (ay-by)*(ay-by));
}

int main(){
	double ax, ay, bx, by, cx, cy;
	cin>>ax>>ay>>bx>>by>>cx>>cy;

	double s = fabs(((ax-cx)*(by-cy) - (bx-cx)*(ay-cy))/2.0);

	printf("%.4f\n", s);

	return 0;
}
/*
a  b

  c

c->a ax-cx ay-cy
c->b bx-cx by-cy

*/

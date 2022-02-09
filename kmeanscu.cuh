
#ifndef KMEANSCU


#include<cuda_runtime.h>
#include "device_launch_parameters.h"
#include <iostream>
#include "defines.h"



/*__global__ void vectAdd(int* a, int* b, int* c);

__host__ int prova();
*/

//__device__ double distance(double x1_point, double y1_point, double x2_point, double y2_point);

__global__ void calculateDistanceCuda(double* vect_x, double* vect_y, centroid_point* cp, int* c_vect);





#define KMEANSCU
#endif // !KMEANSCU

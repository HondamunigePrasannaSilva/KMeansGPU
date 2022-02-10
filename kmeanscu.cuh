
#ifndef KMEANSCU


#include<cuda_runtime.h>
#include "device_launch_parameters.h"
#include <iostream>
#include "defines.h"
#include <curand.h>
#include <curand_kernel.h>


/*__global__ void vectAdd(int* a, int* b, int* c);

__host__ int prova();
*/

//__device__ double distance(double x1_point, double y1_point, double x2_point, double y2_point);

//__global__ void calculateDistanceCuda(double* vect_x, double* vect_y, centroid_point* cp, int* c_vect);


__device__ int random(unsigned int seed, int i);

__global__ void randomCentroidsCuda(double cp_x[], double cp_y[], double* vect_x, double* vect_y, unsigned int seed);

__device__ __host__ double distance(double x1_point, double y1_point, double x2_point, double y2_point);

#define KMEANSCU
#endif // !KMEANSCU

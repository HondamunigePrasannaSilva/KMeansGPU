
#ifndef KMEANSCU


#include<cuda_runtime.h>
#include <iostream>
#include "defines.h"

#include <cuda.h>
#include "device_launch_parameters.h"
#include <curand.h>
#include <curand_kernel.h>


#if !defined(__CUDA_ARCH__) || __CUDA_ARCH__ >= 600

#else
static __inline__ __device__ double atomicAdd(double* address, double val) {
    unsigned long long int* address_as_ull = (unsigned long long int*)address;
    unsigned long long int old = *address_as_ull, assumed;
    if (val == 0.0)
        return __longlong_as_double(old);
    do {
        assumed = old;
        old = atomicCAS(address_as_ull, assumed, __double_as_longlong(val + __longlong_as_double(assumed)));
    } while (assumed != old);
    return __longlong_as_double(old);
}


#endif


__device__ int random(unsigned int seed, int i);

__global__ void randomCentroidsCuda(double cp_x[], double cp_y[], double* vect_x, double* vect_y, unsigned int seed);

__device__  double distance(double x1_point, double y1_point, double x2_point, double y2_point);

__global__ void calculateDistanceCuda(double vect_x[], double vect_y[], double cp_x[], double cp_y[], int c_vect[]);

__global__ void updateCentroidsCuda(int vect_c[], double vect_x[], double vect_y[], double cp_x[], double cp_y[], int *change);

__global__ void calculateCentroidMeans(int vect_c[], double vect_x[], double vect_y[], double sum_c_x[], double sum_c_y[], int num_c[]);

__global__ void updateC(double sum_c_x[], double sum_c_y[], int num_c[], double cp_x[], double cp_y[], double* count);

#define KMEANSCU

#endif // !KMEANSCU



#include<algorithm>
#include <iostream>
#include <math.h>
#include "kmeanscu.cuh"

using std::cout;
using std::endl;






__device__ double distance(double x1_point, double y1_point, double x2_point, double y2_point)
{
	return sqrt(pow(x1_point - x2_point, 2) + pow(y1_point - y2_point, 2));
}

__global__ void calculateDistanceCuda(double vect_x[], double vect_y[], double cp_x[], double cp_y[], int c_vect[])
{
    const int idx = blockIdx.x * blockDim.x + threadIdx.x;

    if (idx >= DATASET_SIZE) return;

    double dist, temp;
    int cluster_class;

    __shared__ double s_vect_cx[CLUSTER_SIZE];
    __shared__ double s_vect_cy[CLUSTER_SIZE];

    if (threadIdx.x == 0)
    {
        for (int i = 0; i < CLUSTER_SIZE; i++)
        {
            s_vect_cx[i] = cp_x[i];
            s_vect_cy[i] = cp_y[i];
        }
    }
    __syncthreads();

    // calculating distance between dataset point and centroid
    // selecting the centroid with minium distance

    dist = distance(vect_x[idx], vect_y[idx], s_vect_cx[0], s_vect_cy[0]);
    cluster_class = 0;
    
    for (int j = 0; j < CLUSTER_SIZE; j++)
    {
        temp = distance(vect_x[idx], vect_y[idx], s_vect_cx[j], s_vect_cy[j]);
        // looking for the minimum distance given a point
        if (dist > temp) 
        {
            cluster_class = j;
            dist = temp;
        }
    }
    // updating to the beloging cluster 
    c_vect[idx] = cluster_class;

}


__global__ void calculateCentroidMeans(int vect_c[], double vect_x[], double vect_y[], double sum_c_x[], double sum_c_y[], int num_c[])
{
    const int idx = blockIdx.x * blockDim.x + threadIdx.x;

    if (idx >= DATASET_SIZE) return;

    __shared__ double s_vect_x[BLOCK];
    __shared__ double s_vect_y[BLOCK];
    __shared__ int s_vect_c[BLOCK];

    __shared__ double partial_sum_x[CLUSTER_SIZE];
    __shared__ double partial_sum_y[CLUSTER_SIZE];
    __shared__ int    partial_num[CLUSTER_SIZE];

    // metto nella shared memory la porzione di dati che il blocco usera per fare i calcoli
    s_vect_x[threadIdx.x] = vect_x[idx];
    s_vect_c[threadIdx.x] = vect_c[idx];
    s_vect_y[threadIdx.x] = vect_y[idx];
    
    __syncthreads();

    if (threadIdx.x == 0)
    {
        int j;
        for (int i = 0; i < CLUSTER_SIZE; i++)
        {
            partial_sum_x[i] = 0;
            partial_sum_y[i] = 0;
            partial_num[i] = 0;
        }
        
  
       
        int q = 0;
        if (DATASET_SIZE - (blockIdx.x * BLOCK) < BLOCK)
            q = DATASET_SIZE - (blockIdx.x * BLOCK);
        else
            q = BLOCK;

        for (int i = 0; i < q; i++)
        {
            j = s_vect_c[i];
            partial_sum_x[j] += s_vect_x[i];
            partial_sum_y[j] += s_vect_y[i];
            partial_num[j] += 1;
        }
        for (int i = 0; i < CLUSTER_SIZE; i++)
        {
            atomicAdd(&sum_c_x[i], partial_sum_x[i]);
            atomicAdd(&sum_c_y[i], partial_sum_y[i]);
            atomicAdd(&num_c[i], partial_num[i]);
        }

    }
}



__global__ void updateC(double sum_c_x[], double sum_c_y[], int num_c[], double cp_x[], double cp_y[], double* count)
{

    const int idx = blockIdx.x * blockDim.x + threadIdx.x;

    __shared__ int c[BLOCK_C];

    if (idx >= CLUSTER_SIZE){return;}

    for (int i = 0; i < BLOCK_C; i++){c[i] = 0;}

    // Calculating the means of the centroids
    if (num_c[idx] == 0){num_c[idx] = 1;}
    
    sum_c_x[idx] = sum_c_x[idx] / num_c[idx];
    sum_c_y[idx] = sum_c_y[idx] / num_c[idx];
    
    // Checking the distance between the old and the new centroid

    double dist = distance(cp_x[idx], cp_y[idx], sum_c_x[idx], sum_c_y[idx]);
    
    if (dist <= THRESHOLD){c[threadIdx.x] = 1;}
    else
    {
        c[threadIdx.x] = 0;
        cp_x[idx] = sum_c_x[idx];
        cp_y[idx] = sum_c_y[idx];
    }
    
    __syncthreads();
    // caluculating unchange centroids
    if (threadIdx.x == 0)
    {
        double sum = 0;
        for (int i = 0; i < BLOCK_C; i++)
        { sum += c[i]; } 
        atomicAdd(count,sum);
    }
    // setting the partial sum vectors to 0
    sum_c_x[idx] = 0;
    sum_c_y[idx] = 0;
    num_c[idx] = 0;
}


__global__ void updateS(double sum_c_x[], double sum_c_y[], int num_c[], double cp_x[], double cp_y[], double* count)
{

    int c = 0;
    double dist = 0;
    double tmp_x = 0;
    double tmp_y = 0;

    for (int i = 0; i < CLUSTER_SIZE; i++)
    {
        if (num_c[i] != 0){

            tmp_x = sum_c_x[i] / num_c[i];
            tmp_y = sum_c_y[i] / num_c[i];
            dist = distance(tmp_x, tmp_y, cp_x[i], cp_y[i]);

            if (dist <= THRESHOLD) { c++; }
            else
            {
                cp_x[i] = tmp_x;
                cp_y[i] = tmp_y;
            }
            sum_c_x[i] = 0;
            sum_c_y[i] = 0;
            num_c[i] = 0;
        }
    }
    *count = c;
}
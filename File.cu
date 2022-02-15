

#include<algorithm>
#include <iostream>
#include <math.h>
#include "kmeanscu.cuh"

using std::cout;
using std::endl;






__device__ int random(unsigned int seed, int i)
{
	/* CUDA's random number library uses curandState_t to keep track of the seed value
	 we will store a random state for every thread  */
	curandState_t state;

	/* we have to initialize the state */
	curand_init(seed, /* the seed controls the sequence of random values that are produced */
		0, /* the sequence number is only important with multiple cores */
		i, /* the offset is how much extra we advance in the sequence for each call, can be 0 */
		&state);

	
	return curand(&state) % DATASET_SIZE;
}


__global__ void randomCentroidsCuda(double cp_x[], double cp_y[], double* vect_x, double* vect_y, unsigned int seed)
{
	const int idx = blockIdx.x * blockDim.x + threadIdx.x;

	if (idx >= CLUSTER_SIZE) return;

	int rand;
	
	rand = random(seed, idx);

	// scelgo un punto randomico dal dataset e lo seleziono come centroide iniziale
	cp_x[idx] = vect_x[rand];
	cp_y[idx] = vect_y[rand];
}


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

    __shared__ double s_vect_x[WRAPDIM];
    s_vect_x[threadIdx.x] = vect_x[idx];

    __shared__ double s_vect_y[WRAPDIM];
    s_vect_y[threadIdx.x] = vect_y[idx];

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

    dist = distance(s_vect_x[threadIdx.x], s_vect_y[threadIdx.x], s_vect_cx[0], s_vect_cy[0]);
    cluster_class = 0;
    
    for (int j = 0; j < CLUSTER_SIZE; j++)
    {
        temp = distance(s_vect_x[threadIdx.x], s_vect_y[threadIdx.x], s_vect_cx[j], s_vect_cy[j]);
        if (dist > temp) // looking for the minimum distance given a point
        {
            cluster_class = j;
            dist = temp;
        }
    }

    // updating to the beloging cluster 
    c_vect[idx] = cluster_class;

}

__global__ void updateCentroidsCuda(int vect_c[], double vect_x[], double vect_y[], double cp_x[], double cp_y[], int* change)
{
    double update_x, update_y;
    int num_points, count = 0;

    for (int i = 0; i < CLUSTER_SIZE; i++)
    {
        update_x = update_y = num_points = 0;

        for (int j = 0; j < DATASET_SIZE; j++)
        {
            if (vect_c[j] == i)
            {
                update_x += vect_x[j];
                update_y += vect_y[j];
                num_points++;
            }
        }

        // calculating che the center of the points given a cluster
        if (num_points != 0)
        {
            update_x = update_x / num_points;
            update_y = update_y / num_points;
        }

        //counting unchange centroid
        double cond = distance(cp_x[i], cp_y[i], update_x, update_y);


        if (cond <= THRESHOLD)
            count++;

        // updating centroids
        if (num_points != 0 && cond > THRESHOLD)
        {
            cp_x[i] = update_x;
            cp_y[i] = update_y;
        }

    }

    if (count > PERCENTAGE * CLUSTER_SIZE)
        *change = 1;
    else
        *change = 0;
}

__global__ void calculateCentroidMeans(int vect_c[], double vect_x[], double vect_y[], double sum_c_x[], double sum_c_y[], int num_c[])
{
    const int idx = blockIdx.x * blockDim.x + threadIdx.x;

    if (idx >= DATASET_SIZE) return;

    __shared__ float s_vect_x[WRAPDIM];
    __shared__ float s_vect_y[WRAPDIM];
    __shared__ int s_vect_c[WRAPDIM];

   

    __shared__ double partial_sum_x[CLUSTER_SIZE];
    __shared__ double partial_sum_y[CLUSTER_SIZE];
    __shared__ int    partial_num[CLUSTER_SIZE];

    s_vect_x[threadIdx.x] = vect_x[idx];
    s_vect_c[threadIdx.x] = vect_c[idx];
    s_vect_y[threadIdx.x] = vect_y[idx];
    
   
    __syncthreads();

    if (threadIdx.x == 0)
    {
        int j;
        for (int i = 0; i < CLUSTER_SIZE; i++)
        {
            partial_sum_x[i] = partial_sum_y[i] = partial_num[i] = 0;
        }
        
        for (int i = 0; i < CLUSTER_SIZE; i++)
        {
            j = s_vect_c[i];
            if (j != -1)
            {
                partial_sum_x[j] += s_vect_x[i];
                partial_sum_y[j] += s_vect_y[i];
                partial_num[j] += 1;
            }
         
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
    
    // controllo della threashold
    // fare un atomic per incrementare il contatore di centroidi non modificati

    const int idx = blockIdx.x * blockDim.x + threadIdx.x;

    __shared__ int c[WRAPDIM_C];

    if (idx >= CLUSTER_SIZE) return;

    // Calculating the means of the centroids
    sum_c_x[idx] = sum_c_x[idx] / num_c[idx];
    sum_c_y[idx] = sum_c_y[idx] / num_c[idx];

    // Checking the distance between the old and the new centroid

    double dist = distance(cp_x[idx], cp_y[idx], sum_c_x[idx], sum_c_y[idx]);

    __syncthreads();
    
    if (dist < THRESHOLD)
        c[threadIdx.x] = 1;
    else
    {
        c[threadIdx.x] = 0;
        cp_x[idx] = sum_c_x[idx];
        cp_y[idx] = sum_c_y[idx];
    }
    __syncthreads();  
    
    if (threadIdx.x == 0)
    {
        double sum = 0;
        for (int i = 0; i < WRAPDIM_C; i++)
        {
            sum += c[i];
        }
        

        atomicAdd(count,sum);
    }

}

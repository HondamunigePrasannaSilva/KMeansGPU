

#include<algorithm>
#include <iostream>
#include <math.h>


using std::cout;
using std::endl;
#include "kmeanscu.cuh"




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
    __shared__ double s_vect_y[WRAPDIM];

    __shared__ double s_vect_cx[CLUSTER_SIZE];
    __shared__ double s_vect_cy[CLUSTER_SIZE];

    if (threadIdx.x == 0)
    {
        for (int i = 0; i < blockDim.x; i++)
        {
            if (i + idx >= DATASET_SIZE) break;

            s_vect_x[i] = vect_x[i+idx];
            s_vect_y[i] = vect_y[i+idx];
        }

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

__global__ void updateCentroids(int vect_c[], double vect_x[], double vect_y[], double cp_x[], double cp_y[], int* change)
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

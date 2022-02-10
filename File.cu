

#include<algorithm>
#include <iostream>
#include <math.h>


using std::cout;
using std::endl;
#include "kmeanscu.cuh"


/*
__global__ void vectAdd(int* a, int* b, int* c)
{
	int i = threadIdx.x;
	c[i] = a[i] + b[i];
}
*/
/*__host__ int prova()
{
	int a[] = {1,2,3};
	int b[] = { 4,5,6 };
	int c[sizeof(a) / sizeof(int)] = { 0 };

	int* cudaA = 0;
	int* cudaB = 0;
	int* cudaC = 0;


	// alloccato memoria nel GPU
	cudaMalloc(&cudaA, sizeof(a));
	cudaMalloc(&cudaB, sizeof(b));
	cudaMalloc(&cudaC, sizeof(c));


	// copiare i vettori nel gpu
	cudaMemcpy(cudaA, a, sizeof(a), cudaMemcpyHostToDevice);
	cudaMemcpy(cudaB, b, sizeof(b), cudaMemcpyHostToDevice);


	vectAdd <<< 1, sizeof(a) / sizeof(int) >>> (cudaA, cudaB, cudaC);

	cudaMemcpy(c, cudaC, sizeof(c), cudaMemcpyDeviceToHost);

	return 0;

}



__device__ double distance(double x1_point, double y1_point, double x2_point, double y2_point)
{
	return sqrt(pow(x1_point - x2_point, 2) + pow(y1_point - y2_point, 2));
}


__global__ void calculateDistanceCuda(double* vect_x, double* vect_y, centroid_point* cp, int* c_vect)
{
	double dist, temp;
	int cluster_class;

	const int idx = blockIdx.x * blockDim.x + threadIdx.x;
	
	if (idx >= DATASET_SIZE) return;

	dist = distance(vect_x[idx], vect_y[idx], cp->x_c[0], cp->y_c[0]);
	cluster_class = 0;

	for (int j = 1; j < CLUSTER_SIZE; j++)
	{
		temp = distance(vect_x[idx], vect_y[idx], cp->x_c[j], cp->y_c[j]);

		if (dist > temp) // looking for the minimum distance given a point
		{
			cluster_class = j;
			dist = temp;
		}
	}

	// updating to the beloging cluster 
	c_vect[idx] = cluster_class;

	
}
*/

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
	//return (abs(x1_point-x2_point)+abs(y1_point-y2_point));
}


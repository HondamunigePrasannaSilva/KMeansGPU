#include<cuda_runtime.h>
#include "device_launch_parameters.h"
#include <iostream>

__global__ void vectAdd(int* a, int* b, int* c)
{
	int i = threadIdx.x;
	c[i] = a[i] + b[i];
}

int main()
{
	int a[] = { 1,2,3 };
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

	for (int i = 0; i < 3; i++)
	{
		std::cout << c[i] << std::endl;
	}
	return 0;

}
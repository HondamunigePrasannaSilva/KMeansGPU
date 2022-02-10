


#include"Intestazione.h"

#include"kmeanscu.cuh"




int main()
{
    std::string   DATASET_PATH;

    // if the centroid are not changed then the method stops
    bool isChange = true;
    int i = 0;
    
    cout << "DATASET SIZE: " << DATASET_SIZE << " CLUSTER SIZE: " << CLUSTER_SIZE << " ITERATIONS: " << endl;

    // declaring array for dataset point and for centroid points
    
    double  x[DATASET_SIZE];
    double  y[DATASET_SIZE];
    int     c[DATASET_SIZE];
    
    double cpx[CLUSTER_SIZE];
    double cpy[CLUSTER_SIZE];


    // -----------------------------------------
    //alloccare memoria nella GPU

    double* cudax = 0;
    double* cuday = 0;
    int*    cudac = 0;

    double* cudacpx = 0;
    double* cudacpy = 0;

    cudaError_t cudaStatus;

    cudaStatus = cudaMalloc((void**)&cudax, DATASET_SIZE * sizeof(double));
    if (cudaStatus != cudaSuccess) {
        fprintf(stderr, "cudaMalloc failed!");
        goto Error;
    }

    cudaStatus = cudaMalloc((void**)&cuday, DATASET_SIZE * sizeof(double));
    if (cudaStatus != cudaSuccess) {
        fprintf(stderr, "cudaMalloc failed!");
        goto Error;
    }

    cudaStatus = cudaMalloc((void**)&cudac, DATASET_SIZE * sizeof(int));
    if (cudaStatus != cudaSuccess) {
        fprintf(stderr, "cudaMalloc failed!");
        goto Error;
    }
    
    cudaStatus = cudaMalloc((void**)&cudacpx, DATASET_SIZE * sizeof(double));
    if (cudaStatus != cudaSuccess) {
        fprintf(stderr, "cudaMalloc failed!");
        goto Error;
    }

    cudaStatus = cudaMalloc((void**)&cudacpy, DATASET_SIZE * sizeof(double));
    if (cudaStatus != cudaSuccess) {
        fprintf(stderr, "cudaMalloc failed!");
        goto Error;
    }

    // -----------------------------------------
    
   
    DATASET_PATH = "Datasets/dataset/ds.txt";
    loadDataset(DATASET_PATH, x, y, c);

    cout << "Finish loading data.." << endl;

    // copia del dataset nella gpu
  
    cudaStatus = cudaMemcpy(cudax, x, DATASET_SIZE * sizeof(double), cudaMemcpyHostToDevice);
    if (cudaStatus != cudaSuccess) {
        fprintf(stderr, "cudaMemcpy failed!");
        goto Error;
    }
    cudaStatus = cudaMemcpy(cuday, y, DATASET_SIZE * sizeof(double), cudaMemcpyHostToDevice);
    if (cudaStatus != cudaSuccess) {
        fprintf(stderr, "cudaMemcpy failed!");
        goto Error;
    }
    cudaStatus = cudaMemcpy(cudac, c, DATASET_SIZE * sizeof(int), cudaMemcpyHostToDevice);
    if (cudaStatus != cudaSuccess) {
        fprintf(stderr, "cudaMemcpy failed!");
        goto Error;
    }
    // -----------------------------------------------------


    // generating random centroid for the first step of the method
    cout << "Generating first " << CLUSTER_SIZE << " centroids.." << endl;


    // chiamare il randomcentroidcuda
    
    //randomCentroids(cpx, cpy, x, y);

    randomCentroidsCuda <<< (CLUSTER_SIZE+32)/32, 32 >> > (cudacpx, cudacpy, cudax, cuday, time(NULL));


    cudaStatus = cudaGetLastError();
    if (cudaStatus != cudaSuccess) {
        fprintf(stderr, "addKernel launch failed: %s\n", cudaGetErrorString(cudaStatus));
        goto Error;
    }

    cudaStatus = cudaDeviceSynchronize();
    if (cudaStatus != cudaSuccess) {
        fprintf(stderr, "cudaDeviceSynchronize returned error code %d after launching addKernel!\n", cudaStatus);
        goto Error;
    }

  
    // -----------------------------------------
    // copiare i centroidi iniziali nella gpu
    //cudaMemcpy(cudacpx, cpx, sizeof(cpx), cudaMemcpyHostToDevice);
    //cudaMemcpy(cudacpy, cpy, sizeof(cpy), cudaMemcpyHostToDevice);

    // -----------------------------------------

       // Copy output vector from GPU buffer to host memory.
    cudaStatus = cudaMemcpy(cpx, cudacpx, CLUSTER_SIZE * sizeof(double), cudaMemcpyDeviceToHost);
    if (cudaStatus != cudaSuccess) {
        fprintf(stderr, "cudaMemcpy failed!");
        goto Error;
    }
    cudaStatus = cudaMemcpy(cpy, cudacpy, CLUSTER_SIZE * sizeof(double), cudaMemcpyDeviceToHost);
    if (cudaStatus != cudaSuccess) {
        fprintf(stderr, "cudaMemcpy failed!");
        goto Error;
    }
    
    cout << "Finish generating random centroids.." << endl;

    printClusterPoint(cpx, cpy);


    



    while (isChange == true)
    {
        cout << "Calculating cluster cycle: " << i + 1 << "..." << endl;
        calculateDistance(x, y, cpx, cpy, c);
        cout << "End calculating cluster cycle: " << i + 1 << endl;

        cout << "Updating centroids..." << endl;
        isChange = updateCentroids(c, x, y, cpx, cpy);
        cout << "End Updating centroids..." << endl;
        i++;

    }



    // copio i cluster dei punti e i centroidi dalla gpu alla memoria ram
    //cudaMemcpy(c, cudac, sizeof(cudac), cudaMemcpyDeviceToHost);
    //cudaMemcpy(cpx, cudacpx, sizeof(cudacpx), cudaMemcpyDeviceToHost);
    //cudaMemcpy(cpy, cudacpy, sizeof(cudacpy), cudaMemcpyDeviceToHost);


    // printing the centroid after the kmeans methods
    printClusterPoint(cpx, cpy);


Error:
    // free dei puntatori
    cudaFree(cudax);
    cudaFree(cuday);
    cudaFree(cudac);
    cudaFree(cudacpx);
    cudaFree(cudacpy);





}
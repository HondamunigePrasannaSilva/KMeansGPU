


#include"Intestazione.h"

#include"kmeanscu.cuh"




int main()
{
    std::string   DATASET_PATH;

    // if the centroid are not changed then the method stops
    int* isChange = (int*)malloc(sizeof(int));
    
    *isChange = 0;

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

    int*    change = 0;
    cudaError_t cudaStatus;

    cudaStatus = cudaMalloc((void**)&cudax, DATASET_SIZE * sizeof(double));
    if (cudaStatus != cudaSuccess) {
        fprintf(stderr, "cudaMalloc vect_x failed!");
        goto Error;
    }

    cudaStatus = cudaMalloc((void**)&cuday, DATASET_SIZE * sizeof(double));
    if (cudaStatus != cudaSuccess) {
        fprintf(stderr, "cudaMalloc vect_y failed!");
        goto Error;
    }

    cudaStatus = cudaMalloc((void**)&cudac, DATASET_SIZE * sizeof(int));
    if (cudaStatus != cudaSuccess) {
        fprintf(stderr, "cudaMalloc vect_c  failed!");
        goto Error;
    }
    
    cudaStatus = cudaMalloc((void**)&cudacpx, DATASET_SIZE * sizeof(double));
    if (cudaStatus != cudaSuccess) {
        fprintf(stderr, "cudaMalloc vect_cpx failed!");
        goto Error;
    }

    cudaStatus = cudaMalloc((void**)&cudacpy, DATASET_SIZE * sizeof(double));
    if (cudaStatus != cudaSuccess) {
        fprintf(stderr, "cudaMalloc vect_cpx failed!");
        goto Error;
    }

    cudaStatus = cudaMalloc((void**)&change, DATASET_SIZE * sizeof(int));
    if (cudaStatus != cudaSuccess) {
        fprintf(stderr, "cudaMalloc vect_cpx failed!");
        goto Error;
    }



    // -----------------------------------------
    
   
    DATASET_PATH = "Datasets/dataset/ds.txt";
    loadDataset(DATASET_PATH, x, y, c);

    cout << "Finish loading data.." << endl;

    // copia del dataset nella gpu
  
    cudaStatus = cudaMemcpy(cudax, x, DATASET_SIZE * sizeof(double), cudaMemcpyHostToDevice);
    if (cudaStatus != cudaSuccess) {
        fprintf(stderr, "cudaMemcpy vect_x failed!");
        goto Error;
    }
    cudaStatus = cudaMemcpy(cuday, y, DATASET_SIZE * sizeof(double), cudaMemcpyHostToDevice);
    if (cudaStatus != cudaSuccess) {
        fprintf(stderr, "cudaMemcpy vect_y failed!");
        goto Error;
    }
   
    // -----------------------------------------------------


    // generating random centroid for the first step of the method
    cout << "Generating first " << CLUSTER_SIZE << " centroids.." << endl;


    
    randomCentroidsCuda <<< (CLUSTER_SIZE+32)/32, 32 >> > (cudacpx, cudacpy, cudax, cuday, time(NULL));


    cudaStatus = cudaGetLastError();
    if (cudaStatus != cudaSuccess) {
        fprintf(stderr, "randomCentroidCuda launch failed: %s\n", cudaGetErrorString(cudaStatus));
        goto Error;
    }

    cudaStatus = cudaDeviceSynchronize();
    if (cudaStatus != cudaSuccess) {
        fprintf(stderr, "cudaDeviceSynchronize returned error code %d after launching randomCentroidCuda!\n", cudaStatus);
        goto Error;
    }

  
    

    // -----------------------------------------

       // Copy output vector from GPU buffer to host memory.
    cudaStatus = cudaMemcpy(cpx, cudacpx, CLUSTER_SIZE * sizeof(double), cudaMemcpyDeviceToHost);
    if (cudaStatus != cudaSuccess) {
        fprintf(stderr, "cudaMemcpy vect_cpx failed!");
        goto Error;
    }
    cudaStatus = cudaMemcpy(cpy, cudacpy, CLUSTER_SIZE * sizeof(double), cudaMemcpyDeviceToHost);
    if (cudaStatus != cudaSuccess) {
        fprintf(stderr, "cudaMemcpy vect_cpy failed!");
        goto Error;
    }
    
    cout << "Finish generating random centroids.." << endl;

    printClusterPoint(cpx, cpy);


    



    while (*isChange == 0)
    {
        cout << "Calculating cluster cycle: " << i + 1 << "..." << endl;
        cout << BLOCKDIM;
        calculateDistanceCuda<<<BLOCKDIM, WRAPDIM >>>(cudax, cuday, cudacpx, cudacpy, cudac);


        cudaStatus = cudaDeviceSynchronize();
        if (cudaStatus != cudaSuccess) {
            fprintf(stderr, "cudaDeviceSynchronize returned error code %d after launching calculateDistanceCuda!\n", cudaStatus);
            goto Error;
        }


        cout << "End calculating cluster cycle: " << i + 1 << endl;

        cout << "Updating centroids..." << endl;

        //isChange = updateCentroids(c, x, y, cpx, cpy);
        updateCentroids<<<1,1>>>(cudac, cudax, cuday, cudacpx, cudacpy, change);
        
        cout << "End Updating centroids..." << endl;
        i++;

        cudaStatus = cudaMemcpy(isChange, change, sizeof(int), cudaMemcpyDeviceToHost);
       
        if (cudaStatus != cudaSuccess) {
            fprintf(stderr, "cudaMemcpy change failed!");
            goto Error;
        }

    }



    // copio i cluster dei punti e i centroidi dalla gpu alla memoria ram
    //cudaMemcpy(c, cudac, sizeof(cudac), cudaMemcpyDeviceToHost);
    //cudaMemcpy(cpx, cudacpx, sizeof(cudacpx), cudaMemcpyDeviceToHost);
    //cudaMemcpy(cpy, cudacpy, sizeof(cudacpy), cudaMemcpyDeviceToHost);

    
    cudaStatus = cudaMemcpy(cpx, cudacpx, CLUSTER_SIZE * sizeof(double), cudaMemcpyDeviceToHost);
    if (cudaStatus != cudaSuccess) {
        fprintf(stderr, "cudaMemcpy vect_cpx failed!");
        goto Error;
    }
    cudaStatus = cudaMemcpy(cpy, cudacpy, CLUSTER_SIZE * sizeof(double), cudaMemcpyDeviceToHost);
    if (cudaStatus != cudaSuccess) {
        fprintf(stderr, "cudaMemcpy vect_cpy failed!");
        goto Error;
    }
    cudaStatus = cudaMemcpy(c, cudac, DATASET_SIZE * sizeof(int), cudaMemcpyDeviceToHost);
    if (cudaStatus != cudaSuccess) {
        fprintf(stderr, "cudaMemcpy vect_c failed!");
        goto Error;
    }
    



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
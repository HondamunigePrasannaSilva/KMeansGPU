


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
    
    double cpx[CLUSTER_SIZE];   // array of centroid, x value
    double cpy[CLUSTER_SIZE];   // array of centroid, y value

    double sum_cen_x[CLUSTER_SIZE];
    double sum_cen_y[CLUSTER_SIZE];
    int    num_cen[CLUSTER_SIZE];


    // -----------------------------------------
    //alloccare memoria nella GPU

    double* cudax = 0;
    double* cuday = 0;
    int*    cudac = 0;

    double* cudacpx = 0;
    double* cudacpy = 0;

    double* cudascx = 0;
    double* cudascy = 0;
    int* cudanc  = 0;

    int*    change = 0;
    cudaError_t cudaStatus;
    
    cudaStatus = cudaMalloc((void**)&cudax, DATASET_SIZE * sizeof(double));
    if (cudaErrorStatus("cudaMalloc", cudaStatus, "cudax")) goto Error;
   

    cudaStatus = cudaMalloc((void**)&cuday, DATASET_SIZE * sizeof(double));
    if (cudaErrorStatus("cudaMalloc", cudaStatus, "cuday")) goto Error;

    cudaStatus = cudaMalloc((void**)&cudac, DATASET_SIZE * sizeof(int));
    if (cudaErrorStatus("cudaMalloc", cudaStatus, "cudac")) goto Error;
   
    cudaStatus = cudaMalloc((void**)&cudacpx, DATASET_SIZE * sizeof(double));
    if (cudaErrorStatus("cudaMalloc", cudaStatus, "cudacpx")) goto Error;
   

    cudaStatus = cudaMalloc((void**)&cudacpy, DATASET_SIZE * sizeof(double));
    if (cudaErrorStatus("cudaMalloc", cudaStatus, "cudacpy")) goto Error;


    cudaStatus = cudaMalloc((void**)&change, sizeof(int));
    if (cudaErrorStatus("cudaMalloc", cudaStatus, "change")) goto Error;



    cudaStatus = cudaMalloc((void**)&cudascx, CLUSTER_SIZE * sizeof(double));
    if (cudaErrorStatus("cudaMalloc", cudaStatus, "cudascx")) goto Error;

    cudaStatus = cudaMalloc((void**)&cudascy, CLUSTER_SIZE * sizeof(double));
    if (cudaErrorStatus("cudaMalloc", cudaStatus, "cudascy")) goto Error;

    cudaStatus = cudaMalloc((void**)&cudanc, CLUSTER_SIZE * sizeof(int));
    if (cudaErrorStatus("cudaMalloc", cudaStatus, "cudanc")) goto Error;


    // initialize sum of centroid and number of data of each centroid to 0.
    cudaMemset(cudascx, 0, CLUSTER_SIZE * sizeof(double));
    cudaMemset(cudascy, 0, CLUSTER_SIZE * sizeof(double));
    cudaMemset(cudanc, 0,  CLUSTER_SIZE * sizeof(int));


    // -----------------------------------------
    
   
    DATASET_PATH = "Datasets/dataset/ds.txt";
    loadDataset(DATASET_PATH, x, y, c);

    cout << "Finish loading data.." << endl;

    // copia del dataset nella gpu
  
    cudaStatus = cudaMemcpy(cudax, x, DATASET_SIZE * sizeof(double), cudaMemcpyHostToDevice);
    if (cudaErrorStatus("cudaMemcpy", cudaStatus, "x->cudax")) goto Error;

    cudaStatus = cudaMemcpy(cuday, y, DATASET_SIZE * sizeof(double), cudaMemcpyHostToDevice);
    if (cudaErrorStatus("cudaMemcpy", cudaStatus, "y->cuday")) goto Error;

   
    // -----------------------------------------------------


    // generating random centroid for the first step of the method
    cout << "Generating first " << CLUSTER_SIZE << " centroids.." << endl;


    
    randomCentroidsCuda <<< (CLUSTER_SIZE+32)/32, 32 >> > (cudacpx, cudacpy, cudax, cuday, time(NULL));


    cudaStatus = cudaGetLastError();
    if (cudaErrorStatus("randomCentroidCuda", cudaStatus, cudaGetErrorString(cudaStatus))) goto Error;

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

        //updateCentroids<<<1,1>>>(cudac, cudax, cuday, cudacpx, cudacpy, change);
        
        calculateCentroidMeans<<<BLOCKDIM , WRAPDIM>>>(cudac, cudax, cuday, cudascx, cudascy, cudanc);
        cudaStatus = cudaGetLastError();
        if (cudaErrorStatus("calculateCentroidMeans ", cudaStatus, cudaGetErrorString(cudaStatus))) goto Error;


        

        



        cout << "End Updating centroids..." << endl;
        i++;

        /*
        cudaStatus = cudaMemcpy(isChange, change, sizeof(int), cudaMemcpyDeviceToHost);
       
        if (cudaStatus != cudaSuccess) {
            fprintf(stderr, "cudaMemcpy change failed!");
            goto Error;
        }*/

    }

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
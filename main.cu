


#include"Intestazione.h"

//#include"kmeanscu.cuh"




int main()
{
    std::string   DATASET_PATH;

    // if the centroid are not changed then the method stops
    bool isChange = true;

    cout << "DATASET SIZE: " << DATASET_SIZE << " CLUSTER SIZE: " << CLUSTER_SIZE << " ITERATIONS: " << endl;


    // declaring array for dataset point and for centroid points
    centroid_point  cpoints;
    static double  x[DATASET_SIZE];
    static double  y[DATASET_SIZE];
    static int     c[DATASET_SIZE];
    
    static double cpx[DATASET_SIZE];
    static double cpy[DATASET_SIZE];

    // initialize random seed
    srand(time(NULL));

  
    DATASET_PATH = "Datasets/dataset/ds.txt";
    loadDataset(DATASET_PATH, x, y, c);

    cout << "Finish loading data.." << endl;


    // generating random centroid for the first step of the method
    cout << "Generating first " << CLUSTER_SIZE << " centroids.." << endl;
    randomCentroids(cpx, cpy, x, y);
    cout << "Finish generating random centroids.." << endl;

    printClusterPoint(cpx, cpy);
    // funzione che calcola la distanza

    auto start = high_resolution_clock::now();

    int i = 0;
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

    auto stop = high_resolution_clock::now();
    auto duration = duration_cast<std::chrono::microseconds>(stop - start);
    cout << "Tempo: " << duration.count() << " micro_s" << endl;



    // printing the centroid after the kmeans methods
    printClusterPoint(cpx, cpy);

}
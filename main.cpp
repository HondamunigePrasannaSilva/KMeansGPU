#include <iostream>
#include <fstream>
#include <time.h>
#include <math.h>
#include <chrono>
#include<vector>
#include<string>
#include<algorithm>
#include"Intestazione.h"

//using namespace std;

using std::cout;
using std::endl;
using std::chrono::high_resolution_clock;
using std::chrono::duration_cast;

int main()
{

    std::ifstream myfile;
    std::ifstream myfilepath;
    std::string   line, x_s, y_s;
    std::string   DATASET_PATH, PARTITION_PATH;
    int  posC;

    // if the centroid are not changed then the method stops
    bool isChange = true;

    cout << "DATASET SIZE: " << DATASET_SIZE << " CLUSTER SIZE: " << CLUSTER_SIZE << " ITERATIONS: " << endl;


    // declaring array for dataset point and for centroid points
    centroid_point  cpoints;
    static double  x[DATASET_SIZE];
    static double  y[DATASET_SIZE];
    static int     c[DATASET_SIZE];
    static int     pa[DATASET_SIZE];

    //DATASET_PATH = "dataset/ds.txt";
    DATASET_PATH = "urban/urbanGb.txt";

    // initialize random seed
    srand(time(NULL));

    myfile.open(DATASET_PATH);

    cout << "Loading data from file to arrays.." << endl;

    for (int i = 0; i < DATASET_SIZE; i++)
    {
        // get line with new line delimiter
        getline(myfile, line, '\n');

        // split the line in two part using the comma delimiter
        posC = line.find_first_of(',');
        x_s = line.substr(0, posC);
        y_s = line.substr(posC + 1);
        //parsing from string to double and filling to the array of struct
        x[i] = stod(x_s);
        y[i] = stod(y_s);
        c[i] = -1;

    }

    myfile.close();
    cout << "Finish loading data.." << endl;

    // generating random centroid for the first step of the method
    cout << "Generating first " << CLUSTER_SIZE << " centroids.." << endl;
    randomCentroids(cpoints, x, y);
    cout << "Finish generating random centroids.." << endl;

    printClusterPoint(cpoints);
    // funzione che calcola la distanza

    auto start = high_resolution_clock::now();

    int i = 0;
    while (isChange == true)
    {
        cout << "Calculating cluster cycle: " << i + 1 << "..." << endl;
        calculateDistance(x, y, cpoints, c);
        cout << "End calculating cluster cycle: " << i + 1 << endl;

        cout << "Updating centroids..." << endl;
        isChange = updateCentroids(c, x, y, cpoints);
        cout << "End Updating centroids..." << endl;
        i++;

    }

    auto stop = high_resolution_clock::now();
    auto duration = duration_cast<std::chrono::microseconds>(stop - start);
    cout << "Tempo: " << duration.count() << " micro_s" << endl;

    // printing the centroid after the kmeans methods

    printClusterPoint(cpoints);


}

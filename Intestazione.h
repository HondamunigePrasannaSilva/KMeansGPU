#ifndef INTESTAZIONE


#include <iostream>
#include <fstream>
#include <time.h>
#include <math.h>
#include <chrono>

#include<string>
#include<algorithm>

#include "defines.h"

#include "kmeanscu.cuh"

using std::cout;
using std::endl;
using std::chrono::high_resolution_clock;
using std::chrono::duration_cast;


void printClusterPoint(double cp_x[], double cp_y[]);

void loadDataset(std::string DATA_PATH, double x[], double y[], int c[]);

void printClusterPoint(double cp_x[], double cp_y[])
{
    for (int i = 0; i < CLUSTER_SIZE; i++)
    {
        cout << cp_x[i] << "," << cp_y[i] << endl;

    }
}

void loadDataset(std::string DATASET_PATH, double x[], double y[], int c[])
{
    std::ifstream myfile;
    std::ifstream myfilepath;
    std::string   line, x_s, y_s;
    
    int  posC;

    myfile.open(DATASET_PATH);

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
}

bool cudaErrorStatus(std::string cmd, cudaError_t cudaStatus, std::string var_name)
{
    if (cudaStatus != cudaSuccess) 
    {
        fprintf(stderr, "cudaMalloc vect_x failed!");
        cout << stderr << " " << cmd << " " << var_name << " FAILED!" << endl;
        return true;
    }
    return false;
}


#define INTESTAZIONE
#endif // !INTESTAZIONE


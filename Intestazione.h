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

bool cudaErrorStatus(std::string cmd, cudaError_t cudaStatus, std::string var_name);

void saveCSV(double x[], double y[], int c[]);

void randomCentroids(double cp_x[], double cp_y[], double* vect_x, double* vect_y);


#define INTESTAZIONE
#endif // !INTESTAZIONE


#ifndef INTESTAZIONE


#include <iostream>
#include <fstream>
#include <time.h>
#include <math.h>
#include <chrono>
#include<vector>
#include<string>
#include<algorithm>

#include "defines.h"



using std::cout;
using std::endl;
using std::chrono::high_resolution_clock;
using std::chrono::duration_cast;
using std::vector;

void randomCentroids(double cp_x[], double cp_y[], double vect_x[], double vect_y[]);
void printClusterPoint(double cp_x[], double cp_y[]);
double distance(double x1_point, double y1_point, double x2_point, double y2_point);
void loadDataset(std::string DATA_PATH, double x[], double y[], int c[]);
void calculateDistance(double vect_x[], double vect_y[], double cp_x[], double cp_y[], int c_vect[]);


bool updateCentroids(int vect_c[], double vect_x[], double vect_y[], double cp_x[], double cp_y[]);



void randomCentroids(double cp_x[], double cp_y[], double vect_x[], double vect_y[])
{
    double max_x, min_x, max_y, min_y;

    // calculating max and min of the points to generate random centroids

    max_x = *std::max_element(vect_x, vect_x + DATASET_SIZE);
    max_y = *std::max_element(vect_y, vect_y + DATASET_SIZE);
    min_x = *std::min_element(vect_x, vect_x + DATASET_SIZE);
    min_y = *std::min_element(vect_y, vect_y + DATASET_SIZE);
    cout << "max_x: " << max_x << "max_y: " << max_y << "min_x: " << min_x << "min_y: " << min_y << endl;
    for (int i = 0; i < CLUSTER_SIZE; i++)
    {
        cp_x[i] = (max_x - min_x) * ((double)rand() / (double)RAND_MAX) + min_x;
        cp_y[i] = (max_y - min_y) * ((double)rand() / (double)RAND_MAX) + min_y;
    }
}

void printClusterPoint(double cp_x[], double cp_y[])
{
    for (int i = 0; i < CLUSTER_SIZE; i++)
    {
        cout << cp_x[i] << "," << cp_y[i] << endl;

    }
}

void calculateDistance(double vect_x[], double vect_y[], double cp_x[], double cp_y[], int c_vect[])
{
    double dist, temp;
    int cluster_class;

    for (int i = 0; i < DATASET_SIZE; i++)
    {
        // calculating distance between dataset point and centroid
        // selecting the centroid with minium distance

        dist = distance(vect_x[i], vect_y[i], cp_x[0], cp_y[0]);
        cluster_class = 0;

        for (int j = 1; j < CLUSTER_SIZE; j++)
        {
            temp = distance(vect_x[i], vect_y[i], cp_x[j], cp_y[j]);
            if (dist > temp) // looking for the minimum distance given a point
            {
                cluster_class = j;
                dist = temp;
            }
        }

        // updating to the beloging cluster 
        c_vect[i] = cluster_class;

    }


}

double distance(double x1_point, double y1_point, double x2_point, double y2_point)
{
    return sqrt(pow(x1_point - x2_point, 2) + pow(y1_point - y2_point, 2));
    //return (abs(x1_point-x2_point)+abs(y1_point-y2_point));
}

bool updateCentroids(int vect_c[], double vect_x[], double vect_y[], double cp_x[], double cp_y[])
{
    /*
        i centroidi aggiornati non sono punti del dataset
    */

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
    if (count > 0.7 * CLUSTER_SIZE)
        return false;

    return true;
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

#define INTESTAZIONE
#endif // !INTESTAZIONE


#include "defines.h"
#include "Intestazione.h"

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

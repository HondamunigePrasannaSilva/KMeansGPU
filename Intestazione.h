

#define DATASET_SIZE    360177
#define CLUSTER_SIZE    469
#define THRESHOLD       0.0001


struct centroid_point
{
    double x_c[CLUSTER_SIZE];
    double y_c[CLUSTER_SIZE];
};

void randomCentroids(centroid_point& cp, double vect_x[], double vect_y[]);
bool updateCentroids(int vect_c[], double vect_x[], double vect_y[], centroid_point& cp);
void calculateDistance(double vect_x[], double vect_y[], centroid_point cp, int c_vect[]);
double distance(double x1_point, double y1_point, double x2_point, double y2_point);
void printClusterPoint(centroid_point cp);




void randomCentroids(centroid_point& cp, double vect_x[], double vect_y[])
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
        cp.x_c[i] = (max_x - min_x) * ((double)rand() / (double)RAND_MAX) + min_x;
        cp.y_c[i] = (max_y - min_y) * ((double)rand() / (double)RAND_MAX) + min_y;
    }

}

void printClusterPoint(centroid_point cp)
{
    for (int i = 0; i < CLUSTER_SIZE; i++)
    {
        cout << cp.x_c[i] << "," << cp.y_c[i] << endl;
    }
}

void calculateDistance(double vect_x[], double vect_y[], centroid_point cp, int c_vect[])
{
    double dist, temp;
    int cluster_class;

    for (int i = 0; i < DATASET_SIZE; i++)
    {
        // calculating distance between dataset point and centroid
        // selecting the centroid with minium distance

        dist = distance(vect_x[i], vect_y[i], cp.x_c[0], cp.y_c[0]);
        cluster_class = 0;

        for (int j = 1; j < CLUSTER_SIZE; j++)
        {
            temp = distance(vect_x[i], vect_y[i], cp.x_c[j], cp.y_c[j]);
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

bool updateCentroids(int vect_c[], double vect_x[], double vect_y[], centroid_point& cp)
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
        double cond = distance(cp.x_c[i], cp.y_c[i], update_x, update_y);


        if (cond <= THRESHOLD)
            count++;

        // updating centroids
        if (num_points != 0 && cond > THRESHOLD)
        {
            cp.x_c[i] = update_x;
            cp.y_c[i] = update_y;
        }
    }
    if (count > 0.7 * CLUSTER_SIZE)
        return false;

    return true;
}
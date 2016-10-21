#include <iostream>
#include <vector>
#include <cstdlib>
#include <ctime>
#include <algorithm>

using namespace std;

int main() {
    srand((unsigned)time(0));

    const int dataSetSize = 1000000;
    vector<int> dataSet;
    for(int i = 0; i < dataSetSize; ++i) {
        dataSet.push_back(rand() % dataSetSize);
    }

    // Copy the vector
    vector<int> sorted;
    sorted.reserve(dataSet.size());
    sorted = dataSet;
    std::sort(sorted.begin(), sorted.end());

    for(vector<int>::iterator it = sorted.begin(); it != sorted.end(); ++it) {
        cout << *it << endl;
    }

    return 0;
}
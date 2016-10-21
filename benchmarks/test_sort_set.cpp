#include <iostream>
#include <vector>
#include <set>
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

    set<int> sorted;
    for(vector<int>::iterator it = dataSet.begin(); it != dataSet.end(); ++it) {
        sorted.insert(*it);
    }

    for(set<int>::iterator it = sorted.begin(); it != sorted.end(); ++it) {
        cout << *it << endl;
    }

    return 0;
}
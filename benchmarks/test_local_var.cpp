#include <iostream>
#include <vector>

using namespace std;

bool isEven(int i) {
    // Not optimal solution using local vars.
    /*bool ret = false;
    if(i%2 == 0) {
        ret = true;
    }

    return ret;*/

    /*
    real  0m51.568s
    user  0m45.232s
    sys   0m5.685s
    */

    return i%2 == 0;

    /*
    real    0m49.817s
    user    0m44.407s
    sys     0m4.877s
    */
}

int main() {
    const int dataSetSize = 1000000000;
    vector<int> dataSet;
    for(int i = 0; i < dataSetSize; ++i) {
        dataSet.push_back(i);
    }

    vector<int> evens;
    std::remove_copy_if(dataSet.begin(), dataSet.end(), std::back_inserter(evens), isEven);

    cout << evens.size() <<  " even numbers." << endl;

    return 0;
}
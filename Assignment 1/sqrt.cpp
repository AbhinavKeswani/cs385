/*******************************************************************************
 * Author      : Abhinav Keswani
 * Pledge      : I pledge my honor that I have abided by the Stevens Honor System.
 * Date        : 9/8/2026
 * Description : Compute square root using Newton's method.
 ******************************************************************************/

#include <iostream>
#include <iomanip>
#include <limits>
#include <sstream>
#include <cmath>


double sqrt(double num, double epsilon) {

    if (num < 0) {
        return std::numeric_limits<double>::quiet_NaN();
    }

  
    if (num == 0 || num == 1) {
        return num;
    }

    
    double last_guess = num;
    double next_guess = (last_guess + (num / last_guess)) / 2.0;
    
    while (std::abs(last_guess - next_guess) > epsilon) {
        last_guess = next_guess;
        next_guess = (last_guess + (num / last_guess)) / 2.0;
    }

    return next_guess;
}

int main(int argc, char* argv[]) {

    if (argc < 2 || argc > 3) {
        std::cerr << "Usage: " << argv[0] << " <value> [epsilon]" << std::endl;
        return 1;
    }

    double value;
    double epsilon = 1e-7;

    std::istringstream iss_val(argv[1]);
    if (!(iss_val >> value)) {
        std::cerr << "Error: Value argument must be a double." << std::endl;
        return 1;
    }

    if (argc == 3) {
        std::istringstream iss_eps(argv[2]);
        if (!(iss_eps >> epsilon) || epsilon <= 0) {
            std::cerr << "Error: Epsilon argument must be a positive double." << std::endl;
            return 1;
        }
    }

    std::cout << std::fixed << std::setprecision(8) << sqrt(value, epsilon) << std::endl;

    return 0;
}

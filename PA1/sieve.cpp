/*******************************************************************************
 * Name        : sieve.cpp
 * Author      : Abhinav Keswani    
 * Date        : 9/18/2026
 * Description : Sieve of Eratosthenes
 * Pledge      : I pledge my honor that I have abided by the Stevens Honor System.
 ******************************************************************************/
#include <cmath>
#include <iomanip>
#include <iostream>
#include <sstream>

using namespace std;

class PrimesSieve {
public:
    PrimesSieve(int limit);

    ~PrimesSieve() {
        delete [] is_prime_;
    }

    void display_primes() const;

private:
    // Instance variables
    bool * const is_prime_;
    const int limit_;
    int num_primes_, max_prime_;

    // Method declarations
    void sieve();
    static int num_digits(int num);
};

PrimesSieve::PrimesSieve(int limit) :
        is_prime_{new bool[limit + 1]}, limit_{limit} {
    sieve();
}

void PrimesSieve::display_primes() const {
    // TODO: write code to display the primes in the format specified in the
    // requirements document.
    const int max_prime_width = num_digits(max_prime_),
              primes_per_row = 80 / (max_prime_width + 1);

    cout << "Number of primes found: " << num_primes_ << endl;
    cout << "Primes up to " << limit_ << ":" << endl;

    int count = 0;
    for (int i = 2; i <= limit_; i++) {
        if (is_prime_[i] == true) {
            count++;
            if (num_primes_ <= primes_per_row) {
                if (count == 1) {
                    cout << i;
                } else {
                    cout << " " << i;
                }
            } else {
                cout << setw(max_prime_width) << i;
                if (count % primes_per_row == 0 && count != num_primes_) {
                    cout << endl;
                } else if (count != num_primes_) {
                    cout << " ";
                }
            }
        }
    }
    cout << endl;
}

void PrimesSieve::sieve() {
    // TODO: write sieve algorithm
    // All instance variables must be initialized by the end of this method.
    is_prime_[0] = false;
    is_prime_[1] = false;
    for (int i = 2; i <= limit_; i++) {
        is_prime_[i] = true;
    }

    for (int i = 2; i <= sqrt(limit_); i++) {
        if (is_prime_[i] == true) {
            for (int j = i * i; j <= limit_; j = j + i) {
                is_prime_[j] = false;
            }
        }
    }

    num_primes_ = 0;
    max_prime_ = 0;
    for (int i = 2; i <= limit_; i++) {
        if (is_prime_[i] == true) {
            num_primes_++;
            max_prime_ = i;
        }
    }
}

int PrimesSieve::num_digits(int num) {
    // TODO: write code to determine how many digits are in an integer
    // Hint: No strings are needed. Keep dividing by 10.
    int count = 0;
    while (num != 0) {
        count++;
        num = num / 10;
    }
    return count;
}

int main() {
    cout << "**************************** " <<  "Sieve of Eratosthenes" <<
            " ****************************" << endl;
    cout << "Search for primes up to: ";
    string limit_str;
    cin >> limit_str;
    int limit;

    // Use stringstream for conversion. Don't forget to #include <sstream>
    istringstream iss(limit_str);

    // Check for error.
    if ( !(iss >> limit) ) {
        cerr << "Error: Input is not an integer." << endl;
        return 1;
    }
    if (limit < 2) {
        cerr << "Error: Input must be an integer >= 2." << endl;
        return 1;
    }

    // TODO: write code that uses your class to produce the desired output.
    PrimesSieve sieve(limit);
    cout << endl;
    sieve.display_primes();
    return 0;
}

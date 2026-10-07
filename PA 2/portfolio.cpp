/*******************************************************************************
 * Name        : portfolio.cpp
 * Author      : Abhinav Keswani
 * Date        : 10/6/2026
 * Description : Finds the lowest-risk equally weighted portfolio of exactly k
 *               stocks by enumerating every k-stock portfolio three ways:
 *               looping over every mask, recursion, and Gosper's hack.
 *               A portfolio is an unsigned int: bit i is 1 iff stock i is held.
 * Pledge      : I pledge my honor that I have abided by the Stevens Honor System.
 ******************************************************************************/
#include <algorithm>
#include <cmath>
#include <fstream>
#include <iomanip>
#include <iostream>
#include <sstream>
#include <string>
#include <vector>

using namespace std;

/* ============================== STUDENT CODE ==============================
 * Fill in the ten functions below and the argument checking in main. Do not
 * change the function names or their parameters: the autograder calls them
 * exactly as they are written here. See Section 6 of the assignment.
 * ========================================================================= */

/* ----- Bit basics ----- */

// TODO: Returns true if stock i is in the portfolio, that is, if bit i is 1.
// Hint: the mask 1u << i has a single 1 bit, in position i.
bool holds(unsigned int portfolio, int i) {
    // Build a mask with a single 1 bit in position i and AND it with the
    // portfolio. The result is nonzero exactly when bit i is set.
    return (portfolio & (1u << i)) != 0;
}

// TODO: Returns the number of stocks in the portfolio (the number of 1 bits).
// Hint: p = p & (p - 1) clears the lowest 1 bit of p. Count how many times you
// can do that before p becomes 0. Compiler bit-counting builtins are not allowed.
int count_stocks(unsigned int portfolio) {
    // Each iteration clears the lowest 1 bit, so the loop runs once per held
    // stock instead of once per bit position.
    int count = 0;
    while (portfolio != 0) {
        portfolio = portfolio & (portfolio - 1);
        ++count;
    }
    return count;
}

// TODO: Returns the indices of the held stocks, in increasing order.
// Hint: check the lowest bit, then shift the portfolio right by one, until the
// portfolio is 0. That way the loop stops after the highest held stock instead
// of always running 32 times.
vector<int> held_stocks(unsigned int portfolio) {
    vector<int> stocks;
    int i = 0;
    // Look at the lowest bit, then shift everything down by one. The loop
    // ends as soon as no 1 bits remain, i.e. right after the highest held stock.
    while (portfolio != 0) {
        if ((portfolio & 1u) != 0) {
            stocks.push_back(i);
        }
        portfolio = portfolio >> 1;
        ++i;
    }
    return stocks;
}

/* ----- Enumeration ----- */

// TODO: Method 1. Returns every portfolio of exactly k stocks chosen from
// stocks 0 through n - 1, in increasing numeric order, by trying every integer
// from 0 to 2^n - 1 and keeping the ones with exactly k stocks.
// This is the only function allowed to loop over every integer.
vector<unsigned int> all_masks(int n, int k) {
    vector<unsigned int> portfolios;
    // Every portfolio of n stocks is an integer in [0, 2^n), so counting up
    // visits them all in increasing order. Keep the ones with exactly k bits.
    const unsigned int limit = 1u << n;
    for (unsigned int mask = 0; mask < limit; ++mask) {
        if (count_stocks(mask) == k) {
            portfolios.push_back(mask);
        }
    }
    return portfolios;
}

// TODO: Method 2. Returns the same list, but built recursively, as in the
// stair climber problem. Every portfolio either
//   - leaves out stock n - 1: it is one of the portfolios of get_portfolios(n - 1, k), or
//   - holds stock n - 1: it is a portfolio of get_portfolios(n - 1, k - 1) with bit n - 1 set.
// Putting the portfolios that leave out stock n - 1 first gives increasing order.
// Base cases: k == 0 means one portfolio, the empty portfolio 0; n < k means none.
// This function must be recursive.
vector<unsigned int> get_portfolios(int n, int k) {
    // Base cases: choosing 0 stocks gives only the empty portfolio, and
    // choosing more stocks than are available gives nothing.
    if (k == 0) {
        return vector<unsigned int>{0};
    }
    if (n < k) {
        return vector<unsigned int>{};
    }
    // Portfolios without stock n - 1 come from the first n - 1 stocks alone.
    // They are all smaller than any portfolio with bit n - 1 set, so putting
    // them first keeps the list in increasing order.
    vector<unsigned int> result = get_portfolios(n - 1, k);
    // Portfolios with stock n - 1: choose k - 1 from the first n - 1 stocks,
    // then turn on bit n - 1.
    vector<unsigned int> with_last = get_portfolios(n - 1, k - 1);
    const unsigned int last = 1u << (n - 1);
    for (unsigned int p : with_last) {
        result.push_back(p | last);
    }
    return result;
}

// TODO: One step of Gosper's hack: returns the next larger integer with the
// same number of 1 bits as x. See Section 4 of the assignment.
unsigned int next_portfolio(unsigned int x) {
    unsigned int c = x & (~x + 1);           // lowest 1 bit of x
    unsigned int r = x + c;                  // carry through the lowest run of 1s
    // (r ^ x) marks the bits that changed: the lowest run of 1s plus the 0
    // just above it. Shifting right by 2 and dividing by c (a power of two,
    // so the division is another right shift) moves that run down to the
    // bottom with one fewer 1 bit, which is exactly what the carry removed.
    return (((r ^ x) >> 2) / c) | r;
}

// TODO: Method 3. Returns the same list again, starting at the smallest
// k-stock portfolio, (1u << k) - 1, and calling next_portfolio until the
// result is at least 1u << n.
vector<unsigned int> gosper_portfolios(int n, int k) {
    vector<unsigned int> portfolios;
    if (k > n) {
        return portfolios;
    }
    if (k == 0) {
        // Gosper's hack needs at least one 1 bit, so handle the empty
        // portfolio directly.
        portfolios.push_back(0);
        return portfolios;
    }
    const unsigned int limit = 1u << n;
    // Start with the k lowest bits set and step to the next larger integer
    // with k bits until we run past the largest n-bit value.
    for (unsigned int x = (1u << k) - 1; x < limit; x = next_portfolio(x)) {
        portfolios.push_back(x);
    }
    return portfolios;
}

/* ----- Risk ----- */

// TODO: Returns the variance of the equally weighted portfolio by looking at
// every pair (i, j) of the n stocks and adding cov[i][j] when both stocks are
// held. Divide the sum by k * k, where k is the number of stocks held.
double variance_all_pairs(unsigned int portfolio, const vector<vector<double>> &cov) {
    const int n = cov.size();
    const int k = count_stocks(portfolio);
    if (k == 0) {
        return 0.0;
    }
    double sum = 0.0;
    // Visit all n^2 pairs and only count the ones where both stocks are held.
    for (int i = 0; i < n; ++i) {
        if (!holds(portfolio, i)) {
            continue;
        }
        for (int j = 0; j < n; ++j) {
            if (holds(portfolio, j)) {
                sum += cov[i][j];
            }
        }
    }
    return sum / (static_cast<double>(k) * k);
}

// TODO: Returns the same value, but call held_stocks first and loop only over
// the pairs of stocks that are actually held.
double portfolio_variance(unsigned int portfolio, const vector<vector<double>> &cov) {
    vector<int> stocks = held_stocks(portfolio);
    const int k = stocks.size();
    if (k == 0) {
        return 0.0;
    }
    double sum = 0.0;
    // Only k^2 pairs to look at, since every pair of held stocks is relevant.
    for (int i : stocks) {
        for (int j : stocks) {
            sum += cov[i][j];
        }
    }
    return sum / (static_cast<double>(k) * k);
}

// TODO: Returns the portfolio with the smallest portfolio_variance. If two
// portfolios have the same variance, return the one that comes first.
unsigned int lowest_risk(const vector<unsigned int> &portfolios,
                         const vector<vector<double>> &cov) {
    unsigned int best = 0;
    double best_variance = 0.0;
    bool found = false;
    for (unsigned int p : portfolios) {
        double v = portfolio_variance(p, cov);
        // Strict less-than keeps the earliest portfolio when variances tie.
        if (!found || v < best_variance) {
            best = p;
            best_variance = v;
            found = true;
        }
    }
    return best;
}

/* ============================= PROVIDED CODE ============================== */

struct Stock {
    string ticker;
    string sector;
    vector<double> returns;   // daily returns, as decimals
};

// Reads one stock per line: ticker,sector,return1,return2,...
// Returns false if the file cannot be opened.
bool load_stocks(const string &path, vector<Stock> &stocks) {
    ifstream in(path);
    if (!in) {
        return false;
    }
    string line, cell;
    while (getline(in, line)) {
        if (line.empty()) {
            continue;
        }
        istringstream row(line);
        Stock s;
        getline(row, s.ticker, ',');
        getline(row, s.sector, ',');
        while (getline(row, cell, ',')) {
            s.returns.push_back(stod(cell));
        }
        stocks.push_back(s);
    }
    return true;
}

// Annualized sample covariance matrix of the daily returns.
vector<vector<double>> covariance(const vector<Stock> &stocks) {
    int n = stocks.size();
    int days = stocks[0].returns.size();
    vector<double> mean(n, 0);
    for (int i = 0; i < n; ++i) {
        for (double r : stocks[i].returns) {
            mean[i] += r;
        }
        mean[i] /= days;
    }
    vector<vector<double>> cov(n, vector<double>(n, 0));
    for (int i = 0; i < n; ++i) {
        for (int j = 0; j < n; ++j) {
            for (int t = 0; t < days; ++t) {
                cov[i][j] += (stocks[i].returns[t] - mean[i]) * (stocks[j].returns[t] - mean[j]);
            }
            cov[i][j] = cov[i][j] / (days - 1) * 252;
        }
    }
    return cov;
}

int num_digits(int num) {
    int digits = 1;
    while (num > 9) {
        num /= 10;
        ++digits;
    }
    return digits;
}

// Stock indices sorted from least to most volatile (ties keep file order).
vector<int> by_volatility(const vector<vector<double>> &cov) {
    vector<int> order(cov.size());
    for (size_t i = 0; i < order.size(); ++i) {
        order[i] = i;
    }
    stable_sort(order.begin(), order.end(),
                [&cov](int a, int b) { return cov[a][a] < cov[b][b]; });
    return order;
}

void print_volatility_table(const vector<Stock> &stocks, const vector<vector<double>> &cov,
                            const vector<int> &order) {
    size_t ticker_width = 0, sector_width = 0;
    for (const Stock &s : stocks) {
        ticker_width = max(ticker_width, s.ticker.size());
        sector_width = max(sector_width, s.sector.size());
    }
    const int rank_width = num_digits(stocks.size()) + 2;
    cout << "Stocks from least to most volatile:" << endl << fixed << setprecision(1);
    for (size_t r = 0; r < order.size(); ++r) {
        const Stock &s = stocks[order[r]];
        cout << setw(rank_width) << r + 1 << ". " << left << setw(ticker_width + 2) << s.ticker
             << setw(sector_width) << s.sector << right << setw(7)
             << 100 * sqrt(cov[order[r]][order[r]]) << '%' << endl;
    }
}

// Prints e.g. "Lowest-risk portfolio:    11.2%  DUK PG JNJ MSFT XOM".
void print_portfolio(const string &label, int label_width, unsigned int portfolio,
                     const vector<Stock> &stocks, const vector<vector<double>> &cov) {
    cout << left << setw(label_width) << label << right << fixed << setprecision(1) << setw(4)
         << 100 * sqrt(portfolio_variance(portfolio, cov)) << "% ";
    for (int i : held_stocks(portfolio)) {
        cout << ' ' << stocks[i].ticker;
    }
    cout << endl;
}

// True if the two variance functions agree (to a relative tolerance) on
// every portfolio.
bool variances_agree(const vector<unsigned int> &portfolios, const vector<vector<double>> &cov) {
    for (unsigned int p : portfolios) {
        double a = variance_all_pairs(p, cov), b = portfolio_variance(p, cov);
        if (fabs(a - b) > 1e-9 * max(fabs(a), fabs(b))) {
            return false;
        }
    }
    return true;
}

int main(int argc, char *argv[]) {
    /* ----- STUDENT CODE: check the command-line arguments -----
     * Handle Cases 1 to 3 of the assignment:
     *   - wrong number of arguments: print the usage message and return 1;
     *   - the file cannot be opened: print the error message and return 1
     *     (load_stocks below returns false when the file cannot be opened);
     *   - the number of stocks is not an integer between 1 and the number of
     *     stocks in the file: print the error message and return 1.
     * All three messages go to cerr. See Section 5 for their exact wording.
     *
     * When the arguments are good, the code below expects these variables:
     *   vector<Stock> stocks   the stocks read from the file
     *   const int n            the number of stocks in the file
     *   int k                  the number of stocks to hold
     */
    if (argc != 3) {
        cerr << "Usage: ./portfolio <stocks file> <number of stocks>" << endl;
        return 1;
    }

    vector<Stock> stocks;
    if (!load_stocks(argv[1], stocks)) {
        cerr << "Error: Cannot open file '" << argv[1] << "'." << endl;
        return 1;
    }
    const int n = stocks.size();

    // The count must be a whole number (no leftover characters) in [1, n].
    int k;
    istringstream iss(argv[2]);
    if (!(iss >> k) || !iss.eof() || k < 1 || k > n) {
        cerr << "Error: Number of stocks must be an integer between 1 and " << n << "." << endl;
        return 1;
    }

    /* ----- PROVIDED CODE ----- */
    if (n > 31) {
        cerr << "Error: At most 31 stocks are supported." << endl;
        return 1;
    }
    vector<vector<double>> cov = covariance(stocks);
    vector<int> order = by_volatility(cov);
    print_volatility_table(stocks, cov, order);

    vector<unsigned int> by_masks = all_masks(n, k);
    vector<unsigned int> by_recursion = get_portfolios(n, k);
    vector<unsigned int> by_gosper = gosper_portfolios(n, k);

    const string masks_label = "Loop over all " + to_string(1u << n) + " masks:";
    const int count_width = masks_label.size() + 2;
    cout << endl << "Choosing " << k << " of " << n << " stocks:" << endl << left;
    cout << "  " << setw(count_width) << masks_label << by_masks.size() << " portfolios" << endl;
    cout << "  " << setw(count_width) << "Recursion:" << by_recursion.size() << " portfolios" << endl;
    cout << "  " << setw(count_width) << "Gosper's hack:" << by_gosper.size() << " portfolios" << endl;
    cout << right;
    if (by_masks == by_recursion && by_recursion == by_gosper) {
        cout << "  All three lists match." << endl;
    } else {
        cout << "  The lists do NOT match." << endl;
    }
    if (variances_agree(by_recursion, cov)) {
        cout << "  Both variance functions agree." << endl;
    } else {
        cout << "  The variance functions do NOT agree." << endl;
    }

    // Baseline: the k least volatile stocks.
    unsigned int least_volatile = 0;
    for (int r = 0; r < k; ++r) {
        least_volatile |= 1u << order[r];
    }
    unsigned int best = lowest_risk(by_recursion, cov);

    const string naive_label = to_string(k) + (k == 1 ? " least volatile stock:" : " least volatile stocks:");
    const string best_label = "Lowest-risk portfolio:";
    const int label_width = max(naive_label.size(), best_label.size()) + 2;
    cout << endl;
    print_portfolio(naive_label, label_width, least_volatile, stocks, cov);
    print_portfolio(best_label, label_width, best, stocks, cov);
    return 0;
}

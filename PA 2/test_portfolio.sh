#!/bin/bash
################################################################################
# test_portfolio.sh - CS 385 Programming Assignment 2
#
# Run this from the folder that holds portfolio.cpp, stocks.csv and makefile:
#
#     bash test_portfolio.sh
#
# It checks your file, builds it with make, tests each function you wrote, and
# runs your finished program. To list every individual check, run:
#
#     VERBOSE=1 bash test_portfolio.sh
#
# The score below covers the code only. The written questions are graded
# separately.
################################################################################

targetfile=portfolio.cpp
datafile=stocks.csv
maxtime=10
command="./portfolio"
CXX=g++
CXXFLAGS="-g -std=c++17 -Wall -Werror -pedantic-errors -fmessage-length=0"

# Colors, but only when the output goes to a terminal.
if [ -t 1 ]; then
    BOLD=$'\033[1m'; DIM=$'\033[2m'; RED=$'\033[31m'; GREEN=$'\033[32m'
    YELLOW=$'\033[33m'; OFF=$'\033[0m'
else
    BOLD=""; DIM=""; RED=""; GREEN=""; YELLOW=""; OFF=""
fi
OK="${GREEN}ok${OFF}"
BAD="${RED}FAILED${OFF}"
WARN="${YELLOW}missing${OFF}"

line() {
    printf "%s\n" "${DIM}--------------------------------------------------------------------------${OFF}"
}

section() {
    echo
    printf "%s\n" "${BOLD}$1${OFF}"
    line
}

# row <label> <status>: prints the label, dots, then the status.
row() {
    local label="$1" status="$2" dots=$((56 - ${#1}))
    [ $dots -lt 2 ] && dots=2
    printf "  %s %s %s\n" "$label" "$(printf "%*s" $dots "" | tr ' ' '.')" "$status"
}

# detail <text>: an indented explanation under a row.
detail() {
    printf "       %s\n" "$1"
}

stop_here() {
    echo
    line
    printf "  %s\n" "${BOLD}Final score: score - penalties = 0 - 0 = 0${OFF}"
    exit 1
}

echo
printf "%s\n" "${BOLD}CS 385 Programming Assignment 2: the lowest-risk portfolio${OFF}"
printf "%s\n" "${DIM}test script - your own copy, run it as often as you like${OFF}"

section "Your files"
all_files=1
for f in "$targetfile" "$datafile" makefile; do
    if [ -f "$f" ]; then
        row "$f" "$OK"
    else
        row "$f" "$BAD"
        detail "Put $f in this folder (all three come from Canvas)."
        all_files=0
    fi
done
if [ $all_files -eq 0 ]; then
    stop_here
fi
for f in answers.txt AI_USAGE.txt; do
    if [ -f "$f" ]; then
        row "$f" "$OK"
    else
        row "$f" "$WARN"
        detail "Not needed to run these tests, but your zip file must contain it."
    fi
done

# Required by the Honor System
missing_name=0
if head -n 20 "$targetfile" | grep -Eiq "author.*[a-zA-Z]+"; then
    row "your name in the header" "$OK"
else
    row "your name in the header" "$BAD"
    detail "Fill in the Author line at the top of $targetfile (-5 points)."
    missing_name=1
fi

missing_pledge=0
if head -n 20 "$targetfile" | grep -Eiq "I.*pledge.*my.*honor.*that.*I.*have.*abided.*by.*the.*Stevens.*Honor.*System"; then
    row "Stevens pledge in the header" "$OK"
else
    row "Stevens pledge in the header" "$BAD"
    detail "Fill in the Pledge line at the top of $targetfile (-5 points)."
    missing_pledge=1
fi

# Restrictions (Section 7 of the assignment), checked with comments removed
stripped=$($CXX -fpreprocessed -dD -E -P "$targetfile" 2> /dev/null)
if [ -z "$stripped" ]; then
    stripped=$(cat "$targetfile")
fi
violations=()
grep -qE 'bitset' <<< "$stripped" && violations+=("std::bitset")
grep -qE 'vector[[:space:]]*<[[:space:]]*bool[[:space:]]*>' <<< "$stripped" && violations+=("vector<bool>")
grep -qE '__builtin_popcount' <<< "$stripped" && violations+=("__builtin_popcount")
grep -qE '__builtin_ctz' <<< "$stripped" && violations+=("__builtin_ctz")
grep -qE 'std::popcount|#include[[:space:]]*<bit>' <<< "$stripped" && violations+=("std::popcount")
if [ ${#violations[@]} -eq 0 ]; then
    row "only the allowed operations" "$OK"
else
    row "only the allowed operations" "$BAD"
    for v in "${violations[@]}"; do
        detail "Your code uses $v, which Section 7 does not allow."
    done
    detail "Submissions that break these rules lose points when they are graded."
fi

section "Building your program (make)"
build=$(make 2>&1)
if [ $? -ne 0 ]; then
    row "make" "$BAD"
    detail "Your program did not compile. Fix these errors first:"
    echo
    printf "%s\n" "$build" | head -n 30 | sed 's/^/       /'
    stop_here
fi
row "make" "$OK"
detail "No compiler warnings."

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

############################################################
# Function tests
#
# Your portfolio.cpp is compiled a second time with main renamed and linked
# with a test program that calls your functions directly. It is also compiled
# with -finstrument-functions so the tests can check that get_portfolios calls
# itself, gosper_portfolios calls next_portfolio, and portfolio_variance calls
# held_stocks.
############################################################
cat > "$tmpdir/harness.cpp" << 'HARNESS'
#include <bitset>
#include <cmath>
#include <fstream>
#include <functional>
#include <iostream>
#include <sstream>
#include <string>
#include <vector>

using namespace std;

// The required functions, with the signatures from the assignment.
bool holds(unsigned int portfolio, int i);
int count_stocks(unsigned int portfolio);
vector<int> held_stocks(unsigned int portfolio);
vector<unsigned int> all_masks(int n, int k);
vector<unsigned int> get_portfolios(int n, int k);
unsigned int next_portfolio(unsigned int x);
vector<unsigned int> gosper_portfolios(int n, int k);
double variance_all_pairs(unsigned int portfolio, const vector<vector<double>> &cov);
double portfolio_variance(unsigned int portfolio, const vector<vector<double>> &cov);
unsigned int lowest_risk(const vector<unsigned int> &portfolios, const vector<vector<double>> &cov);

// If one of your functions is missing or its signature differs from the
// assignment, the stand-in below is linked instead and every test that calls it
// fails with a message naming the expected signature.
struct Missing {
    string signature;
};
#define STAND_IN(signature) { throw Missing{signature}; }
__attribute__((weak)) bool holds(unsigned int, int)
    STAND_IN("bool holds(unsigned int portfolio, int i)")
__attribute__((weak)) int count_stocks(unsigned int)
    STAND_IN("int count_stocks(unsigned int portfolio)")
__attribute__((weak)) vector<int> held_stocks(unsigned int)
    STAND_IN("vector<int> held_stocks(unsigned int portfolio)")
__attribute__((weak)) vector<unsigned int> all_masks(int, int)
    STAND_IN("vector<unsigned int> all_masks(int n, int k)")
__attribute__((weak)) vector<unsigned int> get_portfolios(int, int)
    STAND_IN("vector<unsigned int> get_portfolios(int n, int k)")
__attribute__((weak)) unsigned int next_portfolio(unsigned int)
    STAND_IN("unsigned int next_portfolio(unsigned int x)")
__attribute__((weak)) vector<unsigned int> gosper_portfolios(int, int)
    STAND_IN("vector<unsigned int> gosper_portfolios(int n, int k)")
__attribute__((weak)) double variance_all_pairs(unsigned int, const vector<vector<double>> &)
    STAND_IN("double variance_all_pairs(unsigned int portfolio, const vector<vector<double>> &cov)")
__attribute__((weak)) double portfolio_variance(unsigned int, const vector<vector<double>> &)
    STAND_IN("double portfolio_variance(unsigned int portfolio, const vector<vector<double>> &cov)")
__attribute__((weak)) unsigned int lowest_risk(const vector<unsigned int> &, const vector<vector<double>> &)
    STAND_IN("unsigned int lowest_risk(const vector<unsigned int> &portfolios, const vector<vector<double>> &cov)")

// Call counters, updated on every entry to an instrumented function.
static long calls_get_portfolios = 0, calls_next_portfolio = 0, calls_held_stocks = 0;
extern "C" {
void __cyg_profile_func_enter(void *fn, void *site) __attribute__((no_instrument_function));
void __cyg_profile_func_exit(void *fn, void *site) __attribute__((no_instrument_function));
void __cyg_profile_func_enter(void *fn, void *) {
    if (fn == reinterpret_cast<void *>(&get_portfolios)) {
        ++calls_get_portfolios;
    } else if (fn == reinterpret_cast<void *>(&next_portfolio)) {
        ++calls_next_portfolio;
    } else if (fn == reinterpret_cast<void *>(&held_stocks)) {
        ++calls_held_stocks;
    }
}
void __cyg_profile_func_exit(void *, void *) {}
}

/* ----- Expected values for stocks.csv ----- */

struct KnownVariance {
    unsigned int portfolio;
    double variance;
};

// BEGIN EXPECTED VALUES FOR stocks.csv (generated; do not edit)
const vector<KnownVariance> known_variances = {
    {41033u, 0.012599080050850702},
    {91u, 0.019598014680187827},
    {8257u, 0.015568729889507221},
    {16384u, 0.19601673760238611},
    {786432u, 0.17153069624338771},
    {699050u, 0.016695258544454538},
    {349525u, 0.016667537424717552},
    {1048575u, 0.015234466804277629},
};
const vector<unsigned int> candidates = {
    9298u, 41034u, 196706u, 67204u, 299013u, 41042u, 8785u, 41033u,
    73809u, 41041u, 66833u, 91u, 2183u, 73801u, 280642u, 9297u,
    52736u, 788744u, 73810u, 33805u,
};
const unsigned int lowest_candidate = 41033u;
// END EXPECTED VALUES FOR stocks.csv

vector<vector<double>> load_cov(const string &path) {
    vector<vector<double>> returns;
    ifstream in(path);
    string line, cell;
    while (getline(in, line)) {
        if (line.empty()) continue;
        istringstream row(line);
        getline(row, cell, ',');
        getline(row, cell, ',');
        vector<double> r;
        while (getline(row, cell, ',')) r.push_back(stod(cell));
        returns.push_back(r);
    }
    size_t n = returns.size(), days = returns[0].size();
    vector<double> mean(n, 0);
    for (size_t i = 0; i < n; ++i) {
        for (double r : returns[i]) mean[i] += r;
        mean[i] /= days;
    }
    vector<vector<double>> cov(n, vector<double>(n, 0));
    for (size_t i = 0; i < n; ++i)
        for (size_t j = 0; j < n; ++j) {
            for (size_t t = 0; t < days; ++t)
                cov[i][j] += (returns[i][t] - mean[i]) * (returns[j][t] - mean[j]);
            cov[i][j] = cov[i][j] / (days - 1) * 252;
        }
    return cov;
}

/* ----- Formatting and comparison ----- */

string bin(unsigned int x, int width) {
    return bitset<32>(x).to_string().substr(32 - width);
}

string show(const vector<unsigned int> &v, int width) {
    string s = "{";
    for (size_t i = 0; i < v.size(); ++i) s += (i ? ", " : "") + bin(v[i], width);
    return s + "}";
}

string show(const vector<int> &v) {
    string s = "{";
    for (size_t i = 0; i < v.size(); ++i) s += (i ? ", " : "") + to_string(v[i]);
    return s + "}";
}

string same_list(const vector<unsigned int> &got, const vector<unsigned int> &expected, int width) {
    if (got == expected) return "";
    if (got.size() <= 10 && expected.size() <= 10)
        return "returned " + show(got, width) + ", expected " + show(expected, width);
    if (got.size() != expected.size())
        return "returned " + to_string(got.size()) + " portfolios, expected " + to_string(expected.size());
    for (size_t i = 0; i < got.size(); ++i)
        if (got[i] != expected[i])
            return "position " + to_string(i) + " is " + bin(got[i], width) + ", expected " +
                   bin(expected[i], width);
    return "";
}

// Checks that a list contains every k-stock portfolio from n stocks in
// increasing order: every entry holds exactly k of the n stocks, the entries
// are strictly increasing, and there are `count` of them. Together these
// imply the list is complete.
string complete_list(const vector<unsigned int> &got, int n, int k, size_t count) {
    for (size_t i = 0; i < got.size(); ++i) {
        unsigned int x = got[i];
        if (x >= (1u << n))
            return "position " + to_string(i) + " is " + bin(x, 32) +
                   ", which holds a stock numbered " + to_string(n) + " or higher";
        if (bitset<32>(x).count() != static_cast<size_t>(k))
            return "position " + to_string(i) + " is " + bin(x, n) + ", which does not hold exactly " +
                   to_string(k) + " stocks";
        if (i > 0 && x <= got[i - 1])
            return "position " + to_string(i) + " is " + bin(x, n) +
                   ", which is not larger than the portfolio before it, " + bin(got[i - 1], n);
    }
    if (got.size() != count)
        return "returned " + to_string(got.size()) + " portfolios, expected " + to_string(count);
    return "";
}

string same_bool(bool got, bool expected) {
    return got == expected ? "" : string("returned ") + (got ? "true" : "false");
}

string same_int(long got, long expected) {
    return got == expected ? "" : "returned " + to_string(got) + ", expected " + to_string(expected);
}

string same_uint(unsigned int got, unsigned int expected, int width) {
    return got == expected ? "" : "returned " + bin(got, width) + ", expected " + bin(expected, width);
}

string same_double(double got, double expected) {
    if (fabs(got - expected) <= 1e-9 * fabs(expected)) return "";
    ostringstream out;
    out.precision(10);
    out << "returned " << got << ", expected " << expected;
    return out.str();
}

/* ----- Tests ----- */

struct Test {
    string description;
    function<string()> run;   // returns "" on success, otherwise what went wrong
};

// A small covariance matrix with easy-to-check answers.
const vector<vector<double>> small_cov = {{4, 1, 0}, {1, 9, -2}, {0, -2, 16}};
const vector<vector<double>> identity3 = {{1, 0, 0}, {0, 1, 0}, {0, 0, 1}};

vector<Test> list_tests(const string &name, function<vector<unsigned int>(int, int)> method) {
    vector<Test> t;
    t.push_back({name + "(4, 2) returns {0011, 0101, 0110, 1001, 1010, 1100}",
                 [=] { return same_list(method(4, 2), {3, 5, 6, 9, 10, 12}, 4); }});
    t.push_back({name + "(5, 3) returns the 10 portfolios in increasing order",
                 [=] { return same_list(method(5, 3), {7, 11, 13, 14, 19, 21, 22, 25, 26, 28}, 5); }});
    t.push_back({name + "(3, 3) returns {111}",
                 [=] { return same_list(method(3, 3), {7}, 3); }});
    t.push_back({name + "(1, 1) returns {1}",
                 [=] { return same_list(method(1, 1), {1}, 1); }});
    t.push_back({name + "(16, 5) returns all 4368 portfolios in increasing order",
                 [=] { return complete_list(method(16, 5), 16, 5, 4368); }});
    t.push_back({name + "(20, 5) returns all 15504 portfolios in increasing order",
                 [=] { return complete_list(method(20, 5), 20, 5, 15504); }});
    return t;
}

vector<Test> bits_tests() {
    vector<Test> t;
    t.push_back({"holds(73, 0) is true", [] { return same_bool(holds(73, 0), true); }});
    t.push_back({"holds(73, 1) is false", [] { return same_bool(holds(73, 1), false); }});
    t.push_back({"holds(73, 3) is true", [] { return same_bool(holds(73, 3), true); }});
    t.push_back({"holds(73, 6) is true", [] { return same_bool(holds(73, 6), true); }});
    t.push_back({"holds(73, 7) is false", [] { return same_bool(holds(73, 7), false); }});
    t.push_back({"holds(0, 0) is false", [] { return same_bool(holds(0, 0), false); }});
    t.push_back({"holds(2147483648, 31) is true (bit 31)",
                 [] { return same_bool(holds(0x80000000u, 31), true); }});
    t.push_back({"holds(2147483648, 30) is false",
                 [] { return same_bool(holds(0x80000000u, 30), false); }});
    t.push_back({"count_stocks(0) is 0", [] { return same_int(count_stocks(0), 0); }});
    t.push_back({"count_stocks(1) is 1", [] { return same_int(count_stocks(1), 1); }});
    t.push_back({"count_stocks(73) is 3", [] { return same_int(count_stocks(73), 3); }});
    t.push_back({"count_stocks(41033) is 5", [] { return same_int(count_stocks(41033), 5); }});
    t.push_back({"count_stocks(2147483648) is 1 (bit 31)",
                 [] { return same_int(count_stocks(0x80000000u), 1); }});
    t.push_back({"count_stocks(4294967295) is 32 (all bits)",
                 [] { return same_int(count_stocks(0xFFFFFFFFu), 32); }});
    return t;
}

vector<Test> held_tests() {
    vector<Test> t;
    auto check = [](unsigned int p, vector<int> expected) {
        return [=] {
            vector<int> got = held_stocks(p);
            return got == expected ? "" : "returned " + show(got) + ", expected " + show(expected);
        };
    };
    vector<int> all32;
    for (int i = 0; i < 32; ++i) all32.push_back(i);
    t.push_back({"held_stocks(0) is {}", check(0, {})});
    t.push_back({"held_stocks(1) is {0}", check(1, {0})});
    t.push_back({"held_stocks(73) is {0, 3, 6}", check(73, {0, 3, 6})});
    t.push_back({"held_stocks(41033) is {0, 3, 6, 13, 15}", check(41033, {0, 3, 6, 13, 15})});
    t.push_back({"held_stocks(2147483649) is {0, 31}", check(0x80000001u, {0, 31})});
    t.push_back({"held_stocks(4294967295) is {0, 1, ..., 31}", check(0xFFFFFFFFu, all32)});
    return t;
}

vector<Test> masks_tests() {
    vector<Test> t = list_tests("all_masks", all_masks);
    t.push_back({"all_masks(4, 0) returns {0000}", [] { return same_list(all_masks(4, 0), {0}, 4); }});
    t.push_back({"all_masks(3, 4) returns {}", [] { return same_list(all_masks(3, 4), {}, 3); }});
    return t;
}

vector<Test> recursion_tests() {
    vector<Test> t = list_tests("get_portfolios", get_portfolios);
    t.push_back({"get_portfolios(4, 0) returns {0000}",
                 [] { return same_list(get_portfolios(4, 0), {0}, 4); }});
    t.push_back({"get_portfolios(3, 4) returns {}",
                 [] { return same_list(get_portfolios(3, 4), {}, 3); }});
    t.push_back({"get_portfolios is recursive (it calls itself)", [] {
                     calls_get_portfolios = 0;
                     get_portfolios(6, 3);
                     return calls_get_portfolios > 1 ? ""
                            : "get_portfolios(6, 3) did not call get_portfolios again";
                 }});
    return t;
}

vector<Test> gosper_tests() {
    vector<Test> t;
    auto next = [](unsigned int x, unsigned int expected, int width) {
        return Test{"next_portfolio(" + bin(x, width) + ") is " + bin(expected, width),
                    [=] { return same_uint(next_portfolio(x), expected, width); }};
    };
    t.push_back(next(0b0011, 0b0101, 4));
    t.push_back(next(0b0101, 0b0110, 4));
    t.push_back(next(0b0110, 0b1001, 4));
    t.push_back(next(0b1100, 0b10001, 5));
    t.push_back(next(0b01110, 0b10011, 5));
    t.push_back(next(0b10110, 0b11001, 5));
    t.push_back(next(0b1, 0b10, 2));
    t.push_back(Test{"next_portfolio(2^30) is 2^31",
                     [] { return same_uint(next_portfolio(0x40000000u), 0x80000000u, 32); }});
    for (const Test &test : list_tests("gosper_portfolios", gosper_portfolios)) t.push_back(test);
    t.push_back({"gosper_portfolios(5, 5) returns {11111}",
                 [] { return same_list(gosper_portfolios(5, 5), {31}, 5); }});
    t.push_back({"gosper_portfolios calls next_portfolio", [] {
                     calls_next_portfolio = 0;
                     gosper_portfolios(6, 3);
                     return calls_next_portfolio >= 19 ? ""
                            : "gosper_portfolios(6, 3) called next_portfolio " +
                              to_string(calls_next_portfolio) + " times, expected at least 19";
                 }});
    return t;
}

vector<Test> variance_tests(const vector<vector<double>> &cov) {
    vector<Test> t;
    struct Case { unsigned int p; double expected; };
    // With small_cov: {0,1} -> (4+1+1+9)/4, {0,2} -> (4+16)/4, {0,1,2} -> 27/9, {1} -> 9.
    vector<Case> cases = {{0b011, 3.75}, {0b101, 5.0}, {0b111, 3.0}, {0b010, 9.0}};
    for (const Case &c : cases) {
        ostringstream e;
        e << c.expected;
        t.push_back({"variance_all_pairs(" + bin(c.p, 3) + ", small matrix) is " + e.str(),
                     [=] { return same_double(variance_all_pairs(c.p, small_cov), c.expected); }});
        t.push_back({"portfolio_variance(" + bin(c.p, 3) + ", small matrix) is " + e.str(),
                     [=] { return same_double(portfolio_variance(c.p, small_cov), c.expected); }});
    }
    auto known = [cov](function<double(unsigned int, const vector<vector<double>> &)> f) {
        return [=] {
            for (const KnownVariance &kv : known_variances) {
                string r = same_double(f(kv.portfolio, cov), kv.variance);
                if (!r.empty()) return "for portfolio " + bin(kv.portfolio, 20) + " " + r;
            }
            return string();
        };
    };
    const string count = to_string(known_variances.size());
    t.push_back({"variance_all_pairs is correct for " + count + " portfolios from stocks.csv",
                 known(variance_all_pairs)});
    t.push_back({"portfolio_variance is correct for " + count + " portfolios from stocks.csv",
                 known(portfolio_variance)});
    t.push_back({"portfolio_variance calls held_stocks", [] {
                     calls_held_stocks = 0;
                     portfolio_variance(0b011, small_cov);
                     return calls_held_stocks > 0 ? "" : "held_stocks was not called";
                 }});
    return t;
}

vector<Test> lowest_tests(const vector<vector<double>> &cov) {
    vector<Test> t;
    t.push_back({"lowest_risk({011, 101, 110}, small matrix) is 011",
                 [] { return same_uint(lowest_risk({0b011, 0b101, 0b110}, small_cov), 0b011, 3); }});
    t.push_back({"lowest_risk({101}, small matrix) is 101",
                 [] { return same_uint(lowest_risk({0b101}, small_cov), 0b101, 3); }});
    t.push_back({"lowest_risk keeps the first portfolio when variances tie",
                 [] { return same_uint(lowest_risk({0b110, 0b011, 0b101}, identity3), 0b110, 3); }});
    const string count = to_string(candidates.size());
    t.push_back({"lowest_risk over " + count + " portfolios from stocks.csv", [cov] {
                     return same_uint(lowest_risk(candidates, cov), lowest_candidate, 20);
                 }});
    t.push_back({"lowest_risk over the same " + count + " portfolios in reverse order", [cov] {
                     vector<unsigned int> reversed(candidates.rbegin(), candidates.rend());
                     return same_uint(lowest_risk(reversed, cov), lowest_candidate, 20);
                 }});
    return t;
}

int main(int argc, char *argv[]) {
    if (argc != 3) {
        cerr << "Usage: " << argv[0] << " <group> <stocks file>" << endl;
        return 2;
    }
    string group = argv[1];
    vector<vector<double>> cov = load_cov(argv[2]);
    vector<Test> tests;
    if (group == "bits") tests = bits_tests();
    else if (group == "held") tests = held_tests();
    else if (group == "masks") tests = masks_tests();
    else if (group == "recursion") tests = recursion_tests();
    else if (group == "gosper") tests = gosper_tests();
    else if (group == "variance") tests = variance_tests(cov);
    else if (group == "lowest") tests = lowest_tests(cov);
    cout << "PLAN " << tests.size() << endl;
    for (const Test &test : tests) {
        string problem;
        try {
            problem = test.run();
        } catch (const Missing &m) {
            problem = m.signature + " was not found (check that your signature matches exactly)";
        } catch (const exception &e) {
            problem = string("threw an exception: ") + e.what();
        }
        if (problem.empty()) {
            cout << "PASS " << test.description << endl;
        } else {
            cout << "FAIL " << test.description << " -- " << problem << endl;
        }
    }
    return 0;
}
HARNESS

section "Your functions"
harness_ok=1
build=$( { $CXX $CXXFLAGS -Dmain=student_main -finstrument-functions -c "$targetfile" -o "$tmpdir/student.o" &&
           $CXX -std=c++17 -g -c "$tmpdir/harness.cpp" -o "$tmpdir/harness.o" &&
           $CXX "$tmpdir/student.o" "$tmpdir/harness.o" -o "$tmpdir/harness"; } 2>&1 )
if [ $? -ne 0 ]; then
    harness_ok=0
    row "building the function tests" "$BAD"
    detail "The tests could not be built:"
    printf "%s\n" "$build" | grep -E "error" | head -n 6 | sed 's/^/       /'
fi

code_score=0
summary_labels=()
summary_earned=()
summary_points=()

run_function_group() {
    local group="$1" title="$2" points="$3"
    local plan=0 passed=0 status line rest earned colour
    if [ $harness_ok -eq 0 ]; then
        row "$title" "$BAD"
        summary_labels+=("$title"); summary_earned+=(0); summary_points+=("$points")
        return
    fi
    (timeout --preserve-status "$maxtime" "$tmpdir/harness" "$group" "$datafile" > "$tmpdir/out" 2>&1
     echo $? > "$tmpdir/status") &> /dev/null
    status=$(cat "$tmpdir/status")
    while IFS= read -r line; do
        case "$line" in
            "PLAN "*) plan=${line#PLAN } ;;
            "PASS "*) ((passed++)) ;;
        esac
    done < "$tmpdir/out"
    if [ "$plan" -eq 0 ]; then
        earned=0
    else
        earned=$((points * passed / plan))
    fi
    if [ "$passed" -eq "$plan" ] && [ "$plan" -gt 0 ]; then
        colour="$GREEN"
    elif [ "$passed" -eq 0 ]; then
        colour="$RED"
    else
        colour="$YELLOW"
    fi
    row "$title" "$(printf "%s%2s of %-2s checks%s  %2s/%-2s points" "$colour" "$passed" "$plan" "$OFF" "$earned" "$points")"
    while IFS= read -r line; do
        case "$line" in
            "FAIL "*)
                rest=${line#FAIL }
                printf "       %s %s\n" "${RED}x${OFF}" "${rest%% -- *}"
                detail "  ${rest#* -- }"
                ;;
            "PASS "*)
                if [ -n "$VERBOSE" ]; then
                    printf "       %s %s\n" "${GREEN}+${OFF}" "${line#PASS }"
                fi
                ;;
        esac
    done < "$tmpdir/out"
    case $status in
        0)   ;;
        134) detail "${RED}Your program stopped early${OFF} (it aborted, for example an exception)." ;;
        136) detail "${RED}Your program stopped early${OFF} (arithmetic error such as dividing by zero)." ;;
        139) detail "${RED}Your program crashed${OFF} (segmentation fault)." ;;
        143) detail "${RED}Your program ran out of time${OFF} after $maxtime seconds (infinite loop?)." ;;
        *)   detail "${RED}Your program stopped early${OFF} (exit status $status)." ;;
    esac
    if [ "$status" -ne 0 ]; then
        detail "The checks after that point were not run and count as failed."
    fi
    code_score=$((code_score + earned))
    summary_labels+=("$title"); summary_earned+=("$earned"); summary_points+=("$points")
}

run_function_group bits      "holds, count_stocks"                      10
run_function_group held      "held_stocks"                               5
run_function_group masks     "all_masks"                                10
run_function_group recursion "get_portfolios (recursive, in order)"     20
run_function_group gosper    "next_portfolio, gosper_portfolios"        20
run_function_group variance  "variance_all_pairs, portfolio_variance"   10
run_function_group lowest    "lowest_risk"                               5

############################################################
# Program tests
############################################################
args_tests=0
args_right=0
output_tests=0
output_right=0
memory_problems=0

# run_program_test <args|output> <valgrind yes|no> <arguments> <expected output>
run_program_test() {
    local category="$1" use_valgrind="$2" args="$3" expected_output="$4"
    local outputfile statusfile start end status computed_output vgstatus label elapsed extra diffs

    if [ "$category" = "args" ]; then
        ((args_tests++))
    else
        ((output_tests++))
    fi
    label="$command $args"
    [ -z "$args" ] && label="$command (no arguments)"

    outputfile=$(mktemp)
    statusfile=$(mktemp)

    start=$(date +%s.%N)
    (timeout --preserve-status "$maxtime" $command $args < /dev/null &> "$outputfile"; echo $? > "$statusfile") &> /dev/null
    end=$(date +%s.%N)
    status=$(cat "$statusfile")

    case $status in
        135)
            row "$label" "$BAD"
            detail "Your program crashed (bus error)."
            ;;
        139)
            row "$label" "$BAD"
            detail "Your program crashed (segmentation fault)."
            ;;
        143)
            row "$label" "$BAD"
            detail "Your program ran out of time after $maxtime seconds (infinite loop?)."
            ;;
        *)
            # bash doesn't like null bytes so we substitute by hand.
            computed_output=$(sed -e 's/\x0/(NULL BYTE)/g' "$outputfile")
            if [ "$computed_output" = "$expected_output" ]; then
                if [ "$category" = "args" ]; then
                    ((args_right++))
                else
                    ((output_right++))
                fi
                elapsed=$(echo $start $end | awk '{printf "%.2fs", $2 - $1}')
                extra=""
                if [ "$use_valgrind" = "yes" ]; then
                    (valgrind --leak-check=full --error-exitcode=93 $command $args < /dev/null &> /dev/null; echo $? > "$statusfile") &> /dev/null
                    vgstatus=$(cat "$statusfile")
                    case $vgstatus in
                        127) extra="" ;;
                        $status) extra=", no memory errors" ;;
                        *) ((memory_problems++)); extra=", ${YELLOW}memory errors${OFF}" ;;
                    esac
                fi
                row "$label" "$OK ${DIM}($elapsed$extra)${OFF}"
                if [ -n "$extra" ] && [ "$extra" != ", no memory errors" ]; then
                    detail "valgrind found a memory problem here (-5 points, at most -15)."
                fi
            else
                row "$label" "$BAD"
                detail "Your output is not what was expected. Lines marked - are expected, + are yours:"
                diff <(printf "%s\n" "$expected_output") <(printf "%s\n" "$computed_output") \
                    | grep -E "^[<>]" | head -n 10 | sed -E "s/^<[ ]?/       ${RED}-${OFF} /; s/^>[ ]?/       ${GREEN}+${OFF} /"
                diffs=$(diff <(printf "%s\n" "$expected_output") <(printf "%s\n" "$computed_output") | grep -cE "^[<>]")
                if [ "$diffs" -gt 10 ]; then
                    detail "... and $((diffs - 10)) more lines are different."
                fi
                detail "Run this yourself to see the whole thing:  $label"
            fi
            ;;
    esac
    rm -f "$outputfile" "$statusfile"
}

section "Your program: command-line arguments"
run_program_test args yes "" "Usage: ./portfolio <stocks file> <number of stocks>"
run_program_test args yes "stocks.csv" "Usage: ./portfolio <stocks file> <number of stocks>"
run_program_test args yes "stocks.csv 5 6" "Usage: ./portfolio <stocks file> <number of stocks>"
run_program_test args yes "nosuchfile.csv 5" "Error: Cannot open file 'nosuchfile.csv'."
run_program_test args yes "stocks.csv five" "Error: Number of stocks must be an integer between 1 and 20."
run_program_test args yes "stocks.csv 0" "Error: Number of stocks must be an integer between 1 and 20."
run_program_test args yes "stocks.csv -3" "Error: Number of stocks must be an integer between 1 and 20."
run_program_test args yes "stocks.csv 21" "Error: Number of stocks must be an integer between 1 and 20."

args_score=$((5 * args_right / args_tests))
code_score=$((code_score + args_score))
summary_labels+=("checking the arguments in main"); summary_earned+=("$args_score"); summary_points+=(5)

section "Your program: full output"
run_program_test output yes "stocks.csv 1" "$(cat << 'EOF'
Stocks from least to most volatile:
   1. DUK   Utilities    17.0%
   2. SO    Utilities    17.6%
   3. KO    Staples      18.0%
   4. PG    Staples      19.1%
   5. JNJ   Healthcare   19.1%
   6. PEP   Staples      21.4%
   7. PFE   Healthcare   24.0%
   8. CVX   Energy       24.3%
   9. JPM   Financials   24.7%
  10. XOM   Energy       24.9%
  11. BAC   Financials   25.1%
  12. NEE   Utilities    25.2%
  13. MSFT  Technology   28.9%
  14. AAPL  Technology   28.9%
  15. MRK   Healthcare   29.0%
  16. COP   Energy       32.4%
  17. GS    Financials   32.7%
  18. AEM   Gold         42.0%
  19. NVDA  Technology   44.3%
  20. NEM   Gold         44.4%

Choosing 1 of 20 stocks:
  Loop over all 1048576 masks:  20 portfolios
  Recursion:                    20 portfolios
  Gosper's hack:                20 portfolios
  All three lists match.
  Both variance functions agree.

1 least volatile stock:  17.0%  DUK
Lowest-risk portfolio:   17.0%  DUK
EOF
)"
run_program_test output yes "stocks.csv 3" "$(cat << 'EOF'
Stocks from least to most volatile:
   1. DUK   Utilities    17.0%
   2. SO    Utilities    17.6%
   3. KO    Staples      18.0%
   4. PG    Staples      19.1%
   5. JNJ   Healthcare   19.1%
   6. PEP   Staples      21.4%
   7. PFE   Healthcare   24.0%
   8. CVX   Energy       24.3%
   9. JPM   Financials   24.7%
  10. XOM   Energy       24.9%
  11. BAC   Financials   25.1%
  12. NEE   Utilities    25.2%
  13. MSFT  Technology   28.9%
  14. AAPL  Technology   28.9%
  15. MRK   Healthcare   29.0%
  16. COP   Energy       32.4%
  17. GS    Financials   32.7%
  18. AEM   Gold         42.0%
  19. NVDA  Technology   44.3%
  20. NEM   Gold         44.4%

Choosing 3 of 20 stocks:
  Loop over all 1048576 masks:  1140 portfolios
  Recursion:                    1140 portfolios
  Gosper's hack:                1140 portfolios
  All three lists match.
  Both variance functions agree.

3 least volatile stocks:  14.9%  DUK SO KO
Lowest-risk portfolio:    12.5%  DUK JNJ MSFT
EOF
)"
run_program_test output no "stocks.csv 5" "$(cat << 'EOF'
Stocks from least to most volatile:
   1. DUK   Utilities    17.0%
   2. SO    Utilities    17.6%
   3. KO    Staples      18.0%
   4. PG    Staples      19.1%
   5. JNJ   Healthcare   19.1%
   6. PEP   Staples      21.4%
   7. PFE   Healthcare   24.0%
   8. CVX   Energy       24.3%
   9. JPM   Financials   24.7%
  10. XOM   Energy       24.9%
  11. BAC   Financials   25.1%
  12. NEE   Utilities    25.2%
  13. MSFT  Technology   28.9%
  14. AAPL  Technology   28.9%
  15. MRK   Healthcare   29.0%
  16. COP   Energy       32.4%
  17. GS    Financials   32.7%
  18. AEM   Gold         42.0%
  19. NVDA  Technology   44.3%
  20. NEM   Gold         44.4%

Choosing 5 of 20 stocks:
  Loop over all 1048576 masks:  15504 portfolios
  Recursion:                    15504 portfolios
  Gosper's hack:                15504 portfolios
  All three lists match.
  Both variance functions agree.

5 least volatile stocks:  14.0%  DUK SO PG KO JNJ
Lowest-risk portfolio:    11.2%  DUK PG JNJ MSFT XOM
EOF
)"
run_program_test output no "stocks.csv 10" "$(cat << 'EOF'
Stocks from least to most volatile:
   1. DUK   Utilities    17.0%
   2. SO    Utilities    17.6%
   3. KO    Staples      18.0%
   4. PG    Staples      19.1%
   5. JNJ   Healthcare   19.1%
   6. PEP   Staples      21.4%
   7. PFE   Healthcare   24.0%
   8. CVX   Energy       24.3%
   9. JPM   Financials   24.7%
  10. XOM   Energy       24.9%
  11. BAC   Financials   25.1%
  12. NEE   Utilities    25.2%
  13. MSFT  Technology   28.9%
  14. AAPL  Technology   28.9%
  15. MRK   Healthcare   29.0%
  16. COP   Energy       32.4%
  17. GS    Financials   32.7%
  18. AEM   Gold         42.0%
  19. NVDA  Technology   44.3%
  20. NEM   Gold         44.4%

Choosing 10 of 20 stocks:
  Loop over all 1048576 masks:  184756 portfolios
  Recursion:                    184756 portfolios
  Gosper's hack:                184756 portfolios
  All three lists match.
  Both variance functions agree.

10 least volatile stocks:  12.1%  DUK SO PG KO PEP JNJ PFE JPM XOM CVX
Lowest-risk portfolio:     10.6%  DUK SO PG KO PEP JNJ BAC MSFT NVDA XOM
EOF
)"
run_program_test output no "stocks.csv 20" "$(cat << 'EOF'
Stocks from least to most volatile:
   1. DUK   Utilities    17.0%
   2. SO    Utilities    17.6%
   3. KO    Staples      18.0%
   4. PG    Staples      19.1%
   5. JNJ   Healthcare   19.1%
   6. PEP   Staples      21.4%
   7. PFE   Healthcare   24.0%
   8. CVX   Energy       24.3%
   9. JPM   Financials   24.7%
  10. XOM   Energy       24.9%
  11. BAC   Financials   25.1%
  12. NEE   Utilities    25.2%
  13. MSFT  Technology   28.9%
  14. AAPL  Technology   28.9%
  15. MRK   Healthcare   29.0%
  16. COP   Energy       32.4%
  17. GS    Financials   32.7%
  18. AEM   Gold         42.0%
  19. NVDA  Technology   44.3%
  20. NEM   Gold         44.4%

Choosing 20 of 20 stocks:
  Loop over all 1048576 masks:  1 portfolios
  Recursion:                    1 portfolios
  Gosper's hack:                1 portfolios
  All three lists match.
  Both variance functions agree.

20 least volatile stocks:  12.3%  DUK SO NEE PG KO PEP JNJ MRK PFE JPM BAC GS AAPL MSFT NVDA XOM CVX COP NEM AEM
Lowest-risk portfolio:     12.3%  DUK SO NEE PG KO PEP JNJ MRK PFE JPM BAC GS AAPL MSFT NVDA XOM CVX COP NEM AEM
EOF
)"

############################################################
# Score
############################################################
section "Score"
for i in "${!summary_labels[@]}"; do
    row "${summary_labels[$i]}" "$(printf "%3d / %d" "${summary_earned[$i]}" "${summary_points[$i]}")"
done
row "full output tests (no points of their own)" "$(printf "%3d / %d" "$output_right" "$output_tests")"

penalty_notes=()
[ $missing_name -eq 1 ] && penalty_notes+=("your name is missing from the header (-5)")
[ $missing_pledge -eq 1 ] && penalty_notes+=("the Stevens pledge is missing from the header (-5)")
if [ $memory_problems -gt 3 ]; then
    memory_problems=3
fi
[ $memory_problems -gt 0 ] && penalty_notes+=("valgrind found memory problems in $memory_problems tests (-$((5 * memory_problems)))")

penalties=$((5 * missing_name + 5 * missing_pledge + 5 * memory_problems))
final_score=$((code_score - penalties))
if [ $final_score -lt 0 ]; then
    final_score=0
fi
if [ ${#penalty_notes[@]} -gt 0 ]; then
    row "penalties" "$(printf "%3d" "-$penalties")"
    for note in "${penalty_notes[@]}"; do
        detail "- $note"
    done
fi
line
row "${BOLD}your score${OFF}" "$(printf "%s%3d / 85%s" "$BOLD" "$final_score" "$OFF")"

echo
if [ $final_score -eq 85 ] && [ $output_right -eq $output_tests ] && [ ${#violations[@]} -eq 0 ]; then
    printf "  %s\n" "${GREEN}Everything passed.${OFF}"
else
    printf "  %s\n" "Work through the ${RED}FAILED${OFF} lines above, starting with the first one."
fi
if [ -z "$VERBOSE" ]; then
    printf "  %s\n" "${DIM}Run 'VERBOSE=1 bash test_portfolio.sh' to see every check, passed ones included.${OFF}"
fi
printf "  %s\n" "Do not forget answers.txt and AI_USAGE.txt in your zip file."
printf "  %s\n" "The written questions are worth another 15 points and are graded separately."
echo
printf "%s\n" "Final score: score - penalties = $code_score - $penalties = $final_score"

make clean > /dev/null 2>&1

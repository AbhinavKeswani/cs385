/*******************************************************************************
 * Filename : student.cpp
 * Author   : Dev Parikh
 * Version  : 1.0
 * Date     : September 13, 2025
 * Description: Print grades and info of students with GPA less than 1.0
 * Pledge   : I pledge my honor that I have abided by the Stevens Honor System
 ******************************************************************************/

#include <iostream>
#include <iomanip>
#include <vector>
#include <string>
using namespace std;

class Student {
private:
    string first_;
    string last_;
    float gpa_;
    int id_;

public:
    Student(string first, string last, float gpa, int id)
        : first_(first), last_(last), gpa_(gpa), id_(id) {}

    string full_name() const {
        return first_ + " " + last_;
    }

    int id() const {
        return id_;
    }

    float gpa() const {
        return gpa_;
    }

    void print_info() const {
        cout << fixed << setprecision(2);
        cout << full_name() << ", GPA: " << gpa_ << ", ID: " << id_ << endl;
    }
};

//Returns list of students lower than 1.0 GPA
vector<Student> find_failing_students(const vector<Student>& students) {
    vector<Student> failing;
    for (size_t i = 0; i < students.size(); i++) {
        if (students[i].gpa() < 1.0f) {
            failing.push_back(students[i]);
        }
    }
    return failing;
}

//Has each student on seperate line
void print_students(const vector<Student>& students) {
    for (size_t i = 0; i < students.size(); i++) {
        students[i].print_info();
    }
}

int main() {
    vector<Student> students;
    char another = 'Y';

    do {
        string firstname, lastname;
        float gpa;
        int id;

        cout << "Enter student's first name: ";
        cin >> firstname;

        cout << "Enter student's last name: ";
        cin >> lastname;

        //Checks range for GPA
        gpa = -1.0f;
        while (gpa < 0.0f || gpa > 4.0f) {
            cout << "Enter student's GPA (0.0-4.0): ";
            cin >> gpa;
        }

        cout << "Enter student's ID: ";
        cin >> id;

        students.push_back(Student(firstname, lastname, gpa, id));

        cout << "Add another student to database (Y/N)? ";
        cin >> another;
    } while (another == 'Y' || another == 'y');

    cout << "\nAll students:\n";
    print_students(students);

    cout << "\nFailing students:";
    vector<Student> failing = find_failing_students(students);
    if (failing.empty()) {
        cout << " None\n";
    } else {
        cout << endl;
        print_students(failing);
    }

    return 0;
}

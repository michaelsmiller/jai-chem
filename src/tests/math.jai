validate_matrix_code :: () {
  perform_test ("read_matrix() works correctly", #code {
    s :: #string DONE
      5 6 7
      2 4 1
      8 3 9
    DONE;

    matrix := read_matrix(s);
    // corners
    check(get(*matrix, 0, 0) == 5, "Top-left element is wrong");
    check(get(*matrix, 2, 0) == 8, "Bottom-left element is wrong");
    check(get(*matrix, 0, 2) == 7, "Top-right element is wrong");
    check(get(*matrix, 2, 2) == 9, "Bottom-right element is wrong");
  });

  perform_test ("Matrix multiplication works", #code {
    a_string :: #string DONE
      1 2 3
      4 5 6
      7 8 9
      1 1 1
    DONE;
    b_string :: #string DONE
      0 1 2 1
      1 2 0 1
      0 2 1 1
    DONE;

    a := read_matrix(a_string);
    b := read_matrix(b_string);
    c := a * b;
    check(get(*c, 0, 0) == 2);
    check(get(*c, 3, 0) == 1);
    check(get(*c, 3, 3) == 3);
  });
}

#scope_file

#load "test_util.jai"; // perform_test, check
#import "math";

#import "Basic";

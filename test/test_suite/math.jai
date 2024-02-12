test_read_matrix :: () {
  test_print("read_matrix() works correctly");
  s :: #string DONE
    5 6 7
    2 4 1
    8 3 9
  DONE;

  matrix := read_matrix(s);
  // corners
  check(get(*matrix, 0, 0) == 5, message="Top-left element is wrong");
  check(get(*matrix, 2, 0) == 8, message="Bottom-left element is wrong");
  check(get(*matrix, 0, 2) == 7, message="Top-right element is wrong");
  check(get(*matrix, 2, 2) == 9, message="Bottom-right element is wrong");
} @Test


test_matrix_multiplication :: () {
  test_print("Matrix multiplication works");

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
} @Test

#scope_file

#import "math";
#import "check";

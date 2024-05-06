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


test_erf :: () {
  test_print("error function is same as libm");
  epsilon : f64 = 1.0E-14;

  libm :: #system_library "libm";
  erf_libm :: (x: f64) -> f64 #foreign libm "erf";

  check_eq(erf_libm(0), erf(0));
  x := 4.252411080786993;
  check_close(erf_libm(x), erf(x));

  // Checks consistency with libm on N values between -BOUND and BOUND
  N :: 10000;
  NUM_DOTS :: 10;
  BOUND :f64: 10;

  INTERVAL_SHOWN :: N / NUM_DOTS;
  for x, i: range(-BOUND, BOUND, n=N) {
    y := erf(x);
    y_ref := erf_libm(x);
    if i > 0 && i % INTERVAL_SHOWN == 0
      check_close(y_ref, y, epsilon=epsilon);
    else {
      diff := Math.abs(y - y_ref);
      if diff > epsilon check(false, message="Failed here somewhere");
    }
  }

} @Test


test_sqrt :: () {
  test_print("sqrt() is correct for float64");
  // one example, used to diagnose the issue of PI vs PI64
  t :f64: 18.083;
  x := Math.PI64 / (4.0 * t);
  x_ref :: 0.043432957108745694;
  check_close(x, x_ref, epsilon=1.0E-14);
} @Test


test_boys :: () {
  test_print("Boys function is accurate");
  f :: boys;
  epsilon :: 1.0E-14;
  MAX_T :: 20;
  // edge cases (m, t)
  check_close(f(0, 0), 1);
  check_close(f(1, 0), cast(f64)1 / 3);

  examples := read_data_file(tprint("%boys.dat", TEST_DATA_DIR));;
  for i : 0..examples.m-1 {
    x := get(*examples, i, 0);
    if Math.abs(x) > MAX_T
      continue;

    for j : 1..examples.n-1 {
      m := cast(s8)(j-1);
      y_ref := get(*examples, i, j);
      y := f(m, x);

      prefix := tprint("f_%(%): ", m, formatFloat(x, trailing_width=12));
      print_on_success := i > 0 && j == examples.n-1 && i % (examples.m / 4) == 0;
      // print_on_success := true;
      check_close(y, y_ref, print_on_success=print_on_success, prefix=prefix, epsilon=epsilon);
      // what
    }
  }
} @Test


test_double_factorial :: () {
  test_print("Double factorial (x!!)");
  Pair :: struct {
    x: s16;
    y: f64;
  }
  pairs := Pair.[
    .{0, 1},
    .{1, 1},
    .{-1, 1},
    .{2, 2},
    .{10, 3840},
    .{11, 10395},
  ];
  for pair: pairs
    check_eq_fancy(double_factorial(pair.x), pair.y);
} @Test


test_read_data :: () {
  test_print("Test read_data() test function");
  // path := TEST_DATA_DIR
  matrix := read_data_file(tprint("%test.dat", TEST_DATA_DIR));
  defer free(matrix);

  // make sure enough of the values are correct
  check_eq(matrix.m, 3);
  check_eq(matrix.n, 4);
  check_eq(get(*matrix, 0, 0), cast(f64)1);
  check_eq(get(*matrix, 1, 3), -2.7);
  check_eq(get(*matrix, 2, 3), 0.66);
} @Test


#scope_file

Math :: #import "Math";

#import "test_util";
#import "math";
#import "check";

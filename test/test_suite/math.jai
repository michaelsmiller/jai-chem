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


test_boys :: () {
  test_print("Boys function is accurate");
  // edge cases (m, t)
  check_close(boys_shavitt(0, 0), 1);
  check_close(boys_shavitt(1, 0), cast(f64)1 / 3);
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


#scope_file

Math :: #import "Math";

#import "math";
#import "check";

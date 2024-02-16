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
  Pair :: struct {
    x, y: f64;
  }
  epsilon : f64 = 1.0E-14;
  X := f64.[
    0, 0.2,  -0.2,  0.5,  1,   -1,  2.1, -2.1, 3, -3
    // .{-3,  -0.99997790950300141455862722387041767962015229291260075034}
  ];

  libm :: #system_library "libm";
  erf_libm :: (x: f64) -> f64 #foreign libm "erf";

  for x: X {
    y := erf(x);
    y_ref := erf_libm(x);
    check_close(y_ref, y, epsilon=epsilon);
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

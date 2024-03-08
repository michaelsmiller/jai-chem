boys :: (m : s8, t : f64) -> f64 {
  if t < MIN_T return boys_maclaurin(m, t);

  // @todo: find the closest grid point and expand accordingly
  // if t > get(BOYS_TABLE.data.t)
  else if t < MAX_T {
    // @todo: find the closest t value we have gridpoints for
    i_unrounded := (t - MIN_T) / DT;
    i := cast(int)i_unrounded;
    di := abs(cast(f64)i - i_unrounded);
    if abs(cast(f64)i + 1 - i_unrounded) < di i += 1;
    t0 := BOYS_TABLE.t_values[i];
    return boys_taylor_expand(*BOYS_TABLE, i, m, t);
  }

  // else {
  //   numerator := double_factorial(2*m-1);
  //   inv_denominator := exp(-cast(f64)(m+1));
  //   discriminant : f64 = PI64 * pow(t, -cast(float64)(2*m+1));
  //   return numerator * inv_denominator * sqrt(discriminant);
  // }

  else {
    fnt := sqrt(0.25 * PI64 / t) * erf(sqrt(t)); // f0(t)
    // print("\n%\n%\n%\n", formatFloat(sqrt(0.25 * PI64 / t), trailing_width=14), formatFloat(erf(sqrt(t)), trailing_width=14), formatFloat(fnt, trailing_width=14));
    exp_term := exp(-t);
    inv_denominator := 0.5 / t;
    for n: 0..m-1 {
      fnt = inv_denominator * ((2*n+1)*fnt - exp_term);
    }
    return fnt;
  }
}


double_factorial :: inline (x : s16) -> f64 {
  if x == 0 return 1;
  if x < 0 return 1;

  result := 1;
  y := x;
  while y > 0 {
    defer y-=2;
    result *= y;
  }
  return cast(f64)result;
}


#scope_file

BoysTable :: struct {
  dt : f64;
  data : Matrix;
  t_values : [NUM_VALUES] f64;
}

DT    : f64 : 0.02;
MIN_T : f64 : 1.6;
MAX_T : f64 : 18;
NUM_VALUES :: #run 1 + cast(int) ((MAX_T - MIN_T) / DT);
MAX_K      :: 10; // how many elements in series before convergence
MAX_M      :: 10; // The max order we care to compute


boys_maclaurin :: (m : s8, t : f64) -> f64 {
  numerator :f64 = 1;
  sum : f64 = 0; // summation starts at i=1
  for k: 0..30 {
    defer numerator *= -t;
    term := numerator / (factorial(cast(s16)k) * (2*m+2*k+1));
    sum += term;
  }

  Basic.assert(sum >= 0);
  return sum;
}

boys_taylor_expand :: (table : *BoysTable, i: int, m: s8, t1: f64) -> f64 {
  t0 := table.t_values[i];
  dt := t1 - t0;
  sum : f64 = 0;
  // expand to as many terms as we can
  max_k := table.data.m-1 - m;
  for k : 0..max_k {
    // @todo: make this more efficient
    fnt := get(*table.data, m+k, i);
    polynomial : f64 = pow(-dt, cast(f64)k);
    denominator := factorial(cast(s16)k);
    sum += fnt * polynomial / denominator;
  }
  return sum;
}

BOYS_TABLE :: #run () -> BoysTable {
  table : BoysTable = ---;
  table.dt = DT;
  table.data = create(MAX_M+MAX_K+1, NUM_VALUES);
  table.t_values[0] = MIN_T;
  for i: 1..NUM_VALUES-1 table.t_values[i] = table.t_values[i-1] + DT;

  for m : 0..table.data.m-1 {
    y := boys_maclaurin(cast(s8)m, MIN_T);
    set(*table.data, m, 0, y);
  }

  for i: 1..NUM_VALUES-1 {
    t := table.t_values[i];

    f0t := boys_taylor_expand(*table, i-1, 0, t);
    set(*table.data, 0, i, f0t);

    fmt := f0t;
    half_inv_t := 0.5 / t;
    for m: 0..table.data.m-2 {
      // upward recursion (stable for values of t this large, so should be okay)
      fmt = half_inv_t * (fmt * (2*m+1) - exp(-t));
      set(*table.data, m+1, i, fmt);
    }
  }

  return table;
}();


factorial :: inline (x : s16) -> f64 {
  if x == 0 return 1;
  if x < 0 return 0;

  result := 1;
  for y: 1..x result *= y;
  return cast(f64)result;
}




#import "constants";
#import,file "erf.jai";

#import "Math";
Basic :: #import "Basic";

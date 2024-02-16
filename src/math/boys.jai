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

boys_shavitt :: (m : s8, t : f64, epsilon : f64 = 1.0E-6) -> f64 {

  Basic.assert(t >= 0);
  Basic.assert(m >= 0);
  if t == 0 {
    return cast(f64)1 / (2 * m + 1);
  }
  else if m == 0 {
    return sqrt(0.25 * PI / t) * erf(sqrt(t));
  }

  // large t
  large_approximation :: (t : f64, m: s8) -> f64 {
    numerator := double_factorial(2*m-1);
    inv_denominator := exp(-cast(f64)(m+1));
    discriminant : f64 = PI * pow(t, -cast(float64)(2*m+1));
    return numerator * inv_denominator * sqrt(discriminant);
  }

  if t > 18
    return large_approximation(t, m);

  // small t
  small_approximation :: (m: s8, t: f64, epsilon: f64) -> f64 {
    numerator :f64= 1;
    k_factorial :f64= 1;
    sum : f64 = cast(f64)1 / cast(f64)(2*m+1); // summation starts at i=1
    for k: 1..10 {
      numerator *= -t;
      k_factorial *= k;

      term := numerator / (k_factorial * (2*m+2*k+1));
      sum += term;
      if abs(term) < epsilon break;
    }
    return sum;
  }
  result := small_approximation(m, t, epsilon);

  Basic.assert(result > 0);
  return result;
}
#scope_file

#import "constants";
#import,file "erf.jai";

#import "Math";
Basic :: #import "Basic";

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

erf_power :: (x: f64, epsilon : f64 = 1.0E-10) -> f64 {
  factor := cast(f64)2 / sqrt(cast(f64)PI);
  // odd function
  if x < 0 {
    factor = -factor;
    x = -x;
  }

  // doesn't get any better after 50
  N :: 50;
  num_iters := N;
  terms : [N] f64 = ---;

  x2 := x*x;
  sign :f64 = 1;
  numerator : f64 = x;
  terms[0] = x;
  for i: 1..N-1 {
    k := cast(f64)(2*i+1);

    sign = -sign;
    inv_k := 1 / k;
    numerator *= x2 / cast(f64)i;
    term := sign * numerator * inv_k;

    terms[i] = term;
    print("%: %\n", i, Basic.formatFloat(term, mode=.SCIENTIFIC));

    if abs(term*factor) < epsilon {
      if num_iters == N num_iters = i+1;
      // break;
    }
  }

  print("Necessary iters: %\n", num_iters);
  // kahan sum
  sum : f64 = 0;
  // for < i: num_iters-1..0 sum += terms[i];
  sum = kahan_sum(terms);
  return factor * sum;
}

erf_glibc :: (x: f64) -> f64 {
  // https://sourceware.org/git/?p=glibc.git;a=blob;f=sysdeps/ieee754/dbl-64/s_erf.c
  if x == 0 return x;
  result : f64 = -1; // good sentinel since erf(+) = +

  // always positive
  sign :f64= 1;
  if x < 0 {
    sign = -1;
    x = -x;
  }

  // computes the quotient P(y)/Q(y) of two polynomials
  compute_polynomial_quotient :: inline (P : [] f64, Q: [] f64, y: f64) -> f64 {
    yi : f64 = 1;
    p := P[0];
    q := Q[0];
    for i: 1..P.count-1 {
      yi *= y;
      p += yi*P[i];
      q += yi*Q[i];
    }
    return p/q;
  }

  // [0, 0.84375)
  if x < 0.84375 {
    P :: f64.[
      1.28379167095512558561E-01,
      -3.25042107247001499370E-01,
      -2.84817495755985104766E-02,
      -5.77027029648944159157E-03,
      -2.37630166566501626084E-05,
      0
    ];
    Q :: f64.[
      1.0,
      3.97917223959155352819E-01,
      6.50222499887672944485E-02,
      5.08130628187576562776E-03,
      1.32494738004321644526E-04,
      -3.96022827877536812320E-06
    ];

    y := x*x;
    pq := compute_polynomial_quotient(P, Q, y);
    result = x + x * pq;
  }

  // [0.84375, 1.25)
  else if x < 1.25 {
    erx :: 8.45062911510467529297E-01;
    P :: f64.[
      -2.36211856075265944077E-03,
      4.14856118683748331666E-01,
      -3.72207876035701323847E-01,
      3.18346619901161753674E-01,
      -1.10894694282396677476E-01,
      3.54783043256182359371E-02,
      -2.16637559486879084300E-03
    ];
    Q :: f64.[
      1.0,
      1.06420880400844228286E-01,
      5.40397917702171048937E-01,
      7.18286544141962662868E-02,
      1.26171219808761642112E-01,
      1.36370839120290507362E-02,
      1.19844998467991074170E-02
    ];
    #assert(P.count == Q.count);

    y := x - cast(f64)1;
    pq := compute_polynomial_quotient(P, Q, y);
    result = erx + pq;
  }

  // [1.25, 2.857)
  // else if x < 1 / 0.35 {
  else if x < 6 {
    // These are polynomials in y = x^-2
    // [1.25, 2.857)
    P1 :: f64.[
      -9.86494403484714822705E-03,
      -6.93858572707181764372E-01,
      -1.05586262253232909814E+01,
      -6.23753324503260060396E+01,
      -1.62396669462573470355E+02,
      -1.84605092906711035994E+02,
      -8.12874355063065934246E+01,
      -9.81432934416914548592E+00,
      0
    ];
    Q1 :: f64.[
      1,
      1.96512716674392571292E+01,
      1.37657754143519042600E+02,
      4.34565877475229228821E+02,
      6.45387271733267880336E+02,
      4.29008140027567833386E+02,
      1.08635005541779435134E+02,
      6.57024977031928170135E+00,
      -6.04244152148580987438E-02
    ];
    #assert(P1.count == Q1.count);

    // [2.857, 6)
    P2 :: f64.[
      -9.86494292470009928597E-03,
      -7.99283237680523006574E-01,
      -1.77579549177547519889E+01,
      -1.60636384855821916062E+02,
      -6.37566443368389627722E+02,
      -1.02509513161107724954E+03,
      -4.83519191608651397019E+02,
      0,
    ];
    Q2 :: f64.[
      1,
      3.03380607434824582924E+01,
      3.25792512996573918826E+02,
      1.53672958608443695994E+03,
      3.19985821950859553908E+03,
      2.55305040643316442583E+03,
      4.74528541206955367215E+02,
      -2.24409524465858183362E+01
    ];

    inv_x := cast(f64)1 / x;
    y := inv_x*inv_x;
    pq : f64 = ---;
    if x < 1/0.35
      pq = compute_polynomial_quotient(P1, Q1, y);
    else
      pq = compute_polynomial_quotient(P2, Q2, y);

    result = 1 - inv_x*exp(-x*x-0.5625+pq);
  }

  // [6, inf)
  else {
    return sign * (cast(f64)1 - 1.0E-300); // arbitrarily close to 1
  }

  assert(result != -1);
  return sign * result;
}

erf :: erf_glibc;

kahan_sum :: inline (values : [] f64) -> f64 {
  c, sum : f64;
  for i: 0..values.count-1 {
    y := values[i] - c;
    t := sum + y;
    c = (t - sum) - y;
    sum = t;
  }
  return sum;
}

#scope_file

#import "constants";

#import "Math";
Basic :: #import "Basic";

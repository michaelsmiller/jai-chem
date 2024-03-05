#scope_export

erf :: erf_glibc;

#scope_file

erf_glibc :: (x: f64) -> f64 {
  // This uses the same algorithm as the glibc implementation that makes it
  // into a lot of libm packages. Except I cleaned up the variable names,
  // use loops for clarity which is probably way slower unless we figure out
  // a way to unroll them from macros, and I don't cover the denormal input
  // case (which probably doesn't matter in the context of chemistry).

  // glibc code can be found here:
  // https://github.com/bminor/glibc/blob/master/sysdeps/ieee754/dbl-64/s_erf.c

  if x == 0 return x;
  result : f64 = -1; // good sentinel since erf(+) = +

  ZERO :f64: 0;
  ONE :f64: 1;

  // always positive
  sign :f64 = ifx x < 0 then -ONE else ONE;
  x = Math.abs(x);

  // computes the quotient P(y)/Q(y) of two polynomials
  compute_polynomial_quotient :: inline (P : [] f64, Q: [] f64, y: f64) -> f64 {
    assert(P.count == Q.count);
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

    y := x - ONE;
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

    inv_x := ONE / x;
    y := inv_x*inv_x;
    pq : f64 = ---;
    // [1.25, 2.857)
    if x < 1/0.35 pq = compute_polynomial_quotient(P1, Q1, y);
    // [2.857, 6)
    else          pq = compute_polynomial_quotient(P2, Q2, y);

    result = ONE - inv_x*Math.exp(-x*x-0.5625+pq);
  }

  // [6, inf)
  else {
    result = ONE - 1.0E-300; // arbitrarily close to 1
  }

  assert(result != -1);
  return sign * result;
}

#scope_file

#import "constants"; // types
#import "util"; // types

Math :: #import "Math";
#import "Basic";

#import "math";
#import "chemistry";
Math :: #import "Math";

integrate_ss_overlap :: (coeff_a: f64, coeff_b: f64, zeta_a: f64, zeta_b: f64, ra: Vector3, rb: Vector3) -> f64 {
  zeta := zeta_a + zeta_b;
  xi := zeta_a * zeta_b / zeta;
  rp := (zeta_a*ra + zeta_b*rb) / zeta;
  rab := rb - ra;
  prefactor := Math.pow(Math.PI64/zeta, 1.5) * coeff_a * coeff_b;
  return prefactor * Math.exp(-xi*norm2(rab));
}

// integrate_ss_overlap :: (cgto_pair: *BasisPairs.CgtoPair) -> f64 {
//   sum : f64 = 0;

// }

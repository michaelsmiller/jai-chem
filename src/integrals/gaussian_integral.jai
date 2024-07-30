#scope_export

GaussianIndex :: struct {
  x, y, z : s8;
  #place x;
  data : [3] s8;
}

operator == :: inline (a : GaussianIndex, b : GaussianIndex) -> bool {
  return a.x == b.x && a.y == b.y && a.z == b.z;
}

S_INDEX :: GaussianIndex.{0, 0, 0};

D_INDICES :: GaussianIndex.[
  .{2, 0, 0},
  .{0, 2, 0},
  .{0, 0, 2},
  .{1, 1, 0},
  .{1, 0, 1},
  .{0, 1, 1}
];

get_total_angular_momentum :: inline (i : GaussianIndex) -> s8 {
  return i.x + i.y + i.z;
}

get_max :: inline (a : GaussianIndex) -> s8 {
  i : s8 = ifx a.y > a.x then cast(s8) 1 else 0;
  return ifx a.z > a.data[i] then cast(s8) 2 else i;
}

decrement :: inline (a : GaussianIndex, i : int) -> GaussianIndex {
  b := a;
  assert(b.data[i] > 0);
  b.data[i] -= 1;
  return b;
}

increment :: inline (a : GaussianIndex, i : int) -> GaussianIndex {
  b := a;
  b.data[i] += 1;
  return b;
}


compute_gaussian_index :: (l : int, m : int) -> GaussianIndex {
  assert(m >= 0 && m < SHELL_MULTIPLICITY[l]);
  i := S_INDEX;
  if l == {
    case 0; return i;
    case 1; i.data[m] = 1; return i;
    case 2; return D_INDICES[m];
    case; error("Should not get here!\n");
  }
  return i; // should never reach this, just to make warnings go away
}


PairParameters :: struct {
  zeta_a : f64;
  zeta_b : f64;
  #place zeta_a;
  zetas : [2] f64 = ---;
  xi : f64;
  ab2 : f64;
  coefficient : f64;
  PA : Vector3;
  PB : Vector3;
  PC : Vector3;
  #place PA;
  PX : [3] Vector3 = ---; // useful for some equations
}

integrate_primitives :: (a : GaussianIndex, b : GaussianIndex, p : *PairParameters) -> f64 {
  // This function is written recursively
  zeta := p.zeta_a + p.zeta_b;
  assert(zeta > 0);
  la := get_total_angular_momentum(a);
  lb := get_total_angular_momentum(b);
  assert(la >= 0 && lb >= 0);
  integral : f64 = ---;

  // recursion base case
  if a == S_INDEX && b == S_INDEX {
    integral = p.coefficient * Math.pow(Math.PI64 / zeta, 1.5) * Math.exp(-p.xi * p.ab2);
    return integral;
  }

  a_prime : GaussianIndex = ---;
  b_prime : GaussianIndex = ---;
  i : s8;
  if la > 0 {
    i = get_max(a);
    a_prime = decrement(a, i);
    b_prime = b;
    integral = p.PA.vec[i] * integrate_primitives(a_prime, b_prime, p);
  }
  else {
    i = get_max(b);
    a_prime = a;
    b_prime = decrement(b, i);
    integral = p.PB.vec[i] * integrate_primitives(a_prime, b_prime, p);
  }

  za : f64 = 0.5 / p.zeta_a;
  zb : f64 = 0.5 / p.zeta_b;
  if a_prime.data[i] > 0
    integral += za * a_prime.data[i] * integrate_primitives(decrement(a_prime, i), b_prime, p);
  if b_prime.data[i] > 0
    integral += zb * b_prime.data[i] * integrate_primitives(a_prime, decrement(b_prime, i), p);

  return integral;
}

#scope_file

#import "math";
#import "util"; // f64
#import "chemistry";
Math :: #import "Math";
#import "Basic"; // assert


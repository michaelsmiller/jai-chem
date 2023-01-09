GaussianIndex :: struct {
  x : s8;
  y : s8;
  z : s8;
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

PairParameters :: struct {
  zeta_a : f64;
  zeta_b : f64;
  #place zeta_a; zetas : [2] f64;
  zeta : f64;
  xi : f64;
  ab2 : f64;
  coefficient : f64;
  PA : Vector3;
  PB : Vector3;
  PC : Vector3;
  #place PA; PX : [3] Vector3;
}

integrate_primitives :: (a : GaussianIndex, b : GaussianIndex, p : *PairParameters) -> f64 {
  assert(p.zeta > 0);
  la := get_total_angular_momentum(a);
  lb := get_total_angular_momentum(b);
  assert(la >= 0 && lb >= 0);
  integral : f64 = 0;
  if a == S_INDEX && b == S_INDEX {
    integral = Math.pow(PI / p.zeta, 1.5) * Math.exp(-p.xi * p.ab2);
    return p.coefficient * integral;
  }

  a_prime : GaussianIndex;
  b_prime : GaussianIndex;
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
  integral *= p.coefficient;
  return integral;
}

compute_overlap :: (basis : *Basis, geometry : [] Vector3, C : Vector3, matrix : *Matrix) {
  n := basis.cgtos.count;
  p : PairParameters;
  log("There are % CGTOs total\n", basis.cgtos.count, flags=.VERBOSE_ONLY);
  // For each shell combination la, lb, we loop through all pairs of subshells
  // For each pair of subshells we loop through all pairs of orbitals, then
  // all pairs of primitives.
  for *shell_a, la : basis.shells {
    for *shell_b, lb : basis.shells if lb >= la { // only doing upper right half
      for subshell_a : shell_a.subshells {
        A := geometry[subshell_a.i_atom];
        for subshell_b : shell_b.subshells {
          B := geometry[subshell_b.i_atom];
          p.ab2 = dot(A, B);
          for *a_cgto : subshell_a.cgtos {
            i_cgto := cast(int)(a_cgto - basis.cgtos.data);
            a := compute_gaussian_index(la, a_cgto.m);
            for *b_cgto : subshell_b.cgtos {
              j_cgto := cast(int)(b_cgto - basis.cgtos.data);
              result := get(matrix, i_cgto, j_cgto);
              defer set(matrix, i_cgto, j_cgto, result);
              b := compute_gaussian_index(lb, b_cgto.m);
              // for i_gto : a_cgto.start..a_cgto.end-1 {
              for *a_gto : a_cgto.gtos {
                p.zeta_a = a_gto.exponent;
                // for j_gto : b_cgto.start..b_cgto.end-1 {
                for *b_gto : b_cgto.gtos {
                  p.zeta_b = b_gto.exponent;

                  p.zeta = p.zeta_a + p.zeta_b;
                  P := ((p.zeta_a * A) + (p.zeta_b * B)) / p.zeta;
                  p.PA = P - A;
                  p.PB = P - B;
                  p.PC = P - C;

                  p.xi = p.zeta_a * p.zeta_b / p.zeta;
                  p.coefficient = a_gto.contraction_coefficient * b_gto.contraction_coefficient;
                  result += integrate_primitives(a, b, *p);
                }
              }
            }
          }
        }
      }
    }
  }
  copy_over_diagonal(matrix, upper_right_to_lower_left=true);
}

#scope_file

#import "Basic"; // debugging, really
Math :: #import "Math";

#import "chemistry";
#import "util"; // f64
#import "math"; // Vector3
#import "constants";

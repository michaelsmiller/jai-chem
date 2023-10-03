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
  #place zeta_a;
  zetas : [2] f64 = ---;
  zeta : f64;
  xi : f64;
  ab2 : f64;
  coefficient : f64;
  PA : Vector3;
  PB : Vector3;
  PC : Vector3;
  #place PA;
  PX : [3] Vector3 = ---; // useful for some equations
}

integrate_primitives :: (
  basis : *Basis, geometry : [] Vector3,
  atom_a : int, atom_b : int,
  la : int, lb : int,
  cgto_a_index : int, cgto_b_index : int
) -> f64 {
  subshell_a := *basis.subshells;
  p : PairParameters;
  // @todo: derive the parameters and call integrate_primitives
}

integrate_primitives :: (a : GaussianIndex, b : GaussianIndex, p : *PairParameters, level_debug := 0) -> f64 {
  assert(p.zeta > 0);
  la := get_total_angular_momentum(a);
  lb := get_total_angular_momentum(b);
  assert(la >= 0 && lb >= 0);
  integral : f64 = ---;
  if a == S_INDEX && b == S_INDEX {
    integral = p.coefficient * Math.pow(PI / p.zeta, 1.5) * Math.exp(-p.xi * p.ab2);
    // log("(%|%) = %");
    return integral;
  }

  a_prime : GaussianIndex;
  b_prime : GaussianIndex;
  i : s8;
  // @todo: rewrite this to just choose one to decrement
  if la > 0 {
    i = get_max(a);
    a_prime = decrement(a, i);
    b_prime = b;
    integral = p.PA.vec[i] * integrate_primitives(a_prime, b_prime, p, level_debug+1);
  }
  else {
    i = get_max(b);
    a_prime = a;
    b_prime = decrement(b, i);
    integral = p.PB.vec[i] * integrate_primitives(a_prime, b_prime, p, level_debug+1);
  }

  za : f64 = 0.5 / p.zeta_a;
  zb : f64 = 0.5 / p.zeta_b;
  if a_prime.data[i] > 0
    integral += za * a_prime.data[i] * integrate_primitives(decrement(a_prime, i), b_prime, p, level_debug+1);
  if b_prime.data[i] > 0
    integral += zb * b_prime.data[i] * integrate_primitives(a_prime, decrement(b_prime, i), p, level_debug+1);
  integral *= p.coefficient;

  return integral;
}

// @todo: clean this up so that C is optional, since for overlap there *is* no point of evaluation
//        or rather, the integral is the same everywhere.
compute_overlap :: (basis_pairs : *BasisPairs, C : Vector3, matrix : *Matrix) {
  p : PairParameters;
  log("There are % pairs of CGTOs total\n", basis_pairs.cgto_pairs.count);
  // For each shell combination la, lb, we loop through all pairs of subshells
  // For each pair of subshells we loop through all pairs of orbitals, then
  // all pairs of primitives.
  for *shell_pair : basis_pairs.shell_pairs {
    log("Shell pair %:%\n", shell_pair.la, shell_pair.lb);
    for *subshell_pair : shell_pair.subshell_pairs {
      log("Subshell pair %:%\n", subshell_pair.atom_a, subshell_pair.atom_b);
      p.ab2 = subshell_pair.ab2;
      for *cgto_pair : subshell_pair.cgto_pairs {
        a := compute_gaussian_index(shell_pair.la, cgto_pair.ma);
        b := compute_gaussian_index(shell_pair.lb, cgto_pair.mb);

        result := get(matrix, cgto_pair.index_a, cgto_pair.index_b);
        defer set(matrix, cgto_pair.index_a, cgto_pair.index_b, result);
        for *gto_pair : cgto_pair.gto_pairs {
          p.zeta_a = gto_pair.zeta_a;
          p.zeta_b = gto_pair.zeta_b;
          p.zeta   = gto_pair.zeta;

          P := gto_pair.P;
          p.PA = P - subshell_pair.A;
          p.PB = P - subshell_pair.B;
          p.PC = P - C;
          p.xi = gto_pair.xi;
          p.coefficient = gto_pair.coefficient;
          integral := integrate_primitives(a, b, *p);
          log("% => %\n", p, integral);
          result += integral;
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

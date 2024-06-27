#scope_export

MAX_ANGULAR_MOMENTUM : s8 : 2;
NUM_ANGULAR_MOMENTUM : s8 : MAX_ANGULAR_MOMENTUM + 1;
NUM_PAIRS :: NUM_ANGULAR_MOMENTUM * (NUM_ANGULAR_MOMENTUM + 1) / 2;

MomentumAccumulator :: [NUM_ANGULAR_MOMENTUM] int; // useful typedef
// Shell multiplicity is just the powers of 3
SHELL_MULTIPLICITY :: #run () -> [NUM_ANGULAR_MOMENTUM] s8 {
  result : [NUM_ANGULAR_MOMENTUM] s8;
  for i : 0..MAX_ANGULAR_MOMENTUM {
    result[i] = ((i+1)*(i+2))/2;
  }
  return result;
}();

// (L+1)(L+2)/2

BasisPairs :: struct {
  ShellPair :: struct {
    la : s8;
    lb : s8;
    subshell_pairs : [] SubshellPair;
  }
  SubshellPair :: struct {
    atom_a : int;
    atom_b : int;
    ab2 : f64;
    A : Vector3;
    B : Vector3;
    cgto_pairs : [] CgtoPair;
  }
  CgtoPair :: struct {
    ma : s8;
    mb : s8;
    index_a  : int; // index in global list of cgtos, useful for matrix elements
    index_b  : int;
    gto_pairs : [] GtoPair;
  }
  GtoPair :: struct {
    P : Vector3; // Center of mass of A, B based on their zetas
    coefficient : f64;
    zeta_a : f64;
    zeta_b : f64;
    zeta   : f64; // zeta_a + zeta_b
    xi     : f64; // product divided by sum of zeta_a, zeta_b
  }

  shell_pairs: [NUM_PAIRS] ShellPair;
  subshell_pairs : [] SubshellPair;
  cgto_pairs : [] CgtoPair;
  gto_pairs  : [] GtoPair;
}

create_basis_pairs :: (basis : *Basis) -> BasisPairs {
  pairs : BasisPairs;

  // Meant to only have UNIQUE combinations of elements
  get_num_combinations :: inline (n : $T) -> T {
    return n * (n+1) / 2;
  }

  // allocate memory
  // don't need to allocate shell_pairs memory because it's static
  nsubshells := basis.subshells.count;
  nsubshell_pairs := get_num_combinations(nsubshells);
  pairs.subshell_pairs = NewArray(nsubshell_pairs, BasisPairs.SubshellPair);
  subshell_pair := pairs.subshell_pairs.data;
  defer assert(subshell_pair == pairs.subshell_pairs.data + pairs.subshell_pairs.count);

  ncgtos := basis.cgtos.count;
  ncgto_pairs := get_num_combinations(ncgtos);
  pairs.cgto_pairs = NewArray(ncgto_pairs, BasisPairs.CgtoPair);
  cgto_pair := pairs.cgto_pairs.data;
  defer assert(cgto_pair == pairs.cgto_pairs.data + pairs.cgto_pairs.count);

  ngtos := basis.gtos.count;
  ngto_pairs := get_num_combinations(ngtos);
  pairs.gto_pairs = NewArray(ngto_pairs, BasisPairs.GtoPair);
  gto_pair := pairs.gto_pairs.data;
  defer assert(gto_pair == pairs.gto_pairs.data + pairs.gto_pairs.count);

  shell_pair := pairs.shell_pairs.data;
  defer assert(shell_pair == pairs.shell_pairs.data + pairs.shell_pairs.count);

  // set all the arrays to point to the right places
  // shells
  for *shell_a : basis.shells {
    n_subshells_a := shell_a.subshells.count;
    for *shell_b : basis.shells if shell_b >= shell_a {
      la := shell_a.angular_momentum;
      lb := shell_b.angular_momentum;
      assert(lb >= la);
      n_subshells_b := shell_b.subshells.count;
      defer shell_pair += 1;
      n_subshell_pairs := ifx shell_a == shell_b then get_num_combinations(n_subshells_a) else n_subshells_a * n_subshells_b;
      log("Shell pair % %\n", la, lb);
      shell_pair.la = shell_a.angular_momentum;
      shell_pair.lb = shell_b.angular_momentum;
      shell_pair.subshell_pairs.count = n_subshell_pairs;
      shell_pair.subshell_pairs.data = subshell_pair;
      for *subshell_a : shell_a.subshells {
        n_cgtos_a := subshell_a.cgtos.count;
        for *subshell_b : shell_b.subshells if subshell_b >= subshell_a {
          log("Subshell pair: % | %\n", subshell_a.i_atom, subshell_b.i_atom);
          assert(lb > la || subshell_b.i_atom >= subshell_a.i_atom);
          defer subshell_pair += 1;
          n_cgtos_b := subshell_b.cgtos.count;
          n_cgto_pairs := ifx subshell_a == subshell_b then get_num_combinations(n_cgtos_a) else n_cgtos_a*n_cgtos_b;
          subshell_pair.atom_a = subshell_a.i_atom;
          subshell_pair.atom_b = subshell_b.i_atom;
          subshell_pair.cgto_pairs.count = n_cgto_pairs;
          subshell_pair.cgto_pairs.data = cgto_pair;

          for *cgto_a : subshell_a.cgtos {
            i_cgto := cast(int)(cgto_a - basis.cgtos.data);
            n_gtos_a := cgto_a.gtos.count;
            for *cgto_b : subshell_b.cgtos if cgto_b >= cgto_a {
              j_cgto := cast(int)(cgto_b - basis.cgtos.data);
              defer cgto_pair += 1;
              n_gtos_b := cgto_b.gtos.count;
              n_gto_pairs := ifx cgto_a == cgto_b then get_num_combinations(n_gtos_a) else n_gtos_a*n_gtos_b;
              cgto_pair.ma = cgto_a.m;
              cgto_pair.mb = cgto_b.m;
              cgto_pair.index_a = i_cgto;
              cgto_pair.index_b = j_cgto;
              cgto_pair.gto_pairs.count = n_gto_pairs;
              cgto_pair.gto_pairs.data = gto_pair;

              for *gto_a : cgto_a.gtos {
                for *gto_b : cgto_b.gtos if gto_b >= gto_a {
                  defer gto_pair += 1;
                  gto_pair.coefficient = gto_a.contraction_coefficient * gto_b.contraction_coefficient;
                  gto_pair.zeta_a = gto_a.exponent;
                  gto_pair.zeta_b = gto_b.exponent;
                  gto_pair.zeta = gto_pair.zeta_a + gto_pair.zeta_b;
                  gto_pair.xi = gto_pair.zeta_a * gto_pair.zeta_b / gto_pair.zeta;
                  {
                    index := cast(int)(gto_pair - pairs.gto_pairs.data);
                    log("GTO Pair (%/%): % % %\n", index, ngto_pairs, gto_pair.zeta_a, gto_pair.zeta_b, gto_pair.zeta);
                  }
                  assert(gto_pair.zeta != 0);
                }
              }
            }
          }
        }
      }
    }
  }
  return pairs; // using "defer" upon instantiation creates a compiler warning
}

update_basis_pairs :: (pairs : *BasisPairs, geometry : [] Vector3) {
  log("%\n", geometry);
  for *subshell_pair : pairs.subshell_pairs {
    A := geometry[subshell_pair.atom_a];
    B := geometry[subshell_pair.atom_b];
    ab2 := dot(A, B);
    subshell_pair.A = A;
    subshell_pair.B = B;
    subshell_pair.ab2 = ab2;
    log("Subshell pair % | %, % : %\n", it_index, subshell_pair.atom_a, subshell_pair.atom_b, subshell_pair.cgto_pairs.count);
    log("%, %\n", A, B);
    for *cgto_pair : subshell_pair.cgto_pairs {
      for *gto_pair : cgto_pair.gto_pairs {
        gto_pair.P = (gto_pair.zeta_a * A + gto_pair.zeta_b * B) / gto_pair.zeta;
      }
    }
  }
}

// @todo: Consider whether it's better to store a subshell for every element
//        rather than every atom, and just have the number of that atom there as well
Basis :: struct {
  Shell :: struct {
    // Contains all the orbitals of a given angular momentum (e.g. S Shell, P Shell)
    angular_momentum : s8; // l is a bad letter for programming
    subshells : [] Subshell;
  };
  Subshell :: struct {
    // Orbitals with same angular momentum for one atom
    // e.g. P subshell for the second oxygen atom in H2O2
    i_atom : int; // index in canonical array of atoms
    cgtos : [] Cgto;
  };
  Cgto :: struct {
    // Contains a single atom centered contracted orbital
    // e.g. The second Px orbital in a Phosphorus atom
    m : s8; // magnetic quantum number (e.g. 0, 1, 2 for p orbitals)
    gtos : [] Gto;
  };
  Gto :: struct {
    // A single gaussian orbital
    exponent                : f64;
    contraction_coefficient : f64;
  };

  shells : [NUM_ANGULAR_MOMENTUM] Shell;
  subshells : [] Subshell;
  cgtos  : [] Cgto;
  gtos   : [] Gto;

  // @note: the following attributes are inferrable from the above attributes
  cgto_starts : [NUM_ANGULAR_MOMENTUM] int;
  gto_starts  : [NUM_ANGULAR_MOMENTUM] int;
}

normalize_basis :: (basis : *Basis) {
  params : PairParameters;
  for *shell : basis.shells {
    for *subshell: shell.subshells {
      for *cgto: subshell.cgtos {
        total_integral : f64 = 0;
        for *gto1: cgto.gtos {
          for *gto2: cgto.gtos if gto2 >= gto1 {
            params.zeta_a = gto1.exponent;
            params.zeta_b = gto2.exponent;
            params.xi = params.zeta_a * params.zeta_b / (params.zeta_a + params.zeta_b);
            params.coefficient = gto1.contraction_coefficient * gto2.contraction_coefficient;
            a := compute_gaussian_index(shell.angular_momentum, cgto.m);
            b := a;
            primitive_integral := integrate_primitives(a, b, *params);
            total_integral += primitive_integral;
          }
        }
        assert(total_integral > 0);
        inv_factor := Math.pow(total_integral, -0.5);
        for *gto: cgto.gtos gto.contraction_coefficient *= inv_factor;
      }
    }
  }
}

free :: (b : Basis) {
  array_free(b.subshells);
  array_free(b.cgtos);
  array_free(b.gtos);
}
free :: (p : BasisParameters) {
  array_free(p.element_groups);
  array_free(p.cgtos);
  array_free(p.gtos);
}
free :: (p : BasisPairs) {
  array_free(p.subshell_pairs);
  array_free(p.cgto_pairs);
  array_free(p.gto_pairs);
}



create_basis :: (p : *BasisParameters, atoms : [] Atom) -> Basis {
  b : Basis;

  // precompute number of each element
  element_counts : [NUM_ELEMENTS] int;
  for * atom : atoms element_counts[atom.element] += 1;

  // compute number of each momentum cgto by looping over element_types
  cgto_totals : MomentumAccumulator;
  gto_totals  : MomentumAccumulator;
  subshell_totals  : MomentumAccumulator;
  for * element_group : p.element_groups {
    num_of_this_element := element_counts[element_group.element];
    if num_of_this_element == 0 continue;
    has_subshell : [NUM_ANGULAR_MOMENTUM] bool;
    for i : element_group.start..element_group.end-1 {
      cgto := *p.cgtos[i];
      l := cgto.total_angular_momentum;
      has_subshell[l] = true;
      cgto_totals[l] += num_of_this_element * SHELL_MULTIPLICITY[l];
      gto_totals[l]  += num_of_this_element * (cgto.end - cgto.start) * SHELL_MULTIPLICITY[l];
    }
    for l : 0..MAX_ANGULAR_MOMENTUM if has_subshell[l] subshell_totals[l] += num_of_this_element;
  }
  log("CGTO TOTALS: %\n", cgto_totals);
  log("GTO TOTALS: %\n", gto_totals);
  log("SUBSHELL TOTALS: %\n", subshell_totals);

  // compute the starts for cgtos beforehand and reserve space for all of them
  cgto_starts : MomentumAccumulator;
  gto_starts : MomentumAccumulator;
  subshell_starts : MomentumAccumulator;
  for l : 1..MAX_ANGULAR_MOMENTUM {
    cgto_starts[l] = cgto_starts[l-1] + cgto_totals[l-1];
    gto_starts[l] = gto_starts[l-1] + gto_totals[l-1];
    subshell_starts[l] = subshell_starts[l-1] + subshell_totals[l-1];
  }
  log("CGTO STARTS: %\n", cgto_starts);
  log("GTO STARTS: %\n", gto_starts);
  log("SUBSHELL STARTS: %\n", gto_starts);

  total_num_cgtos := cgto_starts[MAX_ANGULAR_MOMENTUM] + cgto_totals[MAX_ANGULAR_MOMENTUM];
  total_num_gtos := gto_starts[MAX_ANGULAR_MOMENTUM] + gto_totals[MAX_ANGULAR_MOMENTUM];
  total_num_subshells := subshell_starts[MAX_ANGULAR_MOMENTUM] + subshell_totals[MAX_ANGULAR_MOMENTUM];

  { // scope to remove _ptr
    _ptr : *void;
    b.cgtos, _ptr = NewArray(total_num_cgtos, Basis.Cgto);
    b.gtos, _ptr = NewArray(total_num_gtos, Basis.Gto);
    b.subshells, _ptr = NewArray(total_num_subshells, Basis.Subshell);
    // for *shell, l : b.shells shell.subshells, _ptr = NewArray(subshell_totals[l], Basis.Subshell);
  }
  log("Num atoms: %\n", atoms.count);
  log("Total subshells: %\n", b.subshells.count);
  log("Total cgtos: %\n", b.cgtos.count);
  log("Total gtos: %\n", b.gtos.count);

  i_cgto := 0;
  i_gto := 0;
  i_subshell := 0;
  for l : 0..MAX_ANGULAR_MOMENTUM {
    log("\n-----------------\nShell %\n-----------------\n", l);
    b.shells[l].subshells.count = subshell_totals[l];
    b.shells[l].angular_momentum = l;
    if subshell_totals[l] == 0 continue;
    b.shells[l].subshells.data =  *b.subshells[subshell_starts[l]];
    for * atom, i_atom : atoms {
      log("Atom %: %\n", i_atom, atom.element);
      element_group := pick_item_with_element(p.element_groups, atom.element);

      num_cgtos := 0;
      for i : element_group.start..element_group.end-1
        if p.cgtos[i].total_angular_momentum == l
          num_cgtos += SHELL_MULTIPLICITY[l];
      if num_cgtos == 0 continue;

      // only create subshell when there are orbitals with that angular momentum
      defer i_subshell += 1;
      log("Number of subshells: %\n", b.shells[l].subshells.count);
      subshell := *b.subshells[i_subshell];
      start := i_cgto;
      end   := i_cgto + num_cgtos;
      defer assert(end == i_cgto);
      subshell.i_atom = i_atom;
      subshell.cgtos.count = end-start;
      subshell.cgtos.data  = *b.cgtos[start];
      defer log("Subshell %: %\n", i_subshell, <<subshell);

      for i : element_group.start..element_group.end-1 {
        cgto := *p.cgtos[i];
        if cgto.total_angular_momentum == l {
          for m : 0..SHELL_MULTIPLICITY[l]-1 {
            defer i_cgto += 1;
            new_cgto := *b.cgtos[i_cgto];

            new_cgto.m = m;
            new_cgto.gtos.count = cgto.end - cgto.start;
            new_cgto.gtos.data  = *b.gtos[i_gto];

            for *new_gto, j : new_cgto.gtos {
              defer i_gto += 1;
              gto := *p.gtos[cgto.start + j];
              new_gto.exponent = gto.exponent;
              new_gto.contraction_coefficient = gto.contraction_coefficient;
            }
          }
        }
      }
    }
  }

  b.gto_starts = gto_starts;
  b.cgto_starts = cgto_starts;

  log("\n------------\nSHELLS (%):\n%\n", b.shells.count, b.shells);
  log("\nSUBSHELLS (%):\n%\n", b.subshells.count, b.subshells);
  log("\nCGTOS (%):\n%\n", b.cgtos.count, b.cgtos);
  log("\nGTOS (%):\n%\n", b.gtos.count, b.gtos);

  normalize_basis(*b);
  return b;
}

// Data structure to internally store the information of a basis
// @note: Each element has an associated set of contracted Gaussian Orbitals (CGTOs).
//        Each CGTO has a total angular momentum (quantum number l) and is in turn a linear
//        combination of gaussian-type orbitals (GTOs) with that angular momentum.
//        Each GTO has its magnetic quantum number (m), an exponent, and a coefficient.
//        In theory CGTOs Φ(r) are normalized: <Φ|Φ> = 1. However, some basis sets have
//        contractions of different shells (e.g. Φ = 1 S + 1 P). We separate those out into
//        different "orbitals". The reason for this is it greatly speeds up and simplifies integrals
//        The actual number of orbitals shouldn't matter as long as properties
//        like the overlap integral producing the total electronic charge hold, and that is
//        enforced by keeping the coefficients correct.
BasisParameters :: struct {
  ElementGroup :: struct {
    element : Element = .NULL;
    start   : int = -1; // index in cgtos array
    end     : int = -1;
  };
  Cgto :: struct {
    total_angular_momentum : s8;
    start : int = -1; // index in gtos array
    end   : int = -1;

    // @todo: include labels here
  };
  Gto :: struct {
    exponent                : f64;
    contraction_coefficient : f64;
  };

  // ordered by start, not by element
  element_groups : [..] ElementGroup;
  cgtos : [..] Cgto;
  gtos : [..] Gto;
}

read_basis_file :: (filepath : string) -> BasisParameters {
  element_groups : [..] BasisParameters.ElementGroup;
  cgtos : [..] IntermediateCgto;
  gtos : [..] IntermediateGto;


  s, success := File.read_entire_file(filepath);
  if !success error("Unable to read basis file '%'", filepath);
  lines0 := String.split(s, cast(u8)(#char "\n"));

  // trim and filter comments
  lines : [..] string;
  for line0 : lines0 {
    line := String.trim(line0);
    i := String.find_index_from_left(line, "!");
    if i != -1 {
      line = String.slice(line, 0, i);
      line = String.trim(line);
    }
    if line.count > 0 array_add(*lines, line);
  }

  log("Number of lines: %\n", lines.count);
  element := Element.NULL;
  set_element := true; // flag representing state when reading this line
  shell_factor : f64 = 1.0; // subject to change
  shells_covering : [3] bool; // NUM_SHELLS here or something
  i_orbital := 0;
  for line : lines {
    if line == "****" {
      assert(!set_element);
      set_element = true; // next line should be the element declaration
      if element != Element.NULL element_groups[element_groups.count-1].end = cgtos.count;
      continue;
    }

    split := split_nonempty(line);
    if set_element {
      assert(split.count == 2);
      element_shortname := split[0];
      log("Reading in orbitals for element '%'\n", element_shortname);
      element = name_to_element(element_shortname);
      set_element = false;
      if element == Element.NULL continue;

      group := array_add(*element_groups);
      group.element = element;
      group.start = cgtos.count;
      group.end = -1;
      assert(split[1] == "0");
      continue;
    }

    // case  "S 3 1.00"
    //  same thing as setting element, but for the contracted orbital
    if is_alpha(split[0][0]) {
      if element == Element.NULL continue;
      shell_factor = scientific_string_to_float(split[2]);
      orbital := split[0];
      memset(shells_covering.data, 0, shells_covering.count * size_of(bool)); // reset
      if orbital == {
        case "S";
          shells_covering[0] = true;
        case "SP";
          shells_covering[0] = true;
          shells_covering[1] = true;
        case "P";
          shells_covering[1] = true;
        case "D";
          shells_covering[2] = true;
        case;
          error("Need to cover case '%'\n", orbital);
      }
      cgto := array_add(*cgtos);
      cgto.start = gtos.count;
      cgto.end = -1;
      continue;
    }

    // case  "   0.01234  0.4321 0.2345"
    assert(split.count >= 2 && split.count <= 3);
    if element == Element.NULL continue;
    coefficients : [..] f64;
    array_resize(*coefficients, split.count);
    for i : 0..split.count-1 {
      coefficients[i] = scientific_string_to_float(split[i]);
    }

    if shells_covering[0] && shells_covering[1] { // SP
      assert(coefficients.count == 3);
      // exponent, S, P
      add_coeff(coefficients, shell_factor, 0, 1, *gtos, cgtos);
      add_coeff(coefficients, shell_factor, 1, 2, *gtos, cgtos);
    }
    else if shells_covering[0] { // S
      assert(coefficients.count == 2);
      // exponent, coeff
      add_coeff(coefficients, shell_factor, 0, 1, *gtos, cgtos);
    }
    else if shells_covering[1] { // P
      assert(coefficients.count == 2);
      // exponent, coeff
      add_coeff(coefficients, shell_factor, 1, 1, *gtos, cgtos);
    }
    else if shells_covering[2] { // D
      assert(coefficients.count == 2);
      // exponent, coeff
      add_coeff(coefficients, shell_factor, 2, 1, *gtos, cgtos);
    }
    else
      error("shells_covering = '%'\n", shells_covering);
  }

  p : BasisParameters;

  // The GTOs might need to be rearranged, so we should do everything by CGTO
  cgto_offset := 0;
  gto_offset := 0;
  for * element_group : element_groups {
    new_element_group := array_add(*p.element_groups);
    new_element_group.element = element_group.element;
    new_element_group.start = cgto_offset;
    defer new_element_group.end = cgto_offset;
    for i_cgto : element_group.start..element_group.end-1 {
      cgto := *cgtos[i_cgto];
      // figure out the split of all orbitals
      counter : MomentumAccumulator;
      for i : cgto.start..cgto.end-1
        counter[gtos[i].total_angular_momentum] += 1;

      for l : 0..MAX_ANGULAR_MOMENTUM if counter[l] > 0 {
        cgto_offset += 1;
        new_cgto := array_add(*p.cgtos);
        new_cgto.total_angular_momentum = l;
        new_cgto.start = gto_offset;
        defer new_cgto.end = gto_offset;
        for i : cgto.start..cgto.end-1 if gtos[i].total_angular_momentum == l {
          gto_offset += 1;
          gto := *gtos[i];
          new_gto := array_add(*p.gtos);
          new_gto.exponent = gto.exponent;
          new_gto.contraction_coefficient = gto.contraction_coefficient;
        }
      }
    }
  }

  return p;
}


#scope_file

IntermediateCgto :: struct {
  start : int = -1; // index in gtos array
  end   : int = -1;
};
IntermediateGto :: struct {
  total_angular_momentum  : s8;
  exponent                : f64;
  contraction_coefficient : f64;
};


split_nonempty :: (s : string) -> [] string {
  ctx : Context;
  ctx.allocator = temporary_allocator;

  // There has to be an easier way of passing the temp allocator to an array, right
  push_context ctx {
    split : [..] string;
    i := 0;
    for j : 0..s.count-1 {
      c := s[j];
      if c == cast(u8)(#char " ") || c == cast(u8)(#char "\t") {
        if i < j array_add(*split, String.slice(s, i, j-i));
        i = j+1;
      }
    }
    if i < s.count array_add(*split, String.slice(s, i, s.count));
    return split;
  }
}

add_coeff :: (coefficients : [] f64, shell_factor : f64,
              angular_momentum : s8, contraction_index : int,
              gtos : *[..] IntermediateGto, cgtos : [] IntermediateCgto) {
  gto := array_add(gtos);
  gto.total_angular_momentum = angular_momentum;
  gto.exponent = coefficients[0];
  gto.contraction_coefficient = shell_factor*coefficients[contraction_index];
  cgtos[cgtos.count-1].end = gtos.count;
}


scientific_string_to_float :: (s : string) -> f64 {
  if !String.contains_any_character(s, "eEdD") {
    result, success := string_to_float64(s);
    assert(success);
    return cast(f64)result;
  }

  i_delimiter := String.find_index_of_any_from_left(s, "eEdD");
  assert(i_delimiter > 0);
  base_string     := String.slice(s, 0, i_delimiter);
  exponent_string := String.slice(s, i_delimiter+1, s.count);
  exponent, success1 := string_to_int  (exponent_string);
  base,     success2 := string_to_float64(base_string);
  assert(success1);
  assert(success2);
  return cast(f64)base * Math.pow(10., cast(f64)exponent);
}


File :: #import "File";
String :: #import "String";
Math :: #import "Math";

#import "chemistry";
#import "util";
#import "math";
#import,file "../integrals/gaussian_integral.jai";

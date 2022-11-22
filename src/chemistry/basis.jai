#scope_export

MAX_ANGULAR_MOMENTUM : s8 : 2;
NUM_ANGULAR_MOMENTUM : s8 : MAX_ANGULAR_MOMENTUM + 1;

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
    start : int;
    end : int;
  }
  CgtoPair :: struct {
    ma : s8;
    mb : s8;
    index_a  : int;
    index_b  : int;
    ab2 : f64; // dist(A, B)
    start : int;
    end : int;
  }
  GtoPair :: struct {
    P : Vector3; // Center of mass of A, B based on their zetas
    zeta_a : f64;
    zeta_b : f64;
    zeta   : f64; // zeta_a + zeta_b
    xi     : f64; // product divided by sum of zeta_a, zeta_b
  }

  shell_pairs: [] ShellPair;
  cgto_pairs : [] CgtoPair;
  gto_pairs  : [] GtoPair;
}

// @todo: Consider whether it's better to store a subshell for every element
//        rather than every atom, and just have the number of that atom there as well
Basis :: struct {
  Shell :: struct {
    // Contains all the orbitals of a given angular momentum (e.g. S Shell, P Shell)
    angular_momentum : s8; // l is a bad letter, unfortunately
    subshells : [] Subshell;
    // @note: giving each shell an array gives less room for error when checking sizes
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

free :: (b : *Basis) {
  array_free(b.cgtos);
  array_free(b.gtos);
  for *shell : b.shells array_free(shell.subshells);
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
    has_subshell : [NUM_ANGULAR_MOMENTUM] bool;
    for i : element_group.start..element_group.end-1 {
      cgto := *p.cgtos[i];
      l := cgto.total_angular_momentum;
      has_subshell[l] = true;
      cgto_totals[l] += num_of_this_element * SHELL_MULTIPLICITY[l];
      gto_totals[l]  += num_of_this_element * (cgto.end - cgto.start) * SHELL_MULTIPLICITY[l];
    }
    for l : 0..MAX_ANGULAR_MOMENTUM if has_subshell[l] subshell_totals[l] += 1;
  }
  print("CGTO TOTALS: %\n", cgto_totals);
  print("GTO TOTALS: %\n", gto_totals);
  print("SUBSHELL TOTALS: %\n", subshell_totals);

  // compute the starts for cgtos beforehand and reserve space for all of them
  cgto_starts : MomentumAccumulator;
  gto_starts : MomentumAccumulator;
  for l : 1..MAX_ANGULAR_MOMENTUM {
    cgto_starts[l] = cgto_starts[l-1] + cgto_totals[l-1];
    gto_starts[l] = gto_starts[l-1] + gto_totals[l-1];
  }
  print("CGTO STARTS: %\n", cgto_starts);
  print("GTO STARTS: %\n", gto_starts);

  total_num_cgtos := cgto_starts[MAX_ANGULAR_MOMENTUM] + cgto_totals[MAX_ANGULAR_MOMENTUM];
  total_num_gtos := gto_starts[MAX_ANGULAR_MOMENTUM] + gto_totals[MAX_ANGULAR_MOMENTUM];

  { // scope to remove _ptr
    _ptr : *void;
    b.cgtos, _ptr = NewArray(total_num_cgtos, Basis.Cgto);
    b.gtos, _ptr = NewArray(total_num_gtos, Basis.Gto);
    for *shell, l : b.shells shell.subshells, _ptr = NewArray(subshell_totals[l], Basis.Subshell);
  }
  print("Total cgtos: %\n", b.cgtos.count);
  print("Total gtos: %\n", b.gtos.count);

  i_cgto := 0;
  i_gto := 0;
  i_subshell := 0;
  for l : 0..MAX_ANGULAR_MOMENTUM {
    for * atom, i_atom : atoms {
      element_group := pick_item_with_element(p.element_groups, atom.element);
      print("\n-----------------\n%: % %\n-----------------\n", l, i_atom, element_group.element);

      num_cgtos := 0;
      for i : element_group.start..element_group.end-1
        if p.cgtos[i].total_angular_momentum == l
          num_cgtos += SHELL_MULTIPLICITY[l];
      if num_cgtos == 0 continue;

      // only create subshell when there are orbitals with that angular momentum
      defer i_subshell += 1;
      subshell := *b.shells[l].subshells[i_subshell];
      start := i_cgto;
      end   := i_cgto + num_cgtos;
      defer assert(end == i_cgto);
      subshell.cgtos.count = end-start;
      subshell.cgtos.data  = *b.cgtos[start];
      print("Subshell %: %\n", i_subshell, <<subshell);

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

  print("\n------------\nCGTOS:\n%\n", b.cgtos);
  print("\nGTOS:\n%\n", b.gtos);

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


read_basis_file :: (filename : string) -> BasisParameters {
  element_groups : [..] BasisParameters.ElementGroup;
  cgtos : [..] IntermediateCgto;
  gtos : [..] IntermediateGto;


  s, _ := File.read_entire_file(filename);
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

  print("Number of lines: %\n", lines.count);
  element := Element.NULL;
  set_element := true; // flag representing state when reading this line
  shell_factor : f64 = 1.0; // subject to change
  shells_covering : [3] bool; // NUM_SHELLS here or something
  i_orbital := 0;
  success : bool;
  for line : lines {
    // print("%\n", line);
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
      print("Reading in orbitals for element '%'\n", element_shortname);
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
          print("Need to cover case '%'\n", orbital);
          assert(false);
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
    else {
      print("shells_covering = '%'\n", shells_covering);
      exit(1);
    }
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
    result, success := string_to_float(s);
    assert(success);
    return cast(f64)result;
  }

  i_delimiter := String.find_index_of_any_from_left(s, "eEdD");
  assert(i_delimiter > 0);
  base_string     := String.slice(s, 0, i_delimiter);
  exponent_string := String.slice(s, i_delimiter+1, s.count);
  exponent, success1 := string_to_int  (exponent_string);
  base,     success2 := string_to_float(base_string);
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

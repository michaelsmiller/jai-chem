check :: (condition : bool, message : string = "Condition not met!", print_args : ..Any) #expand {
  if !condition {
    error(message, ..print_args);
  }
}

test_print :: (message : string, print_args : ..Any) #expand {
  log_info(tprint("TEST: %", message), ..print_args, type = .TITLE);
}

correct_print :: (message : string, print_args : ..Any) #expand {
  log_info(message, ..print_args, type=.SUCCESS);
}

perform_test :: (message : string, code : Code) #expand {
  test_print("%...", message);
  #insert code;
  correct_print("PASSED\n");
}

get_test_basis :: () -> Basis, [] Vector3 {
  basis_path := sprint("%03-21g.gbs", BASIS_DIR);
  log("Opening basis file '%'\n", basis_path);
  basis_params := read_basis_file(basis_path);
  defer free(basis_params);

  geometry_path := sprint("%hf.xyz", GEOMETRY_DIR);
  log("Opening basis file '%'\n", geometry_path);
  atoms, geometry := read_geometry_from_xyz_file(geometry_path);
  defer array_free(atoms);
  defer array_free(geometry);

  basis := create_basis(*basis_params, atoms);
  return basis, geometry;
}

is_in_range :: inline (x : $T, low : T, high : T, $$end_inclusive := false) -> bool {
  #if end_inclusive
    return x >= low && x <= high;
  else return x >= low && x < high;
}

validate_basis_pairs :: () {
   basis, geometry := get_test_basis();
   defer free(basis);

   pairs := create_basis_pairs(*basis);
   perform_test(
     "Checking subshell pairs", #code {
       for *shell_pair : pairs.shell_pairs
        check(is_in_range(shell_pair.subshell_pairs.count, 0, pairs.subshell_pairs.count, true));
     }
   );
   perform_test(
     "Checking CGTO pairs", #code {
       for *subshell_pair : pairs.subshell_pairs
        check(is_in_range(subshell_pair.cgto_pairs.count, 0, pairs.cgto_pairs.count, true));
     }
   );
   perform_test(
     "Checking GTO pairs", #code {
       start := pairs.cgto_pairs.data;
       end := pairs.cgto_pairs.data + pairs.cgto_pairs.count;
       for *cgto_pair : pairs.cgto_pairs
        check(is_in_range(cgto_pair.gto_pairs.count, 0, pairs.gto_pairs.count, true));
       for *subshell_pair : pairs.subshell_pairs {
         local_pairs := *subshell_pair.cgto_pairs;
         check(is_in_range(local_pairs.data, start, end, false));
         check(is_in_range(local_pairs.data + local_pairs.count, start, end, true));
       }
     }
   );

   update_basis_pairs(*pairs, geometry);
}

validate_basis :: () {
  basis := get_test_basis();
  defer free(basis);

  // Actual validation
  perform_test ("Checking that shells have correct angular momenta", #code {
    for *shell, i : basis.shells {
      check(i == shell.angular_momentum, "% != %\n", i, shell.angular_momentum);
    }
  });
  perform_test ("Checking shells have consecutive spans of subshells", #code {
    for *shell, i : basis.shells if i < basis.shells.count-1 {
      next_shell := *basis.shells[i+1];
      check(next_shell.subshells.count == 0 || *next_shell.subshells[0] == shell.subshells.data + shell.subshells.count);
    }
  });
  perform_test ("Checking subshells have consecutive spans of cgtos", #code {
    for *subshell, i : basis.subshells if i < basis.subshells.count-1 {
      next_subshell := *basis.subshells[i+1];
      check(*next_subshell.cgtos[0] == subshell.cgtos.data + subshell.cgtos.count);
    }
  });
  perform_test ("Checking cgtos have consecutive spans of gtos", #code {
    for *cgto, i : basis.cgtos if i < basis.cgtos.count-1 {
      next_cgto := *basis.cgtos[i+1];
      check(*next_cgto.gtos[0] == cgto.gtos.data + cgto.gtos.count);
    }
  });
}

#scope_file

#import "chemistry";
#import "util"; // for I/O
#import "math"; // Vector3

#import "Basic";
#import "Print_Color";

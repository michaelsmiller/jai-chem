#scope_export

is_in_range :: inline (x : $T, low : T, high : T, $$end_inclusive := false) -> bool {
  #if end_inclusive
    return x >= low && x <= high;
  else return x >= low && x < high;
}

test_basis_pairs :: () {
  test_print("Checking that basis pairs get created correctly");

  basis, geometry := get_test_basis();
  defer free(basis);

  pairs := create_basis_pairs(*basis);
  for *shell_pair : pairs.shell_pairs
    check(is_in_range(shell_pair.subshell_pairs.count, 0, pairs.subshell_pairs.count, true));

  for *subshell_pair : pairs.subshell_pairs {
    check(is_in_range(subshell_pair.cgto_pairs.count, 0, pairs.cgto_pairs.count, true));

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

  update_basis_pairs(*pairs, geometry); // why is this here?
} @Test

test_basis :: () {
  test_print("Checking that basis gets set up correctly");
  basis := get_test_basis();
  defer free(basis);

  // Actual validation
  for *shell, i : basis.shells {
    check_eq(i, shell.angular_momentum);
  }

  for *shell, i : basis.shells if i < basis.shells.count-1 {
    next_shell := *basis.shells[i+1];
    check(next_shell.subshells.count == 0 || *next_shell.subshells[0] == shell.subshells.data + shell.subshells.count);
  }

  for *subshell, i : basis.subshells if i < basis.subshells.count-1 {
    next_subshell := *basis.subshells[i+1];
    check(*next_subshell.cgtos[0] == subshell.cgtos.data + subshell.cgtos.count);
  }

  for *cgto, i : basis.cgtos if i < basis.cgtos.count-1 {
    next_cgto := *basis.cgtos[i+1];
    check(*next_cgto.gtos[0] == cgto.gtos.data + cgto.gtos.count);
  }
} @Test

#scope_file

#import "test_util"; // for setting up the specific basis
#import "check";

#import "chemistry";
#import "util"; // for I/O
#import "math"; // Vector3

#import "Basic";

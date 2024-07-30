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
  for *shell_pair,i : pairs.shell_pairs
    check(is_in_range(shell_pair.subshell_pairs.count, 0, pairs.subshell_pairs.count, true), print_on_success=i==0);

  for *subshell_pair,i : pairs.subshell_pairs {
    check(is_in_range(subshell_pair.cgto_pairs.count, 0, pairs.cgto_pairs.count, true), print_on_success=i==0);

      start := pairs.cgto_pairs.data;
      end := pairs.cgto_pairs.data + pairs.cgto_pairs.count;
      for *cgto_pair,j : pairs.cgto_pairs
       check(is_in_range(cgto_pair.gto_pairs.count, 0, pairs.gto_pairs.count, true), print_on_success=i+j==0);
      for *subshell_pair,j : pairs.subshell_pairs {
        local_pairs := *subshell_pair.cgto_pairs;
        check(is_in_range(local_pairs.data, start, end, false), print_on_success=i+j==0);
        check(is_in_range(local_pairs.data + local_pairs.count, start, end, true), print_on_success=i+j==0);
      }
  }

  update_basis_pairs(*pairs, geometry); // why is this here?
} @Test

test_basis :: () {
  test_print("Checking that basis gets set up correctly");
  basis := get_test_basis();
  defer free(basis);

  check_eq(basis.shells[0].angular_momentum, 0);
  check_eq(basis.shells[0].subshells.count, 2);
  check_eq(basis.shells[0].subshells[0].i_atom, 0); // H
  check_eq(basis.shells[0].subshells[1].i_atom, 1); // F
  check_eq(basis.shells[1].angular_momentum, 1);
  check_eq(basis.shells[1].subshells.count, 1);
  check_eq(basis.shells[1].subshells[0].i_atom, 1); // F
  check_eq(basis.shells[2].angular_momentum, 2);
  check_eq(basis.shells[2].subshells.count, 0);

  check_eq(basis.subshells[0].i_atom, 0);
  check_eq(basis.subshells[0].cgtos.count, 2); // 2 S CGTOs for H
  check_eq(basis.subshells[1].i_atom, 1);
  check_eq(basis.subshells[1].cgtos.count, 3); // 3 S CGTOs for F
  check_eq(basis.subshells[2].i_atom, 1);
  check_eq(basis.subshells[2].cgtos.count, 6); // 6 P CGTOs for F
  // The ordering is each P orbital, then magnetic quantum number (P1x, P1y, P1z, P2x, P2y, ...)
  check_eq(basis.subshells[2].cgtos[0].m, 0);
  check_eq(basis.subshells[2].cgtos[1].m, 1);
  check_eq(basis.subshells[2].cgtos[2].m, 2);
  check_eq(basis.subshells[2].cgtos[3].m, 0);


  // Actual validation
  for *shell, i : basis.shells {
    check_eq(i, shell.angular_momentum, print_on_success=i==0);
  }

  for *shell, i : basis.shells if i < basis.shells.count-1 {
    next_shell := *basis.shells[i+1];
    check(next_shell.subshells.count == 0 || *next_shell.subshells[0] == shell.subshells.data + shell.subshells.count, print_on_success=i==0);
  }

  for *subshell, i : basis.subshells if i < basis.subshells.count-1 {
    next_subshell := *basis.subshells[i+1];
    check(*next_subshell.cgtos[0] == subshell.cgtos.data + subshell.cgtos.count, print_on_success=i==0);
  }

  for *cgto, i : basis.cgtos if i < basis.cgtos.count-1 {
    next_cgto := *basis.cgtos[i+1];
    check(*next_cgto.gtos[0] == cgto.gtos.data + cgto.gtos.count, print_on_success=i==0);
  }
} @Test

#scope_file

#import "test_util"; // for setting up the specific basis
#import "check";

#import "chemistry";
#import "util"; // for I/O
#import "math"; // Vector3

#import "Basic";

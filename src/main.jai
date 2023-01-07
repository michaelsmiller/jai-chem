SimulationArguments :: struct {
  // @note: important detail here is that we currently EXPECT basis files
  //        to exist in the basis folder, while theoretically any geometry can
  //        be passed. Could eventually just move to check if the path works
  //        appended to "project_dir/basis/" and then treat it as an absolute path
  //        or relative path to the executable otherwise, so that people can use
  //        custom basis sets no problem
  input := "geometry/h2.xyz";
  basis := "3-21g.gbs";
  test  := false;
}

main :: () {
  success, args, is_set, _ := parse_arguments(SimulationArguments, Argument_Flags.SORT_HELP|.ALIGN_HELP|.SHOW_HELP_ON_ERROR);
  if !success {
    print("Parsing input args failed.\n");
    exit(0);
  }

  if is_set.test {
    Test.run_tests();
    return;
  }

  print("\nReading Basis parameters from file '%'\n\n", args.basis);
  basis_params := read_basis_file(tprint("basis/%", args.basis));
  defer free(basis_params);

  print("Reading system from input file '%'\n", args.input);
  atoms, geometry := read_geometry_from_xyz_file(args.input);
  print("%\n", atoms);

  print("\nGENERATING BASIS\n\n");
  basis := create_basis(*basis_params, atoms);
  defer free(basis);
  basis_pairs := create_basis_pairs(*basis);
  update_basis_pairs(*basis_pairs, geometry);

  print("\nCOMPUTING INTEGRALS\n\n");
  n := basis.cgtos.count;
  overlap_matrix := create(n);
  defer free(overlap_matrix);
  compute_overlap(*basis, geometry, .{0, 0, 0}, *overlap_matrix);
  print_matrix(*overlap_matrix);


  print("\nExiting successfully.\n");
}

#scope_file

#import "Basic";
#import "Command_Line"; // for parse_arguments()
String :: #import "String";

#load "constants.jai";
#import "chemistry";
#import "util";
#import "math";
#import "integrals";

Test :: #import "tests"; // for running tests only
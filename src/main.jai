SimulationArguments :: struct {
  input := "test/h2.xyz";
  basis := "3-21g.gbs";
}

main :: () {
  success, args, is_set, _ := parse_arguments(SimulationArguments, Argument_Flags.SORT_HELP|.ALIGN_HELP|.SHOW_HELP_ON_ERROR);
  if !success {
    print("Parsing input args failed.\n");
    exit(0);
  }

  print("\nReading Basis parameters from file '%'\n\n", args.basis);
  basis_params := read_basis_file(tprint("basis/%", args.basis));

  print("Reading system from input file '%'\n", args.input);
  atoms, geometry := read_geometry_from_xyz_file(args.input);
  print("%\n", atoms);

  print("\nGENERATING BASIS\n\n");
  basis := create_basis(*basis_params, atoms);
  defer free(*basis);
  // basis_pairs : BasisPairs;
  // init_basis_pairs(*basis, *basis_pairs);

  // print("\nCOMPUTING INTEGRALS\n\n");
  // n := basis.cgtos.count;
  // overlap_matrix := create(n);
  // defer free(overlap_matrix);
  // compute_overlap(*basis, geometry, .{0, 0, 0}, *overlap_matrix);
  // print_matrix(*overlap_matrix);


  print("\nExiting successfully.\n");
}

#scope_file

#import "Basic";
#import "Command_Line"; // for parse_arguments()

#load "constants.jai";
#import "chemistry";
#import "util";
#import "math";
#import "integrals";

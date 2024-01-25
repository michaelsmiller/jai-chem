#scope_export

validate_constants :: () {
    perform_test(
      "Checking derived constants", #code {
        check_close(FINE_STRUCTURE_CONSTANT, 0.0072973525693); // unitless
        check_close(BOHR_RADIUS, 5.29177210903E-11); // meters
      }
  );
}

validate_geometry_parsing :: () {
   perform_test(
     "Reading geometry file works", #code {
        atoms, geometry := read_geometry_from_xyz_file("geometry/h2.xyz");
        check(geometry.count == atoms.count);
        check(geometry.count == 2);
        A := geometry[0];
        B := geometry[1];
        check(A.x == 0);
        check(B.x == ANGSTROM_TO_BOHR);
     }
   );
}

#scope_file

#load "test_util.jai";
#import "constants";

#import "chemistry";
#import "util"; // for I/O
#import "math"; // Vector3

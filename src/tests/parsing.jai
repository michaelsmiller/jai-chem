#scope_export

validate_constants :: () {
    log_info("FINE STRUCTURE CONSTANT: %\n", formatFloat(FINE_STRUCTURE_CONSTANT, mode=.SCIENTIFIC));
    log_info("BOHR RADIUS (m): %\n", formatFloat(BOHR_RADIUS, mode=.SCIENTIFIC));
}

validate_geometry_parsing :: () {
   perform_test(
     "Parsing geometry file", #code {
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

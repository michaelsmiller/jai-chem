#scope_export

test_constants :: () {
    test_print("Checking derived constants");
    check_close(FINE_STRUCTURE_CONSTANT, 0.0072973525693); // unitless
    check_close(BOHR_RADIUS, 5.29177210903E-11); // meters
} @Test

test_geometry_parsing :: () {
   test_print("Reading geometry file works");

    atoms, geometry := read_geometry_from_xyz_file("geometry/h2.xyz");
    check(geometry.count == atoms.count);
    check(geometry.count == 2);
    A := geometry[0];
    B := geometry[1];
    check_eq(A.x, 0);
    check_eq(B.x, ANGSTROM_TO_BOHR);
}

#scope_file

#import "check";

#import "constants";
#import "chemistry";
#import "util"; // for I/O
#import "math"; // Vector3

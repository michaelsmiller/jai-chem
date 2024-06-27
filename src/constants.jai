#scope_export

PLANCK            : f64 : 6.62607015E-34;
ELEMENTARY_CHARGE : f64 : 1.602176634E-19;
ELECTRON_MASS     : f64 : 9.109383701528E-31;
AVOGADRO          : f64 : 6.02214076E23;
PERMITTIVITY      : f64 : 8.8541878128E-12;
SPEED_OF_LIGHT    : f64 : 299792458;

// Derived intermediates
REDUCED_PLANCK    : f64 : h / (2 * pi);
COULOMB_CONSTANT : f64 : 1. / (4 * pi * e0);
FINE_STRUCTURE_CONSTANT : f64 : k * e * e / (hbar * c);

// Atomic Units conversions
BOHR_RADIUS      : f64 : hbar / (a * me * c);
BOHR_TO_ANGSTROM : f64 : a0 * 1.e10;
ANGSTROM_TO_BOHR : f64 : 1. / BOHR_TO_ANGSTROM;

JOULE_TO_HARTREE : f64 : hbar * hbar / (me * a0 * a0);
KJPERMOLE_TO_HARTREE : f64 : JOULE_TO_HARTREE * 1000. / Na;



#scope_file

// Helpful file-local shorthand
e    : f64 : ELEMENTARY_CHARGE;
e0   : f64 : PERMITTIVITY;
hbar : f64 : REDUCED_PLANCK;
h    : f64 : PLANCK;
me   : f64 : ELECTRON_MASS;
Na   : f64 : AVOGADRO;
pi   : f64 : Math.PI64;
c    : f64 : SPEED_OF_LIGHT;
k    : f64 : COULOMB_CONSTANT;
a    : f64 : FINE_STRUCTURE_CONSTANT;
a0   : f64 : BOHR_RADIUS;

#import "util";
Math :: #import "Math";

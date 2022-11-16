#scope_export

PLANCK            : f64 : 6.62607015e-34;
ELEMENTARY_CHARGE : f64 : 1.602176634e-19;
ELECTRON_MASS     : f64 : 9.109383701528e-31;
AVOGADRO          : f64 : 6.02214076e23;
PERMITTIVITY      : f64 : 8.8541878128e-12;

// Derived intermediates
PI                : f64 : Math.PI;
REDUCED_PLANCK    : f64 : 2 * pi * h;


// Atomic Units conversions
BOHR_RADIUS       : f64 : 4 * pi * e0 * hbar * hbar / (me * e * e);
ANGSTROM_TO_BOHR : f64 : a0 * 1.e-10;
BOHR_TO_ANGSTROM : f64 : 1. / ANGSTROM_TO_BOHR;

JOULE_TO_HARTREE : f64 : hbar * hbar / (me * a0 * a0);
KJPERMOLE_TO_HARTREE : f64 : JOULE_TO_HARTREE * 1.e-3 * Na;



#scope_file

// Helpful file-local shorthand
e    :: ELEMENTARY_CHARGE;
e0   :: PERMITTIVITY;
hbar :: REDUCED_PLANCK;
h    :: PLANCK;
me   :: ELECTRON_MASS;
Na   :: AVOGADRO;
pi   :: PI;
a0   :: BOHR_RADIUS;


#import "util";
Math :: #import "Math";

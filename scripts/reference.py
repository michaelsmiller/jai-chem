#!/usr/bin/env python

import pyscf
from pyscf.gto.basis.parse_gaussian import parse as parse_gaussian
from pyscf.gto.mole import Mole
import os
from pathlib import Path

def create_molecule(geometry_name : str, basis_name : str) -> Mole:
    root_dir = Path(".")
    geometry_dir = root_dir / "test" /  "geometry"
    geometry_path = geometry_dir / geometry_name

    with open(geometry_path) as f:
        lines = f.readlines()
        geometry_string = "\n".join(lines[2:]) # remove first 2 lines

    molecule = pyscf.M(atom=geometry_string, basis=basis_name)
    return molecule

def main():
    geometry_name = "h2.xyz"
    basis_name = '3-21g'
    logfilename = "test.log"

    mol = create_molecule(geometry_name, basis_name)
    # print("Occupancy:", mol.get_occ())
    mol.output = logfilename
    overlap = mol.intor('int1e_ovlp')
    print(overlap)

    print(mol.nbas, mol.nao_nr())
    print(sum(mol.bas_nctr(i) for i in range(mol.nbas)))


if __name__ == "__main__":
    main()

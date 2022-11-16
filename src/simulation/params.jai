#scope_export

SimulationType :: enum u8 {
  SINGLE_POINT;
  MINIMIZATION;
  DYNAMICS;
}

SimulationParameters :: struct {
  simulation_type : SimulationType = .SINGLE_POINT;
  initial_geometry : [..] Atom;
}

#scope_file

#import "chemistry";

Vector3 :: struct {
  x, y, z : f64;
  #overlay (x) vec : [3] f64 = ---;
}

make_vector :: inline (x : f64, y : f64, z : f64) -> Vector3 {
  v : Vector3 = ---;
  v.x = x;
  v.y = y;
  v.z = z;
  return v;
}

operator * :: (c : $T, v : Vector3) -> Vector3 #symmetric #modify {
  ti := cast(*Type_Info) T;
  return ti.type == .INTEGER || ti.type == .FLOAT, "Argument is not scalar type";
}{
  f := cast(f64) c; // assume casting is fine
  return make_vector(
    f * v.x,
    f * v.y,
    f * v.z
  );
}

operator / :: (v : Vector3, c : $T) -> Vector3 {
  #if true {
    assert(c != 0);
  }
  return (1. / c) * v;
}

operator + :: (a : Vector3, b : Vector3) -> Vector3 {
  return make_vector(
    a.x + b.x,
    a.y + b.y,
    a.z + b.z
  );
}

operator - :: (a : Vector3, b : Vector3) -> Vector3 {
  return make_vector(
    a.x - b.x,
    a.y - b.y,
    a.z - b.z
  );
}

operator - :: (a : Vector3) -> Vector3 {
  return make_vector(
    -a.x,
    -a.y,
    -a.z
  );
}

operator == :: inline (a : Vector3, b : Vector3) -> bool {
  return a.vec == b.vec;
}

dot :: inline (a : Vector3, b : Vector3) -> f64 {
  return a.x * b.x + a.y * b.y + a.z * b.z;
}

norm2 :: inline (a : Vector3) -> f64 {
  return a.x * a.x + a.y * a.y + a.z * a.z;
}

#scope_file

#import "Basic"; // assert

#import "util"; // f64

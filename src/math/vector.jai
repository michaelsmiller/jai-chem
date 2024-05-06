VecSlice :: struct {
  count: int;
  stride: int;
  data: *f64;
}


get :: inline (v : VecSlice, i: int) -> f64 {
  assert(i >= 0 && i < v.count);
  return v.data[i*v.stride];
}


set :: inline (v : VecSlice, i: int, value: f64) {
  assert(i >= 0 && i < v.count);
  v.data[i*v.stride] = value;
}


add :: (a: VecSlice, b: VecSlice, c: VecSlice) {
  assert(a.count == b.count && b.count == c.count);
  for i: 0..a.count-1 {
    ci := get(a, i) + get(b, i);
    set(c, i, ci);
  }
}


negate :: (a: VecSlice) {
  for i: 0..a.count-1 {
    ai := get(a, i);
    set(a, i, -ai);
  }
}


dot :: (a: VecSlice, b: VecSlice) -> f64 {
  assert(a.count == b.count);
  result : f64 = 0;
  for i: 0..a.count-1 result += get(a, i) * get(b, i);
  return result;
}


make_slice :: inline (array : [] f64) -> VecSlice {
  v := VecSlice.{array.count, 1, array.data};
  return v;
}

copy :: (a: VecSlice, b: VecSlice) {
  assert(a.count <= b.count);
  for i: 0..a.count-1 set(b, i, get(a, i));
}

copy :: (v: VecSlice, array: [] f64) {
  assert(v.count <= array.count);
  v2 := make_slice(array);
  copy(v, v2);
}

to_array :: (v: VecSlice) -> [] f64 {
  array := NewArray(v.count, f64, true);
  copy(v, array);
  return array;
}

#scope_file

#import "util"; // f64
#import "Basic"; // assert

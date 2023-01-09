#scope_export

Element :: enum u8 {
  NULL       :: 0; // might only need this to generate hashmaps correctly

  HYDROGEN   :: 1;
  HELIUM     :: 2;
  LITHIUM    :: 3;
  BERYLLIUM  :: 4;
  BORON      :: 5;
  CARBON     :: 6;
  NITROGEN   :: 7;
  OXYGEN     :: 8;
  FLUORINE   :: 9;
  NEON       :: 10;
  SODIUM     :: 11;
  MAGNESIUM  :: 12;
  ALUMINUM   :: 13;
  SILICON    :: 14;
  PHOSPHORUS :: 15;
  SULFUR     :: 16;
  CHLORINE   :: 17;
  ARGON      :: 18;
  POTASSIUM  :: 19;
  CALCIUM    :: 20;
}
NUM_ELEMENTS :: #run 1 + enum_highest_value(Element);

ElementInfo :: struct {
  element : Element = .NULL;
  name      : string; // e.g. "Hydrogen"
  shortname : string; // e.g. "H"
  atomic_number : s8;
  mass          : f64; // au
  // @todo: add radius for easy copying over to graphics
  // @todo: add default color for graphics
}

ELEMENT_ATTRIBUTES :: ElementInfo.[
  .{.NULL,       "Null",       "NA", 0 , 0.0000000000},
  .{.HYDROGEN,   "Hydrogen",   "H",  1 , 1.0000000000},
  .{.HELIUM,     "Helium",     "He", 2 , 4.0026032500},
  .{.LITHIUM,    "Lithium",    "Li", 3 , 7.0160045000},
  .{.BERYLLIUM,  "Beryllium",  "Be", 4 , 9.0121825000},
  .{.BORON,      "Boron",      "B",  5 , 11.009305300},
  .{.CARBON,     "Carbon",     "C",  6 , 12.000000000},
  .{.NITROGEN,   "Nitrogen",   "N",  7 , 14.003074008},
  .{.OXYGEN,     "Oxygen",     "O",  8 , 15.994914640},
  .{.FLUORINE,   "Fluorine",   "F",  9 , 18.998403250},
  .{.NEON,       "Neon",       "Ne", 10, 19.992439100},
  .{.SODIUM,     "Sodium",     "Na", 11, 22.989769700},
  .{.MAGNESIUM,  "Magnesium",  "Mg", 12, 23.985045000},
  .{.ALUMINUM,   "Aluminum",   "Al", 13, 26.981541300},
  .{.SILICON,    "Silicon",    "Si", 14, 27.976928400},
  .{.PHOSPHORUS, "Phosphorus", "P",  15, 30.973763400},
  .{.SULFUR,     "Sulfur",     "S",  16, 31.972071800},
  .{.CHLORINE,   "Chlorine",   "Cl", 17, 34.968852729},
  .{.ARGON,      "Argon",      "Ar", 18, 39.962383100},
  .{.POTASSIUM,  "Potassium",  "K",  19, 39.098300000},
  .{.CALCIUM,    "Calcium",    "Ca", 20, 40.078000000}
];
// Must have 1 element for everything
#assert(ELEMENT_ATTRIBUTES.count == NUM_ELEMENTS);
#run {
  for x, i : ELEMENT_ATTRIBUTES
    assert(i == cast(s64) x.element);
};

get_element_info :: (element : Element) -> ElementInfo {
  return ELEMENT_ATTRIBUTES[element];
}

// gets the element from the short name
// Can use the element to get any kind of atomic info
name_to_element :: (name : string) -> Element {
  element, success := HTable.table_find(*ELEMENT_NAME_TO_ELEMENT, name);
  if !success {
    return .NULL;
  }
  return element;
}


// Meant to be used as an interface, not as a struct by itself
HasElement :: struct {
  element : Element;
};

pick_item_with_element :: (items : [] $T/HasElement, element : Element) -> *T {
  for *items if it.element == element return it;
  error("Unable to find item of type '%' with element '%'", T, element);
  return null;
}

#scope_file

// Hash map to do the backend of the lookups
// djb2 is the perfect hash for the short strings, since they will all map to something different
ElementPropertiesMap :: HTable.Table(string, Element, Hash.djb2_hash);
ELEMENT_NAME_TO_ELEMENT :: #run () -> ElementPropertiesMap {
  table : ElementPropertiesMap;
  for element : enum_values_as_enum(Element) {
    HTable.table_add(*table, ELEMENT_ATTRIBUTES[element].shortname, element);
  }
  return table;
}();

#import "Basic";
Hash :: #import "Hash";
HTable :: #import "Hash_Table";

#import "util";

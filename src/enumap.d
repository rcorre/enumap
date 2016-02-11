/**
 * An `Enumap` maps each member of an enum to a single value.
 *
 * An `Enumap` is effectively a lightweight associative array with some benefits.
 *
 * You can think of an `Enumap!(MyEnum, int)` somewhat like a `int[MyEnum]`,
 * with the following differences:
 *
 * - `Enumap!(K,V)` is a value type and requires no dynamic memory allocation
 *
 * - `Enumap!(K,V)` has a pre-initialized entry for every member of `K`
 *
 * - `Enumap!(K,V)` supports the syntax `map.name` as an alias to `map[K.name]`
 *
 * - `Enumap!(K,V)` supports array-wise operations
 *
 * Authors: Ryan Roden-Corrent ($(LINK2 https://github.com/rcorre, rcorre))
 * License: MIT
 * Copyright: © 2015, Ryan Roden-Corrent
 *
 * Examples:
 * Suppose you are building a good ol' dungeon-crawling RPG.
 * Where to start? How about the classic 6 attributes:
 *
 * ---
 * enum Attribute {
 *  strength, dexterity, constitution, wisdom, intellect, charisma
 * };
 *
 * struct Character {
 *  Enumap!(Attribute, int) attributes;
 * }
 * ---
 *
 * Lets roll some stats!
 *
 * ---
 * Character hero;
 * hero.attributes = sequence!((a,n) => uniform!"[]"(0, 20))().take(6);
 * ---
 *
 * Note that we can assign directly from a range!
 * Just like static array assignment, it will fail if the length doesn't match.
 *
 * We can access those values using either `opIndex` or `opDispatch`:
 *
 * ---
 * if (hero.attributes[Attribute.wisdom] < 5) hero.drink(unidentifiedPotion);
 * // equivalent
 * if (hero.attributes.wisdom < 5) hero.drink(unidentifiedPotion);
 * ---
 *
 * We can also perform binary operations between `Enumap`s:
 *
 * ---
 * // note the convenient assignment from an associative array:
 * Enumap!(Attribute, int) bonus = {Attribute.charisma: 2, Attribute.wisom: 1};
 *
 * // level up! adds 2 to charisma and 1 to wisdom.
 * hero.attributes += bonus;
 * ---
 *
 * Finally, note that we can break the `Enumap` down into a range when needed:
 *
 * ---
 * hero.attributes = hero.attributes.byValue.map!(x => x + 1);
 * ---
 *
 * See the full documentation of `Enumap` for all the operations it supports.
 *
 */
module enumap;

import std.conv      : to;
import std.range;
import std.traits    : Unqual, EnumMembers;
import std.typecons  : tuple, staticIota;
import std.algorithm : map;

/**
 * A structure that maps each member of an enum to a single value.
 *
 * An `Enumap` is a lightweight alternative to an associative array that is
 * useable when your key type is an enum.
 *
 * It provides some added benefits over the AA, such as array-wise operations,
 * default values for all keys, and some nice `opDispatch` based syntactic
 * sugar for element access.
 *
 * The key enum must be backed by an integral type and have 'default' numbering.
 * The backing value must start at 0 and grows by 1 for each member.
 *
 * Params:
 * K = The type of enum used as a key.
 *     The enum values must start at 0, and increase by 1 for each entry.
 * V = The type of value stored for each enum member
 */
struct Enumap(K, V)
  if(EnumMembers!K == staticIota!(0, EnumMembers!K.length))
{
  /// The number of entries in the `Enumap`
  enum length = EnumMembers!K.length;

  /// Assuming Element consists of air, earth, water, and fire (4 members):
  unittest {
    static assert(Enumap!(Element, int).length == 4);
  }

  private V[length] _store;

  /// Construct an Enumap from a static array.
  this(V[length] values) {
    _store = values;
  }

  ///
  @nogc unittest {
    auto elements = Enumap!(Element, int)([1, 2, 3, 4]);

    assert(elements[Element.air]   == 1);
    assert(elements[Element.earth] == 2);
    assert(elements[Element.water] == 3);
    assert(elements[Element.fire]  == 4);
  }

  /// Assign from a range with a number of elements exactly matching `length`.
  this(R)(R values) if (isInputRange!R && is(ElementType!R : V)) {
    int i = 0;
    foreach(val ; values) {
      assert(i < length, "range contains more values than Enumap");
      _store[i++] = val;
    }
    assert(i == length, "range contains less values than Enumap");
  }

  ///
  @nogc unittest {
    import std.range : repeat;
    Enumap!(Element, int) elements = 9.repeat(4);
    assert(elements.air   == 9);
    assert(elements.earth == 9);
    assert(elements.water == 9);
    assert(elements.fire  == 9);
  }

  /// An Enumap can be assigned from an array or range of values
  void opAssign(T)(T val) if (is(typeof(typeof(this)(val)))) {
    this = typeof(this)(val);
  }

  /// Assign an Enumap from a static array.
  @nogc unittest {
    Enumap!(Element, int) elements;
    int[elements.length] arr = [1, 2, 3, 4];
    elements = arr;

    with (Element) {
      assert(elements[air]   == 1);
      assert(elements[earth] == 2);
      assert(elements[water] == 3);
      assert(elements[fire]  == 4);
    }
  }

  /// Assign an Enumap from a range
  @nogc unittest {
    import std.range : iota;

    Enumap!(Element, int) elements;

    with (Element) {
      elements = iota(0, 4);

      assert(elements[air]   == 0);
      assert(elements[earth] == 1);
      assert(elements[water] == 2);
      assert(elements[fire]  == 3);
    }
  }

  /**
   * Access the value at the index specified by an enum member.
   *
   * Indexing returns a reference, so it can be used as a getter or setter.
   */
  ref auto opIndex(K key) inout {
    return _store[key];
  }

  ///
  @nogc unittest {
    Enumap!(Element, int) elements;
    elements[Element.fire] = 4;
    assert(elements[Element.fire] == 4);
  }

  /**
   * Access the value at the index specified by the name of an enum member.
   *
   * The value is returned by reference, so it can used for assignment.
   * `map.name` is just syntactic sugar for `map[SomeEnum.name]`.
   */
  ref auto opDispatch(string s)() inout {
    enum key = s.to!K;
    return this[key];
  }

  ///
  @nogc unittest {
    Enumap!(Element, int) elements;
    elements.water = 5;
    assert(elements.water == 5);
  }

  /// Execute a foreach statement over (EnumMember, value) pairs.
  int opApply(scope int delegate(K, const V) dg) const {
    // declare the callee as @nogc so @nogc callers can use foreach
    // oddly, this works even if dg is non-nogc... huh?
    // I'm just gonna take this and run before the compiler catches me.
    alias nogcDelegate = @nogc int delegate(K, const V);
    auto callme = cast(nogcDelegate) dg;

    int res = 0;

    foreach(key ; EnumMembers!K) {
      res = callme(key, this[key]);
      if (res) break;
    }

    return res;
  }

  /// foreach iterates over (EnumMember, value) pairs.
  @nogc unittest {
    const auto elements = enumap(Element.water, 4, Element.air, 3);

    foreach(key, value ; elements) {
      assert(
          key == Element.water && value == 4 ||
          key == Element.air   && value == 3 ||
          value == 0);
    }
  }

  /// Execute foreach over (EnumMember, ref value) pairs to modify elements.
  int opApply(scope int delegate(K, ref V) dg) {
    // declare the callee as @nogc so @nogc callers can use foreach
    // oddly, this works even if dg is non-nogc... huh?
    // I'm just gonna take this and run before the compiler catches me.
    alias nogcDelegate = @nogc int delegate(K, ref V);
    auto callme = cast(nogcDelegate) dg;

    int res = 0;

    foreach(key ; EnumMembers!K) {
      res = callme(key, this[key]);
      if (res) break;
    }

    return res;
  }

  /// foreach can modify values by ref
  @nogc unittest {
    Enumap!(Element, int) elements;

    foreach(key, ref value ; elements) {
      if      (key == Element.air)   value = 4;
      else if (key == Element.water) value = 2;
    }

    assert(elements.air   == 4);
    assert(elements.water == 2);
  }

  // make sure you can foreach with a non-nogc delegate
  unittest {
    foreach(key, ref value ; enumap(Element.water, "here comes..."))
      value ~= "a spurious allocation!";
  }

  /// Apply an array-wise operation between two `Enumap`s.
  auto opBinary(string op)(inout typeof(this) other) const
    if (is(typeof(mixin("V.init"~op~"V.init")) : V))
  {
    Unqual!(typeof(this)) result;

    foreach(member ; EnumMembers!K) {
      result[member] = mixin("this[member]"~op~"other[member]");
    }

    return result;
  }

  ///
  @nogc unittest {
    immutable base  = enumap(Element.water, 4, Element.air , 3);
    immutable bonus = enumap(Element.water, 5, Element.fire, 2);

    immutable sum  = base + bonus;
    immutable diff = base - bonus;
    immutable prod = base * bonus;

    assert(sum.water == 4 + 5);
    assert(sum.air   == 3 + 0);
    assert(sum.fire  == 0 + 2);
    assert(sum.earth == 0 + 0);

    assert(diff.water == 4 - 5);
    assert(diff.air   == 3 - 0);
    assert(diff.fire  == 0 - 2);
    assert(diff.earth == 0 - 0);

    assert(prod.water == 4 * 5);
    assert(prod.air   == 3 * 0);
    assert(prod.fire  == 0 * 2);
    assert(prod.earth == 0 * 0);
  }

  ///
  unittest {
    auto inventory = enumap(
        ItemType.junk  , [ "Gemstone"        ],
        ItemType.normal, [ "Sword", "Shield" ],
        ItemType.key   , [ "Bronze Key"      ]);

    auto loot = enumap(
        ItemType.junk  , [ "Potato"       ],
        ItemType.normal, [ "Potion"       ],
        ItemType.key   , [ "Skeleton Key" ]);

    inventory ~= loot;

    assert(inventory.junk   == [ "Gemstone", "Potato"          ]);
    assert(inventory.normal == [ "Sword", "Shield" , "Potion"  ]);
    assert(inventory.key    == [ "Bronze Key" , "Skeleton Key" ]);
  }

  /// Perform an in-place operation.
  auto opOpAssign(string op)(inout typeof(this) other)
    if (is(typeof(this.opBinary!op(other)) : typeof(this)))
  {
    this = this.opBinary!op(other);
  }

  ///
  @nogc unittest {
    auto  base  = enumap(Element.water, 4, Element.air , 3);
    const bonus = enumap(Element.water, 5, Element.fire, 2);

    base += bonus;

    assert(base.water == 4 + 5);
    assert(base.air   == 3 + 0);
    assert(base.fire  == 0 + 2);
    assert(base.earth == 0 + 0);

    base -= bonus; // cancel out the previous addition

    assert(base.water == 4);
    assert(base.air   == 3);
    assert(base.fire  == 0);
    assert(base.earth == 0);

    base *= bonus;
    assert(base.water == 4 * 5);
    assert(base.air   == 3 * 0);
    assert(base.fire  == 0 * 2);
    assert(base.earth == 0 * 0);
  }

  /// Perform a unary operation on each entry.
  auto opUnary(string op)() const
    if (is(typeof(mixin(op~"V.init")) : V))
  {
    V[length] result = mixin(op~"_store[]");
    return typeof(this)(result);
  }

  @nogc unittest {
    immutable elements = enumap(Element.water, 4);
    assert((-elements).water == -4);
  }

  /// Get a range iterating over the members of the enum `K`.
  auto byKey() const { return only(EnumMembers!K); }

  @nogc unittest {
    import std.range     : only;
    import std.algorithm : equal;

    Enumap!(Element, int) e;
    with (Element) {
      assert(e.byKey.equal(only(air, earth, water, fire)));
    }
  }

  /// Get a range iterating over the stored values.
  auto byValue() inout { return _store[]; }

  /// you can use byValue to perform range based operations on the values:
  @nogc unittest {
    import std.range     : iota;
    import std.algorithm : map, equal;

    const Enumap!(Element, int) e1 = iota(0, 4);
    const Enumap!(Element, int) e2 = e1.byValue.map!(x => x + 2);
    assert(e2.byValue.equal(iota(2, 6)));
  }

  /// `byValue` supports ref access:
  @nogc unittest {
    with (Element) {
      auto elements = enumap(air, 1, water, 2, fire, 3, earth, 4);
      foreach(ref val ; elements.byValue) ++val;
      assert(elements == enumap(air, 2, water, 3, fire, 4, earth, 5));
    }
  }

  /**
   * Return a range of (EnumMember, value) pairs.
   *
   * Note that byKeyValue does _not_ support modifying the underlying values by
   * reference.
   * For that, you should just use foreach directly (see `opApply`).
   */
  auto byKeyValue() const {
    return only(EnumMembers!K).map!(key => tuple(key, this[key]));
  }

  ///
  @nogc unittest {
    import std.typecons  : tuple;
    import std.algorithm : map;

    immutable elements = enumap(Element.water, 4, Element.air, 3);

    auto pairs = elements.byKeyValue.map!(pair => tuple(pair[0], pair[1] + 1));

    foreach(key, value ; pairs) {
      assert(
          key == Element.water && value == 5 ||
          key == Element.air   && value == 4 ||
          value == 1);
    }
  }
}

  /**
   * Construct an `Enumap` from a sequence of key/value pairs.
   *
   * Any values not specified default to `V.init`.
   */
@nogc auto enumap(T...)(T pairs) if (T.length >= 2 && T.length % 2 == 0) {
  alias K = T[0];
  alias V = T[1];

  Enumap!(K, V) result;

  // pop a key/vaue pair, assign it to the enumap, and recurse until empty
  void helper(U...)(U params) {
    static assert(is(U[0] == K), "enumap: mismatched key type");
    static assert(is(U[1] == V), "enumap: mismatched value type");

    auto key = params[0];
    auto val = params[1];

    result[key] = val;

    static if (U.length > 2) {
      helper(params[2..$]);
    }
  }

  helper(pairs);
  return result;
}

///
@nogc unittest {
  with (Element) {
    auto elements = enumap(air, 1, earth, 2, water, 3);

    assert(elements[air]   == 1);
    assert(elements[earth] == 2);
    assert(elements[water] == 3);
    assert(elements[fire]  == 0); // unspecified values default to V.init
  }
}

version (unittest) {
  // define some enums for testing
  private enum Element { air, earth, water, fire };
  private enum ItemType { junk, normal, key };
}

// make sure the readme examples work:
unittest {
  import std.algorithm, std.range, std.random;

  enum Attribute {
    strength, dexterity, constitution, wisdom, intellect, charisma
  }

  Enumap!(Attribute, int) attributes;
  assert(attributes.wisdom == 0); // default value check

  attributes[Attribute.strength] = 10;

  attributes = generate!(() => uniform!"[]"(1, 20)).take(6);

  // make sure accessors compile:
  if (attributes[Attribute.wisdom] < 5) { }
  if (attributes.wisdom < 5) { }

  // key/value constructor
  auto bonus = enumap(Attribute.charisma, 2, Attribute.wisdom, 1);

  // opBinary
  attributes += bonus;

  // nogc test
  void donFancyHat(int[Attribute] attrs) { attrs[Attribute.charisma] += 1; }
  @nogc void donFancyHat2(Enumap!(Attribute, int) attrs) { attrs.charisma += 1; }
}

// constness tests:
unittest {
  auto      mmap = enumap(Element.air, 2, Element.water, 4);
  const     cmap = enumap(Element.air, 2, Element.water, 4);
  immutable imap = enumap(Element.air, 2, Element.water, 4);

  // value access permitted on all
  static assert(__traits(compiles, mmap[Element.air] == 2));
  static assert(__traits(compiles, cmap[Element.air] == 2));
  static assert(__traits(compiles, imap[Element.air] == 2));
  static assert(__traits(compiles, mmap.air == 2));
  static assert(__traits(compiles, cmap.air == 2));
  static assert(__traits(compiles, imap.air == 2));

  // value setters only permitted if mutable
  static assert( __traits(compiles, { mmap[Element.air] = 2; }));
  static assert(!__traits(compiles, { cmap[Element.air] = 2; }));
  static assert(!__traits(compiles, { imap[Element.air] = 2; }));
  static assert( __traits(compiles, { mmap.air = 2; }));
  static assert(!__traits(compiles, { cmap.air = 2; }));
  static assert(!__traits(compiles, { imap.air = 2; }));

  // readonly foreach permitted on all
  static assert(__traits(compiles, { foreach(k,v ; mmap) {} }));
  static assert(__traits(compiles, { foreach(k,v ; cmap) {} }));
  static assert(__traits(compiles, { foreach(k,v ; imap) {} }));

  // foreach with modification permitted only if mutable
  static assert( __traits(compiles, { foreach(k, ref v ; mmap) {++v;} }));
  static assert(!__traits(compiles, { foreach(k, ref v ; cmap) {++v;} }));
  static assert(!__traits(compiles, { foreach(k, ref v ; imap) {++v;} }));

  // opBinary permitted on all
  static assert(__traits(compiles, { immutable res = mmap + mmap; }));
  static assert(__traits(compiles, { immutable res = cmap + cmap; }));
  static assert(__traits(compiles, { immutable res = imap + imap; }));
  static assert(__traits(compiles, { immutable res = mmap + imap; }));
  static assert(__traits(compiles, { immutable res = imap + mmap; }));

  // opBinaryAssign permitted only if mutable
  static assert( __traits(compiles, { mmap += mmap; }));
  static assert( __traits(compiles, { mmap += cmap; }));
  static assert( __traits(compiles, { mmap += imap; }));
  static assert(!__traits(compiles, { cmap += mmap; }));
  static assert(!__traits(compiles, { cmap += cmap; }));
  static assert(!__traits(compiles, { imap += imap; }));

  // opUnary permitted on all
  static assert(__traits(compiles, { -mmap; }));
  static assert(__traits(compiles, { -cmap; }));
  static assert(__traits(compiles, { -imap; }));

  // opUnary permitted on all
  static assert(__traits(compiles, { -mmap; }));
  static assert(__traits(compiles, { -cmap; }));
  static assert(__traits(compiles, { -imap; }));

  // byKey permitted on all
  static assert(__traits(compiles, { mmap.byKey; }));
  static assert(__traits(compiles, { cmap.byKey; }));
  static assert(__traits(compiles, { imap.byKey; }));

  // byValue permitted on all
  static assert(__traits(compiles, { foreach(v ; mmap.byValue) {} }));
  static assert(__traits(compiles, { foreach(v ; cmap.byValue) {} }));
  static assert(__traits(compiles, { foreach(v ; imap.byValue) {} }));

  // byValue with ref assignment permitted only if mutable
  static assert( __traits(compiles, { foreach(ref v ; mmap.byValue) ++v; }));
  static assert(!__traits(compiles, { foreach(ref v ; cmap.byValue) ++v; }));
  static assert(!__traits(compiles, { foreach(ref v ; imap.byValue) ++v; }));

  // byKeyValue permitted on all
  static assert(__traits(compiles, { foreach(k, v ; mmap.byKeyValue) {} }));
  static assert(__traits(compiles, { foreach(k, v ; cmap.byKeyValue) {} }));
  static assert(__traits(compiles, { foreach(k, v ; imap.byKeyValue) {} }));
}

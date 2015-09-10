/**
 * An `EnumSet` maps each member of an enum to a single value.
 *
 * An `EnumSet` is effectively a lightweight associative array with some benefits.
 *
 * You can think of an `EnumSet!(MyEnum, int)` somewhat like a `int[MyEnum]`,
 * with the following differences:
 *
 * - `EnumSet!(K,V)` is a value type and requires no dynamic memory allocation
 *
 * - `EnumSet!(K,V)` has a pre-initialized entry for every member of `K`
 *
 * - `EnumSet!(K,V)` supports the syntax `set.name` as an alias to `set[K.name]`
 *
 * - `EnumSet!(K,V)` supports array-wise operations
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
 *  EnumSet!(Attribute, int) attributes;
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
 * We can also perform binary operations between `EnumSet`s:
 *
 * ---
 * // note the convenient assignment from an associative array:
 * EnumSet!(Attribute, int) bonus = {Attribute.charisma: 2, Attribute.wisom: 1};
 *
 * // level up! adds 2 to charisma and 1 to wisdom.
 * hero.attributes += bonus;
 * ---
 *
 * Finally, note that we can break the `EnumSet` down into a range when needed:
 *
 * ---
 * hero.attributes = hero.attributes.byValue.map!(x => x + 1);
 * ---
 *
 * See the full documentation of `EnumSet` for all the operations it supports.
 *
 */
module enumset;

import std.conv      : to;
import std.range;
import std.traits    : EnumMembers;
import std.typecons  : tuple, staticIota;
import std.algorithm : map;

/**
 * A structure that maps each member of an enum to a single value.
 *
 * An `EnumSet` is a lightweight alternative to an associative array that is
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
struct EnumSet(K, V)
  if(EnumMembers!K == staticIota!(0, EnumMembers!K.length))
{
  /// The number of entries in the `EnumSet`
  enum length = EnumMembers!K.length;

  /// Assuming Element consists of air, earth, water, and fire (4 members):
  unittest {
    static assert(EnumSet!(Element, int).length == 4);
  }

  private V[length] _store;

  /// Construct an EnumSet from a static array.
  this(V[length] values) {
    _store = values;
  }

  ///
  @nogc unittest {
    auto set = EnumSet!(Element, int)([1, 2, 3, 4]);

    assert(set[Element.air]   == 1);
    assert(set[Element.earth] == 2);
    assert(set[Element.water] == 3);
    assert(set[Element.fire]  == 4);
  }

  /// Assign from a range with a number of elements exactly matching `length`.
  this(R)(R values) if (isInputRange!R && is(ElementType!R : V)) {
    int i = 0;
    foreach(val ; values) {
      assert(i < length, "range contains more values than EnumSet");
      _store[i++] = val;
    }
    assert(i == length, "range contains less values than EnumSet");
  }

  ///
  @nogc unittest {
    import std.range : repeat;
    EnumSet!(Element, int) elements = 9.repeat(4);
    assert(elements.air   == 9);
    assert(elements.earth == 9);
    assert(elements.water == 9);
    assert(elements.fire  == 9);
  }

  /// An EnumSet can be assigned from an array or range of values
  void opAssign(T)(T val) if (is(typeof(typeof(this)(val)))) {
    this = typeof(this)(val);
  }

  /// Assign an EnumSet from a static array.
  @nogc unittest {
    EnumSet!(Element, int) set;
    int[set.length] arr = [1, 2, 3, 4];
    set = arr;

    with (Element) {
      assert(set[air]   == 1);
      assert(set[earth] == 2);
      assert(set[water] == 3);
      assert(set[fire]  == 4);
    }
  }

  /// Assign an EnumSet from a range
  @nogc unittest {
    import std.range : iota;

    EnumSet!(Element, int) set;

    with (Element) {
      set = iota(0, 4);

      assert(set[air]   == 0);
      assert(set[earth] == 1);
      assert(set[water] == 2);
      assert(set[fire]  == 3);
    }
  }

  /**
   * Access the value at the index specified by an enum member.
   *
   * Indexing returns a reference, so it can be used as a getter or setter.
   */
  ref auto opIndex(K key) {
    return _store[key];
  }

  ///
  @nogc unittest {
    EnumSet!(Element, int) elements;
    elements[Element.fire] = 4;
    assert(elements[Element.fire] == 4);
  }

  /**
   * Access the value at the index specified by the name of an enum member.
   *
   * The value is returned by reference, so it can used for assignment.
   * `set.name` is just syntactic sugar for `set[SomeEnum.name]`.
   */
  ref auto opDispatch(string s)() {
    enum key = s.to!K;
    return this[key];
  }

  ///
  @nogc unittest {
    EnumSet!(Element, int) elements;
    elements.water = 5;
    assert(elements.water == 5);
  }

  /// Return a range of (EnumMember, value) pairs.
  alias opSlice = byKeyValue;

  /// foreach iterates over (EnumMember, value) pairs.
  @nogc unittest {
    EnumSet!(Element, int) elements;
    elements.water = 4;
    elements.air   = 3;

    foreach(key, value ; elements) {
      assert(
          key == Element.water && value == 4 ||
          key == Element.air   && value == 3 ||
          value == 0);

    }
  }

  /// Apply an array-wise operation between two `EnumSet`s.
  auto opBinary(string op)(typeof(this) other)
    if (is(typeof(mixin("V.init"~op~"V.init")) : V))
  {
    typeof(this) result;
    foreach(member ; EnumMembers!K) {
      result[member] = mixin("this[member]"~op~"other[member]");
    }

    return result;
  }

  ///
  unittest {
    auto inventory = enumset(
        ItemType.junk  , [ "Gemstone"        ],
        ItemType.normal, [ "Sword", "Shield" ],
        ItemType.key   , [ "Bronze Key"      ]);

    auto loot = enumset(
        ItemType.junk  , [ "Potato"       ],
        ItemType.normal, [ "Potion"       ],
        ItemType.key   , [ "Skeleton Key" ]);

    inventory ~= loot;

    assert(inventory.junk   == [ "Gemstone", "Potato"          ]);
    assert(inventory.normal == [ "Sword", "Shield" , "Potion"  ]);
    assert(inventory.key    == [ "Bronze Key" , "Skeleton Key" ]);
  }

  ///
  @nogc unittest {
    EnumSet!(Element, int) base;
    base.water = 4;
    base.air   = 3;

    EnumSet!(Element, int) bonus;
    bonus.water = 5;
    bonus.fire  = 2;

    auto sum = base + bonus;
    auto diff = base - bonus;
    auto prod = base * bonus;

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

  /// Perform an in-place operation.
  auto opOpAssign(string op)(typeof(this) other)
    if (is(typeof(this.opBinary!op(other)) : typeof(this)))
  {
    this = this.opBinary!op(other);
  }

  ///
  @nogc unittest {
    auto base  = enumset(Element.water, 4, Element.air , 3);
    auto bonus = enumset(Element.water, 5, Element.fire, 2);

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
  auto opUnary(string op)()
    if (is(typeof(mixin(op~"V.init")) : V))
  {
    V[length] result = mixin(op~"_store[]");
    return typeof(this)(result);
  }

  @nogc unittest {
    EnumSet!(Element, int) elements;
    elements.water = 4;

    assert((-elements).water == -4);
  }

  /// Get a range iterating over the members of the enum `K`.
  auto byKey() { return only(EnumMembers!K); }

  @nogc unittest {
    import std.range     : only;
    import std.algorithm : equal;

    EnumSet!(Element, int) e;
    with (Element) {
      assert(e.byKey.equal(only(air, earth, water, fire)));
    }
  }

  /// Get a range iterating over the stored values.
  auto byValue() { return _store[]; }

  @nogc unittest {
    import std.range     : iota;
    import std.algorithm : map, equal;

    EnumSet!(Element, int) e1 = iota(0, 4);
    EnumSet!(Element, int) e2 = e1.byValue.map!(x => x + 2);
    assert(e2.byValue.equal(iota(2, 6)));
  }

  /// Return a range of (EnumMember, value) pairs.
  auto byKeyValue() {
    return only(EnumMembers!K).map!(key => tuple(key, this[key]));
  }

  ///
  @nogc unittest {
    EnumSet!(Element, int) elements;
    elements.water = 4;
    elements.air = 3;

    foreach(key, value ; elements.byKeyValue) {
      assert(
          key == Element.water && value == 4 ||
          key == Element.air   && value == 3 ||
          value == 0);

    }
  }
}

  /**
   * Construct an `EnumSet` from a sequence of key/value pairs.
   *
   * Any values not specified default to `V.init`.
   */
auto enumset(T...)(T pairs) @nogc if (T.length >= 2 && T.length % 2 == 0) {
  alias K = T[0];
  alias V = T[1];

  EnumSet!(K, V) set;

  // pop a key/vaue pair, assign it to the enumset, and recurse until empty
  void helper(U...)(U params) {
    static assert(is(U[0] == K), "enumset: mismatched key type");
    static assert(is(U[1] == V), "enumset: mismatched value type");

    auto key = params[0];
    auto val = params[1];

    set[key] = val;

    static if (U.length > 2) {
      helper(params[2..$]);
    }
  }

  helper(pairs);
  return set;
}

///
@nogc unittest {
  with (Element) {
    auto set = enumset(air, 1, earth, 2, water, 3);

    assert(set[air]   == 1);
    assert(set[earth] == 2);
    assert(set[water] == 3);
    assert(set[fire]  == 0); // unspecified values default to V.init
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

  EnumSet!(Attribute, int) attributes;
  assert(attributes.wisdom == 0); // default value check

  attributes[Attribute.strength] = 10;

  attributes = generate!(() => uniform!"[]"(1, 20)).take(6);

  // make sure accessors compile:
  if (attributes[Attribute.wisdom] < 5) { }
  if (attributes.wisdom < 5) { }

  // key/value constructor
  auto bonus = enumset(Attribute.charisma, 2, Attribute.wisdom, 1);

  // opBinary
  attributes += bonus;

  // nogc test
  void donFancyHat(int[Attribute] aa) { aa[Attribute.charisma] += 1; }
  @nogc void donFancyHat2(EnumSet!(Attribute, int) set) { set.charisma += 1; }
}

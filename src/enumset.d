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
 * Just like the array assignment, it will fail if the length doesn't match.
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
 * hero.attributes = hero.attributes[].map!(x => x + 1);
 * ---
 *
 * See the full documentation of `EnumSet` for all the operations it supports.
 *
 */
module enumset;

import std.conv     : to;
import std.range;
import std.format   : format;
import std.traits   : EnumMembers;
import std.typecons : staticIota;

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
 * Params:
 * K = The type of enum used as a key.
 *     The enum values must start at 0, and increase by 1 for each entry.
 * V = The type of value stored for each enum member
 */
struct EnumSet(K, V)
  if(EnumMembers!K == staticIota!(0, EnumMembers!K.length))
{
  enum length = EnumMembers!K.length;

  /// Assuming Element consists of air, earth, water, and fire:
  unittest {
    static assert(EnumSet!(Element, int).length == 4);
  }

  private V[length] _store;

  /// Construct an EnumSet from a static array.
  this(V[length] values) {
    _store = values;
  }

  ///
  unittest {
    auto set = EnumSet!(Element, int)([1, 2, 3, 4]);

    assert(set[Element.air]   == 1);
    assert(set[Element.earth] == 2);
    assert(set[Element.water] == 3);
    assert(set[Element.fire]  == 4);
  }

  /**
   * Construct an EnumSet from an associative array.
   *
   * Any values not specified in `dict` default to `V.init`.
   */
  this(V[K] dict) {
    foreach(pair ; dict.byKeyValue) this[pair.key] = pair.value;
  }

  ///
  unittest {
    with (Element) {
      EnumSet!(Element, int) set = [ air: 1, earth: 2, water: 3 ];

      assert(set[air]   == 1);
      assert(set[earth] == 2);
      assert(set[water] == 3);
      assert(set[fire]  == 0); // unspecified values default to V.init
    }
  }

  /// Assign from a range with a number of elements exactly matching `length`.
  this(R)(R values) if (isInputRange!R && is(ElementType!R : V)) {
    assert(values.walkLength == length,
        "range contains %d elements, expected exactly %d"
        .format(values.walkLength, length));

    foreach (i, val ; values.enumerate) _store[i] = val;
  }

  unittest {
    import std.range : repeat;
    EnumSet!(Element, int) elements = 9.repeat(4);
    assert(elements.air   == 9);
    assert(elements.earth == 9);
    assert(elements.water == 9);
    assert(elements.fire  == 9);
  }

  /// An EnumSet can be assigned from any type if can be constructed from.
  void opAssign(T)(T val) if (is(typeof(typeof(this)(val)))) {
    this = typeof(this)(val);
  }

  /// Assign an EnumSet from a static array.
  unittest {
    EnumSet!(Element, int) set;
    set = [1, 2, 3, 4];

    with (Element) {
      assert(set[air]   == 1);
      assert(set[earth] == 2);
      assert(set[water] == 3);
      assert(set[fire]  == 4);
    }
  }

  /// Assign an EnumSet from an associative array.
  unittest {
    EnumSet!(Element, int) set;

    with (Element) {
      set = [ air: 1, earth: 2, water: 3, fire: 4 ];

      assert(set[air]   == 1);
      assert(set[earth] == 2);
      assert(set[water] == 3);
      assert(set[fire]  == 4);
    }
  }

  /// Assign an EnumSet from a range
  unittest {
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
  unittest {
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
  unittest {
    EnumSet!(Element, int) elements;
    elements.water = 5;
    assert(elements.water == 5);
  }

  /// Return a range of (EnumMember, value) pairs.
  alias opSlice = byKeyValue;

  /// foreach iterates over (EnumMember, value) pairs.
  unittest {
    import std.format;

    EnumSet!(Element, int) elements = [Element.water : 4, Element.air : 3];
    string[] result;

    foreach(element, value ; elements) {
      result ~= "%s : %s".format(element, value);
    }

    assert(result == ["air : 3", "earth : 0", "water : 4", "fire : 0"]);
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
    EnumSet!(ItemType, string[]) inventory = [
      ItemType.junk   : [ "Gemstone"        ],
      ItemType.normal : [ "Sword", "Shield" ],
      ItemType.key    : [ "Bronze Key"      ]
    ];

    EnumSet!(ItemType, string[]) loot = [
      ItemType.junk   : [ "Potato"       ],
      ItemType.normal : [ "Potion"       ],
      ItemType.key    : [ "Skeleton Key" ]
    ];

    inventory ~= loot;

    assert(inventory.junk   == [ "Gemstone", "Potato"          ]);
    assert(inventory.normal == [ "Sword", "Shield" , "Potion"  ]);
    assert(inventory.key    == [ "Bronze Key" , "Skeleton Key" ]);
  }

  ///
  unittest {
    EnumSet!(Element, int) base  = [Element.water : 4, Element.air : 3];
    EnumSet!(Element, int) bonus = [Element.water : 5, Element.fire : 2];

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
  unittest {
    EnumSet!(Element, int) base  = [Element.water : 4, Element.air : 3];
    EnumSet!(Element, int) bonus = [Element.water : 5, Element.fire : 2];

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

  unittest {
    EnumSet!(Element, int) elements  = [Element.water : 4, Element.air : 3];

    assert(-elements.water == -4);
    assert(-elements.air   == -3);
  }

  /// Get a range iterating over the members of the enum `K`.
  auto byKey() { return only(EnumMembers!K); }

  unittest {
    import std.algorithm : equal;

    EnumSet!(Element, int) e;
    with (Element) {
      assert(e.byKey.equal([ air, earth, water, fire ]));
    }
  }

  /// Get a range iterating over the stored values.
  auto byValue() { return _store[]; }

  unittest {
    import std.algorithm : map;

    EnumSet!(Element, int) e1 = [1, 2, 3, 4];
    EnumSet!(Element, int) e2 = e1.byValue.map!(x => x + 2);
    assert(e2.byValue == [3, 4, 5, 6]);
  }

  /// Return a range of (EnumMember, value) pairs.
  auto byKeyValue() {
    return zip(only(EnumMembers!K), _store[]);
  }

  ///
  unittest {
    import std.format;

    EnumSet!(Element, int) elements = [Element.water : 4, Element.air : 3];
    string[] result;

    foreach(name, value ; elements.byKeyValue) {
      result ~= "%s : %s".format(name, value);
    }

    assert(result == ["air : 3", "earth : 0", "water : 4", "fire : 0"]);
  }
}

version (unittest) {
  private enum Element { air, earth, water, fire };
  private enum ItemType { junk, normal, key };
  private EnumSet!(Element, int) triggerTest;
}

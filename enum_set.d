module enum_set;

import std.conv   : to;
import std.range  : enumerate, walkLength, isInputRange, ElementType;
import std.format : format;
import std.traits : EnumMembers;

struct EnumSet(K, V) {
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

  /// Get a slice of all the values.
  auto opSlice() { return _store[]; }

  /// Slice an `EnumSet` to work with it as a range
  unittest {
    import std.algorithm : map;

    EnumSet!(Element, int) e1 = [1, 2, 3, 4];
    EnumSet!(Element, int) e2 = e1[].map!(x => x + 2);
    assert(e2[] == [3, 4, 5, 6]);
  }

  /// Apply an array-wise operation between two `EnumSet`s.
  auto opBinary(string op)(typeof(this) other)
    if (is(typeof(mixin("V.init"~op~"V.init")) : V))
  {
    V[length] result = mixin("_store[]"~op~"other._store[]");
    return typeof(this)(result);
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
}

version (unittest) {
  private enum Element { air, earth, water, fire };
  private EnumSet!(Element, int) triggerTest;
}

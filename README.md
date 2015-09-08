EnumSet: D language implementation of an enum set data structure.
===

An `EnumSet` provides a lightweight mapping between each member of an enum and a
value.

An `EnumSet` is just a wrapper around a static array that uses enum members as
indices.

With no further ado, lets jump in to an example:

```
enum Attribute {
 strength, dexterity, constitution, wisdom, intellect, charisma
};

struct Character {
 EnumSet!(Attribute, int) attributes;
}
```

Lets roll some stats!

```
Character hero;
hero.attributes = sequence!((a,n) => uniform!"[]"(0, 20))().take(6);
```

Note that we can assign directly from a range!
Just like the array assignment, it will fail if the length doesn't match.

We can access those values using either `opIndex` or `opDispatch`:

```
if (hero.attributes[Attribute.wisdom] < 5) hero.drink(unidentifiedPotion);
// equivalent
if (hero.attributes.wisdom < 5) hero.drink(unidentifiedPotion);
```

If a binary operation is possible between the value types, it can be performed
across all members in the set (similar to an array-wise operation).

```
// note the convenient assignment from an associative array:
EnumSet!(Attribute, int) bonus = {Attribute.charisma: 2, Attribute.wisom: 1};

// level up! adds 2 to charisma and 1 to wisdom.
hero.attributes += bonus;
```

Finally, note that we can break the `EnumSet` down into a range when needed:

```
hero.attributes = hero.attributes.byValue.map!(x => x + 1);
```

There's a few other things not covered here,
check the [docs](http://rcorre.github.io/dtiled/index.html) for more details.

EnumSet (D)
===

An `EnumSet` is a wrapper around a static array that uses enum members as indices.
It is essentially a lightweight associative array specialized for using an enum
as the key type.

Example time!

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
Just like static array assignment, it will fail if the length doesn't match.

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

Check the [docs](http://rcorre.github.io/dtiled/index.html) for the full feature
set.

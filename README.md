EnumSet
===

An `EnumSet` is a glorified wrapper around a static array.
Are you sold yet? No? Alright, take a look at this:

```
enum Attribute {
 strength, dexterity, constitution, wisdom, intellect, charisma
}
```

Now you want to map each `Attribute` to an `int`.
You could use D's built-in associative arrays:

```
int[Attribute] attributes;
attributes[Attribute.strength] = 10;
```

However, I think you'll like `EnumSet` better:

```
EnumSet!(Attribute, int) attributes;
attributes[Attribute.strength] = 10;
```

Still not impressed? Well, you might prefer an `EnumSet` if:

You like syntactic sugar:

```
// Boring!
if (hero.attributes[Attribute.wisdom] < 5) hero.drink(unidentifiedPotion);

// Fun! And Concise!
if (hero.attributes.wisdom < 5) hero.drink(unidentifiedPotion);
```

You like ranges:

```
// roll for stats!
attributes = generate!(() => uniform!"[]"(1, 20)).take(6);
```

You like default values:

```
int[Attribute] aa;
EnumSet!(Attribute, int) set;

aa[Attribute.strength]; // Range violation!
set.strength;           // 0
```

You like array-wise operations:

```
// note the convenient constructor function:
auto bonus = enumset(Attribute.charisma, 2, Attribute.wisdom, 1);

// level up! adds 2 to charisma and 1 to wisdom.
hero.attributes += bonus;
```

You dislike garbage day:

```
      void donFancyHat(int[Attribute] aa) { aa[Attribute.charisma] += 1; }
@nogc void donFancyHat(EnumSet!(Attribute, int) set) { set.charisma += 1; }
```

Check the [docs](http://rcorre.github.io/enumset) for the full feature set.

`EnumSet` comes in [dub package form](http://code.dlang.org/packages/enumset).

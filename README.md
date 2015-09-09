EnumSet
===

An `EnumSet` is a static array that behaves like an associative array
specialized for using a named enum as a key type:

```
enum Attribute {
 strength, dexterity, constitution, wisdom, intellect, charisma
};

EnumSet!(Attribute, int) attributes;

attributes[Attribute.Strength] = 10;
```

So, why would you use an `EnumSet` instead of an associative array?

`EnumSet` might be right for you if:

You like ranges:

```
// roll for stats!
attributes = generate!(() => uniform!"[]"(1, 20)).take(6);
```

You like syntactic sugar:

```
// Boring!
if (hero.attributes[Attribute.wisdom] < 5) hero.drink(unidentifiedPotion);

// Fun! And Concise!
if (hero.attributes.wisdom < 5) hero.drink(unidentifiedPotion);
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
// note the convenient assignment from an associative array:
EnumSet!(Attribute, int) bonus = {Attribute.charisma: 2, Attribute.wisom: 1};

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

```json
"dependencies": {
  "enumset": "~>0.1.0"
}
```

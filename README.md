# Mos *(Work In Progress)*

An emulator for the **Mos 6502 Processor** for use in Garry's Mod

## What is it?

The [Mos 6502](https://en.wikipedia.org/wiki/MOS_Technology_6502) processor is an 8-bit microprocessor introduced in the 70s.
Commonly known for its use in old computers such as the Apple I or the Commodore PET, it was the least expensive processor of its time.

This is an emulated verison of the 6502 that you can program and run, all from within Garry's Mod.

# Writing Conventions

## Globals

To keep the global space clean, avoid creating global variables and instead store them in a [namespace](#namespaces).

## Namespaces

Namespaces are defined as tables and stored in the global `Mos` table.  
This allows namespaces to be accessed anywhere.

Namespaces are used to group API functions.

### Localizing namespace data

Be careful when localizing dat stored in namespaces as if the data is changed from somewhere else, it may not be updated locally. This is the case for all data that isn't a table.

## Objects and static data

To differenciate objects (instanciable data) from static data, the casing of function names changes.  
Namespaces, libraries and classes use `UpperCamelCase` as well as static functions declared in these scopes.  
Instance data and functions use `lowerCamelCase`.

**Exception:**  
Custom VGUI panel methods use `UpperCamelCase` to respect the standard that Garry's Mod panels use.

### About classes

An object should be a class (instanciatable) *only* if multiple of that object are needed at once.

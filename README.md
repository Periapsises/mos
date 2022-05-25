# Mos6502

An emulator for the **Mos 6502 Processor** for use in Garry's Mod

---
## Code guidelines

Here are some guidelines to keep the code clean.  
These are some '*rules*' to help make the code more readable and more importantly, standardized.

### Comments

Comments are a really important part of the code.  
They help developers understand what was done in the past or by someone else and makes it easier to edit the code.

There are different ways of writing comments depending on the purpose they serve.
- [Basic documentation](#basic-documentation)
- [Documenting api for the Wiki](#api-documentation)
- [Documenting for the Usage](#usage-documentation)

### Basic Documentation

Basic documentation is there to help understand parts of the code.  
They are mostly used to document local sections of code such as local functions or describing local variables.  
They can also list problems faced that led to decisions that might not be obvious.

```lua
-- Does this and that. Changes this, depends on that
-- Takes some arguments that does stuff
local function someFunction( someArg )
```

They are also used to *tag* the code.  
A good example of this is TODO, where code needs to be edited, fixed or expanded on in the future.

```lua
-- TODO: Fix that and add this
```

### Api Documentation

The Api documentation comments have a specific format so that (*in the future*) the documentation can be generated automatically from the code.  

```lua
--[[
    @class SomeLib
    @desc Class that provides this and that to do something
]]
local SomeLib = {}

--[[
    @name SomeLib:SomeFunction()
    @desc Some description about that function

    @param type someArg: What this arguemnt does
    @return type: What this function returns
]]
function SomeLib:SomeFunction( someArg )
```

### Usage Documentation

Like the Api docs comments, the usage documentation is generated (*will be*) from the code.  
Because of that, the format of the comments is important.

You can document instructions:

```lua
--- instruction: name
-- mode, mode, ...
-- A description about this instruction
```

And directives:

```lua
--- directive: name
-- arg, arg, ...
-- A description about this directive
```
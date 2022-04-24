# Mos6502

An emulator for the **Mos 6502 Processor** for use in Garry's Mod

## AST Structure Reference

```lua
{
    type = "Program",
    line = 1,
    char = 1,
    value = {
        [1] = {
            type = "Directive",
            line = NUMBER,
            char = NUMBER,
            value = {
                directive = {
                    type = "Identifier",
                    line = NUMBER,
                    char = NUMBER,
                    value = STRING
                },
                arguments = {
                    [1] = {
                        type = "Operation",
                        line = NUMBER,
                        char = NUMBER,
                        value = {
                            operator = {
                                type = "Operator",
                                line = NUMBER,
                                char = NUMBER,
                                value = STRING
                            }
                            left = {
                                type = "Identifier / Number / String",
                                line = NUMBER,
                                char = NUMBER,
                                value = STRING
                            },
                            right = {
                                type = "Identifier / Number / String",
                                line = NUMBER,
                                char = NUMBER,
                                value = STRING
                            }
                        }
                    }
                },
                value = nil -- Can be a list of statements like the program's value
            }
        },
        [2] = {
            type = "Instruction",
            line = NUMBER,
            char = NUMBER,
            value = {
                instruction = {
                    type = "Identifier",
                    line = NUMBER,
                    char = NUMBER,
                    value = STRING
                },
                operand = {
                    type = "AddressingMode",
                    line = NUMBER,
                    char = NUMBER,
                    value = {
                        type = STRING, -- Addressing mode
                        value = {
                            type = "Identifier / Number / String",
                            line = NUMBER,
                            char = NUMBER,
                            value = STRING
                        }
                    }
                }
            }
        }
    }
}
```

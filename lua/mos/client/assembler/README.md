# The Assembly Process

Nowadays, most languages (that are not interpreted) are **compiled**.
This is the case for assembly, but it is usually refered to as 'Assembling' which is why the program used to process assembly code is called an **Assembler**.

These are the terms I'll be using mostly, but they are quite interchangable.

## Assembling code

Only one thing is needed to assemble code:
<u>The path to an existing file</u>.

From there, the assembler can read the contents of the file and start the whole process.  
Other files may be included, but the path to those can be found within the code itself.  
Therefore, with only one path you can get the compiled code from your project.

## Preparing the asembly

Once the assembler has the contents of the initial *main* file, it can setup everything that will be needed to complete the assembly.

### Tokens, so many tokens

The very first thing to do is generate tokens.  
Verry little can be done with raw text data, which is why the lexer is responsible of turning that data into a different form.  
Not only are they useful for compilation, but tokens can also serve for syntax highlighting.  

This is where we find the first errors, even if those are simple ones such as malformed numbers or unfinished strings.

The lexer does not care about syntax.  
It is just a very simple way of describing parts of the code and discarding what the assembler doesn't need such as whitespaces.

These are the important tokens generated:

| Token type  | Example     | Description                                                                  |
| ----------- | ----------- | ---------------------------------------------------------------------------- |
| Directive   | `.org`      | Used mostly by preprocessor to specify special instructions at compile time. |
| Label       | `start:`    | Used as variable, they will be used to indicate locations in the code.       |
| Instruction | `lda`       | Actual assembly instructions, the barebone of the language.                  |
| Number      | `0x7f`      | Plain old numbers. Can be decimal, hexadecimal or binary representations.    |
| String      | `"Hello"`   | Represents text, within quotes or single-quotes.                             |
| Operator    | `+` `*` `-` | To easily perform arithmetic operations at compile time.                     |
| Control     | `(` `)` `,` | Control characters, mostly used for different addressing modes.              |

The lexer then outputs a stream of tokens, that is, a list of all tokens generated in the order in which they appear in the code.  
For instance:
```c
.org 0x0100

start:
    lda 255
```
Would result in:
```lua
{
    Token( "directive", ".org" ),
    Token( "label", "start:" ),
    Token( "instruction", "lda" ),
    Token( "number", "255" )
}
```

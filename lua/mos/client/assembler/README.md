# Mos 6502 Assembly
## The process of turning text into bytes

The **assembler** is the heart of the assembly language in my opinion.  
It is what takes the code you write and converts it into something that the processor will understand.

There are a lot of steps involved for a good assembler, as it usually has a lot of features that give a lot of freedom but also a lot of help to the developer.

Here, the whole process of assembling your program is described, from starting with a single source file, all the way through getting your final program.

**Table of contents:**
- [The source file](#the-source-file)
    - [The lexer](#the-lexer)
    - [The parser](#the-parser)
    - [The preprocessor](#the-preprocessor)
- [Including other files](#including-other-files)
    - [The only difference](#the-only-difference)
- [Generating bytes from the AST](#generating-bytes-from-the-ast)
    - [Labels everywhere](#labels-everywhere)
    - [Passes](#passes)
        - [The first pass](#the-first-pass)
        - [The second pass](#the-second-pass)

**Note:** For other languages the name *Compiler* is used.  

## The source file

To begin, the assembler requires a single source file form which (if present) other files will be included.  
The first issue the assembler meets is that it has no idea what any of the text in your file means, or even if it is valid assembly.  
This is what the **Parser** and **Lexer** are for.

### The lexer

The lexer,s job is to take the raw text from your file and turn it into a sequence of what is known as tokens.  
During this process, a lot of the code is cleaned up as every character not needed like newlines, spaces and comments are discarded.  
After that, instead of a stream of characters you end up with a stream of tokens that can give information on a part of the text.  

### The parser

The parser works with the output of the lexer.  
It takes the stream of tokens and tries to build an *Abstract Syntax Tree* (AST).  
The tree is what gives structure to the program and during its generation we can also see wether or not the code is valid or not.  
This is where syntax errors will be detected in majority.

### The preprocessor

The preprocessor is where text starts to be replaced with something else such as bytes or different code.  
This is how included files are added to the main code.  
With the AST now built, the preprocesor can find and understand instructions meant to happen before the final assembly, hence the name **pre**processor.  
From there, the next major step in assembling is reached.

## Including other files

Including other files is pretty straight forward as it consists of repeating the same steps from the first source file recursively if that file also has includes.

### The only difference

Once we have a new AST from the included file, it is inserted into the main AST in place of the include directive.  
This means we now have more code available for the next step.

## Generating bytes from the AST

When the preprocessor has completed its task, all that should be left in the AST are instructions that tell the assembler exactly how to generate a binary file from the code.  
There is still one problem the assembler faces at this point.

### Labels everywhere

Labels are a very important part of assembly and they can happen nearly everywhere in the code.  
An issue arises when the assembler needs to compile the address of a label that hasn't been declared yet.  
For this reason, the assembler performs two passes.

### Passes

The passes consist of two essential steps:
- gathering info about the code
- Using that info along with the code to generate a file

#### The first pass

The first pass is used to obtain info on how long in binary instructions take so the address of labels can be determined.  
That info is stored for the second pass.

#### The second pass

Now that the assembler has all the info it needs, it can finally generate the output file.

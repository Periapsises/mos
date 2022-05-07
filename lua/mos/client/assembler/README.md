# The Assembler

The assembler is what takes raw source code and processes it in order to generate a binary file which the processor can execute.  
It creates all the necessary elements to go through all the required steps of compiling the code.

## The Process

When creating a new assembler, these are the steps that happen.

- Get the currently open file from the editor
- Create an assembly to hold the important data about the current program
- Start the preprocessor and make it process the given code
- Start the compiler using the AST given in the previous step
    - Perform the first pass to get information about addresses
    - Perform the second and final pass to generate the binary code
- Write the binary code to the output file

### Getting the main file

The first step is to get the main file, that is, the file currently open in the editor.  
This file is called `main` as it is where the entire assembly process is gonna start from.

The output file's name will be based on the main file, its extension being changed to `.bin`

### Generating an assembly

The assembly holds important information during the process of compilation.  
Initially it holds:

| Key            | Description                                      |
| -------------- | ------------------------------------------------ |
| `main`         | The path to the main file                        |
| `files`        | An empty list to wich to add included file paths |
| `preprocessor` | The preprocessor object to be used               |
| `compiler`     | The compiler object to be used                   |

Before starting, the compiler and preprocessor will be assigned this assembly so they can fetch the data they need.

### Start the preprocessor

With all that info, the preprocessor can start.  
It will generate an ast with the main file and fetch all included files it will find.  
Once done, the generated ast is stored on the assembly for the compiler.

### Start the compiler

With the ast complete, the compiler can start converting the code into binary.

#### First pass:

The first pass calculates the position of all defined labels for use in the next step

#### Second pass:

The second pass then goes through all the code, converting it into binary form and writing it to the output file given by the compiler.

### Write the output file

The output file is then saved and closed and can be read from.

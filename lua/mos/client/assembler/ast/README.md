# The Abstract Syntax Tree

Given its complexity, the generation of an [Abstract Syntax Tree](https://en.wikipedia.org/wiki/Abstract_syntax_tree) (AST) can quickly become as much of a mess as tangled earphones in your pocket.  
This section is here to hopefully prevent that by documenting and setting some standards for the AST used in this addon.

## Nodes and Tokens

From the Lexer, a Parser gets a stream of Tokens.  
It then arranges them into a tree that represents the structure given by the input, in out case, the assembly language.

Nodes and tokens both hold a value. But there is one major difference.  
A token always holds a string which is the part of text matched by the Lexer.  
On the other hand, a node will contain more information as its value. In this case it will either hold another node, a [list](#lists) or [table](#tables) of them, or a [leaf](#leaves).

## The different types of nodes

Those are all based on the basic `Node`.  
They represent information in a similar manner, but each serve a different purpose in presenting it.  

Here are the different types of nodes that can exist in our AST.

- [Node](#nodes)
- [List](#lists)
- [Table](#tables)
- [Leaf](#leaves)

---

### Nodes

The `Node` is the base for all other types.  
It simply contains a type, a *single* value and the line and character which it represents in the input.

Its value will aways be one of the four existing types of nodes which means it can always be visited.

There are multiple ways of creating a node.  
This is the most basic. It creates and returns a new node that is not attached to anything.
```lua
local myNode = Mos.Assembler.Ast.Node.Create( "type" )
```

This method uses an already existing node and once created, the new node becomes the value of the previous one.
```lua
local myNode = aNode:node( "type" )

print( aNode._value ) -- typeNode( nil )
```

Internally, this calls `Node:attach()` on the existing node.  
This method can be used manually after creating an orphan node too:
```lua
local myNode = Mos.Assembler.Ast.Node.Create( "type" )
aNode:attach( myNode )
```

---

### Lists

`Lists` are very similar to `Nodes`, the only difference being they hold multiple values at once in an ordered list.  
The line and character of the list are set from the first child node appended to it.

When visited, a builtin visitor will handle looping over the list, calling the visitor for each value in order.  
This default behavior can be overwriten by creating a `visitList` visitor method, or by changing the `_type` of the list.

Like the `Node`, there are two ways of creating a list.
```lua
local myList = Mos.Assembler.Ast.List.Create()
aNode:attach( myList )
```
```lua
local myList = aNode:list()
```

But unlike the node, a list cannot be attached to with `:attach()`.  
Rather is uses an `:append()` method to append children nodes to the list.

```lua
local myList = aNode:list()

myList:append( child1 )
myList:append( child2 )
```

Calling the functions to create nodes from a list will automatically append them.

---

### Tables

`Tables` can store multiple values like `Lists` but differ a lot from other nodes when visited.  
Instead of storing noded in an ordered list, they are stored with a key (Hence the name Table).  
When visited, all key-value pairs will be taken and a visitor will be fetched using the key.

For instance, a key named `Statements` will fetch a visitor called `:visitStatements()` and pass the value to it.

Tables are created like other nodes.
```lua
local myTable = Mos.Assembler.Ast.Table.Create()
aNode:attach( myTable )
```
```lua
local myTable = aNode:table()
```

The `:attach()` and `:append()` methods cannot be used on tables.  
Instead you can just assign values to keys like you would with a normal lua table.

```lua
local myTable = aNode:table()

myTable.key1 = value1
myTable.key2 = value2
```

---

### Leaves

`Leaves` are a special type of node.  
They are the same as basic `Nodes` except that their value isn't visitable, it isn't a node.  
This is the reason they are called leaves, they are the extremities of the tree.  
They are just replacements for tokens but with the extra info the AST needs to visit everything properly.

Just like all other nodes, you can create a leaf from the main table, or from another node.
```lua
local myLeaf = Mos.Assembler.Ast.Leaf.Create( token )
aNode:attach( myLeaf )
```
```lua
local myLeaf = aNode:leaf( token )
```

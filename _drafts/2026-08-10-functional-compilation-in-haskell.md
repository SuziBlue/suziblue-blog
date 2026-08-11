---
title: Functional Compilation in Haskell
layout: post
---
# Functional Language Compilation in Haskell
- I built a compiler in Haskell.
- Outputs a custom assembly-like IR.
- Compiles a custom embedded expression based language.
- Pure functional language.
- No runtime or garbage collection.
- Strictly point free style.
- Linearly typed.
- Algebraic sum and product types.

## AST
- The AST is created through a Haskell GADT of type `Cat a b` where `a` is the input type of the expression and `b` is the output type.
- Each node represents a function from `a` to `b`.
- GADT constructors define the language syntax.
- Expressions are created by composing constructors.

- Constructors include:
    - Identity
    - Element constructors
    - Primitive functions
    - Primitive conditionals
    - Conditional loops
    - Push/Pop onto stack
    - Sum of functions
    - Product of functions
    - Function composition
    - Function currying

- Types include:
    - Primitives
    - Unit
    - Sum Type
    - Product Type
    - Exponent Type
    - Recursive Type

### Elements
- Point free style means no variable assignments like `x = 5` or function parameters like `f(x) = ...`.
- Constants are created from the literal constructor `Lit: Int -> Cat Unit IntTy` which means a function from the unit type to the primitive int type.
- Variable parameters that are given at runtime are created from the variable constructor `Var: Str -> Cat Unit IntTy` which creates a named variable which can be specified when running the program.
- Function parameters are not needed since programs can only be written by composing functions, never by calling functions.

### Composition
- Function composition is accomplished using the constructor `Comp: Cat b c -> Cat a b -> Cat a c`.
- It takes two functions and applies the first function to the result of the second function.

### Product and Sum Types
- Product and sum types represents compinations of other types.
- A product of two types `a` and `b` is a type `ProdTy a b`.
- An element of `ProdTy a b` is and element of `a` AND an element of `b` together.
- A sum of two types `a` and `b` is a type `SumTy a b`.
- An element of `SumTy a b` is and element of `a` OR and element of `b`.
- The product constructor `Prod: Cat a b -> Cat c d -> Cat (ProdTy a c) (ProdTy b d)` takes two functions `Cat a b` and `Cat c d` and returns the product function of the two `Cat (ProdTy a c) (ProdTy b d)` which means evaluate two functions on independent data.
The product type comes with two constructors `Fst: Cat (ProdTy a b) a` and `Snd: Cat (ProdTy a b) b` which select the first or second element of the product respectively.
- The sum constructor `Sum: Cat a b -> Cat c d -> Cat (SumTy a c) (SumTy b d)` does the same for sum types and means execute the left function if the input is type `a` or execute the right function if the input is type `b`.
The sum type comes with two constructors `Inl: Cat a (SumTy a b)` and `InR: Cat b (SumTy a b)` which takes a known value and creates a left or right sum element respectively.

### Basic Functions
- Let's look at a basic function `Add: Cat (ProdTy IntTy IntTy) IntTy` meaning `Add` is a function that takes two integers and returns one integer.
- Other basic binary functions include `Sub`, `Mul`, `Div`.
- `Neg` takes only one value and negates it so it has the type `Cat IntTy IntTy`

### A Simple Program
- Let's create a simple program from the components we have already discussed.
- This program will add two constant integers together.
- First we need to construct the constant elements we want to add using the `Lit` constructor.
- Since we need two elements, we will use the `Prod` constructor.
- The expression `elements = Prod (Lit 5) (Lit 6)` has the type `Cat (ProdTy Unit Unit) (ProdTy IntTy IntTy)` which is a function that produces two integers from the unit singleton.
- Since the output type of `elements` is `ProdTy IntTy IntTy` we can compose it with our `Add` function.
- Our program is then `program = Comp Add elements` or if we write out the whole AST: `Comp Add (Prod (Lit 5) (Lit 6))` which has type `Cat (ProdTy Unit Unit) IntTy`.
- Using compinations of `Lit`, `Prod`, and primitive operations we can construct any algebraic expression on integers.

### Control Flow Using Conditionals
- Conditionals allow programs to execute different branches based on a comparison operation.
- Branching paths are constructed using the `Sum`.
- To create a `SumTy` we need to use a primitive `Cmp` operation.
- `Cmp: Cond -> Cat (ProdTy IntTy IntTy) (SumTy Unit Unit)` takes a condition argument (less than, greater than, etc.) and creates a function that takes two integers and returns the `SumTy` of two `Unit`.
- `SumTy Unit Unit` is isomorphic to a boolean since it has only two possible states.
- Let's create a simple program that returns the sign of an integer.
- The boolean can be calculated by comparing the input with zero, `bool = Comp (Cmp Lt) (Prod (Var "x") (Lit 0))`.
- Then we convert the "boolean" back into an integer, `sign = Comp (Sum (Lit -1) (Lit 1)) bool`.
- The `Sum` constructor creates a function that converts the left `Unit` into -1 and the right `Unit` into 1. It has the type `Cat (SumTy Unit Unit) (SumTy IntTy IntTy)`. But we want our function to have the plain old `IntTy` as output. 
- We need another constructor called `Match: Cat a c -> Cat b c -> Cat (SumTy a b) c` which can identify which conditional branch the program is in and transform each possible type, `a` or `b`, into a unifying type `c`.
- Since we don't need to transform the contents at all we can use the function `match = Match Id Id` to simply forget the conditional tag.
- The final program is `program: Cat (ProdTy IntTy Unit) IntTy = Comp match sign`.
- The extra `Unit` in the input type is due to the `Lit 0` constructor.

### Infix Notation
- Writing nested constructors quickly becomes verbose and difficult to comprehend.
- To simplify the syntax we can use infix operators to replace the `Prod`, `Sum`, and `Comp` operators.
- Introducing `.` where `f . g === Comp f g` and `>>>` where `f >>> g === Comp g f`.
- For `Prod` we have `f *** g === Prod f g`.
- For `Sum` we have `f +++ g === Sum f g`.

### Copying and Untagging
- For any value of type `a` we can copy it and create a value of type `ProdTy a a` using `Copy: Cat a (ProdTy a a)`
- We will define an infix operator for applying two functions to the same input by copying `f &&& g === (f *** g) . Copy` where `f: Cat a b` and `g: Cat a c`
- For any value of type `Sum a a` we can forget which branch the value is in by forgetting the tag using `Untag: Cat (SumTy a a) a`.
- We can unify two branches with the infix operator `f ||| g === Untag . (f +++ g)` where `f: Cat a c` and `g: Cat b c`.

### Distributive Property of Types
- The `SumTy` and `ProdTy` are distributive in the same way as sums and products in algebra.
- We can transform `ProdTy a (SumTy b c)` into `SumTy (ProdTy a b) (ProdTy a c)`.

### Conditional Loops and Tail Recursion
- Generic recursion is not allowed.
- Tail recursion is implemented by a special constructor called `Trace: Cat a (SumTy a b) -> Cat a b` which takes a function from input `a` to either `a` or `b` and executes the function recursively on the left value until it returns the right value creating a function from `a` to `b`.
- To create a function that loops n times we start with a function to subtract 1: `minus_one: Cat a IntTy = Prod (Var "x") (Lit 1) >>> Sub`.
- Create a counter function that counts down from n to 0: `counter: Cat a (SumTy IntTy IntTy) = minus_one >>> Copy >>> (Id *** lessThanZero) >>> Distrib`
- We need to loop over a function that takes the product of a state value and a counter integer while applying a function to mutate the state, `body: Cat s s -> Cat (Prod s IntTy) (SumTy (Prod s IntTy) (Prod s IntTy)) = \f -> (f *** counter) >>> Distrib`
- Now we can apply the `Trace` constructor and select the first element of the output product which is the final state: `for_loop: Cat s s -> Cat (Prod s IntTy) s = \f -> Trace (body f) >>> Fst`.
 
### Haskell Arrows vs. Language Functions
 - Haskell lambda expressions can be used to create language macros as we saw in the for loop example.
 - Valid programs must be of the type `Cat a b`.
 - All Haskell expressions must be evaluated at compile time.
 - The difference between a macro such as `macro = \n -> Lit n` and a language function `func = Var "x"` is that `macro` must be evaluated at compile time to produce a static `Lit n`, `macro 0: Cat Unit IntTy` while `func: Cat Unit IntTy` is a runtime variable.

## Compilation
- Programs are compiled to an assembly-like intermediate language.
- The IR is imperative, an IR program is just a list of IR operations.
- The IR targets an infinite register virtual machine.
- Operations include:
    - Arithmetic, bitwise operations.
    - Comparison operation.
    - Push/Pop from a stack.
    - Jumps/Conditional jumps.
    - Load/Store from memory addresses.
- Functional expressions are compiled using a state monad and recursive folding over the AST.

### Variables and Registers
- The compiler tracks registers and variables.
- Registers are physical resources of the virtual machine.
- Registers are ordered.
- Variables are virtual references to values that exist in a register. Every variable is single-use. When a variable is read by the compiler it returns the register of the variable's value and the variable is freed.
- Variables are linked to registers using a map and each register's reference count is tracked.
- If a variable is freed and the register has no other references to it, the register may be reused to store a new value.
- Since variables are single use, it is easy to determine their lifetimes.
- New variables can be created or copied freely. Copying a variable increments the reference count of the register it is mapped to.
- Once the last copy of a variable is freed, the underlying register is returned to the pool of available registers. The lowest register is always prefered when creating a new variable.
- Since variables are destroyed on use, mutating a value naturally reuses the current register if the register has only one reference, and lazily copies the register if there is more than one reference.
- Variables can be read non-destructively, but only if its value is not changed.


### Layouts
- Each type in the language has a corresponding layout, `Layout t`, and a layout constructor.
- To compile a function `Cat a b`, the compiler takes an input `Layout a` and produces a new `Layout b` alongside the IR program.
- The layout of type `Layout t` contains the variables that make up a value of type `t`.
- The layout of `Unit` is an empty layout
- The layout of `IntTy` is just a single variable.
- The layout of `ProdTy a b` is the layout of `a` and the layout of `b`.
- The layout of `SumTy a b` is the layout of `a` and the layout of `b` and a tag variable.

### Primitive Binary Operations
- `Add`, `Sub`, `Mul`, `Div` functions map directly onto a corresponding primitive operation in the IR.
- Every binary operator is compiled the same with just a different primitive operation.
- The compiler reads the variables from the input layout `LProd x y`.
- A new variable `z` is created to store the result.
- Since the input variables are freed, one of the input registers are mutated in place if there are no references to it.
- The binary operator instruction and any move instructions are generated.
- The output layout `LScalar z` is created.
- The instructions and layout are returned.

### Function Products
- `Prod f g` is compiled recursively, first `f` and then `g`, then the resulting instructions are concatenated.
- Each function takes one layout from the input product layout and produces a new layout. Once both are compiled, a new product layout is created from the outputs of the two functions.
- The input layout is `LProd inF inG` and the output layout is another `LProd outF outG`

### Function Sums
- `Sum f g` is also compiled recursively.
- For each function, a label is created.
- A compare instruction and a conditional jump is created to check the tag variable and jump to the correct label.
- Since the tag variable cannot be changed by `f` or `g`, the tag variable can be reused to create the output layout `LSum outF outG`.

### Initiating the Compiler
- The compiler needs an initial input layout to start compilation.
- The only type with a known layout is `Unit`, which hold no values.
- Only programs with type `Cat Unit b` can be compiled.
- To guarantee all resources are freed before the program ends, we will enforce that the output type is also `Unit`.
- Therefore a valid program must have type `Cat Unit Unit`.

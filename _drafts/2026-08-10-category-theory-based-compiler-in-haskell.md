---
id: Category Theory Based Compiler in Haskell
aliases: []
tags: []
---
- Should the [[Category]] be implemented on the type level or on the value level?
	- Type level implementation gives access to Haskell's type checking when writing the language as an embedded language, but requires using introspection to get type level information into the compilation runtime.
	- Value level implementation requires reimplementing type checking, but removes complex type introspection.
- How do I convert AST into a flat sequence of memory layouts and computation steps?
	- Type level fold over the AST.
	- You need a IR which create and track infinite registers.
	- Each composition node gets its own layout with a size determined by the width of the string diagram at that point.
	- Cartesian product nodes are recursively converted to \[left] ++ \[right] layouts.
	- Coproduct nodes are converted to \[tag] ++ \[max] style layouts.
	- Construct computation steps which take the calculated input layout and produce the output layout.
	- Somehow link the layout registers to the correct inputs and outputs.
	- Finally lower the IR by assigning registers to each slot in each intermediate layout. This should be simple since each layout is independent.

## Progress on Compiler
6/4/2026

The architecture progressed through several major design phases to optimize pattern safety and eliminate redundant assembly move instructions:

### 1. Eliminating Non-Exhaustive Pattern Matching Warnings

- **The Problem:** The initial implementation used a standard data type for `Layout`, which led to GHC warning about non-exhaustive pattern matches because the compiler could not statically verify that the `Layout` shape matched the type index of the `AsmCat` expression.
    
- **The Solution:** We migrated `Layout` to a GADT indexed by a type-level representation of `Ty`. To bridge the gap between runtime value operations and compile-time type verification, a Singleton type (`STy`) was introduced. This allowed helper functions like `allocLayout` to return a strongly-typed `Layout t` without using complex existential wrappers (`SomeLayout`).
    

### 2. Transitioning to Pure Wire Tracking

- **The Problem:** Compiling composition (`Comp g f`) originally relied on allocating temporary layouts and running a copy pass (`generateCopies`), which generated redundant register-to-register `Mov` operations (e.g., `Mov r1 (Reg r1)`).
    
- **The Solution:** We decoupled structural layout tracking from assembly emission. By defining a pure metadata function `compileToLayout`, the compiler acts as a string-diagram wire tracer. Category-theoretic combinators (`Id`, `Fst`, `Snd`, `UnitorL`, etc.) are processed as zero-cost structural "views" that emit no physical assembly instructions.
    

### 3. Implementing Lazy Literal Materialization

- **The Problem:** In strict Destination-Passing Style (DPS), expressions are forced to write results into pre-allocated register layouts. This caused structural crashes when a pure literal generator (`PrimLit`) was composed and asked to write directly to a read-only immediate target.
    
- **The Solution:** We shifted the `compile` function signature to return synthesized layouts dynamically (`Compiler (Layout b, [Op])`). This allowed literal values (`Lit val`) to step forward through composition chains as weightless metadata. They are lazily retained on the "wires" and only materialize into concrete hardware registers at the exact moment they hit an operation that demands a physical machine state.
    
- Constant folding was further improved by compiling binary operators on two literals into a single literal AST node. This causes register allocation to only occur when at least one of the arguments is a variable. Nested expressions are automatically folded during compilation without a separate optimization step.

### 4. Categorical In-Place Optimizations

- **The Insight:** Because `AsmCat` operates under the strict laws of a monoidal category, wires cannot fork or branch implicitly; variables are treated as strictly linear resources unless an explicit duplicating/copying node is invoked.
    
- **The Outcome:** This structural guarantee allowed the implementation of highly aggressive, 100% safe in-place updates during instruction selection for mathematical nodes. For example, `PrimAdd` can destructively overwrite its input registers (e.g., `Add r1 r1 v2`) without requiring a separate live-range analysis pass or register allocator, as it is algebraically impossible for the input register `r1` to be accessed by any subsequent or parallel operation.

- This will be changed in the future to allow for virtual copies of registers. I need to add the capability for the compiler to track lifetimes and mutable vs. immutable copies. This will probably use the same logic as pointers. A virtual register copy is just a virtual pointer to a real register.

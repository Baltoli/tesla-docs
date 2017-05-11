# Programming with TESLA

This page walks you through how to use TESLA. It explains how TESLA is
implemented (and some associated terminology), how to use the toolchain, then
how to start writing useful assertions about your programs.

## TESLA Basics

TESLA is implemented as a set of tools that extend the traditional C compilation
process. To write TESLA assertions, you need to add these tools to your
build system and generate the TESLA intermediate products.

### Intermediate Products

To use TESLA, you need to generate some extra intermediate products during your
build process. These products are:

* **Assertions**: the assertions you write about a program are parsed out and
  written to external files in a structured format.
* **Manifest**: assertions in one file can reference those written in other
  files, so they need to be merged into one manifest file.
* **LLVM IR**: your code needs to be compiled to LLVM IR so that the TESLA tools
  can analyse and modify it.
* **Instrumented IR**: the assertion manifest is used to add TESLA
  instrumentation code to the compiled LLVM IR.

A dependency graph between these products is shown in the graph below.

![](process.dot.svg)

### Toolchain

To generate TESLA intermediate products, you use the TESLA command-line tools.
These are:

* `tesla analyse` generates an assertion file (`.tesla`) from a C source file.
* `tesla cat` combines assertion files together into a manifest.
* `tesla instrument` uses a manifest to add instrumentation code to IR.

Your C programs need to be compiled using `clang` 4.0. To generate LLVM IR from
a C source, use the flags `-c -emit-llvm`.

## Example

It's useful to work through a simple example to get a feel for the TESLA
toolchain and assertion language. The scenario we'll consider here is a [mutual
exclusion lock][mutex], with the aim of preventing deadlock.

The example code in this guide can be found [here][example-code].

### Setup

The first step is to establish the data structures and operations we'll be
working with. At its simplest, a mutual exclusion lock can be modelled by a
structure with a single boolean field:

```c
#include <stdatomic.h>
#include <stdbool.h>

struct lock {
  _Atomic(bool) held;
};
```

If we have a lock, the only things we can do are to _acquire_ or _release_ it:

```c
bool lock_acquire(struct lock *l) {
  bool f = false;
  return atomic_compare_exchange_strong(&(lock->held), &f, true);
}

void lock_release(struct lock *l) {
  l->held = false;
}
```

These operations are thread safe (because they're written using the C11 atomics
library). If `lock_acquire` is called on a lock that's already held, it returns
`false`. If we acquired the lock successfully, then it returns `true`.

The simplest possible program that uses the lock is:

```c
int main(void) {
  struct lock *l = malloc(sizeof(*lock));

  lock_acquire(l);
  lock_release(l);

  free(lock);
  return 0;
}
```

Because of limitations in the TESLA assertion parser, it can't currently work
with stack-allocated structures. Memory has to be dynamically allocated instead.

### A First Assertion

To prevent deadlock in code that uses these locks, the property we'd like to
assert is that a lock must eventually be released after it is acquired. The
TESLA expression of this property is:

```c
#include <tesla-macros.h>

bool lock_acquire(struct lock *l) {
  TESLA_WITHIN(main, eventually(
    call(lock_release(l))
  ));

  bool f = false;
  return atomic_compare_exchange_strong(&(lock->held), &f, true);
}
```

There's quite a few things going on here. `TESLA_WITHIN` is the primary starting
point for TESLA assertions. Its first argument should be a function that acts as
a "bounding context", and the second argument is a TESLA assertion.

A bounding context limits the scope of an assertion. When the context function
is called, TESLA performs internal initialisation (and cleanup when it returns).
In this example, the bounding context is `main`. For small programs this is OK,
but for larger programs it can lead to performance issues. Generally speaking,
it's best to use the narrowest bound possible for your assertions.

The assertion itself uses the `eventually` macro, which states that the body of
the macro (`call(lock_release(l))`) happens at some point *after* the assertion
site (i.e. the location of `TESLA_WITHIN(...)`).

Altogether, the assertion states that "during each execution of `main`, if the
assertion site is reached, `lock_release` is eventually called with `l` as its
argument". Note that if the assertion site is not reached, then the assertion
does not fail.

We can compile this first example using:

```shell
clang -O0 -c -emit-llvm locks.c -o locks.bc
tesla analyse locks.c -o locks.tesla --
tesla instrument -tesla-manifest locks.tesla locks.bc -o locks.instr.bc
clang locks.instr.bc -o locks
```

Running `./locks` will produce no output, as expected---the usage of the lock is
correct. If you modify the body of `main` to acquire but not release `l`, then
running the compiled executable will produce a TESLA crash:

```
TESLA failure:
In automaton 'locks.c:21#0':
TESLA_WITHIN(main, eventually(
    call(lock_release(l))
  ));
Instance 1 is in state 2
but received event '--(main() == X (Callee) <<cleanup>>)-->('NFA:5')'
(causes transition in: [ (1:0x0 -> 3:0x0 <clean>) (4:0x1 -> 3:0x0 <clean>) ])

locks: TESLA: failure in 'locks.c:21#0' --(main() == X (Callee) <<cleanup>>)-->('NFA:5'): bad transition
```

### Debugging

The TESLA crash in the previous section is rather difficult to understand. We
can get a better picture of it by using `tesla print` to print out a DOT
formatted version of the TESLA internal automaton:

```shell
tesla print -d -format=dot locks.tesla
```

This produces output that looks like this:

![](auto.dot.svg)

It's still not the easiest to understand, but we can get a better idea of why
the assertion failed---the automaton was in state 2, but received the `main() cleanup` event. From state 2, we can see that (as expected), instead of reaching
the end of `main`, we should have called `lock_release`.

[example-code]: https://github.com/Baltoli/tesla-examples/blob/master/site/locks.c
[mutex]: https://en.wikipedia.org/wiki/Mutual_exclusion

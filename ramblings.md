These are some habits that I have acquired that I currently think help me write better rust code.

# How to review code

## The module is the boundary at which invariants are enforced

- The module is the boundary at which invariants can be enforced:
    - It's ok to depend on invariants enforced elsewhere in the same module.
    - Read and understand every module that is changed in its entirety.
# Naming

## "Name variables, parameters, and associated types according to their roles"

This guideline is heavily inspired by the Swift API design guidelines [^1].
In Rust, it complements the new type idiom [^2] nicely.

```
struct Years(i32);

fn is_adult(age: &Years) -> bool {
    age.0 >= 18
}
```

## "Compensate for weak type information"

This guideline is heavily inspired by the Swift API design guidelines [^1].
One common occurrence is when dealing with time, where it is easy to forget what unit is being used;
seconds, milliseconds, microseconds, and nanoseconds are all common units that are often encoded using the same type.

```
fn is_adult(age_ms: &i32) -> bool {
    age_ms >= 568_036_800_000
}
```

# Other

## Don't implement `From<T> for U` where `U` is a semantically more specific type than `T`

Consider the example below.
In it a reader of `main` would likely miss the mistake.
This is especially true in code review tools, which typically add no annotations to the code besides syntax highlighting.
But even in my IDE the information needed to catch such a mistake is not eagerly displayed.

```
mod my_lib {
    pub struct UserId(u128);

    impl From<u128> for UserId {
        fn from(value: u128) -> Self {
            Self(value)
        }
    }

    /// Remove the user
    pub fn rm(_: UserId) {}
}

use my_lib::rm;

fn main() {
    let directory = 123;
    rm(directory.into());
}
```

This guideline is related to C-CONV-TRAITS [^6], which states that `From` "should be implemented where it makes sense".
Seen in that context, this guideline articulates one of the cases where doing so does not make sense.

## List all preconditions for a public function to not panic

Panics can hide in unexpected places and, though their behavior is defined, the consequences can still be dire [^5].

This guideline makes it easier to use functions in a way that don't cause the program to unexpectedly crash.
It also nudges function authors to reason about when a function may panic and provably remove such cases.

```
/// Say hello in the specified language
///
/// # Panics
///
/// This function panics if the language not "se".
fn say_hello(language: &str) {
    match language {
        "se" => println!("Hej!"),
        _ => panic!("Unknown language {language}")
    }
}
```

This is inspired by how the standard library development guide expects safety-preconditions to be documented [^3].
When it comes to ensuring memory safety, this is such a widespread practice that a Clippy lint exists [^4].
Unfortunately, no lints exist for defining and discharging non-memory-safety obligations for the caller. 

This guideline is related to C-FAILURE [^7], which states that "panic conditions should be documented in a "Panics" section".

[^1]: https://www.swift.org/documentation/api-design-guidelines
[^2]: https://doc.rust-lang.org/rust-by-example/generics/new_types.html
[^3]: https://github.com/rust-lang/std-dev-guide/blob/3158d0e090a3fd90ece1a9e6486bdf79d2a389d6/src/policy/safety-comments.md
[^4]: https://github.com/rust-lang/rust-clippy/blob/f43f1d61b72bf3ce1c58547ce7e72749b93d45a7/clippy_lints/src/doc/mod.rs#L106
[^5]: https://blog.cloudflare.com/18-november-2025-outage/#memory-preallocation
[^6]: https://github.com/rust-lang/api-guidelines/blob/97a0969cb07fe4cabb0eed8a56234053f47d83dc/src/interoperability.md#conversions-use-the-standard-traits-from-asref-asmut-c-conv-traits
[^7]: https://github.com/rust-lang/api-guidelines/blob/97a0969cb07fe4cabb0eed8a56234053f47d83dc/src/documentation.md#function-docs-include-error-panic-and-safety-considerations-c-failure
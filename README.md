#  PCG random number generator for Swift 4.2+

Swift implementation of a fast, space-efficient, and statistically excellent 64-bit random number generator using a [PCG algorithm](http://www.pcg-random.org). Works as a drop in replacement to the default random number generator in Swift 4.2+.

## Installation

### Compatibility

Requires Swift 4.2+

### Install Using Swift Package Manager
The [Swift Package Manager](https://swift.org/package-manager/) is a decentralized dependency manager for Swift.

1. Add the project to your `Package.swift`.

    ```swift
    import PackageDescription

    let package = Package(
        name: "MyProject",
        dependencies: [
            .Package(url: "https://github.com/amarcu5/pcg-swift.git",
                     majorVersion: 1)
        ]
    )
    ```

2. Import the PermutedCongruentialGenerator module.

    ```swift
    import PermutedCongruentialGenerator
    ```

## Usage

```Swift

var pcg = PermutedCongruentialGenerator.shared

["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"].randomElement(using: &pcg)!
// "Wed"

["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"].shuffled(using: &pcg)
// ["Tue", "Mon", "Fri", "Thu", "Sun", "Sat", "Wed"]

Int.random(in: 1...6, using: &pcg)
// 5

Double.random(in: -1...1, using: &pcg)
// -0.5793378414800663
```

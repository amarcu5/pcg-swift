//
//  PCG Random Number Generation for Swift.
//
//  Copyright 2018 Adam Marcus (https://github.com/amarcu5)
//  Based on original work by Melissa O'Neill
//
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      http://www.apache.org/licenses/LICENSE-2.0
//
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.
//
//  For additional information about the PCG random number generation scheme,
//  including its license and other licensing options, visit
//
//        http://www.pcg-random.org
//

import Foundation

// Generates 64-bit psuedo random integers using PCG (http://www.pcg-random.org)
//
// Internally combines the output of two distinct 32-bit PCG generators using
// XSH-RR output functions to workaround Swift's missing 128-bit math support
//
// Period: 2^64
// State space: ~2^254
// Statistical quality: Excellent (Passes TestU01's BigCrush and PractRand)
// Cryptographically secure: No
//
// Thread safe: No (But accessing `shared` across threads *is* safe as it
//                  returns a thread local instance)
//
public final class PermutedCongruentialGenerator : RandomNumberGenerator {
  
  private struct PCGRand32 {
    
    private static let _multiplier: UInt64 = 0x5851f42d4c957f2d
    
    private var _state: UInt64 = 0x853c49e6748fea9b
    private var _increment: UInt64 = 0xda3e39cb94b95bdb
    
    // Seed the RNG state
    mutating func seed(initstate: UInt64, initseq: UInt64) {
      _state = 0
      _increment = (initseq << 1) | 1
      step()
      _state = _state &+ initstate
      step()
    }
    
    // Generate random UInt32 using LCG permuted by XorShift and Rotate Right
    mutating func next() -> UInt32 {
      
      // Advance LCG, use old state for max ILP
      let oldState = _state
      step()
      
      // XorShift
      let xorShifted = UInt32(truncatingIfNeeded: ((oldState >> 18) ^ oldState) >> 27)
      
      // Rotate Right
      let rotationCount = UInt32(truncatingIfNeeded: oldState >> 59)
      let result = (xorShifted >> rotationCount) | (xorShifted << ((~rotationCount &+ 1) & 31))
      
      return result
    }
    
    // Multi-step advance underlying LCG (jump-ahead, jump-back)
    // Uses algorithm described by F. Brown, "Random Number Generation with Arbitrary Stride"
    // Trans. Am. Nucl. Soc. (Nov. 1994) to achieve O(log2(N)) time complexity
    mutating func advance(_ steps: Int64) {
      
      var currentMultiplier = PCGRand32._multiplier
      var currentPlus = _increment
      var accumulateMultiplier: UInt64 = 1
      var accumulatePlus: UInt64 = 0
      
      // Compute positive number of steps to skip by adding period of generator;
      // As period is 2^64 this can also be achieved by reinterpretting as an unsigned integer
      var delta = UInt64(bitPattern: steps)
      
      while delta > 0 {
        if delta & 1 != 0 {
          accumulateMultiplier = accumulateMultiplier &* currentMultiplier
          accumulatePlus = accumulatePlus &* currentMultiplier &+ currentPlus
        }
        currentPlus = (currentMultiplier &+ 1) &* currentPlus
        currentMultiplier = currentMultiplier &* currentMultiplier
        delta /= 2
      }
      _state = accumulateMultiplier &* _state &+ accumulatePlus
    }
    
    // Advance the underlying LCG one step
    private mutating func step() {
      _state = _state &* PCGRand32._multiplier &+ _increment
    }
  }
  
  // Returns a shared thread local instance seeded by the device generator
  public static var shared: PermutedCongruentialGenerator {
    get {
      let threadKey = "com.random.pcg" as NSString
      
      let localThreadDictionary = Thread.current.threadDictionary
      var threadLocalGenerator = localThreadDictionary[threadKey] as? PermutedCongruentialGenerator
      
      if threadLocalGenerator == nil {
        threadLocalGenerator = PermutedCongruentialGenerator()
        threadLocalGenerator!.seed(with: &DeviceRandom.shared)
        localThreadDictionary[threadKey] = threadLocalGenerator
      }
      
      return threadLocalGenerator!
    }
    set { /* Discard */ }
  }
  
  private var _generator1 = PCGRand32()
  private var _generator2 = PCGRand32()
  
  // Seed underlying PCG generators using another RNG
  public func seed<T: RandomNumberGenerator>(with generator: inout T) {
    seed(with: (generator.next(),
                generator.next(),
                generator.next(),
                generator.next()))
  }
  
  // Seed underlying PCG generators by value
  public func seed(with values: (UInt64, UInt64, UInt64, UInt64)) {
    let (seed1, seed2, seq1, seq2) = values
    
    // Ensure streams for each of the generators are distinct
    let mask: UInt64 = ~0 >> 1
    var distinctSeq2: UInt64 = seq2
    if (seq1 & mask) == (seq2 & mask) {
      distinctSeq2 = ~seq2
    }
    
    // Seed the generators
    _generator1.seed(initstate: seed1, initseq: seq1)
    _generator2.seed(initstate: seed2, initseq: distinctSeq2)
  }
  
  // Generate random UInt64
  public func next() -> UInt64 {
    return UInt64(_generator1.next()) << 32 | UInt64(_generator2.next())
  }
  
  // Advance underlying PCG generators forwards or backwards
  public func advance<N: BinaryInteger>(_ steps: N) {
    _generator1.advance(Int64(steps))
    _generator2.advance(Int64(steps))
  }
  
  // MARK: `DeviceRandom` specific performance enhancements

  // Seed underlying PCG generators using the device generator
  public func seed<T: DeviceRandom>(with generator: inout T) {
    var values = (UInt64(0), UInt64(0), UInt64(0), UInt64(0))
    withUnsafeMutableBytes(of: &values) { bytes in
      generator.fill(bytes: bytes)
    }
    
    seed(with: values)
  }
}

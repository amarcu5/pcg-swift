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

// Generates 64-bit psuedo random integers using the device generator at
// "/dev/random" or "/dev/urandom"
//
// Statistical quality: Good (although varies depending on OS implementation)
//
// Cryptographically secure: Yes
// Thread safe: Yes
//
public final class DeviceRandom : RandomNumberGenerator {
  
  // The device source
  public enum Source: String {
    
    // random device - usually blocks until sufficent device entropy
    case random
    
    // urandom device - usually non-blocking
    case urandom
    
    // The path for the device
    public var path: String {
      return "/dev/" + rawValue
    }
  }
  
  // Returns default global instance with "/dev/urandom"
  public static var `default` = DeviceRandom(source: .urandom)
  
  private let _fileDescriptor: Int32
  
  // Creates an instance by opening a file descriptor to the device at `source`
  public init(source: Source) {
    _fileDescriptor = open(source.path, O_RDONLY | O_CLOEXEC)
    
    if _fileDescriptor < 0 {
      fatalError("Unable to read \(source.path)")
    }
  }
  
  // Release the file descriptor
  deinit {
    close(_fileDescriptor)
  }
  
  // Generate random UInt64
  public func next() -> UInt64 {
    var value: UInt64 = 0
    read(_fileDescriptor, &value, MemoryLayout<UInt64>.size)
    return value
  }
  
  // FIXME: De-underscore after swift-evolution amendment
  public func _fill(bytes: UnsafeMutableRawBufferPointer) {
    read(_fileDescriptor, bytes.baseAddress, bytes.count)
  }
}

import XCTest
@testable import PermutedCongruentialGenerator

private let targetValues: [UInt64] = [
  0xa15c02b71a410f65, 0x7b47f409e0b09a53, 0xba1d333011fba8ac, 0x83d2f293452993e9,
  0xbfa4784b36082c12, 0xcbed606ef5934191, 0xbfc6a3ad57d8966c, 0x812fff6db80de24a,
  0xe61f305a24b91bda, 0xf9384b90a56af4d2, 0x32db86feb6ca672f, 0x1dc035f927571abe,
  0xed78682682c952c1, 0x3822441dad4a4f6c, 0x2ba113d78f9980f4, 0x1c5b818b776e5403,
  0xa233956a00af3273, 0x84da65e33bfd2ee3, 0xced67292038cb94f, 0xb2c0fe063c815560,
  0x91817130fa9bbb8b, 0x55fe891791327bc8, 0x47e92091affd6be4, 0x486af29908d3c60e,
  0xb1e882bba1af1e12, 0xc261e84548dfb740, 0x1a9b90f686ba8b46, 0x7964e884f88f3f81,
  0x5f36d7a4220d7b8f, 0x1ee2052d3bce00a4, 0x8519f5d5b267296b, 0x293d4e4f14b72035,
]

final class PermutedCongruentialGeneratorTests: XCTestCase {
  
  static let allTests = [
    ("testValues", testValues),
    ("testJump", testJump),
  ]
  
  // Test output against reference implementation
  func testValues() {
    
    // Create generator with specific seed
    var pcg = PermutedCongruentialGenerator()
    pcg.seed(with: (42, 42, 54, 54))
    
    // Generate the values
    var values = [UInt64]()
    for _ in 0 ..< targetValues.count {
      values.append(UInt64.random(in: .min ... .max, using: &pcg))
    }
    
    // Ensure values equal reference implementation
    XCTAssertEqual(values, targetValues)
  }
  
  // Tests jump ahead/backwards
  func testJump() {
  
    let testCount = 1000
    let stepSize = 10
    
    var pcg = PermutedCongruentialGenerator.shared
    
    // Generate initial values
    var initialValues = [UInt64]()
    for _ in 0 ..< testCount {
      initialValues.append(UInt64.random(in: .min ... .max, using: &pcg))
      pcg.advance(stepSize)
    }
    
    // Reset the stream by jumping backward
    pcg.advance(-testCount * (stepSize + 1))
    
    // Calculate jump values
    var jumpValues = [UInt64]()
    for _ in 0 ..< testCount {
      jumpValues.append(UInt64.random(in: .min ... .max, using: &pcg))
      pcg.advance(stepSize)
    }
    
    // Ensure values are equal
    XCTAssertEqual(initialValues, jumpValues)
  }
  
}

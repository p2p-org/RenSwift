import Foundation
import SolanaSwift

extension Array where Element == UInt8 {
    public func sha3(_ variant: SHA3.Variant) -> Self {
        SHA3(variant: variant).calculate(for: self)
    }
    
    public func sha256() -> Self {
        SHA2(variant: .sha256).calculate(for: self)
    }
}

extension Data {
    public func sha3(_ variant: SHA3.Variant) -> Self {
        Data(Array(self).sha3(variant))
    }
    
    public func sha256() -> Self {
        Data(Array(self).sha256())
    }
}

extension Array {
    @inlinable
    var slice: ArraySlice<Element> {
        self[self.startIndex ..< self.endIndex]
    }
}

extension Collection where Self.Element == UInt8, Self.Index == Int {
  // Big endian order
  @inlinable
  func toUInt32Array() -> Array<UInt32> {
    guard !isEmpty else {
      return []
    }

    let c = strideCount(from: startIndex, to: endIndex, by: 4)
    return Array<UInt32>(unsafeUninitializedCapacity: c) { buf, count in
      var counter = 0
      for idx in stride(from: startIndex, to: endIndex, by: 4) {
        let val = UInt32(bytes: self, fromIndex: idx).bigEndian
        buf[counter] = val
        counter += 1
      }
      count = counter
      assert(counter == c)
    }
  }

  // Big endian order
  @inlinable
  func toUInt64Array() -> Array<UInt64> {
    guard !isEmpty else {
      return []
    }

    let c = strideCount(from: startIndex, to: endIndex, by: 8)
    return Array<UInt64>(unsafeUninitializedCapacity: c) { buf, count in
      var counter = 0
      for idx in stride(from: startIndex, to: endIndex, by: 8) {
        let val = UInt64(bytes: self, fromIndex: idx).bigEndian
        buf[counter] = val
        counter += 1
      }
      count = counter
      assert(counter == c)
    }
  }
}

@usableFromInline
func strideCount(from: Int, to: Int, by: Int) -> Int {
    let count = to - from
    return count / by + (count % by > 0 ? 1 : 0)
}

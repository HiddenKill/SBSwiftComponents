//
//  SBManualExt.swift
//  SBSwiftComponents
//
//  Created by nanhu on 2018/9/4.
//  Copyright © 2018年 nanhu. All rights reserved.
//

import UIKit
import SBToaster
import Foundation

// MARK: - Hash-MAC for String
public enum CryptoAlgorithm {
    /// 加密的枚举选项
    case MD5, SHA1, SHA224, SHA256, SHA384, SHA512
    var HMACAlgorithm: CCHmacAlgorithm {
        var result: Int = 0
        switch self {
        case .MD5:      result = kCCHmacAlgMD5
        case .SHA1:     result = kCCHmacAlgSHA1
        case .SHA224:   result = kCCHmacAlgSHA224
        case .SHA256:   result = kCCHmacAlgSHA256
        case .SHA384:   result = kCCHmacAlgSHA384
        case .SHA512:   result = kCCHmacAlgSHA512
        }
        return CCHmacAlgorithm(result)
    }
    var digestLength: Int {
        var result: Int32 = 0
        switch self {
        case .MD5:      result = CC_MD5_DIGEST_LENGTH
        case .SHA1:     result = CC_SHA1_DIGEST_LENGTH
        case .SHA224:   result = CC_SHA224_DIGEST_LENGTH
        case .SHA256:   result = CC_SHA256_DIGEST_LENGTH
        case .SHA384:   result = CC_SHA384_DIGEST_LENGTH
        case .SHA512:   result = CC_SHA512_DIGEST_LENGTH
        }
        return Int(result)
    }
}
public extension String {
    
    private func sb_stringFromResult(result: UnsafeMutablePointer<CUnsignedChar>, length: Int) -> String {
        let hash = NSMutableString()
        for i in 0..<length {
            hash.appendFormat("%02x", result[i])
        }
        return String(hash)
    }
    public func sb_hmac(algorithm: CryptoAlgorithm, key: String = "com.landun.app") -> String {
        let str = self.cString(using: String.Encoding.utf8)
        let strLen = Int(self.lengthOfBytes(using: String.Encoding.utf8))
        let digestLen = algorithm.digestLength
        let result = UnsafeMutablePointer<CUnsignedChar>.allocate(capacity: digestLen)
        let keyStr = key.cString(using: String.Encoding.utf8)
        let keyLen = Int(key.lengthOfBytes(using: String.Encoding.utf8))
        CCHmac(algorithm.HMACAlgorithm, keyStr!, keyLen, str!, strLen, result)
        let digest = sb_stringFromResult(result:  result, length: digestLen)
        result.deallocate()
        return digest
    }
}

public extension Data {
    public func md5String() -> String {
        var digest = [UInt8](repeating: 0, count: Int(CC_MD5_DIGEST_LENGTH))
        _ = withUnsafeBytes({ (bytes) in
            CC_MD5(bytes, CC_LONG(count), &digest)
        })
        var digestHex = ""
        for idx in 0 ..< Int(CC_MD5_DIGEST_LENGTH) {
            digestHex += String(format: "%02x", digest[idx])
        }
        return digestHex
    }
    
    public func sha256String() -> String {
        var digest = [UInt8](repeating: 0, count: Int(CC_SHA256_DIGEST_LENGTH))
        _ = withUnsafeBytes({ (bytes) in
            CC_SHA256(bytes, CC_LONG(count), &digest)
        })
        var digestHex = ""
        for idx in 0 ..< Int(CC_SHA256_DIGEST_LENGTH) {
            digestHex += String(format: "%02x", digest[idx])
        }
        return digestHex
    }
}

// MARK: - 自增 自减
extension Int {
    static postfix func ++(num: inout Int) -> Int {
        num = num + 1
        return num
    }
    
    static postfix func --(num: inout Int) -> Int {
        num = num - 1
        return num
    }
}

// MARK: - Base Profile手动扩展
extension BaseProfile {
    func app() -> AppDelegate {
        return UIApplication.shared.delegate as! AppDelegate
    }
}

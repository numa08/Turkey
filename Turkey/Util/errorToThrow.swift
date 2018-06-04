//
//  errorToThrow.swift
//  Turkey
//
//  Created by numa08 on 2018/06/01.
//  Copyright © 2018年 numa08. All rights reserved.
//

import Foundation

func errorToThrow<T> (_ fn: (ErrorPointer) -> T) throws -> T {
    var error: NSError?
    let t = fn(&error)
    if let error = error {
        throw error
    }
    return t
}

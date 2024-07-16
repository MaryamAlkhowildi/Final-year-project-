//
//  ARCollosion .swift
//  FinalYearProjectLegoLike
//
//  Created by MARYAM ALKHOWILDI on 16/02/2024.
//

import Foundation

struct ARCollision: OptionSet {
    let rawValue: Int

    static let bottom = ARCollision(rawValue: 1 << 0)
    static let block = ARCollision(rawValue: 1 << 1)
}

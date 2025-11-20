//
//  Typography.swift
//  CardGenius
//
//  Design System - Typography
//

import SwiftUI

extension Font {
    static func cgTitle(_ size: CGFloat = 34, weight: Weight = .bold) -> Font {
        .system(size: size, weight: weight, design: .default)
    }
    
    static func cgHeadline(_ size: CGFloat = 20, weight: Weight = .semibold) -> Font {
        .system(size: size, weight: weight, design: .default)
    }
    
    static func cgBody(_ size: CGFloat = 17, weight: Weight = .regular) -> Font {
        .system(size: size, weight: weight, design: .default)
    }
    
    static func cgSubheadline(_ size: CGFloat = 15, weight: Weight = .regular) -> Font {
        .system(size: size, weight: weight, design: .default)
    }
    
    static func cgCaption(_ size: CGFloat = 13, weight: Weight = .regular) -> Font {
        .system(size: size, weight: weight, design: .default)
    }
    
    static func cgFootnote(_ size: CGFloat = 12, weight: Weight = .regular) -> Font {
        .system(size: size, weight: weight, design: .default)
    }
}


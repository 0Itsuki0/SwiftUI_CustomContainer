//
//  View+Extensions.swift
//  ItsukiBoard
//
//  Created by Itsuki on 2024/09/26.
//
import SwiftUI

extension View {
    
    // card view
    func cardBackground<V>(@ViewBuilder _ view: () -> V) -> some View where V : View {
        containerValue(\.cardBackground, AnyView(view()))
    }
    
    func cardPadding(_ edges: Edge.Set, _ length: CGFloat) -> some View {
        containerValue(\.cardPadding, (edges, length))
    }
}


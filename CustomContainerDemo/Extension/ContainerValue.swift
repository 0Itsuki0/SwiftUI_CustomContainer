//
//  ContainerValue+Extensions.swift
//  CustomContainerDemo
//
//  Created by Itsuki on 2024/09/28.
//

import SwiftUI

extension ContainerValues {
    // card view
    @Entry var cardBackground: AnyView = AnyView(CardView.defaultBackground)
    @Entry var cardPadding: (Edge.Set, CGFloat) = CardView.defaultPadding
}

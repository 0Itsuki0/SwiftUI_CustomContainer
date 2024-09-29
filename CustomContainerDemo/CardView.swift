//
//  CardView.swift
//  ItsukiBoard
//
//  Created by Itsuki on 2024/09/26.
//

import SwiftUI

struct CardView<Content: View, Background: View>: View {
    // padding
    var padding: (Edge.Set, CGFloat)
    
    // background
    @ViewBuilder var background: Background
    @ViewBuilder var content: Content

    var body: some View {
        content
            .padding(padding.0, padding.1)
            .background(
                background
            )
    }
}

extension CardView where Content == Never, Background == Never  {
    static var defaultBackground: some View {
        let backgroundShape = RoundedRectangle(cornerRadius: 8)
        
        return ZStack {
            backgroundShape
                .inset(by: 2)
                .fill(.clear)
            backgroundShape
                .strokeBorder(.black.opacity(0.7), lineWidth: 1)
        }
        .background(
            .white.shadow(.drop(
                color: .black.opacity(0.3),
                radius: 1, x: 1, y: 2)),
            in: backgroundShape)
    }
    
    static var defaultPadding: (Edge.Set, CGFloat) = (.all, 16)
}


#Preview {
    VStack {
        CardView(
            padding:CardView.defaultPadding,
            background: {
                CardView.defaultBackground
            }, content: {
                Text("test")
            })
        
        CardView(
            padding:CardView.defaultPadding,
            background: {
                CardView.defaultBackground
            },
            content: {
                VStack {
                    HStack {
                        Image(systemName: "heart.fill")
                        Text("heart.fill")
                    }
                    HStack {
                        Image(systemName: "cloud")
                        Text("cloud")
                    }
                }
            }
        )
    }
}

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
    
    var onDelete: (() -> Void)? = nil

    @State private var showDelete: Bool = false
    private let maxButtonWidth: CGFloat = 48
    private let dampingFactor: CGFloat = 0.1
    @State private var buttonWidth: CGFloat = .zero

    var body: some View {
        content
            .padding(padding.0, padding.1)
            .background(
                background
            )
            .containerShape(Rectangle())
            .gesture(
                DragGesture()
                    .onChanged { value in
                        if onDelete == nil {return}
                        let translationWidth = value.translation.width*dampingFactor
                        if translationWidth > 0 && buttonWidth <= 0 {
                            return
                        }
                        buttonWidth = max(0, min(buttonWidth-translationWidth, maxButtonWidth))
                    }
                    .onEnded({ value in
                        if onDelete == nil {return}
                        withAnimation {
                            if buttonWidth > maxButtonWidth/2 {
                                buttonWidth = maxButtonWidth
                            } else {
                                buttonWidth = 0
                            }
                        }
                    })
            )
            .overlay(alignment: .trailing, content: {
                Button(action: {
                    onDelete?()
                }, label: {
                    Image(systemName: "trash.fill")
                        .resizable()
                        .scaledToFit()
                        .frame(maxWidth: 24)
                        .foregroundStyle(.white)
                        .padding(.horizontal, 16)
                        .frame(width: buttonWidth)
                        .frame(maxHeight: .infinity)
                        .background(RoundedRectangle(cornerRadius: 8).fill(.red))
                })

            })

                
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
            }, onDelete: nil)
        
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
            }, onDelete: {}
        )
    }
}

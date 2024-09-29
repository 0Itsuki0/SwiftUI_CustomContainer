//
//  V3.swift
//  CustomContainerDemo
//
//  Created by Itsuki on 2024/09/27.
//

// subview counts

import SwiftUI

struct SectionViewV3<Content: View, MoreButtonLabel: View, HideButtonLabel: View>: View {
    @ViewBuilder var content: Content
    
    var padding: (horizontal: CGFloat, vertical: CGFloat)

    var itemSpacing: CGFloat
    var sectionWidth: CGFloat?
    
    var backgroundStyle: (color: Color, strokeStyle: StrokeStyle)
    
    var maxItemCount: Int?
    @ViewBuilder var moreButtonLabel: MoreButtonLabel
    @ViewBuilder var hideButtonLabel: HideButtonLabel
    var toggleAnimation: Animation
    

    @State private var isExpanded: Bool = false
    
    var body: some View {
        Group(subviews: content) { subviews in
            let moreItemsAvailable = if let maxItemCount = maxItemCount, subviews.count > maxItemCount {
                true
            } else {
                false
            }
            
            let newSubviews = if let maxItemCount = maxItemCount, moreItemsAvailable, !isExpanded {
                Array(subviews.prefix(maxItemCount))
            } else {
                Array(subviews)
            }
            
            VStack(spacing: itemSpacing) {
                
                ForEach(newSubviews) { subview in
                    let values = subview.containerValues
                    let background = values.cardBackground
                    let padding = values.cardPadding
                    CardView(
                        padding: padding,
                        background: {background},
                        content: {
                            subview
                                .frame(maxWidth: .infinity)
                        })
                }
                
                if moreItemsAvailable {
                    Button(action: {
                        isExpanded.toggle()
                    }, label: {
                        if isExpanded {
                            hideButtonLabel
                        } else {
                            moreButtonLabel
                        }
                    })
                }
                
            }
            .padding(.horizontal, padding.horizontal)
            .padding(.vertical, padding.vertical)
            .animation(toggleAnimation, value: isExpanded)
            .frame(width: sectionWidth)
            .frame(alignment: .top)
            .background(background())
        }
    }
    
    private func background(isHeaderFooter: Bool = false) ->  some View {
        let backgroundShape = RoundedRectangle(cornerRadius: 8)
        
        return ZStack {
            backgroundShape
                .inset(by: 2)
                .fill(backgroundStyle.color.opacity(isHeaderFooter ? 0.6 : 0.3))
            backgroundShape
                .stroke(backgroundStyle.color.opacity(0.8), style: backgroundStyle.strokeStyle)
        }
        .background(
            .white.shadow(.drop(
                color: backgroundStyle.color.opacity(0.3),
                radius: 1, x: 1, y: 2)),
            in: backgroundShape)
    }
}

#Preview {
    let items = [1, 2, 3, 4, 5, 6, 7, 8]
    
    HStack {
        
        SectionViewV3(content: {
            ForEach(items, id:\.self) { item in
                Text("item: \(item)")
            }
        }, padding: (24, 24), itemSpacing: 24, sectionWidth: 160, backgroundStyle: (.brown, .init(lineWidth: 1.0)),maxItemCount: 4, moreButtonLabel: {
            Text("my button")
        }, hideButtonLabel: {
            Text("hide")
        }, toggleAnimation: .default)
        .frame(maxHeight: .infinity, alignment: .top)

    }

}

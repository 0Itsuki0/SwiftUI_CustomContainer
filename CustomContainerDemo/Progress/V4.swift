//
//  V4.swift
//  CustomContainerDemo
//
//  Created by Itsuki on 2024/09/27.
//

// sections

import SwiftUI

struct BoardViewV4<Content: View>: View {
    @ViewBuilder var content: Content

    var title: String? = nil
    
    var padding: (Edge.Set, CGFloat) = (.all, 48)
    var sectionSpacing: CGFloat = 24

    var backgroundColor: Color = .gray
    var backgroundStrokeStyle: StrokeStyle = .init(lineWidth: 1)

    var body: some View {
        Group(sections: content) { sections in
            HStack(spacing: sectionSpacing) {
                ForEach(sections) { section in

                    SectionViewV4(
                        header: section.header,
                        footer: section.footer,
                        content: section.content,
                        padding: (24, 24),
                        itemSpacing: 16,
                        sectionWidth: 240,
                        backgroundStyle: SectionViewV4.defaultBackgroundStyle,
                        maxItemCount: nil,
                        moreButtonLabel: {SectionViewV4.defaultMoreButtonLabel},
                        hideButtonLabel:  {SectionViewV4.defaultHideButtonLabel},
                        toggleAnimation: .linear(duration: 0.4)

                    )
                    .frame(maxHeight: .infinity, alignment: .top)
                }
            }
            .fixedSize(horizontal: false, vertical: true)
            .padding(padding.0, padding.1)
            .background(background())
        }

    }
    
    private func background(isTitle: Bool = false) ->  some View {
        let backgroundShape = RoundedRectangle(cornerRadius: 8)
        
        return ZStack {
            backgroundShape
                .inset(by: 2)
                .fill(backgroundColor.opacity(0.3))
            backgroundShape
                .stroke(backgroundColor.opacity(0.8), style: backgroundStrokeStyle)
        }
        .background(
            .white.shadow(.drop(
                color: backgroundColor.opacity(0.3),
                radius: 1, x: 1, y: 2)),
            in: backgroundShape)
    }
}


#Preview {
    let items = [1, 2, 3, 4, 5, 6, 7, 8]
        
    BoardViewV4(content: {
        Section {
            ForEach(items, id:\.self) { item in
                Text("section 1: \(item)")
            }
        }
        
        Section(content: {
            ForEach(items, id:\.self) { item in
                Text("section 2: \(item)")
            }
        }, header: {
            Text("header")
        }, footer: {
            Text("footer")
        })
        
        Section {
            ForEach(items, id:\.self) { item in
                Text("section 3: \(item)")
            }
        }
        
        ForEach(items, id:\.self) { item in
            Text("non-section: \(item)")
        }
    })
    .frame(maxHeight: .infinity, alignment: .top)
}



fileprivate struct SectionViewV4<MoreButtonLabel: View, HideButtonLabel: View>: View {
    
    var header: SubviewsCollection
    var footer: SubviewsCollection
    var content: SubviewsCollection
    
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
        let moreItemsAvailable = if let maxItemCount = maxItemCount, content.count > maxItemCount {
            true
        } else {
            false
        }

        let newSubviews = if let maxItemCount = maxItemCount, moreItemsAvailable, !isExpanded {
            Array(content.prefix(maxItemCount))
        } else {
            Array(content)
        }
        
        VStack(spacing: itemSpacing) {
            if !header.isEmpty {
                headerView()
            } else {
                Spacer().frame(height: padding.vertical)
            }

            ForEach(newSubviews) { subview in
                CardView(
                    padding: CardView.defaultPadding,
                    background: {CardView.defaultBackground},
                    content: {
                        subview
                            .frame(maxWidth: .infinity)
                    })
            }
            .padding(.horizontal, padding.horizontal)
            
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
            
            if !footer.isEmpty {
                footerView()
            } else {
                Spacer().frame(height: padding.vertical)
            }

        }
        .animation(toggleAnimation, value: isExpanded)
        .frame(width: sectionWidth)
        .frame(alignment: .top)
        .background(background())
        
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
    
    func headerView() -> some View {
        header
            .padding(.all, 16)
            .frame(maxWidth: .infinity)
            .background(background(isHeaderFooter: true))
    }
    
    func footerView() -> some View {
        footer
            .padding(.all, 16)
            .frame(maxWidth: .infinity)
            .background(background(isHeaderFooter: true))
    }
}

extension SectionViewV4 where MoreButtonLabel == Never, HideButtonLabel == Never {
    
    static var defaultPadding: (horizontal: CGFloat, vertical: CGFloat) = (24, 24)
    static var defaultItemSpacing: CGFloat = 16
    static var defaultSectionWidth: CGFloat? = 240.0
    
    static var defaultBackgroundStyle: (color: Color, strokeStyle: StrokeStyle) = (.brown, .init(lineWidth: 1))
    
    static var defaultMoreButtonLabel: some View {
        Text("More")
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .foregroundStyle(.white)
            .background(RoundedRectangle(cornerRadius: 8).fill(.black))
    }
    
    static var defaultHideButtonLabel: some View {
        Text("Hide")
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .foregroundStyle(.white)
            .background(RoundedRectangle(cornerRadius: 8).fill(.black))
    }
    
    static var defaultMaxItemCount: Int? = nil
    static var defaultAnimation: Animation = .default

}

#Preview {
    let items = [1, 2, 3, 4, 5, 6, 7, 8]
    let content = Section(content: {
        ForEach(items, id:\.self) { item in
            Text("item: \(item)")
                .cardBackground({Ellipse()
                    .background(Color.clear)
                    .foregroundColor(.purple)
                    .opacity(0.3)})
                .cardPadding(.vertical, 24)
        }
    }, header: {
        Text("header")
    }, footer: {
        Text("footer")
    })
    

    ScrollView {
        VStack {
            ForEach(sections: content) { section in
                SectionViewV4(
                    header: section.header,
                    footer: section.footer,
                    content: section.content,
                    padding: (24, 24),
                    itemSpacing: 16,
                    sectionWidth: 240,
                    backgroundStyle: SectionViewV4.defaultBackgroundStyle,
                    maxItemCount: 4,
                    moreButtonLabel: {SectionViewV4.defaultMoreButtonLabel},
                    hideButtonLabel:  {SectionViewV4.defaultHideButtonLabel},
                    toggleAnimation: .linear(duration: 0.4)
                )
            }
        }
        .scrollTargetLayout()
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
    .scrollIndicators(.hidden)

}


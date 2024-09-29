//
//  V5.swift
//  CustomContainerDemo
//
//  Created by Itsuki on 2024/09/27.
//

// container Values

import SwiftUI

struct BoardViewV5<Content: View>: View {

    var title: String? = nil
    
    var padding: (Edge.Set, CGFloat) = (.all, 48)
    var sectionSpacing: CGFloat = 24

    var backgroundColor: Color = .gray
    var backgroundStrokeStyle: StrokeStyle = .init(lineWidth: 1)
    
    @ViewBuilder var content: Content


    var body: some View {
        Group(sections: content) { sections in
            HStack(spacing: sectionSpacing) {
                ForEach(sections) { section in
                    let values = section.containerValues
                    SectionViewV5(
                        header: section.header,
                        footer: section.footer,
                        content: section.content,
                        padding: values.sectionPadding,
                        itemSpacing: values.itemSpacing,
                        sectionWidth: values.sectionWidth,
                        backgroundStyle: values.sectionBackgroundStyle,
                        maxItemCount: values.maxItemCount,
                        moreButtonLabel: {values.moreButtonLabel},
                        hideButtonLabel:  {values.hideButtonLabel},
                        toggleAnimation: values.toggleAnimation

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

extension BoardViewV5 {
    init<Data: RandomAccessCollection, C: View>(_ data: Data, @ViewBuilder content: @escaping (Data.Element) -> C) where Data.Element: Identifiable, Content == ForEach<Data, Data.Element.ID, C> {
        self.init {
            ForEach(data, content: content)
        }
    }
    
    init<Data: RandomAccessCollection,  ID : Hashable, C: View>(_ data: Data, id: KeyPath<Data.Element, ID>, @ViewBuilder content: @escaping (Data.Element) -> C) where Content == ForEach<Data, ID, C> {
        self.init {
            ForEach(data, id: id, content: content)
        }
    }
}


fileprivate extension ContainerValues {
    
    // section View
    @Entry var sectionPadding: (horizontal: CGFloat, vertical: CGFloat) = SectionViewV5.defaultPadding
    @Entry var itemSpacing: CGFloat = SectionViewV5.defaultItemSpacing
    @Entry var sectionWidth: CGFloat? = SectionViewV5.defaultSectionWidth
    @Entry var sectionBackgroundStyle: (color: Color, strokeStyle: StrokeStyle) = SectionViewV5.defaultBackgroundStyle
    
    @Entry var maxItemCount: Int? = SectionViewV5.defaultMaxItemCount
    @Entry var moreButtonLabel: AnyView = AnyView(SectionViewV5.defaultMoreButtonLabel)
    @Entry var hideButtonLabel: AnyView = AnyView(SectionViewV5.defaultHideButtonLabel)
    @Entry var toggleAnimation: Animation = SectionViewV5.defaultAnimation

}


fileprivate extension View {
    
    // section view
    
    func sectionPadding(_ horizontal: CGFloat, _ vertical: CGFloat) -> some View {
        containerValue(\.sectionPadding, (horizontal, vertical))
    }
    
    func itemSpacing(_ spacing: CGFloat) -> some View {
        containerValue(\.itemSpacing, spacing)
    }
    
    func sectionWidth(_ width: CGFloat?) -> some View {
        containerValue(\.sectionWidth, width)
    }
    
    func sectionBackgroundStyle(_ color: Color, _ strokeStyle: StrokeStyle) -> some View {
        containerValue(\.sectionBackgroundStyle, (color, strokeStyle))
    }

    
    
    func maxItemCount(_ count: Int?) -> some View {
        containerValue(\.maxItemCount, count)
    }
    
    func moreButtonLabel<V>(@ViewBuilder _ view: () -> V) -> some View where V : View {
        containerValue(\.moreButtonLabel, AnyView(view()))
    }
    
    func hideButtonLabel<V>(@ViewBuilder _ view: () -> V) -> some View where V : View {
        containerValue(\.hideButtonLabel, AnyView(view()))
    }
    
    func toggleAnimation(_ animation: Animation) -> some View {
        containerValue(\.toggleAnimation, animation)
    }
}


fileprivate struct SectionViewV5<MoreButtonLabel: View, HideButtonLabel: View>: View {
    
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

extension SectionViewV5 where MoreButtonLabel == Never, HideButtonLabel == Never {
    
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
                SectionViewV5(
                    header: section.header,
                    footer: section.footer,
                    content: section.content,
                    padding: (24, 24),
                    itemSpacing: 16,
                    sectionWidth: 240,
                    backgroundStyle: SectionViewV5.defaultBackgroundStyle,
                    maxItemCount: 4,
                    moreButtonLabel: {SectionViewV5.defaultMoreButtonLabel},
                    hideButtonLabel:  {SectionViewV5.defaultHideButtonLabel},
                    toggleAnimation: .linear(duration: 0.4)
                )
            }
        }
        .scrollTargetLayout()
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
    .scrollIndicators(.hidden)

    
}


struct V5ContentView: View {
    let items = [1, 2, 3, 4, 5, 6, 7, 8]

    var body: some View {
            
        BoardViewV5(content: {
            Section {
                ForEach(items, id:\.self) { item in
                    Text("section 1: \(item)")
                }
            }
            
            ForEach(items, id:\.self) { item in
                Text("non-section: \(item)")
                    .cardBackground({Ellipse()
                        .background(Color.clear)
                        .foregroundColor(.purple)
                        .opacity(0.3)})
                    .cardPadding(.vertical, 24)
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
            .sectionPadding(0, 0)
            .maxItemCount(4)
            .moreButtonLabel({
                HStack {
                    Image(systemName: "heart.fill")
                    Text("More")
                }
            })
            .hideButtonLabel({
                HStack {
                    Image(systemName: "heart.fill")
                    Text("Less")
                }
            })
            .sectionWidth(120)
            .sectionBackgroundStyle(.green, .init(lineWidth: 2.0))
            
            
        })
        .frame(maxHeight: .infinity, alignment: .top)
    }
}


#Preview {
    V5ContentView()
}

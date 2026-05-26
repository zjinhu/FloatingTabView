//
//  FloatingTabView.swift
//  PawLog
//
//  Created by HU on 4/20/26.
//

import SwiftUI

public struct TabItemData: Identifiable, Equatable {
    public let icon: Image
    public let iconHighlight: Image
    public let title: String
    public var id: AnyHashable
}

public struct FloatingTabItemPreferenceKey: PreferenceKey {
    public static var defaultValue: [TabItemData] = []
    
    public static func reduce(value: inout [TabItemData], nextValue: () -> [TabItemData]) {
        for item in nextValue() {
            if !value.contains(where: { $0.id == item.id }) {
                value.append(item)
            }
        }
    }
}

public extension View {
    
    @ViewBuilder
    func floatingTabItem(
        title: String,
        icon: Image,
        iconHighlight: Image,
        tag: Int
    ) -> some View {
        self
            .tag(tag)
            .preference(
                key: FloatingTabItemPreferenceKey.self,
                value: [TabItemData(icon: icon, iconHighlight: iconHighlight, title: title, id: tag)]
            )
            .toolbar(.hidden, for: .tabBar)
    }
    
    @ViewBuilder
    func floatingTabItem<T: TabItemProtocol>(_ item: T) -> some View {
        self
            .tag(item)
            .preference(key: FloatingTabItemPreferenceKey.self, value: [TabItemData(icon: item.icon, iconHighlight: item.iconHighlight, title: item.title, id: item)])
            .toolbar(.hidden, for: .tabBar)
    }
}

public struct FloatingTabView<SelectionValue: Hashable, Content: View>: View {
    @Binding private var selection: SelectionValue
    @State private var tabs: [TabItemData] = []
    private let content: Content
    private var themeColor: Color = .blue
    private var trailingIcon: Image?
    private var trailingIconHighlight: Image?
    private var trailingMenu: ((@escaping () -> Void) -> AnyView)?
    @Namespace private var animation
    @State private var isExpandedInternal: Bool = false
    private var isExpandedBinding: Binding<Bool>?
    @State private var capsuleWidth: CGFloat?
    private let barHeight: CGFloat = 55
    
    private var isExpanded: Bool {
        get { isExpandedBinding?.wrappedValue ?? isExpandedInternal }
        nonmutating set {
            if let binding = isExpandedBinding {
                binding.wrappedValue = newValue
            } else {
                isExpandedInternal = newValue
            }
        }
    }
    
    public init(
        selection: Binding<SelectionValue>,
        trailingIcon: Image? = nil,
        trailingIconHighlight: Image? = nil,
        trailingMenu: ((@escaping () -> Void) -> AnyView)? = nil,
        isExpandedBinding: Binding<Bool>? = nil,
        @ViewBuilder content: () -> Content
    ) {
        self._selection = selection
        self.trailingIcon = trailingIcon
        self.trailingIconHighlight = trailingIconHighlight
        self.trailingMenu = trailingMenu
        self.isExpandedBinding = isExpandedBinding
        self.content = content()
    }
    
    public var body: some View {
        TabView(selection: $selection) {
            content
        }
        .overlay {
            Color.black.opacity(isExpanded ? 0.15 : 0)
                .ignoresSafeArea()
                .allowsHitTesting(isExpanded)
                .onTapGesture {
                    withAnimation(.bouncy(duration: 0.5, extraBounce: 0.05)) {
                        isExpanded = false
                    }
                }
                .animation(.easeInOut(duration: 0.3), value: isExpanded)
        }
        .safeAreaInset(edge: .bottom) {
            // 固定高度的 spacer，不受 morph 动画影响
            Color.clear.frame(height: barHeight + 10)
            
        }
        .overlay(alignment: .bottom) {
            // floatingBar 放在 overlay 里，展开时高度变化不会触发安全区域重算
            floatingBar
                .padding(.horizontal, 20)
                .ignoresSafeArea(edges: .bottom)
                .offset(y: 12)
        }
        .background {
            Group { content }.hidden()
        }
        .onPreferenceChange(FloatingTabItemPreferenceKey.self) { items in
            self.tabs = items
        }
    }
    
    private var floatingBar: some View {
        HStack(alignment: .bottom, spacing: 12) {
            // Morph Glass 容器：MorphGlassView 管理 label ↔ content 过渡
            tabBarMorphView
            
            // Trailing button
            if let trailingIcon = trailingIcon, trailingMenu != nil {
                Button{
                    withAnimation(.bouncy(duration: 0.5, extraBounce: 0.05)) {
                        isExpanded.toggle()
                    }
                } label: {
                    ZStack {
                        trailingIcon
                            .foregroundStyle(.white)
                            .rotationEffect(.degrees(isExpanded ? 90 : 0))
                            .opacity(isExpanded ? 0 : 1)
                            .scaleEffect(isExpanded ? 0.6 : 1.0)
                        
                        (trailingIconHighlight ?? Image(systemName: "xmark"))
                            .font(.system(size: 22, weight: .semibold))
                            .foregroundStyle(Color(.label))
                            .rotationEffect(.degrees(isExpanded ? 0 : -90))
                            .opacity(isExpanded ? 1 : 0)
                            .scaleEffect(isExpanded ? 1.0 : 0.6)
                    }
                    .frame(width: barHeight, height: barHeight)
                    .background {
                        Circle()
                            .fill(isExpanded ? Color(.systemGray5) : themeColor)
                            .shadow(color: .gray.opacity(0.4), radius: 3)
                    }
                }
                .buttonStyle(.plain)
            }
        }
    }
    
    // MARK: - Morph Glass Tab Bar
    @ViewBuilder
    private var tabBarMorphView: some View {
        ZStack {
            if let capsuleWidth {
                let progress: CGFloat = isExpanded ? 1 : 0
                let labelSize = CGSize(width: capsuleWidth, height: barHeight)
                let cornerRadius = barHeight / 2
                
                MorphGlassView(
                    alignment: .center,
                    progress: progress,
                    labelSize: labelSize,
                    cornerRadius: cornerRadius
                ) {
                    // Content: 展开后的 menu
                    if let trailingMenu = trailingMenu {
                        trailingMenu {
                            withAnimation(.bouncy(duration: 0.5, extraBounce: 0.05)) {
                                isExpanded = false
                            }
                        }
                    }
                } label: {
                    // Label: 折叠态的 tab 按钮
                    HStack(spacing: 2) {
                        ForEach(tabs) { tab in
                            tabButton(tab)
                        }
                    }
                    .padding(.vertical, 6)
                    .frame(maxWidth: .infinity)
                }
            }
        }
        .frame(maxWidth: .infinity)
//        .background(.white)
        .clipShape(RoundedRectangle(cornerRadius: isExpanded ? 24 : 40, style: .continuous))
        .shadow(color: .gray.opacity(0.4), radius: 3)
        .onGeometryChange(for: CGFloat.self) { proxy in
            proxy.size.width
        } action: { newValue in
            capsuleWidth = newValue
        }
        .frame(height: capsuleWidth == nil ? barHeight : nil)
    }
    
    private func tabButton(_ tab: TabItemData) -> some View {
        let isSelected = AnyHashable(selection) == tab.id
        
        return Button {
            if let tag = tab.id as? SelectionValue {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    selection = tag
                }
            }
        } label: {
            HStack(spacing: 8) {

                tab.icon
                
                if isSelected && !tab.title.isEmpty {
                    Text(tab.title)
                        .lineLimit(1)
                        .fixedSize(horizontal: true, vertical: false) // 强制横向不压缩
                }
            }
            .font(.subheadline.bold())
            .foregroundStyle(isSelected ? .white : .gray)
            .padding(.vertical, 12)
            .padding(.horizontal, isSelected ? 18: 30)
            .background {
                if isSelected {
                    Capsule()
                        .fill(themeColor)
                        .matchedGeometryEffect(id: "tab_bg", in: animation)
                }
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

public extension FloatingTabView {
    func trailingButton<MenuView: View>(
        icon: Image,
        iconHighlight: Image? = nil,
        @ViewBuilder menu: @escaping () -> MenuView
    ) -> FloatingTabView {
        var copy = self
        copy.trailingIcon = icon
        copy.trailingIconHighlight = iconHighlight
        copy.trailingMenu = { _ in AnyView(menu()) }
        return copy
    }
    
    func trailingButton<MenuView: View>(
        icon: Image,
        iconHighlight: Image? = nil,
        @ViewBuilder menu: @escaping (@escaping () -> Void) -> MenuView
    ) -> FloatingTabView {
        var copy = self
        copy.trailingIcon = icon
        copy.trailingIconHighlight = iconHighlight
        copy.trailingMenu = { action in AnyView(menu(action)) }
        return copy
    }
    
    func trailingButton<T: TabItemProtocol, MenuView: View>(
        _ item: T,
        @ViewBuilder menu: @escaping () -> MenuView
    ) -> FloatingTabView {
        var copy = self
        copy.trailingIcon = item.icon
        copy.trailingIconHighlight = item.iconHighlight
        copy.trailingMenu = { _ in AnyView(menu()) }
        return copy
    }
    
    func trailingButton<T: TabItemProtocol, MenuView: View>(
        _ item: T,
        @ViewBuilder menu: @escaping (@escaping () -> Void) -> MenuView
    ) -> FloatingTabView {
        var copy = self
        copy.trailingIcon = item.icon
        copy.trailingIconHighlight = item.iconHighlight
        copy.trailingMenu = { action in AnyView(menu(action)) }
        return copy
    }
    
    func themeColor(_ color: Color) -> FloatingTabView {
        var copy = self
        copy.themeColor = color
        return copy
    }
    
    func isExpanded(_ binding: Binding<Bool>) -> FloatingTabView {
        var copy = self
        copy.isExpandedBinding = binding
        return copy
    }
}
    
#Preview {
    
    @Previewable @State var selectedTab: TabBarItem = .home
    
    FloatingTabView(selection: $selectedTab) {
        Color.green
            .floatingTabItem(TabBarItem.home)
        
        Color.blue
            .floatingTabItem(TabBarItem.remind)
        
        Color.orange
            .floatingTabItem(TabBarItem.profile)
        
    }
    .trailingButton(TabBarItem.add) { dismiss in
        VStack {
            Text("Expanded Menu View")
                .font(.title)
                .padding()
            Spacer()
        }
        .onTapGesture {
            //关闭菜单
            dismiss()
        }
        .frame(maxWidth: .infinity)
        .frame(height: 400)
        .background(Color(.orange))
        .cornerRadius(20)
        .shadow(radius: 10)
    }
    .themeColor(.orange)
}

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
    private var trailingAction: (() -> Void)?
    @Namespace private var animation
    @State private var bottomInsets: CGFloat = 0
    
    public init(
        selection: Binding<SelectionValue>,
        trailingIcon: Image? = nil,
        trailingAction: (() -> Void)? = nil,
        @ViewBuilder content: () -> Content
    ) {
        self._selection = selection
        self.trailingIcon = trailingIcon
        self.trailingAction = trailingAction
        self.content = content()
    }
    
    public var body: some View {
        
        TabView(selection: $selection) {
            content
        }
        .safeAreaInset(edge: .bottom) {
            floatingBar
                .ignoresSafeArea()
                .padding(.horizontal, 20)
                .padding(.bottom, -bottomInsets + 20)
                .onGeometryChange(for: CGFloat.self) { proxy in
                    proxy.safeAreaInsets.bottom
                } action: { value in
                    guard bottomInsets != value else { return }
                    bottomInsets = value
                }
        }
        .background {
            Group { content }.hidden()
        }
        .onPreferenceChange(FloatingTabItemPreferenceKey.self) { items in
            self.tabs = items
        }
    }
    
    private var floatingBar: some View {
        HStack(spacing: 12) {
            HStack(spacing: 0) {
                ForEach(tabs) { tab in
                    Spacer().frame(width: 6)
                    tabButton(tab)
                    Spacer().frame(width: 6)
                }
            }
            .padding(.vertical, 6)
            .background(.white)
            .clipShape(Capsule())
            .shadow(color: .gray.opacity(0.4), radius: 3)
            
            if let trailingIcon = trailingIcon, let trailingAction = trailingAction {
                Button(action: trailingAction) {
                    trailingIcon
                        .foregroundStyle(.white)
                        .frame(width: 55, height: 55)
                        .background{
                            Circle()
                                .fill(themeColor)
                                .shadow(color: .gray, radius: 3)
                        }
                }
            }
        }
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
                }
            }
            .font(.subheadline.bold())
            .foregroundStyle(isSelected ? .white : .gray)
            .padding(.vertical, 12)
            .padding(.horizontal, isSelected ? 18 : 12)
            .fixedSize(horizontal: true, vertical: false)
            .background {
                if isSelected {
                    Capsule()
                        .fill(themeColor)
                        .matchedGeometryEffect(id: "tab_bg", in: animation)
                }
            }
        }
        .buttonStyle(.plain)
    }
}

public extension FloatingTabView {
    func trailingButton(icon: Image,
                        action: @escaping () -> Void) -> FloatingTabView {
        var copy = self
        copy.trailingIcon = icon
        copy.trailingAction = action
        return copy
    }
    
    func trailingButton<T: TabItemProtocol>(_ item: T, action: @escaping () -> Void) -> FloatingTabView {
        var copy = self
        copy.trailingIcon = item.icon
        copy.trailingAction = action
        return copy
    }
    
    func themeColor(_ color: Color) -> FloatingTabView {
        var copy = self
        copy.themeColor = color
        return copy
    }
}

#Preview {
    
    @Previewable @State var selectedTab: TabBarItem = .home
    @Previewable @State var isPresented: Bool = false
    
    FloatingTabView(selection: $selectedTab) {
        Color.green
            .floatingTabItem(TabBarItem.home)
        
        Color.blue
            .floatingTabItem(TabBarItem.remind)
        
        Color.orange
            .floatingTabItem(TabBarItem.profile)
        
    }
    .trailingButton(TabBarItem.add) {
        isPresented.toggle()
    }
    .themeColor(.orange)
    .sheet(isPresented: $isPresented) {
        Text("Profile Sheet")
    }
}

//
//  ContentView.swift
//  TabTab
//
//  Created by HU on 5/25/26.
//

import SwiftUI

#Preview {
    VStack{
        Spacer()
        
        ContentView()
    }
}

// MARK: - 数据模型
struct QuickAddItem: Identifiable {
    let id = UUID()
    let title: String
    let icon: String
    let color: Color
}

// MARK: - 主视图
struct ContentView: View {
    @State private var selectedTab: Int = 0
    @State private var showQuickAdd: Bool = false

    var body: some View {
        FloatingTabView(selection: $selectedTab) {
            HomeView()
                .floatingTabItem(
                    title: "首页",
                    icon: Image(systemName: "house"),
                    iconHighlight: Image(systemName: "house.fill"),
                    tag: 0
                )
            
            VStack {
                Image(systemName: "chart.bar.fill")
                    .font(.system(size: 40))
                    .foregroundStyle(.pink.gradient)
                    .padding(.bottom, 8)
                Text("统计")
                    .font(.title2.bold())
                    .foregroundStyle(.primary)
                Text("在这里查看您的统计报告")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color(.systemGroupedBackground))
            .floatingTabItem(
                title: "统计",
                icon: Image(systemName: "chart.bar"),
                iconHighlight: Image(systemName: "chart.bar.fill"),
                tag: 1
            )
            
            VStack {
                Image(systemName: "square.grid.2x2.fill")
                    .font(.system(size: 40))
                    .foregroundStyle(.pink.gradient)
                    .padding(.bottom, 8)
                Text("更多")
                    .font(.title2.bold())
                    .foregroundStyle(.primary)
                Text("探索更多个性化配置")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color(.systemGroupedBackground))
            .floatingTabItem(
                title: "更多",
                icon: Image(systemName: "square.grid.2x2"),
                iconHighlight: Image(systemName: "square.grid.2x2.fill"),
                tag: 2
            )
        }
        .isExpanded($showQuickAdd)
        .trailingButton(icon: Image(systemName: "plus")) { dismiss in
            QuickAddOverlay(isPresented: $showQuickAdd, dismissAction: dismiss)
        }
        .themeColor(.pink)
    }
}

// MARK: - 快速记录覆盖层
struct QuickAddOverlay: View {
    @Binding var isPresented: Bool
    var dismissAction: (() -> Void)? = nil

    private let items: [QuickAddItem] = [
        QuickAddItem(title: "亲喂", icon: "figure.and.child.holdinghands", color: .pink),
        QuickAddItem(title: "睡眠", icon: "moon.fill", color: .indigo),
        QuickAddItem(title: "瓶喂", icon: "drop.fill", color: .orange),
        QuickAddItem(title: "泵奶", icon: "waveform.path.ecg", color: .brown),
        QuickAddItem(title: "换尿布", icon: "heart.fill", color: .green),
        QuickAddItem(title: "洗澡", icon: "shower.fill", color: .blue),
        QuickAddItem(title: "生长", icon: "ruler.fill", color: .teal),
        QuickAddItem(title: "妈妈体重", icon: "scalemass.fill", color: .pink),
        QuickAddItem(title: "宝宝营养品", icon: "capsule.fill", color: .mint),
        QuickAddItem(title: "疫苗", icon: "syringe.fill", color: .purple),
        QuickAddItem(title: "体温", icon: "thermometer.medium", color: .red),
    ]

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 12), count: 3)

    var body: some View {
        VStack(spacing: 0) {

                LazyVGrid(columns: columns, spacing: 16) {
                    ForEach(Array(items.enumerated()), id: \.element.id) { index, item in
                        QuickAddCell(item: item) {
                            if let dismissAction = dismissAction {
                                dismissAction()
                            } else {
                                withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                                    isPresented = false
                                }
                            }
                        }
                        .transition(
                            .asymmetric(
                                insertion: .scale(scale: 0.7).combined(with: .opacity)
                                    .animation(.spring(response: 0.4, dampingFraction: 0.7).delay(Double(index) * 0.1)),
                                removal: .opacity.animation(.easeOut(duration: 0.15))
                            )
                        )
                    }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 20)
 
        }
    }
}

// MARK: - 单个快速记录格子
struct QuickAddCell: View {
    let item: QuickAddItem
    let action: () -> Void

    @State private var isPressed = false

    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                ZStack {
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(item.color.opacity(0.12))
                        .frame(width: 56, height: 56)

                    Image(systemName: item.icon)
                        .font(.system(size: 24))
                        .foregroundStyle(item.color)
                }

                Text(item.title)
                    .font(.caption)
                    .foregroundStyle(.primary)
                    .lineLimit(1)
            }
        }
        .buttonStyle(.plain)
        .scaleEffect(isPressed ? 0.92 : 1.0)
        .onLongPressGesture(
            minimumDuration: 0,
            pressing: { pressing in
                withAnimation(.easeInOut(duration: 0.1)) { isPressed = pressing }
            },
            perform: {}
        )
    }
}

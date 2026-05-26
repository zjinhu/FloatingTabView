//
//  TabBarItem.swift
//  PawLog
//
//  Created by HU on 4/16/26.
//

import SwiftUI

public protocol TabItemProtocol: Hashable {
    var title: String { get }
    var icon: Image { get }
    var iconHighlight: Image { get }
}

enum TabBarItem: Int, CaseIterable, TabItemProtocol {
    case home
    case profile
    case remind
    case add

    var icon: Image {
        switch self {
        case .home: return Image(.tabHomeNor).renderingMode(.template)
        case .remind: return Image(.tabReminderNor).renderingMode(.template)
        case .add: return Image(systemName: "plus")
        case .profile: return Image(.tabProfileNor).renderingMode(.template)
        }
    }
    
    var iconHighlight: Image {
        switch self {
        case .home: return Image(.tabHomeSel).renderingMode(.template)
        case .remind: return Image(.tabReminderSel).renderingMode(.template)
        case .add: return Image(systemName: "xmark")
        case .profile: return Image(.tabProfileSel).renderingMode(.template)
        }
    }
    
    var title: String {
        switch self {
        case .home: return "Home"
        case .remind: return "Reminder"
        case .add: return "Add"
        case .profile: return "Profile"
        }
    }
}

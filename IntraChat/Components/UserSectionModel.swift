//
//  UserSectionModel.swift
//  IntraChat
//
//  Created by Robyarta Haruli Ruci on 23/01/18.
//  Copyright © 2018 Personal. All rights reserved.
//

import UIKit
import RxDataSources

enum MultipleSectionModel {
    case UserSection(title: String, items: [SectionItem])
}

enum SectionItem {
    case UserSectionItem(user: User)
}

extension MultipleSectionModel: SectionModelType {
    typealias Item = SectionItem
    
    var items: [SectionItem] {
        switch  self {
        case .UserSection(title: _, items: let items):
            return items.map{$0}
        }
    }
    
    init(original: MultipleSectionModel, items: [Item]) {
        switch original {
        case .UserSection(title: let title, items: _):
            self = .UserSection(title: title, items: items)
        }
    }
}

extension MultipleSectionModel {
    var title: String {
        switch self {
        case .UserSection(title: let title, items: _):
            return title
        }
    }
}

protocol ReusableView: class {
    static var reuseIdentifier: String {get}
}

extension ReusableView {
    static var reuseIdentifier: String {
        return String(describing: self)
    }
}

extension UITableViewCell: ReusableView {
}

extension UITableView {
    
    func dequeueReusableCell<T: UITableViewCell>(forIndexPath indexPath: IndexPath) -> T {
        guard let cell = dequeueReusableCell(withIdentifier: T.reuseIdentifier, for: indexPath) as? T else {
            fatalError("Could not dequeue cell with identifier: \(T.reuseIdentifier)")
        }
        
        return cell
    }
}

public extension Sequence {
    func categorise<U : Hashable>(_ key: (Iterator.Element) -> U) -> [U:[Iterator.Element]] {
        var dict: [U:[Iterator.Element]] = [:]
        for el in self {
            let key = key(el)
            if case nil = dict[key]?.append(el) { dict[key] = [el] }
        }
        return dict
    }
}

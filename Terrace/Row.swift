//
//  Row.swift
//  Terrace
//
//  Created by Jesse Hao on 2019/2/21.
//  Copyright © 2019 Snoware. All rights reserved.
//

import Foundation

public protocol FormRowCellProtocol {
	static var defaultHeight:CGFloat { get }
	static var defaultEstimatedHeight:CGFloat { get }
}

extension FormRowCellProtocol {
	static var defaultHeight:CGFloat { return UITableView.automaticDimension }
	static var defaultEstimatedHeight:CGFloat { return 44 }
}

extension Form {
	open class Row : NSObject {
		open var isValid:Bool { return self.cell != nil || self.isDynamic }
		open var canSelect:Bool = true { didSet { self.cell?.selectionStyle = self.canSelect ? .default : .none } }
		open var canDelete:Bool = false
		open var height:CGFloat = UITableView.automaticDimension
		open var estimatedHeight:CGFloat = 48
		// Static
		open private(set) var cell:UITableViewCell?
		open var onSelectRowEventHandler:(() -> Void)?
		// Dynamic
		/// The type for dynamic cell which inherits from `UITableViewCell`
		open private(set) var cellType:AnyClass?
		/// The reuse identifier for dynamic cell.
		open private(set) var reuseIdentifier:String?
		
		/// count 1 represent the single static cell or there is only one dynamic cell.
		open var dynamicRowCount:Int = 1
	}
}

// MARK: - Static Row
public extension Form.Row {
	convenience init(withCell cell:UITableViewCell) {
		self.init()
		self.cell = cell
		if let standardType = type(of: cell) as? FormRowCellProtocol.Type {
			self.height = standardType.defaultHeight
			self.estimatedHeight = standardType.defaultEstimatedHeight
		}
	}
	
	@discardableResult
	func onSelect(_ handler:@escaping () -> Void) -> Form.Row {
		self.onSelectRowEventHandler = handler
		return self
	}
}

// MARK: - Dynamic Row
public extension Form.Row {
	var isDynamic:Bool { return self.cellType != nil && self.reuseIdentifier != nil }
	convenience init(withCellType type:AnyClass, reuseIdentifier identifier:String) {
		self.init()
		self.cellType = type
		self.reuseIdentifier = identifier
	}
}

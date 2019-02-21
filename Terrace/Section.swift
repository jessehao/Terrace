//
//  Section.swift
//  Terrace
//
//  Created by Jesse Hao on 2019/2/21.
//  Copyright © 2019 Snoware. All rights reserved.
//

import Foundation

extension Form {
	open class Section : NSObject, ExpressibleByArrayLiteral {
		open weak var form:Form?
		open private(set) var rows:[Row] = []
		open var header:String?
		open var footer:String?
		open var headerView:UITableViewHeaderFooterView?
		open var footerView:UITableViewHeaderFooterView?
		// Expressible By Array Literal
		public typealias ArrayLiteralElement = Form.Row
		public required init(arrayLiteral elements: Form.Row...) {
			self.rows = elements
		}
		open func reloadData() {
			guard let form = self.form else { return }
			guard let index = form.firstIndex(of: self) else {
				form.delegate?.needsToReloadData(for: form)
				return
			}
			form.delegate?.form(form, sectionsUpdatedAt: [index])
		}
	}
}

// MARK: - Helper
public extension Form.Section {
	var appendingIndex:Int { return self.endIndex - 1 }
	
	convenience init(forForm form:Form) {
		self.init()
		self.form = form
	}
	
	func allDynamicRows() -> [Form.Row] {
		return self.filter { $0.isDynamic }
	}
	
	func formRowIndexWithRelativeOffset(forTableViewRowIndex index:Int) -> (index:Int, offset:Int) {
		var retval = 0
		var i = 0
		var offset = 0
		while i <= index {
			let row = self[retval]
			i += row.isDynamic ? row.dynamicRowCount : 1
			offset = row.isDynamic ? row.dynamicRowCount - (i - index) : 0
			retval += 1
		}
		return (retval - 1, offset)
	}
	
	func tableViewRowIndex(forFormRowIndex index:Int) -> Int {
		let tableViewIndex = self[self.startIndex..<index].reduce(0) { $0 + ($1.isDynamic ? $1.dynamicRowCount : 1) }
		return tableViewIndex
	}
	
	func insertCell(forDynamicRowIdentifier identifier:String, at index:Int) {
		guard let form = self.form, let sectionIndex = form.index(of: self) else { return }
		guard let formIndex = self.index(where: { $0.reuseIdentifier == identifier }) else { return }
		let rowIndex = self.tableViewRowIndex(forFormRowIndex: formIndex) + index
		form.delegate?.form(form, rowsAddedAt: [[sectionIndex, rowIndex]])
	}
	
	func appendCell(forDynamicRowIdentifier identifier:String) {
		guard let form = self.form, let sectionIndex = form.index(of: self) else { return }
		guard let formIndex = self.index(where: { $0.reuseIdentifier == identifier }) else { return }
		let count = self[formIndex].dynamicRowCount
		let rowIndex = self.tableViewRowIndex(forFormRowIndex: formIndex) + count
		form.delegate?.form(form, rowsAddedAt: [[sectionIndex, rowIndex]])
	}
	
	private func indexPaths(ForSection section:Int, rowPosition:Int, rowCount:Int) -> [IndexPath] {
		let rowTail = rowPosition + rowCount - 1
		return (rowPosition...rowTail).map { IndexPath(row: $0, section: section) }
	}
	
	private func rowForIndexPath(fromPosition position:Int) -> Int {
		return self.rows[self.startIndex...(position - 1)].reduce(0) { $0 + ($1.isDynamic ? $1.dynamicRowCount : 1) }
	}
}

extension Form.Section : Collection {
	public typealias Element = Form.Row
	public typealias Index = Int
	public var startIndex: Int { return self.rows.startIndex }
	public var endIndex: Int { return self.rows.endIndex }
	public func index(after i: Int) -> Int { return self.rows.index(after: i) }
	
}

extension Form.Section : MutableCollection {
	public subscript(position: Int) -> Form.Row {
		get { return self.rows[position] }
		set {
			self.rows[position] = newValue
			guard let form = self.form, let section = form.index(of: self) else { return }
			if self.rows[position].isDynamic || newValue.isDynamic {
				form.delegate?.form(form, sectionsUpdatedAt: [section])
			} else {
				form.delegate?.form(form, rowsUpdatedAt: [[section, position]])
			}
		}
	}
}

public extension Form.Section {
	func insert(_ newElement: Form.Row, at i: Int) {
		self.rows.insert(newElement, at: i)
		guard let form = self.form, let section = form.index(of: self) else { return }
		form.registerRowIfNeeded([newElement])
		if newElement.isDynamic {
			form.delegate?.form(form, sectionsUpdatedAt: [section])
		} else {
			let row = self.rowForIndexPath(fromPosition: i)
			form.delegate?.form(form, rowsAddedAt: [[section, row]])
		}
	}
	
	func insert<C>(contentsOf newElements: C, at i: Int) where C : Collection, Form.Section.Element == C.Element {
		self.rows.insert(contentsOf: newElements, at: i)
		guard let form = self.form, let section = form.index(of: self) else { return }
		form.registerRowIfNeeded(newElements)
		if newElements.contains(where: { $0.isDynamic }) {
			form.delegate?.form(form, sectionsUpdatedAt: [section])
		} else {
			let row = self.rowForIndexPath(fromPosition: i)
			form.delegate?.form(form, rowsAddedAt: self.indexPaths(ForSection: section, rowPosition: row, rowCount: newElements.count))
		}
	}
	
	func append(_ newElement: Form.Row) {
		self.rows.append(newElement)
		guard let form = self.form, let section = form.index(of: self) else { return }
		form.registerRowIfNeeded([newElement])
		if newElement.isDynamic {
			form.delegate?.form(form, sectionsUpdatedAt: [section])
		} else {
			let row = self.rowForIndexPath(fromPosition: self.appendingIndex)
			form.delegate?.form(form, rowsAddedAt: [[section, row]])
		}
	}
	
	func append<S>(contentsOf newElements: S) where S : Sequence, Form.Section.Element == S.Element {
		self.rows.append(contentsOf: newElements)
		guard let form = self.form, let section = form.index(of: self) else { return }
		form.registerRowIfNeeded(newElements)
		if newElements.contains(where: { $0.isDynamic }) {
			form.delegate?.form(form, sectionsUpdatedAt: [section])
		} else {
			let row = self.rowForIndexPath(fromPosition: self.appendingIndex)
			form.delegate?.form(form, rowsAddedAt: self.indexPaths(ForSection: section, rowPosition: row, rowCount: newElements.underestimatedCount))
		}
	}
	
	func replaceSubrange<C, R>(_ subrange: R, with newElements: C) where C : Collection, R : RangeExpression, Form.Section.Element == C.Element, Form.Section.Index == R.Bound {
		self.rows.replaceSubrange(subrange, with: newElements)
		guard let form = self.form, let section = form.index(of: self) else { return }
		form.registerRowIfNeeded(newElements)
		let range = subrange.relative(to: self.rows)
		if self.rows.contains(where: { $0.isDynamic }) || newElements.contains(where: { $0.isDynamic }) {
			form.delegate?.form(form, sectionsUpdatedAt: [section])
		} else {
			form.delegate?.form(form, rowsUpdatedAt: (range.lowerBound...range.upperBound).map { IndexPath(row: $0, section: section) })
		}
	}
	
	@discardableResult func remove(at position: Int) -> Form.Row {
		let row = self.rows.remove(at: position)
		if let form = self.form, let section = form.index(of: self) {
			if row.isDynamic {
				form.delegate?.form(form, rowsRemovedAt: self.indexPaths(ForSection: section, rowPosition: position, rowCount: row.dynamicRowCount))
			} else {
				form.delegate?.form(form, rowsRemovedAt: [[section, position]])
			}
		}
		return row
	}
	
	func removeSubrange(_ bounds: Range<Int>) {
		self.rows.removeSubrange(bounds)
		guard let form = self.form, let section = form.index(of: self) else { return }
		form.delegate?.form(form, rowsRemovedAt: (bounds.lowerBound..<bounds.upperBound).map { IndexPath(row: $0, section: section) })
	}
	
	func removeAll() {
		self.rows.removeAll()
		guard let form = self.form, let section = form.index(of: self) else { return }
		form.delegate?.form(form, sectionsUpdatedAt: [section])
	}
	
	@discardableResult func removeLast() -> Form.Row {
		return self.remove(at: self.count - 1)
	}
}

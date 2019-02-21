//
//  Form.swift
//  Terrace
//
//  Created by Jesse Hao on 2019/2/21.
//  Copyright © 2019 Snoware. All rights reserved.
//

import Foundation

public protocol FormDelegate : class {
	func form(_ form:Form, sectionsAddedAt indexes:IndexSet)
	func form(_ form:Form, sectionsRemovedAt indexes:IndexSet)
	func form(_ form:Form, sectionsUpdatedAt indexes:IndexSet)
	func form(_ form:Form, rowsAddedAt indexPaths:[IndexPath])
	func form(_ form:Form, rowsRemovedAt indexPaths:[IndexPath])
	func form(_ form:Form, rowsUpdatedAt indexPaths:[IndexPath])
	func needsToReloadData(for form:Form)
	func form(_ form:Form, dynamicRowsNeedsToRegister:Form.Row)
}

open class Form : NSObject {
	open weak var delegate:FormDelegate?
	
	private var sections:[Section] = []
	
	// MARK: - Lifecycle
	required override public init() {
		super.init()
		self.setup()
	}
	
	// MARK: - Operations
	open func setup() {
		self.sections = self.initialSections()
		self.prepareTargets()
	}
	
	open func prepareTargets() {}
	
	open func initialSections() -> [Section] {
		var retval:[Section] = []
		if let section = self.defaultSection() {
			retval.append(section)
		}
		return retval
	}
	open func defaultSection() -> Section? { return nil }
}

// MARK: - Helper
public extension Form {
	subscript(indexPath:IndexPath) -> (row:Row, offset:Int) {
		let section = self[indexPath.section]
		let rowIndexWithOffset = section.formRowIndexWithRelativeOffset(forTableViewRowIndex: indexPath.row)
		return (section[rowIndexWithOffset.index], rowIndexWithOffset.offset)
	}
	
	func allDynamicRows() -> [Row] {
		var retval:[Row] = []
		self.forEach { retval.append(contentsOf: $0.allDynamicRows()) }
		return retval
	}
	
	func registerRowIfNeeded<S>(_ row:S) where S : Sequence, S.Element : Row {
		row.filter { $0.isDynamic }.forEach {
			self.delegate?.form(self, dynamicRowsNeedsToRegister: $0)
		}
	}
}

// MARK: - All Row Iterator
public extension Form {
	struct AllRowIterator: IteratorProtocol {
		public typealias Element = Row
		public weak var form:Form? {
			didSet {
				self.sectionIterator = self.form?.makeIterator()
			}
		}
		private var currentSection:Int = 0
		private var currentRow:Int = 0
		private var sectionIterator:IndexingIterator<Form>?
		private var rowIterator:IndexingIterator<Section>?
		public mutating func next() -> Form.Row? {
			if let row = self.rowIterator?.next() { return row }
			if let section = self.sectionIterator?.next() {
				self.rowIterator = section.makeIterator()
				return self.next()
			}
			return nil
		}
	}
	
	func makeAllRowIterator() -> AllRowIterator {
		var retval = AllRowIterator()
		retval.form = self
		return retval
	}
}

extension Form : Collection {
	public typealias Element = Section
	public typealias Index = Int
	public var startIndex: Int { return self.sections.startIndex }
	public var endIndex: Int { return self.sections.endIndex }
	public func index(after i: Int) -> Int { return self.sections.index(after: i) }
}

extension Form : MutableCollection {
	public subscript(position: Int) -> Form.Section {
		get { return self.sections[position] }
		set {
			self.sections[position] = newValue
			self.delegate?.form(self, sectionsUpdatedAt: [position])
		}
	}
}

public extension Form {
	var appendingIndex:Int { return self.endIndex - 1 }
	
	func insert(_ newElement: Form.Section, at i: Int) {
		newElement.form = self
		self.sections.insert(newElement, at: i)
		self.registerRowIfNeeded(newElement.rows)
		self.delegate?.form(self, sectionsAddedAt: [i])
	}
	
	func insert<C>(contentsOf newElements: C, at i: Int) where C : Collection, Form.Element == C.Element {
		newElements.forEach {
			$0.form = self
			self.registerRowIfNeeded($0.rows)
		}
		self.sections.insert(contentsOf: newElements, at: i)
		self.delegate?.form(self, sectionsAddedAt: self.indexes(ForPosition: i, count: newElements.count))
	}
	
	func append(_ newElement: Form.Section) {
		newElement.form = self
		self.registerRowIfNeeded(newElement.rows)
		self.sections.append(newElement)
		self.delegate?.form(self, sectionsAddedAt: [self.appendingIndex])
	}
	
	func append<S>(contentsOf newElements: S) where S : Sequence, Form.Element == S.Element {
		newElements.forEach {
			$0.form = self
			self.registerRowIfNeeded($0.rows)
		}
		self.sections.append(contentsOf: newElements)
		self.delegate?.form(self, sectionsAddedAt: self.indexes(ForPosition: self.appendingIndex, count: newElements.underestimatedCount))
	}
	
	func replaceSubrange<C, R>(_ subrange: R, with newElements: C) where C : Collection, R : RangeExpression, Form.Element == C.Element, Form.Index == R.Bound {
		newElements.forEach {
			$0.form = self
			self.registerRowIfNeeded($0.rows)
		}
		self.sections[subrange].forEach { $0.form = nil }
		self.sections.replaceSubrange(subrange, with: newElements)
		let range = subrange.relative(to: self.sections)
		self.delegate?.form(self, sectionsUpdatedAt: IndexSet(range.lowerBound...range.upperBound))
	}
	
	@discardableResult func remove(at position: Int) -> Form.Section {
		defer { self.delegate?.form(self, sectionsRemovedAt: [position]) }
		let retval = self.sections.remove(at: position)
		retval.form = nil
		return retval
	}
	
	func removeSubrange(_ bounds: Range<Int>) {
		defer { self.delegate?.form(self, sectionsRemovedAt: IndexSet(bounds.lowerBound...bounds.upperBound - 1)) }
		self.sections[bounds].forEach { $0.form = nil }
		self.sections.removeSubrange(bounds)
	}
	
	func removeAll(keepingCapacity keepCapacity: Bool = false) {
		defer { self.delegate?.form(self, sectionsRemovedAt: IndexSet(self.startIndex...self.endIndex)) }
		self.sections.forEach { $0.form = nil }
		self.sections.removeAll()
	}
	
	private func indexes(ForPosition position:Int, count:Int) -> IndexSet {
		let tail = position + count - 1
		return IndexSet(position...tail)
	}
}

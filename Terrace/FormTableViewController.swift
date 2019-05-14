//
//  FormTableViewController.swift
//  Terrace
//
//  Created by Jesse Hao on 2019/2/21.
//  Copyright © 2019 Snoware. All rights reserved.
//

import Foundation

open class FormTableViewController<FormType:Form>: UITableViewController, FormDelegate {
	public let form:FormType = FormType()
	
	// MARK: - Lifecycle
	convenience init() {
		self.init(style: .grouped)
	}
	
	public override init(style: UITableView.Style) {
		super.init(style: style)
		self.initializing()
	}
	
	public override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
		super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
		self.initializing()
	}
	
	required public init?(coder aDecoder: NSCoder) {
		super.init(coder: aDecoder)
		self.initializing()
	}
	
	open func initializing() {
		self.clearsSelectionOnViewWillAppear = true
	}
	
	override open func viewDidLoad() {
		super.viewDidLoad()
		self.configuringTableView(self.tableView)
		self.configuringForm(self.form)
		self.registerDynamicRows()
	}
	
	// MARK: - Form Events
	open func configuringForm(_ form:FormType) {
		form.delegate = self
	}
	open func configuringDynamicCell(_ cell:UITableViewCell, withIdentifier identifier:String, at index:Int) {}
	open func numberOfRows(forDynamicCellReuseIdentifier identifier:String) -> Int { return 0 }
	open func didSelectDynamicRow(forIdentifier identifier:String, at index:Int) {}
	open func willDeleteDynamicCell(forIdentifier identifier:String, at index:Int) {}
	
	// MARK: - Form Delegate
	open func form(_ form: Form, sectionsAddedAt indexes: IndexSet) {
		self.tableView.beginUpdates()
		self.tableView.insertSections(indexes, with: .fade)
		self.tableView.endUpdates()
	}
	
	open func form(_ form: Form, sectionsRemovedAt indexes: IndexSet) {
		self.tableView.beginUpdates()
		self.tableView.deleteSections(indexes, with: .fade)
		self.tableView.endUpdates()
	}
	
	open func form(_ form: Form, sectionsUpdatedAt indexes: IndexSet) {
		self.tableView.beginUpdates()
		self.tableView.reloadSections(indexes, with: .automatic)
		self.tableView.endUpdates()
	}
	
	open func form(_ form: Form, rowsAddedAt indexPaths: [IndexPath]) {
		self.tableView.beginUpdates()
		self.tableView.insertRows(at: indexPaths, with: .middle)
		self.tableView.endUpdates()
	}
	
	open func form(_ form: Form, rowsRemovedAt indexPaths: [IndexPath]) {
		self.tableView.beginUpdates()
		self.tableView.deleteRows(at: indexPaths, with: .top)
		self.tableView.endUpdates()
	}
	
	open func form(_ form: Form, rowsUpdatedAt indexPaths: [IndexPath]) {
		self.tableView.beginUpdates()
		self.tableView.reloadRows(at: indexPaths, with: .automatic)
		self.tableView.endUpdates()
	}
	
	open func needsToReloadData(for form: Form) {
		self.tableView.reloadData()
	}
	
	open func form(_ form: Form, dynamicRowsNeedsToRegister: Form.Row) {
		guard let identifier = dynamicRowsNeedsToRegister.reuseIdentifier else { return }
		self.tableView.register(dynamicRowsNeedsToRegister.cellType, forCellReuseIdentifier: identifier)
	}
	
	// MARK: - UITableView Data Source
	override open func numberOfSections(in tableView: UITableView) -> Int {
		return self.form.count
	}
	
	override open func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		let sec = self.form[section]
		let retval = sec.reduce(0) { sum, row in
			row.dynamicRowCount = row.isDynamic ? self.numberOfRows(forDynamicCellReuseIdentifier: row.reuseIdentifier!) : 1
			return sum + row.dynamicRowCount
		}
		return retval
	}
	
	override open func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
		let rowWithOffset = self.form[indexPath]
		if rowWithOffset.row.isDynamic, let identifier = rowWithOffset.row.reuseIdentifier {
			let cell = tableView.dequeueReusableCell(withIdentifier: identifier, for: indexPath)
			self.configuringDynamicCell(cell, withIdentifier: identifier, at: rowWithOffset.offset)
			return cell
		}
		return rowWithOffset.row.cell!
	}
	
	// Title for Header/Footer
	override open func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
		let formSection = self.form[section]
		return formSection.headerView != nil ? nil : formSection.header
	}
	
	override open func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String? {
		let formSection = self.form[section]
		return formSection.footerView != nil ? nil : formSection.footer
	}
	
	// Inserting / Deleting
	override open func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
		return self.form[indexPath].row.canDelete
	}
	
	override open func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
		let rowWithOffset = self.form[indexPath]
		if rowWithOffset.row.canDelete {
			if rowWithOffset.row.isDynamic {
				self.willDeleteDynamicCell(forIdentifier: rowWithOffset.row.reuseIdentifier!, at: rowWithOffset.offset)
				tableView.deleteRows(at: [indexPath], with: .top)
			} else {
				let formRowIndex = self.form[indexPath.section].formRowIndexWithRelativeOffset(forTableViewRowIndex: indexPath.row).index
				tableView.deleteRows(at: [[indexPath.section, formRowIndex]], with: .top)
			}
		}
	}
	
	// MARK: - UITableView Delegate
	override open func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
		return self.form[indexPath].row.height
	}
	
	override open func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
		return self.form[indexPath].row.estimatedHeight
	}
	
	// Selections
	override open func tableView(_ tableView: UITableView, willSelectRowAt indexPath: IndexPath) -> IndexPath? {
		let rowWithOffset = self.form[indexPath]
		if rowWithOffset.row.canSelect {
			return indexPath
		}
		return nil
	}
	
	override open func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
		let rowWithOffset = self.form[indexPath]
		if rowWithOffset.row.isDynamic {
			self.didSelectDynamicRow(forIdentifier: rowWithOffset.row.reuseIdentifier!, at: rowWithOffset.offset)
		} else {
			rowWithOffset.row.onSelectRowEventHandler?()
		}
	}
	
	// Header / Footer
	override open func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
		return self.form[section].headerView
	}
	
	override open func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
		return self.form[section].footerView
	}
	
	override open func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
		return UITableView.automaticDimension
	}
	
	override open func tableView(_ tableView: UITableView, estimatedHeightForHeaderInSection section: Int) -> CGFloat {
		return 10
	}
	
	// Editing
	override open func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCell.EditingStyle {
		if self.form[indexPath].row.canDelete { return .delete }
		return .none
	}
	
	// MARK: - Operations
	open func configuringTableView(_ tableView: UITableView) {
		tableView.keyboardDismissMode = .onDrag
	}
	
	open func registerDynamicRows() {
		self.form.allDynamicRows().forEach {
			guard let identifier = $0.reuseIdentifier else { return }
			self.tableView.register($0.cellType, forCellReuseIdentifier: identifier)
		}
	}
}

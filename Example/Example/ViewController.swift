//
//  ViewController.swift
//  Example
//
//  Created by Jesse Hao on 2019/2/21.
//  Copyright © 2019 Snoware. All rights reserved.
//

import Terrace
import Zench
import SnapKit

class TextCell : StandardTableViewCell, FormRowCellProtocol {
	let textView = UITextView()
	
	override func prepareSubviews() {
		super.prepareSubviews()
		self.contentView.addSubview(self.textView)
	}
	
	override func makeConstraints() {
		super.makeConstraints()
		self.textView.snp.makeConstraints { make in
			make.edges.equalToSuperview()
		}
	}
	
	override class var defaultHeight:CGFloat { return 100 }
}

class RootForm : Form {
	override func initialSections() -> [Form.Section] {
		var retval = super.initialSections()
		retval.append(Section(rows: RootForm.staticNumberRows()))
		retval.append(Section(arrayLiteral: Row(withCell: TextCell())))
		return retval
	}
	
	override func defaultSection() -> Form.Section? {
		return [
			Row(withCell: RootForm.staticRow(title: "First", content: "first detail")),
			Row(withCell: RootForm.staticRow(title: "Section", content: "second detail"))
		]
	}
	
	static func staticNumberRows() -> [Row] {
		var retval:[Row] = []
		(0...10).forEach {
			retval.append(Row(withCell: staticRow(title: $0.string, content: "details")))
		}
		return retval
	}
	
	static func staticRow(title:String, content:String) -> UITableViewCell {
		let retval = UITableViewCell()
		retval.textLabel?.text = title
		retval.detailTextLabel?.text = content
		retval.accessoryType = .disclosureIndicator
		return retval
	}
}

class ViewController: FormTableViewController<RootForm> {}


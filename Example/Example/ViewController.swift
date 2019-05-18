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
		retval.append(Section(arrayLiteral: Row(withCell: TextCell()), Row(withCell: TextCell())))
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

class CollapsingForm : Form {
	let row1 = Row(withCell: .newWithConfiguration {
		$0.textLabel?.text = "Press me"
		})
	let row2 = Row(withCell: .newWithConfiguration {
		$0.textLabel?.text = "Press me too"
		})
	let row3 = Row(withCell: .newWithConfiguration {
		$0.textLabel?.text = "show me"
		})
	let row4 = Row(withCell: .newWithConfiguration {
		$0.textLabel?.text = "show me too"
		})
	
	var indexOfRow1:Int { return 0 }
	var indexOfRow2:Int { return self.hasRow3Shows ? 2 : 1 }
	var hasRow3Shows:Bool = false {
		didSet {
			guard self.hasRow3Shows != oldValue else { return }
			if self.hasRow3Shows {
				self.first?.insert(self.row3, at: self.indexOfRow1 + 1)
				self.hasRow4Shows = false
			} else {
				self.first?.remove(at: self.indexOfRow1 + 1)
			}
		}
	}
	var hasRow4Shows:Bool = false {
		didSet {
			guard self.hasRow4Shows != oldValue else { return }
			if self.hasRow4Shows {
				self.first?.insert(self.row4, at: self.indexOfRow2 + 1)
				self.hasRow3Shows = false
			} else {
				self.first?.remove(at: self.indexOfRow2 + 1)
			}
		}
	}
	
	override func defaultSection() -> Form.Section? {
		return [row1, row2]
	}
	
	override func setup() {
		super.setup()
		row1.onSelect { [weak self] in
			guard let self = self else { return }
			self.hasRow3Shows.negate()
		}
		row2.onSelect { [weak self] in
			guard let self = self else { return }
			self.hasRow4Shows.negate()
		}
	}
}

class ViewController: FormTableViewController<CollapsingForm> {}


//
//  DemoViewController.swift
//  UIKitDemo
//
//  Created by Steven Harris on 3/9/21.
//  Copyright © 2021 Steven Harris. All rights reserved.
//

import UIKit
import SwiftUI
import Combine
// 布局建议修改为Storyboard、Xib、Snapkit等
class DemoViewController: UIViewController {
    var stack: UIStackView!
    private var rawTextView: UITextView!
    private var bottomStack: UIStackView!
    private var bottomStackHeightConstraint: NSLayoutConstraint!
    var selectedWebView: MarkupWKWebView? { MarkupEditor.selectedWebView }
    var selectImageCancellable: AnyCancellable?

    var backBtn = UIButton()
    var saveBtn = UIButton()

    var fileName = "demo"
    
    private let resourcesUrl: URL? = URL(string: Bundle.main.resourceURL!.path)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        initializePickers()
        MarkupEditor.leftToolbar = AnyView(FileToolbar(fileToolbarDelegate: self))
        initializeStackView()
    }
    
    func initializePickers() {
        selectImageCancellable = MarkupEditor.selectImage.$value.sink { [weak self] value in
            if value {
                let controller =  UIDocumentPickerViewController(forOpeningContentTypes: [.image])
                controller.allowsMultipleSelection = false
                controller.delegate = self
                self?.present(controller, animated: true)
            }
        }
    }
    
    func divider(in parent: UIView) -> UIView {
        let parentView = parent
        let divider = UIView()
        parentView.addSubview(divider)
        divider.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            divider.heightAnchor.constraint(equalToConstant: 1),
            divider.leftAnchor.constraint(equalTo: parentView.leftAnchor),
            divider.rightAnchor.constraint(equalTo: parentView.rightAnchor),
        ])
        divider.backgroundColor = UIColor.systemGray5
        return divider
    }

    func initializeStackView() {
        
        self.view.backgroundColor = .white
        backBtn.setTitle("返回", for: .normal)
        backBtn.setTitleColor(.black, for: .normal)
        backBtn.frame = CGRect(origin: CGPoint(x: 10, y: 60), size: CGSize(width: 50, height: 30))
        backBtn.addTarget(self, action: #selector(backBtnAction), for: .touchUpInside)
        view.addSubview(backBtn)
        
        saveBtn.setTitle("保存", for: .normal)
        saveBtn.setTitleColor(.black, for: .normal)
        saveBtn.frame = CGRect(origin: CGPoint(x: view.frame.size.width - 60, y: 60), size: CGSize(width: 50, height: 30))
        saveBtn.addTarget(self, action: #selector(saveBtnAction), for: .touchUpInside)
        view.addSubview(saveBtn)
        
        // Create the stack
        stack = UIStackView()
        stack.axis = .vertical
        stack.distribution = .fill
        stack.frame = CGRect(origin: CGPoint(x: 10, y: 100), size: CGSize(width: view.frame.size.width-20, height: view.frame.size.height - 100))
        stack.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        view.addSubview(stack)


        // Create the webView
        let markupEditorView = MarkupEditorUIView(markupDelegate: self, html: demoHtml(), resourcesUrl: resourcesUrl, id: "Document")
        stack.addArrangedSubview(markupEditorView)
        bottomStack = UIStackView()
        bottomStack.isHidden = true
        bottomStack.axis = .vertical
        bottomStack.spacing = 8
        bottomStack.addArrangedSubview(divider(in: stack))
        let label = UILabel()
        label.text = "Document HTML"
        label.textAlignment = .center
        label.backgroundColor = UIColor.systemGray5
        bottomStack.addArrangedSubview(label)
        rawTextView = UITextView()
        rawTextView.isEditable = false
        rawTextView.contentInset = UIEdgeInsets(top: 8, left: 8, bottom: 8, right: 8)
        bottomStack.addArrangedSubview(rawTextView)
        stack.addArrangedSubview(bottomStack)
        bottomStackHeightConstraint = NSLayoutConstraint(item: bottomStack!, attribute: .height, relatedBy: .equal, toItem: markupEditorView, attribute: .height, multiplier: 1, constant: 1)
    }
    @objc func backBtnAction(){
        self.dismiss(animated: true)
    }
    @objc func saveBtnAction(){
        self.selectedWebView?.getRawHtml({ html in
            // 此处是需要保存的内容
        })
        self.dismiss(animated: true)
    }
    private func setRawText(_ handler: (()->Void)? = nil) {
        selectedWebView?.getHtml { html in
            self.rawTextView.attributedText = self.attributedString(from: html ?? "")
            handler?()
        }
    }
    
    private func attributedString(from string: String) -> NSAttributedString {
        var attributes = [NSAttributedString.Key: AnyObject]()
        attributes[.foregroundColor] = UIColor.label
        attributes[.font] = UIFont.monospacedSystemFont(ofSize: StyleContext.P.fontSize, weight: .regular)
        return NSAttributedString(string: string, attributes: attributes)
    }
    
    private func openExistingDocument(url: URL) {
        do {
            let html = try String(contentsOf: url, encoding: .utf8)
            selectedWebView?.setHtml(html) {
                self.setRawText()
            }
        } catch let error {
            print("Error loading html: \(error.localizedDescription)")
        }
    }
    
    private func imageSelected(url: URL) {
        guard let view = selectedWebView else { return }
        markupImageToAdd(view, url: url)
    }
    
    private func demoHtml() -> String {
        guard let demoUrl = Bundle.main.url(forResource: fileName, withExtension: "html") else { return "" }
        return (try? String(contentsOf: demoUrl)) ?? ""
    }

}

extension DemoViewController: MarkupDelegate {
    
    func markupDidLoad(_ view: MarkupWKWebView, handler: (()->Void)?) {
        MarkupEditor.selectedWebView = view
        setRawText(handler)
    }
    
    func markupInput(_ view: MarkupWKWebView) {
        // This is way too heavyweight, but it suits the purposes of the demo
        setRawText()
    }
    
    func markupImageAdded(url: URL) {
        print("Image added from \(url.path)")
    }
    
    func markupError(code: String, message: String, info: String?, alert: Bool) {
        print("Error \(code): \(message)")
        if let info = info { print(" \(info)") }
    }
    
}

extension DemoViewController: FileToolbarDelegate {
    
    func newDocument(handler: ((URL?)->Void)? = nil) {
        selectedWebView?.emptyDocument() {
            self.setRawText()
        }
    }
    
    func existingDocument(handler: ((URL?)->Void)? = nil) {
        let controller =  UIDocumentPickerViewController(forOpeningContentTypes: [.html])
        controller.allowsMultipleSelection = false
        controller.delegate = self
        present(controller, animated: true)
    }
    
    func rawDocument() {
        let willBeHidden = !bottomStack.isHidden
        bottomStackHeightConstraint.isActive = !willBeHidden
        bottomStack.isHidden = willBeHidden
    }
    
}

extension DemoViewController: UIDocumentPickerDelegate {
    
    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
        guard let url = urls.first, url.startAccessingSecurityScopedResource() else { return }
        defer { url.stopAccessingSecurityScopedResource() }
        if (MarkupEditor.selectImage.value) {
            MarkupEditor.selectImage.value = false
            imageSelected(url: url)
        } else {
            openExistingDocument(url: url)
        }
    }
    
    func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
        MarkupEditor.selectImage.value = false
        controller.dismiss(animated: true, completion: nil)
    }
    
}

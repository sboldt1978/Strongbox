//
//  PasskeyTableCellView.swift
//  Strongbox
//
//  Created by Strongbox on 17/09/2023.
//  Copyright © 2023 Mark McGuill. All rights reserved.
//

import UIKit

class PasskeyTableCellView: UITableViewCell {
    @IBOutlet var labelRelyingPartyId: UILabel!
    @IBOutlet var labelCredentialId: UILabel!
    @IBOutlet var labelUserHandle: UILabel!
    @IBOutlet var buttonSharePrivate: UIButton!
    @IBOutlet var labelUsername: UILabel!
    @IBOutlet var expandButton: UIButton!
    @IBOutlet weak var detailStackView: UIStackView!

    @objc
    var viewController: UIViewController!

    @objc
    var copyFunction: ((_ string: String) -> Void)!

    @objc
    var launchUrlFunction: ((_ string: String) -> Void)!

    @objc
    var onToggleCollapse: (() -> Void)?

    @objc
    var isCollapsed: Bool = false {
        didSet {
            updateCollapsedState()
        }
    }

    @objc
    var passkey: Passkey! {
        didSet {
            labelRelyingPartyId.text = passkey.relyingPartyId
            labelCredentialId.text = passkey.credentialIdB64
            labelUserHandle.text = passkey.userHandleB64
            labelUsername.text = passkey.username
        }
    }

    @IBAction func onLaunchRelyingParty(_: Any) {
        launchUrlFunction(passkey.relyingPartyId)
    }

    @IBAction func onCopyRelyingParty(_: Any) {
        copyFunction?(passkey.relyingPartyId)
    }

    @IBAction func onCopyUsername(_: Any) {
        copyFunction?(passkey.username)
    }

    @IBAction func onCopyCredentialId(_: Any) {
        copyFunction?(passkey.credentialIdB64)
    }

    @IBAction func onCopyUserHandle(_: Any) {
        copyFunction?(passkey.userHandleB64)
    }

    @IBAction func onCopyPrivateKey(_: Any) {
        copyFunction?(passkey.privateKeyPem)
    }

    @IBAction func onCollapseToggle(_ sender: Any) {
        isCollapsed.toggle()
        onToggleCollapse?()
    }

    private func updateCollapsedState() {
        self.detailStackView.isHidden = self.isCollapsed

        UIView.animate(withDuration: 0.3) { [weak self] in
            guard let self = self else { return }

            let rotation = self.isCollapsed ? 0 : CGFloat.pi / 2
            self.expandButton.transform = CGAffineTransform(rotationAngle: rotation)

            self.contentView.layoutIfNeeded()
        }
    }

    @IBAction func onSharePrivateKey(_: Any) {
        let foo = NSTemporaryDirectory() as NSString
        let bar = foo.appendingPathComponent(passkey.relyingPartyId)
        let path = (bar as NSString).appendingPathExtension("pem") ?? bar

        let url = URL(fileURLWithPath: path)

        guard let data = passkey.privateKeyPem.data(using: .utf8) else {
            Alerts.info(viewController,
                        title: NSLocalizedString("export_vc_error_exporting", comment: "Error Exporting"),
                        message: NSLocalizedString("export_vc_error_exporting", comment: "Error Exporting"))
            return
        }

        do {
            try data.write(to: url)
        } catch {
            Alerts.error(viewController, error: error)
            return
        }

        export(viewController, url: url, popoverView: buttonSharePrivate)
    }

    func export(_ viewController: UIViewController, url: URL, popoverView: UIView) {
        let activityViewController = UIActivityViewController(activityItems: [url], applicationActivities: nil)

        

        activityViewController.popoverPresentationController?.sourceView = popoverView
        activityViewController.popoverPresentationController?.sourceRect = popoverView.bounds
        activityViewController.popoverPresentationController?.permittedArrowDirections = .any

        activityViewController.completionWithItemsHandler = { _, _, _, _ in
            
            try? FileManager.default.removeItem(at: url)
        }

        viewController.present(activityViewController, animated: true)
    }
}

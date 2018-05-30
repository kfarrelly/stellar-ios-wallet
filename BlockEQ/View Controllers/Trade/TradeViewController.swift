//
//  TradeViewController.swift
//  BlockEQ
//
//  Created by Satraj Bambra on 2018-05-23.
//  Copyright © 2018 Satraj Bambra. All rights reserved.
//

import stellarsdk
import UIKit

protocol TradeViewControllerDelegate: AnyObject {
    func getOrderBook(sellingAsset: StellarAsset, buyingAsset: StellarAsset)
}

class TradeViewController: UIViewController {
    
    @IBOutlet var addAssetButton: UIButton!
    @IBOutlet var arrowImageView: UIImageView!
    @IBOutlet var buttonHolderView: UIView!
    @IBOutlet var tableview: UITableView!
    @IBOutlet var tradeFromView: UIView!
    @IBOutlet var tradeToView: UIView!
    @IBOutlet var tradeFromButton: UIButton!
    @IBOutlet var tradeToButton: UIButton!
    @IBOutlet var tradeFromTextField: UITextField!
    @IBOutlet var tradeToTextField: UITextField!
    @IBOutlet var tradeFromSelectorTextField: UITextField!
    @IBOutlet var tradeToSelectorTextField: UITextField!
    @IBOutlet var tradeFromInputAccessoryView: UIView!
    @IBOutlet var tradeToInputAccessoryView: UIView!
    @IBOutlet var tradeFromSelectorAccessoryInputView: UIView!
    @IBOutlet var tradeToSelectorAccessoryInputView: UIView!
    
    let tradeFromPickerView = UIPickerView()
    let tradeToPickerView = UIPickerView()
    var stellarAccount = StellarAccount()
    var toAssets: [StellarAsset] = []
    var fromAsset: StellarAsset!
    var toAsset: StellarAsset!
    
    weak var delegate: TradeViewControllerDelegate?
    
    @IBAction func addAsset() {
        
    }
    
    @IBAction func submitTrade() {
        guard let tradeFromAmount = tradeFromTextField.text, !tradeFromAmount.isEmpty else {
            tradeFromTextField.shake()
            return
        }
        
        guard let tradeToAmount = tradeToTextField.text, !tradeToAmount.isEmpty else {
            tradeToTextField.shake()
            return
        }
        
        showHud()
        
        TradeOperation.postTrade(amount: Decimal(string: tradeFromAmount)!,
                                 numerator: Int(Float(tradeToAmount)! * 1000),
                                 denominator: Int(Float(tradeFromAmount)! * 1000),
                                 sellingAsset: fromAsset,
                                 buyingAsset: toAsset) { completion in
            self.hideHud()
            self.getOrderBook()
        }
    }
    
    @IBAction func tradeFromSelected() {
        tradeFromSelectorTextField.becomeFirstResponder()
    }
    
    @IBAction func tradeToSelected() {
        tradeToSelectorTextField.becomeFirstResponder()
    }
    
    @IBAction func dismissKeyboard() {
        view.endEditing(true)
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        setupView()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        getAccountDetails()
    }

    func setupView() {
        tradeFromView.layer.borderWidth = 0.5
        tradeFromView.layer.borderColor = Colors.red.cgColor
        
        tradeToView.layer.borderWidth = 0.5
        tradeToView.layer.borderColor = Colors.green.cgColor
        
        arrowImageView.tintColor = Colors.lightGray
        addAssetButton.backgroundColor = Colors.primaryDark
        tableview.backgroundColor = Colors.lightBackground
        tradeFromButton.backgroundColor = Colors.red
        tradeToButton.backgroundColor = Colors.green
        tradeFromTextField.textColor = Colors.darkGray
        tradeToTextField.textColor = Colors.darkGray
        tradeToView.backgroundColor = Colors.lightBackground
        tradeFromView.backgroundColor = Colors.lightBackground
        view.backgroundColor = Colors.lightBackground
        
        for subview in buttonHolderView.subviews {
            if let button = subview as? UIButton {
                button.backgroundColor = Colors.lightGrayTransparent
                button.setTitleColor(Colors.darkGray, for: .normal)
            }
        }
        
        tradeFromPickerView.dataSource = self
        tradeFromPickerView.delegate = self
        
        tradeToPickerView.dataSource = self
        tradeToPickerView.delegate = self
        
        tradeFromTextField.inputAccessoryView = tradeFromInputAccessoryView
        tradeToTextField.inputAccessoryView = tradeToInputAccessoryView
        tradeFromSelectorTextField.inputAccessoryView = tradeFromSelectorAccessoryInputView
        tradeToSelectorTextField.inputAccessoryView = tradeToSelectorAccessoryInputView
        
        tradeFromSelectorTextField.inputView = tradeFromPickerView
        tradeToSelectorTextField.inputView = tradeToPickerView
    }
    
    func setTradeSelectors(fromAsset: StellarAsset?, toAsset: StellarAsset?) {
        if let selectedFromAsset = fromAsset {
            self.fromAsset = selectedFromAsset
            setTradeFromSelector()
            getOrderBook()
            return
        }
        
        if let selectedToAsset = toAsset {
            self.toAsset = selectedToAsset
            setTradeToSelector()
            getOrderBook()
            return
        }
    }
    
    func getOrderBook() {
        if let sellingAsset = fromAsset, let buyingAsset = toAsset {
            delegate?.getOrderBook(sellingAsset: sellingAsset, buyingAsset: buyingAsset)
        }
    }
    
    func setTradeFromSelector() {
        if let toButtonText = tradeToButton.titleLabel?.text, !toButtonText.elementsEqual(fromAsset.shortCode) {
            tradeFromButton.setTitle(fromAsset.shortCode, for: .normal)
            return
        }
        
        guard let removableIndex = self.stellarAccount.assets.index(of: fromAsset) else {
            return
        }
        
        tradeFromButton.setTitle(fromAsset.shortCode, for: .normal)
        
        toAssets = self.stellarAccount.assets
        toAssets.remove(at: removableIndex)
        toAsset = toAssets[0]
        tradeToButton.setTitle(toAsset.shortCode, for: .normal)
        
        tradeFromPickerView.reloadAllComponents()
        tradeToPickerView.reloadAllComponents()
        tradeToPickerView.selectRow(0, inComponent: 0, animated: false)
        
        return
    }
    
    func setTradeToSelector() {
        if let fromButtonText = tradeFromButton.titleLabel?.text, !fromButtonText.elementsEqual(toAsset.shortCode) {
            tradeToButton.setTitle(toAsset.shortCode, for: .normal)
            return
        }
        
        var toAssetToRemove: StellarAsset!
        
        for asset in self.stellarAccount.assets {
            if tradeFromButton.titleLabel?.text != asset.shortCode {
                print(fromAsset.shortCode)
                fromAsset = asset
                tradeFromButton.setTitle(fromAsset.shortCode, for: .normal)
                toAssetToRemove = fromAsset
                break
            }
        }
        
        guard let removableToAsset = toAssetToRemove, let removableIndex = self.stellarAccount.assets.index(of: removableToAsset) else {
            return
        }
        
        tradeToButton.setTitle(toAsset.shortCode, for: .normal)
        
        toAssets = self.stellarAccount.assets
        toAssets.remove(at: removableIndex)
        
        tradeFromPickerView.reloadAllComponents()
        tradeToPickerView.reloadAllComponents()
        
        tradeFromPickerView.selectRow(0, inComponent: 0, animated: false)
    }
    
    func showHud() {
        let hud = MBProgressHUD.showAdded(to: (navigationController?.view)!, animated: true)
        hud.label.text = "Placing Trade Offer..."
        hud.mode = .indeterminate
    }
    
    func hideHud() {
        MBProgressHUD.hide(for: (navigationController?.view)!, animated: true)
    }
}

extension TradeViewController: UIPickerViewDataSource {
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        if pickerView == tradeFromPickerView {
            return stellarAccount.assets.count
        }
        return toAssets.count
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        if pickerView == tradeFromPickerView {
            setTradeSelectors(fromAsset: stellarAccount.assets[row], toAsset: nil)
            return
        }
        setTradeSelectors(fromAsset: nil, toAsset: toAssets[row])
    }
}

extension TradeViewController: UIPickerViewDelegate {
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        if pickerView == tradeFromPickerView {
            return "\(Assets.displayTitle(shortCode: stellarAccount.assets[row].shortCode)) (\(stellarAccount.assets[row].shortCode))"
        }
        return "\(Assets.displayTitle(shortCode: toAssets[row].shortCode)) (\(toAssets[row].shortCode))"
    }
}

/*
 * Operations
 */
extension TradeViewController {
    func getAccountDetails() {
        guard let accountId = KeychainHelper.getAccountId() else {
            return
        }
        
        AccountOperation.getAccountDetails(accountId: accountId) { responseAccounts in
            if !responseAccounts.isEmpty && responseAccounts[0].assets.count > 1{
                self.stellarAccount = responseAccounts[0]
                self.setTradeSelectors(fromAsset: self.stellarAccount.assets[0], toAsset: nil)
            }
        }
    }
}



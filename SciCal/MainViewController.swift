    //
    //  MainViewController.swift
    //  SciCal
    //
    //  Created by BinWu on 15/2/1.
    //  Copyright (c) 2015年 BinWu. All rights reserved.
    //
    
    import UIKit
    
    class MainViewController: UIViewController {
        
        @IBOutlet weak var historyDisplay: UILabel!
        @IBOutlet weak var resultDisplay: UILabel!
        
        var firstKey :Bool = true
        //        var calcBrain = CalcBrain()
        var calcBrain = CalcModel()
        var currentNumber:String = ""
        
        var result :String {
            get{
                return resultDisplay.text!
            }
            set{
                resultDisplay.text = newValue
            }
        }
        
        var historyDisplayValue :String {
            get{
                return historyDisplay.text!
            }
            set{
                historyDisplay.text = "\(newValue)"
            }
        }
        
        func appendkey(newKey:String){
            if firstKey {
                if newKey == "." {
                    currentNumber = "0."
                }else{
                    currentNumber = newKey
                }
                firstKey = false
                (result, historyDisplayValue) = calcBrain.pushKey(newNumber:currentNumber)
            }else{
                if (currentNumber == "0")&&(newKey != "."){
                    currentNumber = newKey
                }else{
                    currentNumber = currentNumber + newKey
                }
                (result, historyDisplayValue) = calcBrain.pushKey(updateNumber: currentNumber)
            }
        }
        
        @IBAction func keyPad(sender: UIButton) {
            if sender.currentTitle! == "." {
                if let _ = currentNumber.rangeOfString("."){
                }else{
                    appendkey(sender.currentTitle!)
                }
            }else{
                appendkey(sender.currentTitle!)
            }
        }
        
        @IBAction func operate(sender: UIButton) {
            firstKey = true
            (result,historyDisplayValue) = calcBrain.pushOP(sender.currentTitle!)
            if(sender.currentTitle == "="){
                historyDisplay.text = ""
                firstKey = true
                calcBrain.clearHistory()
                if result != "ERROR"{
                    appendkey(result)
                }
            }
        }
        
        @IBAction func clearAll() {
            historyDisplay.text = ""
            result = ""
            firstKey = true
            calcBrain.clearHistory()
        }
        
        @IBAction func back(sender: UIButton) {
            if !calcBrain.isHistoryEmpty(){
                (result,historyDisplayValue) = calcBrain.deleteAbit()
                
                if calcBrain.isHistoryEmpty() {
                    currentNumber = ""
                    historyDisplay.text = ""
                }else{
                    let numbers = currentNumber.characters.count
                    if numbers > 1{
                        let index = currentNumber.startIndex.advancedBy(numbers-1)
                        currentNumber.removeAtIndex(index)
                    }else if numbers == 1{
                        currentNumber = ""
                        firstKey = true
                    }
                }
            }
        }
        
        
        override func viewDidLoad() {
            super.viewDidLoad()
            
            // Do any additional setup after loading the view.
        }
        
        override func didReceiveMemoryWarning() {
            super.didReceiveMemoryWarning()
            // Dispose of any resources that can be recreated.
        }
        
    }

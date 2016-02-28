//
//  CalcModel.swift
//  SciCal
//
//  Created by BinWu on 15/2/5.
//  Copyright (c) 2015年 BinWu. All rights reserved.
//

import Foundation

class CalcModel {
    
    enum historyElement : CustomStringConvertible {
        case Number(String)
        case UnaryOperation(String,Int,Double ->Double?)
        case BinaryOperation(String,Int,(Double ,Double) -> Double?)
        case UnaryOptionOperation(String,Int,() -> Double)
        case AloneOperation(String)
        
        var description : String{
            get{
                switch self {
                case .Number(let number):
                    return "\(number)"
                case .UnaryOperation(let operation,_,_):
                    return "\(operation)"
                case .BinaryOperation(let operation,_,_):
                    return "\(operation)"
                case .UnaryOptionOperation(let operation,_,_):
                    return "\(operation)"
                case .AloneOperation(let string):
                    return "\(string)"
                }
            }
        }
    }
    
    var historyStack = [historyElement]()
    var knownOps = [String:historyElement]()
    
    init(){
        knownOps["+"] = historyElement.BinaryOperation("+",1){$0+$1}
        knownOps["−"] = historyElement.BinaryOperation("−",1){$0-$1}
        knownOps["×"] = historyElement.BinaryOperation("×",2){$0*$1}
        knownOps["÷"] = historyElement.BinaryOperation("÷",2) {if $1 == 0 {return nil} else {return $0/$1} }
        knownOps["√"] = historyElement.UnaryOperation("√",3) {sqrt($0)}
        knownOps["Sin"] = historyElement.UnaryOperation("Sin",3) {sin($0 * M_PI/180)}
        knownOps["Cos"] = historyElement.UnaryOperation("Cos",3) {cos($0 * M_PI/180)}
        knownOps["∏"] = historyElement.UnaryOptionOperation("∏",3) {M_PI}
        knownOps["("] = historyElement.AloneOperation("(")
        knownOps[")"] = historyElement.AloneOperation(")")
    }
    
    func takeFirstElement(elements:[historyElement]) -> (firstElement:historyElement?,  remaingingElements:[historyElement]) {
        if !elements.isEmpty {
            var remaingingElements = elements
            let element = remaingingElements.removeAtIndex(0)
            return (element,remaingingElements)
        }else{
            return (nil, elements)
        }
    }
    
    func searchParenthesesPosition(elements: [historyElement]) -> (left: Int? , right: Int?) {
        var leftPosition :Int? = nil
        var rightPosition :Int? = nil
        var index :Int = 0
        var firstElement :historyElement? = nil
        var tempElements = elements
        while  true {
            (firstElement, tempElements) = takeFirstElement(tempElements)
            if firstElement != nil {
                switch firstElement! {
                case .AloneOperation(let string):
                    if string == "(" {
                        leftPosition = index
                    }else if string == ")" {
                        rightPosition = index
                        return  (leftPosition, rightPosition)
                    }
                default:
                    break
                }
            }else{
                break
            }
            index++
        }
        return  (leftPosition, rightPosition)
    }
    
    func isElementANumber(element: historyElement?) -> Bool? {
        if element != nil {
            switch element! {
            case .Number(_):
                return true
            default:
                return false
            }
        }else{
            return nil
        }
    }
    
    func calcGetAnElement(elements:[historyElement]) -> (element:historyElement?,  remaingingElements:[historyElement]) {
        if !elements.isEmpty {
            var remaingingElements = elements
            let element = remaingingElements.removeAtIndex(0)
            return (element,remaingingElements)
        }else{
            return (nil, elements)
        }
    }
    
    func calcgetFirstOptionNumber(elements:[historyElement]) -> (number: Double?,remainingElements:[historyElement]){
        
        let (element, remainingElements) = calcGetAnElement(elements)
        if element != nil {
            switch element! {
            case .Number(let number):
                return (NSNumberFormatter().numberFromString(number)!.doubleValue,remainingElements)
            case .UnaryOptionOperation(_, _, let operation):
                return (operation(),remainingElements)
            default:
                return (nil, remainingElements)
            }
        }else{
            return (nil, remainingElements)
        }
    }
    
    
    func calcGetTwoOperationAndLevel(elements:[historyElement]) -> (operationLevel1 :Int ,operationPosition1 :Int?,
        operationLevel2 :Int ,operationPosition2 :Int? )
    {
        var firstOperationPosition : Int? = nil
        var firstOperationLevel :Int = 0
        var secondOperationPosition : Int? = nil
        var secondOperationLevel :Int = 0
        var times :Int = 0
        var remainingElements = elements
        
        var operationType :historyElement? = nil
        var operationLevel :Int? = nil
        
        while !remainingElements.isEmpty {
            (operationType, remainingElements) = calcGetAnElement(remainingElements)
            if operationType != nil {
                
                switch operationType! {
                case .BinaryOperation(_,let level,_):
                    operationLevel = level
                case .UnaryOperation(_,let level, _):
                    operationLevel = level
                case .UnaryOptionOperation(_,let level, _):
                    operationLevel = level
                default:
                    
                    break
                }
                
                if operationLevel != nil {
                    if firstOperationPosition != nil {
                        secondOperationPosition = times
                        secondOperationLevel = operationLevel!
                        break
                    }else{
                        firstOperationPosition = times
                        firstOperationLevel = operationLevel!
                        operationLevel = nil
                    }
                }
            }
            times++
        }
        
        
        return (firstOperationLevel,firstOperationPosition,
            secondOperationLevel,secondOperationPosition)
    }
    
    func calcOnce(elements:[historyElement]) -> (result:Double?, remaingingElements:[historyElement]){
        var element:historyElement? = nil
        var remainingElements = [historyElement]()
        _ = [historyElement]()
        var result :Double? = nil
        
        (element, remainingElements) = calcGetAnElement(elements)
        
        if element != nil {
            switch element! {
            case .Number(let stringNumber):
                let firstNumber = NSNumberFormatter().numberFromString(stringNumber)!.doubleValue
                var operationType :historyElement? = nil
                
                (operationType, remainingElements) = calcGetAnElement(remainingElements)
                if operationType != nil {
                    switch operationType! {
                    case .BinaryOperation(_, _, let binaryOperation):
                        var secondNumber :Double? = nil
                        (number: secondNumber,remainingElements) = calcgetFirstOptionNumber(remainingElements)
                        if secondNumber != nil {
                            result = binaryOperation(firstNumber,secondNumber!)
                        }else{
                            result = firstNumber
                            remainingElements.removeAll()
                        }
                    case .UnaryOperation(_, _, _):
                        var nextResult :Double? = nil
                        remainingElements = elements
                        remainingElements.removeAtIndex(0)
                        (result:nextResult,remainingElements) = calcOnce(remainingElements)
                        if nextResult != nil {
                            result = firstNumber * nextResult!
                        }else{
                            result = firstNumber
                            remainingElements.removeAll()
                        }
                        //                    case .UnaryOptionOperation(_, _, let unaryNumber):
                        //                        remainingElements = elements
                        //                        remainingElements.removeAtIndex(0)
                        //                        remainingElements.insert(knownOps["×"]!, atIndex: 0)
                        //                        result = firstNumber
                    default:
                        break
                    }
                }else{
                    result = firstNumber
                    remainingElements.removeAll()
                }
            case .BinaryOperation(_, _, _):
                remainingElements.removeAll()
            case .UnaryOperation(_, _, let operation):
                var number :Double? = nil
                (number:number,remainingElements: remainingElements) = calcgetFirstOptionNumber(remainingElements)
                if number != nil {
                    result = operation(number!)
                }else{
                    remainingElements.removeAll()
                }
            case .UnaryOptionOperation(_, _, let operation):
                //                var number :Double? = nil
                //                tempRemainingElements = remainingElements
                //                (number: number,remainingElements: tempRemainingElements) = calcgetFirstOptionNumber(tempRemainingElements)
                //                if number != nil {
                //                    remainingElements.insert(knownOps["×"]!, atIndex: 0)
                //                }
                result = operation()
            default:
                break
            }
        }
        
        return (result, remainingElements)
    }
    
    func calcFixPIE(elements:[historyElement]) -> [historyElement]{
        var tempElements = elements
        var i:Int = 0
        var lastElement:historyElement? = nil
        var positions = [Int]()
        
        for ob in tempElements {
            if(lastElement != nil){
                switch (lastElement!, ob) {
                case (.Number(_), .UnaryOptionOperation(_)):
                    fallthrough
                case (.UnaryOptionOperation(_), .Number(_)):
                    fallthrough
                case (.UnaryOptionOperation(_),.UnaryOptionOperation(_)):
                    positions.append(i)
                default:
                    break
                }
            }
            lastElement = ob
            i++
        }
        
        while !positions.isEmpty {
            let position = positions.removeLast()
            tempElements.insert(knownOps["×"]!, atIndex: position)
        }
        //        print("CA:")
        //        for ob in tempElements{
        //            print("\(ob) ")
        //        }
        //        println("")
        
        return tempElements
    }
    
    func calc(subElements elements:[historyElement]) -> Double? {
        var result :Double? = nil
        var remainingElements = elements
        
        while !remainingElements.isEmpty {
            var firstOperationPosition : Int? = nil
            var firstOperationLevel :Int = 0
            var secondOperationPosition : Int? = nil
            var secondOperationLevel :Int = 0
            remainingElements = calcFixPIE(remainingElements)
            var tempRemainingElements = remainingElements
            
            (firstOperationLevel,firstOperationPosition,
                secondOperationLevel,secondOperationPosition) = calcGetTwoOperationAndLevel(tempRemainingElements)
            
            if (firstOperationPosition != nil) && (secondOperationPosition != nil) && (firstOperationLevel < secondOperationLevel) {
                let firstOperationRange :Range = 0...firstOperationPosition!
                let remainingRange :Range = firstOperationPosition!+1..<remainingElements.endIndex
                var tempResult :Double? = nil
                
                tempRemainingElements = remainingElements
                tempRemainingElements.removeRange(remainingRange)
                let firstOperationElements = tempRemainingElements
                
                tempRemainingElements = remainingElements
                tempRemainingElements.removeRange(firstOperationRange)
                (tempResult,tempRemainingElements) = calcOnce(tempRemainingElements)
                
                if tempResult != nil {
                    remainingElements = firstOperationElements
                    remainingElements.append(historyElement.Number("\(tempResult!)"))
                    remainingElements += tempRemainingElements
                }else{
                    let lastRange :Range = secondOperationPosition!..<remainingElements.endIndex
                    remainingElements.removeRange(lastRange)
                    (result,_) = calcOnce(remainingElements)
                    remainingElements.removeAll()
                }
            }else{
                (result,remainingElements) = calcOnce(remainingElements)
                if remainingElements.isEmpty {
                    
                }else{
                    remainingElements.insert(historyElement.Number("\(result!)"), atIndex: 0)
                }
            }
        }
        return result
    }
    
    func calc(elements elements:[historyElement]) -> Double? {
        var tempElements = elements
        var result :Double? = nil
        
        while !tempElements.isEmpty {
            var leftPosition :Int? = nil
            var rightPosition :Int? = nil
            
            (leftPosition,rightPosition) = searchParenthesesPosition(tempElements)
            if leftPosition == nil {
                if rightPosition == nil {
                }else{
                    tempElements.removeRange(rightPosition!..<tempElements.endIndex)
                }
                tempElements.insert(knownOps["("]!, atIndex: 0)
                tempElements.append(knownOps[")"]!)
                leftPosition = 0
                rightPosition = tempElements.endIndex-1
            }else{
                if rightPosition == nil {
                    tempElements.append(knownOps[")"]!)
                    rightPosition = tempElements.endIndex-1
                }
            }
            
            var subElements = tempElements
            var leftElements = tempElements
            var rightElements = tempElements
            
            subElements.removeRange(rightPosition!..<subElements.endIndex)
            subElements.removeRange(0...leftPosition!)
            
            leftElements.removeRange(leftPosition!..<leftElements.endIndex)
            rightElements.removeRange(0...rightPosition!)
            
            result =  calc(subElements:subElements)
            
            if result != nil {
                tempElements.removeRange(leftPosition!...rightPosition!)
                if tempElements.isEmpty {
                    break
                }
                if let isRightANumber = isElementANumber(rightElements.first){
                    if isRightANumber {
                        tempElements.insert(knownOps["×"]!, atIndex: leftPosition!)
                        tempElements.insert(historyElement.Number("\(result!)"),atIndex: leftPosition!)
                    }else{
                        tempElements.insert(historyElement.Number("\(result!)"),atIndex: leftPosition!)
                    }
                }else{
                    tempElements.append(historyElement.Number("\(result!)"))
                }
                
                if let isLeftANumber = isElementANumber(rightElements.first) {
                    if isLeftANumber {
                        tempElements.insert(knownOps["×"]!, atIndex: leftPosition!)
                    }
                }
            }else{
                tempElements = leftElements
            }
        }
        
        return result
    }
    
    func calc () -> String{
        if let result =  calc(elements:historyStack){
            return "\(result)"
        }else{
            return "ERROR"
        }
    }
    
    func printHistoryStack(){
        print("HS:", terminator: "")
        for ob in historyStack {
            print("\(ob) ", terminator: "")
        }
        print("")
    }
    
    /* store model */
    func pushKey(newNumber number:String) -> (reslut:String , history:String){
        historyStack.append(historyElement.Number(number))
        printHistoryStack()
        return (calc(), getHistoryString())
    }
    
    func pushKey(updateNumber number:String) -> (reslut:String , history:String){
        historyStack.removeLast()
        return pushKey(newNumber: number)
    }
    
    func pushOP(symbol:String) -> (reslut:String , history:String){
        if let operation = knownOps[symbol] {
            historyStack.append(operation)
            switch symbol{
            case "Sin":
                fallthrough
            case "√":
                fallthrough
            case "Cos":
                historyStack.append(knownOps["("]!)
            default:
                break
            }
        }
        printHistoryStack()
        return (calc(), getHistoryString())
    }
    
    func getHistoryString()-> String{
        var histroyString : String = ""
        for ob in historyStack
        {
            histroyString = histroyString + "\(ob) "
        }
        return histroyString
    }
    
    func clearHistory(){
        historyStack.removeAll()
    }
    
    func isHistoryEmpty() ->Bool {
        if let _ = historyStack.last {
            return false
        }
        return true
    }
    
    func deleteAbit() -> (result: String , historyString :String){
        if let lastElement = historyStack.last {
            switch lastElement {
            case .Number(var number):
                historyStack.removeLast()
                number = String(number.characters.dropLast())
                if number != "" {
                    historyStack.append(historyElement.Number(number))
                }
            default:
                historyStack.removeLast()
            }
        }
        if isHistoryEmpty() {
            return ("", "")
        }else{
            return (calc(), getHistoryString())
        }
    }
}
//
//  CalcBrain.swift
//  SciCal
//
//  Created by BinWu on 15/2/1.
//  Copyright (c) 2015年 BinWu. All rights reserved.
//

import Foundation

class CalcBrain {
    
    enum historyElement : CustomStringConvertible {
        case Number(String)
        case Operation(String)
        
        var description : String{
            get{
                switch self {
                case .Number(let number):
                    return "\(number)"
                case .Operation(let operation):
                    return "\(operation)"
                }
            }
        }
    }
    
    enum Op {
        case UnaryOperation(Int,Double ->Double?)
        case BinaryOperation(Int,(Double ,Double) -> Double?)
        case UnaryNumber(Int,() -> Double)
        case DoneOperation(String)
    }
    
    //    var opStack = [Op]()
    var elementStack = [historyElement]()
    
    var evaluate = [Op]()
    
    var knownOps = [String:Op]()
    
    var newKey:Bool = true
    
    init(){
        knownOps["+"] = Op.BinaryOperation(1){$0+$1}
        knownOps["−"] = Op.BinaryOperation(1){$0-$1}
        knownOps["×"] = Op.BinaryOperation(2){$0*$1}
        knownOps["÷"] = Op.BinaryOperation(2) {if $1 == 0 {return nil} else {return $0/$1} }
        knownOps["√"] = Op.UnaryOperation(3) {sqrt($0)}
        knownOps["Sin"] = Op.UnaryOperation(3) {sin($0 * M_PI/180)}
        knownOps["Cos"] = Op.UnaryOperation(3) {cos($0 * M_PI/180)}
        knownOps["∏"] = Op.UnaryNumber(3) {M_PI}
        knownOps["="] = Op.DoneOperation("=")
    }
    
    func calc(elements:[historyElement]) -> (element:historyElement?,  remaingingElements:[historyElement]) {
        if !elements.isEmpty {
            var remaingingElements = elements
            let element = remaingingElements.removeAtIndex(0)
            return (element,remaingingElements)
        }else{
            return (nil, elements)
        }
    }
    
    func calc(elements:[historyElement]) -> (operation :Op?,  remaingingElements:[historyElement]){
        var remainingElements :[historyElement] = []
        var element:historyElement? = nil
        var operation :Op? = nil
        (element, remainingElements) = calc(elements)
        
        if element != nil {
            switch element! {
            case .Operation(let operationString):
                operation = knownOps[operationString]
            default:
                break
            }
        }
        return (operation,remainingElements)
    }
    
    func calc(elements:[historyElement]) -> (operationLevel :Int? ,remaingingElements:[historyElement]){
        var remainingElements = [historyElement]()
        var operationType :Op? = nil
        var operationLevel :Int? = nil
        
        (operation: operationType, remainingElements) = calc(elements)
        if operationType != nil {
            switch operationType! {
            case .BinaryOperation(let level,_):
                operationLevel = level
            case .UnaryOperation(let level, _):
                operationLevel = level
            case .UnaryNumber(let level, _):
                operationLevel = level
            default:
                break
            }
        }
        return (operationLevel,remainingElements)
    }
    
    func calc(elements:[historyElement]) -> (BinaryOperation:((Double,Double) -> Double?)? ,remaingingElements:[historyElement]){
        var remainingElements = [historyElement]()
        var operationType :Op? = nil
        var operation :((Double,Double) -> Double?)? = nil
        
        (operation: operationType, remainingElements) = calc(elements)
        if operationType != nil {
            switch operationType! {
            case .BinaryOperation(_, let operationGet):
                operation = operationGet
            default:
                break
            }
        }
        return (operation,remainingElements)
    }
    
    func calc(elements:[historyElement]) -> (UnaryOperation:(Double -> Double?)? ,remaingingElements:[historyElement]){
        var remainingElements = [historyElement]()
        var operationType :Op? = nil
        var operation :(Double -> Double?)? = nil
        
        (operation: operationType, remainingElements) = calc(elements)
        if operationType != nil {
            switch operationType! {
            case .UnaryOperation(_, let operationGet):
                operation = operationGet
            default:
                break
            }
        }
        return (operation,remainingElements)
    }
    
    
    func calc(elements:[historyElement]) -> (number:Double?,  remaingingElements:[historyElement]){
        var remainingElements :[historyElement] = []
        var element:historyElement? = nil
        var number :Double? = nil
        (element, remainingElements) = calc(elements)
        
        if element != nil {
            switch element! {
            case .Number(let stringNumber):
                number = NSNumberFormatter().numberFromString(stringNumber)!.doubleValue
            default:
                break
            }
        }
        return (number,remainingElements)
    }
    
    func calc(elements:[historyElement]) -> (result:Double?, remaingingElements:[historyElement]){
        var element:historyElement? = nil
        var remainingElements = [historyElement]()
        var tempRemainingElements = [historyElement]()
        var result :Double? = nil
        (element, remainingElements) = calc(elements)
        
        if element != nil {
            switch element! {
            case .Number(let stringNumber):
                let firstNumber = NSNumberFormatter().numberFromString(stringNumber)!.doubleValue
                var operationType :Op? = nil
                
                (operation: operationType, remainingElements) = calc(remainingElements)
                if operationType != nil {
                    switch operationType! {
                    case .BinaryOperation(_, let binaryOperation):
                        var secondNumber :Double? = nil
                        (number: secondNumber,remainingElements) = calc(remainingElements)
                        if secondNumber != nil {
                            result = binaryOperation(firstNumber,secondNumber!)
                        }else{
                            result = firstNumber
                            remainingElements.removeAll()
                        }
                    case .UnaryOperation(_, _):
                        var nextResult :Double? = nil
                        remainingElements = elements
                        remainingElements.removeAtIndex(0)
                        (result:nextResult,remainingElements) = calc(remainingElements)
                        if nextResult != nil {
                            result = firstNumber * nextResult!
                        }else{
                            result = firstNumber
                            remainingElements.removeAll()
                        }
                    case .UnaryNumber(_, _):
                        remainingElements = elements
                        remainingElements.removeAtIndex(0)
                        remainingElements.insert(historyElement.Operation("×"), atIndex: 0)
                        result = firstNumber
                    default:
                        break
                    }
                }else{
                    result = firstNumber
                    remainingElements.removeAll()
                }
            case .Operation(let operationString):
                let operationTyoe = knownOps[operationString]
                if operationTyoe != nil {
                    switch operationTyoe! {
                    case .BinaryOperation(_,_):
                        remainingElements.removeAll()
                    case .DoneOperation(_):
                        remainingElements.removeAll()
                    case .UnaryOperation(_, let operation):
                        var number :Double? = nil
                        (number:number,remainingElements) = calc(remainingElements)
                        if number != nil {
                            result = operation(number!)
                        }else{
                            remainingElements.removeAll()
                        }
                    case .UnaryNumber(_, let operation):
                        var number :Double? = nil
                        tempRemainingElements = remainingElements
                        (number:number,tempRemainingElements) = calc(tempRemainingElements)
                        if number != nil {
                            remainingElements.insert(historyElement.Operation("×"), atIndex: 0)
                        }
                        result = operation()
                    }
                }
            }
        }
        
        return (result, remainingElements)
    }
    
    
    
    func calc () -> Double?{
        var result :Double? = nil
        var remainingElements = elementStack
        var tempRemainingElements = [historyElement]()
        //        var tempRemainingElements2 = [historyElement]()
        
        while !remainingElements.isEmpty {
            var firstOperationPosition : Int? = nil
            var firstOperationLevel :Int = 0
            var secondOperationPosition : Int? = nil
            var secondOperationLevel :Int = 0
            var times :Int = 0
            
            tempRemainingElements = remainingElements
            
            while !tempRemainingElements.isEmpty {
                var operationLevel :Int? = nil
                
                (operationLevel :operationLevel,tempRemainingElements) = calc(tempRemainingElements)
                if operationLevel != nil {
                    if firstOperationPosition != nil {
                        secondOperationPosition = times
                        secondOperationLevel = operationLevel!
                        break
                    }else{
                        firstOperationPosition = times
                        firstOperationLevel = operationLevel!
                    }
                }
                times++
            }
            
            if (firstOperationPosition != nil) && (secondOperationPosition != nil) && (firstOperationLevel < secondOperationLevel) {
                let firstOperationRange :Range = 0...firstOperationPosition!
                let remainingRange :Range = firstOperationPosition!+1..<remainingElements.endIndex
                var tempResult :Double? = nil
                
                tempRemainingElements = remainingElements
                tempRemainingElements.removeRange(remainingRange)
                let firstOperationElements = tempRemainingElements
                
                tempRemainingElements = remainingElements
                tempRemainingElements.removeRange(firstOperationRange)
                (result:tempResult,tempRemainingElements) = calc(tempRemainingElements)
                
                if tempResult != nil {
                    remainingElements = firstOperationElements
                    remainingElements.append(historyElement.Number("\(tempResult!)"))
                    remainingElements += tempRemainingElements
                }else{
                    let lastRange :Range = secondOperationPosition!..<remainingElements.endIndex
                    remainingElements.removeRange(lastRange)
                    (result:result,_) = calc(remainingElements)
                    remainingElements.removeAll()
                }
                
            }else{
                (result:result,remainingElements) = calc(remainingElements)
                if remainingElements.isEmpty {
                    
                }else{
                    remainingElements.insert(historyElement.Number("\(result!)"), atIndex: 0)
                }
            }
        }
        return result
    }
    
    func pushKey(number:String) -> (Double? , String){
        var result:Double? = nil
        if newKey {
            elementStack.append(historyElement.Number(number))
            newKey = false
        }else{
            elementStack.removeLast()
            elementStack.append(historyElement.Number(number))
        }
        
        for ob in elementStack
        {
            print("\(ob) ", terminator: "")
        }
        print("")
        
        //        result = calc(nil,remainingElement: elementStack,getANumberOnly: false)
        result = calc()
        let histroyString = getHistoryString()
        return (result, histroyString)
    }
    
    func pushOP(symbol:String) -> (Double? , String){
        var result:Double? = nil
        
        newKey = true
        if symbol != "=" {
            elementStack.append(historyElement.Operation(symbol))
        }
        
        for ob in elementStack
        {
            print("\(ob) ", terminator: "")
        }
        print("")
        
        //        result = calc(nil,remainingElement: elementStack,getANumberOnly: false)
        result = calc()
        let histroyString = getHistoryString()
        if symbol == "=" {
            clearHistory()
            if result != nil {
                elementStack.append(historyElement.Number("\(result!)"))
            }
        }
        
        return (result, histroyString)
    }
    
    func getHistoryString()-> String{
        var histroyString : String = ""
        for ob in elementStack
        {
            histroyString = histroyString + "\(ob) "
        }
        return histroyString
    }
    
    func clearHistory(){
        elementStack.removeAll()
        newKey = true
    }
    
    func isHistoryEmpty() ->Bool {
        if let _ = elementStack.last {
            return false
        }
        return true
    }
    
    func deleteAbit() -> (Double? , String){
        if let lastElement = elementStack.last {
            switch lastElement {
            case .Operation(_):
                elementStack.removeLast()
            case .Number(var number):
                elementStack.removeLast()
                number = String(number.characters.dropLast())
                if number != "" {
                    elementStack.append(historyElement.Number(number))
                    newKey = false
                }else{
                    newKey = true
                }
            }
        }
        
        if let _ = elementStack.last{
            var result:Double? = nil
            //            result = calc(nil,remainingElement: elementStack,getANumberOnly: false)
            result = calc()
            let histroyString = getHistoryString()
            return (result, histroyString)
        }else{
            newKey = true
            return (0,"")
        }
    }
}
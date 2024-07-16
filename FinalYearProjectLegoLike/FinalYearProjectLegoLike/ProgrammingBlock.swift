//
//  ProgrammingBlock.swift
//  FinalYearProjectLegoLike
//
//  Created by MARYAM ALKHOWILDI on 07/03/2024.
//

import Foundation

protocol ProgrammingBlock: AnyObject {
    var codeTemplate: String { get }
    var children: [ProgrammingBlock] { get set }
    func generateCode() -> String
    func generateSidebarMessage(indentationLevel: Int) -> String
    func identifier() -> String
}


class StartBlock: ProgrammingBlock {
    func identifier() -> String {
        return "Start"
    }
    
    var children = [ProgrammingBlock]()
    var codeTemplate: String {
        return "func main() { \n<<code>>\n}"
    }

    func generateCode() -> String {
        return codeTemplate
    }

    func generateSidebarMessage(indentationLevel: Int = 0) -> String {
        let indent = String(repeating: "  ", count: indentationLevel)
        var message = "\(indent)func main() {\n"
        for child in children {
            message += child.generateSidebarMessage(indentationLevel: indentationLevel + 1)
        }
        message += "\(indent)\n"
        return message
    }
}


class InputBlock: ProgrammingBlock {
    func identifier() -> String {
        return "InputBlock"
    }
    
    var variableName: String
    var userInput: String
    var inputType: String  // "int", "bool", "string"
    var children: [ProgrammingBlock] = [] // Implementing as empty since not used
    
    var codeTemplate: String {
        switch inputType {
        case "int", "bool", "string":
            return "\(inputType) \(variableName) = \(userInput)"
        default:
            return "Unknown type"
        }
    }

    func generateCode() -> String {
        return codeTemplate
    }

    // Adapted to protocol but ignores indentationLevel since it's not relevant for InputBlock
    func generateSidebarMessage(indentationLevel: Int = 0) -> String {
        // Simply return the message, ignoring indentation as InputBlock doesn't nest
        return "Input: \(codeTemplate)"
    }

    init(variableName: String = "", userInput: String = "", inputType: String = "") {
        self.variableName = variableName
        self.userInput = userInput
        self.inputType = inputType
    }
}



class VariableBlock: ProgrammingBlock {
    func identifier() -> String {
        return "VariableBlock"
    }
    
    
    var variableName: String
    var value: Any
    var children: [ProgrammingBlock] = [] // Implementing as empty since not used
    
    var codeTemplate: String {
        if let intValue = value as? Int {
            return "\(variableName) = \(intValue)   Integer variable"
        } else if let boolValue = value as? Bool {
            return "\(variableName) = \(boolValue)   Boolean variable"
        } else if let stringValue = value as? String {
            return "\(variableName) = '\(stringValue)'   String variable"
        } else {
            return "\(variableName) = None  # Undefined variable"
        }
    }
    
    func generateCode() -> String {
        return codeTemplate
    }
    
    // Adapted to protocol but ignores indentationLevel since it's not relevant for VariableBlock
    func generateSidebarMessage(indentationLevel: Int = 0) -> String {
        // Simply return the message, ignoring indentation as VariableBlock doesn't nest
        let valueString: String
        if let intValue = value as? Int {
            valueString = String(intValue)
        } else if let boolValue = value as? Bool {
            valueString = String(boolValue)
        } else if let stringValue = value as? String {
            valueString = "\"\(stringValue)\""
        } else {
            valueString = "None"
        }
        return "\(variableName) = \(valueString)  # "
    }
    
    init(variableName: String, value: Any) {
        self.variableName = variableName
        self.value = value
    }
}

class PrintStatementBlock: ProgrammingBlock {
    func identifier() -> String {
        return "PrintStatementBlock"
    }
    
    
    var message: String
    var children: [ProgrammingBlock] = [] // Implementing as empty since not used

    var codeTemplate: String {
        return "print('\(message)')"
    }
    
    func generateCode() -> String {
        return codeTemplate
    }
    
    // Adapted to protocol but ignores indentationLevel since it's not relevant for PrintStatementBlock
    func generateSidebarMessage(indentationLevel: Int = 0) -> String {
        // Simply return the message, ignoring indentation as PrintStatementBlock doesn't nest
        return "print: (\(message))"
    }
    
    init(message: String) {
        self.message = message
    }
}


class IfStatementBlock: ProgrammingBlock {
    func identifier() -> String {
        return "IfStatementBlock"
    }
    
    var condition: String
    var trueBranchOutput: String
    var falseBranchOutput: String
    var children: [ProgrammingBlock] = []
    
    var codeTemplate: String {
        """
        if \(condition) {
            // True branch
            \(trueBranchOutput)
        } else {
            // False branch
            \(falseBranchOutput)
        }
        """
    }
    
    func generateCode() -> String { codeTemplate }
    func generateSidebarMessage(indentationLevel: Int = 0) -> String {
        """
        If : \(condition) {
        True: \(trueBranchOutput),
        False: \(falseBranchOutput) }
    """
    }
    
    init(condition: String, trueBranchOutput: String, falseBranchOutput: String ) {
        self.condition = condition
        self.trueBranchOutput = trueBranchOutput
        self.falseBranchOutput = falseBranchOutput
    }
}
    
    
    
class ForLoopBlock: ProgrammingBlock {
    func identifier() -> String {
        return "ForLoopBlock"
    }
    
        var variableName: String
        var startValue: Int
        var endCondition: String
        var increment: Int
        var loopBodyCode: String?
        var children = [ProgrammingBlock]() // Implementing the children property
        
        var codeTemplate: String {
            _ = increment > 1 ? "\(variableName) += \(increment)" : "\(variableName)++"
            var code = "for \(variableName) in \(startValue)...\(endCondition) {\n"
            for child in children {
                code += child.generateCode() + "\n" // Use child's generateCode for nested structure
            }
            code += "}\n"
            return code
        }
        
        func generateCode() -> String {
            return codeTemplate
        }
        
        func generateSidebarMessage(indentationLevel: Int = 0) -> String {
            let indent = String(repeating: "  ", count: indentationLevel)
            var message = "\(indent)For \(variableName) from \(startValue) to \(endCondition) increment by \(increment)\n"
            
            for child in children {
                message += child.generateSidebarMessage(indentationLevel: indentationLevel + 1) // Recursively generate messages for children
            }
            
            return message
        }
        
        init(variableName: String, startValue: Int, endCondition: String, increment: Int, loopBodyCode: String? = nil) {
            self.variableName = variableName
            self.startValue = startValue
            self.endCondition = endCondition
            self.increment = increment
            self.loopBodyCode = loopBodyCode
        }
    }
    
    
class DefaultBlock: ProgrammingBlock {
    func identifier() -> String {
        return "DefaultBlock"
    }
    
        var children: [ProgrammingBlock] = [] // Required by protocol, but unused for DefaultBlock
        
        var codeTemplate: String {
            // A basic template or an empty string if no code should be generated
            return ""
        }
        
        func generateCode() -> String {
            // Since this is a default block, it might not generate any code
            return ""
        }
        
        // Adapted to include indentationLevel, but it's not used since DefaultBlock doesn't nest blocks
        func generateSidebarMessage(indentationLevel: Int = 0) -> String {
            // Ignoring indentation as DefaultBlock doesn't support nesting
            return ""
        }
    }
    
    

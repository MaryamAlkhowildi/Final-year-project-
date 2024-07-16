//
//  ARAlertController.swift
//  FinalYearProjectLegoLike
//
//  Created by MARYAM ALKHOWILDI on 02/02/2024.
//

import Foundation
import UIKit

class ARAlertController {
    weak var viewController: ViewController?
    
    func presentChallengeExplanation() {
        let alert = UIAlertController(title: "Challenge Explanation",
                                      message: "START the program, declare an INTEGER variable then check IF the variable is greater than 0. If TRUE, print 'positive'; if ELSE, print 'negative'. Explore the ITERATE and inside PRINT 'Hello World' 3 Times",
                                      preferredStyle: .alert)
        
        let acceptAction = UIAlertAction(title: "Accept Challenge", style: .default) { _ in
            // Here you can perform a relevant action, or leave it empty if nothing is needed
            print("Challenge accepted")
        }
        
        alert.addAction(acceptAction)
        
        // If you want to ensure the user cannot dismiss the alert without accepting the challenge
        // you can omit adding a cancel action to make the alert modal.
        
        DispatchQueue.main.async {
            self.viewController?.present(alert, animated: true)
        }
    }
    
    func presentTutorial() {
        let alert = UIAlertController(title: "App Tutorial",
                                      message: "Here's how to navigate the app:\n\n- To add an object, tap the 'ADD' button, select the object, and tap on the scene where you want to place it.\n- To move an object, tap on it and drag it to your desired location.\n- To delete an object, press and hold on it for 1 second; a 'delete' button will appear.\n- Connection points are highlighted for your convenience.\n- Use the 'switch' button to toggle plane detection on and off.\n- Press 'run' to execute your code and see the output.",
                                      preferredStyle: .alert)
        
        let acceptAction = UIAlertAction(title: "GOT IT", style: .default) { _ in

        }
        
        alert.addAction(acceptAction)
        
        // If you want to ensure the user cannot dismiss the alert without accepting the challenge
        // you can omit adding a cancel action to make the alert modal.
        
        DispatchQueue.main.async {
            self.viewController?.present(alert, animated: true)
        }
    }
    
    
    
    func showAddARNodeAlert() {
        let alert = UIAlertController(title: "Select The Block!",
                                      message: nil,
                                      preferredStyle: UIDevice.current.userInterfaceIdiom == .pad ? .alert : .actionSheet)
        
        let startAction = UIAlertAction(title: "Start", style: .default) { _ in
            self.viewController?.sceneName = "Start.usdz"
            print("start block selected")
            
        }
        let inputAction = UIAlertAction(title: "Input", style: .default) { _ in
            self.viewController?.sceneName = "Input.usdz"
            print("input block selected")
            
        }
        let intAction = UIAlertAction(title: "Integer", style: .default) { _ in
            self.viewController?.sceneName = "int.usdz"
            print("int block selected")
            
        }
        let stringAction = UIAlertAction(title: "Charecter", style: .default) { _ in
            self.viewController?.sceneName = "String.usdz"
            print("char block selected")
            
        }
        let BoolAction = UIAlertAction(title: "Boolen", style: .default) { _ in
            self.viewController?.sceneName = "Bool.usdz"
            print("Bool block selected")
            
        }
        let outputAction = UIAlertAction(title: "Print", style: .default) { _ in
            self.viewController?.sceneName = "Print.usdz"
            print("print block selected")
            
        }
        let loopAction = UIAlertAction(title: "Iteration", style: .default) { _ in
            self.viewController?.sceneName = "Loop.usdz"
            print("Loop block selected")
            
        }
        let ifAction = UIAlertAction(title: "if Statement", style: .default) { _ in
            self.viewController?.sceneName = "IfCondition.usdz"
            print("If block selected")
            
        }
        
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        alert.addAction(startAction)
        alert.addAction(inputAction)
        alert.addAction(intAction)
        alert.addAction(stringAction)
        alert.addAction(BoolAction)
        alert.addAction(outputAction)
        alert.addAction(loopAction)
        alert.addAction(ifAction)
        alert.addAction(cancelAction)
        viewController?.present(alert, animated: true, completion: nil)
    }
    
    func showOverlyText(_ text: String, withDuration duration: Int) {
        let alert = UIAlertController(title: nil, message: text, preferredStyle: .alert)
        viewController?.present(alert, animated: true, completion: nil)
        DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(duration)) {
            alert.dismiss(animated: true, completion: nil)
        }
    }
    
    func promptForInput(completion: @escaping (String, String, String) -> Void) {
        let alertController = UIAlertController(title: "Input Type", message: "Select the type of the input.\n" +
                                                "Int Block: Use this to store and work with whole numbers. \n" +
                                                "Bool Block: Use this to store true/false values and control the flow of your program with conditions. \n" +
                                                "String Block: Use this to store and manipulate textual data like words and sentences." , preferredStyle: .alert)
        
        let intAction = UIAlertAction(title: "Int", style: .default) { _ in
            self.promptForVariableNameAndValue(inputType: "int", completion: completion)
        }
        let boolAction = UIAlertAction(title: "Bool", style: .default) { _ in
            self.promptForVariableNameAndValue(inputType: "bool", completion: completion)
        }
        let stringAction = UIAlertAction(title: "String", style: .default) { _ in
            self.promptForVariableNameAndValue(inputType: "string", completion: completion)
        }
        
        alertController.addAction(intAction)
        alertController.addAction(boolAction)
        alertController.addAction(stringAction)
        
        DispatchQueue.main.async {
            self.viewController?.present(alertController, animated: true, completion: nil)
        }
    }
    
    func promptForVariableNameAndValue(inputType: String, completion: @escaping (String, String, String) -> Void) {
        let alertController = UIAlertController(title: "Input Details", message: "Enter a massege for the user", preferredStyle: .alert)
        
        alertController.addTextField { textField in
            textField.placeholder = "Variable name"
        }
        alertController.addTextField { textField in
            textField.placeholder = "Enter the value here"
        }
        
        let submitAction = UIAlertAction(title: "Submit", style: .default) { _ in
            let variableName = alertController.textFields?[0].text ?? ""
            let value = alertController.textFields?[1].text ?? ""
            completion(inputType, variableName, value)
        }
        
        alertController.addAction(submitAction)
        
        DispatchQueue.main.async {
            self.viewController?.present(alertController, animated: true, completion: nil)
        }
    }
    
    
    // Example modification of your promptForInt to also capture a variable name
    func promptForIntAndVariableName(completion: @escaping (String, Int?) -> Void) {
        viewController?.sceneView.scene.isPaused = true
        let alertController = UIAlertController(title: "Define Integer Variable", message: "Enter a variable name and its integer value, this to store and work with whole numbers.", preferredStyle: .alert)
        
        alertController.addTextField { textField in
            textField.placeholder = "Variable name"
        }
        
        alertController.addTextField { textField in
            textField.placeholder = "Integer value"
            textField.keyboardType = .numberPad
        }
        
        let submitAction = UIAlertAction(title: "Submit", style: .default) { _ in
            let variableName = alertController.textFields?.first?.text ?? "variable"
            let inputValue = alertController.textFields?.last?.text
            let intValue = Int(inputValue ?? "")
            completion(variableName, intValue)
        }
        
        alertController.addAction(submitAction)
        alertController.addAction(UIAlertAction(title: "Cancel", style: .cancel) { _ in completion("", nil) })
        
        DispatchQueue.main.async {
            self.viewController?.present(alertController, animated: true, completion: nil)
            self.viewController?.sceneView.scene.isPaused = false
        }
    }
    
    func promptForStringAndVariableName(completion: @escaping (String, String?) -> Void) {
        let alertController = UIAlertController(title: "Define String Variable", message: "Enter a variable name and its string value, this to store and manipulate textual data like words and sentences.", preferredStyle: .alert)
        
        alertController.addTextField { textField in
            textField.placeholder = "Variable name"
        }
        
        alertController.addTextField { textField in
            textField.placeholder = "String value"
            // No specific keyboard type needed for string input
        }
        
        let submitAction = UIAlertAction(title: "Submit", style: .default) { _ in
            let variableName = alertController.textFields?.first?.text ?? "variable"
            let stringValue = alertController.textFields?.last?.text
            completion(variableName, stringValue) // Pass back the variable name and string value
        }
        
        alertController.addAction(submitAction)
        alertController.addAction(UIAlertAction(title: "Cancel", style: .cancel) { _ in completion("", nil) })
        
        DispatchQueue.main.async {
            self.viewController?.present(alertController, animated: true, completion: nil)
        }
    }
    
    func promptForBoolAndVariableName(completion: @escaping (String, Bool?) -> Void) {
        let alertController = UIAlertController(title: "Define Boolean Variable", message: "Enter a variable name and choose a boolean value, this to store true/false values and control the flow of your program with conditions.", preferredStyle: .alert)
        
        alertController.addTextField { textField in
            textField.placeholder = "Variable name"
        }
        
        let trueAction = UIAlertAction(title: "True", style: .default) { _ in
            let variableName = alertController.textFields?.first?.text ?? "variable"
            completion(variableName, true) // Pass back the variable name and true for the boolean value
        }
        
        let falseAction = UIAlertAction(title: "False", style: .default) { _ in
            let variableName = alertController.textFields?.first?.text ?? "variable"
            completion(variableName, false) // Pass back the variable name and false for the boolean value
        }
        
        alertController.addAction(trueAction)
        alertController.addAction(falseAction)
        alertController.addAction(UIAlertAction(title: "Cancel", style: .cancel) { _ in completion("", nil) })
        
        DispatchQueue.main.async {
            self.viewController?.present(alertController, animated: true, completion: nil)
        }
    }
    
    func promptForPrint(completion: @escaping (String) -> Void) {
        let alertController = UIAlertController(title: "Print Statement", message: "Enter the message to print", preferredStyle: .alert)
        
        alertController.addTextField { textField in
            textField.placeholder = "Message"
        }
        
        let submitAction = UIAlertAction(title: "Submit", style: .default) { _ in
            let message = alertController.textFields?.first?.text ?? "default message"
            completion(message)
        }
        
        alertController.addAction(submitAction)
        alertController.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        
        DispatchQueue.main.async {
            self.viewController?.present(alertController, animated: true, completion: nil)
        }
    }
    
    func promptForCondition(completion: @escaping (String, String, String) -> Void) {
        let alertController = UIAlertController(
            title: "If Statement Condition",
            message: "Enter the condition for the if statement.",
            preferredStyle: .alert
        )
        
        alertController.addTextField { textField in
            textField.placeholder = "Condition (e.g., x > 10)"
        }
        
        let submitAction = UIAlertAction(title: "Submit", style: .default) { [weak self] _ in
            guard let condition = alertController.textFields?.first?.text, !condition.isEmpty else {
                completion("cancelled", "", "")
                return
            }
            
            // Prompt for true branch outcome
            self?.promptForBranchOutcome(title: "True Branch Output", message: "Enter the output for the true branch of the if statement.") { trueBranchOutput in
                // Prompt for false branch outcome
                self?.promptForBranchOutcome(title: "False Branch Output", message: "Enter the output for the false branch of the if statement.") { falseBranchOutput in
                    completion(condition, trueBranchOutput, falseBranchOutput)
                }
            }
        }
        
        alertController.addAction(submitAction)
        alertController.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { _ in completion("cancelled", "", "") }))
        
        DispatchQueue.main.async {
            self.viewController?.present(alertController, animated: true, completion: nil)
        }
    }
    
    func promptForBranchOutcome(title: String, message: String, completion: @escaping (String) -> Void) {
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        
        alertController.addTextField { textField in
            textField.placeholder = "Output"
        }
        
        let submitAction = UIAlertAction(title: "Submit", style: .default) { _ in
            let output = alertController.textFields?.first?.text ?? ""
            completion(output)
        }
        
        alertController.addAction(submitAction)
        alertController.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { _ in completion("") }))
        
        DispatchQueue.main.async {
            self.viewController?.present(alertController, animated: true, completion: nil)
        }
    }
    
    
    
    
    func promptForLoopDetails(completion: @escaping (String, Int, String, Int) -> Void) {
        let alertController = UIAlertController(
            title: "For Loop Details",
            message: "Set the loop starting value, end condition, and increment.",
            preferredStyle: .alert
        )
        
        alertController.addTextField { textField in
            textField.placeholder = "Variable name (e.g., i)"
            textField.text = "i"  // Default value
        }
        
        alertController.addTextField { textField in
            textField.placeholder = "Start value (e.g., 0)"
            textField.keyboardType = .numberPad
        }
        
        alertController.addTextField { textField in
            textField.placeholder = "End condition (e.g., 10)"
            textField.keyboardType = .numberPad
        }
        
        alertController.addTextField { textField in
            textField.placeholder = "Increment (e.g., 1)"
            textField.keyboardType = .numberPad
        }
        
        let submitAction = UIAlertAction(title: "Submit", style: .default) { _ in
            let variableName = alertController.textFields?[0].text ?? "i"
            let startValue = Int(alertController.textFields?[1].text ?? "0") ?? 0
            let endCondition = alertController.textFields?[2].text ?? "10"
            let increment = Int(alertController.textFields?[3].text ?? "1") ?? 1
            completion(variableName, startValue, endCondition, increment)
        }
        
        alertController.addAction(submitAction)
        alertController.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        
        DispatchQueue.main.async {
            self.viewController?.present(alertController, animated: true, completion: nil)
        }
    }
}

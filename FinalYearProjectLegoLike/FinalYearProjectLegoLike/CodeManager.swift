//
//  CodeManager.swift
//  FinalYearProjectLegoLike
//
//  Created by MARYAM ALKHOWILDI on 09/03/2024.
//

import Foundation


class CodeManager {
    var blocks: [ProgrammingBlock] = []
    var intValue: Int?
    var variableName: String? 
    var userCondition: String?
    weak var viewController: ViewController?
    
    enum ConnectionPoint {
        case top
        case bottom
        case right
    }


    func addBlock(_ block: ProgrammingBlock, to parentBlock: ProgrammingBlock?, at connectionPoint: ConnectionPoint) {
        print("Attempting to add block at connectionPoint: \(connectionPoint)")

        if let parent = parentBlock, parent.identifier() == "ForLoopBlock" && connectionPoint != .right {
            print("Error: ForLoopBlock can only have blocks added to the right.")
            return
        }

        switch connectionPoint {
        case .right:
            if let parent = parentBlock {
                parent.children.append(block)
                print("Adding block inside the parent.")
                // Update the parent block in the codeManager.blocks array
                if let index = blocks.firstIndex(where: { $0 === parent }) {
                    blocks[index] = parent
                }
            }
        case .bottom, .top:
            // For simplicity, handling bottom and right similarly for non-loop blocks
            blocks.append(block)
            print("Adding block to the bottom or top.")
        }
        print("Operation completed.")
    }


    func runChallenge() -> String {
        // Basic validation and execution simulation
        guard let n = intValue else {
            return "Error: No input provided."
        }
        
        // Assuming validateBlocks() and simulateChallengeExecution(input:) are implemented
        let hasRequiredBlocks = validateBlocks()
        if !hasRequiredBlocks {
            return "Error: Missing or incorrect block sequence."
        }
        
        return simulateChallengeExecution(input: n)
    }
    
    
 /*   private func validateBlocks() -> Bool {
        // Step 1: Check for the correct total number of blocks
        if blocks.count < 3 {
            return false // Ensure there are at least 6 blocks
        }

        // Step 2: Validate the specific sequence of block types
        if !(blocks[0] is StartBlock) {
            return false // The sequence does not match the required setup
            
        }
          // Check for exactly one PrintBlock following the ForLoopBlock that prints "Hello World"
       //   if let printBlock = blocks[1] as? PrintStatementBlock, printBlock.message == "H" {
              // The PrintBlock is correctly placed and configured
      //    } else {
    //          return false // Missing PrintBlock, incorrectly placed, or it doesn't print "Hello World"
       //   }



          // All checks passed, indicating a valid block sequence as per challenge requirements
          return true
      } */
    private func validateBlocks() -> Bool {
        // Step 1: Check for the correct total number of blocks
        if blocks.count < 5 {
            return false // Adjusted to account for the additional ForLoopBlock requirement
        }

        // Step 2: Validate the specific sequence of block types
        if !(blocks[0] is StartBlock && blocks[1] is VariableBlock && blocks[2] is IfStatementBlock) {
            return false // The sequence does not match the required setup
        }

        // Validate IfStatementBlock for containing "positive" or "negative"
        if let ifBlock = blocks[2] as? IfStatementBlock {
            let containsCorrectOutputs = ifBlock.trueBranchOutput.contains("positive") || ifBlock.falseBranchOutput.contains("negative") ||
                                         ifBlock.falseBranchOutput.contains("positive") || ifBlock.trueBranchOutput.contains("negative")
            
            if !containsCorrectOutputs {
                return false // IfStatementBlock doesn't have the correct outputs
            }
        } else {
            return false // Missing IfStatementBlock in the sequence
        }

        // Validate ForLoopBlock is set to 3 iterations with an increment of 1
        if let forLoopBlock = blocks.first(where: { $0 is ForLoopBlock }) as? ForLoopBlock {
            // Assuming 'totalIterations' or a similar mechanism to determine the loop runs 3 times.
            // This might need to be adjusted based on your actual ForLoopBlock implementation.
            let correctSetup = forLoopBlock.endCondition == "3" && forLoopBlock.increment == 1
            
            if !correctSetup {
                return false // The ForLoopBlock isn't configured as required
            }
        } else {
            return false // Missing ForLoopBlock
        }

        // Check for a PrintBlock that prints "Hello World"
        if let printBlock = blocks.first(where: { $0 is PrintStatementBlock }) as? PrintStatementBlock, printBlock.message == "Hello World" {
            // The PrintBlock is correctly placed and configured
        } else {
            return false // Missing PrintBlock, incorrectly placed, or it doesn't print "Hello World"
        }

        // All checks passed, indicating a valid block sequence as per the updated challenge requirements
        return true
    }



    private func simulateChallengeExecution(input: Int) -> String {
        var outputLines: [String] = []
        
        // Simulate the IfBlock based on input

        outputLines.append(input >= 0 ? "positive" : "negative")
        
        // Simulate the LoopBlock
        for _ in 1...3 {
            outputLines.append("Hello World")
        }
        
        return "\n\n\n\n\n\n\nOutput:\n" + outputLines.joined(separator: "\n")
    }
}

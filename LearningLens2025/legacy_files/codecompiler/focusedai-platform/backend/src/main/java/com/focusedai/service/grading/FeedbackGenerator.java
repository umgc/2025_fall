package com.focusedai.service.grading;

import com.focusedai.dto.ExecutionResultDto;
import com.focusedai.dto.GradingRequestDto;
import org.springframework.stereotype.Service;

import java.util.Map;

@Service
public class FeedbackGenerator {

    public String generateFeedback(ExecutionResultDto executionResult, GradingRequestDto request) {
        StringBuilder feedback = new StringBuilder();
        String strategy = executionResult.getUsedStrategy();
        
        feedback.append("## Code Execution Results\n\n");
        
        if (executionResult.isSuccess()) {
            feedback.append("✅ **Execution Status:** Successful\n");
            feedback.append(String.format("⏱️ **Execution Time:** %d ms\n", executionResult.getExecutionTimeMs()));
            feedback.append(String.format("💾 **Memory Usage:** %d MB\n", executionResult.getMemoryUsedMb()));
            
            if (executionResult.isTestPassed()) {
                feedback.append("🎯 **Test Result:** PASSED\n");
                feedback.append("🎉 Your program output matches the expected result perfectly!\n\n");
            } else {
                feedback.append("❌ **Test Result:** FAILED\n");
                feedback.append(String.format("📊 **Output Similarity:** %.1f%%\n", executionResult.getOutputSimilarity()));
                feedback.append("Your program runs but produces different output than expected.\n\n");
            }
            
            appendStrategySpecificFeedback(feedback, strategy, executionResult);
            
        } else {
            feedback.append("❌ **Execution Status:** Failed\n");
            feedback.append("**Error Details:**\n```\n");
            feedback.append(executionResult.getError());
            feedback.append("\n```\n\n");
            feedback.append("**Common Solutions:**\n");
            feedback.append("- Check for compilation errors\n");
            feedback.append("- Verify class and method names\n");
            feedback.append("- Ensure proper imports\n");
            feedback.append("- Test your code locally first\n\n");
        }
        
        if (!executionResult.getOutput().isEmpty()) {
            feedback.append("**Your Program Output:**\n```\n");
            feedback.append(executionResult.getOutput());
            feedback.append("\n```\n\n");
        }
        
        if (request.getExpectedOutput() != null && !request.getExpectedOutput().isEmpty()) {
            feedback.append("**Expected Output:**\n```\n");
            feedback.append(request.getExpectedOutput());
            feedback.append("\n```\n");
        }
        
        return feedback.toString();
    }

    public String generateErrorFeedback(ExecutionResultDto executionResult) {
        StringBuilder feedback = new StringBuilder();
        feedback.append("## Execution Failed\n\n");
        feedback.append("❌ Your code could not be executed successfully.\n\n");
        
        if (executionResult.getError() != null && !executionResult.getError().isEmpty()) {
            feedback.append("**Error Details:**\n```\n");
            feedback.append(executionResult.getError());
            feedback.append("\n```\n\n");
        }
        
        feedback.append("**Next Steps:**\n");
        feedback.append("1. Review the error message above\n");
        feedback.append("2. Check for syntax and compilation errors\n");
        feedback.append("3. Verify your class and method names\n");
        feedback.append("4. Test your code in your local development environment\n");
        feedback.append("5. Ask for help if you're stuck!\n");
        
        return feedback.toString();
    }

    private void appendStrategySpecificFeedback(StringBuilder feedback, String strategy, ExecutionResultDto result) {
        switch (strategy) {
            case "METHOD_CALL":
                feedback.append("🔧 **Execution Strategy:** Method Call Testing\n");
                feedback.append("Your code was tested by calling specific methods directly.\n\n");
                break;
            case "UNIT_TEST":
                feedback.append("🧪 **Execution Strategy:** Unit Testing\n");
                feedback.append("Your code was evaluated using automated unit tests.\n\n");
                break;
            case "FILE_IO":
                feedback.append("📁 **Execution Strategy:** File I/O Testing\n");
                feedback.append("Your code was tested with file input/output operations.\n\n");
                break;
            case "INTERACTIVE":
                feedback.append("💬 **Execution Strategy:** Interactive Testing\n");
                feedback.append("Your code was tested with interactive user input.\n\n");
                break;
            case "STDIN_STDOUT":
            default:
                feedback.append("📥 **Execution Strategy:** Standard Input/Output\n");
                feedback.append("Your code was tested with standard console input/output.\n\n");
                break;
        }
    }
}
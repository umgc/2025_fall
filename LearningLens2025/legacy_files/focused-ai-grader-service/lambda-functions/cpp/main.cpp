#include <aws/lambda-runtime/runtime.h>
#include <iostream>
#include <string>
#include <sstream>
#include <regex>
#include <fstream>
#include <cstdlib>
#include <unistd.h>
#include <sys/wait.h>
#include <sys/stat.h>  // For mkdir
#include <sys/types.h> // For mkdir
#include <chrono>

using namespace aws::lambda_runtime;

class CppExecutor {
public:
    invocation_response execute(invocation_request const& request) {
        auto startTime = std::chrono::high_resolution_clock::now();
        
        try {
            std::string payload = request.payload;
            
            // Handle HTTP Function URL format - extract body
            std::string actualPayload = payload;
            if (payload.find("\"body\"") != std::string::npos) {
                size_t bodyPos = payload.find("\"body\":");
                if (bodyPos != std::string::npos) {
                    size_t startQuote = payload.find("\"", bodyPos + 7);
                    if (startQuote != std::string::npos) {
                        startQuote++; // Skip the opening quote
                        size_t endQuote = startQuote;
                        int escapeCount = 0;
                        while (endQuote < payload.length()) {
                            if (payload[endQuote] == '\\') {
                                escapeCount++;
                            } else if (payload[endQuote] == '"' && escapeCount % 2 == 0) {
                                break;
                            } else {
                                escapeCount = 0;
                            }
                            endQuote++;
                        }
                        
                        if (endQuote < payload.length()) {
                            actualPayload = payload.substr(startQuote, endQuote - startQuote);
                            // Unescape the JSON
                            actualPayload = unescapeJson(actualPayload);
                        }
                    }
                }
            }
            
            // Extract files content
            std::string code = extractCodeContent(actualPayload);
            if (code.empty()) {
                return createErrorResponse("No code content found");
            }
            
            // Execute the code
            ExecutionResult result = executeCppCode(code, "main.cpp");
            
            auto endTime = std::chrono::high_resolution_clock::now();
            auto duration = std::chrono::duration_cast<std::chrono::milliseconds>(endTime - startTime);
            
            // Create response
            std::string response = createJsonResponse(result, duration.count());
            
            // Check if this is a Function URL request and wrap in HTTP response
            if (payload.find("\"body\"") != std::string::npos) {
                return createHttpResponse(response);
            } else {
                return invocation_response::success(response, "application/json");
            }
            
        } catch (const std::exception& e) {
            auto endTime = std::chrono::high_resolution_clock::now();
            auto duration = std::chrono::duration_cast<std::chrono::milliseconds>(endTime - startTime);
            
            ExecutionResult errorResult;
            errorResult.success = false;
            errorResult.output = "";
            errorResult.error = e.what();
            
            std::string response = createJsonResponse(errorResult, duration.count());
            return invocation_response::success(response, "application/json");
        }
    }
    
private:
    struct ExecutionResult {
        bool success = false;
        std::string output = "";
        std::string error = "";
    };
    
    std::string unescapeJson(const std::string& input) {
        std::string result;
        for (size_t i = 0; i < input.length(); i++) {
            if (input[i] == '\\' && i + 1 < input.length()) {
                switch (input[i + 1]) {
                    case 'n': result += '\n'; i++; break;
                    case 't': result += '\t'; i++; break;
                    case 'r': result += '\r'; i++; break;
                    case '\\': result += '\\'; i++; break;
                    case '"': result += '"'; i++; break;
                    default: result += input[i]; break;
                }
            } else {
                result += input[i];
            }
        }
        return result;
    }
    
    std::string extractCodeContent(const std::string& payload) {
        // Look for "content" field
        size_t contentPos = payload.find("\"content\"");
        if (contentPos == std::string::npos) return "";
        
        contentPos = payload.find("\"", contentPos + 9);
        if (contentPos == std::string::npos) return "";
        contentPos++;
        
        size_t endPos = contentPos;
        while (endPos < payload.length()) {
            if (payload[endPos] == '"' && (endPos == 0 || payload[endPos - 1] != '\\')) {
                break;
            }
            endPos++;
        }
        
        std::string content = payload.substr(contentPos, endPos - contentPos);
        return unescapeJson(content);
    }
    
    ExecutionResult executeCppCode(const std::string& code, const std::string& filename) {
        // Create temporary directory
        std::string tempDir = "/tmp/cpp_execution_" + std::to_string(getpid());
        if (::mkdir(tempDir.c_str(), 0755) != 0) {
            ExecutionResult result;
            result.success = false;
            result.error = "Failed to create temporary directory";
            return result;
        }
        
        try {
            // Write source code
            std::string sourceFile = tempDir + "/" + filename;
            std::ofstream file(sourceFile);
            if (!file) {
                ExecutionResult result;
                result.success = false;
                result.error = "Failed to create source file";
                return result;
            }
            
            std::string enhancedCode = addHeaders(code);
            file << enhancedCode;
            file.close();
            
            // Compile
            std::string executable = tempDir + "/program";
            std::string compileCmd = "g++ -std=c++17 -O2 " + sourceFile + " -o " + executable + " 2>&1";
            
            FILE* pipe = popen(compileCmd.c_str(), "r");
            if (!pipe) {
                ExecutionResult result;
                result.success = false;
                result.error = "Failed to run compiler";
                return result;
            }
            
            std::string compileOutput;
            char buffer[128];
            while (fgets(buffer, sizeof(buffer), pipe) != nullptr) {
                compileOutput += buffer;
            }
            
            int compileStatus = pclose(pipe);
            
            if (compileStatus != 0) {
                ExecutionResult result;
                result.success = false;
                result.error = "Compilation failed: " + compileOutput;
                return result;
            }
            
            // Execute
            std::string execCmd = "timeout 30s " + executable + " 2>&1";
            pipe = popen(execCmd.c_str(), "r");
            if (!pipe) {
                ExecutionResult result;
                result.success = false;
                result.error = "Failed to execute program";
                return result;
            }
            
            std::string output;
            while (fgets(buffer, sizeof(buffer), pipe) != nullptr) {
                output += buffer;
            }
            
            pclose(pipe);
            
            // Clean up
            std::system(("rm -rf " + tempDir).c_str());
            
            ExecutionResult result;
            result.success = true;
            result.output = output;
            return result;
            
        } catch (const std::exception& e) {
            std::system(("rm -rf " + tempDir).c_str());
            ExecutionResult result;
            result.success = false;
            result.error = "Execution failed: " + std::string(e.what());
            return result;
        }
    }
    
    std::string addHeaders(const std::string& code) {
        std::string headers = 
            "#include <iostream>\n"
            "#include <vector>\n"
            "#include <algorithm>\n"
            "#include <string>\n"
            "#include <map>\n"
            "#include <set>\n"
            "#include <queue>\n"
            "#include <stack>\n"
            "#include <cmath>\n"
            "#include <iomanip>\n"
            "using namespace std;\n\n";
        
        if (code.find("int main") != std::string::npos) {
            return headers + code;
        }
        
        return headers + "int main() {\n" + code + "\nreturn 0;\n}";
    }
    
    std::string escapeJson(const std::string& input) {
        std::string result;
        for (char c : input) {
            switch (c) {
                case '"': result += "\\\""; break;
                case '\\': result += "\\\\"; break;
                case '\n': result += "\\n"; break;
                case '\r': result += "\\r"; break;
                case '\t': result += "\\t"; break;
                default: result += c; break;
            }
        }
        return result;
    }
    
    std::string createJsonResponse(const ExecutionResult& result, long executionTimeMs) {
        std::ostringstream response;
        response << "{"
                << "\"success\": " << (result.success ? "true" : "false") << ","
                << "\"output\": \"" << escapeJson(result.output) << "\","
                << "\"error\": \"" << escapeJson(result.error) << "\","
                << "\"language\": \"CPP\","
                << "\"executionTimeMs\": " << executionTimeMs << ","
                << "\"container\": \"cpp:gcc\""
                << "}";
        return response.str();
    }
    
    invocation_response createHttpResponse(const std::string& jsonResponse) {
        std::ostringstream httpResponse;
        httpResponse << "{"
                   << "\"statusCode\": 200,"
                   << "\"headers\": {"
                   << "\"Content-Type\": \"application/json\","
                   << "\"Access-Control-Allow-Origin\": \"*\","
                   << "\"Access-Control-Allow-Methods\": \"POST\","
                   << "\"Access-Control-Allow-Headers\": \"*\""
                   << "},"
                   << "\"body\": \"" << escapeJson(jsonResponse) << "\""
                   << "}";
        return invocation_response::success(httpResponse.str(), "application/json");
    }
    
    invocation_response createErrorResponse(const std::string& errorMessage) {
        std::ostringstream response;
        response << "{"
                << "\"success\": false,"
                << "\"output\": \"\","
                << "\"error\": \"" << escapeJson(errorMessage) << "\","
                << "\"language\": \"CPP\""
                << "}";
        return invocation_response::success(response.str(), "application/json");
    }
};

int main() {
    run_handler([](invocation_request const& request) {
        CppExecutor executor;
        return executor.execute(request);
    });
    return 0;
}

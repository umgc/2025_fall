import json
import sys
import io
import traceback
import tempfile
import os
import subprocess
import time
from contextlib import redirect_stdout, redirect_stderr

def lambda_handler(event, context):
    start_time = time.time()
    
    try:
        # Parse the request
        files = event.get('files', [])
        if not files:
            return create_error_response('No files provided')
        
        # Get the main Python file
        main_file = files[0]
        code = main_file.get('content', '')
        filename = main_file.get('filename', 'script.py')
        
        # Security validation
        if not is_code_safe(code):
            return create_error_response('Code contains potentially dangerous operations')
        
        # Execute the code in a safe environment
        output = execute_python_code(code)
        
        execution_time = int((time.time() - start_time) * 1000)
        
        return {
            'success': True,
            'output': output,
            'error': '',
            'language': 'PYTHON',
            'executionTimeMs': execution_time,
            'container': 'python:3.9'
        }
        
    except Exception as e:
        execution_time = int((time.time() - start_time) * 1000)
        return {
            'success': False,
            'output': '',
            'error': str(e),
            'language': 'PYTHON',
            'executionTimeMs': execution_time
        }

def is_code_safe(code):
    """Basic security check for dangerous operations"""
    dangerous_patterns = [
        'import os',
        'import subprocess',
        'import sys',
        '__import__',
        'eval(',
        'exec(',
        'open(',
        'file(',
        'input(',
        'raw_input(',
    ]
    
    code_lower = code.lower()
    for pattern in dangerous_patterns:
        if pattern in code_lower:
            return False
    return True

def execute_python_code(code):
    """Execute Python code and capture output"""
    # Create string buffers for stdout and stderr
    stdout_buffer = io.StringIO()
    stderr_buffer = io.StringIO()
    
    try:
        # Redirect stdout and stderr
        with redirect_stdout(stdout_buffer), redirect_stderr(stderr_buffer):
            # Create a restricted execution environment
            safe_globals = {
                '__builtins__': {
                    'print': print,
                    'len': len,
                    'str': str,
                    'int': int,
                    'float': float,
                    'bool': bool,
                    'list': list,
                    'dict': dict,
                    'tuple': tuple,
                    'set': set,
                    'range': range,
                    'enumerate': enumerate,
                    'zip': zip,
                    'sum': sum,
                    'max': max,
                    'min': min,
                    'abs': abs,
                    'round': round,
                }
            }
            
            # Execute the code
            exec(code, safe_globals)
        
        # Get outputs
        stdout_content = stdout_buffer.getvalue()
        stderr_content = stderr_buffer.getvalue()
        
        if stderr_content:
            raise Exception(stderr_content)
            
        return stdout_content
        
    except Exception as e:
        stderr_content = stderr_buffer.getvalue()
        if stderr_content:
            raise Exception(stderr_content)
        else:
            raise e

def create_error_response(error_message):
    return {
        'success': False,
        'output': '',
        'error': error_message,
        'language': 'PYTHON'
    }

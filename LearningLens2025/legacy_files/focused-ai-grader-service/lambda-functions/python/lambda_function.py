import json
import sys
import io
import traceback
import time
import builtins
from contextlib import redirect_stdout, redirect_stderr

def lambda_handler(event, context):
    start_time = time.time()
    
    try:
        # Handle Function URL format (HTTP request)
        if 'body' in event:
            if isinstance(event['body'], str):
                body = json.loads(event['body'])
            else:
                body = event['body']
        else:
            # Direct invoke format
            body = event
        
        # Parse the request
        files = body.get('files', [])
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
        
        result = {
            'success': True,
            'output': output,
            'error': '',
            'language': 'PYTHON',
            'executionTimeMs': execution_time,
            'container': 'python:3.9'
        }
        
        # Return format for Function URL
        if 'body' in event:
            return {
                'statusCode': 200,
                'headers': {
                    'Content-Type': 'application/json',
                    'Access-Control-Allow-Origin': '*',
                    'Access-Control-Allow-Methods': 'POST',
                    'Access-Control-Allow-Headers': '*'
                },
                'body': json.dumps(result)
            }
        else:
            # Direct invoke format
            return result
        
    except Exception as e:
        execution_time = int((time.time() - start_time) * 1000)
        error_result = {
            'success': False,
            'output': '',
            'error': str(e),
            'language': 'PYTHON',
            'executionTimeMs': execution_time
        }
        
        if 'body' in event:
            return {
                'statusCode': 200,
                'headers': {
                    'Content-Type': 'application/json',
                    'Access-Control-Allow-Origin': '*'
                },
                'body': json.dumps(error_result)
            }
        else:
            return error_result

def is_code_safe(code):
    """Basic security check for dangerous operations"""
    dangerous_patterns = [
        'import os',
        'import subprocess',
        'import sys',
        '__import__',
        'eval(',
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
    """Execute Python code and capture output with complete built-ins"""
    stdout_buffer = io.StringIO()
    stderr_buffer = io.StringIO()
    
    try:
        with redirect_stdout(stdout_buffer), redirect_stderr(stderr_buffer):
            # Create a more complete execution environment
            safe_globals = {
                '__builtins__': {
                    # Essential built-ins for class definition
                    '__build_class__': builtins.__build_class__,
                    '__name__': '__main__',
                    
                    # Basic functions
                    'print': print,
                    'len': len,
                    'str': str,
                    'int': int,
                    'float': float,
                    'bool': bool,
                    'type': type,
                    'isinstance': isinstance,
                    'issubclass': issubclass,
                    'hasattr': hasattr,
                    'getattr': getattr,
                    'setattr': setattr,
                    'delattr': delattr,
                    'callable': callable,
                    
                    # Data structures
                    'list': list,
                    'dict': dict,
                    'tuple': tuple,
                    'set': set,
                    'frozenset': frozenset,
                    
                    # Iteration and sequences
                    'range': range,
                    'enumerate': enumerate,
                    'zip': zip,
                    'iter': iter,
                    'next': next,
                    'reversed': reversed,
                    'sorted': sorted,
                    'slice': slice,
                    
                    # Math functions
                    'sum': sum,
                    'max': max,
                    'min': min,
                    'abs': abs,
                    'round': round,
                    'pow': pow,
                    'divmod': divmod,
                    
                    # Conversion functions
                    'ord': ord,
                    'chr': chr,
                    'bin': bin,
                    'oct': oct,
                    'hex': hex,
                    'repr': repr,
                    'ascii': ascii,
                    'format': format,
                    
                    # Functional programming
                    'map': map,
                    'filter': filter,
                    'any': any,
                    'all': all,
                    
                    # Object oriented
                    'property': property,
                    'staticmethod': staticmethod,
                    'classmethod': classmethod,
                    'super': super,
                    'vars': vars,
                    'dir': dir,
                    'id': id,
                    
                    # Exceptions
                    'Exception': Exception,
                    'ValueError': ValueError,
                    'TypeError': TypeError,
                    'IndexError': IndexError,
                    'KeyError': KeyError,
                    'AttributeError': AttributeError,
                    'NameError': NameError,
                    'ZeroDivisionError': ZeroDivisionError,
                }
            }
            
            # Execute the code
            exec(code, safe_globals)
        
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

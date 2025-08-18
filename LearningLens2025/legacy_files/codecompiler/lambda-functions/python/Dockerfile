FROM public.ecr.aws/lambda/python:3.9

# Copy requirements first for better caching
COPY requirements.txt .
RUN pip install -r requirements.txt

# Copy function code
COPY lambda_function.py ${LAMBDA_TASK_ROOT}

# Set the CMD to your handler
CMD [ "lambda_function.lambda_handler" ]

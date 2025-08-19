FROM public.ecr.aws/lambda/nodejs:18

# Copy package.json and install dependencies
COPY package.json ${LAMBDA_TASK_ROOT}
RUN npm install

# Copy function code
COPY index.js ${LAMBDA_TASK_ROOT}

# Set the CMD to your handler
CMD [ "index.handler" ]

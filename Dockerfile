FROM public.ecr.aws/lambda/nodejs:20

# Copy package.json and package-lock.json (if present)
COPY package*.json ${LAMBDA_TASK_ROOT}/

# Install production dependencies
RUN npm ci --only=production

# Copy scanner and handler code
COPY scanner.js server.js lambda.js ${LAMBDA_TASK_ROOT}/

# Set the CMD to your handler (filename.method)
CMD [ "lambda.handler" ]

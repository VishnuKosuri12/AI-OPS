# 1. Use the official AWS Lambda Python base image
FROM public.ecr.aws/lambda/python:3.12

# 2. Copy your Python scripts into the container
# AWS Lambda looks for code in the ${LAMBDA_TASK_ROOT} directory
COPY app.py portals.py ${LAMBDA_TASK_ROOT}/

# 3. If you had a requirements.txt, you would uncomment these lines:
# COPY requirements.txt .
# RUN pip install -r requirements.txt

# 4. Set the CMD to your handler function
# Format: [filename].[function_name]
CMD [ "app.Happy_new_year" ]
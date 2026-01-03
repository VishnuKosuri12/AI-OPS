# Use a lightweight Python base image
FROM python:3.12-slim

# Set the working directory inside the container
WORKDIR / src/

# Copy the requirements file and install dependencies
# Note: Since Boto3 is the only dependency, we install it directly
RUN pip install --no-cache-dir boto3

# Copy your Python script into the container
COPY app.py .

# Set the command to run your script
# This triggers the 'if __name__ == "__main__":' block we added earlier
CMD ["python", "app.py"]
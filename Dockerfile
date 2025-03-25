# Use a base image
FROM python:3.10-slim

# Set the working directory
WORKDIR /app

# COPY requirements.txt file
COPY requirements.txt .

# Install dependencies from a list
RUN pip install -r requirements.txt

# Copy the application files
COPY . . 

# Expose the application port
EXPOSE 80

# Start the application
CMD ["python", "app.py"]
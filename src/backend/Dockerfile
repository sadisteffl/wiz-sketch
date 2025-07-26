# docker
FROM python:3.9-slim

WORKDIR /app

COPY requirements.txt ./
RUN pip install --no-cache-dir -r requirements.txt

COPY . .

# This line needs to be added
RUN echo "This file is required for the Wiz Technical Exercise." > wizexercise.txt

EXPOSE 5000
CMD ["python", "main.py"]
FROM nvidia/cuda:11.8.0-runtime-ubuntu20.04

WORKDIR /app

RUN apt-get update && \
    apt-get install -y python3-pip python3-dev libglib2.0-0 libsm6 libxext6 libxrender-dev && \
    rm -rf /var/lib/apt/lists/*

COPY requirements.txt .
RUN pip3 install --no-cache-dir -r requirements.txt

COPY . .

RUN echo "This container is part of the Wiz Field Tech Exercise." > wizexercise.txt

CMD ["python3", "main.py"]

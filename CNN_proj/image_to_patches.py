import serial
import time
from PIL import Image
import numpy as np
import sys
import os


SERIAL_PORT = "/dev/serial0"

# Initialize UART
try:
    ser = serial.Serial(SERIAL_PORT, baudrate=115200, timeout=1)
except serial.SerialException as e:
    print(f"Error: {e}")
    sys.exit(1)

# CNN class labels
fruit_classes = [
    "Apple", "Banana", "Cherry", "Date", "Elderberry",
    "Fig", "Grape", "Honeydew", "Indian Fig", "Jackfruit",
    "Kiwi", "Lemon", "Mango", "Nectarine", "Orange",
    "Papaya", "Quince", "Raspberry", "Strawberry", "Tomato"
]

def send_patch(image_path):
    if not os.path.exists(image_path):
        print(f"File not found: {image_path}")
        return

    print("Preparing image patch...")
    img = Image.open(image_path).convert('L').resize((32, 32))
    pixels = np.array(img, dtype=np.uint8)

    print("Sending image patch to FPGA...")
    for val in pixels.flatten():
        ser.write(bytes([val]))
        time.sleep(0.001)  # delay to prevent overflow

def receive_class():
    print("Waiting for classification result from FPGA...")
    while True:
        byte = ser.read()
        if byte:
            class_idx = int.from_bytes(byte, byteorder='big')
            if 0 <= class_idx < len(fruit_classes):
                print(f"\nPrediction: {fruit_classes[class_idx]}")
            else:
                print(f"Received invalid class index: {class_idx}")
            break

if __name__ == "__main__":
    if len(sys.argv) != 2:
        print("Usage: python3 classify_fruit.py <image_path>")
        sys.exit(1)

    image_path = sys.argv[1]
    send_patch(image_path)
    time.sleep(0.1)  # wait for classification
    receive_class()





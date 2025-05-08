  import cv2
import serial
import time
import numpy as np
import sys

# Config
PATCH_SIZE = 32
SERIAL_PORT = '/dev/ttyS0'  # or '/dev/serial0' depending on your Pi
BAUD_RATE = 115200

# Get image file name from user input
if len(sys.argv) > 1:
    IMAGE_PATH = sys.argv[1]  # if passed as command line argument
else:
    IMAGE_PATH = input("Enter image file name (e.g., image.jpg): ")

# Initialize UART
ser = serial.Serial(SERIAL_PORT, BAUD_RATE, timeout=2)
time.sleep(2)  # Give UART time to stabilize

# Load and preprocess the image
try:
    image = cv2.imread(IMAGE_PATH)
    if image is None:
        raise FileNotFoundError(f"Cannot open image: {IMAGE_PATH}")
except Exception as e:
    print(e)
    sys.exit(1)

gray = cv2.cvtColor(image, cv2.COLOR_BGR2GRAY)
gray = cv2.resize(gray, (640, 480))  # Resize to 480p

height, width = gray.shape

# Split image into patches and process
for y in range(0, height, PATCH_SIZE):
    for x in range(0, width, PATCH_SIZE):
        patch = gray[y:y+PATCH_SIZE, x:x+PATCH_SIZE]

        if patch.shape != (PATCH_SIZE, PATCH_SIZE):
            continue  # Skip incomplete patches

        # Flatten and send patch
        flat_patch = patch.flatten()
        assert len(flat_patch) == 1024, "Each patch must be exactly 1024 bytes!"

        print(f"Sending patch at ({x}, {y})...")
        ser.write(flat_patch.tobytes())
        ser.flush()

        # Wait and read FPGA prediction
        prediction_byte = ser.read(1)
        if prediction_byte:
            prediction = int.from_bytes(prediction_byte, byteorder='big')
            print(f"Patch ({x},{y}) → Predicted class: {prediction}")
        else:
            print(f"Patch ({x},{y}) → No prediction received")

ser.close()


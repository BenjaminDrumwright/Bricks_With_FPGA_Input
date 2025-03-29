  import cv2
  import serial
  import time
  import numpy as np

  # config
  IMAGE_PATH = 'image.jpg'  
  PATCH_SIZE = 32 # can change later on
  SERIAL_PORT = '/dev/ttyS0'
  BAUD_RATE = 115200

  # initialize serial
  ser = serial.Serial(SERIAL_PORT, BAUD_RATE, timeout=1)
  time.sleep(2)  # wait for serial connection

  # loads and preprocesses image
  image = cv2.imread(IMAGE_PATH) # uses cv2 to read image
  gray = cv2.cvtColor(image, cv2.COLOR_BGR2GRAY) # converts to greyscale

  # resizes to 480p incase not already
  gray = cv2.resize(gray, (640, 480))

  # extract patches
  height, width = gray.shape 
  for y in range(0, height, PATCH_SIZE):
      for x in range(0, width, PATCH_SIZE):
          patch = gray[y:y+PATCH_SIZE, x:x+PATCH_SIZE]
          if patch.shape != (PATCH_SIZE, PATCH_SIZE):
              continue  # skip incomplete patches

          # flatten the patch to send over UART
          flat_patch = patch.flatten()
          for pixel in flat_patch:
              ser.write(bytes([pixel]))  # send pixel as byte
              time.sleep(0.001)  # small delay (tune if needed)

          # optionally wait for prediction
          prediction = ser.readline().decode().strip()
          print(f"Patch ({x},{y}) → Prediction: {prediction}")

  ser.close()


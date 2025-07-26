import serial
import sys
import glob
import numpy as np
from PIL import Image
from tqdm import tqdm

def serial_ports():
    """ Lists serial port names

        :raises EnvironmentError:
            On unsupported or unknown platforms
        :returns:
            A list of the serial ports available on the system
    """
    if sys.platform.startswith('win'):
        ports = ['COM%s' % (i + 1) for i in range(256)]
    elif sys.platform.startswith('linux') or sys.platform.startswith('cygwin'):
        # this excludes your current terminal "/dev/tty"
        ports = glob.glob('/dev/tty[A-Za-z]*')
    elif sys.platform.startswith('darwin'):
        ports = glob.glob('/dev/tty.*')
    else:
        raise EnvironmentError('Unsupported platform')

    result = []
    for port in ports:
        try:
            s = serial.Serial(port)
            s.close()
            result.append(port)
        except (OSError, serial.SerialException):
            pass
    return result

print(serial_ports())


port = serial_ports()[0]
print(f"Using port {port}.")

s = serial.Serial(port, 115200)
output = np.zeros((256,256,3), dtype=np.uint8)

try:
    for i in tqdm(range(256)):
        for j in range(256):
            pixel = []
            for k in range(3):
                pixel.append(int.from_bytes(s.read(), "big"))
            output[i][j] = np.asarray(pixel)
            #print(pixel)
except KeyboardInterrupt:
    pass

import json

with open("out.txt", "w") as f:
    f.write(json.dumps(output.tolist()))

img = Image.fromarray(output)
img.show()
img.save("out.png", "png")

import os
from scipy import misc
import RPi.GPIO as GPIO
from time import sleep
import spidev

MyARM_ResetPin = 19 # Pin 4 of connector = BCM19 = GPIO[1]

MySPI_FPGA = spidev.SpiDev()
MySPI_FPGA.open(0,0)
MySPI_FPGA.max_speed_hz = 5000000

GPIO.setmode(GPIO.BCM)
GPIO.setwarnings(False)
GPIO.setup(MyARM_ResetPin, GPIO.OUT)

print("\n*************************************************")
print("* BMP images transfer script (RPi to DE0-Nano)! *")
print("*************************************************\n")

print("This version of the script suppose that your BMP")
print("files are stored in a folder 'Slides' located")
print("in the same directory that this script\n");

# do not set MSB, it makes python3 crash...
magic = 0x0EADBEEF

def read_spi(reg_id):
    ToSPI = [reg_id, 0x00, 0x00, 0x00, 0x00] 
    FromSPI = MySPI_FPGA.xfer2(ToSPI)
    try:
        s = 0
        for i, x in enumerate(FromSPI[1:]):
            y = 2**(8*(3-i))
            z = int(x) * y
            s += z
        return s
    except:
        print(FromSPI)
        raise

def load_images():
    ToSPI = [0x80, 0x00, 0x00, 0x00, 0x00] 
    FromSPI = MySPI_FPGA.xfer2(ToSPI)
    print("listening...")
    while True:
        x = read_spi(0x0)
        if x == magic:
            break

    # Important to wait for the DE0-Nano to be ready
    # !! Have to be replaced by a proper handshake !!
                
    print("Transfer launched:\n")

    # Total number of images to be transferred
    img_tot = 1    

    # Transmit image number information to the DE0-Nano
    ToSPI = [0x90, 0x00, 0x00, 0x00, int(img_tot)] 
    FromSPI = MySPI_FPGA.xfer2(ToSPI)

    for k in range(1,int(img_tot)+1):
        img_name = 'MTL_Slide' + str(k) + '.bmp'
        # Image processing function from "scipy" library
        image = misc.imread(os.path.join('./Slides/',img_name),flatten=0)    
        img_dim = image.shape
        # 24-bit pixel transfer loop (row-by-col)
        for i in range(0,img_dim[0]):
            for j in range(0,img_dim[1]):
                ToSPI = [0x91, 0x00, int(image[i,j,0]), int(image[i,j,1]), int(image[i,j,2])] 
                FromSPI = MySPI_FPGA.xfer2(ToSPI)

        msg_progr = '--> Image ' + str(k) + '/' + str(img_tot) + ' transfer done !'        
        print(msg_progr)
            
    ToSPI = [0x80, 0x0E, 0xAD, 0xBE, 0xEF] 
    FromSPI = MySPI_FPGA.xfer2(ToSPI)

    while read_spi(1) != magic:
        pass
    print("loading finished")

if __name__ == "__main__":
    while True:
        load_images()


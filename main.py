import RPi.GPIO as GPIO
import subprocess
import time
import board
import busio
import digitalio
from PIL import Image, ImageDraw, ImageFont
import adafruit_ssd1306
from multiprocessing import Process

def Oled_screen():
    oled_reset = digitalio.DigitalInOut(board.D4)
    
    # Display Parameters
    WIDTH = 128
    HEIGHT = 64
    BORDER = 5
    
    # Use for I2C.
    i2c = board.I2C()
    oled = adafruit_ssd1306.SSD1306_I2C(WIDTH, HEIGHT, i2c, addr=0x3C, reset=oled_reset)
    
    image= Image.open('lain.ppm').convert('1')
    oled.image(image)
    oled.show()
    time.sleep(4)
    oled.fill(0)
    oled.show()
    
    # Clear display.
    oled.fill(0)
    oled.show()
    
    # Create blank image for drawing.
    # Make sure to create image with mode '1' for 1-bit color.
    image = Image.new("1", (oled.width, oled.height))
    
    # Get drawing object to draw on image.
    draw = ImageDraw.Draw(image)
    
    # Draw a white background
    draw.rectangle((0, 0, oled.width, oled.height), outline=255, fill=255)
    
    font = ImageFont.truetype('PixelOperator.ttf', 16)
    #font = ImageFont.load_default()
    start=time.time()
    while True:
    
        # Draw a black filled box to clear the image.
        draw.rectangle((0, 0, oled.width, oled.height), outline=0, fill=0)
    
        # Shell scripts for system monitoring from here : https://unix.stackexchange.com/questions/119126/command-to-display-memory-usage-disk-usage-and-cpu-load
        cmd = "hostname -I | cut -d\' \' -f1"
        IP = subprocess.check_output(cmd, shell = True )
        cmd = "top -bn1 | grep load | awk '{printf \"CPU: %.2f\", $(NF-2)}'"
        CPU = subprocess.check_output(cmd, shell = True )
        cmd = "free -m | awk 'NR==2{printf \"Mem: %s/%sMB %.2f%%\", $3,$2,$3*100/$2 }'"
        MemUsage = subprocess.check_output(cmd, shell = True )
        cmd = "df -h | awk '$NF==\"/\"{printf \"Disk: %d/%dGB %s\", $3,$2,$5}'"
        Disk = subprocess.check_output(cmd, shell = True )
        cmd = "vcgencmd measure_temp |cut -f 2 -d '='"
        temp = subprocess.check_output(cmd, shell = True )
    
        # Pi Stats Display
        draw.text((0, 0), "IP: " + str(IP,'utf-8'), font=font, fill=255)
        draw.text((0, 16), str(CPU,'utf-8') + "%", font=font, fill=255)
        draw.text((80, 16), str(temp,'utf-8') , font=font, fill=255)
        draw.text((0, 32), str(MemUsage,'utf-8'), font=font, fill=255)
        draw.text((0, 48), str(Disk,'utf-8'), font=font, fill=255)
    
        #Display Image    
        oled.image(image)
        oled.show()
        time.sleep(.1)
        if ((time.time()-start)/60>2):
            oled.fill(0)
            oled.show()
            break


def Fan_control():
    GPIO.setup(11,GPIO.OUT)
    pwm=GPIO.PWM(11,100)
    pwm.start(0)
    while True:
        temp=str(subprocess.check_output('/usr/bin/vcgencmd measure_temp',shell=True))
        temp=float(temp[7:-5])
        val_pwm=int((temp - 45) * (100 - 0) // (70 - 45) + 0)
        if (temp>50):
            pwm.ChangeDutyCycle(val_pwm)
        else:
            pwm.ChangeDutyCycle(0)


def Power_button():
    pin=27
    i=0
    GPIO.setup(pin,GPIO.IN,pull_up_down=GPIO.PUD_UP)
    while True:
        time.sleep(0.5)
        if GPIO.input(pin)==False:
            i=i+1
        else:
            i=0
        if (i>6):
            subprocess.run("poweroff",shell=True)
            

Oled=Process(target=Oled_screen)
Fan=Process(target=Fan_control)
butonn=Process(target=Power_button)
Oled.start()
Fan.start()
butonn.start()

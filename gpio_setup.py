import RPi.GPIO as GPIO
import sys

bcm=int(sys.argv[1])

GPIO.setmode(GPIO.BCM)

GPIO.setup(bcm, GPIO.IN, pull_up_down=GPIO.PUD_UP)


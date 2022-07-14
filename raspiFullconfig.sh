echo "|||||||||||||OLED CONFIG START|||||||||||||||||"
sudo apt-get install -y python3 git python3-pip
echo #############python3, git and pyhton3-pip installed#############
sudo pip3 install --upgrade setuptools
echo #############python setuptools installed#############
cd ~
sudo raspi-config nonint do_i2c 0
echo "#############i2c enabled#############"
sudo raspi-config nonint do_spi 0
echo "#############spi enabled#############"
sudo raspi-config nonint do_serial 0
echo "#############serial comunication enabled#############"
sudo raspi-config nonint do_ssh 0
echo "#############ssh enabled#############"
sudo raspi-config nonint do_camera 0
echo "#############camera enabled#############"
sudo raspi-config nonint disable_raspi_config_at_boot 0
echo "#############raspi-init disabled at boot#############"
sudo apt-get install -y i2c-tools libgpiod-dev
echo "#############i2c-tools and libgiod-dev installed#############"
pip3 install --upgrade RPi.GPIO
echo "#############pip3 RPi.GPIO installed#############"
pip3 install --upgrade adafruit-blinka
echo "#############blinka installed#############"
pip3 install adafruit-circuitpython-ssd1306
echo "#############adafruit installed#############"
pip3 install subprocess.run 
echo "#############subrocess installed#############"
pip3 install python-time
echo "#############time installed#############"
sudo apt-get install -y python3-pil
echo "#############python-pil installed#############"
echo "|||||||||||||OLED CONFIG DONE|||||||||||||||||"


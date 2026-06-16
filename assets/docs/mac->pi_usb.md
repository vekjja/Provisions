# Mac -> Pi via USB

## Create a new PiOS SD Card
* Use  Raspberry Pi Imager or Similar to create the SD Card  or use DD:  
```sh
 sudo dd bs=1m if=/path/to/image.img of=/dev/YOUR_DISK_DRIVE
```

* Eject and remount device
```sh
  vim /Volumes/bootfs/config.txt   # add dtoverlay=dwc2
  vim /Volumes/bootfs/cmdline.txt  # after `rootwait` add `modules-load=dwc2,g_ether`
  touch /Volumes/bootfs/ssh
```

### If you didn’t configure WiFi with RPi Imager, you can enable WiFi with file: `wpa_supplicant.conf`

```sh
vim /Volumes/bootfs/wpa_supplicant.conf
```

* Add:
```sh
country=US
ctrl_interface=DIR=/var/run/wpa_supplicant GROUP=netdev
update_config=1

network={
    ssid="YourNetworkSSID"
    psk="YourNetworkPassword"
    key_mgmt=WPA-PSK
}
```

### Optionally  create a `firstboot.sh`
```sh
vim /Volumes/bootfs/gadget-dhcpcd.conf
```

* In gadget-dhcpcd.conf:
```sh
interface usb0
static ip_address=100.0.0.10/24
static routers=100.0.0.1
static domain_name_servers=8.8.8.8 1.1.1.1
```

```sh
vim /Volumes/bootfs/firstboot.sh
```

* In firstboot.sh:
```sh
#!/bin/bash
if [ -f /boot/gadget-dhcpcd.conf ]; then
    sudo apt update && sudp apt install dhcpcd5 vim
    cp /boot/gadget-dhcpcd.conf /etc/dhcpcd.conf
    rm /boot/gadget-dhcpcd.conf  # Remove so it runs only once
    systemctl restart dhcpcd
fi
```

* Then configure your image to execute this script on boot.  
  One common method is to add a line in `/etc/rc.local`  
  (if your image uses it) before the exit 0 line: `/boot/firstboot.sh`

* Make it executable: `chmod +x /boot/firstboot.sh`

## Eject the SD from the Mac and Boot the Pi 
make sure to use a connected data cable from the Mac to the Data port on the Pi  
Allow the Pi a couple of minutes to power on

```sh
ssh-wait pi-gadget.local
```

* If you setup the first boot.sh just wait for a connection… and skip to **On the Mac**:

## On the PI:
```sh
sudo apt update
sudo apt install dhcpcd5 vim
sudo systemctl enable dhcpcd
sudo systemctl start dhcpcd
sudo vim /etc/dhcpcd.conf
```

* In /etc/dhcpcd.conf:
```sh
interface usb0
static ip_address=100.0.0.10/24
# Use the static route only if 
# you want all traffic routed through usb0
# static routers=100.0.0.1
static domain_name_servers=8.8.8.8 1.1.1.1
```

```sh
sudo systemctl restart dhcpcd
```

Try a one-liner:
```sh
ssh pi@<wifi-ip> "sudo apt update && sudo apt install -y dhcpcd5 && echo -e '\ninterface usb0\nstatic ip_address=100.0.0.10/24\nstatic routers=100.0.0.1\nstatic domain_name_servers=8.8.8.8 1.1.1.1\n' | sudo tee -a /etc/dhcpcd.conf && sudo systemctl restart dhcpcd"
```

## On the Mac:
* Open System **Settings** -> **Network** -> **RNDIS/Ethernet Gadget**  
You should see _Self-assigned IP 169.254.250.233_ or similar
    * change to: `100.0.0.1`

* You should see: _Connected_

* Test the connection:
```sh
ping -c 3 100.0.0.10
ssh 100.0.0.10
```

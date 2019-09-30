## Steps to setup SD Card

1. `diskutil unmountDisk /dev/disk`
1. `cd rpi`
1. `sudo dd bs=1m if=2019-07-10-raspbian-buster.img of=/dev/rdisk2 conv=sync`
1. Setup Wifi
  - Under `boot/wpa_supplicant.conf`

```
ctrl_interface=DIR=/var/run/wpa_supplicant GROUP=netdev
update_config=1
country=US

network={
    ssid="castlelouie"
    psk="1234567890"
    key_mgmt=WPA-PSK
}
```
1. Enable SSH: `touch boot/ssh`

## Steps on Pi

1. `sudo apt-get install ruby-full`
1. Clone Repo
1. Set system TZ `sudo timedatectl set-timezone "Asia/Singapore"`

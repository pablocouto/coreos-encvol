#!/bin/sh

install -o root -m 644 encvol@.service /etc/systemd/system/
install -o root -m 644 encvol-env@.service /etc/systemd/system/
install -o root -m 755 -d /etc/opt/encvol/keys/
install -o root -m 755 -d /opt/encvol/bin/
install -o root -m 755 -d /opt/encvol/volumes/
install -o root -m 755 encvol.sh /opt/encvol/bin/

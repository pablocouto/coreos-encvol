#!/bin/sh

trap "Exit" SIGHUP SIGINT SIGTERM

VOLUME=$1

Open () {
    losetup /dev/loop0 /opt/container/volume
    logger \
           $(gpg --batch --passphrase-file /var/opt/container/password \
                 -d /etc/opt/container/key \
                    | cryptsetup -v --key-file - luksOpen /dev/loop0 $VOLUME;
             echo $? > /tmp/container/socket)
}

Persist () {
    while true; do sleep 1; done
}

Close () {
    logger $(cryptsetup -v luksClose $VOLUME)
    logger $(losetup -d /dev/loop0)
}

Exit () {
    Close
    exit
}

Open
Persist

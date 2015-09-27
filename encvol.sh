#!/bin/sh

MkFifos () {
    /usr/bin/mkfifo -m 600 $PASSWORD
    /usr/bin/mkfifo -m 600 $SOCKET
}

RunDocker () {
    LOOPDEV=$(losetup -f)

    /usr/bin/docker run --name=encvol.$VOLUME.service \
                    --net=none \
                    --cap-add=SYS_ADMIN \
                    --device=/dev/mapper/control:/dev/mapper/control \
                    --device=$LOOPDEV:/dev/loop0 \
                    -v /dev/log:/dev/log \
                    -v $SOCKET:/tmp/container/socket \
                    -v $PASSWORD:/var/opt/container/password \
                    -v /etc/opt/encvol/keys/$VOLUME.gpg:/etc/opt/container/key \
                    -v /opt/encvol/volumes/$VOLUME.vol:/opt/container/volume \
                    pablocouto/coreos-encvol $VOLUME
}

Mount () {
    udevadm settle
    mount -v /dev/mapper/$VOLUME /mnt/$VOLUME
}

Clean () {
    /usr/bin/rm $PASSWORD
    /usr/bin/rm $SOCKET
    /usr/bin/rm /dev/shm/encvol@$VOLUME.env
}

TryMount () {
    while true; do
        if read line <$SOCKET; then
            case $line in
                0)
                    Mount
                    Clean
                    exit 0
                    ;;

                *)
                    Clean
                    exit -1
                    ;;
            esac
        fi
        sleep 1
    done
}

case $1 in
    pre)
        MkFifos
        ;;

    run)
        RunDocker
        ;;

    mount)
        TryMount
        ;;
esac

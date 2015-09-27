# coreos-encvol
Dockerized service for mounting LUKS encrypted volumes in CoreOS.

This service doesn’t store the volume password on disk; it has to be entered manually during start. The volume will be accessible on the host’s `/mnt/$VOLUME`.

_Please bear in mind: this service is probably not safe for production use._

# Installation

```
$ sudo ./install.sh
```

# Configuration for a new volume named `$VOLUME`

- First, we must have a key to encrypt the volume. We use GnuPG (≥ 2.1) for this:

```bash
$ dd if=/dev/urandom bs=512 count=4 | gpg -v --pinentry-mode loopback --cipher-algo aes256 --digest-algo sha512 -c -a > $VOLUME.gpg
```

This may require that `allow-loopback-pinentry` is present in `~/.gnupg/gpg-agent.conf`. It is recommended to run this command on a machine different from the one that will host the volume.

- Once the key is on the host (at, say, `~/$VOLUME.gpg`):

```bash
$ sudo install -o root -m 644 ~/$VOLUME.gpg /etc/opt/encvol/keys/
```

- Next, we create the volume on disk:

```bash
$ sudo mkdir /mnt/$VOLUME
$ sudo fallocate -l 300G /opt/encvol/volumes/$VOLUME.vol # volume of 300 GB
$ export LOOPDEV=$(sudo losetup --show -f /opt/encvol/volumes/$VOLUME.vol)
$ gpg -d /etc/opt/encvol/keys/$VOLUME.gpg | sudo cryptsetup -v -c aes-xts-plain64 -s 256 -h sha1 luksFormat $LOOPDEV -
gpg: AES256 encrypted data
gpg: encrypted with 1 passphrase
Command successful.
```

and format it (with, for example, ext4), ending setup:

```bash
$ gpg -d /etc/opt/encvol/keys/$VOLUME.gpg | sudo cryptsetup -v --key-file - luksOpen $LOOPDEV $VOLUME
gpg: AES256 encrypted data
gpg: encrypted with 1 passphrase
Key slot 0 unlocked.
Command successful.

$ sudo mkfs.ext4 /dev/mapper/$VOLUME
mke2fs 1.42.13 (17-May-2015)
Creating filesystem with 78642688 4k blocks and 19660800 inodes
Filesystem UUID: 849c58ce-c069-4d6c-8d07-f1d69e9193dd
Superblock backups stored on blocks:
        32768, 98304, 163840, 229376, 294912, 819200, 884736, 1605632, 2654208,
        4096000, 7962624, 11239424, 20480000, 23887872, 71663616

Allocating group tables: done                            
Writing inode tables: done                            
Creating journal (32768 blocks): done
Writing superblocks and filesystem accounting information: done     

$ sudo cryptsetup luksClose $VOLUME
$ sudo losetup -d $LOOPDEV
```

# Usage

Once the volume is ready, after having completed the above, we can launch the service. The following command will pull the docker image – which may take some time – and ask us for a password:

```bash
$ sudo systemctl start encvol@$VOLUME.service
Please enter the password for encvol:$VOLUME: ************************
```

If everything went well, the volume will now be mounted on `/mnt/$VOLUME`. It can be unmounted, and the associated docker container stopped and removed, with `sudo systemctl stop encvol@$VOLUME.service`.

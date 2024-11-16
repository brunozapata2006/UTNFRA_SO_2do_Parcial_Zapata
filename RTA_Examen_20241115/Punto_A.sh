#!/bin/bash

# Crear partición primaria de 5MB
(
fdisk /dev/sda <<EOF
n
p
1

+5M
w
EOF
)

# Crear partición extendida y particiones lógicas
(
fdisk /dev/sda <<EOF
n
e
2


w
EOF
)

(
fdisk /dev/sda <<EOF
n
l

+1.5G
w
EOF
)

(
fdisk /dev/sda <<EOF
n
l

+512M
w
EOF
)

# Inicializar las particiones como volúmenes físicos
pvcreate /dev/sda1
pvcreate /dev/sda5
pvcreate /dev/sda6

vgcreate vg_datos /dev/sda1 /dev/sda5
vgcreate vg_temp /dev/sda6

lvcreate -L 5M -n lv_docker vg_datos
lvcreate -L 1.5G -n lv_workareas vg_datos
lvcreate -L 512M -n lv_swap vg_temp

mkfs.ext4 /dev/vg_datos/lv_docker
mkfs.ext4 /dev/vg_datos/lv_workareas
mkswap /dev/vg_temp/lv_swap

mkdir -p /var/lib/docker/
mkdir -p /work/

mount /dev/vg_datos/lv_docker /var/lib/docker/
mount /dev/vg_datos/lv_workareas /work/
swapon /dev/vg_temp/lv_swap

echo '/dev/vg_datos/lv_docker /var/lib/docker ext4 defaults 0 0' | tee -a /etc/fstab
echo '/dev/vg_datos/lv_workareas /work ext4 defaults 0 0' | tee -a /etc/fstab
echo '/dev/vg_temp/lv_swap none swap sw 0 0' | tee -a /etc/fstab


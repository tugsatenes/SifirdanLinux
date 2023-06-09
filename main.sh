#!/bin/sh

# Diski gösterir
#fdisk /dev/nvme0n1 -l
fdisk /dev/sda -l
# echo "Şu anlık sadece sanal makine destegi var \
# Diski gösteriyor"
# fdisk /dev/vda -l
sleep 2
clear

# diski şu şekilde biçimlendirir:
# 512MB UEFI disk bölümü (1)
# 1GB Swap (takas) alanı (2)
# Diskin kalanı ise Kök (/) bölümü (3)

echo "Disk bu bicimde bicimlendiriliyor: \
 512MB UEFI disk bolumu (1) \
 1GB Swap (takas) alani (2) \
 Diskin kalani ise Kok (/) bolumu (3)"
sleep 2
clear

sed -e 's/\s*\([\+0-9a-zA-Z]*\).*/\1/' << FDISK_CMDS  | fdisk /dev/sda
g      # Yeni GPT bölümü oluşturur
n      # yeni bölüm ekler
1      # Bölüm numarası
       # Varsayılan olarak ilk sektör alanını boş bırakıyoruz 
+512MB # Bölüm boyutu
n      # 
2      # 
       #  
+1GB   #  
t      # Bölüm tipini değiştirir
1      # 
uefi   # EFI bölümü
t      # 
2      # 
swap   # Takas alanı
n      #
3      #
       #
       # Geriye kalan bütün alan
w      # bölümlendirme tablosunu yazar ve çıkar
FDISK_CMDS

# Dosya sistemleri
mkfs.fat -F 32 /dev/sda1    # UEFI bölümü
mkswap /dev/sda2            # SWAP oluşturma
swapon /dev/sda2            # SWAP etkinleştirme
mkfs.ext4 /dev/sda3         # Kök (/)

export LFS=/mnt/lfs

echo $LFS
sleep 2
clear

mkdir -pv $LFS

mount -v -t ext4 /dev/sda3 $LFS

mkdir -v $LFS/sources

chmod -v a+wt $LFS/sources

wget https://www.linuxfromscratch.org/lfs/view/stable/wget-list-sysv

wget --input-file=wget-list-sysv --continue --directory-prefix=$LFS/sources

chown root:root $LFS/sources/*

mkdir -pv $LFS/{etc,var} $LFS/usr/{bin,lib,sbin}

for i in bin lib sbin; do
  ln -sv usr/$i $LFS/$i
done

case $(uname -m) in
  x86_64) mkdir -pv $LFS/lib64 ;;
esac

mkdir -pv $LFS/tools

groupadd lfs
useradd -s /bin/bash -g lfs -m -k /dev/null lfs

passwd lfs

chown -v lfs $LFS/{usr{,/*},lib,var,etc,bin,sbin,tools}
case $(uname -m) in
  x86_64) chown -v lfs $LFS/lib64 ;;
esac

su - lfs
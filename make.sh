#!/bin/sh

FASMG_PATH="../../fasmg"
#FASMG_PATH="$(which fasmg)"

# on 64-bit linux not being able to run 32-bit executables (eg. WSL - Windows Subsystem Linux):
FASMG_EXEC="qemu-i386-static $FASMG_PATH"
# on 32-bit linux:
#FASMG_EXEC="$FASMG_PATH"

# cd to this script dir
cd "$(readlink -f "$(dirname "$0")")"

# compile efi64.asm ro efi64.efi
export INCLUDE="include"
[ -e "efi64.efi" ] && mv "efi64.efi" "efi64.efi.prev"
$FASMG_EXEC efi64.asm efi64.efi

if [ $? -ne 0 ]; then
	echo "ERROR IN COMPILING!!!"
	exit 1
fi

if [ "$1" != "qemu" ]; then
	echo "COMPILED. To run efi64.efi in qemu emulator, run this script with 'qemu' as 1st argument."
	exit 0
fi

QEMU_ARCH=x86_64
QEMU_EXE="qemu-system-$QEMU_ARCH"
QEMU_PATH="$(which "$QEMU_EXE")"

if ! [ -x "$QEMU_PATH" ]; then
	echo "ERROR! Cannot find qemu executable ($QEMU_EXE). Install it or edit this script and provide path where installed."
	exit 2
fi

OVMF_BIOS_NAME=OVMF.fd
OVMF_BIOS_DIR="/usr/share/qemu"
OVMF_BIOS_PATH="${OVMF_BIOS_DIR}/${OVMF_BIOS_NAME}"


if ! [ -e "$OVMF_BIOS_PATH" ]; then
	echo "ERROR! Cannot find OVMF bios on '$OVMF_BIOS_PATH'. Install it or edit this script and provide path where installed."
	exit 3
fi

IMAGE_EFI_BOOT_DIR="image/efi/boot"
[ -d "$IMAGE_EFI_BOOT_DIR" ] || mkdir -p "$IMAGE_EFI_BOOT_DIR"

UEFI_EXT=x64
BOOT_NAME="boot${UEFI_EXT}.efi"

cp "efi64.efi" "${IMAGE_EFI_BOOT_DIR}/boot${UEFI_EXT}.efi"

echo "STARTING QEMU with efi64.efi"

QEMU_OPTS="-net none -monitor none -parallel none"
"$QEMU_PATH" $QEMU_OPTS -L . -bios "$OVMF_BIOS" -hda fat:image


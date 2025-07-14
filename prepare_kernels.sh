#!/bin/bash

NORMAL_COLOR='\e[0m'
BLUE_COLOR='\e[1;34m'
GREEN_COLOR='\e[1;32m'
RED_COLOR="\e[1;31m"

apply_patches()
{
for patch in ./kernel-patches/"$1"/*.patch; do
	echo -e "${BLUE_COLOR}Applying patch: $patch$NORMAL_COLOR"
	patch -d"./kernels/$1" -p1 --no-backup-if-mismatch -N < "$patch" || { echo -e "${RED_COLOR}Kernel $1 patch $patch failed$NORMAL_COLOR"; exit 1; }
done
echo -e "${GREEN_COLOR}Applying patch all done!$NORMAL_COLOR"
}

make_config()
{
echo "Creating $2 config for kernel $1"
cp ./kernel-patches/mipad2_defconfig ./kernels/$1/arch/x86/configs/mipad2_defconfig || { echo -e "${RED_COLOR}Kernel $1 configuration failed$NORMAL_COLOR"; exit 1; }
make -C ./kernels/$1 O=out mipad2_defconfig || { echo -e "${RED_COLOR}Kernel $1 configuration failed$NORMAL_COLOR"; exit 1; }
}

download_and_patch_kernels()
{
for kernel in $kernels; do
	kernel_remote_path=${kernel_info["$kernel,url"]}
	kernel_remote_branch=${kernel_info["$kernel,branch"]}
	echo -e "${BLUE_COLOR}kernel_remote_path=$kernel_remote_path$NORMAL_COLOR"

	git clone --depth=1 $kernel_remote_path -b $kernel_remote_branch --recursive ./kernels/$kernel || { echo -e "${RED_COLOR}Download kernel $kernel failed!$NORMAL_COLOR"; exit 1; }

	# 对于没有ksu内核，集成SukiSU-Ultra。非GKI模式
	if [ ! -d "./kernels/$kernel/KernelSU" ];then
		pushd ./kernels/$kernel
		curl -LSs "https://raw.githubusercontent.com/SukiSU-Ultra/SukiSU-Ultra/main/kernel/setup.sh" | bash -s nongki
		popd
	fi

	apply_patches "$kernel"
	make_config "$kernel"
done
}

rm -rf kernels

GITHUB_URL=https://github.com

declare -A kernel_info=(
	["6.12,url"]=$GITHUB_URL/android-generic/kernel-zenith
	["6.12,branch"]="6.12"
	["6.14,url"]=$GITHUB_URL/android-generic/kernel-zenith
	["6.14,branch"]="6.14"
)

kernels="6.14"
download_and_patch_kernels


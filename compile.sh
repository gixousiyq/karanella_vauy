CONFIG="vayu_user_defconfig"

OUT=$(pwd)/out

CLANG=$OUT/clang

AK3=$OUT/ak3

sudo apt update
sudo apt install -y build-essential libssl-dev ccache device-tree-compiler xz-utils zip bc bison flex python2 python-is-python3

build() {
    make -j$(nproc --all) O=out         \
    ARCH=arm64                          \
    SUBARCH=arm64                       \
    DTC_EXT=dtc                         \
    CROSS_COMPILE=aarch64-linux-gnu-    \
    LLVM=1                              \
    LLVM_IAS=1                          \
    LD=ld.lld                           \
    AR=llvm-ar                          \
    NM=llvm-nm                          \
    STRIP=llvm-strip                    \
    OBJCOPY=llvm-objcopy                \
    OBJDUMP=llvm-objdump                \
    READELF=llvm-readelf                \
    HOSTCC=clang                        \
    HOSTCXX=clang++                     \
    HOSTAR=llvm-ar                      \
    HOSTLD=ld.lld                       \
    CC="ccache clang"                   \
    $1
}

restorePanels() {
    git restore arch/arm64/boot/dts/qcom/dsi-panel-j20s-36-02-0a-lcd-dsc-vid.dtsi
    git restore arch/arm64/boot/dts/qcom/dsi-panel-j20s-42-02-0b-lcd-dsc-vid.dtsi
}

if [ ! -d $OUT ]; then
    mkdir $OUT
fi

if [ ! -d $CLANG ]; then
    wget "$(curl -s https://raw.githubusercontent.com/ZyCromerZ/Clang/main/Clang-main-link.txt)" -O "$OUT/clang.tar.gz"
    mkdir $CLANG && tar -xvf $OUT/clang.tar.gz -C $CLANG && rm -rf $OUT/clang.tar.gz
fi

export PATH=$CLANG/bin:$PATH

if [ ! -d $AK3 ]; then
    git clone --depth=1 https://github.com/chiteroman/AnyKernel3-vayu.git $AK3
    rm -rf $AK3/.git $AK3/.github $AK3/README.md
fi

restorePanels

build "$CONFIG"

build all

cat $OUT/arch/arm64/boot/dts/qcom/*.dtb > $AK3/dtb

cp -f $OUT/arch/arm64/boot/Image $AK3

cp -f $OUT/arch/arm64/boot/dtbo.img $AK3

sed -i 's/<70>/<695>/g'     arch/arm64/boot/dts/qcom/dsi-panel-j20s-36-02-0a-lcd-dsc-vid.dtsi
sed -i 's/<154>/<1546>/g'   arch/arm64/boot/dts/qcom/dsi-panel-j20s-36-02-0a-lcd-dsc-vid.dtsi
sed -i 's/<70>/<695>/g'     arch/arm64/boot/dts/qcom/dsi-panel-j20s-42-02-0b-lcd-dsc-vid.dtsi
sed -i 's/<154>/<1546>/g'   arch/arm64/boot/dts/qcom/dsi-panel-j20s-42-02-0b-lcd-dsc-vid.dtsi

build dtbs

restorePanels

cp -f $OUT/arch/arm64/boot/dtbo.img out/dtbo-miui.img

cd $AK3

zip -r9 $OUT/kernel.zip * -x .git README.md *placeholder

# Maintainer: Michael Dobachesky <mgdobachesky@live.com>

pkgname=maint
pkgver=1.0.0
pkgrel=1
pkgdesc="A utility to automatically perform Arch Linux system maintenance"
arch=('x86_64')
url="https://gitlab.com/mgdobachesky/ArchSystemMaintenance"
license=('GPLv3')
depends=('python' 
         'python-xmltodict' 
         'python-dateutil' 
         'sed' 
         'awk' 
         'reflector' 
         'rmlint'
         'pacman-contrib' 
         'pacutils')

source=("https://gitlab.com/mgdobachesky/ArchSystemMaintenance/raw/master/$pkgname-$pkgver/run.sh"
        "https://gitlab.com/mgdobachesky/ArchSystemMaintenance/raw/master/$pkgname-$pkgver/Scripts/ArchNews.py"
        "https://gitlab.com/mgdobachesky/ArchSystemMaintenance/raw/master/$pkgname-$pkgver/Scripts/rmjunk.py")

md5sums=('SKIP'
         'SKIP'
         'SKIP')

install_dir="opt/$pkgname"
symlink_dir="usr/bin"

build() {
    umask 022
    mkdir -p "$srcdir/$install_dir/Scripts"
    mkdir -p "$srcdir/$symlink_dir"

    sed -i "s|{{PKG_PATH}}|/${install_dir}|" "$srcdir/run.sh"

    install -m 755 "$srcdir/run.sh" $install_dir
    install -m 755 "$srcdir/ArchNews.py" "$install_dir/Scripts"
    install -m 755 "$srcdir/rmjunk.py" "$install_dir/Scripts"
}

package() {
    cp -r "$srcdir/opt" "$pkgdir"
    cp -r "$srcdir/usr" "$pkgdir"
    ln -s "/$install_dir/run.sh" "$pkgdir/$symlink_dir/$pkgname"
}

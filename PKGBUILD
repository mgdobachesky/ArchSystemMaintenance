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
symlink_dir="usr/local/bin"

package() {
    mkdir -p "$pkgdir/$install_dir"
    mkdir -p "$pkgdir/$symlink_dir"
    
    sed -i "s|{{PKG_PATH}}|/${install_dir}|" "$srcdir/run.sh"
    cp "$srcdir/run.sh" "$pkgdir/$install_dir"
    cp "$srcdir/ArchNews.py" "$pkgdir/$install_dir"
    cp "$srcdir/rmjunk.py" "$pkgdir/$install_dir"

    ln -s "/$install_dir/run.sh" "$pkgdir/$symlink_dir/$pkgname"
}

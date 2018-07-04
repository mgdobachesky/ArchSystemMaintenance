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

package() {
    mkdir -p "$pkgdir/usr/local/bin"
    mkdir -p "$pkgdir/opt/$pkgname/Scripts"
    sed -i "s/{{PKG_PATH}}/\/opt\/$pkgname/" "../$pkgname-$pkgver/run.sh"
    cp "../$pkgname-$pkgver/run.sh" "$pkgdir/opt/$pkgname"
    cp -r "../$pkgname-$pkgver/Scripts" "$pkgdir/opt/$pkgname"
    ln -s "/opt/$pkgname/run.sh" "$pkgdir/usr/local/bin/$pkgname"
}

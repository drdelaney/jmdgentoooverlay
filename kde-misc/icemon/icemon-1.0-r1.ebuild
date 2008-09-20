# Copyright 1999-2006 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: $

inherit kde

MY_P="${PN}-kde3"
S="${WORKDIR}/${MY_P}"

DESCRIPTION="Icemon is a KDE monitor program for use with Icecream compile clusters."
HOMEPAGE="http://www.opensuse.org/icecream"
SRC_URI="http://www.cs.tcd.ie/~furlongm/gentoo/packages/${MY_P}-${PV}.tar.bz2"

LICENSE="GPL-2"
SLOT="0"
KEYWORDS="~x86 ~amd64"
DEPEND="virtual/libc kde-base/kdelibs:3.5 !<=sys-devel/icecream-0.7.6"
IUSE=""

src_compile() {

	use amd64 && export CFLAGS="${CFLAGS} -fPIC -DPIC"
	use amd64 && export CXXFLAGS="${CXXFLAGS} -fPIC -DPIC"
	kde_src_compile 'all' || die "error compiling"
}

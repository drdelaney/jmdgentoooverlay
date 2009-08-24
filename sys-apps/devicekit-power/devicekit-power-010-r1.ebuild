# Copyright 1999-2009 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: $

inherit eutils gnome2 autotools linux-info

MY_PN="DeviceKit-power"

DESCRIPTION="D-Bus abstraction for enumerating power devices and querying history and statistics"
HOMEPAGE="http://www.freedesktop.org/wiki/Software/DeviceKit"
SRC_URI="http://hal.freedesktop.org/releases/${MY_PN}-${PV}.tar.gz"

LICENSE="GPL-2 LGPL-2"
SLOT="0"
KEYWORDS="~amd64 ~x86"
IUSE="debug doc"

RDEPEND=">=dev-libs/glib-2.16.1
	>=dev-libs/dbus-glib-0.76
	>=sys-fs/udev-145
	>=sys-auth/polkit-0.91
	sys-apps/dbus
	virtual/libusb
"
DEPEND="${RDEPEND}
	>=dev-util/intltool-0.40
	dev-util/pkgconfig
	dev-libs/libxslt
	dev-util/gtk-doc-am
	doc? ( >=dev-util/gtk-doc-1.3 )
"

S="${WORKDIR}/${MY_PN}-${PV}"

function check_battery() {
	# check sysfs power interface, bug #263959
	local CONFIG_CHECK="ACPI_SYSFS_POWER"
	check_extra_config
}

pkg_setup() {
	# Pedantic is currently broken
	G2CONF="${G2CONF}
		--localstatedir=/var
		--disable-ansi
		--enable-man-pages
		$(use_enable debug verbose-mode)
	"

	check_battery
}

src_unpack() {
	gnome2_src_unpack

	# Fix build with older gcc, bug #266987
	epatch "${FILESDIR}/${PN}-009-build-gcc-4.1.2.patch"

	# Fix crazy cflags and moved them to maintainer-mode, bug #267139
	epatch "${FILESDIR}/${PN}-007-maintainer-cflags.patch"

	eautoreconf
}

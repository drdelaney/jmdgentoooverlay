# Copyright 1999-2005 Gentoo Foundation
# Copyright 2005 Preston Crow
#  ( If you make changes, please add a copyright notice above, but
#    never remove an existing notice. )
# Distributed under the terms of the GNU General Public License v2
# $Header: $

inherit myth-svn

DESCRIPTION="Gallery and slideshow module for MythTV."
HOMEPAGE="http://www.mythtv.org/"

LICENSE="GPL-2"
SLOT="0"
KEYWORDS="~amd64 ~x86"
IUSE="opengl exif"

DEPEND=">=sys-apps/sed-4
	opengl? ( virtual/opengl )
	exif? ( media-libs/libexif )
	media-libs/tiff
	virtual/mythtvlibs
	!media-plugins/mythgallery
	!media-plugins/mythgallery-cvs"

setup_pro() {
	myconf="${myconf} $(use_enable exif) $(use_enable opengl)"
}

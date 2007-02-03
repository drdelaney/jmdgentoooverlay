# Copyright 1999-2006 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/www-apps/mythweb/mythweb-0.19.ebuild,v 1.3 2006/02/21 15:27:01 cardoe Exp $

ECVS_SERVER="cvs.sourceforge.net:/cvsroot/mythburn"
ECVS_MODULE="mythburn"
ECVS_USER="anonymous"
ECVS_PASS=""

inherit webapp depend.php cvs

DESCRIPTION="PHP scripts intended to manage MythTV from a web browser."
HOMEPAGE="http://www.mythtv.org/"
SRC_URI="http://www.mythtv.org/mc/mythplugins-${PV}.tar.bz2"
IUSE="useppm"
LICENSE="GPL-2"
KEYWORDS="~amd64 ~ppc ~x86"

RDEPEND="virtual/httpd-php
	>=media-video/mjpegtools-1.6.2
	>=media-video/transcode-0.6.14
	>=media-video/dvdauthor-0.6.10
	>=media-gfx/imagemagick-6.0.6
	dev-db/mysql
	>=sys-devel/bc-1.06
	>=dev-lang/perl-5
	>=app-cdr/cdrtools-2.01
	media-video/ffmpeg
	media-video/projectx
	app-cdr/dvd+rw-tools"

S="${WORKDIR}/mythplugins-${PV}/mythweb"

function mythburn_create_menu_images() {
	echo "Creating/Checking 5 sample background menu images"

	#Does not really matter about size of images, they are resized later
	pageresolution=720x576

	echo 1 of 5
	if ! [ -f images/backgrounds/plasma-tomato.png ]; then
		convert -size $pageresolution plasma:tomato-dodgerblue -blur 0x3 ${myfolder}/images/backgrounds/plasma-tomato.png
	fi  

	echo 2 of 5
	if ! [ -f images/backgrounds/plasma-green-yellow.png ]; then
		convert -size $pageresolution plasma:green-yellow -blur 0x3 ${myfolder}/images/backgrounds/plasma-green-yellow.png 
	fi

	echo 3 of 5
	if ! [ -f images/backgrounds/plasma-fractal.png ]; then
		convert -size $pageresolution plasma:fractal -gaussian 0x3 ${myfolder}/images/backgrounds/plasma-fractal.png
	fi

	echo 4 of 5                
	if ! [ -f images/backgrounds/gradient-dodgerblue.png ]; then
		convert -size $pageresolution gradient:dodgerblue -blur 0x3 ${myfolder}/images/backgrounds/gradient-dodgerblue.png
	fi
	
	echo 5 of 5
	if ! [ -f images/backgrounds/backgrounds/black.png ]; then
		convert -size $pageresolution xc:black ${myfolder}/images/backgrounds/black.png
	fi

	mkdir ${myfolder}/images/backgrounds/thumbnails
	
	echo Creating thumbnail of background images
	${myfolder}/createbackgroundthumbs.sh ${myfolder}
}

function patch_mythweb(){
	patch -u --forward --reject-file=/tmp/reject.txt ${mythwebfolder}/themes/default/header.php < ${myfolder}/mythweb/patch_header.php
	patch -u --forward --reject-file=/tmp/reject.txt ${mythwebfolder}/includes/init.php < ${myfolder}/mythweb/patch_init.php

	cp -R ${myfolder}/mythweb/modules ${mythwebfolder}
	cp -R ${myfolder}/mythweb/themes ${mythwebfolder}
	cp -R ${myfolder}/mythweb/skins ${mythwebfolder}
	${mythwebfolder}/languages/build_translation.pl

	mkdir -p ${mythwebfolder}/modules/mythburn/mythburntemp
	mkdir -p ${mythwebfolder}/modules/mythburn/mythburnscripts
	cp ${myfolder}/* ${mythwebfolder}/modules/mythburn/mythburnscripts
	cp -R ${myfolder}/scripts ${mythwebfolder}/modules/mythburn/mythburnscripts

	cp -R ${myfolder}/music ${mythwebfolder}/modules/mythburn/mythburnscripts
	cp -R ${myfolder}/images ${mythwebfolder}/modules/mythburn/mythburnscripts
	cp -R ${myfolder}/mpg ${mythwebfolder}/modules/mythburn/mythburnscripts
	
	mkdir -p ${mythwebfolder}/config/mythburnconf
	cp -R ${myfolder}/conf ${mythwebfolder}/modules/mythburn/mythburnscripts

	dosym ${mythwebfolder}/modules/mythburn/mythburnscripts/conf ${mythwebfolder}/config/mythburnconf 
}

function init_myth_burn() {
	einfo "Removoving CVS folders - Please ignore any No such file or directory errors"
	#Remove CVS folders
	find ${WORKDIR}/mythburn -name CVS -exec rm -Rf {} \;

	#Making scripts executable
	find ${WORKDIR}/mythburn -name '*.sh' -exec chmod a+x {} \;	
	find ${WORKDIR}/mythburn -name '*.pl' -exec chmod a+x {} \;
}


src_unpack() {
        unpack ${A}
	cvs_src_unpack
	cd ${S}

	cd ${WORKDIR}/mythburn

	epatch ${FILESDIR}/mythwebburn-0.19-echo-cmdline.patch
	epatch ${FILESDIR}/mythwebburn-0.19-extend-readlog.patch
	epatch ${FILESDIR}/mythwebburn-0.19-estimate_cutsize.patch
	
	if use useppm; then
		einfo ""
		einfo "Using ppm images to generate animated memues and the intro."
		epatch ${FILESDIR}/mythwebburn-0.19-useppm.patch
	fi

	init_myth_burn

	myfolder=`pwd`
	mythwebfolder=${S}

	mythburn_create_menu_images
	
	patch_mythweb

}


pkg_setup() {
	webapp_pkg_setup

	if has_version 'dev-lang/php' ; then
		require_php_with_use session
	fi
}

src_install() {
	webapp_src_preinst

	dodoc README TODO

	dodir ${MY_HTDOCSDIR}/data

	cp -R ${S}/* .htaccess ${D}${MY_HTDOCSDIR}

	cp ${D}${MY_HTDOCSDIR}/modules/mythburn/mythburnscripts/mythburn.conf.example ${D}${MY_HTDOCSDIR}/modules/mythburn/mythburnscripts/mythburn.conf
	cp ${ROOT}${VHOST_ROOT}/${MY_HTDOCSBASE}/${PN}/modules/mythburn/mythburnscripts/mythburn.conf ${D}${MY_HTDOCSDIR}/modules/mythburn/mythburnscripts/mythburn.conf
	cp ${ROOT}${VHOST_ROOT}/${MY_HTDOCSBASE}/${PN}/modules/mythburn/mythburnscripts/conf/mythtvburnconfig.xml ${D}${MY_HTDOCSDIR}/modules/mythburn/mythburnscripts/conf/mythtvburnconfig.xml


	webapp_serverowned ${MY_HTDOCSDIR}/data
	webapp_serverowned -R ${MY_HTDOCSDIR}/modules/mythburn 

	webapp_configfile ${MY_HTDOCSDIR}/config/conf.php
	webapp_configfile ${MY_HTDOCSDIR}/modules/mythburn/mythburnscripts/mythburn.conf
	webapp_postinst_txt en ${FILESDIR}/postinstall-en.txt

	webapp_src_install
}

pkg_postinst() {
	webapp_pkg_postinst

	cd  ${ROOT}${VHOST_ROOT}/${MY_HTDOCSBASE}/${PN}/modules/mythburn/mythburnscripts
	
	find . -name '*.sh' -exec chmod a+x {} \;
	find . -name '*.pl' -exec chmod a+x {} \;
}


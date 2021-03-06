# Copyright 1999-2009 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: $

: ${EHG_REPO_URI:=${V4L_DVB_HG_REPO_URI:-http://linuxtv.org/hg/v4l-dvb}}

EAPI="2"

inherit linux-mod eutils toolchain-funcs mercurial savedconfig

DESCRIPTION="live development version of v4l&dvb-driver for Kernel 2.6"
SRC_URI=""
HOMEPAGE="http://www.linuxtv.org"

KEYWORDS="~amd64 ~x86"
SLOT="0"
LICENSE="GPL-2"
IUSE=""

S="${WORKDIR}/${EHG_REPO_URI##*/}/v4l"

pkg_setup()
{
	linux-mod_pkg_setup
	if [[ "${KV_MAJOR}.${KV_MINOR}" != "2.6"  ]]; then
		ewarn "other Kernel than 2.6.x are not supported at the moment."
		die "unsupported Kernel (not 2.6.x)"
	fi
	MODULE_NAMES="dvb(dvb:${S})"
	BUILD_PARAMS="KDIR=${KERNEL_DIR}"
	BUILD_TARGETS="default"

	if [[ -d ${ROOT}/lib/modules/${KV_FULL}/v4l-dvb-cvs ]]; then
		ewarn "There are stale dvb-modules from the ebuild v4l-dvb-cvs."
		ewarn "Please remove the directory /lib/modules/${KV_FULL}/v4l-dvb-cvs"
		ewarn "with all its files and subdirectories and then restart emerge."
		ewarn
		ewarn "# rm -rf /lib/modules/${KV_FULL}/v4l-dvb-cvs"
		die "Stale dvb-modules found, restart merge after removing them."
	fi
}

src_prepare() {

	einfo "Removing modules-install"
        sed -i ${S}/v4l/Makefile \
        -e "s/install:: media-install firmware_install/install:: media-install/"

	# apply local patches
	if test -n "${DVB_LOCAL_PATCHES}";
	then
		ewarn "Applying local patches:"
		for LOCALPATCH in ${DVB_LOCAL_PATCHES};
		do
			if test -f "${LOCALPATCH}";
			then
				if grep -q linux/drivers "${LOCALPATCH}"; then
					cd "${S}"/..
				else
					cd "${S}"
				fi
				epatch "${LOCALPATCH}"
			fi
		done
	else
		einfo "No additional local patches to use"
	fi

	export ARCH=$(tc-arch-kernel)
	make allmodconfig ${BUILD_PARAMS}
	export ARCH=$(tc-arch)

	echo

	
	elog "Removing autoload-entry from stradis-driver."
	sed -i "${S}"/v4l/../linux/drivers/media/video/stradis.c -e '/MODULE_DEVICE_TABLE/d'

	cd "${S}/v4l"
	sed	-e '/-install::/s:rminstall::' \
		-i Makefile

	elog "Removing depmod-calls"
	sed -e '/depmod/d' -i Makefile* scripts/make_makefile.pl scripts/make_kconfig.pl \
	|| die "Failed removing depmod call from Makefile"

	grep depmod * && die "Not removed depmod found."

	mkdir "${WORKDIR}"/header
	cd "${WORKDIR}"/header
	cp "${S}"/../linux/include/linux/dvb/* .
	sed -e '/compiler/d' \
		-e 's/__user//' \
		-i *.h

	cd "${S}"

	pwd	
	epatch_user
	restore_config .config
}

src_install() {
	# install the modules
	local DEST="${D}/lib/modules/${KV_FULL}/v4l-dvb"
	make install \
		DEST="${DEST}" \
		KDIR26="${DEST}" \
		KDIRA="${DEST}" \
	|| die "make install failed"

	cd "${S}"/v4l/..
	dodoc linux/Documentation/dvb/*.txt
	dosbin linux/Documentation/dvb/get_dvb_firmware

	insinto /usr/include/v4l-dvb-hg/linux/dvb
	cd "${WORKDIR}/header"
	doins *.h

	cd "${S}"
	save_config .config
}

pkg_postinst() {
	echo
	elog "Firmware-files can be found in media-tv/linuxtv-dvb-firmware"
	echo

	linux-mod_pkg_postinst
	echo
	echo
	elog "if you want to use the IR-port or networking"
	elog "with the dvb-card you need to"
	elog "install linuxtv-dvb-apps"
	echo
}

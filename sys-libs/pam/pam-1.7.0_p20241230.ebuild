# Copyright 1999-2025 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

MY_P="Linux-${PN^^}-${PV}"

# Avoid QA warnings
# Can reconsider w/ EAPI 8 and IDEPEND, bug #810979
TMPFILES_OPTIONAL=1

inherit db-use fcaps flag-o-matic meson-multilib

DESCRIPTION="Linux-PAM (Pluggable Authentication Modules)"
HOMEPAGE="https://github.com/linux-pam/linux-pam"

if [[ ${PV} == *_p* ]] ; then
	PAM_COMMIT="e634a3a9be9484ada6e93970dfaf0f055ca17332"
	SRC_URI="
		https://github.com/linux-pam/linux-pam/archive/${PAM_COMMIT}.tar.gz -> ${P}.gh.tar.gz
	"
	S="${WORKDIR}"/linux-${PN}-${PAM_COMMIT}
else
	VERIFY_SIG_OPENPGP_KEY_PATH=/usr/share/openpgp-keys/strace.asc
	inherit verify-sig

	SRC_URI="
		https://github.com/linux-pam/linux-pam/releases/download/v${PV}/${MY_P}.tar.xz
		verify-sig? ( https://github.com/linux-pam/linux-pam/releases/download/v${PV}/${MY_P}.tar.xz.asc )
	"
	S="${WORKDIR}/${MY_P}"

	BDEPEND="verify-sig? ( sec-keys/openpgp-keys-strace )"
fi

LICENSE="|| ( BSD GPL-2 )"
SLOT="0"
# Unkeyworded until man pages are figured out
#KEYWORDS="~alpha ~amd64 ~arm ~arm64 ~hppa ~loong ~m68k ~mips ~ppc ~ppc64 ~riscv ~s390 ~sparc ~x86 ~amd64-linux ~x86-linux"
IUSE="audit berkdb elogind examples debug nis nls selinux systemd"
REQUIRED_USE="?? ( elogind systemd )"

# meson.build specifically checks for bison and then byacc
BDEPEND+="
	|| ( sys-devel/bison dev-util/byacc )
	sys-devel/flex
	virtual/pkgconfig
	nls? ( sys-devel/gettext )
"
DEPEND="
	virtual/libcrypt:=[${MULTILIB_USEDEP}]
	>=virtual/libintl-0-r1[${MULTILIB_USEDEP}]
	audit? ( >=sys-process/audit-2.2.2[${MULTILIB_USEDEP}] )
	berkdb? ( >=sys-libs/db-4.8.30-r1:=[${MULTILIB_USEDEP}] )
	!berkdb? ( sys-libs/gdbm:=[${MULTILIB_USEDEP}] )
	selinux? ( >=sys-libs/libselinux-2.2.2-r4[${MULTILIB_USEDEP}] )
	systemd? ( sys-apps/systemd:=[${MULTILIB_USEDEP}] )
	nis? (
		net-libs/libnsl:=[${MULTILIB_USEDEP}]
		>=net-libs/libtirpc-0.2.4-r2:=[${MULTILIB_USEDEP}]
	)
"
RDEPEND="${DEPEND}"
PDEPEND=">=sys-auth/pambase-20200616"

src_configure() {
	# meson.build sets -Wl,--fatal-warnings and with e.g. mold, we get:
	#  cannot assign version `global` to symbol `pam_sm_open_session`: symbol not found
	append-ldflags $(test-flags-CCLD -Wl,--undefined-version)

	# Do not let user's BROWSER setting mess us up, bug #549684
	unset BROWSER

	meson-multilib_src_configure
}

multilib_src_configure() {
	local emesonargs=(
		$(meson_feature audit)
		$(meson_native_use_bool examples)
		$(meson_use debug pam-debug)
		$(meson_feature nis)
		$(meson_feature nls i18n)
		$(meson_feature selinux)

		-Disadir='.'
		-Dxml-catalog="${BROOT}"/etc/xml/catalog
		-Dsecuredir="${EPREFIX}"/$(get_libdir)/security

		-Ddb=$(usex berkdb 'db' 'gdbm')
		-Ddb-uniquename=$(db_findver sys-libs/db)

		# TODO: Docs are currently disabled as would need to either
		# add the deps (some appear unpackaged too?) and possibly
		# generate a tarball for them, but not so critical of an issue
		# to handle with the Meson migration given this was disabled
		# before too (see bug #913087).
		#$(meson_native_enabled docs)
		-Ddocs=disabled

		-Dpam_unix=enabled

		# TODO: wire this up now it's more useful as of 1.5.3 (bug #931117)
		-Deconf=disabled

		# TODO: lastlog is enabled again for now by us as elogind support
		# wasn't available at first. Even then, disabling lastlog will
		# probably need a news item.
		$(meson_feature systemd logind)
		$(meson_feature elogind)
		-Dpam_lastlog=enabled
	)

	# This whole weird has_version libxcrypt block can go once
	# musl systems have libxcrypt[system] if we ever make
	# that mandatory. See bug #867991.
	#if use elibc_musl && ! has_version sys-libs/libxcrypt[system] ; then
	#	# Avoid picking up symbol-versioned compat symbol on musl systems
	#	export ac_cv_search_crypt_gensalt_rn=no
	#
	#	# Need to avoid picking up the libxcrypt headers which define
	#	# CRYPT_GENSALT_IMPLEMENTS_AUTO_ENTROPY.
	#	cp "${ESYSROOT}"/usr/include/crypt.h "${T}"/crypt.h || die
	#	append-cppflags -I"${T}"
	#fi

	meson_src_configure
}

multilib_src_install_all() {
	find "${ED}" -type f -name '*.la' -delete || die

	# tmpfiles.eclass is impossible to use because
	# there is the pam -> tmpfiles -> systemd -> pam dependency loop
	dodir /usr/lib/tmpfiles.d

	cat ->> "${ED}"/usr/lib/tmpfiles.d/${CATEGORY}-${PN}.conf <<-_EOF_
		d /run/faillock 0755 root root
	_EOF_
	use selinux && cat ->> "${ED}"/usr/lib/tmpfiles.d/${CATEGORY}-${PN}-selinux.conf <<-_EOF_
		d /run/sepermit 0755 root root
	_EOF_

	# TODO: See bug #913087
	#local page
	#for page in doc/man/*.{3,5,8} modules/*/*.{5,8} ; do
	#	doman ${page}
	#done
}

pkg_postinst() {
	ewarn "Some software with pre-loaded PAM libraries might experience"
	ewarn "warnings or failures related to missing symbols and/or versions"
	ewarn "after any update. While unfortunate this is a limit of the"
	ewarn "implementation of PAM and the software, and it requires you to"
	ewarn "restart the software manually after the update."
	ewarn ""
	ewarn "You can get a list of such software running a command like"
	ewarn "  lsof / | grep -E -i 'del.*libpam\\.so'"
	ewarn ""
	ewarn "Alternatively, simply reboot your system."

	# The pam_unix module needs to check the password of the user which requires
	# read access to /etc/shadow only.
	fcaps cap_dac_override sbin/unix_chkpwd
}

# Copyright 1999-2025 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

DIST_AUTHOR=PLICEASE
DIST_VERSION=1.17
inherit perl-module

DESCRIPTION="A Module::Build subclass for building Alien:: modules and their libraries"
SLOT="0"
KEYWORDS="~alpha amd64 arm arm64 hppa ~loong ~mips ppc ppc64 ~riscv ~s390 sparc x86 ~x64-macos"

# Alien-Build for Alien::Base::PkgConfig
RDEPEND="
	>=dev-perl/Alien-Build-1.200.0
	dev-perl/Archive-Extract
	>=virtual/perl-Archive-Tar-1.400.0
	>=dev-perl/Capture-Tiny-0.170.0
	>=dev-perl/File-chdir-0.100.500
	>=dev-perl/Module-Build-0.400.400
	>=dev-perl/Path-Tiny-0.77.0
	>=virtual/perl-Scalar-List-Utils-1.450.0
	dev-perl/Shell-Config-Generate
	dev-perl/Shell-Guess
	dev-perl/Sort-Versions
	>=virtual/perl-Text-ParseWords-3.260.0
	dev-perl/URI
	dev-perl/HTML-Parser
"
DEPEND="
	>=dev-perl/Module-Build-0.400.400
"
# Test2-Suite for Test2::Require::Module and Test2::V0
BDEPEND="
	${RDEPEND}
	test? (
		>=virtual/perl-Test2-Suite-0.0.121
	)
"

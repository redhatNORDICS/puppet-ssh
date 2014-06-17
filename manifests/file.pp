# Fancy SSH server, client and utility module by James
# Copyright (C) 2012-2013+ James Shubin
# Written by James Shubin <james@shubin.ca>
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU Affero General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU Affero General Public License for more details.
#
# You should have received a copy of the GNU Affero General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.

# TODO: restrict access for file transfer credentials so that ssh communication
# for file pulling is only readonly... only allow scp and sha256sum if possible
# if we can use a non-root user for this, that's even better, even if it's hard

class ssh::file(
	$pair = true,	# limited pair with whoever is sending us files...
	$fast = false
) {	# include this class on senders or receivers for magic!

	include ssh::vardir
	#$vardir = $::ssh::vardir::module_vardir	# with trailing slash
	$vardir = regsubst($::ssh::vardir::module_vardir, '\/$', '')

	file { "${vardir}/file/":
		ensure => directory,	# make sure this is a directory
		recurse => true,	# recurse into directory
		purge => true,		# purge unmanaged files
		force => true,		# purge subdirs and links
		require => File["${vardir}/"],
	}

	# collect and compute all the file hashes that others have requested...
	# NOTE: if we collected the real (ssh::file::hash) type, we would get a
	# duplicate error. as a result, we collect the unique wrappers instead!
	Ssh::File::Hash::Wrapper <<| tag == "${::fqdn}" |>> {
	}

	if $pair {
		# automatically receive the ssh:recv tags we need to use...
		Ssh::Recv::Auto <<| tag == "${::fqdn}" |>> {
			fast => $fast,
		}
	}
}

# vim: ts=8

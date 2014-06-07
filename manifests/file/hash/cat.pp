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

define ssh::file::hash::cat(	# used to install a cat together file of hashes
	$basepath = '',
	$content = ''
) {

	include ssh::vardir
	#$vardir = $::ssh::vardir::module_vardir	# with trailing slash
	$vardir = regsubst($::ssh::vardir::module_vardir, '\/$', '')

	$valid_basepath = "${basepath}" ? {
		'' => "${vardir}/file/cat/",
		# ensure a trailing slash
		default => sprintf("%s/", regsubst("${basepath}", '\/$', '')),
	}

	$valid_fqdn = "${name}"	# TODO: validate/ensure we actually got a fqdn!

	# this file type is wrapped in a higher level type so that the basepath
	# can be set separately on collection through overrides (more correct!)
	file { "${valid_basepath}${valid_fqdn}":
		content => "${content}",
		owner => root,
		group => root,
		mode => 600,	# might as well...
		ensure => present,
		require => File["${valid_basepath}"],
	}
}

# vim: ts=8

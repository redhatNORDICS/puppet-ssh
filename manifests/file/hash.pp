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

define ssh::file::hash(
	$verify = true	# verify the hash on *every* run or rely only on mtime?
) {

	include ssh::file::hash::base
	include ssh::vardir
	#$vardir = $::ssh::vardir::module_vardir	# with trailing slash
	$vardir = regsubst($::ssh::vardir::module_vardir, '\/$', '')

	$safename = regsubst("${name}", '/', '_', 'G')	# make /'s safe
	$metadata = "${vardir}/file/hash/${safename}"

	# tag this metadata so that it doesn't get removed
	file { "${metadata}":
		owner => root,
		group => root,
		mode => 600,	# might as well...
		ensure => present,
		require => File["${vardir}/file/hash/"],
	}

	# hash the file and then set the metadata mtime to match the file mtime
	# if the file doesn't exist, then the metadata file should be set empty
	# we set the metadata mtime to have an epoch date of @0. if the file is
	# still missing, and the metadata has an epoch of 0, then we don't hash
	exec { "(/usr/bin/test ! -e ${name} && echo > ${metadata} && /bin/touch -cmd '@0' ${metadata}) || (/usr/bin/sha256sum '${name}' > ${metadata} && /bin/touch -cmd \"`/usr/bin/stat -c %y '${name}'`\" ${metadata})":
		# TODO: timeout ?
		logoutput => on_failure,
		provider => 'shell',	# ensure that my ! command will work...
		# rehash if the mtimes don't match!
		unless => [
			"/usr/bin/test `/usr/bin/stat -c %Y '${metadata}'` -eq `/usr/bin/stat -c %Y ${name}`",
			"/usr/bin/test ! -e ${name} && /usr/bin/test `/usr/bin/stat -c %Y '${metadata}'` -eq 0",
		],
		onlyif => $verify ? {	# should we run the hashing every time?
			false => undef,	# skip the hashing and only check mtime
			default => "! /usr/bin/sha256sum --quiet --status --check ${metadata}",	# this is a not
		},
		# tag file exists first so that file type doesn't change mtime!
		require => File["${metadata}"],
	}
}

# vim: ts=8

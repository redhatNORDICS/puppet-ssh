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

# NOTE: this code is similar, but *quite* different to the ssh::file::push type
# NOTE: it is preferable to use pull over push, which is provided for symmetry!

# pull a file over ssh. name is used as destination location, can be overridden
# the destination location here takes the form of: /full/posix/path/to/the/file
define ssh::file::pull(	# formerly named: recv; pull was easier to think about!
	$user = '',	# src user
	$host = '',	# src host
	$file = '',	# src file
	# if either $path or $dest are used, then it overrides the $name value!
	$path = '',	# dest path (a var so it can get overridden on collect)
	$dest = '',	# dest file
	# file properties...
	$ensure = '',	# file ensure (setting to absent is a bad idea...)
	$owner = '',	# file user
	$group = '',	# file group
	$mode = '',	# file mode
	$backup = '',	# backup to filebucket ?
	# special
	$verify = true,	# verify the hash on *every* run or rely only on mtime?
	$pair = true,
	$fast = false
) {

	include ssh::file		# TODO: pass in at least the $fast var?
	include ssh::vardir
	#$vardir = $::ssh::vardir::module_vardir	# with trailing slash
	$vardir = regsubst($::ssh::vardir::module_vardir, '\/$', '')

	$valid_user = "${user}" ? {
		'' => 'root',
		default => "${user}",
	}
	$valid_host = "${host}" ? {
		'' => "${::fqdn}",			# default to self fqdn!
		default => "${host}",
	}
	$valid_file = "${file}"			# TODO: check if string is safe
	if "${valid_file}" == '' {
		fail('You must specify a valid file to download.')
	}
	$valid_path = regsubst("${path}", '\/$', '')	# remove trailing slash
	$valid_dest = "${dest}"			# TODO: check if string is safe

	$valid_this = "${valid_path}${valid_dest}" ? {	# 'this' file, eg: dest
		'' => "${name}",	# if both are empty, we use the namevar
		default => "${valid_path}/${valid_dest}",
	}

	if $pair {
		# NOTE: this should be 'ssh::send' on both push and pull!
		#ssh::send { "${valid_host}":
		#}
		$params = {
			fast => $fast,
		}
		# don't cause duplicates if more than one pull is used
		ensure_resource('ssh::send', "${valid_host}", $params)

		# export a special recv type in case they want to use auto recv
		# the name here is ignored and is only needed for uniqueness...
		@@ssh::recv::auto { "${valid_host}-${name}":	# is ignored...
			tag => "${valid_host}",	# to
			from => "${::fqdn}",	# from
			fast => $fast,	# but it's overriden on collect anyways
		}
	}

	$options = "-q -o 'PasswordAuthentication=no' -o 'StrictHostKeyChecking=yes'"

	# use the same mechanic to keep my own local copy of the file hashed...
	# NOTE: if multiple users all want a file, it will cause a duplicate by
	# exported resources all clashing to add the same resource somewhere...
	# to work around this puppet design bug, we use a wrapper to keep these
	# types unique using ensure_resource and a unique (fake) wrapper $name!
	ssh::file::hash::wrapper { "${::fqdn}_${valid_this}":
		realname => "${valid_this}",
		verify => $verify,
	}

	$safefile = regsubst("${valid_this}", '/', '_', 'G')	# make /'s safe
	$metadata = "${vardir}/file/hash/${safefile}"

	$file_gone = "/usr/bin/test ! -e '${valid_this}'"	# file missing!

	# these commands get the values of the hashes- they return '' if empty!
	$this_hash = "/bin/cat ${metadata} 2> /dev/null | /bin/awk '{print \$1}'"
	$that_hash = "/bin/grep '${valid_file}$' '${vardir}/file/cat/${valid_host}' 2> /dev/null | /bin/awk '{print \$1}'"

	# we need to do this empty check so that we run before anything exists!
	$zero_hash = "/usr/bin/test -n \"`${this_hash}`\" && /usr/bin/test -n \"`${that_hash}`\""

	# are our hashes different?
	$test_hash = "/usr/bin/test \"`${this_hash}`\" != \"`${that_hash}`\""

	# this check repeats the process of running the local sha256sum. we can
	# remove this redundant computation and trust the saved hash value, but
	# since the mtime can block its generation, we play it extra safe here!
	$ssh_check = "/usr/bin/test \"`/bin/cat '${valid_this}' | /usr/bin/sha256sum -`\" != \"`/usr/bin/ssh ${options} ${valid_user}@${valid_host} '/bin/cat ${valid_file} | /usr/bin/sha256sum -'`\""

	# we need to template this script because a one-liner would be very bad
	$safename = regsubst("${name}", '/', '_', 'G')	# make /'s safe
	file { "${vardir}/file/pull-unless-${safename}.sh":
		content => regsubst("#!/bin/bash
			${file_gone} && exit 1 # run
			if ${zero_hash}; then
				${test_hash} && exit 1 || exit 0
			fi
			${ssh_check} && exit 1 # run
			exit 0\n", "
			", "\n", 'G'),	# line this up to remove leading tabs!!
		owner => root,
		group => root,
		mode => 700,
		ensure => present,
		require => File["${vardir}/file/"],
	}

	exec { "/usr/bin/scp -p ${options} ${valid_user}@${valid_host}:'${valid_file}' '${valid_this}'":
		logoutput => on_failure,
		provider => 'shell',
		# if the exported hash matches the locally generated hash, then
		# we probably have the same file and we don't need to run a scp
		# if the two hashes don't match, then perhaps something changed
		# or we haven't been informed, and we should re-hash to be sure
		unless => "${vardir}/file/pull-unless-${safename}.sh",
		# don't try to run unless we have the host entry in known_hosts
		onlyif => "/usr/bin/test `/usr/bin/ssh-keygen -F ${valid_host} | /usr/bin/wc -l` -gt 0",
		require => [
			#File["${vardir}/"],
			File["${vardir}/file/pull-unless-${safename}.sh"],
			Ssh::File::Hash["${valid_this}"],	# compute first
		],
		alias => "ssh-file-pull-scp-${name}",
	}

	# TODO
	# if we don't detect the known_hosts entry we need, we need to go again
	#exec { '/bin/true':
	#	logoutput => on_failure,
	#	onlyif => "/usr/bin/test `/usr/bin/ssh-keygen -F ${valid_host} | /usr/bin/wc -l` -gt 0",
	#	notify => TODO: puppet-poke,
	#	require => Exec["ssh-file-pull-scp-${name}"],
	#}

	# tag the file so it doesn't get purged-- these settings are compatible
	# with: scp -p and won't cause repeated copying! see the clarification:
	# > Does mtime ever change on owner/group/mode changes?
	# Only on filesystems that violate POSIX (although offhand I'm not sure
	# what filesystems, if any, that would include). POSIX is quite clear
	# that mtime is not affected by chown or chmod. -- eblake
	if ($ensure != '') or ($owner != '') or ($group != '') or ($mode != '') or ($backup != '') {
		file { "${valid_this}":
			ensure => $ensure ? {
				# by default, ensure this exists...
				'' => present,
				default => $ensure,
			},
			owner => $owner ? {
				'' => undef,
				default => $owner,
			},
			group => $group ? {
				'' => undef,
				default => $group,
			},
			mode => $mode ? {
				'' => undef,
				default => $mode,
			},
			backup => $backup ? {
				'' => undef,
				default => $backup,
			},
			require => Exec["ssh-file-pull-scp-${name}"],
		}
	}

	# add a hash request on the src host, so it computes and exports one...
	@@ssh::file::hash::wrapper { "__${::fqdn}_${valid_file}":	# __ !!
		realname => "${valid_file}",	# complete path of file on host
		tag => "${valid_host}",		# should usually be the fqdn...
	}

	include ssh::file::hash::collect	# collect these exported hashes
}

# vim: ts=8

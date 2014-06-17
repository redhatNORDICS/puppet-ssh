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

# NOTE: this code is similar, but *quite* different to the ssh::file::pull type
# NOTE: it is preferable to use pull over push, which is provided for symmetry!

# push a file over ssh. name is used as destination location, can be overridden
# the destination location here takes the form of: [user]@<hostname>:/full/path
define ssh::file::push(	# formerly named: send; push was easier to think about!
	$file = '',	# src file
	# if any of: $user,$host,$path,$dest are used, $name becomes a comment!
	$user = '',	# dest user
	$host = '',	# dest host
	$path = '',	# dest path (a var so it can get overridden on collect)
	$dest = '',	# dest file
	$verify = true,	# verify the hash on *every* run or rely only on mtime?
	$pair = true,
	$fast = false

) {

	include ssh::file		# TODO: pass in at least the $fast var?
	include ssh::vardir
	#$vardir = $::ssh::vardir::module_vardir	# with trailing slash
	$vardir = regsubst($::ssh::vardir::module_vardir, '\/$', '')

	$valid_file = "${file}"			# TODO: check if string is safe
	if "${valid_file}" == '' {
		fail('You must specify a valid file to download.')
	}

	# TODO: a better regexp magician could probably do a better job :)
	# [user]@hostname:/tmp/dir/file
	$r = '^(([a-zA-Z][a-zA-Z0-9]*)@){0,1}([a-zA-Z][a-zA-Z0-9\.\-]*):(((\/[\w.-]+)*)(\/)([\w.-]+))$'

	$a = regsubst("${name}", $r, '\2')	# user
	$b = regsubst("${name}", $r, '\3')	# host
	$c = regsubst("${name}", $r, '\4')	# path

	# finds the file basename in a complete path; eg: /tmp/dir/file => file
	$x = regsubst("${c}", '(\/[\w.]+)*(\/)([\w.]+)', '\3')
	# finds the basepath in a complete path; eg: /tmp/dir/file => /tmp/dir/
	$d = sprintf("%s/", regsubst("${c}", '((\/[\w.-]+)*)(\/)([\w.-]+)', '\1'))

	$valid_user = "${user}" ? {	# did we explicitly specify a user ?
		'' => "${a}" ? {	# did the regexp find anything fun ?
			'' => 'root',
			default => "${a}",
		},
		default => "${user}",
	}
	$valid_host = "${host}" ? {
		'' => "${b}" ? {
			# if $b == $name, then no match occurred...
			"${name}" => "${::fqdn}",	# default to self fqdn!
			default => "${b}",
		},
		default => "${host}",
	}

	$e = "${path}" ? {
		'' => "${c}" ? {
			# if $c == $name, then no match occurred...
			"${name}" => '',	# TODO: error or set to source?
			default => "${d}",	# not $c !
		},
		default => "${path}",
	}
	$f = "${dest}" ? {
		'' => "${c}" ? {
			# if $c == $name, then no match occurred...
			"${name}" => '',	# TODO: error or set to source?
			default => "${x}",	# not $c !
		},
		default => "${dest}",
	}

	$valid_path = regsubst("${e}", '\/$', '')	# remove trailing slash
	$valid_dest = "${f}"			# TODO: check if string is safe
	if "${valid_path}" == '' {
		fail('You must pick a destination path somewhere.')
	}
	if "${valid_dest}" == '' {
		fail('You must pick a destination file somewhere.')
	}

	$valid_that = "${valid_path}/${valid_dest}"	# 'that' file, eg: dest

	if $pair {
		# NOTE: this should be 'ssh::send' on both push and pull!
		#ssh::send { "${valid_host}":
		#}
		$params = {
			fast => $fast,
		}
		# don't cause duplicates if more than one push is used
		ensure_resource('ssh::send', "${valid_host}", $params)

		# export a special recv type in case they want to use auto recv
		# the name here is ignored and is only needed for uniqueness...
		@@ssh::recv::auto { "${valid_host}-${name}":	# is ignored...
			tag => "${valid_host}",	# to
			from => "${::fqdn}",	# from
			fast => $fast,	# but it's overriden on collect anyways
		}
	}

	$options = "-pq -o 'PasswordAuthentication=no' -o 'StrictHostKeyChecking=yes'"

	# use the same mechanic to keep my own local copy of the file hashed...
	# NOTE: if multiple users all want a file, it will cause a duplicate by
	# exported resources all clashing to add the same resource somewhere...
	# to work around this puppet design bug, we use a wrapper to keep these
	# types unique using ensure_resource and a unique (fake) wrapper $name!
	ssh::file::hash::wrapper { "${::fqdn}_${name}_${valid_file}":
		realname => "${valid_file}",
		verify => $verify,
	}

	$safefile = regsubst("${valid_file}", '/', '_', 'G')	# make /'s safe
	$metadata = "${vardir}/file/hash/${safefile}"

	$file_gone = "/usr/bin/test ! -e '${valid_file}'"	# file missing!

	# these commands get the values of the hashes- they return '' if empty!
	$this_hash = "/bin/cat ${metadata} 2> /dev/null | /bin/awk '{print \$1}'"
	$that_hash = "/bin/grep '${valid_that}$' '${vardir}/file/cat/${valid_host}' 2> /dev/null | /bin/awk '{print \$1}'"

	# we need to do this empty check so that we run before anything exists!
	$zero_hash = "/usr/bin/test -n \"`${this_hash}`\" && /usr/bin/test -n \"`${that_hash}`\""

	# are our hashes different?
	$test_hash = "/usr/bin/test \"`${this_hash}`\" != \"`${that_hash}`\""

	# this check repeats the process of running the local sha256sum. we can
	# remove this redundant computation and trust the saved hash value, but
	# since the mtime can block its generation, we play it extra safe here!
	$ssh_check = "/usr/bin/test \"`/bin/cat '${valid_file}' | /usr/bin/sha256sum -`\" != \"`/usr/bin/ssh ${valid_user}@${valid_host} '/bin/cat ${valid_that} | /usr/bin/sha256sum -'`\""

	# we need to template this script because a one-liner would be very bad
	$safename = regsubst("${name}", '/', '_', 'G')	# make /'s safe
	file { "${vardir}/file/push-unless-${safename}.sh":
		content => regsubst("#!/bin/bash
			#${file_gone} && exit 0 # don't run if file is missing!
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

	# NOTE: if the source file that we're copying is missing, then this can
	# be an error or it can be avoided and skip the exec. for now it errors
	# if there is a reason to do it the other way, ping me to add an option
	exec { "/usr/bin/scp ${options} '${valid_file}' ${valid_user}@${valid_host}:'${valid_that}'":
		logoutput => on_failure,
		provider => 'shell',
		# if the exported hash matches the locally generated hash, then
		# we probably have the same file and we don't need to run a scp
		# if the two hashes don't match, then perhaps something changed
		# or we haven't been informed, and we should re-hash to be sure
		unless => "${vardir}/file/push-unless-${safename}.sh",
		# don't try to run unless we have the host entry in known_hosts
		onlyif => "/usr/bin/test `/usr/bin/ssh-keygen -F ${valid_host} | /usr/bin/wc -l` -gt 0",
		require => [
			#File["${vardir}/"],
			File["${vardir}/file/push-unless-${safename}.sh"],
			# NOTE: i decided to deliberately not auto-require this
			# file that we're sending. ping me if it makes sense to
			#File["${valid_file}"],	# the file that we are copying!
			Ssh::File::Hash["${valid_file}"],	# compute first
		],
		alias => "ssh-file-push-scp-${name}",
	}

	# TODO
	# if we don't detect the known_hosts entry we need, we need to go again
	#exec { '/bin/true':
	#	logoutput => on_failure,
	#	onlyif => "/usr/bin/test `/usr/bin/ssh-keygen -F ${valid_host} | /usr/bin/wc -l` -gt 0",
	#	notify => TODO: puppet-poke,
	#	require => Exec["ssh-file-push-scp-${name}"],
	#}

	# add a hash request on the dest host so it computes and exports one...
	@@ssh::file::hash::wrapper { "__${::fqdn}_${name}_${valid_that}":
		realname => "${valid_that}",	# complete path of file on host
		tag => "${valid_host}",		# should usually be the fqdn...
	}

	include ssh::file::hash::collect	# collect these exported hashes
}

# vim: ts=8

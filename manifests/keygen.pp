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

# helper function to generate and manage an ssh-key
define ssh::keygen(				# TODO: $name is unused for now
	$user = 'root',
	$type = 'rsa',				# we can specify the default...
	$bits = '',				# defaults are specied below...
	$comment = ''				# TODO: is currently ignored...
) {
	$valid_user = "${user}"			# FIXME: do input sanitation...

	$valid_type = $type ? {
		'rsa1' => 'rsa1',	# rsa v.1
		'dsa' => 'dsa',		# dsa v.2
		'rsa' => 'rsa',		# rsa v.2
		default => 'rsa',	# default
	}

	if "${type}" != "${valid_type}" {
		# if user specified an invalid type...
		warning("SSH key type: '${type}', converted to: ${valid_type}.")
	}

	$bits_default = $valid_type ? {	# default bit length when not specified
		'rsa1' => 2048,
		'dsa' => 1024,
		'rsa' => 2048,
	}

	$bits_input = $bits ? {		# pick a default if not user specified!
		'' => $bits_default,
		default => abs(inline_template('<%= @bits.to_i %>'))	# ensure an int
	}

	$valid_bits = $valid_type ? {
		'rsa1' => $bits_input,
		'dsa' => 1024,		# dsa is always 1024 b/c of FIPS 186-2.
		'rsa' => $bits_input,
	}

	if ("${valid_type}" == 'dsa') and not(("${bits}" == '1024') or ("${bits}" == '')) {
		warning("SSH key type: '${valid_type}' bit length must be set to 1024.")
	}

	# TODO: should we also check that a sane bit length was chosen ?
	$rsa_validation = inline_template('<%= ((@valid_bits.is_a?(Integer) and (@valid_bits >= 768)) ? "pass":"fail") %>')
	if (("${valid_type}" == 'rsa') or ("${valid_type}" == 'rsa1')) and "${rsa_validation}" != 'pass' {
		fail("SSH key type: '${valid_type}', length: '${valid_bits}', did not pass bit length validation.")
	}

	#$home = inline_template("<%= File.expand_path('~${valid_user}') %>")	# wrong: templates run on master, not client
	$home = "~${valid_user}"
	$f = $valid_type ? {		# different key types, different names!
		'rsa1' => 'identity',
		'dsa' => 'id_dsa',
		'rsa' => 'id_rsa',
	}
	$priv = "${home}/.ssh/${f}"	# private key path
	$pub = "${priv}.pub"		# public key path

	$priv_e = "\"`/bin/echo -n ${priv}`\""	# expand the ~$user
	$pub_e = "\"`/bin/echo -n ${pub}`\""	# expand the ~$user

	# wrong: templates run on master, not client
	#$xor = inline_template("<%= ((File.exists?('${priv}') ^ File.exists?('${pub}')) ? 'fail':'pass') %>")
	#if "${xor}" != 'pass' {
	#	fail("Half of SSH key: '${priv}' is missing.")
	#}

	# trigger a failure if user doesn't exist
	exec { "/bin/echo 'User: ${valid_user} does not exist!' && /bin/false":
		logoutput => on_failure,
		unless => "/usr/bin/id -u '${valid_user}'",
		alias => "ssh-usercheck-${name}",
	}

	# refuse to run *iff* one of the two key files are missing because when
	# * public key is missing, ssh-keygen will ask if you want to overwrite
	# * private key is missing, ssh-keygen will simply overwrite the public
	exec { "/bin/echo 'Half of SSH key: ${priv} is missing.' && /bin/false":
		logoutput => on_failure,
		onlyif => "/usr/bin/test -e ${priv_e} -a ! -e ${pub_e} -o ! -e ${priv_e} -a -e ${pub_e}",
		alias => "ssh-filecheck-${name}",
	}

	# NOTE: we're specifying an empty passphrase here! ( -N '' )
	exec { "/usr/bin/ssh-keygen -t ${valid_type} -b ${valid_bits} -N '' -f ${priv_e}":
		logoutput => on_failure,
		user => "${valid_user}",
		unless => "/usr/bin/test -e ${priv_e} -o -e ${pub_e}",	# safer
		require => [
			Exec["ssh-usercheck-${name}"],
			Exec["ssh-filecheck-${name}"],
		],
	}
}

# vim: ts=8

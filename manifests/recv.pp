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

define ssh::recv(	# recv...
	#$to
	$fast = false
) {

	# receive from sender...
	Ssh_authorized_key <<| tag == "ssh_key_root_${name}" |>>

	# if we're running fast, we don't care that they match because it's N-N
	$valid_name = $fast ? {
		true => "${name}",
		default => "${::fqdn}",
	}

	# send to sender...
	#@@ssh::known_hosts { "${::hostname}":		# TODO: build this...
	#	user => 'root',
	#	host_aliases => ["${::ipaddress}"],	# TODO: pick a smart ip
	#	type => 'rsa',
	#	tag => "ssh_host_key_${::fqdn}",
	#	key => "${sshrsakey}",			# built-in puppet fact!
	#}
	#@@sshkey { "${::fqdn}":
	$params = {
		# TODO: this could be all the ipaddresses seen instead!
		#host_aliases => ["${::ipaddress}"],	# TODO: pick a smart ip
		type => 'rsa',
		xtag => "ssh_host_key_${valid_name}",
		key => "${sshrsakey}",			# built-in puppet fact!
		ensure => present,
	}
	# FIXME: puppet doesn't allow @@ in ensure_resource!
	#ensure_resource('@@sshkey', "${::fqdn}", $params)
	ensure_resource('ssh::recv::exported_sshkey', "${::fqdn}", $params)

}

# vim: ts=8

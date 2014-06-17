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

define ssh::send(	# send...
	#$from
	$fast = false
) {

	include ssh::send::base

	# add the receiver host key into the sending known_hosts file!
	# receive from receiver...
	#Ssh::Known_hosts <<| tag == "ssh_host_key_${name}" |>>	# TODO
	Sshkey <<| tag == "ssh_host_key_${name}" |>> {
		target => '/root/.ssh/known_hosts',	# use the local file :)
	}

	# if we're running fast, we don't care that they match because it's N-N
	$valid_name = $fast ? {
		true => "${name}",
		default => "${::fqdn}",
	}

	# send to receiver...
	#@@ssh_authorized_key { "root@${::fqdn}":
	$params = {
		user => 'root',
		type => 'rsa',
		xtag => "ssh_key_root_${valid_name}",
		key => getvar("ssh_key_root_${::hostname}_rsa"),	# fact!
		options => [
			#"command=\"TODO\"",	# TODO: can this let argv through ?
			# TODO: this could be all the ipaddresses seen instead!
			#"from=\"${::ipaddress}\"",	# NOTE " must wrap arg!
			'no-port-forwarding',	# safer
			'no-X11-forwarding',	# safer
			'no-agent-forwarding',	# safer
			#'no-pty'		# TODO: is this okay to add ?
		],
	}
	# FIXME: puppet doesn't allow @@ in ensure_resource!
	#ensure_resource('@@ssh_authorized_key', "root@${::fqdn}", $params)
	ensure_resource('ssh::send::exported_ssh_authorized_key', "root@${::fqdn}", $params)

}

# vim: ts=8

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

define ssh::match(
	# User, Group, Host, and Address elements can use: !, *, ?
	$user = [],	# eg: root
	$group = [],	# eg: !wheel
	$host = [],	# eg: *.example.com
	$address = [],	# eg: 192.168.123.0/24
	# available keywords are:
	#AllowAgentForwarding
	#AllowTcpForwarding
	$banner = false,
	#ChrootDirectory
	#ForceCommand
	#GatewayPorts
	#GSSAPIAuthentication
	#HostbasedAuthentication
	#KbdInteractiveAuthentication
	#KerberosAuthentication
	#KerberosUseKuserok
	#MaxAuthTries
	#MaxSessions
	#PubkeyAuthentication
	$authorizedkeyscommand = false,
	$authorizedkeyscommandrunas = '',
	#PasswordAuthentication
	#PermitEmptyPasswords
	#PermitOpen
	#PermitRootLogin
	#RhostsRSAAuthentication
	#RSAAuthentication
	#X11DisplayOffset
	#X11Forwarding
	#X11UseLocalHost
	$comment = ''
) {
	include ssh::server

	# build each match condition (if it exists)
	$user_string = inline_template('<% if user != [] %>User <%= user.join(",") %><% end %>')
	$group_string = inline_template('<% if group != [] %>Group <%= group.join(",") %><% end %>')
	$host_string = inline_template('<% if host != [] %>Host <%= host.join(",") %><% end %>')
	$address_string = inline_template('<% if address != [] %>Address <%= address.join(",") %><% end %>')

	# store all the match conditions in a list
	$match_list = ["${user_string}", "${group_string}", "${host_string}", "${address_string}"]

	# join all non-empty match conditions with a ' '. They are logically AND-ed together.
	$match_string = inline_template('<%= match_list.delete_if {|x| x.empty? }.join(" ") %>')

	if $match_string == '' {
		fail('You must specify at least one match condition.')
	}

	# fragment for: /etc/ssh/sshd_config
	# NOTE: the 001 is so that the match blocks appear last in sort order
	frag { "/etc/ssh/sshd_config.d/001-${name}.match.frag":
		content => template('ssh/match.frag.erb'),
		# FIXME do either of these create a dependency loop ?
		# FIXME	before => Whole['/etc/ssh/sshd_config'],
		# FIXME	notify => Whole['/etc/ssh/sshd_config'],
		require => File['/etc/ssh/sshd_config.d/'],		# the folder to hold the frags should exist first
	}
}

# vim: ts=8

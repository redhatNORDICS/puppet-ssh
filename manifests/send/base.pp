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

class ssh::send::base() {

	# NOTE: it is advantageous to generate this right here, as opposed to
	# generating these centrally and pushing with puppet, because in that
	# scenario, there is a greater chance that a private key gets "lost"!
	ssh::keygen { "root@${::fqdn}":		# build a public/private key!
		user => 'root',
		type => 'rsa',			# TODO: pull from a variable...
		bits => '2048',			# TODO: pull from a variable...
	}
}

# vim: ts=8

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

# causes many to many pairing for anyone including this in the same namespace !
# the first run will cause the hostnames to swap, the second run causes pairing
class ssh::pair(
	$fast = true,	# if true, we don't double run for hostname exchange :)
	$namespace = 'ssh'	# TODO: use this in the types for uniqueness...
) {

	if $fast {
		ssh::recv { "${namespace}":
			fast => true,
		}
		ssh::send { "${namespace}":
			fast => true,
		}

	} else {
		# automatically figure out the send and recv names by exporting them :)
		@@ssh::recv { "${::fqdn}":
			tag => "${namespace}",
		}
		@@ssh::send { "${::fqdn}":
			tag => "${namespace}",
		}
		Ssh::Recv <<| tag == "${namespace}" and title != "${::fqdn}" |>> {
		}
		Ssh::Send <<| tag == "${namespace}" and title != "${::fqdn}" |>> {
		}
	}
}

# vim: ts=8

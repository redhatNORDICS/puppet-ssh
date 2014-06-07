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

# special type to wrap creation of ssh::recv, but without causing duplicates...
# this is useful so that the $name value can be unique on an exported resource!

define ssh::recv::auto(
	$from,	# fqdn
	$fast = false
) {

	$params = {
		fast => $fast,
	}
	# don't cause duplicates if more than one pull is used
	ensure_resource('ssh::recv', "${from}", $params)
}

# vim: ts=8

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

# NOTE: the $name is ignored, as it is used only for uniqueness...
define ssh::file::hash::wrapper(	# avoid duplicates of ssh::file::hash
	$realname,
	$verify = true	# verify the hash on *every* run or rely only on mtime?
) {

	# this must use all the args as listed in ssh::file::hash
	$params = {
		'verify' => $verify,
	}

	# build this resource uniquely...
	ensure_resource('ssh::file::hash', "${realname}", $params)
}

# vim: ts=8

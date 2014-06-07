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

require 'facter'

# find the module_vardir
dir = Facter.value('puppet_vardirtmp')		# nil if missing
if dir.nil?					# let puppet decide if present!
	dir = Facter.value('puppet_vardir')
	if dir.nil?
		var = nil
	else
		var = dir.gsub(/\/$/, '')+'/'+'tmp/'	# ensure trailing slash
	end
else
	var = dir.gsub(/\/$/, '')+'/'
end

if var.nil?
	# if we can't get a valid vardirtmp, then we can't continue
	valid_hashdir = nil
else
	module_vardir = var+'ssh/'
	valid_hashdir = module_vardir.gsub(/\/$/, '')+'/file/hash/'
end

found = []

# NOTE: we cat these together using a loop and a join instead of a straight cat
# because this gives us flexibility in case we join differently in the future !
if not(valid_hashdir.nil?) and File.directory?(valid_hashdir)

	Dir.glob(valid_hashdir+'*').each do |f|
		hash = File.open(f, 'r').read		# read into str
		found.push(hash)
	end
end

# list of available property groups
Facter.add('ssh_file_hash_cat') do
	#confine :operatingsystem => %w{CentOS, RedHat, Fedora}
	setcode {
		found.join('')
	}
end

# vim: ts=8

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

# ssh_keys fact, and multiple facts of: ssh_key_${user}_${hostname}_${type}
require 'facter'
require 'etc'	# parses /etc/passwd
all_users = false				# scan through all users or,
user_list = ['root']				# specify a list to scan for
m = {	# mapping of type to key prefix
	'rsa' => 'id_rsa',
	'dsa' => 'id_dsa',
	'rsa1' => 'identity',
}
hostname = Facter['hostname'].value()
found = []	# list of ssh keys found. used to build the ssh_keys fact below

Etc.passwd { |u|			# loop through each user in /etc/passwd
	if all_users or user_list.include? u.name	# list of allowed users
		ud = u.dir
		if ud != '/' and File.directory?(ud)	# skip lame directories
			# loop through path of each possible public key type...
			# TODO: this can probably be simplified by better ruby:
			m.map { |k,v| {k => File.join(ud, '.ssh/', v+'.pub')} }.each { |h| h.each { |t,d|
			#p.map { |t| File.join(u.dir, '.ssh/', t+'.pub') }.each { |d|
				if File.exists?(d)
					# build unique name for fact
					n = sprintf("ssh_key_%s_%s_%s", u.name, hostname, t)
					Facter.add(n) do
						#confine :operatingsystem => %w{CentOS, RedHat, Fedora}
						setcode do
							Facter::Util::Resolution.exec("/bin/cat '"+d+"' | /bin/awk '{print $2}'")
						end
					end
					found.push(n)	# add to arr of keys...
				end
			} }
		end
	#else
		#puts 'No fact for you!'
	end
}

Facter.add('ssh_keys') do
	#confine :operatingsystem => %w{CentOS, RedHat, Fedora}
	setcode {
		found.join(',')
	}
end

# vim: ts=8

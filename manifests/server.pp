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

class ssh::server(
	$authorizedkeysfile = false,
	$banner = false,
	$authorizedkeyscommand = false,
	$authorizedkeyscommandrunas = '',
	$shorewall = false	# FIXME needed ?
) {
	# keyword processing
	$keyword_authorizedkeysfile = $authorizedkeysfile ? {
		'.ssh/authorized_keys' => false,
		default => $authorizedkeysfile,
	}

	package { 'openssh-server':
		ensure => present,
	}

	file { '/etc/ssh/':
		ensure => directory,		# make sure this is a directory
		recurse => false,		# don't recursively manage directory (different files have different perms)
		purge => false,			# don't purge files
		force => false,			# TODO: what should this be ?
		owner => root,
		group => root,
		mode => 644,
		notify => Service['sshd'],
		require => Package['openssh-server'],
	}

	# NOTE: it is necessary that this file is made from 'frag's because the
	# sshd include directive doesn't exist yet. There is a feature request.
	whole { '/etc/ssh/sshd_config':
		dir => '/etc/ssh/sshd_config.d/',
		owner => root,
		group => root,
		mode => 600,			# u=rw,g=r,o=
		pattern => '*.frag',		# only include files that match
		notify => Service['sshd'],
		require => File['/etc/ssh/'],
	}

	# NOTE: the 000 is so that the main block appears first in sort order
	frag { '/etc/ssh/sshd_config.d/000-sshd_config.frag':
		content => template('ssh/sshd_config.frag.erb'),
		# FIXME do either of these create a dependency loop ?
		# FIXME	before => Whole['/etc/ssh/sshd_config'],
		# FIXME	notify => Whole['/etc/ssh/sshd_config'],
		require => File['/etc/ssh/sshd_config.d/'],		# the folder to hold the frags should exist first
	}

	service { 'sshd':
		enable => true,			# start on boot
		ensure => running,		# ensure it stays running
		hasstatus => true,		# use status command to monitor
		hasrestart => true,		# use restart, not start; stop
		require => Whole['/etc/ssh/sshd_config'],
	}

	# FIXME: should we add firewall rules ?
	#if $shorewall {
	#	####################################################################
	#	#ACTION      SOURCE DEST                PROTO DEST  SOURCE  ORIGINAL
	#	#                                             PORT  PORT(S) DEST
	#	shorewall::rule { 'sshd': rule => "
	#	#SSH/ACCEPT  net    $FW
	#	", comment => 'Allow SSH'}
	#}
}

# vim: ts=8

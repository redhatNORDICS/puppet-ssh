#
#	simple puppet-ssh file push/pull example
#

# on host1:
node 'host1.example.com' {
	# if you include this class, then automatic hashing of local files will
	# occur. these hashes will then be transferred with puppet to the hosts
	# that requested these files... those hosts will no longer do expensive
	# over the wire copying or repeated hashing to ensure that these remote
	# copies are actually idempotent. the logic is quite complex, but it is
	# contained inside this module so you don't have to worry about it much
	include ssh::file	# optional, but makes ssh::file::pull magical!!
	file { '/root/hello':
		content => "Hello from ${hostname}\n",
	}
	file { '/root/goodbye':
		content => "Goodbye from ${hostname}\n",
	}
}

# on host2:
node 'host2.example.com' {
	# this was built with the parameters split apart on purpose! this means
	# you can do fun/scary things like having one host export this resource
	# and have it be collected somewhere else with its parameters overrided
	# this makes a lot of sense; one host tells the other to: "please pull"
	ssh::file::pull { 'ssh-file-pull-comment':	# $name is a comment...
		user => 'root',
		host => 'host1.example.com',
		file => '/root/hello',
		path => '/root/',	# destination path
		dest => 'received',	# destination file
	}
	# another example...
	ssh::file::pull { '/root/this-is-the-destination-location':	# file!
		user => 'root',
		host => 'host1.example.com',
		file => '/root/goodbye',
	}
}

# on host3:
node 'host3.example.com' {
	file { '/root/push-me':
		content => "Hello from ${hostname}\n",
	}
	file { '/root/push-me-too':
		content => "Hello again from ${hostname}\n",
	}
	# using a push is not recommended unless you really know what you want!
	# push was *mostly* provided for symmetry with the ssh::file::push type
	ssh::file::push { 'ssh-file-push-comment':
		file => '/root/push-me',	# same as the second file below
		user => 'root',
		host => 'host4.example.com',
		path => '/root/',
		dest => 'push-to-this-location',
	}
	ssh::file::push { 'root@host4.example.com:/root/push-this-to-here':
		file => '/root/push-me',	# source file...
	}
}

# on host4:
node 'host4.example.com' {
	include ssh::file	# optional, but makes ssh::file::push smarter!!
	# file should appear on this host :)
	# you need to include some classes, if you want automatic key exchange!
}


#
#	contrived puppet-ssh example
#
class { '::ssh::server':

}

ssh::match { 'users-danger':
	group => ['foo'],
	address => ['172.16.1.0/24'],
	authorizedkeyscommand => '/root/danger.sh',
	authorizedkeyscommandrunas => 'root',
	banner => '/root/README',
	require => File['/root/README'],
}

ssh::match { 'users-foobar':
	group => ['bar'],
	host => ['*.example.com', '*.example.org'],
	authorizedkeyscommand => '/root/danger2.sh',
	authorizedkeyscommandrunas => 'root',
	banner => '/root/README',
	require => File['/root/README'],
}


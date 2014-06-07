#
#	simple puppet-ssh example
#
class { 'ssh::server':
	banner => '/root/sshd.banner',
}


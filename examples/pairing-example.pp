#
#	simple puppet-ssh pairing example
#

# by including the following node definition:
node /^host\d+$/ {	# host{1,2,..N}
	include ssh::pair
}

# and then by running puppet in series on the following hosts, you'll see:

# * host1:
# Notice: /Stage[main]/Ssh::Pair/Ssh::Recv[ssh]/Ssh_authorized_key[root@host1.example.com]/ensure: created
# Notice: /Stage[main]/Ssh::Pair/Ssh::Send[ssh]/Sshkey[host1.example.com]/ensure: created

# * host2:
# Notice: /Stage[main]/Ssh::Pair/Ssh::Recv[ssh]/Ssh_authorized_key[root@host2.example.com]/ensure: created
# Notice: /Stage[main]/Ssh::Pair/Ssh::Send[ssh]/Sshkey[host2.example.com]/ensure: created
# Notice: /Stage[main]/Ssh::Pair/Ssh::Send[ssh]/Ssh_authorized_key[root@host1.example.com]/ensure: created
# Notice: /Stage[main]/Ssh::Pair/Ssh::Recv[ssh]/Sshkey[host1.example.com]/ensure: created

# * host1:
# Notice: /Stage[main]/Ssh::Pair/Ssh::Recv[ssh]/Sshkey[host2.example.com]/ensure: created
# Notice: /Stage[main]/Ssh::Pair/Ssh::Send[ssh]/Ssh_authorized_key[root@host2.example.com]/ensure: created

# * host3:
# Notice: /Stage[main]/Ssh::Pair/Ssh::Recv[ssh]/Sshkey[host2.example.com]/ensure: created
# Notice: /Stage[main]/Ssh::Pair/Ssh::Recv[ssh]/Ssh_authorized_key[root@host3.example.com]/ensure: created
# Notice: /Stage[main]/Ssh::Pair/Ssh::Send[ssh]/Sshkey[host3.example.com]/ensure: created
# Notice: /Stage[main]/Ssh::Pair/Ssh::Send[ssh]/Ssh_authorized_key[root@host1.example.com]/ensure: created
# Notice: /Stage[main]/Ssh::Pair/Ssh::Send[ssh]/Ssh_authorized_key[root@host2.example.com]/ensure: created
# Notice: /Stage[main]/Ssh::Pair/Ssh::Recv[ssh]/Sshkey[host1.example.com]/ensure: created

# * host1:
# Notice: /Stage[main]/Ssh::Pair/Ssh::Recv[ssh]/Sshkey[host3.example.com]/ensure: created
# Notice: /Stage[main]/Ssh::Pair/Ssh::Send[ssh]/Ssh_authorized_key[root@host3.example.com]/ensure: created

# as you can see, each host adds the public keys to authorized_keys of whatever
# it can see, even if that happens to only be itself. as subsequent hosts check
# in, they export their data and do the same too. after they've checked in, the
# data that they exported will be available for other hosts to read. when host3
# checks in, it has lots of ssh data sitting there waiting for it to collect :)


# NOTE: it is advantageous to generate this right here, as opposed to
# generating keys centrally, and pushing with puppet, because in that
# scenario, there is a greater chance that a private key gets "lost"!
ssh::keygen { "root@${hostname}":	# build a public/private key
	user => 'root',
	type => 'rsa',
	bits => '2048',
}


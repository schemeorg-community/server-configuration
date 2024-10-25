rm -f id_rsa
rm -f id_rsa.pub
ssh-keygen -t rsa -b 4096 -f ./id_rsa

(echo -n 'JENKINS_AGENT_SSH_PUBKEY=' ; cat id_rsa.pub) > agent.env

#!/bin/bash
set -u -o pipefail

# Set vault address since this will be run by user-data
export VAULT_ADDR=https://vault.service.consul:8200

function wait_for_successful_command {
    local COMMAND=$1

    $COMMAND
    until [ $? -eq 0 ]
    do
        sleep 5
        $COMMAND
    done
}

function complete_constellation_config {
    local PRIVATE_IP=$1
    local CONSTELLATION_CONFIG_PATH=$2

    # Configure constellation with other node IPs
    # TODO: New-style configs
    # TODO: Connect bootnodes to each other?
    CONSTELLATION_OTHER_NODES="otherNodeUrls = []"
    echo "$CONSTELLATION_OTHER_NODES" >> $CONSTELLATION_CONFIG_PATH
    # Configure constellation with URL
    echo "url = \"http://$PRIVATE_IP:9000/\"" >> $CONSTELLATION_CONFIG_PATH
}

# Wait for operator to initialize and unseal vault
wait_for_successful_command 'vault init -check'
wait_for_successful_command 'vault status'

# Wait for vault to be fully configured by the root user
wait_for_successful_command 'vault auth -method=aws'

# Get the overall index, IP, and boot port for this instance
INDEX=$(cat /opt/quorum/info/index.txt)
PRIVATE_IP=$(curl http://169.254.169.254/latest/meta-data/local-ipv4)
BOOT_PORT=30301

# Generate bootnode key and construct bootnode address
BOOT_KEY_FILE=/opt/quorum/private/boot.key
BOOT_PUB_FILE=/opt/quorum/private/boot.pub
BOOT_ADDR_FILE=/opt/quorum/private/boot_addr

BOOT_ADDR=$(vault read -field=address quorum/bootnodes/addresses/$INDEX)
if [ $? -eq 0 ]
then
    # Address already in vault, this is a replacement instance
    CONSTELLATION_PW=$(vault read -field=constellation_pw qorum/bootnodes/passwords/$INDEX)
    BOOT_PUB=$(vault read -field=pub_key quorum/bootnodes/addresses/$INDEX)
    BOOT_KEY=$(vault read -field=bootnode_key quorum/bootnodes/keys/$INDEX)
    echo $BOOT_KEY > $BOOT_KEY_FILE
    echo $BOOT_PUB > $BOOT_PUB_FILE
    echo $BOOT_ADDR > $BOOT_ADDR_FILE
    # Generate constellation key files
    vault read -field=constellation_pub_key quorum/bootnodes/addresses/$CLUSTER_INDEX > /opt/quorum/constellation/private/constellation.pub
    vault read -field=constellation_priv_key quorum/bootnodes/keys/$CLUSTER_INDEX > /opt/quorum/constellation/private/constellation.key
    vault read -field=constellation_a_pub_key quorum/bootnodes/addresses/$CLUSTER_INDEX > /opt/quorum/constellation/private/constellation_a.pub
    vault read -field=constellation_a_priv_key quorum/bootnodes/keys/$CLUSTER_INDEX > /opt/quorum/constellation/private/constellation_a.key
elif [ -e $BOOT_ADDR_FILE ]
then
    # Address in file but not in vault yet, this is a process restart
    CONSTELLATION_PW=$(vault read -field=constellation_pw qorum/bootnodes/passwords/$INDEX)
    BOOT_ADDR=$(cat $BOOT_ADDR_FILE)
    BOOT_PUB=$(cat $BOOT_PUB_FILE)
    BOOT_KEY=$(cat $BOOT_KEY_FILE)
    # Generate constellation keys if they weren't generated last run
    if [ ! -e /opt/quorum/constellation/private/constellation.* ]
    then
        echo "$CONSTELLATION_PW" | constellation-node --generatekeys=/opt/quorum/constellation/private/constellation
        echo "$CONSTELLATION_PW" | constellation-node --generatekeys=/opt/quorum/constellation/private/constellation_a
    fi
else
    # This is a new bootnode
    # Generate and save password first
    # TODO: Make work with nonempty passwords
    CONSTELLATION_PW=""
    wait_for_successful_command "vault write quorum/bootnodes/passwords/$INDEX constellation_pw=$CONSTELLATION_PW"
    BOOT_PUB=$(bootnode --genkey=$BOOT_KEY_FILE --writeaddress)
    BOOT_KEY=$(cat $BOOT_KEY_FILE)
    BOOT_ADDR="enode://$BOOT_PUB@$PRIVATE_IP:$BOOT_PORT"
    echo $BOOT_ADDR > $BOOT_ADDR_FILE
    # Generate constellation keys
    echo "$CONSTELLATION_PW" | constellation-node --generatekeys=/opt/quorum/constellation/private/constellation
    echo "$CONSTELLATION_PW" | constellation-node --generatekeys=/opt/quorum/constellation/private/constellation_a
fi
CONSTELLATION_PUB_KEY=$(cat /opt/quorum/constellation/private/constellation.pub)
CONSTELLATION_A_PUB_KEY=$(cat /opt/quorum/constellation/private/constellation_a.pub)
CONSTELLATION_PRIV_KEY=$(cat /opt/quorum/constellation/private/constellation.key)
CONSTELLATION_A_PRIV_KEY=$(cat /opt/quorum/constellation/private/constellation_a.key)
PRIVATE_IP=$(curl http://169.254.169.254/latest/meta-data/local-ipv4)

complete_constellation_config $PRIVATE_IP /opt/quorum/constellation/config.conf

# Write bootnode address to vault
wait_for_successful_command "vault write quorum/bootnodes/keys/$INDEX bootnode_key=\"$BOOT_KEY\" constellation_priv_key=\"$CONSTELLATION_PRIV_KEY\" constellation_a_priv_key=\"$CONSTELLATION_A_PRIV_KEY\""
wait_for_successful_command "vault write quorum/bootnodes/addresses/$INDEX enode=$BOOT_ADDR pub_key=$BOOT_PUB private_ip=$PRIVATE_IP constellation_pub_key=$CONSTELLATION_PUB_KEY constellation_a_pub_key=$CONSTELLATION_A_PUB_KEY"

# Run the bootnode
sudo mv /opt/quorum/private/bootnode-supervisor.conf /etc/supervisor/conf.d/
sudo mv /opt/quorum/private/constellation-supervisor.conf /etc/supervisor/conf.d/
sudo supervisorctl reread
sudo supervisorctl update
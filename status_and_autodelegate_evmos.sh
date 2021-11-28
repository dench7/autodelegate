#!/bin/bash

export PATH=$PATH:/root/go/bin
date

# LOAD CONFIG.INI
SCRIPT_DIR="$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
IFS="="
while read -r name value
do
eval $name="$value"
done < $SCRIPT_DIR/config_evmos.ini

# START HERE    
echo "Withdraw commission"

echo $PASS | ${BINARY} tx distribution withdraw-rewards ${VALOPER} --commission --from ${KEY_NAME} --gas auto --chain-id=${CHAIN} --fees ${FEE}${COIN} --node http://localhost:${RPC_PORT} -y | grep "raw_log\|txhash"

sleep 10s

echo "Withdraw rewards"

echo $PASS | ${BINARY} tx distribution withdraw-all-rewards --from ${KEY_NAME} --gas auto --fees ${FEE}${COIN} --chain-id=${CHAIN} --node http://localhost:${RPC_PORT} -y | grep "raw_log\|txhash"

sleep 30s

AMOUNT=$(${BINARY} query bank balances ${ADDRESS} --chain-id=${CHAIN} --node http://localhost:${RPC_PORT} --output json | jq -r '.balances[0].amount')

DELEGATE=$((AMOUNT - MIN_BALANCE))
DELEGATE_DENOM=$(echo $DELEGATE/$DENOM | jq -nf /dev/stdin | cut -c1-7)

if [[ $DELEGATE > 0 && $DELEGATE != "null" ]]; then
    echo -e "Delegate"
    echo $PASS | ${BINARY} tx staking delegate ${VALOPER} ${DELEGATE}${COIN} --chain-id=${CHAIN} --from ${KEY_NAME} --fees ${FEE}${COIN} --node http://localhost:${RPC_PORT} -y | grep "raw_log\|txhash"
    sleep 30s
    
    BAL=$(${BINARY} query bank balances ${ADDRESS} --chain-id=${CHAIN} --node http://localhost:${RPC_PORT} --output json | jq -r '.balances[0].amount')
    BAL_DENOM=$(echo $BAL/$DENOM | jq -nf /dev/stdin | cut -c1-7)
    
    PLACE=$(${BINARY} query staking validators --limit 3000 -oj | jq -r '.validators[] | select(.status=="BOND_STATUS_BONDED") | [(.tokens|tonumber / pow(10;18)), .description.moniker] | @csv' | column -t -s"," | sort -k1 -n -r | nl | grep $MONIKER | tr -d '"')
    
    MSG=$(echo -e "<b>$PLACE</b> \n${BINARY} | $(date +'%d-%m-%Y %H:%M') \n<pre>Delegated: ${DELEGATE_DENOM}${COIN_DENOMED} \n  Balance: ${BAL_DENOM}${COIN_DENOMED}</pre>")
else
    MSG=$(echo -e "$PLACE \n${BINARY} | $(date +'%d-%m-%Y %H:%M') \nInsufficient balance for delegation")
fi

echo "---"

if [[ ${TG_TOKEN} != "" ]]; then
  $SCRIPT_DIR/telegram -t $TG_TOKEN -c $TG_CHAT_ID -H "${MSG}"
fi

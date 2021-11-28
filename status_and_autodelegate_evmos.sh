#!/bin/bash

export PATH=$PATH:/root/go/bin
date

# LOAD CONFIG.INI
IFS="="
while read -r name value
do
eval $name="$value"
done < ./config.ini

# FUNCTIONS
function sendTg {
  if [[ ${TG_TOKEN} != "" ]]; then
    local tg_msg="$@"
    SEND=$(curl -s -X POST -H "Content-Type:multipart/form-data" "https://api.telegram.org/bot$TG_TOKEN/sendMessage?chat_id=$TG_CHAT_ID&text=${tg_msg}")
  fi
}

# START HERE    
echo -e "Withdraw rewards"
echo $PASS | ${BINARY} tx distribution withdraw-rewards ${VALOPER} \
  --commission \
  --from ${KEY_NAME} \
  --gas auto \
  --chain-id=${CHAIN} \
  --fees ${FEE}${COIN} \
  --node http://localhost:${RPC_PORT} -y | grep "raw_log\|txhash"
  
sleep 30s

AMOUNT=$(${BINARY} query bank balances ${ADDRESS} --chain-id=${CHAIN} --node http://localhost:${RPC_PORT} --output json | jq -r '.balances[0].amount')

DELEGATE=$((AMOUNT - MIN_BALANCE))
DELEGATE_DENOM=$(echo $DELEGATE/$DENOM | jq -nf /dev/stdin)

if [[ $DELEGATE > 0 && $DELEGATE != "null" ]]; then
    echo -e "Delegate"
    echo $PASS | ${BINARY} tx staking delegate ${VALOPER} ${DELEGATE}${COIN} --chain-id=${CHAIN} --from ${KEY_NAME} --fees ${FEE}${COIN} --node http://localhost:${RPC_PORT} -y | grep "raw_log\|txhash"
    sleep 30s
    
    BAL=$(${BINARY} query bank balances ${ADDRESS} --chain-id=${CHAIN} --node http://localhost:${RPC_PORT} --output json | jq -r '.balances[0].amount')
    BAL_DENOM=$(echo $BAL/$DENOM | jq -nf /dev/stdin)
    
    PLACE=$(${BINARY} query staking validators --limit 3000 -oj | jq -r '.validators[] | select(.status=="BOND_STATUS_BONDED") | [(.tokens|tonumber / pow(10;18)), .description.moniker] | @csv' | column -t -s"," | sort -k1 -n -r | nl | grep $MONIKER)
    
    MSG=$(echo -e "$PLACE %0A${BINARY} | $(date +'%d-%m-%Y %H:%m') %0ADelegated: ${DELEGATE_DENOM}${COIN_DENOMED} %0ABalance: ${BAL_DENOM}${COIN_DENOMED}")
    echo -e "$MSG"
    echo "---"
    sendTg ${MSG}
    
else
    MSG=$(echo -e "$PLACE %0A${BINARY} | $(date +'%d-%m-%Y %H:%m') %0AInsufficient balance for delegation")
    echo -e "$MSG"
    echo "---"
    sendTg ${MSG}
fi

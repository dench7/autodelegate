# Autodelegate and status script with Telegram notifocations

## 1. Install

```
cd $HOME
mkdir scripts
cd scripts
wget -O https://raw.githubusercontent.com/maxzonder/autodelegate/status_and_autodelegate.sh \
&& chmod +x status_and_autodelegate.sh
```

## 2. Set vars

#### EXAMPLE
```
PASS=12345678
KEY_NAME=WALLET_NAME
MONIKER=NODE_NAME
ADDRESS=evmos1... 
VALOPER=evmosvaloper1...
TG_CHAT_ID="34456xx7"
TG_TOKEN="21dfgdfgd1:AAHi9hjkghjkhgjkhjkhgjkhgjkhgjkY"

BINARY=evmosd
COIN=aphoton
COIN_DENOMED=photon
FEE=6000${COIN}
DENOM=1000000000000000000
RPC_PORT=26657
CHAIN=evmos_9000-2
MIN_BALANCE=1000000000000000
```

## 3. Add task in cron

```
crontab -e
```
 
Will call every time

```
0 */1 * * *  /bin/bash /root/Umee_alert_TG/Umee_alert_TG.sh
```

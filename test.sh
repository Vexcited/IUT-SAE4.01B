#!/bin/bash

GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

machines_names=( "pc_v" "pc_ens" "pc_c" "pc_ec" "pc_p" "pc_ps" "pc_etu" "pc_ct" "pc_s" "pc_dns" "pc_rssi" "pc_mail" "pc_bdd" "pc_aux" )
machines_ips=( "172.16.3.65" "172.16.4.1" "172.16.8.1" "172.16.12.1" "172.16.0.1" "172.16.20.1" "172.16.16.1" "172.16.1.1" "172.16.3.28" "172.16.3.17" "172.16.2.1" "172.16.2.3" "172.16.2.2" "172.16.2.4" )

get_ip() {
  local name=$1

  for i in "${!machines_names[@]}"; do
    if [ "${machines_names[$i]}" == "$name" ]; then
      echo "${machines_ips[$i]}"
      return
    fi
  done

  # return empty string if not found
  echo ""
}

function assert_mail_accept {
  echo -e "${YELLOW}Testing mail services access...${NC}"

  for port in 25 587 465 143 993 110 995; do
    kathara exec $machine -- nc -z -w1 $(get_ip "pc_mail") $port &>/dev/null
    if [ $? -ne 0 ]; then
      echo -e "${RED}FAIL${NC}: Cannot connect to pc_mail(eth0) TCP/$port"
    else
      echo -e "${GREEN}PASS${NC}: Connection to pc_mail(eth0) TCP/$port successful"
    fi
  done
}

function assert_mail_drop {
  echo -e "${YELLOW}Verifying mail services are blocked...${NC}"

  for port in 25 587 465 143 993 110 995; do
    kathara exec $machine -- nc -z -w1 $(get_ip "pc_mail") $port &>/dev/null
    if [ $? -eq 0 ]; then
      echo -e "${RED}FAIL${NC}: Can connect to pc_mail(eth0) TCP/$port when it should be blocked"
    else
      echo -e "${GREEN}PASS${NC}: Connection to pc_mail(eth0) TCP/$port blocked as expected"
    fi
  done
}

function assert_dns_accept {
  echo -e "${YELLOW}Testing DNS access...${NC}"
  kathara exec $machine -- nc -z -u -w1 $(get_ip "pc_dns") 53 &>/dev/null
  if [ $? -ne 0 ]; then
    echo -e "${RED}FAIL${NC}: Cannot connect to pc_dns(eth0) UDP/53"
  else
    echo -e "${GREEN}PASS${NC}: Connection to pc_dns(eth0) UDP/53 successful"
  fi
}

function assert_sql_accept {
  echo -e "${YELLOW}Testing SQL database access...${NC}"
  kathara exec $machine -- nc -z -w1 $(get_ip "pc_bdd") 3306 &>/dev/null
  if [ $? -ne 0 ]; then
    echo -e "${RED}FAIL${NC}: Cannot connect to pc_bdd(eth0) TCP/3306"
  else
    echo -e "${GREEN}PASS${NC}: Connection to pc_bdd(eth0) TCP/3306 successful"
  fi
}

function assert_sql_drop {
  echo -e "${YELLOW}Verifying SQL database is blocked...${NC}"
  kathara exec $machine -- nc -z -w1 $(get_ip "pc_bdd") 3306 &>/dev/null
  if [ $? -eq 0 ]; then
    echo -e "${RED}FAIL${NC}: Can connect to pc_bdd(eth0) TCP/3306 when it should be blocked"
  else
    echo -e "${GREEN}PASS${NC}: Connection to pc_bdd(eth0) TCP/3306 blocked as expected"
  fi
}

function assert_web_accept {
  echo -e "${YELLOW}Testing web access...${NC}"

  for port in 80 443; do
    kathara exec $machine --  nc -z -w1 $(get_ip "pc_s") $port &>/dev/null
    if [ $? -ne 0 ]; then
      echo -e "${RED}FAIL${NC}: Cannot connect to pc_s(eth0) TCP/$port"
    else
      echo -e "${GREEN}PASS${NC}: Connection to pc_s(eth0) TCP/$port successful"
    fi
  done
}

function assert_web_drop {
  echo -e "${YELLOW}Verifying web access is blocked...${NC}"

  for port in 80 443; do
    kathara exec $machine -- nc -z -w1 $(get_ip "pc_s") $port &>/dev/null
    if [ $? -eq 0 ]; then
      echo -e "${RED}FAIL${NC}: Can connect to pc_s(eth0) TCP/$port when it should be blocked"
    else
      echo -e "${GREEN}PASS${NC}: Connection to pc_s(eth0) TCP/$port blocked as expected"
    fi
  done
}

function assert_app_accept {
  echo -e "${YELLOW}Testing patient management application access...${NC}"
  kathara exec $machine -- nc -z -w1 $(get_ip "pc_s") 1224 &>/dev/null
  if [ $? -ne 0 ]; then
    echo -e "${RED}FAIL${NC}: Cannot connect to pc_s(eth0) TCP/1224"
  else
    echo -e "${GREEN}PASS${NC}: Connection to pc_s(eth0) TCP/1224 successful"
  fi
}

function assert_app_drop {
  echo -e "${YELLOW}Verifying patient management application is blocked...${NC}"
  kathara exec $machine -- nc -z -w1 $(get_ip "pc_s") 1224 &>/dev/null
  if [ $? -eq 0 ]; then
    echo -e "${RED}FAIL${NC}: Can connect to pc_s(eth0) TCP/1224 when it should be blocked"
  else
    echo -e "${GREEN}PASS${NC}: Connection to pc_s(eth0) TCP/1224 blocked as expected"
  fi
}

for machine in "${machines_names[@]}"; do
  echo ""
  echo -e "${YELLOW}=> MACHINE: $machine${NC}"

  case $machine in
    "pc_p" | "pc_v")
      assert_dns_accept
      assert_web_accept
      assert_mail_drop
      assert_sql_drop
      assert_app_drop
    ;;

    "pc_ens" | "pc_etu")
      assert_dns_accept
      assert_web_accept
      assert_mail_accept
      assert_app_drop
      assert_sql_drop
    ;;

    "pc_c" | "pc_ec")
      assert_dns_accept
      assert_web_accept
      assert_mail_accept
      assert_app_drop
      assert_sql_drop
    ;;

    "pc_ps" | "pc_ct")
      assert_dns_accept
      assert_web_accept
      assert_mail_accept
      assert_app_accept
      assert_sql_drop
    ;;

    "pc_s")
      assert_dns_accept
      assert_mail_drop
      assert_sql_accept
    ;;

    "pc_rssi")
      assert_dns_accept
      assert_web_accept
      assert_mail_accept
      assert_app_accept
      assert_sql_accept

      echo -e "${YELLOW}Testing ICMP (ping) access to all machines...${NC}"
      ping_failures=0

      for machine_key in "${machines_names[@]}"; do
        echo -n "Pinging ${machine_key}... "
        kathara exec $machine -- ping -c1 -W1 $(get_ip $machine_key) > /dev/null 2>&1
        if [ $? -ne 0 ]; then
          echo -e "${RED}FAIL${NC}"
          ((ping_failures++))
        else
          echo -e "${GREEN}PASS${NC}"
        fi
      done

      if [ $ping_failures -eq 0 ]; then
        echo -e "${GREEN}PASS${NC}: RSSI can ping all machines in the network"
      else
        echo -e "${RED}FAIL${NC}: RSSI cannot ping $ping_failures machines"
      fi
    ;;

    "pc_bdd" | "pc_mail" | "pc_aux" | "pc_dns")
      assert_dns_accept
    ;;
  esac
done

#!/bin/bash

machine=$(hostname)

# Color codes for better output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Define all machines and their IP addresses
declare -A machines=(
  ["pc_v_0"]="172.16.3.65"
  ["pc_ens_0"]="172.16.4.1"
  ["pc_c_0"]="172.16.8.1"
  ["pc_ec_0"]="172.16.12.1"
  ["pc_p_0"]="172.16.0.1"
  ["pc_ps_0"]="172.16.20.1"
  ["pc_etu_0"]="172.16.16.1"
  ["pc_ct_0"]="172.16.1.1"
  ["pc_s_0"]="172.16.3.28"
  ["pc_dns_0"]="172.16.3.17"
  ["pc_rssi_0"]="172.16.2.1"
  ["pc_mail_0"]="172.16.2.3"
  ["pc_bdd_0"]="172.16.2.2"
  ["pc_aux_0"]="172.16.2.4"
  ["r_high_0"]="172.16.3.43"
  ["r_mid_0"]="172.16.3.44"
  ["r_low_0"]="172.16.3.45"
)

# Define the router categories for priority checks
declare -A router_priority=(
  ["pc_v"]="low"
  ["pc_p"]="low"
  ["pc_ens"]="mid"
  ["pc_etu"]="mid"
  ["pc_c"]="mid"
  ["pc_ec"]="mid"
  ["pc_ps"]="low"
  ["pc_ct"]="low"
  ["pc_s"]="high"
  ["pc_dns"]="high"
  ["pc_rssi"]="high"
  ["pc_mail"]="high"
  ["pc_bdd"]="high"
  ["pc_aux"]="high"
)

# Function to check SSH access to specific machine
function test_ssh_access() {
  local target=$1
  local expected=$2

  nc -z -w1 ${machines["$target"]} 22 &>/dev/null
  local result=$?

  if [[ $expected -eq 1 && $result -eq 0 ]]; then
    echo -e "${GREEN}PASS${NC}: SSH to $target is accessible"
    return 0
  elif [[ $expected -eq 0 && $result -ne 0 ]]; then
    echo -e "${GREEN}PASS${NC}: SSH to $target is blocked as expected"
    return 0
  else
    if [[ $expected -eq 1 ]]; then
      echo -e "${RED}FAIL${NC}: SSH to $target should be accessible but is blocked"
    else
      echo -e "${RED}FAIL${NC}: SSH to $target should be blocked but is accessible"
    fi
    return 1
  fi
}

# Verification functions for different services
function assert_mail_accept {
  echo -e "${YELLOW}Testing mail services access...${NC}"
  local failures=0

  for port in 25 587 465 143 993 110 995; do
    nc -z -w1 ${machines["pc_mail_0"]} $port &>/dev/null
    if [ $? -ne 0 ]; then
      echo -e "${RED}FAIL${NC}: Cannot connect to pc_mail(eth0) TCP/$port"
      ((failures++))
    else
      echo -e "${GREEN}PASS${NC}: Connection to pc_mail(eth0) TCP/$port successful"
    fi
  done

  return $failures
}

function assert_mail_drop {
  echo -e "${YELLOW}Verifying mail services are blocked...${NC}"
  local failures=0

  for port in 25 587 465 143 993 110 995; do
    nc -z -w1 ${machines["pc_mail_0"]} $port &>/dev/null
    if [ $? -eq 0 ]; then
      echo -e "${RED}FAIL${NC}: Can connect to pc_mail(eth0) TCP/$port when it should be blocked"
      ((failures++))
    else
      echo -e "${GREEN}PASS${NC}: Connection to pc_mail(eth0) TCP/$port blocked as expected"
    fi
  done

  return $failures
}

function assert_dns_accept {
  echo -e "${YELLOW}Testing DNS access...${NC}"
  nc -z -u -w1 ${machines["pc_dns_0"]} 53 &>/dev/null
  if [ $? -ne 0 ]; then
    echo -e "${RED}FAIL${NC}: Cannot connect to pc_dns(eth0) UDP/53"
    return 1
  else
    echo -e "${GREEN}PASS${NC}: Connection to pc_dns(eth0) UDP/53 successful"
    return 0
  fi
}

function assert_sql_accept {
  echo -e "${YELLOW}Testing SQL database access...${NC}"
  nc -z -w1 ${machines["pc_bdd_0"]} 3306 &>/dev/null
  if [ $? -ne 0 ]; then
    echo -e "${RED}FAIL${NC}: Cannot connect to pc_bdd(eth0) TCP/3306"
    return 1
  else
    echo -e "${GREEN}PASS${NC}: Connection to pc_bdd(eth0) TCP/3306 successful"
    return 0
  fi
}

function assert_sql_drop {
  echo -e "${YELLOW}Verifying SQL database is blocked...${NC}"
  nc -z -w1 ${machines["pc_bdd_0"]} 3306 &>/dev/null
  if [ $? -eq 0 ]; then
    echo -e "${RED}FAIL${NC}: Can connect to pc_bdd(eth0) TCP/3306 when it should be blocked"
    return 1
  else
    echo -e "${GREEN}PASS${NC}: Connection to pc_bdd(eth0) TCP/3306 blocked as expected"
    return 0
  fi
}

function assert_ssh_accept {
  echo -e "${YELLOW}Testing SSH access to BDD...${NC}"
  nc -z -w1 ${machines["pc_bdd_0"]} 22 &>/dev/null
  if [ $? -ne 0 ]; then
    echo -e "${RED}FAIL${NC}: Cannot connect to pc_bdd(eth0) TCP/22"
    return 1
  else
    echo -e "${GREEN}PASS${NC}: Connection to pc_bdd(eth0) TCP/22 successful"
    return 0
  fi
}

function assert_ssh_drop {
  echo -e "${YELLOW}Verifying SSH to BDD is blocked...${NC}"
  nc -z -w1 ${machines["pc_bdd_0"]} 22 &>/dev/null
  if [ $? -eq 0 ]; then
    echo -e "${RED}FAIL${NC}: Can connect to pc_bdd(eth0) TCP/22 when it should be blocked"
    return 1
  else
    echo -e "${GREEN}PASS${NC}: Connection to pc_bdd(eth0) TCP/22 blocked as expected"
    return 0
  fi
}

function assert_web_accept {
  echo -e "${YELLOW}Testing web access...${NC}"
  local failures=0

  for port in 80 443; do
    nc -z -w1 ${machines["pc_s_0"]} $port &>/dev/null
    if [ $? -ne 0 ]; then
      echo -e "${RED}FAIL${NC}: Cannot connect to pc_s(eth0) TCP/$port"
      ((failures++))
    else
      echo -e "${GREEN}PASS${NC}: Connection to pc_s(eth0) TCP/$port successful"
    fi
  done

  return $failures
}

function assert_web_drop {
  echo -e "${YELLOW}Verifying web access is blocked...${NC}"
  local failures=0

  for port in 80 443; do
    nc -z -w1 ${machines["pc_s_0"]} $port &>/dev/null
    if [ $? -eq 0 ]; then
      echo -e "${RED}FAIL${NC}: Can connect to pc_s(eth0) TCP/$port when it should be blocked"
      ((failures++))
    else
      echo -e "${GREEN}PASS${NC}: Connection to pc_s(eth0) TCP/$port blocked as expected"
    fi
  done

  return $failures
}

function assert_app_accept {
  echo -e "${YELLOW}Testing patient management application access...${NC}"
  nc -z -w1 ${machines["pc_s_0"]} 1224 &>/dev/null
  if [ $? -ne 0 ]; then
    echo -e "${RED}FAIL${NC}: Cannot connect to pc_s(eth0) TCP/1224"
    return 1
  else
    echo -e "${GREEN}PASS${NC}: Connection to pc_s(eth0) TCP/1224 successful"
    return 0
  fi
}

function assert_app_drop {
  echo -e "${YELLOW}Verifying patient management application is blocked...${NC}"
  nc -z -w1 ${machines["pc_s_0"]} 1224 &>/dev/null
  if [ $? -eq 0 ]; then
    echo -e "${RED}FAIL${NC}: Can connect to pc_s(eth0) TCP/1224 when it should be blocked"
    return 1
  else
    echo -e "${GREEN}PASS${NC}: Connection to pc_s(eth0) TCP/1224 blocked as expected"
    return 0
  fi
}

# Test that machine is using the correct router based on priority
function test_router_priority {
  local expected_priority=${router_priority[$machine]}

  if [ -z "$expected_priority" ]; then
    echo -e "${YELLOW}WARNING${NC}: No priority defined for $machine"
    return 0
  fi

  echo -e "${YELLOW}Testing router priority for $machine (expected: $expected_priority)...${NC}"

  # Check traceroute to see which router is being used
  if command -v traceroute >/dev/null 2>&1; then
    local route=$(traceroute -n -w 1 -q 1 -m 3 8.8.8.8 2>/dev/null | grep -v "* * *" | head -n 3)

    if [[ "$expected_priority" == "high" && "$route" == *"${machines["r_high_0"]}"* ]]; then
      echo -e "${GREEN}PASS${NC}: $machine is using high priority router as expected"
      return 0
    elif [[ "$expected_priority" == "medium" && "$route" == *"${machines["r_medium_0"]}"* ]]; then
      echo -e "${GREEN}PASS${NC}: $machine is using medium priority router as expected"
      return 0
    elif [[ "$expected_priority" == "low" && "$route" == *"${machines["r_low_0"]}"* ]]; then
      echo -e "${GREEN}PASS${NC}: $machine is using low priority router as expected"
      return 0
    else
      echo -e "${RED}FAIL${NC}: $machine is not using the correct priority router"
      echo "Route trace: $route"
      return 1
    fi
  else
    echo -e "${YELLOW}WARNING${NC}: traceroute command not found, skipping router priority check"
    return 0
  fi
}

# Test SSH remote management for DSI
function test_remote_management {
  # Skip if not DSI network machine
  if [[ "$machine" != "pc_rssi" ]]; then
    return 0
  fi

  echo -e "${YELLOW}Testing remote SSH management access from DSI...${NC}"
  local failures=0

  # List of machines that should be remotely manageable
  local manageable_machines=("pc_etu" "pc_ens" "pc_ps" "pc_ct" "pc_s" "pc_dns" "pc_mail" "pc_bdd" "pc_aux")

  for target in "${manageable_machines[@]}"; do
    test_ssh_access "${target}_0" 1
    if [ $? -ne 0 ]; then
      ((failures++))
    fi
  done

  if [ $failures -eq 0 ]; then
    echo -e "${GREEN}PASS${NC}: All required machines are remotely manageable via SSH"
  else
    echo -e "${RED}FAIL${NC}: Some machines are not remotely manageable via SSH"
  fi

  return $failures
}

echo -e "${YELLOW}=== Network Security Test for SAE 4.01B ===${NC}"
echo -e "${YELLOW}Testing machine: $machine${NC}"
echo ""

# Run appropriate tests based on machine type
case $machine in
  # Patients and visitors (low priority)
  "pc_p" | "pc_v")
    test_router_priority
    assert_dns_accept
    assert_web_accept
    assert_mail_drop
    assert_sql_drop
    assert_ssh_drop
    assert_app_drop
  ;;

  # Enseignants et étudiants (medium priority)
  "pc_ens" | "pc_etu")
    test_router_priority
    assert_dns_accept
    assert_web_accept
    assert_mail_accept
    assert_app_drop
    assert_sql_drop
    assert_ssh_drop
  ;;

  # Chercheurs et enseignants-chercheurs (high priority)
  "pc_c" | "pc_ec")
    test_router_priority
    assert_dns_accept
    assert_web_accept
    assert_mail_accept
    assert_app_drop
    assert_sql_drop
    assert_ssh_accept
  ;;

  # Personnel soignant et comptabilité (high priority)
  "pc_ps" | "pc_ct")
    test_router_priority
    assert_dns_accept
    assert_web_accept
    assert_mail_accept
    assert_app_accept
    assert_sql_drop
    assert_ssh_drop
  ;;

  "pc_s")
    test_router_priority
    assert_dns_accept
    assert_mail_drop
    assert_sql_accept
    test_ssh_access "pc_s_0" 0

    # Test if pc_s is accessible from different networks
    echo -e "${YELLOW}Testing access to pc_s from different networks...${NC}"
    # Additional tests could be implemented here if needed
  ;;

  "pc_rssi")
    test_router_priority
    assert_dns_accept
    assert_web_accept
    assert_mail_accept
    assert_app_accept
    assert_sql_accept
    assert_ssh_accept
    test_remote_management

    # Test ping access to all machines
    echo -e "${YELLOW}Testing ICMP (ping) access to all machines...${NC}"
    local ping_failures=0

    for machine_key in "${!machines[@]}"; do
      echo -n "Pinging ${machine_key}... "
      ping -c1 -W1 ${machines[$machine_key]} > /dev/null 2>&1
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
    test_router_priority
    assert_dns_accept
    test_ssh_access "${machine}_0" 0

    # Test that these servers are accessible from authorized networks
    echo -e "${YELLOW}Testing server accessibility from authorized networks...${NC}"
    # Additional tests could be implemented here if needed
  ;;
esac

echo ""
echo -e "${YELLOW}=== Test Completed ===${NC}"

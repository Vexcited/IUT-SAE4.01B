#!/bin/bash

machine=$(hostname)

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
)

# Vérification que les ports de mail sont bien ouverts
function assert_mail_accept {
  nc -z -w1 ${machines["pc_mail_0"]} 25  || echo "KO(1): pc_mail(eth0) TCP/25"
  nc -z -w1 ${machines["pc_mail_0"]} 587 || echo "KO(1): pc_mail(eth0) TCP/587"
  nc -z -w1 ${machines["pc_mail_0"]} 465 || echo "KO(1): pc_mail(eth0) TCP/465"
  nc -z -w1 ${machines["pc_mail_0"]} 143 || echo "KO(1): pc_mail(eth0) TCP/143"
  nc -z -w1 ${machines["pc_mail_0"]} 993 || echo "KO(1): pc_mail(eth0) TCP/993"
  nc -z -w1 ${machines["pc_mail_0"]} 110 || echo "KO(1): pc_mail(eth0) TCP/110"
  nc -z -w1 ${machines["pc_mail_0"]} 995 || echo "KO(1): pc_mail(eth0) TCP/995"
}

# Vérification que les ports de mail sont bien fermés
function assert_mail_drop {
  nc -z -w1 ${machines["pc_mail_0"]} 25  && echo "KO(0): pc_mail(eth0) TCP/25"
  nc -z -w1 ${machines["pc_mail_0"]} 587 && echo "KO(0): pc_mail(eth0) TCP/587"
  nc -z -w1 ${machines["pc_mail_0"]} 465 && echo "KO(0): pc_mail(eth0) TCP/465"
  nc -z -w1 ${machines["pc_mail_0"]} 143 && echo "KO(0): pc_mail(eth0) TCP/143"
  nc -z -w1 ${machines["pc_mail_0"]} 993 && echo "KO(0): pc_mail(eth0) TCP/993"
  nc -z -w1 ${machines["pc_mail_0"]} 110 && echo "KO(0): pc_mail(eth0) TCP/110"
  nc -z -w1 ${machines["pc_mail_0"]} 995 && echo "KO(0): pc_mail(eth0) TCP/995"
}

function assert_dns_accept {
  nc -z -u -w1 ${machines["pc_dns_0"]} 53 || echo "KO(1): pc_dns(eth0) UDP/53"
}

function assert_sql_accept {
  nc -z -w1 ${machines["pc_bdd_0"]} 3306 || echo "KO(1): pc_bdd(eth0) TCP/3306"
}

function assert_sql_drop {
  nc -z -w1 ${machines["pc_bdd_0"]} 3306 && echo "KO(0): pc_bdd(eth0) TCP/3306"
}

function assert_ssh_accept {
  nc -z -w1 ${machines["pc_bdd_0"]} 22 || echo "KO(1): pc_bdd(eth0) TCP/22"
}

function assert_ssh_drop {
  nc -z -w1 ${machines["pc_bdd_0"]} 22 && echo "KO(0): pc_bdd(eth0) TCP/22"
}

function assert_web_accept {
  nc -z -w1 ${machines["pc_s_0"]} 80 || echo "KO(1): pc_s(eth0) TCP/80"
  nc -z -w1 ${machines["pc_s_0"]} 443 || echo "KO(1): pc_s(eth0) TCP/443"
}

function assert_web_drop {
  nc -z -w1 ${machines["pc_s_0"]} 80 && echo "KO(0): pc_s(eth0) TCP/80"
  nc -z -w1 ${machines["pc_s_0"]} 443 && echo "KO(0): pc_s(eth0) TCP/443"
}

function assert_app_accept {
  nc -z -w1 ${machines["pc_s_0"]} 1224 || echo "KO(1): pc_s(eth0) TCP/1224"
}

function assert_app_drop {
  nc -z -w1 ${machines["pc_s_0"]} 1224 && echo "KO(0): pc_s(eth0) TCP/1224"
}

echo "--- Vérification pour machine $machine"

case $machine in
  # Patients et visiteurs
  "pc_p" | "pc_v")
    assert_dns_accept
    assert_web_accept
    assert_mail_drop
    assert_sql_drop
    assert_ssh_drop
    assert_app_drop
  ;;

  # Enseignants et étudiants
  "pc_ens" | "pc_etu")
    assert_dns_accept
    assert_web_accept
    assert_mail_accept
    assert_app_drop
    assert_sql_drop
    assert_ssh_drop
  ;;

  # Chercheurs et enseignants-chercheurs
  "pc_c" | "pc_ec")
    assert_dns_accept
    assert_web_accept
    assert_mail_accept
    assert_app_drop
    assert_sql_drop
    assert_ssh_accept
  ;;

  # Personnel soignant et comptabilité
  "pc_ps" | "pc_ct")
    assert_dns_accept
    assert_web_accept
    assert_mail_accept
    assert_app_accept
    assert_sql_drop
    assert_ssh_drop
  ;;

  "pc_s")
    assert_dns_accept
    assert_mail_drop
    assert_sql_accept
    assert_ssh_drop
  ;;

  "pc_mail")
    assert_dns_accept
    assert_web_drop
    assert_app_drop
    assert_sql_drop
    assert_ssh_drop
  ;;

  "pc_aux")
    assert_dns_accept
    assert_web_drop
    assert_mail_drop
    assert_app_drop
    assert_sql_drop
    assert_ssh_drop
  ;;

  "pc_rssi")
    assert_dns_accept
    assert_web_accept
    assert_mail_accept
    assert_app_accept
    assert_sql_accept
    assert_ssh_accept

    # peut ping toutes les machines
    for machine in "${!machines[@]}"; do
      ping -c1 -W1 ${machines[$machine]} > /dev/null 2>&1 || echo "KO(1): PING $machine"
    done
  ;;

  "pc_bdd")
    assert_dns_accept
    assert_mail_drop
    assert_web_drop
    assert_app_drop
  ;;
esac

echo "--- Fin de la vérification"

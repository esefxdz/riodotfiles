#!/usr/bin/env bash
# ──────────────────────────────────────────────────────────────────────────────
#  zapret auto install tool
#  it runs during installation so you wont see this
#  idk why you d be reading this tho
#  it ll handle everything automatically
# ──────────────────────────────────────────────────────────────────────────────

strict=false
dev=false
debug=false

for arg in "${@}"; do
  [ "${arg}" = "--strict" ] && strict=true
  [ "${arg}" = "--dev" ]    && dev=true
  [ "${arg}" = "--debug" ]  && debug=true
done

log_redirects="/dev/null"
[ "${debug}" = true ] && log_redirects="/dev/stdout"

# ── colors ────────────────────────────────────────────────────────────────────
RED='\033[1;31m'
GRN='\033[1;32m'
YEL='\033[1;33m'
CYN='\033[1;36m'
RST='\033[0m'

info()    { echo -e "${CYN}[·]${RST} $1"; }
success() { echo -e "${GRN}[✓]${RST} $1"; }
warn()    { echo -e "${YEL}[!]${RST} $1"; }
die()     { echo -e "${RED}[✗]${RST} $1"; exit 1; }

# ── banner ────────────────────────────────────────────────────────────────────
banner() {
  echo ""
  echo -e "${RED}══════════════════════════════════════════${RST}"
  echo -e "${RED}  ◈  RIO — ZAPRET DEPLOY                 ◈${RST}"
  echo -e "${RED}    unblocking stuff rq. hold on, esef.    ${RST}"
  echo -e "${RED}══════════════════════════════════════════${RST}"
  echo ""
}

zapret_version="72.12"
blockcheck_domain="unknown"

# ── system detection ──────────────────────────────────────────────────────────

detect_system() {
  if   command -v systemctl  &> /dev/null; then init_system="systemd"
  elif command -v dinitctl   &> /dev/null; then init_system="dinit"
  elif command -v sv         &> /dev/null; then init_system="runit"
  elif command -v s6-svscan  &> /dev/null || command -v s6-rc &> /dev/null; then init_system="s6"
  elif command -v rc-service &> /dev/null; then init_system="openrc"
  elif command -v launchctl  &> /dev/null; then init_system="launchd"
  elif [ -d /opt/etc/init.d ];             then init_system="entware"
  elif command -v service    &> /dev/null || [ -x /usr/sbin/service ] || [ -d /etc/init.d ]; then init_system="sysvinit"
  elif [ -d /etc/rc.d ];                   then init_system="rc"
  else                                          init_system="unknown"
  fi

  if   command -v apt          &> /dev/null; then package_manager="apt"
  elif command -v rpm-ostree   &> /dev/null; then package_manager="rpm-ostree"
  elif command -v dnf          &> /dev/null; then package_manager="dnf"
  elif command -v pacman       &> /dev/null; then package_manager="pacman"
  elif command -v zypper       &> /dev/null; then package_manager="zypper"
  elif command -v xbps-install &> /dev/null; then package_manager="xbps"
  elif command -v apk          &> /dev/null; then package_manager="apk"
  elif command -v emerge       &> /dev/null; then package_manager="emerge"
  elif command -v slackpkg     &> /dev/null; then package_manager="slackpkg"
  elif command -v eopkg        &> /dev/null; then package_manager="eopkg"
  elif command -v opkg         &> /dev/null; then package_manager="opkg"
  else                                            package_manager="unknown"
  fi
}

detect_system

# ── service helpers ───────────────────────────────────────────────────────────

start_service() {
  local svc="${1}"
  case "${init_system}" in
    systemd)  systemctl start "${svc}"                                                        &> "${log_redirects}" ;;
    dinit)    dinitctl start "${svc}"                                                         &> "${log_redirects}" ;;
    runit)    sv start "${svc}"                                                               &> "${log_redirects}" ;;
    s6)       if command -v s6-rc &> /dev/null; then
                s6-rc -u change "${svc}"                                                      &> "${log_redirects}"
              else
                s6-svc -u "$(find /etc/s6-servicedirs /etc/s6/sv -maxdepth 0 -type d 2>/dev/null | head -1)"/"${svc}" &> "${log_redirects}"
              fi ;;
    openrc)   rc-service "${svc}" start                                                       &> "${log_redirects}" ;;
    launchd)  launchctl start "${svc}"                                                        &> "${log_redirects}" ;;
    entware)  "$(ls /opt/etc/init.d/*"${svc}" 2>/dev/null | head -1)" start                 &> "${log_redirects}" ;;
    sysvinit) if command -v service &> /dev/null; then
                service "${svc}" start &> "${log_redirects}"
              else
                /etc/init.d/"${svc}" start &> "${log_redirects}"
              fi ;;
    rc)       /etc/rc.d/rc."${svc}" start &> "${log_redirects}" ;;
    *)        die "unsupported init system — cannot start ${svc}" ;;
  esac
}

restart_service() {
  local svc="${1}"
  case "${init_system}" in
    systemd)  systemctl restart "${svc}"                                                      &> "${log_redirects}" ;;
    dinit)    dinitctl restart "${svc}"                                                       &> "${log_redirects}" ;;
    runit)    sv restart "${svc}"                                                             &> "${log_redirects}" ;;
    s6)       if command -v s6-rc &> /dev/null; then
                s6-rc -d change "${svc}" &> "${log_redirects}"
                s6-rc -u change "${svc}"                                                      &> "${log_redirects}"
              else
                s6-svc -r "$(find /etc/s6-servicedirs /etc/s6/sv -maxdepth 0 -type d 2>/dev/null | head -1)"/"${svc}" &> "${log_redirects}"
              fi ;;
    openrc)   rc-service "${svc}" restart                                                     &> "${log_redirects}" ;;
    launchd)  launchctl stop "${svc}" &> "${log_redirects}"; launchctl start "${svc}"        &> "${log_redirects}" ;;
    entware)  "$(ls /opt/etc/init.d/*"${svc}" 2>/dev/null | head -1)" restart               &> "${log_redirects}" ;;
    sysvinit) if command -v service &> /dev/null; then
                service "${svc}" restart &> "${log_redirects}"
              else
                /etc/init.d/"${svc}" restart &> "${log_redirects}"
              fi ;;
    rc)       /etc/rc.d/rc."${svc}" restart &> "${log_redirects}" ;;
    *)        die "unsupported init system — cannot restart ${svc}" ;;
  esac
}

enable_service() {
  local svc="${1}"
  case "${init_system}" in
    systemd)  systemctl enable "${svc}"                                                       &> "${log_redirects}" ;;
    dinit)    dinitctl enable "${svc}"                                                        &> "${log_redirects}" ;;
    runit)
      local rsvc_dir; rsvc_dir="$(find /etc/sv /etc/runit/sv -maxdepth 0 -type d 2>/dev/null | head -1)"
      local ren_dir;  ren_dir="$(find /etc/service /var/service /run/runit/service /service -maxdepth 0 -type d 2>/dev/null | head -1)"
      [ -d "${rsvc_dir}/${svc}" ] && ln -sf "${rsvc_dir}/${svc}" "${ren_dir}/${svc}"         &> "${log_redirects}" ;;
    s6)       : ;;
    openrc)   rc-update add "${svc}" default                                                  &> "${log_redirects}" ;;
    launchd)  launchctl load -w /Library/LaunchDaemons/"${svc}".plist                        &> "${log_redirects}" ;;
    entware)  : ;;
    sysvinit) if command -v update-rc.d &> /dev/null; then
                update-rc.d "${svc}" defaults &> "${log_redirects}"
              elif command -v chkconfig &> /dev/null; then
                chkconfig "${svc}" on &> "${log_redirects}"
              fi ;;
    rc)       : ;;
    *)        die "unsupported init system — cannot enable ${svc}" ;;
  esac
}

# ── package helper ────────────────────────────────────────────────────────────

install_package() {
  local pkg="${1}"
  case "${package_manager}" in
    apt)        apt install -y "${pkg}"                                &> "${log_redirects}" ;;
    rpm-ostree) rpm-ostree install --apply-live "${pkg}"              &> "${log_redirects}" ;;
    dnf)        dnf install -y "${pkg}"                               &> "${log_redirects}" ;;
    pacman)     pacman -S --noconfirm "${pkg}"                        &> "${log_redirects}" ;;
    zypper)     zypper -n install "${pkg}"                            &> "${log_redirects}" ;;
    xbps)       xbps-install -y "${pkg}"                             &> "${log_redirects}" ;;
    apk)        apk add "${pkg}"                                      &> "${log_redirects}" ;;
    emerge)     emerge "${pkg}"                                       &> "${log_redirects}" ;;
    slackpkg)   slackpkg -batch=on -default_answer=y install "${pkg}" &> "${log_redirects}" ;;
    eopkg)      eopkg install -y "${pkg}"                             &> "${log_redirects}" ;;
    opkg)       opkg install "${pkg}"                                 &> "${log_redirects}" ;;
    *)          die "unsupported package manager" ;;
  esac
}

# ── init zapret for non-systemd systems ───────────────────────────────────────

init_zapret() {
  case "${init_system}" in
    systemd|openrc|launchd) : ;;
    dinit)
      tee /etc/dinit.d/zapret &> /dev/null << EOF
type = scripted
command = /opt/zapret/init.d/sysv/zapret start
stop-command = /opt/zapret/init.d/sysv/zapret stop
restart = false
EOF
      ;;
    runit)
      local rsvc_dir; rsvc_dir="$(find /etc/sv /etc/runit/sv -maxdepth 0 -type d 2>/dev/null | head -1)"
      [ -d /opt/zapret/init.d/runit/zapret ] && ln -sf /opt/zapret/init.d/runit/zapret "${rsvc_dir}/zapret" &> "${log_redirects}" ;;
    s6)
      local s6_dir; s6_dir="$(find /etc/s6-servicedirs /etc/s6/sv -maxdepth 0 -type d 2>/dev/null | head -1)"
      [ -d /opt/zapret/init.d/s6/zapret ] && ln -sf /opt/zapret/init.d/s6/zapret "${s6_dir}/zapret"         &> "${log_redirects}" ;;
    entware)
      tee /opt/etc/init.d/S90zapret &> /dev/null << 'EOF'
#!/bin/sh
case "${1}" in
  start)   /opt/zapret/init.d/sysv/zapret start ;;
  stop)    /opt/zapret/init.d/sysv/zapret stop ;;
  restart) /opt/zapret/init.d/sysv/zapret stop; /opt/zapret/init.d/sysv/zapret start ;;
  *)       echo "Usage: ${0} {start|stop|restart}"; exit 1 ;;
esac
EOF
      chmod +x /opt/etc/init.d/S90zapret ;;
    sysvinit)
      [ -f /opt/zapret/init.d/sysv/zapret ] && ln -sf /opt/zapret/init.d/sysv/zapret /etc/init.d/zapret     &> "${log_redirects}" ;;
    rc)
      [ -f /opt/zapret/init.d/sysv/zapret ] && ln -sf /opt/zapret/init.d/sysv/zapret /etc/rc.d/rc.zapret    &> "${log_redirects}" ;;
  esac
}

# ── find dnscrypt config ──────────────────────────────────────────────────────

find_dnscrypt_config() {
  local paths=(
    "/etc/dnscrypt-proxy.toml"
    "/etc/dnscrypt-proxy/dnscrypt-proxy.toml"
    "/usr/local/etc/dnscrypt-proxy.toml"
    "/usr/local/etc/dnscrypt-proxy/dnscrypt-proxy.toml"
    "/opt/etc/dnscrypt-proxy.toml"
    "/opt/etc/dnscrypt-proxy/dnscrypt-proxy.toml"
    "/opt/dnscrypt-proxy/dnscrypt-proxy.toml"
  )
  for p in "${paths[@]}"; do
    [ -f "${p}" ] && echo "${p}" && return
  done
  if [ -f "/usr/share/defaults/dnscrypt-proxy/dnscrypt-proxy.toml" ]; then
    mkdir -p /etc/dnscrypt-proxy &> "${log_redirects}"
    cp /usr/share/defaults/dnscrypt-proxy/dnscrypt-proxy.toml /etc/dnscrypt-proxy/dnscrypt-proxy.toml &> "${log_redirects}"
    echo "/etc/dnscrypt-proxy/dnscrypt-proxy.toml"
  else
    echo ""
  fi
}

# ── preflight ─────────────────────────────────────────────────────────────────

banner

[ "$(uname)" != "Linux" ] && die "this is linux-only. that's not arch."
[ "${EUID}" != "0" ]      && die "need root. sudo bash install.sh — don't make me repeat myself."

# ── dependencies ──────────────────────────────────────────────────────────────

info "pulling dependencies — this'll be quick."

for pkg in bind bind-tools bind-utils bind9-dnsutils bind920 curl gzip iptables jq nftables tar wget wget-ssl; do
  install_package "${pkg}"
done

if ! command -v dig  &> /dev/null || ! command -v curl &> /dev/null || \
   ! command -v jq   &> /dev/null || ! command -v tar  &> /dev/null || \
   ! command -v wget &> /dev/null; then
  die "something's missing after install. your system might be too old for this."
fi

success "deps sorted."

# ── encrypted DNS ─────────────────────────────────────────────────────────────

info "encrypting your DNS — erdogan can't snoop what it can't read."

if [ "${init_system}" = "systemd" ]; then
  install_package systemd-resolved
  install_package dnscrypt-proxy
  install_package dnscrypt-proxy2
  install_package "dnscrypt-proxy-${init_system}"
  install_package "dnscrypt-proxy2-${init_system}"

  enable_service systemd-resolved
  start_service  systemd-resolved
  enable_service dnscrypt-proxy
  enable_service dnscrypt-proxy2
  start_service  dnscrypt-proxy
  start_service  dnscrypt-proxy2

  dnscrypt_config="$(find_dnscrypt_config)"
  [ -z "${dnscrypt_config}" ] && die "dnscrypt config not found"

  # reset resolved.conf — stub resolver takes port 5300 while dnscrypt bootstraps
  tee /etc/systemd/resolved.conf &> /dev/null <<< ""
  chattr -i /etc/resolv.conf &> "${log_redirects}"
  [ -f /run/systemd/resolve/stub-resolv.conf ] && ln -sf /run/systemd/resolve/stub-resolv.conf /etc/resolv.conf &> "${log_redirects}"
  restart_service systemd-resolved

  mkdir -p /var/cache/dnscrypt-proxy &> "${log_redirects}"
  tee "${dnscrypt_config}" &> /dev/null << EOF
listen_addresses = ["127.0.0.1:5300", "[::1]:5300"]

[sources.public-resolvers]
urls = [
  "https://raw.github.com/dnscrypt/dnscrypt-resolvers/refs/heads/master/v3/public-resolvers.md",
  "https://raw.githack.com/dnscrypt/dnscrypt-resolvers/refs/heads/master/v3/public-resolvers.md",
  "https://cdn.jsdelivr.net/gh/dnscrypt/dnscrypt-resolvers/v3/public-resolvers.md",
  "https://download.dnscrypt.info/resolvers-list/v3/public-resolvers.md"
]
minisign_key = "RWQf6LRCGA9i53mlYecO4IzT51TGPpvWucNSCh1CBM0QTaLn73Y7GFO3"
cache_file = "/var/cache/dnscrypt-proxy/public-resolvers.md"
EOF

  restart_service dnscrypt-proxy
  restart_service dnscrypt-proxy2

  # hold here until dnscrypt is actually up — don't rush this part
  while ! dig -p 5300 +tries=1 +time=10 @127.0.0.1 &> /dev/null && \
        ! dig -p 5300 +tries=1 +time=10 @::1       &> /dev/null; do
    restart_service dnscrypt-proxy
    restart_service dnscrypt-proxy2
    sleep 10
  done

  tee /etc/systemd/resolved.conf &> /dev/null << EOF
[Resolve]
DNS=127.0.0.1:5300
DNS=[::1]:5300
Domains=~.
DNSOverTLS=no
EOF

  chattr -i /etc/resolv.conf &> "${log_redirects}"
  [ -f /run/systemd/resolve/stub-resolv.conf ] && ln -sf /run/systemd/resolve/stub-resolv.conf /etc/resolv.conf &> "${log_redirects}"
  restart_service systemd-resolved

else
  if [ "${package_manager}" = "opkg" ]; then
    install_package dnscrypt-proxy2
  else
    install_package dnscrypt-proxy
  fi
  install_package "dnscrypt-proxy-${init_system}"
  install_package "dnscrypt-proxy2-${init_system}"

  enable_service dnscrypt-proxy
  enable_service dnscrypt-proxy2
  start_service  dnscrypt-proxy
  start_service  dnscrypt-proxy2

  dnscrypt_config="$(find_dnscrypt_config)"
  [ -z "${dnscrypt_config}" ] && die "dnscrypt config not found"

  # temporary Cloudflare nameservers while dnscrypt spins up
  chattr -i /etc/resolv.conf &> "${log_redirects}"
  tee /etc/resolv.conf &> /dev/null << EOF
nameserver 1.1.1.1
nameserver 2606:4700:4700::1111
nameserver 1.0.0.1
nameserver 2606:4700:4700::1001
EOF

  mkdir -p /var/cache/dnscrypt-proxy &> "${log_redirects}"
  tee "${dnscrypt_config}" &> /dev/null << EOF
listen_addresses = ["127.0.0.1:53", "[::1]:53"]

[sources.public-resolvers]
urls = [
  "https://raw.github.com/dnscrypt/dnscrypt-resolvers/refs/heads/master/v3/public-resolvers.md",
  "https://raw.githack.com/dnscrypt/dnscrypt-resolvers/refs/heads/master/v3/public-resolvers.md",
  "https://cdn.jsdelivr.net/gh/dnscrypt/dnscrypt-resolvers/v3/public-resolvers.md",
  "https://download.dnscrypt.info/resolvers-list/v3/public-resolvers.md"
]
minisign_key = "RWQf6LRCGA9i53mlYecO4IzT51TGPpvWucNSCh1CBM0QTaLn73Y7GFO3"
cache_file = "/var/cache/dnscrypt-proxy/public-resolvers.md"
EOF

  restart_service dnscrypt-proxy
  restart_service dnscrypt-proxy2

  while ! dig -p 53 +tries=1 +time=10 @127.0.0.1 &> /dev/null && \
        ! dig -p 53 +tries=1 +time=10 @::1       &> /dev/null; do
    restart_service dnscrypt-proxy
    restart_service dnscrypt-proxy2
    sleep 10
  done

  # lock resolv.conf — nothing touches it after this
  chattr -i /etc/resolv.conf &> "${log_redirects}"
  tee /etc/resolv.conf &> /dev/null << EOF
nameserver 127.0.0.1
nameserver ::1
EOF
  chattr +i /etc/resolv.conf &> "${log_redirects}"
fi

success "DNS encrypted."

# ── download zapret ───────────────────────────────────────────────────────────

info "fetching zapret v${zapret_version}..."

[ -x /opt/zapret/uninstall_easy.sh ] && echo -e "Y\n\n" | /opt/zapret/uninstall_easy.sh &> "${log_redirects}"
rm -rf /opt/zapret &> "${log_redirects}"
rm -f  /tmp/zapret.tar.gz &> "${log_redirects}"

wget -O /tmp/zapret.tar.gz "https://github.com/bol-van/zapret/releases/download/v${zapret_version}/zapret-v${zapret_version}.tar.gz" &> "${log_redirects}"
tar -xz -f /tmp/zapret.tar.gz -C /tmp &> "${log_redirects}"
rm -f /tmp/zapret.tar.gz &> "${log_redirects}"
cp -r "/tmp/zapret-v${zapret_version}" /opt/zapret &> "${log_redirects}"
rm -rf "/tmp/zapret-v${zapret_version}" &> "${log_redirects}"

info "building binaries..."
echo -e "\n\n" | /opt/zapret/install_prereq.sh &> "${log_redirects}"
/opt/zapret/install_bin.sh &> "${log_redirects}"

success "zapret deployed to /opt/zapret."

# ── blockcheck ────────────────────────────────────────────────────────────────

info "running blockcheck."

# walk the domain list — first one curl can't reach is what's being blocked
blockcheck_domains=(
  discord.com facebook.com google.com instagram.com pornhub.com
  roblox.com steampowered.com tiktok.com x.com yandex.com youtube.com
)

for domain in "${blockcheck_domains[@]}"; do
  blockcheck_domain="${domain}"
  curl --max-time 10 "https://${domain}" &> /dev/null || break
done

# --blockcheck-domain override takes priority over auto-detected domain
while [ $# -gt 0 ]; do
  if echo "${1}" | grep -iq "^--blockcheck-domain="; then
    blockcheck_domain="${1#*=}"; shift
  elif [ "${1}" = "--blockcheck-domain" ]; then
    blockcheck_domain="${2}"; shift 2
  else
    shift
  fi
done

if [ "${dev}" = true ]; then
  bypass_methods="--dpi-desync=fake --dpi-desync-ttl=3"
else
  blockcheck_results=$(echo -e "${blockcheck_domain}\n\nN\n\n\n\n\n\n\n" | \
    /opt/zapret/blockcheck.sh 2> "${log_redirects}" | \
    sed -n "/^\* SUMMARY/,/^$/ { /^\* SUMMARY/d; /^$/d; p; }")

  [ "${debug}" = true ] && echo "${blockcheck_results}"

  bypass_results=$(echo "${blockcheck_results}" | grep -E "curl_test_https[^ ]* ipv[0-9] ${blockcheck_domain} : nfqws")

  pick="head"
  [ "${strict}" = true ] && pick="tail"

  if echo "${bypass_results}" | grep -iq "ttl"; then
    bypass_methods=$(echo "${bypass_results}" | grep "ttl" | "${pick}" -n 1)
  else
    bypass_methods=$(echo "${bypass_results}" | "${pick}" -n 1)
  fi

  bypass_methods=$(echo "${bypass_methods}" | sed "s/.*nfqws //" | sed -z "s/^[[:space:]]*//; s/[[:space:]]*$//")
fi

if echo "${blockcheck_results}" | grep -iq "nftables queue support is not available"; then
  echo -e "Y\n\n" | /opt/zapret/uninstall_easy.sh &> "${log_redirects}"
  rm -rf /opt/zapret &> "${log_redirects}"
  die "your kernel has no nftables queue support. too old. update it."
  die "your kernel is archaic. update it, esef."
  #these are comments i ll never see but allg
fi

if ! echo "${bypass_methods}" | grep -iq -- "--"; then
  echo -e "Y\n\n" | /opt/zapret/uninstall_easy.sh &> "${log_redirects}"
  rm -rf /opt/zapret &> "${log_redirects}"
  success "allg, esef"
  exit 0
fi

info "isolated. method: ${bypass_methods}"

# ── install zapret ────────────────────────────────────────────────────────────

info "integrating zapret."

prototype=$(echo -e "\n\n\n\n\n\n\n\n\n\n\n" | /opt/zapret/install_easy.sh 2> "${log_redirects}")

if echo "${prototype}" | grep -iq "system is not either systemd"; then
  if echo "${prototype}" | grep -iq "readonly system detected"; then
    installation_results=$(echo -e "Y\nY\n\n\n\n4\n\n\nY\n\n\n\n\n" | /opt/zapret/install_easy.sh 2> "${log_redirects}")
  else
    installation_results=$(echo -e "Y\n\n\n\n4\n\n\nY\n\n\n\n\n"   | /opt/zapret/install_easy.sh 2> "${log_redirects}")
  fi
else
  if echo "${prototype}" | grep -iq "readonly system detected"; then
    installation_results=$(echo -e "Y\n\n\n\n4\n\n\nY\n\n\n\n\n" | /opt/zapret/install_easy.sh 2> "${log_redirects}")
  else
    installation_results=$(echo -e "\n\n\n4\n\n\nY\n\n\n\n\n"    | /opt/zapret/install_easy.sh 2> "${log_redirects}")
  fi
fi

[ "${debug}" = true ] && echo "${installation_results}"

if echo "${installation_results}" | grep -iq "readonly system detected"; then
  echo -e "Y\n\n" | /opt/zapret/uninstall_easy.sh &> "${log_redirects}"
  rm -rf /opt/zapret &> "${log_redirects}"
  die "filesytem is read-only. resolve it."
fi

if echo "${installation_results}" | grep -iq "could not start zapret service"; then
  echo -e "Y\n\n" | /opt/zapret/uninstall_easy.sh &> "${log_redirects}"
  rm -rf /opt/zapret &> "${log_redirects}"
  die "service failure. check logs, esef."
fi

# install_easy skips non-systemd — handle that ourselves
echo "${installation_results}" | grep -iq "system is not either systemd" && init_zapret

enable_service zapret
start_service  zapret

# inject the bypass flags blockcheck found into zapret's config
sed -i "s|^NFQWS_OPT=.*|NFQWS_OPT=\"${bypass_methods} <HOSTLIST>\"|" /opt/zapret/config

restart_service zapret

# seed the nfqws rule cache before handing off — first few packets matter
for i in {1..3}; do
  curl --max-time 1 https://discord.com &> /dev/null
done

# ── done ──────────────────────────────────────────────────────────────────────

echo -e "${RED}done xd.${RST}"
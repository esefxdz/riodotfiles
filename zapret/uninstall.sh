#!/usr/bin/env bash
# ──────────────────────────────────────────────────────────────────────────────
#  uninstall script
#  run as root
#  this one is ai made tho
#  it should work tho i didnt review much 
# ──────────────────────────────────────────────────────────────────────────────

debug=false

for arg in "${@}"; do
  [ "${arg}" = "--debug" ] && debug=true
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
echo ""
echo -e "${RED}══════════════════════════════════════════${RST}"
echo -e "${RED}  ◈  RIO — ZAPRET TEARDOWN               ◈${RST}"
echo -e "${RED}  rolling back. won't take long, esef.    ${RST}"
echo -e "${RED}══════════════════════════════════════════${RST}"
echo ""

# ── preflight ─────────────────────────────────────────────────────────────────

[ "$(uname)" != "Linux" ] && die "this is linux-only. that's not arch."
[ "${EUID}" != "0" ]      && die "need root. sudo bash uninstall.sh — don't make me repeat myself."

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

stop_service() {
  local svc="${1}"
  case "${init_system}" in
    systemd)  systemctl stop "${svc}"                                                         &> "${log_redirects}" ;;
    dinit)    dinitctl stop "${svc}"                                                          &> "${log_redirects}" ;;
    runit)    sv stop "${svc}"                                                                &> "${log_redirects}" ;;
    s6)       if command -v s6-rc &> /dev/null; then
                s6-rc -d change "${svc}"                                                      &> "${log_redirects}"
              else
                s6-svc -d "$(find /etc/s6-servicedirs /etc/s6/sv -maxdepth 0 -type d 2>/dev/null | head -1)"/"${svc}" &> "${log_redirects}"
              fi ;;
    openrc)   rc-service "${svc}" stop                                                        &> "${log_redirects}" ;;
    launchd)  launchctl stop "${svc}"                                                         &> "${log_redirects}" ;;
    entware)  "$(ls /opt/etc/init.d/*"${svc}" 2>/dev/null | head -1)" stop                  &> "${log_redirects}" ;;
    sysvinit) if command -v service &> /dev/null; then
                service "${svc}" stop &> "${log_redirects}"
              else
                /etc/init.d/"${svc}" stop &> "${log_redirects}"
              fi ;;
    rc)       /etc/rc.d/rc."${svc}" stop &> "${log_redirects}" ;;
    *)        warn "unsupported init system — skipping stop for ${svc}" ;;
  esac
}

disable_service() {
  local svc="${1}"
  case "${init_system}" in
    systemd)  systemctl disable "${svc}"                                                      &> "${log_redirects}" ;;
    dinit)    dinitctl disable "${svc}"                                                       &> "${log_redirects}" ;;
    runit)
      local ren_dir; ren_dir="$(find /etc/service /var/service /run/runit/service /service -maxdepth 0 -type d 2>/dev/null | head -1)"
      [ -L "${ren_dir}/${svc}" ] && rm -f "${ren_dir}/${svc}"                                &> "${log_redirects}" ;;
    s6)       : ;;
    openrc)   rc-update del "${svc}" default                                                  &> "${log_redirects}" ;;
    launchd)  launchctl unload -w /Library/LaunchDaemons/"${svc}".plist                      &> "${log_redirects}" ;;
    entware)  : ;;
    sysvinit) if command -v update-rc.d &> /dev/null; then
                update-rc.d "${svc}" remove &> "${log_redirects}"
              elif command -v chkconfig &> /dev/null; then
                chkconfig "${svc}" off &> "${log_redirects}"
              fi ;;
    rc)       : ;;
    *)        warn "unsupported init system — skipping disable for ${svc}" ;;
  esac
}

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
    *)        warn "unsupported init system — skipping start for ${svc}" ;;
  esac
}

enable_service() {
  local svc="${1}"
  case "${init_system}" in
    systemd)  systemctl enable "${svc}"                                                       &> "${log_redirects}" ;;
    dinit)    dinitctl enable "${svc}"                                                        &> "${log_redirects}" ;;
    openrc)   rc-update add "${svc}" default                                                  &> "${log_redirects}" ;;
    launchd)  launchctl load -w /Library/LaunchDaemons/"${svc}".plist                        &> "${log_redirects}" ;;
    *)        : ;;
  esac
}

# ── package helper ────────────────────────────────────────────────────────────

remove_package() {
  local pkg="${1}"
  case "${package_manager}" in
    apt)        apt purge -y --autoremove "${pkg}"                        &> "${log_redirects}" ;;
    rpm-ostree) rpm-ostree uninstall --apply-live "${pkg}"               &> "${log_redirects}" ;;
    dnf)        dnf remove -y "${pkg}"                                   &> "${log_redirects}" ;;
    pacman)     pacman -Rns --noconfirm "${pkg}"                         &> "${log_redirects}" ;;
    zypper)     zypper -n remove -u "${pkg}"                             &> "${log_redirects}" ;;
    xbps)       xbps-remove -Ry "${pkg}"                                 &> "${log_redirects}" ;;
    apk)        apk del "${pkg}"                                         &> "${log_redirects}" ;;
    emerge)     emerge --unmerge "${pkg}"                                &> "${log_redirects}" ;;
    slackpkg)   slackpkg -batch=on -default_answer=y remove "${pkg}"    &> "${log_redirects}" ;;
    eopkg)      eopkg remove -y --purge "${pkg}"                         &> "${log_redirects}" ;;
    opkg)       opkg remove --autoremove "${pkg}"                        &> "${log_redirects}" ;;
    *)          warn "unsupported package manager — skipping removal of ${pkg}" ;;
  esac
}

install_package() {
  local pkg="${1}"
  case "${package_manager}" in
    apt)        apt install -y "${pkg}"                                   &> "${log_redirects}" ;;
    rpm-ostree) rpm-ostree install --apply-live "${pkg}"                 &> "${log_redirects}" ;;
    dnf)        dnf install -y "${pkg}"                                  &> "${log_redirects}" ;;
    pacman)     pacman -S --noconfirm "${pkg}"                           &> "${log_redirects}" ;;
    zypper)     zypper -n install "${pkg}"                               &> "${log_redirects}" ;;
    xbps)       xbps-install -y "${pkg}"                                 &> "${log_redirects}" ;;
    apk)        apk add "${pkg}"                                         &> "${log_redirects}" ;;
    emerge)     emerge "${pkg}"                                          &> "${log_redirects}" ;;
    slackpkg)   slackpkg -batch=on -default_answer=y install "${pkg}"   &> "${log_redirects}" ;;
    eopkg)      eopkg install -y "${pkg}"                                &> "${log_redirects}" ;;
    opkg)       opkg install "${pkg}"                                    &> "${log_redirects}" ;;
    *)          warn "unsupported package manager — skipping ${pkg}" ;;
  esac
}

# ── restore DNS ───────────────────────────────────────────────────────────────

info "restoring DNS..."

if [ "${init_system}" = "systemd" ]; then
  # re-ensure systemd-resolved is present and healthy
  install_package systemd-resolved
  enable_service systemd-resolved
  start_service  systemd-resolved

  # remove dnscrypt
  stop_service    dnscrypt-proxy
  stop_service    dnscrypt-proxy2
  disable_service dnscrypt-proxy
  disable_service dnscrypt-proxy2
  remove_package  dnscrypt-proxy
  remove_package  dnscrypt-proxy2
  remove_package  "dnscrypt-proxy-${init_system}"
  remove_package  "dnscrypt-proxy2-${init_system}"

  # clear the locked resolved.conf and restore stub symlink
  tee /etc/systemd/resolved.conf &> /dev/null <<< ""
  chattr -i /etc/resolv.conf &> "${log_redirects}"
  [ -f /run/systemd/resolve/stub-resolv.conf ] && \
    ln -sf /run/systemd/resolve/stub-resolv.conf /etc/resolv.conf &> "${log_redirects}"
  systemctl restart systemd-resolved &> "${log_redirects}"

else
  stop_service    dnscrypt-proxy
  stop_service    dnscrypt-proxy2
  disable_service dnscrypt-proxy
  disable_service dnscrypt-proxy2
  remove_package  dnscrypt-proxy
  remove_package  dnscrypt-proxy2
  remove_package  "dnscrypt-proxy-${init_system}"
  remove_package  "dnscrypt-proxy2-${init_system}"

  # unlock and restore resolv.conf to Cloudflare
  chattr -i /etc/resolv.conf &> "${log_redirects}"
  tee /etc/resolv.conf &> /dev/null << EOF
nameserver 1.1.1.1
nameserver 2606:4700:4700::1111
nameserver 1.0.0.1
nameserver 2606:4700:4700::1001
EOF
fi

success "DNS restored."

# ── remove zapret ─────────────────────────────────────────────────────────────

if [ ! -d /opt/zapret ]; then
  warn "zapret isn't here. nothing to remove."
  exit 0
fi

info "removing zapret..."

stop_service    zapret
disable_service zapret

echo -e "Y\n\n" | /opt/zapret/uninstall_easy.sh &> "${log_redirects}"
rm -rf /opt/zapret &> "${log_redirects}"

# clean up any init stubs we dropped during install
rm -f /etc/dinit.d/zapret        &> "${log_redirects}"
rm -f /etc/init.d/zapret         &> "${log_redirects}"
rm -f /etc/rc.d/rc.zapret        &> "${log_redirects}"
rm -f /opt/etc/init.d/S90zapret  &> "${log_redirects}"

success "zapret gone."

# ── done ──────────────────────────────────────────────────────────────────────

echo ""
echo -e "${RED}══════════════════════════════════════════${RST}"
echo -e "${GRN}  ◈  clean. erdogan wins this one.       ◈${RST}"
echo -e "${RED}  run install.sh again whenever you want. ${RST}"
echo -e "${RED}══════════════════════════════════════════${RST}"
echo ""

#!/bin/bash

# Ensure the script is run as root
if [[ "$EUID" -ne 0 ]]; then
  echo "Please run as root"
  exit 1
fi

# Update system and apply security patches
update_system() {
  echo "Updating system packages..."
  apt-get update && apt-get upgrade -y
  apt-get dist-upgrade -y
  echo "System update complete."
}

# Audit user accounts and permissions
audit_users() {
  echo "Auditing user accounts..."
  awk -F: '($3 == "0") {print $1}' /etc/passwd
  echo "Checking for empty passwords..."
  awk -F: '($2 == "" ) {print $1}' /etc/shadow
  echo "Enforcing password policy..."
  # Example: Require strong passwords
  apt-get install -y libpam-cracklib
  echo "password requisite pam_cracklib.so retry=3 minlen=8 difok=3" >> /etc/pam.d/common-password
  echo "User audit complete."
}

# Audit file and directory permissions
audit_files() {
  echo "Auditing file and directory permissions..."
  ls -l /etc/passwd /etc/shadow /etc/hosts
  find / -perm -2 ! -type l -ls
  echo "File and directory audit complete."
}

# Configure and verify firewall
configure_firewall() {
  echo "Configuring firewall..."
  ufw enable
  ufw default deny incoming
  ufw default allow outgoing
  ufw allow ssh
  echo "Firewall configuration complete."
}

# Audit and secure running services
audit_services() {
  echo "Auditing running services..."
  systemctl list-units --type=service --state=running
  echo "Disabling unnecessary services..."
  systemctl disable --now avahi-daemon.service
  echo "Service audit complete."
}

# Network security audit
audit_network() {
  echo "Auditing network security..."
  ss -tuln
  echo "Ensuring SSH is securely configured..."
  sed -i 's/#Port 22/Port 2222/' /etc/ssh/sshd_config
  sed -i 's/#PermitRootLogin yes/PermitRootLogin no/' /etc/ssh/sshd_config
  systemctl reload sshd
  echo "Network security audit complete."
}

# Install and configure Intrusion Detection System
setup_ids() {
  echo "Setting up IDS..."
  apt-get install -y aide
  aideinit
  cp /var/lib/aide/aide.db.new /var/lib/aide/aide.db
  echo "AIDE initialized and configured."
}

# Generate a security report
generate_report() {
  echo "Generating security report..."
  echo "Report Date: $(date)" > /var/log/security_report.log
  echo "-------------------------------" >> /var/log/security_report.log
  echo "User Audit" >> /var/log/security_report.log
  awk -F: '($3 == "0") {print $1}' /etc/passwd >> /var/log/security_report.log
  echo "File and Directory Permissions" >> /var/log/security_report.log
  ls -l /etc/passwd /etc/shadow /etc/hosts >> /var/log/security_report.log
  echo "Running Services" >> /var/log/security_report.log
  systemctl list-units --type=service --state=running >> /var/log/security_report.log
  echo "Open Ports" >> /var/log/security_report.log
  ss -tuln >> /var/log/security_report.log
  echo "Security report generated at /var/log/security_report.log"
}

# Main function to run all audits and hardening steps
main() {
  update_system
  audit_users
  audit_files
  configure_firewall
  audit_services
  audit_network
  setup_ids
  generate_report
}

# Parse command-line arguments
case "$1" in
  --report-only) generate_report ;;
  --quick-harden) update_system; configure_firewall; audit_services ;;
  *) main ;;
esac


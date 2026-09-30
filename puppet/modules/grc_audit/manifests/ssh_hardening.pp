# IA-2: Identification and Authentication (Organizational Users)
# AC-3: Access Enforcement
# AC-17: Remote Access
#
# Validates SSH daemon configuration against NIST 800-53 hardening baselines.
# Runs in noop mode by default (no state changes).
#
# @summary
#   SSH hardening validation for NIST IA-2, AC-3, AC-17
#
# @example
#   include grc_audit::ssh_hardening
#
# @param ensure_compliance
#   Inherited from grc_audit class. False = audit-only (noop).
#
# @param sshd_config_path
#   Path to sshd_config file. Platform-specific default.
#
# @param password_auth_allowed
#   Whether PasswordAuthentication should be enabled. Default: no (NIST baseline).
#
# @param permit_root_login
#   Whether PermitRootLogin should be enabled. Default: no (NIST baseline).
#
# @param pubkey_auth_required
#   Whether PubkeyAuthentication should be enabled. Default: yes (NIST baseline).
class grc_audit::ssh_hardening (
  Boolean $ensure_compliance = false,  # Direct default, doesn't depend on base class
  String $sshd_config_path = $facts['os']['family'] ? {
    'windows' => 'C:/ProgramData/ssh/sshd_config',
    default   => '/etc/ssh/sshd_config',
  },
  Enum['yes', 'no'] $password_auth_allowed = 'no',
  Enum['yes', 'no', 'prohibit-password', 'forced-commands-only'] $permit_root_login = 'no',
  Enum['yes', 'no'] $pubkey_auth_required = 'yes',
) {
  # Validate SSH config file exists (read-only check)
  $sshd_config_exists = $facts['os']['family'] ? {
    'windows' => false,  # Skip Windows in POC
    default   => find_file($sshd_config_path) != undef,
  }

  if !$sshd_config_exists {
    # Skip validation if config file doesn't exist
    # No notify here to avoid affecting exit code
  } else {
    # IA-2: Validate PasswordAuthentication setting
    # Uses 'unless' which runs in noop mode and reports drift only when setting is wrong
    exec { 'check_password_auth':
      command  => '/bin/true',  # Never actually runs in noop
      unless   => "grep -q '^PasswordAuthentication ${password_auth_allowed}' '${sshd_config_path}'",
      path     => ['/usr/bin', '/bin', '/usr/sbin', '/sbin'],
      provider => 'shell',
    }

    # AC-3/AC-17: Validate PermitRootLogin
    exec { 'check_permit_root_login':
      command  => '/bin/true',
      unless   => "grep -q '^PermitRootLogin ${permit_root_login}' '${sshd_config_path}'",
      path     => ['/usr/bin', '/bin', '/usr/sbin', '/sbin'],
      provider => 'shell',
    }

    # IA-2: Validate PubkeyAuthentication
    exec { 'check_pubkey_auth':
      command  => '/bin/true',
      unless   => "grep -q '^PubkeyAuthentication ${pubkey_auth_required}' '${sshd_config_path}'",
      path     => ['/usr/bin', '/bin', '/usr/sbin', '/sbin'],
      provider => 'shell',
    }
  }
}

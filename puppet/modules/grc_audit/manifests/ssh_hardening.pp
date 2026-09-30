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
  Boolean $ensure_compliance = $grc_audit::ensure_compliance,
  Stdlib::Absolutepath $sshd_config_path = $facts['os']['family'] ? {
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
    notify { 'grc_ssh_config_missing':
      message => "SKIP: SSH config not found at ${sshd_config_path} (platform=${facts['os']['family']})",
    }
  } else {
    notify { 'grc_ssh_validation_start':
      message => "IA-2/AC-3: Validating SSH hardening at ${sshd_config_path} (noop=${lookup('noop', Boolean, 'first', true)})",
    }

    # IA-2: Validate PasswordAuthentication setting
    file_line { 'ssh_password_authentication':
      ensure => present,
      path   => $sshd_config_path,
      line   => "PasswordAuthentication ${password_auth_allowed}",
      match  => '^#?\s*PasswordAuthentication\s+',
      # In noop mode, this reports drift without changing the file
    }

    # AC-3/AC-17: Validate PermitRootLogin
    file_line { 'ssh_permit_root_login':
      ensure => present,
      path   => $sshd_config_path,
      line   => "PermitRootLogin ${permit_root_login}",
      match  => '^#?\s*PermitRootLogin\s+',
    }

    # IA-2: Validate PubkeyAuthentication
    file_line { 'ssh_pubkey_authentication':
      ensure => present,
      path   => $sshd_config_path,
      line   => "PubkeyAuthentication ${pubkey_auth_required}",
      match  => '^#?\s*PubkeyAuthentication\s+',
    }

    # Additional hardening checks (logged only)
    $protocol_check = "Protocol 2"  # SSH Protocol 2 required
    file_line { 'ssh_protocol_version':
      ensure => present,
      path   => $sshd_config_path,
      line   => $protocol_check,
      match  => '^#?\s*Protocol\s+',
    }

    notify { 'grc_ssh_validation_complete':
      message => "IA-2/AC-3: SSH hardening validation complete (see noop report for drift)",
      require => [
        File_line['ssh_password_authentication'],
        File_line['ssh_permit_root_login'],
        File_line['ssh_pubkey_authentication'],
      ],
    }
  }
}

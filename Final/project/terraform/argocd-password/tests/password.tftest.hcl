variables {
  password = "Test-password-for-local-checks-123"
}

run "install" {
  command = apply
  assert {
    condition     = can(regex("^\\$2[aby]\\$", output.bcrypt_hash))
    error_message = "Argo CD requires a bcrypt password hash."
  }
}

run "unchanged_password" {
  command = plan
  assert {
    condition     = output.bcrypt_hash == run.install.bcrypt_hash
    error_message = "An unchanged password must preserve its hash."
  }
}

run "rotate_password" {
  command = apply
  variables {
    password = "Changed-test-password-for-checks-456"
  }
  assert {
    condition     = output.bcrypt_hash != run.install.bcrypt_hash
    error_message = "Changing the password must replace its hash."
  }
}

run "rotated_password_is_stable" {
  command = plan
  variables {
    password = "Changed-test-password-for-checks-456"
  }
  assert {
    condition     = output.bcrypt_hash == run.rotate_password.bcrypt_hash
    error_message = "The rotated password must also remain stable on later plans."
  }
}

run "reject_short_password" {
  command = plan
  variables {
    password = "short"
  }
  expect_failures = [var.password]
}

run "reject_empty_password" {
  command = plan
  variables {
    password = ""
  }
  expect_failures = [var.password]
}

run "reject_password_over_bcrypt_limit" {
  command = plan
  variables {
    password = join("", [for i in range(73) : "x"])
  }
  expect_failures = [var.password]
}

run "reject_password_with_whitespace" {
  command = plan
  variables {
    password = "a password with whitespace"
  }
  expect_failures = [var.password]
}

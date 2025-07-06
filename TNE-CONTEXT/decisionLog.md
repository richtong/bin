# Decision Log

This file records architectural and implementation decisions using a list
format. 2025-06-24 15:58:08 - Log of updates made.

-

## Decision

- [2025-06-24 17:37:00] - The `install-1password.sh` script will use a set of
  Bash associative arrays to manage the mapping between environment variables and
  secrets stored in 1Password. This provides a structured and maintainable way to
  handle a large number of secrets.

## Rationale

- [2025-06-24 17:37:00] - Using associative arrays allows for a clear and
  decoupled mapping of secrets. Instead of hardcoding values, the script uses keys
  (the environment variable names) to look up the corresponding item name, field,
  and vault in 1Password. This makes it easy to add, remove, or modify secrets
  without changing the core logic of the script. It also supports conditional
  loading of secrets based on the presence of other environment variables.

## Implementation Details

- [2025-06-24 17:37:00] - The implementation relies on the following Bash
  associative arrays:

  - `OP_API_ITEM`: Maps environment variable names to 1Password item names.
  - `OP_API_FIELD`: Maps environment variable names to the field within the
    1Password item.
  - `OP_API_VAULT`: Maps environment variable names to the 1Password vault
    (with a default vault configured).
  - `OP_API_DISABLE`: Conditionally prevents the export of a secret if a
    specified environment variable is already set. The `1password_export()`
    function iterates through these arrays to construct and execute `op item
get` commands, which are then injected into the user's shell profile or a
    `direnv` file.

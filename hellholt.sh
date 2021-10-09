#!/usr/bin/env bash

ansible_path="${HELLHOLT_ANSIBLE_PATH:-${HOME}/Projects/ansible}";

# Run a specified Ansible role.
function hellholt:ansible_role() {
  : "${2?"Usage: ${FUNCNAME[0]} <HOSTNAME|GROUP> <ROLE> <TASKFILE>"}";
  local host_expression="${1}";
  local role_name="${2}";
  pushd "${ansible_path}" > /dev/null;
  ansible-playbook ${@:3} /dev/stdin <<END
---
- hosts: $host_expression
  roles:
    - '$role_name'
END
  popd > /dev/null;
}

# Run a specified Ansible task.
function hellholt:ansible_task() {
  : "${3?"Usage: ${FUNCNAME[0]} <HOSTNAME|GROUP> <ROLE> <TASKFILE>"}";
  local host_expression="${1}";
  local role_name="${2}";
  local task_file="${3}";
  pushd "${ansible_path}" > /dev/null;
  ansible-playbook ${@:4} /dev/stdin <<END
---
- hosts: $host_expression
  tasks:

  - name: 'Debug.'
    ansible.builtin.debug:
      msg: '$role_name $task_file $args'

  - name: 'Execute $role_name:$task_file'
    ansible.builtin.include_role:
      name: '$role_name'
      tasks_from: '$task_file'
END
  popd > /dev/null;
}

# Setup the host.
function hellholt:setup() {
  : "${1?"Usage: ${FUNCNAME[0]} <HOSTNAME|GROUP>"}";
  local host_expression="${1}";
  local args="${@:2}";
  pushd "${ansible_path}" > /dev/null;
  hellholt:ansible_role "${host_expression}" 'hellholt.setup_host' -e 'ansible_user=root' "${args}";
  popd > /dev/null;
}

# Edit the vault.
function hellholt:edit_vault() {
  pushd "${ansible_path}" > /dev/null;
  ansible-vault edit ./inventory/group_vars/all/vault;
  popd > /dev/null;
}

# Perform an operation on an LXC container.
function hellholt:lxc_container() {
  : "${2?"Usage: ${FUNCNAME[0]} <COMMAND> <HOSTNAME|GROUP>"}";
  local subcommand="${1}";
  local host_expression="${2}";
  local args="${@:3}";
  ANSIBLE_GATHERING='explicit' hellholt:ansible_task "${host_expression}" 'hellholt.proxmox' "${subcommand}_lxc_container.yaml" "${args}";
}

# Show usage information.
function hellholt:usage() {
  echo 'Usage: hellholt <subcommand> [arguments...]';
  echo '';
  echo 'Subcommands: ';
  printf '%14s    %s\n' 'usage' 'Show usage information.';
  printf '%14s    %s\n' 'ansible_task' 'Run a specified Ansible task.';
  printf '%14s    %s\n' 'lxc_container' 'Perform an operation on an LXC container.';
  printf '%14s    %s\n' 'create' 'Create a host as an LXC container.';
  printf '%14s    %s\n' 'destroy' 'Destroy an LXC container.';
  printf '%14s    %s\n' 'stop' 'Stop an LXC container.';
  printf '%14s    %s\n' 'start' 'Start an LXC container.';
  printf '%14s    %s\n' 'restart' 'Restart the LXC container.';
  printf '%14s    %s\n' 'setup' 'Setup the specified host.';
  printf '%14s    %s\n' 'edit_vault' 'Edit the vault.';
  echo '';
}

# Valid subcommands of hellholt:lxc_container.
lxc_container_subcommands=(
  'create'
  'destroy'
  'stop'
  'start'
  'restart'
)

# Primary function.
function hellholt() {
  : "${1?"Usage: ${FUNCNAME[0]} <SUBCOMMAND> [ARGUMENTS] ..."}";
  local subcommand=$1;
  shift;
  if type "hellholt:${subcommand}" > /dev/null 2>&1; then
    "hellholt:${subcommand}" "${@}";
  elif [[ " ${lxc_container_subcommands[*]} " =~ " ${subcommand} " ]]; then
    hellholt:lxc_container "${subcommand}" "${@}";
  else
    hellholt:usage;
  fi;
}

hellholt "${@}";
exit $?;

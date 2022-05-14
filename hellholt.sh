#!/usr/bin/env bash

ansible_path="${HELLHOLT_ANSIBLE_PATH:-${HOME}/Projects/ansible}";

# Edit the vault.
function hellholt:edit_vault() {
  pushd "${ansible_path}" > /dev/null;
  ansible-vault edit ./inventory/group_vars/all/vault;
  popd > /dev/null;
}

# Run a specified Ansible playbook.
function hellholt:ansible_playbook() {
  : "${2?"Usage: ${FUNCNAME[0]} <PLAYBOOK>"}";
  local playbook_expression="${1}";
  pushd "${ansible_path}" > /dev/null;
  ansible-playbook "${playbook_expression}";
  popd > /dev/null;
}

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

  - name: 'Execute $role_name:$task_file'
    ansible.builtin.include_role:
      name: '$role_name'
      tasks_from: '$task_file'
END
  popd > /dev/null;
}

# Perform an operation on a Proxmox VE node.
function hellholt:pve_node() {
  : "${2?"Usage: ${FUNCNAME[0]} <COMMAND> <HOSTNAME|GROUP>"}";
  local host_expression="${1}";
  local subcommand="${2}";
  local args="${@:3}";
  ANSIBLE_GATHERING='implicit' hellholt:ansible_task "${host_expression}" 'hellholt.pve_node' "${subcommand}.yaml" "${args}";
}

# Perform an operation on an LXC container.
function hellholt:pve_lxc() {
  : "${2?"Usage: ${FUNCNAME[0]} <COMMAND> <HOSTNAME|GROUP>"}";
  local host_expression="${1}";
  local subcommand="${2}";
  local args="${@:3}";
  ANSIBLE_GATHERING='explicit' hellholt:ansible_task "${host_expression}" 'hellholt.pve_lxc' "${subcommand}.yaml" "${args}";
}

# Perform an operation on a Proxmox VE LXC container.
function hellholt:setup_host() {
  : "${1?"Usage: ${FUNCNAME[0]} <HOSTNAME|GROUP>"}";
  local host_expression="${1}";
  local operation="${2}";
  local args="${@:3}";
  pushd "${ansible_path}" > /dev/null;
  hellholt:ansible_role "${host_expression}" 'hellholt.pve_lxc' "${operation}.yaml" -e 'ansible_user=root' "${args}";
  popd > /dev/null;
}

# Apply a setup group to a host.
function hellholt:apply_setup_group() {
  : "${2?"Usage: ${FUNCNAME[0]} <HOSTNAME|GROUP> <SETUP_GROUP>"}";
  local host_expression="${1}";
  local setup_group="${2}";
  local args="${@:3}";
  ANSIBLE_GATHERING='implicit' hellholt:ansible_task "${host_expression}" 'hellholt.setup_host' "setup_groups/${setup_group}.yaml" "${args}" --become;
}

# Perform an operation on a Kubernetes cluster.
function hellholt:k8s_cluster() {
  : "${2?"Usage: ${FUNCNAME[0]} <COMMAND> <HOSTNAME|GROUP>"}";
  local subcommand="${1}";
  local host_expression="${2}";
  local args="${@:3}";
  ANSIBLE_GATHERING='explicit' hellholt:ansible_task "${host_expression}" 'hellholt.kubernetes' "${subcommand}.yaml" "${args}";
}

# Refresh Homer.
function hellholt:refresh_homer() {
  ANSIBLE_GATHERING='explicit' hellholt:ansible_task 'homer' 'hellholt.setup_host' 'setup_groups/homer.yaml' --become;
}

# Show usage information.
function hellholt:usage() {
  local subcommand_width='18';
  local subcommand_column="%${subcommand_width}s    %s\n";
  echo 'Usage: hellholt <subcommand> [arguments...]';

  echo '';

  echo 'General subcommands: ';

  printf "${subcommand_column}" 'usage' 'Show usage information.';
  printf "${subcommand_column}" 'ansible_task' 'Run a specified Ansible task.';
  printf "${subcommand_column}" 'edit_vault' 'Edit the vault.';
  printf "${subcommand_column}" 'autocomplete' 'Output autocomplete information.';

  printf "${subcommand_column}" 'reissue_ssh_certs' 'Reissue SSH certificates.';

  printf "${subcommand_column}" 'refresh_homer' 'Refresh Homer.';

  printf "${subcommand_column}" 'aws' 'AWS resources and privileges.';
  printf "${subcommand_column}" 'dotfiles' 'Setup dotfiles to maintain consistency.';

  echo '';

  echo 'Proxmox VE LXC container subcommands:';

  printf "${subcommand_column}" 'pve_lxc:create' 'Create the container(s).';
  printf "${subcommand_column}" 'pve_lxc:destroy' 'Destroy the container(s).';
  printf "${subcommand_column}" 'pve_lxc:stop' 'Stop the container(s).';
  printf "${subcommand_column}" 'pve_lxc:start' 'Start the container(s).';
  printf "${subcommand_column}" 'pve_lxc:restart' 'Restart the container(s).';
  printf "${subcommand_column}" 'pve_lxc:recreate' 'Destroy and recreate the container(s).';
  printf "${subcommand_column}" 'pve_lxc:setup' 'Setup the container(s).';

  echo '';

  echo 'Kubernetes cluster subcommands:';

  printf "${subcommand_column}" 'create_cluster' 'Create a cluster (but do not deploy tasks).';
  printf "${subcommand_column}" 'recreate_cluster' 'Destroy and rereate a cluster (but do not deploy tasks).';
  printf "${subcommand_column}" 'destroy_cluster' 'Destroy a cluster.';
  printf "${subcommand_column}" 'reset_cluster' 'Reset a cluster and deploy tasks.';
  printf "${subcommand_column}" 'setup_cluster' 'Setup a cluster and deploy tasks.';
  printf "${subcommand_column}" 'redeploy_cluster' 'Deploy/redeploy tasks on the clustter.';

  echo '';

}

general_subcommands=(
  'usage'
  'ansible_task'
  'edit_vault'
  'autocomplete'
  'dotfiles'
  'reissue_ssh_certs'
  'refresh_homer'
  'setup_plex'
  'setup_transmission'
  'setup_pve_node'
  'setup_traefik_site_proxy'
  'setup_unifi'
)

# Valid subcommands of hellholt:k8s_cluster.
k8s_cluster_subcommands=(
  'create_cluster'
  'recreate_cluster'
  'destroy_cluster'
  'reset_cluster'
  'setup_cluster'
  'redeploy_cluster'
)

# Print autocomplete script.
function hellholt:autocomplete() {
  local old_ifs="${IFS}";
  IFS=\ ;
  local all_subcommands=(
    "$(echo "${general_subcommands[*]}")"
    "$(echo "${lxc_container_subcommands[*]}")"
    "$(echo "${k8s_cluster_subcommands[*]}")"
  )
  local subcommands_string="$(echo "${all_subcommands[*]}")";
  echo complete -W "'"${subcommands_string}"'" hellholt;
  IFS="${old_ifs}";
}

# Primary function.
function hellholt() {
  : "${1?"Usage: ${FUNCNAME[0]} <SUBCOMMAND> [ARGUMENTS] ..."}";
  local subcommand="${1}";
  export OBJC_DISABLE_INITIALIZE_FORK_SAFETY='YES';
  export K8S_AUTH_KUBECONFIG='~/.kube/config';
  shift;
  if type "hellholt:${subcommand%:*}" > /dev/null 2>&1; then
    "hellholt:${subcommand%:*}" "${1}" "${subcommand#*:}" "${@:2}";
  elif [[ " ${general_subcommands[*]} " =~ " ${subcommand%:*} " ]]; then
    hellholt:ansible_task "${1}" "hellholt.${subcommand%:*}" "${subcommand#*:}.yaml" "${@:2}";
  elif [[ " ${k8s_cluster_subcommands[*]} " =~ " ${subcommand} " ]]; then
    hellholt:k8s_cluster "${subcommand}" "${@}";
  else
    hellholt:usage;
  fi;
}

hellholt "${@}";
exit $?;

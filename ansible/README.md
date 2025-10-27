This folder contains Ansible playbooks and roles to bootstrap the bastion and deploy the backend application.

Usage:

- Edit `inventory/hosts.ini` to set your bastion public IP and the path to your SSH private key.
- Run `ansible-playbook playbooks/bastion-bootstrap.yml` to prepare the bastion.
- Run `ansible-playbook playbooks/deploy-app.yml` to deploy the backend (will clone repo and start service).

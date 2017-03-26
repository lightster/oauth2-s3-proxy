inventory?=production
debug?=

init:;
	echo "password" >.vault_pass_default
	cp -a inventory/group_vars/template/*.vault.yml \
		inventory/group_vars/$(inventory)/
	ansible-vault rekey --vault-password-file=.vault_pass_default --new-vault-password-file=.vault_pass \
		inventory/group_vars/$(inventory)/aws.vault.yml
	ansible-vault rekey --vault-password-file=.vault_pass_default --new-vault-password-file=.vault_pass \
		inventory/group_vars/$(inventory)/oauth2_proxy.vault.yml
	rm .vault_pass_default

vpc:;
	ansible-playbook -i inventory/$(inventory) vpc.yml $(debug)

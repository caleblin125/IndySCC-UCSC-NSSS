# Makefile for Slurm + Munge cluster setup on Jetstream
# Based on https://github.com/SergioMEV/slurm-for-dummies

SSH_USER := exouser

# Define nodes (format: NODE:PASS)
NODES := \
  "149.165.150.159:AURA DANA LIMA OLIN BAND RAG SCOT MEAN MEL WE RAW" \
  "149.165.151.146:WELD RIFT VICE JEFF CAIN TICK FUN DART HOCK ORR HILL" \
  "149.165.169.104:TAD BOOM DOME FORT ICY BED STAN HULL MIND WORK BILL" \
  "149.165.170.88:CHAR BIEN BRAD PI SCAT LEON LUKE TROT GUT EWE VAT" \
  "149.165.170.103:WHAT DRAG MILL GOAT ROUT HAST VAST STAY ED RULE BIT" \
  "149.165.172.202:RANT AUG WU HAYS ARE ASKS COLA HIKE LID ELLA DUEL" \
  "149.165.168.148:OTIS RENT SEE DAM OATH ARC HONE WEEK LOVE BID GARB" \
  "149.165.169.48:CAL DARN HAS GAUR LARD AUTO LIE USES ABE RISK AYE" \
  "149.165.151.122:ACRE FONT OVEN MAP KURT BRIG TORE SLOW SAYS RING REAM" \
  "149.165.174.131:GRAD BOND HAUL LUGE BUM THUD HUGH GUNK JERK SOFA BYE" \
  "149.165.175.119:DANA GUM LOON LEST MAN ROOF HASH POE LYNN LAKE OHIO"

.PHONY: all slurm-munge slurm-setup share

all: slurm-munge slurm-setup share

# -------------------------------
# MUNGE installation and key sync
# -------------------------------
slurm-munge:
	@echo "------------- MUNGE SETUP START ----------------"
	sudo apt update -qq && sudo apt install -y -qq openssh-server openssh-client munge libmunge2 libmunge-dev sshpass
	@sudo bash -c 'if [ ! -f /etc/munge/munge.key ]; then \
		echo "[*] Generating new Munge key..."; \
		/usr/sbin/mungekey; \
	else \
		echo "[*] Munge key already exists — skipping generation."; \
	fi'
	sudo chown -R munge: /etc/munge/ /var/log/munge/ /var/lib/munge/ /run/munge/
	sudo chmod 0700 /etc/munge/ /var/log/munge/ /var/lib/munge/
	sudo chmod 0755 /run/munge/
	sudo chmod 0400 /etc/munge/munge.key
	sudo systemctl enable munge
	sudo systemctl restart munge
	munge -n | unmunge | grep STATUS

	@for NODE_INFO in $(NODES); do \
		NODE=$${NODE_INFO%%:*}; \
		PASS=$${NODE_INFO##*:}; \
		echo "[*] Installing Munge on $$NODE..."; \
		sshpass -p "$$PASS" ssh -o StrictHostKeyChecking=no "$(SSH_USER)@$$NODE" bash -c "'\
			echo \"$$PASS\" | sudo -S apt update -qq && \
			echo \"$$PASS\" | sudo -S apt install -y -qq munge libmunge2 libmunge-dev && \
			sudo systemctl enable munge && sudo systemctl restart munge \
		'"; \
		echo "[*] Copying Munge key to $$NODE..."; \
		sudo cat /etc/munge/munge.key | \
			sshpass -p "$$PASS" ssh "$(SSH_USER)@$$NODE" "sudo tee /etc/munge/munge.key >/dev/null"; \
		sshpass -p "$$PASS" ssh -o StrictHostKeyChecking=no "$(SSH_USER)@$$NODE" bash -c "'\
			sudo chown -R munge: /etc/munge/munge.key && \
			sudo chmod 400 /etc/munge/munge.key && \
			sudo systemctl restart munge \
		'"; \
	done
	@echo "------------- MUNGE SETUP FINISH ----------------"

# -------------------------------
# SLURM installation + config sync
# -------------------------------
slurm-setup:
	@echo "------------- SLURM INSTALL START ----------------"
	sudo apt install -y -qq slurm-wlm libpmix-dev libpmix2
	sudo mkdir -p /etc/slurm /var/spool/slurmctld /var/spool/slurmd
	sudo chown slurm:slurm /var/spool/slurmctld /var/spool/slurmd
	sudo chmod 755 /var/spool/slurmctld /var/spool/slurmd

	@echo "Writing /etc/slurm/slurm.conf..."
	sudo cp -f slurm.conf /etc/slurm/slurm.conf

	sudo systemctl enable slurmctld
	sudo systemctl restart slurmctld

	@for NODE_INFO in $(NODES); do \
		NODE=$${NODE_INFO%%:*}; \
		PASS=$${NODE_INFO##*:}; \
		echo "[*] Installing Slurm on $$NODE..."; \
		sshpass -p "$$PASS" ssh -o StrictHostKeyChecking=no "$(SSH_USER)@$$NODE" bash -c "'\
			sudo apt install -y -qq slurm-wlm libpmix-dev libpmix2 && \
			sudo mkdir -p /var/spool/slurmd && sudo chown slurm:slurm /var/spool/slurmd && sudo chmod 755 /var/spool/slurmd \
		'"; \
		echo "[*] Copying config to $$NODE..."; \
		sudo cat /etc/slurm/slurm.conf | sshpass -p "$$PASS" ssh "$(SSH_USER)@$$NODE" "sudo tee /etc/slurm/slurm.conf >/dev/null"; \
		sshpass -p "$$PASS" ssh -o StrictHostKeyChecking=no "$(SSH_USER)@$$NODE" bash -c "'\
			sudo systemctl enable slurmd && sudo systemctl restart slurmd \
		'"; \
	done
	@echo "------------- SLURM INSTALL FINISH ----------------"

slurm-reload:
	@echo "------------- SLURM RELOAD ----------------"
	sudo systemctl enable slurmctld
	sudo systemctl restart slurmctld

	@for NODE_INFO in $(NODES); do \
		NODE=$${NODE_INFO%%:*}; \
		PASS=$${NODE_INFO##*:}; \
		echo "[*] Copying config to $$NODE..."; \
		sudo cat /etc/slurm/slurm.conf | sshpass -p "$$PASS" ssh "$(SSH_USER)@$$NODE" "sudo tee /etc/slurm/slurm.conf >/dev/null"; \
		sshpass -p "$$PASS" ssh -o StrictHostKeyChecking=no "$(SSH_USER)@$$NODE" bash -c "'\
			sudo systemctl enable slurmd && sudo systemctl restart slurmd \
		'"; \
	done
	@echo "------------- SLURM RELOAD ----------------"

share:
	@echo "------------- SHARE FILES ----------------"
	@for NODE_INFO in $(NODES); do \
		NODE=$${NODE_INFO%%:*}; \
		PASS=$${NODE_INFO##*:}; \
		echo "[*] Resetting and copying ~/share to $$NODE..."; \
		sshpass -p "$$PASS" ssh -o StrictHostKeyChecking=no $(SSH_USER)@$$NODE "rm -rf ~/share"; \
		sshpass -p "$$PASS" scp -r -o StrictHostKeyChecking=no ~/share $(SSH_USER)@$$NODE:~/share; \
	done
	@echo "------------- SHARE COMPLETE ----------------"


# -------------------------------
# Shared filesystem setup (NFS)
# -------------------------------
# shared-fs:
# 	@echo "------------- NFS SHARED FILESYSTEM ----------------"
# 	sudo apt install -y -qq nfs-kernel-server
# 	sudo mkdir -p /shared
# 	sudo chown $(SSH_USER):$(SSH_USER) /shared
# 	sudo chmod 755 /shared
# 	echo "/shared  149.165.154.0/24(rw,sync,no_root_squash,no_subtree_check)" | sudo tee -a /etc/exports >/dev/null
# 	sudo exportfs -ra
# 	sudo systemctl restart nfs-kernel-server

# 	@for NODE_INFO in $(NODES); do \
# 		NODE=$${NODE_INFO%%:*}; \
# 		PASS=$${NODE_INFO##*:}; \
# 		echo "[*] Mounting NFS on $$NODE..."; \
# 		sshpass -p "$$PASS" ssh -o StrictHostKeyChecking=no "$(SSH_USER)@$$NODE" bash -c "'\
# 			sudo apt install -y -qq nfs-common && \
# 			sudo mkdir -p /shared && \
# 			sudo mount login:/shared /shared && \
# 			echo \"login:/shared   /shared   nfs   defaults  0  0\" | sudo tee -a /etc/fstab \
# 		'"; \
# 	done
# 	@echo "------------- NFS SHARED FILESYSTEM ----------------"

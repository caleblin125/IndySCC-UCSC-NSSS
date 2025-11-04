# Makefile for Slurm + Munge cluster setup on Jetstream
# Based on https://github.com/SergioMEV/slurm-for-dummies

SSH_USER := exouser

LOGINIP := 149.165.171.234
LOGIN := herologin

# Define nodes (format: NODE:PASS)
NODES := \
  "149.165.168.188:HAVE SLAM USES BURR LIMA BOG NEED HEAL WAY BET MAO" \
  "149.165.171.243:LINK BODE JUST ANY RAVE BUDD FLUB SCAT RUST HELD BOTH" \
  "149.165.174.243:HIP MEMO LINE BAWL OUT HARD GENT LA MALT LENS EGG" \
  "149.165.150.159:GAL SLOG NESS CADY CARL ROOD SHED COT REEL FORD WINE" \
  "149.165.175.218:FIR FOAM CODA DUE GARY BALK HOYT TICK GASH FLUB YARD" \
  "149.165.169.217:FEED LUSH RISE TIP LIMA NAVE DARE FIRE HERO MOCK SOW" \
  "149.165.168.25:RUTH QUOD BONE BEY NOVA VOID DOCK MANN USER VERY HAUL" \
  "149.165.175.152:SHOE WORD MOE MEND TWIG DUMB NOVA HOUR TUB SKEW TRIO" \
  "149.165.169.133:SEAL BATE PEG OWLY BULB FARM BRAE MIT NOON CUNY CURD"

NAMES := \
	"worker-1-of-9"\
	"worker-2-of-9"\
	"worker-3-of-9"\
	"worker-4-of-9"\
	"worker-5-of-9"\
	"worker-6-of-9"\
	"worker-7-of-9"\
	"worker-8-of-9"\
	"worker-9-of-9"

.PHONY: all slurm-munge add-all-hosts slurm-setup share

all: slurm-munge add-all-hosts slurm-setup share

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

add-all-hosts:
	@echo "------------- ADD ALL HOSTS START ----------------"
	# Add controller
	@echo "Adding controller $$LOGIN ($$LOGINIP) to /etc/hosts"; \
	sudo echo "$$LOGINIP $$LOGIN" | sudo tee -a /etc/hosts >/dev/null; \

	# Add workers
	i=1; \
	for NODE_INFO in $(NODES); do \
	    NODE=$${NODE_INFO%%:*}; \
	    PASS="$${NODE_INFO##*:}"; \
	    HOSTNAME=$$(echo $(NAMES) | cut -d' ' -f$$i); \
	    echo "Adding $$NODE $$HOSTNAME to /etc/hosts"; \
	    echo "$$NODE $$HOSTNAME" | sudo tee -a /etc/hosts >/dev/null; \
	    i=$$((i+1)); \
	done

	# Copy /etc/hosts to each worker
	@for NODE_INFO in $(NODES); do \
	    NODE=$${NODE_INFO%%:*}; \
	    PASS=$${NODE_INFO##*:}; \
	    echo "Copying /etc/hosts to $$NODE"; \
	    sudo cat /etc/hosts | sshpass -p "$$PASS" ssh -o StrictHostKeyChecking=no "$(SSH_USER)@$$NODE" "sudo tee /etc/hosts >/dev/null"; \
	done

	@echo "------------- ADD ALL HOSTS FINISH ----------------"
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
	@echo "Writing /etc/slurm/slurm.conf..."
	
	sudo cp -f slurm.conf /etc/slurm/slurm.conf
	sudo systemctl enable slurmctld
	sudo systemctl restart slurmctld
	sudo systemctl status slurmctld.service

	@for NODE_INFO in $(NODES); do \
		NODE=$${NODE_INFO%%:*}; \
		PASS=$${NODE_INFO##*:}; \
		echo "[*] Copying config to $$NODE..."; \
		sudo cat /etc/slurm/slurm.conf | sshpass -p "$$PASS" ssh "$(SSH_USER)@$$NODE" "sudo tee /etc/slurm/slurm.conf >/dev/null"; \
		sshpass -p "$$PASS" ssh -o StrictHostKeyChecking=no "$(SSH_USER)@$$NODE" bash -c "'\
			sudo systemctl enable slurmd && sudo systemctl restart slurmd && sudo systemctl status slurmd.service\
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

#-------------------------------
#Shared filesystem setup (NFS)
#-------------------------------
shared-fs:
	@echo "------------- NFS SHARED FILESYSTEM ----------------"
	sudo apt install -y -qq nfs-kernel-server
	sudo mkdir -p /shared
	sudo chown $(SSH_USER):$(SSH_USER) /shared
	sudo chmod 755 /shared
	echo "/shared  149.165.154.0/24(rw,sync,no_root_squash,no_subtree_check)" | sudo tee -a /etc/exports >/dev/null
	sudo exportfs -ra
	sudo systemctl restart nfs-kernel-server

	@for NODE_INFO in $(NODES); do \
		NODE=$${NODE_INFO%%:*}; \
		PASS=$${NODE_INFO##*:}; \
		echo "[*] Mounting NFS on $$NODE..."; \
		sshpass -p "$$PASS" ssh -o StrictHostKeyChecking=no "$(SSH_USER)@$$NODE" bash -c "'\
			sudo apt install -y -qq nfs-common && \
			sudo mkdir -p /shared && \
			sudo mount login:/shared /shared && \
			echo \"login:/shared   /shared   nfs   defaults  0  0\" | sudo tee -a /etc/fstab \
		'"; \
	done
	@echo "------------- NFS SHARED FILESYSTEM ----------------"

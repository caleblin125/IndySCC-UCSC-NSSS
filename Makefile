# Makefile for Slurm + Munge cluster setup on Jetstream
# Based on https://github.com/SergioMEV/slurm-for-dummies

SSH_USER := exouser

LOGINIP := 149.165.150.100
LOGIN := herologin

SSHKEY := herologinkey

# Define nodes (format: NODE:PASS)
NODES := \
  "149.165.153.230:ANDY GLEN DADE CASH HOC FEAT VAIL SAP YARN NEWT JIVE" \
  "149.165.150.184:SAY TIM THIS BARR AVID EVIL SONG FLAM HECK STOW DOTE" \
  "149.165.151.133:NON IO FOOD JAIL HANG BREW GRAY ORB JAVA COLT FLED" \
  "149.165.150.61:RUN PIN CUBA FOAL CITE HUED MIRE ANNA TOGO ONLY ACE"

NAMES := \
	"worker-1-of-3"\
	"worker-2-of-3"\
	"worker-3-of-3"\
	"workergpu"

.PHONY: all slurm-munge add-all-hosts slurm-setup 

all: slurm-munge ssh-share add-all-hosts slurm-setup shared-fs
reconnect: ssh-share add-all-hosts slurm-reload
clean: mpi-clean slurm-reload

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

ssh-share:
	@echo "------------- ADD ALL SSH START ----------------"

	rm ~/.ssh/known_hosts ~/.ssh/known_hosts.old
	@echo "Adding controller $(LOGIN) $(LOGINIP) to /etc/hosts"
	cat ~/.ssh/$(SSHKEY).pub >> ~/.ssh/authorized_keys

	@i=1; \
	for NODE_INFO in $(NODES); do \
	    NODE=$${NODE_INFO%%:*}; \
	    PASS=$${NODE_INFO##*:}; \
	    HOSTNAME=$$(echo $(NAMES) | cut -d' ' -f$$i); \
	    echo "Adding $$NODE ($$HOSTNAME) to SSH authorized keys"; \
	    sshpass -p "$$PASS" ssh -o StrictHostKeyChecking=no "$(SSH_USER)@$$NODE" "\
			rm -f ~/.ssh/known_hosts ~/.ssh/known_hosts.old && \
	        mkdir -p ~/.ssh && \
	        if [ ! -f ~/.ssh/id_rsa ]; then \
	            echo 'Generating new SSH key for $$HOSTNAME...'; \
	            ssh-keygen -t rsa -b 4096 -C '$$HOSTNAME' -f ~/.ssh/id_rsa -N ''; \
	        else \
	            echo 'SSH key already exists on $$HOSTNAME, skipping generation.'; \
	        fi"; \
	    sshpass -p "$$PASS" ssh -o StrictHostKeyChecking=no "$(SSH_USER)@$$NODE" "\
	        cat ~/.ssh/id_rsa.pub" >> ~/.ssh/authorized_keys; \
	    i=$$((i+1)); \
	done

	sort -u ~/.ssh/authorized_keys -o ~/.ssh/authorized_keys

	@i=1; \
	for NODE_INFO in $(NODES); do \
	    NODE=$${NODE_INFO%%:*}; \
	    PASS=$${NODE_INFO##*:}; \
	    echo "Copying authorized_keys to $$NODE"; \
	    cat ~/.ssh/authorized_keys | sshpass -p "$$PASS" ssh -o StrictHostKeyChecking=no "$(SSH_USER)@$$NODE" "\
	        mkdir -p ~/.ssh && cat > ~/.ssh/authorized_keys && chmod 700 ~/.ssh && chmod 600 ~/.ssh/authorized_keys"; \
	    i=$$((i+1)); \
	done

	@echo "------------- ADD ALL SSH END ----------------"

add-all-hosts:
	@echo "------------- ADD ALL HOSTS START ----------------"
	# Add controller

	sudo cat defaultHosts | sudo tee /etc/hosts >/dev/null; 

	@echo "Adding controller $(LOGIN) $(LOGINIP) to /etc/hosts"; \
	sudo echo "$(LOGINIP) $(LOGIN)" | sudo tee -a /etc/hosts >/dev/null; \

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
	sudo apt install -y -qq slurm-wlm libpmix-dev libpmix2 slurm-wlm-basic-plugins slurm-wlm-basic-plugins-dev 
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
		echo "[*] Installing Slurm on $$NODE... <----------------"; \
		sshpass -p "$$PASS" ssh -o StrictHostKeyChecking=no "$(SSH_USER)@$$NODE" bash -c "'\
			sudo apt install -y slurm-wlm libpmix-dev libpmix2 slurm-wlm-basic-plugins slurm-wlm-basic-plugins-dev&& \
			sudo mkdir -p /var/spool/slurmd && sudo chown slurm:slurm /var/spool/slurmd && sudo chmod 755 /var/spool/slurmd \
		'"; \
		echo "[*] Copying config to $$NODE... <-----------------"; \
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
	yes q | sudo systemctl status slurmctld.service

	@for NODE_INFO in $(NODES); do \
		NODE=$${NODE_INFO%%:*}; \
		PASS=$${NODE_INFO##*:}; \
		echo "[*] Copying config to $$NODE..."; \
		sudo cat /etc/slurm/slurm.conf | sshpass -p "$$PASS" ssh "$(SSH_USER)@$$NODE" "sudo tee /etc/slurm/slurm.conf >/dev/null"; \
		sshpass -p "$$PASS" ssh -o StrictHostKeyChecking=no "$(SSH_USER)@$$NODE" bash -c "'\
			sudo systemctl enable slurmd && sudo systemctl restart slurmd && sudo systemctl status slurmd.service\
		'"; \
	done

	i=0; \
	for NODE_INFO in $(NODES); do \
	    NODE=$${NODE_INFO%%:*}; \
	    PASS="$${NODE_INFO##*:}"; \
	    HOSTNAME=$$(echo $(NAMES) | cut -d' ' -f$$i); \
	    sudo scontrol update NodeName=$$HOSTNAME State=resume \
	    i=$$((i+1)); \
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

disable-firewall:
	@echo "------------- FIREWALL ----------------"
	@for NODE_INFO in $(NODES); do \
		NODE=$${NODE_INFO%%:*}; \
		PASS=$${NODE_INFO##*:}; \
		echo "[*] disable firewall $$NODE..."; \
		sshpass -p "$$PASS" ssh -o StrictHostKeyChecking=no $(SSH_USER)@$$NODE "sudo ufw disable"; \
	done
	@echo "------------- FIREWALL COMPLETE ----------------"


mpi-install:
	@echo "------------- MPI INSTALL ----------------"
	sudo apt install -y pkg-config openmpi-bin libopenmpi-dev
	@for NODE_INFO in $(NODES); do \
		NODE=$${NODE_INFO%%:*}; \
		PASS=$${NODE_INFO##*:}; \
		echo "[*] install mpi $$NODE..."; \
		sshpass -p "$$PASS" ssh -o StrictHostKeyChecking=no $(SSH_USER)@$$NODE " \
		 sudo apt install -y openmpi-bin libopenmpi-dev && \
		 mkdir ~/openmpi && mkdir ~/openmpi/bin && \
		 sudo cp /usr/lib/x86_64-linux-gnu/openmpi/include/openmpi/orte/orted ~/openmpi/bin"; \
	done
	@echo "------------- MPI INSTALL COMPLETE ----------------"

mpi-clean:
	@echo "------------- MPI DEL ----------------"
	@for NODE_INFO in $(NODES); do \
		NODE=$${NODE_INFO%%:*}; \
		PASS=$${NODE_INFO##*:}; \
		echo "[*] delete mpi $$NODE..."; \
		sshpass -p "$$PASS" ssh -o StrictHostKeyChecking=no "$(SSH_USER)@$$NODE" \
		"sudo pkill -u $$USER -f mpirun || true; sudo rm -rf /dev/shm/openmpi.*; \
		 sudo pkill -9 pmix orted mpirun hpl || true;" || true; \
	done
	@echo "------------- MPI DEL COMPLETE ----------------"


#-------------------------------
#Shared filesystem setup (NFS)
#-------------------------------
shared-fs:
	@echo "------------- SHARED FILESYSTEM ----------------"
	sudo bash setup_manila.sh
	@for NODE_INFO in $(NODES); do \
		NODE=$${NODE_INFO%%:*}; \
		PASS=$${NODE_INFO##*:}; \
		echo "[*] Running setup_manila.sh on $$NODE..."; \
		cat setup_manila.sh | sshpass -p "$$PASS" ssh -o StrictHostKeyChecking=no "$(SSH_USER)@$$NODE" sudo bash -s; \
	done
	@echo "------------- SHARED FILESYSTEM ----------------"


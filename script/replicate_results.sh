# Note that this Shell script must be run with the the additional kernel instrumentatations

#!/bin/bash

if [ "$(id -u)" != "0" ]; then
   echo "[ERROR] This script must be run as root!"
   exit
fi

# Step0A: Download and split raw traffic captures
mkdir $1
wget -P $1 http://mawi.nezu.wide.ad.jp/mawi/samplepoint-F/2020/202004071400.pcap.gz
gzip -dc $1/202004071400.pcap.gz $1
../bin/PcapSpliter $1/202004071400.pcap -m connection -out $1
rm $1/202004071400.pcap.gz $1/202004071400.pcap

# Step0B: Install instrumented kernel
sudo dpkg -i ../bin/*.deb

# Step1: Replay the specified pcap files
# (Note this step needs to happen after the instrumented kernel is installed [Step0B])
sudo iptables -A INPUT -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT
sudo python3 per_packet_replay_pcap.py --pcap-dir $1 --output ../data/replay_res/mawi_substate_ws_fixed.csv --interface lo
sudo iptables -D INPUT -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT

# Step2: Combine dumped states and packet features to form the dataset
python3 analyze_packet_trace.py --pcap-dir $1 --dataset-fpath ../data/raw_dataset/mawi_ws_ds_sorted.csv.raw --kitsune-dataset-fpath ../data/raw_dataset/mawi_ws_ds_sorted.csv.raw.kitsune --dataset-type wami --sk-mapping-path ../data/replay_res/mawi_substate_ws_fixed.csv

# Step3: Preprocess formed dataset to produce dataset that is consumable by the model
sh prepare_dataset.sh mawi_ws_ds_sorted 6 none --incremental-seq-ack-strict --coarse-grained-label-overall --filter-capture-loss --dummy merge_kitsune

# Step4: Run experiments and dump results
sh run_experiment.sh 37 40 3 50 1000 cpu -1 -1 37 --train-rnn --train-ae --launch-attack mawi_ws_ds_sorted use_gates none gpu large weighted all_addi only_outbound

# Compute and visualize the results
python3 paint_fig.py --fin-our ../data/visualization/our_approach_res.csv --fin-baseline ../data/visualization/baseline_res.csv --fin-kitsune ../data/visualization/kitsune_res.csv --merged-res ../data/visualization/detection_res.csv

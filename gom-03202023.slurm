#!/bin/bash
##ENVIRONMENT SETTINGS; CHANGE WITH CAUTION
#SBATCH --export=NONE        #Do not propagate environment
#SBATCH --get-user-env=L     #Replicate login environment
  
##NECESSARY JOB SPECIFICATIONS
#SBATCH --job-name=qiime2-gom     #Set the job name to "JobExample1"
#SBATCH --time=4-00:00:00            #Set the wall clock limit to 1hr and 30min
#SBATCH --ntasks=1                 #Request 1 task
#SBATCH --ntasks-per-node=16        #Request 1 task/core per node
#SBATCH --mem=150GB                #Request 2560MB (2.5GB) per node
#SBATCH --output=qiime-gom.%j    #Send stdout/err to "Example1Out.[jobID]"

#First Executable Line
# This example requests 1 core on 1 node with 2.5 GB of RAM for 1.5 hours
# For grace, there are 48 cores with 384 GB of usable memory

export OMP_NUM_THREADS=16

eval "$(conda shell.bash hook)"

conda activate qiime2-2022.11

./qiime2-code-gom.sh

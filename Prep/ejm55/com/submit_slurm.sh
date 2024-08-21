#!/bin/bash
#SBATCH --job-name=COMejm55
#SBATCH --time=48:00:00
#SBATCH --nodes=1
#SBATCH --ntasks-per-node=10
#SBATCH --mem-per-cpu=1GB
#SBATCH --partition=bsc120c
#SBATCH --exclude=bsc120c-pg0-[1-3],bsc120c-pg0-[5-30]
#SBATCH --no-requeue

source /anfhome/.profile
module load gromacs
export GMX="gmx_mpi"
export LAUNCH="mpirun -np 10"
steps=(01_min 02_nvt_all 03_nvt_backbone 03_nvt_relax 04_npt_heavy 05_npt_relax 06_RestraintSearch)




for i in $(seq 0 $((${#steps[@]}-1)));do
    if [ ! -e ${steps[$i]}/${steps[$i]}.log ];then
        echo "${steps[$i]}/${steps[$i]}.log not exist and start running..."
        if [ $i == 0 ];then                
           echo "Running ${steps[$i]}"
           ${LAUNCH} ${GMX} grompp -f ${steps[$i]}/${steps[$i]}.mdp -c system.gro -p system.top -r system.gro -o ${steps[$i]}/${steps[$i]}.tpr
           ${LAUNCH} ${GMX} mdrun -ntomp 1 -deffnm ${steps[$i]}/${steps[$i]} -c ${steps[$i]}/${steps[$i]}_out.gro
        elif [ $i == 1 ];then
           echo "Running ${steps[$i]}"
           ${LAUNCH} ${GMX} grompp -f ${steps[$i]}/${steps[$i]}.mdp -c ${steps[$(($i-1))]}/${steps[$(($i-1))]}_out.gro -p ${steps[$i]}/${steps[$i]}.top -r ${steps[$(($i-1))]}/${steps[$(($i-1))]}_out.gro -o ${steps[$i]}/${steps[$i]}.tpr
           ${LAUNCH} ${GMX} mdrun -ntomp 1 -deffnm ${steps[$i]}/${steps[$i]} -c ${steps[$i]}/${steps[$i]}_out.gro
        else
           echo "Running ${steps[$i]}"
           ${LAUNCH} ${GMX} grompp -f ${steps[$i]}/${steps[$i]}.mdp -c ${steps[$(($i-1))]}/${steps[$(($i-1))]}_out.gro -p ${steps[$i]}/${steps[$i]}.top -r ${steps[$(($i-1))]}/${steps[$(($i-1))]}_out.gro -t ${steps[$(($i-1))]}/${steps[$(($i-1))]}.cpt -o ${steps[$i]}/${steps[$i]}.tpr
           ${LAUNCH} ${GMX} mdrun -ntomp 1 -deffnm ${steps[$i]}/${steps[$i]} -c ${steps[$i]}/${steps[$i]}_out.gro
        
        fi
    else
        value=$(tail -n 2 ${steps[$i]}/${steps[$i]}.log | head -n 1 |  awk '{print $1}')
        if [[ ${value} != "Finished" ]];then
           echo "${steps[$i]}/${steps[$i]}.log not finished and start running..."
           if [ $i == 0 ];then                
              echo "Running ${steps[$i]}"
              ${LAUNCH} ${GMX} grompp -f ${steps[$i]}/${steps[$i]}.mdp -c system.gro -p system.top -r system.gro -o ${steps[$i]}/${steps[$i]}.tpr
              ${LAUNCH} ${GMX} mdrun -ntomp 1 -deffnm ${steps[$i]}/${steps[$i]} -c ${steps[$i]}/${steps[$i]}_out.gro
           elif [ $i == 1 ];then
              echo "Running ${steps[$i]}"
              ${LAUNCH} ${GMX} grompp -f ${steps[$i]}/${steps[$i]}.mdp -c ${steps[$(($i-1))]}/${steps[$(($i-1))]}_out.gro -p ${steps[$i]}/${steps[$i]}.top -r ${steps[$(($i-1))]}/${steps[$(($i-1))]}_out.gro -o ${steps[$i]}/${steps[$i]}.tpr
              ${LAUNCH} ${GMX} mdrun -ntomp 1 -deffnm ${steps[$i]}/${steps[$i]} -c ${steps[$i]}/${steps[$i]}_out.gro
           else
              echo "Running ${steps[$i]}"
              ${LAUNCH} ${GMX} grompp -f ${steps[$i]}/${steps[$i]}.mdp -c ${steps[$(($i-1))]}/${steps[$(($i-1))]}_out.gro -p ${steps[$i]}/${steps[$i]}.top -r ${steps[$(($i-1))]}/${steps[$(($i-1))]}_out.gro -t ${steps[$(($i-1))]}/${steps[$(($i-1))]}.cpt -o ${steps[$i]}/${steps[$i]}.tpr
              ${LAUNCH} ${GMX} mdrun -ntomp 1 -deffnm ${steps[$i]}/${steps[$i]} -c ${steps[$i]}/${steps[$i]}_out.gro
        
           fi
        else 
           echo "${steps[$i]}/${steps[$i]} finished"
        fi
        
    fi
done





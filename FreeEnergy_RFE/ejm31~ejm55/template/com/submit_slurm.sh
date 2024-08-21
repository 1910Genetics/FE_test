#!/bin/bash 
#SBATCH --job-name=COMejm31~ejm55
#SBATCH --time=24:00:00    
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

NLAM=11

DLAM=$(bc -l <<< "1./(${NLAM}-1)")
FLAM=$(printf "%.4f" ${DLAM})
LAMS=($( for i in $(seq ${NLAM}); do printf " %.4f" $(bc -l <<< "($i-1.)/(${NLAM}-1.)"); done))
steps=(min nvt npt pro)



for i in $(seq 0 $((${#steps[@]}-1)));do
    for ilam in ${LAMS[@]};do
        lam=$(printf "lambda_%s" ${ilam})
        if [ ! -e "${steps[$i]}/${lam}/gromacs.log" ];then
            echo "${steps[$i]}/${lam}/gromacs.log not exist and start running..."
            if [ $i == 0 ];then
                echo "Running ${steps[$i]}/${lam}"
                ${LAUNCH} ${GMX} grompp -f ${steps[$i]}/${lam}/gromacs.mdp -c ${steps[$i]}/${lam}/gromacs.gro -p ${steps[$i]}/${lam}/gromacs.top  -o ${steps[$i]}/${lam}/gromacs.tpr
                ${LAUNCH} ${GMX} mdrun -ntomp 1 -deffnm ${steps[$i]}/${lam}/gromacs -c ${steps[$i]}/${lam}/gromacs_out.gro
            elif [ $i == 1 ];then
                echo "Running ${steps[$i]}/${lam}"
                ${LAUNCH} ${GMX} grompp -f ${steps[$i]}/${lam}/gromacs.mdp -c ${steps[$(($i-1))]}/${lam}/gromacs_out.gro -p ${steps[$i]}/${lam}/gromacs.top  -o ${steps[$i]}/${lam}/gromacs.tpr
                ${LAUNCH} ${GMX} mdrun -ntomp 1 -deffnm ${steps[$i]}/${lam}/gromacs -c ${steps[$i]}/${lam}/gromacs_out.gro
            else
                echo "Running ${steps[$i]}/${lam}"
                ${LAUNCH} ${GMX} grompp -f ${steps[$i]}/${lam}/gromacs.mdp -c ${steps[$(($i-1))]}/${lam}/gromacs_out.gro -p ${steps[$i]}/${lam}/gromacs.top  -t ${steps[$(($i-1))]}/${lam}/gromacs.cpt -o ${steps[$i]}/${lam}/gromacs.tpr
                ${LAUNCH} ${GMX} mdrun -ntomp 1 -deffnm ${steps[$i]}/${lam}/gromacs -c ${steps[$i]}/${lam}/gromacs_out.gro
            fi
        else 
            value=$(tail -n 2 ${steps[$i]}/${lam}/gromacs.log | head -n 1 |  awk '{print $1}')
            if [[ ${value} != "Finished" ]];then
                echo "${steps[$i]}/${lam}/gromacs.log not finished and start running..."
                if [ $i == 0 ];then
                    echo "Running ${steps[$i]}/${lam}"
                    ${LAUNCH} ${GMX} grompp -f ${steps[$i]}/${lam}/gromacs.mdp -c ${steps[$i]}/${lam}/gromacs.gro -p ${steps[$i]}/${lam}/gromacs.top  -o ${steps[$i]}/${lam}/gromacs.tpr
                    ${LAUNCH} ${GMX} mdrun -ntomp 1 -deffnm ${steps[$i]}/${lam}/gromacs -c ${steps[$i]}/${lam}/gromacs_out.gro
                elif [ $i == 1 ];then
                    echo "Running ${steps[$i]}/${lam}"
                    ${LAUNCH} ${GMX} grompp -f ${steps[$i]}/${lam}/gromacs.mdp -c ${steps[$(($i-1))]}/${lam}/gromacs_out.gro -p ${steps[$i]}/${lam}/gromacs.top  -o ${steps[$i]}/${lam}/gromacs.tpr
                    ${LAUNCH} ${GMX} mdrun -ntomp 1 -deffnm ${steps[$i]}/${lam}/gromacs -c ${steps[$i]}/${lam}/gromacs_out.gro
                else
                    echo "Running ${steps[$i]}/${lam}"
                    ${LAUNCH} ${GMX} grompp -f ${steps[$i]}/${lam}/gromacs.mdp -c ${steps[$(($i-1))]}/${lam}/gromacs_out.gro -p ${steps[$i]}/${lam}/gromacs.top  -t ${steps[$(($i-1))]}/${lam}/gromacs.cpt -o ${steps[$i]}/${lam}/gromacs.tpr
                    ${LAUNCH} ${GMX} mdrun -ntomp 1 -deffnm ${steps[$i]}/${lam}/gromacs -c ${steps[$i]}/${lam}/gromacs_out.gro
                fi
            else
                echo "${steps[$i]}/${lam} finished"
            fi
            
        fi
    done
    

done



                                
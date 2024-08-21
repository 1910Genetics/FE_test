# FE_test
This is a test case including protein and small molecules for free energy simulations, which is used for FE_workflow



# FE_workflow
The free energy workflow is created based on [BioSimSpace](https://github.com/OpenBioSim/biosimspace). It contains scripts to setup, run simulation via slurm and analysis for free energy using [Gromacs](https://www.gromacs.org/).

## Installation
You need to install [BioSimSpace](https://github.com/OpenBioSim/biosimspace) first. Please read their instructions.
If you install BioSimSpace using conda, it is recommended that to install FE-workflow, you need to type this in the same conda environment:
```
pip install FE-workflow
```
If installed successfully, you can call the script(i.e. AFE_parameter.py) in the terminal. 
## Free Energy Simulation
Free energy simulation using molecular dynamics is a complicated topic, it is highly recommended to read some [theories](https://manual.gromacs.org/current/reference-manual/algorithms/free-energy-calculations.html) and [tutorials](https://github.com/OpenBioSim/biosimspace_tutorials).  

Here we don't include protein structure preparation, such as adding missing residues or changing the charges. 
The test system is provided [here](https://github.com/jnutyj/FE_test). You can download it and the following command is used for this test case. 

The abbreviation here is "com" for complex(protein+ligand in water), "sol" for solvation phase (ligand in water), and "vac" for vacuum phase. 

### Relative Free Energy
*1. Network Consideration*

You need to consider different perturbations for ligand candidates in binding free energy calculation, because each relative free energy simulation is to compare two ligands. If you have a lot of ligand candidates, enumerating all possible combination of two ligands might be a waste of time. Fortunately, free energy is a state function, ane namely, given $\Delta G_{a->b}$ and $\Delta G_{a->c}$, you can get $\Delta G_{b->c}$.  Alternetively, you can create a network that minimizes the number of perturbations and selects the most similar two ligands for perturbations. 

In the [inputs](https://github.com/jnutyj/FE_test) provided here, you can type:
```
RFE_network.py -l inputs/ligands/*sdf -o output_network
```
And you can even add more ligands in other folder:
```
RFE_network.py -l inputs/ligands/*sdf ../inputs/ligands/intermediate/*sdf -o output_network
```
This script requires sdf for ligands. You can view the network in network_graph.png, and the script also generates network.dat which contains the perturbatins and the [lomap scores](https://www.ncbi.nlm.nih.gov/pmc/articles/PMC3837551/). The higher the lomap score is, the "easier" to perturbate for two ligands.  You can see the test case [here](https://github.com/jnutyj/FE_test/tree/main/output_network).

*2. Parametrize and Equilibrium*

For relative binding free energy, it is assumed that the binding pose is located, and the ligand sdf files have the correct position responding to protein pdb file. For relative solvation free energy, there is no such concern.
The purpose in this step is to add periodic box and solvent molecules to the system, and it also prepares the slurm scripts and gromacs input file for running equilibrium system. 
To prepare the protein system with ligand bound to it, you can type:
```
RFE_parameter.py -t com -w tip3p -f1 gaff2 -f2 ff14SB -s cubic -l inputs/ligands/*sdf -p inputs/protein.pdb -o Prep 
```
You can type "RFE_parameter.py -h" to get more information for how to specify each options. 

To prepare the ligand system in water, it is also similar:
```
RFE_parameter.py -t lig -w tip3p -f1 gaff2 -s cubic -l inputs/ligands/*sdf -o Prep 
```
Here, it generates a folder called Prep, which you can also check in [here](https://github.com/jnutyj/FE_test/tree/main/Prep) if you just want to see how it looks. 

Then, you need to run the equilibrium in HPC using the submit_slurm.sh script in each path. 

*3. Free Energy Setup*

After you get the equilibrium systems, then you can set up the alchemical free energy based on the network we created before. 
You can specify which type of relative free energy you want to calculate, either relative binding free energy(RBFE) or solvation free energy(RSFE). 
```
RFE_fesetup.py -t RBFE -n output_network/network.dat -f Prep -ts 5.0 -o FreeEnergy_RFE
```
Please note that RBFE is created for NPT and RSFE is created for NVT due to that vacuum phase cannot run in NPT. 
To get more information, please use "-h" flag for the script. 

*4. Free Energy Analysis*

After you run all the free energy simulation in HPC, you can collect the results and run the analysis. 
```
RFE_analysis.py -t RBFE -n output_network/network.dat -f FreeEnergy_RFE -o Results
```
It generates cvs file in the "Results" folder, and you can also specify the other folder name.

### Absolute Free Energy
To run the absolute free energy simulation, it is similar to the relative free energy. But, absolute free energy simulation does not require network for perturbations. In addition, for the absolute binding free energy(ABFE), we need to add restraints between protein and the ligand to that in the dummy state, where the ligand has no interaction with protein. 

*1. Parameter and Equilibrium*

This is almost the same step as relative free energy(the second step in relative free energy shown above). The only difference is to run long simulation for protein + ligand complex to generate trajectory, which is used for searching restraints later. 

To prepare the protein system with ligand bound to it, you can type:
```
AFE_parameter.py -t com -w tip3p -f1 gaff2 -f2 ff14SB -s cubic -l inputs/ligands/*sdf -p inputs/protein.pdb -o Prep 
```
You can type "AFE_parameter.py -h" to get more information for how to specify each options. 

To prepare the ligand system in water, it is also similar:
```
AFE_parameter.py -t lig -w tip3p -f1 gaff2 -s cubic -l inputs/ligands/*sdf -o Prep 
```
*2. Free Energy Setup*

It is also very similar to RFE. But it also includes searching the restraints for ABFE. To know more about background of restraints, please take a look at [Boresch *J Chem Inf Model* 2024, 64, 3605-3609](https://pubs.acs.org/doi/epdf/10.1021/acs.jcim.4c00442). 

This script might take some time to analyze the trajectory for restraints. In the previous step, the default setting is running 5ns. So the trajectory is very long. To shorten the time for analysis, you can run this command in the "Prep/ejm31/com/06_RestraintSearch" for instance:
```
gmx trjcov -f 06_RestraintSearch.xtc -dt 10 -o new.xtc
## save the original xtc file
mv 06_RestraintSearch.xtc 06_RestraintSearch.xtc.orig
## change the new xtc file to the name "06_RestraintSearch.xtc"
mv new.xtc 06_RestraintSearch.xtc
```
For the meaning of gromacs command, please read the gromacs manual. 

Here, you can type this to create folder to free energy:
```
AFE_fesetup.py -t ABFE -f Prep -s ejm31 -o FreeEnergy_ABFE
```
The command shown above is the example for ABFE for one ligand system. You can also specify the number of lambda windows, and running step and trials. Please use "-h" flag for more information. 

Please note that in this process, besides generating the free energy folder for simulation, in the complex phase, it also provided "restraint.dat" which contains the information of restraints and the free energy value for restraints.

*3. Free Energy Analysis*
To do the analysis after simulation, it is the same as RFE. 
```
AFE_analysis.py -t ABFE -f FreeEnergy_ABFE -s ejm31 -o Results
```
Again, it generates cvs file in the Results folder. It contains each term of free energy and error. 


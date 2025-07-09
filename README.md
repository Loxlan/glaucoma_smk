## Snakemake workflow
Cite:
- Detecting neurodegenerative changes in glaucoma using deep mean kurtosis-curve–corrected tractometry
Loxlan W. Kasa, William Schierding, Eryn Kwon, Samantha Holdsworth, Helen V Danesh-Meyer
medRxiv 2025.06.05.25329075; doi: https://doi.org/10.1101/2025.06.05.25329075

Snakemake workflow for anatomically guided tracking

Inputs:
- participants.tsv with target subject IDs
- For each target subject:
    - Freesurfer processed data
    - DWI data
- Singularity containers required:
    - [mrtrix3, freesurfer and qsiprep]

### Software Requirements
Data should be in BIDs format

### Authors
Loxlan Kasa @loxlan_kasa

### Usage
#### Step 1: Clone the repository to your local system
#### Step 2: Configure your workflow
Edit the files in the config/ folder accordingly. Adjust config.yml to configure the workflow execution and participants.tsv to specify your subjects.
#### Step 3: Install Snakemake system
Install Snakemake using conda:

```conda create -c bioconda -c conda-forge -n snakemake snakemake```

For installation details, see the instructions in the [Snakemake documentation](https://snakemake.readthedocs.io/en/stable/getting_started/installation.html).

#### Step 4: Execute workflow
Activate the conda environment:

conda activate snakemake
Test your configuration by performing a dry-run via

```snakemake --use-singularity -n```
Execute the workflow locally via

```snakemake --use-singularity --cores $N```
using $N cores or run it in a cluster environment via

```snakemake --use-singularity --cluster qsub --jobs 100```
or

```snakemake --use-singularity --drmaa --jobs 100```
If you are using HCP, you can use your slurm profile, which submits jobs and takes care of requesting the correct resources per job (including GPUs). Once it is set-up run:

```snakemake --profile slurm_profile```
Or, you can request for interactive job following your system requirements:
Then, run:

```snakemake --use-singularity --cores 8 --resources mem=32000``` 
See the [Snakemake documentation](https://snakemake.readthedocs.io/en/stable/getting_started/installation.html) for further details.

#### Step 5: Investigate results
After successful execution, you can create a self-contained interactive HTML report with all results via:

```snakemake --report report.html```

## Open Data and Software
This study incooperated open tools and the UKBB, listed below:
- UKBB
  https://www.ukbiobank.ac.uk/enable-your-research/about-our-data
- [Detect](https://github.com/chamberm/Detect.git)
- [SCILPY](github.com/scilus/scilpy)



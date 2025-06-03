#preprocess subject T1 with freesurfer before ACT
rule freesurfer:
    input: join(config['deriv_dir'],'bids/{subject}/ses-2/anat/{subject}_ses-2_T1_orig_defaced.nii.gz')
    output: join(config['deriv_dir'],'freesurfer/{subject}/scripts/recon-all.done')        
    params:
        sd = join(config['deriv_dir'],'freesurfer'),
        fs_setup = config['fs_setup']          
    container: config['mrtrix3']     
    resources:
        cpus=lambda wildcards, threads: threads,
        mem_mb=config["long_fat"]["mem_mb"],
        runtime=config["long_fat"]["time_min"]
    threads: config["long_fat"]["threads"]  
    shell:
        "mkdir -p {params.sd}/{wildcards.subject}/mri/orig && "
        "{params.fs_setup} mri_convert {input} {params.sd}/{wildcards.subject}/mri/orig/001.mgz -nc && "
        "{params.fs_setup} recon-all -all -s {wildcards.subject} -sd {params.sd}"



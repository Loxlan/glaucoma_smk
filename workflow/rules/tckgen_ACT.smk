##converting from .nii to .mif format
rule nii2mif:
    input:
        dwi = join(config['deriv_dir'],'MK-Curve/{subject}/out/threshold_0.50/corrected_nii/corrected_dwi.nii.gz'),
        bvecs = join(config['deriv_dir'],'MK-Curve/{subject}/out/threshold_0.50/corrected_nii/corrected_bvec'),
        bvals = join(config['deriv_dir'],'MK-Curve/{subject}/out/threshold_0.50/corrected_nii/corrected_bval')        
    output: 
        dwi_mif = join(config['deriv_dir'],'tckgen_ACT/{subject}/{subject}_corrected_dwi.mif'),
        bvecs = join(config['deriv_dir'],'tckgen_ACT/{subject}/{subject}_corrected.bvec'),
        bvals = join(config['deriv_dir'],'tckgen_ACT/{subject}/{subject}_corrected.bval'),     
        brain_mask = join(config['deriv_dir'],'tckgen_ACT/{subject}/{subject}_corrected_brainmask.nii.gz'), 
        brain_mask_mif = join(config['deriv_dir'],'tckgen_ACT/{subject}/{subject}_corrected_brainmask.mif')
    container: config['mrtrix3']
    resources:
        cpus=lambda wildcards, threads: threads,
        mem_mb=config["shot_skinny"]["mem_mb"],
        runtime=config["shot_skinny"]["time_min"]
    threads: config["shot_skinny"]["threads"]  
    shell:
        "mrconvert {input.dwi} {output.dwi_mif} -fslgrad {input.bvecs} {input.bvals} -export_grad_fsl {output.bvecs} {output.bvals} && " 
        "dwi2mask {input.dwi} {output.brain_mask} -fslgrad {output.bvecs} {output.bvals} && "      
        "mrconvert {output.brain_mask} {output.brain_mask_mif}"

# ## Generate response function
rule response_fn:
    input: 
        dwi_mif = rules.nii2mif.output.dwi_mif
    output:
        wmresponse_out = join(config['deriv_dir'],'tckgen_ACT/{subject}/{subject}_corrected_wmresponse.txt'),
        gmresponse_out = join(config['deriv_dir'],'tckgen_ACT/{subject}/{subject}_corrected_gmresponse.txt'),
        csfresponse_out = join(config['deriv_dir'],'tckgen_ACT/{subject}/{subject}_corrected_csfresponse.txt')     
    container: config['mrtrix3']
    resources:
        cpus=lambda wildcards, threads: threads,
        mem_mb=config["shot_fat"]["mem_mb"],
        runtime=config["shot_fat"]["time_min"]
    threads: config["shot_fat"]["threads"]  
    shell: 
        "dwi2response dhollander {input.dwi_mif} {output.wmresponse_out} {output.gmresponse_out} {output.csfresponse_out}"

# # ## Generate fods
rule fods:
    input:
        dwi_mif = rules.nii2mif.output.dwi_mif,
        wmresponse_in = rules.response_fn.output.wmresponse_out,
        gmresponse_in = rules.response_fn.output.gmresponse_out,
        csfresponse_in = rules.response_fn.output.csfresponse_out,
        brain_mask = rules.nii2mif.output.brain_mask_mif
    output:
        wmfod_out = join(config['deriv_dir'],'tckgen_ACT/{subject}/{subject}_corrected_wmfod.mif'),
        gmfod_out = join(config['deriv_dir'],'tckgen_ACT/{subject}/{subject}_corrected_gmfod.mif'),
        csffod_out = join(config['deriv_dir'],'tckgen_ACT/{subject}/{subject}_corrected_csffod.mif')       
    container: config['mrtrix3']
    resources:
        cpus=lambda wildcards, threads: threads,
        mem_mb=config["shot_fat"]["mem_mb"],
        runtime=config["shot_fat"]["time_min"]
    threads: config["shot_fat"]["threads"]   
    shell: 
        "dwi2fod msmt_csd {input.dwi_mif} {input.wmresponse_in} {output.wmfod_out} {input.gmresponse_in} "
        "{output.gmfod_out} {input.csfresponse_in} {output.csffod_out} -mask {input.brain_mask}"     

## Generate five-tissue-type
rule fivetissues:
    input:
        fs_sd = join(config['deriv_dir'],'freesurfer/{subject}')
    output:
        tissues = join(config['deriv_dir'],'tckgen_ACT/{subject}/{subject}_corrected_5tt.mif'),
        gmwm_mask = join(config['deriv_dir'],'tckgen_ACT/{subject}/{subject}_corrected_gmwm-mask.mif'),
        gmwm_mask_nii = join(config['deriv_dir'],'tckgen_ACT/{subject}/{subject}_corrected_5tt_gmwm-mask.nii.gz')       
    params: join(config['deriv_dir'],'tckgen_ACT/{subject}')
    container: config['mrtrix3']
    resources:
        cpus=lambda wildcards, threads: threads,
        mem_mb=config["shot_fat"]["mem_mb"],
        runtime=config["shot_fat"]["time_min"]
    threads: config["shot_fat"]["threads"]      
    shell:
        '''
        5ttgen hsvs {input.fs_sd} {output.tissues} -scratch {params}
        5tt2gmwmi {output.tissues} {output.gmwm_mask}
        mrconvert {output.gmwm_mask} {output.gmwm_mask_nii}
        '''
rule binarize_seed:
    input:
        seed_roi = join(config['deriv_dir'],'tckgen_ACT/{subject}/{subject}_corrected_5tt_gmwm-mask.nii.gz')
    output:
        seed_roi_bin = join(config['deriv_dir'],'tckgen_ACT/{subject}/{subject}_corrected_5tt_gmwm-mask_bin.nii'),    #Error with fsl .gz default output on NeSI
        seed_roi_bin_mif = join(config['deriv_dir'],'tckgen_ACT/{subject}/{subject}_corrected_5tt_gmwm-mask_bin.mif')                 
    container: config['mrtrix3']
    resources:
        cpus=lambda wildcards, threads: threads,
        mem_mb=config["shot_skinny"]["mem_mb"],
        runtime=config["shot_skinny"]["time_min"]
    threads: config["shot_skinny"]["threads"]      
    shell:
        "fslmaths {input.seed_roi} -bin {output.seed_roi_bin} && "
        "mrconvert {output.seed_roi_bin} {output.seed_roi_bin_mif}"
        
# #currently doing whole-brain, tract-specific can be added
rule ACT:
    input:
        wmfod = rules.fods.output.wmfod_out,
        tissues = rules.fivetissues.output.tissues,
        seed_mask = rules.binarize_seed.output.seed_roi_bin,
        bvecs = rules.nii2mif.output.bvecs,
        bvals = rules.nii2mif.output.bvals
    output:
        tck_out = join(config['deriv_dir'],'tckgen_ACT/{subject}/{subject}_corrected_whole-brain_10M.tck'),
        # smallertck_out = join(config['deriv_dir'],'tckgen_ACT/{subject}/{subject}_corrected_whole-brain_100K.tck')          
    params:
        optional = '-crop_at_gmwmi -step 0.8 -minlength 8 -maxlength 250 -cutoff 0.06' 
    container:config['mrtrix3']    
    resources:
        cpus=lambda wildcards, threads: threads,
        mem_mb=config["long_fat"]["mem_mb"],
        runtime=config["long_fat"]["time_min"]
    threads: config["long_fat"]["threads"]      
    shell:
        "tckgen {input.wmfod} {output.tck_out} -act {input.tissues} {params.optional} -seed_image {input.seed_mask} "
        "-select 10000000 -seed_unidirectional -fslgrad {input.bvecs} {input.bvals}"
    
    
clc
clear
setenv('LD_LIBRARY_PATH','');
setenv('SUBJECTS_DIR',fullfile('./subjects/'))

temp_dir = './templates/'
hemi = {'lh','rh'};
FS_dir = './subjects';
freesurfer_init
% template_L = dir(sprintf('%s/*.L.*.nii',temp_dir))
% template_R = dir(sprintf('%s/*.R.*.nii',temp_dir))

% system(sprintf('wb_command -cifti-separate %sQ1-Q6_RelatedParcellation210.R.CorticalAreas_dil_Colors.32k_fs_LR.dlabel.nii COLUMN -label CORTEX_RIGHT %sQ1-Q6_RelatedParcellation210.R.CorticalAreas_dil_Colors.32k_fs_LR.label.gii',temp_dir,temp_dir))
% system(sprintf('wb_command -cifti-separate %sQ1-Q6_RelatedParcellation210.L.CorticalAreas_dil_Colors.32k_fs_LR.dlabel.nii COLUMN -label CORTEX_LEFT %sQ1-Q6_RelatedParcellation210.L.CorticalAreas_dil_Colors.32k_fs_LR.label.gii',temp_dir,temp_dir))

subjects = dir('./subjects/*')
list =regexp({subjects.name},'\d{6}','match');
mysubj = find(~cellfun(@isempty,list));
subjects = subjects(mysubj);
%%
for s = 1 : length(subjects)
    
    subject = subjects(s).name
    
    anat = sprintf('./subjects_diffusion/%s/T1w/T1w_acpc_dc_restore_1.25.nii.gz',subject);
    anatFSmgz = sprintf('%s/%s/mri/brain.mgz',FS_dir,subject);
    anatFSnii = sprintf('%s/%s/mri/brain.nii.gz',FS_dir,subject);
    anatINmni = sprintf('./subjects_diffusion/%s/T1w/T1w_acpc_dc_restore_1.25_mni.nii.gz',subject);
    anat2standard = sprintf('./subjects_diffusion/%s/xfms/acpc_dc2standard.nii.gz',subject);
    standard2anat = sprintf('./subjects_diffusion/%s/xfms/standard2acpc_dc.nii.gz',subject);
    standard_MNI = '/usr/local/fsl/data/standard/MNI152_T1_1mm.nii.gz';
    roi4track = sprintf('./subjects_diffusion/%s/roi4track/',subject);
    LGNinMNI = './LGNS/';
    mkdir(roi4track)
    template_dir = sprintf('./subjects_diffusion/%s/Native/',subject);
    subject_dti_dir = sprintf('./subjects_diffusion/%s/Diffusion/',subject);
    bvals = sprintf('./subjects_diffusion/%s/Diffusion/bvals',subject);
    bvecs = sprintf('./subjects_diffusion/%s/Diffusion/bvecs',subject);
    dwi_str = sprintf('./subjects_diffusion/%s/Diffusion/data.nii.gz',subject);
    subjectfolder = sprintf('./subjects_diffusion/%s/',subject);
    fibers_dir = sprintf('./subjects_diffusion/%s/fibers/',subject);
    
    
    subject_dir = sprintf('./subjects/%s/',subject)
    
    
    subject_sphere_dir =  sprintf('./subjects_diffusion/%s/Native/',subject)
    dir164k = sprintf('./subjects_diffusion/%s/Native/',subject);
    
    system(sprintf('wb_command -label-resample %sQ1-Q6_RelatedParcellation210.L.CorticalAreas_dil_Colors.32k_fs_LR.label.gii  %sL.sphere.32k_fs_LR.surf.gii %s%s.L.sphere.164k_fs_LR.surf.gii BARYCENTRIC %sQ1-Q6_RelatedParcellation210.L.CorticalAreas_dil_Colors.164k_fs_LR.label.gii', temp_dir,temp_dir,dir164k,subject,subject_sphere_dir))
    system(sprintf('wb_command -label-resample %sQ1-Q6_RelatedParcellation210.R.CorticalAreas_dil_Colors.32k_fs_LR.label.gii  %sR.sphere.32k_fs_LR.surf.gii %s%s.R.sphere.164k_fs_LR.surf.gii BARYCENTRIC %sQ1-Q6_RelatedParcellation210.R.CorticalAreas_dil_Colors.164k_fs_LR.label.gii', temp_dir,temp_dir,dir164k,subject,subject_sphere_dir))
    
    
    system(sprintf('wb_command -label-resample %sQ1-Q6_RelatedParcellation210.L.CorticalAreas_dil_Colors.164k_fs_LR.label.gii %s%s.L.sphere.164k_fs_LR.surf.gii  %s%s.L.sphere.MSMAll.native.surf.gii  BARYCENTRIC %sleft.native.label.gii',subject_sphere_dir,dir164k,subject,subject_sphere_dir,subject,subject_sphere_dir))
    system(sprintf('wb_command -label-resample %sQ1-Q6_RelatedParcellation210.R.CorticalAreas_dil_Colors.164k_fs_LR.label.gii %s%s.R.sphere.164k_fs_LR.surf.gii  %s%s.R.sphere.MSMAll.native.surf.gii  BARYCENTRIC %sright.native.label.gii',subject_sphere_dir,dir164k,subject,subject_sphere_dir,subject,subject_sphere_dir))
    
    system(sprintf('%smris_convert --annot %sleft.native.label.gii %s%s.L.sphere.MSMAll.native.surf.gii %s/label/lh.HCP-MMP1.nat.annot',freesurfer_string,subject_sphere_dir,subject_sphere_dir,subject,subject_dir))
    system(sprintf('%smris_convert --annot %sright.native.label.gii %s%s.R.sphere.MSMAll.native.surf.gii %s/label/rh.HCP-MMP1.nat.annot',freesurfer_string,subject_sphere_dir,subject_sphere_dir,subject,subject_dir))
    
    
    
    
    
    mkdir(sprintf('%slabels_MSM',subject_dir))
    
    for h = 1 : length(hemi)
%         system(sprintf('mri_annotation2label --subject %s --hemi %s --annotation HCP-MMP1.nat --outdir %slabels_MSM',subject,hemi{h},subject_dir))
        
%         source = sprintf('%slabels_MSM/%s.%s_ProS_ROI.label',subject_dir,hemi{h},upper(hemi{h}(1)));
%         target = sprintf('%slabel/%s.ProS.msm.label',subject_dir,hemi{h})
%         copyfile(source,target)
        
        system(sprintf('mri_label2vol --label %s%s.ProS.msm.label --temp %s --hemi %s --identity --subject %s --o %s%s.ProS.msm.label.nii.gz',[subject_dir 'label/'],hemi{h},anatFSnii,hemi{h},subject,roi4track,hemi{h}));%
        system(sprintf('3dAllineate -input %s%s.ProS.msm.label.nii.gz -newgrid 1.25 -prefix %s%s.Pros_vol_1.25.nii.gz -final wsinc5 -master %s -1Dparam_apply ''1D: 12@0''\\''',roi4track,hemi{h},roi4track,hemi{h},anat));
        tmp = load_nifti(sprintf('%s%s.Pros_vol_1.25.nii.gz',roi4track,hemi{h}));
        tmp.vol = tmp.vol > 0.3;
        save_nifti(tmp,sprintf('%s%s.Pros_vol_1.25_clean.nii.gz',roi4track,hemi{h}));
    end
    
    
    
end



%%

clc
clear all
startup
subjects = {'102311'}

rois = {'LGN_lh_30.nii.gz';'LGN_rh_30.nii.gz'}
hemi = {'lh';'rh'}
FS_dir = '/Applications/freesurfer/';
mypython_dist = '/usr/bin/python';
subcort = 1;
cort = 1;
anatINmni = 0;

subjects = dir('./subjects/*')
list =regexp({subjects.name},'\d{6}','match');
mysubj = find(~cellfun(@isempty,list));
subjects = subjects(mysubj);

%%
for s = 1 : length(subjects)
    
    subject = subjects(s).name;
    
    setenv('SUBJECTS_DIR','/usr/local/freesurfer/subjects');
    anat = sprintf('./%s/T1w/T1w_acpc_dc_restore_1.25.nii.gz',subject);
    anatINmni = sprintf('./%s/T1w/T1w_acpc_dc_restore_1.25_mni.nii.gz',subject);
    anat2standard = sprintf('./%s/xfms/acpc_dc2standard.nii.gz',subject);
    standard2anat = sprintf('./%s/xfms/standard2acpc_dc.nii.gz',subject);
    standard_MNI = '/usr/local/fsl/data/standard/MNI152_T1_1mm.nii.gz';
    roi4track = sprintf('./%s/roi4track/',subject);
    LGNinMNI = './LGNS/';
    mkdir(roi4track);
    template_dir = sprintf('./%s/Native/',subject);
    subject_dir = sprintf('./subjects/%s/',subject);
    anatFSnii = sprintf('%smri/brain.nii.gz',subject_dir);
    
    if anatINmni 
        
        system(sprintf('applywarp -v -i %s -r %s -w %s  -o %s',anat, standard_MNI,anat2standard,anatINmni));
    end
    system(sprintf('mri_convert %s/mri/brain.mgz %s/mri/brain.nii.gz',subject_dir,subject_dir))
    
    if subcort
        
        for r = 1 : length(rois)
            
            roi2warp = sprintf('%s%s',LGNinMNI,rois{r});
            roiwarped = sprintf('%s%s',roi4track,rois{r});
            system(sprintf('applywarp -v -i %s -r %s -w %s  -o %s',roi2warp,anat,standard2anat,roiwarped));
            tmp = load_nifti(roiwarped);
            tmp.vol = tmp.vol>0;
            save_nifti(tmp,roiwarped);

        end
        
    end
    
    if cort
        system(sprintf('%s -m neuropythy benson14_retinotopy %s -x',mypython_dist,subject_dir))
        
        for h = 1 : length(hemi)
            
            setenv('SUBJECTS_DIR','./subjects/');

            system(sprintf('mri_convert %ssurf/%s.benson14_varea %ssurf/%s.benson14_varea.nii.gz',subject_dir,hemi{h},subject_dir,hemi{h}));
            system(sprintf('mri_convert %ssurf/%s.benson14_eccen %ssurf/%s.benson14_eccen.nii.gz',subject_dir,hemi{h},subject_dir,hemi{h}));
            system(sprintf('mri_convert %ssurf/%s.benson14_angle %ssurf/%s.benson14_angle.nii.gz',subject_dir,hemi{h},subject_dir,hemi{h}));
            
            ecc = load_nifti(sprintf('%ssurf/%s.benson14_eccen.nii.gz',subject_dir,hemi{h}));
            ang = load_nifti(sprintf('%ssurf/%s.benson14_angle.nii.gz',subject_dir,hemi{h}));
            vea = load_nifti(sprintf('%ssurf/%s.benson14_varea.nii.gz',subject_dir,hemi{h}));
            
            V1 = vea.vol == 1;
            tmp = ecc;
            tmp.vol = tmp.vol .* V1;
            thr = mean(tmp.vol(tmp.vol~=0));
            
            tmp.vol = (ecc.vol<thr) .* V1;
            save_nifti(tmp,sprintf('%s%s.V1_fov_surf.nii.gz',roi4track,hemi{h}));
            system(sprintf('mri_surf2vol --surfval %s%s.V1_fov_surf.nii.gz --template %s --hemi %s --identity %s --o %s%s.V1_fov_vol.nii.gz',roi4track,hemi{h},anatFSnii,hemi{h},subject,roi4track,hemi{h}));%
            
            tmp.vol = (ecc.vol>thr) .* V1;
            save_nifti(tmp,sprintf('%s%s.V1_peri_surf.nii.gz',roi4track,hemi{h}))
            system(sprintf('mri_surf2vol --surfval %s%s.V1_peri_surf.nii.gz --template %s --hemi %s --identity %s --o %s%s.V1_peri_vol.nii.gz',roi4track,hemi{h},anatFSnii,hemi{h},subject,roi4track,hemi{h}));%
            
            tmp.vol = (ang.vol<90) .* V1;
            save_nifti(tmp,sprintf('%s%s.V1_inf_surf.nii.gz',roi4track,hemi{h}))
            system(sprintf('mri_surf2vol --surfval %s%s.V1_inf_surf.nii.gz --template %s --hemi %s --identity %s --o %s%s.V1_inf_vol.nii.gz',roi4track,hemi{h},anatFSnii,hemi{h},subject,roi4track,hemi{h}));%
            
            tmp.vol = (ang.vol>90) .* V1;
            save_nifti(tmp,sprintf('%s%s.V1_sup_surf.nii.gz',roi4track,hemi{h}))
            system(sprintf('mri_surf2vol --surfval %s%s.V1_sup_surf.nii.gz --template %s --hemi %s --identity %s --o %s%s.V1_sup_vol.nii.gz',roi4track,hemi{h},anatFSnii,hemi{h},subject,roi4track,hemi{h}));%
            
            
            
            names = {'inf';'sup';'peri';'fov'};
            for n = 1 : length(names)
                
                system(sprintf('3dAllineate -input %s%s.V1_%s_vol.nii.gz -newgrid 1.25 -prefix %s%s.V1_%s_vol_1.25.nii.gz -final wsinc5 -master %s -1Dparam_apply ''1D: 12@0''\\''',roi4track,hemi{h},names{n},roi4track,hemi{h},names{n},anat));
                tmp = load_nifti(sprintf('%s%s.V1_%s_vol_1.25.nii.gz',roi4track,hemi{h},names{n}));
                tmp.vol = tmp.vol > 0.3;
                save_nifti(tmp,sprintf('%s%s.V1_%s_vol_1.25_clean.nii.gz',roi4track,hemi{h},names{n}));
                
            end
        end
    end
end
clc
clear all
close all

subjects = dir('./subjects/*')
list =regexp({subjects.name},'\d{6}','match');
mysubj = find(~cellfun(@isempty,list));
subjects = subjects(mysubj);

addpath(genpath('./vistasoft-master'))
addpath(genpath('./encode-0.45'))
Niter = 500
setenv('LD_LIBRARY_PATH','');
pos  = {'dors';'vent'}
hemi = {'lh';'rh'}


cmap =[[14 200 200];[255 140 0];[20 158 29]]
cmap = [[50 220 254];[253 255 6];[11 102 35]]
cmap = [[64 219 253];[251 251 56];[47 213 102]]

trans = 0
%%
ct = 1


for s = 1:  length(subjects);% 3 7 8 9 ran just before Jan left March2018
    
    subject = subjects(s).name
    
    anat = sprintf('./subjects_diffusion/%s/T1w/T1w_acpc_dc_restore_1.25.nii.gz',subject);
    anatINmni = sprintf('./subjects_diffusion/%s/T1w/T1w_acpc_dc_restore_1.25_mni.nii.gz',subject);
    anat2standard = sprintf('./subjects_diffusion/%s/xfms/acpc_dc2standard.nii.gz',subject);
    standard2anat = sprintf('./subjects_diffusion/%s/xfms/standard2acpc_dc.nii.gz',subject);
    standard_MNI = '/usr/local/fsl/data/standard/MNI152_T1_1mm.nii.gz';
    roi4track = sprintf('./subjects_diffusion/%s/roi4track/',subject);
    LGNinMNI = './LGNS/';
    %     mkdir(roi4track)
    template_dir = sprintf('./subjects_diffusion/%s/Native/',subject);
    subject_dir = sprintf('./subjects/%s/',subject);
    subject_dir_labels = sprintf('./subjects/%s/label/',subject);
    
    subject_dti_dir = sprintf('./subjects_diffusion/%s/Diffusion/',subject);
    bvals = sprintf('./subjects_diffusion/%s/Diffusion/bvals',subject);
    bvecs = sprintf('./subjects_diffusion/%s/Diffusion/bvecs',subject);
    dwi = sprintf('./subjects_diffusion/%s/Diffusion/data.nii.gz',subject);
    subjectfolder = sprintf('./subjects_diffusion/%s/',subject);
    fibers_dir = sprintf('./subjects_diffusion/%s/fibers/',subject);
    subject_dir_life = sprintf('./subjects_diffusion/%s/life/',subject);
    dwiFile = sprintf('%sdata_aligned_trilin_noMEC.nii.gz',subjectfolder);
    
    
  
    
    
    for h = 1  : length(hemi)
        fib = dir([subject_dir_life sprintf('*%s*vol*.mat',hemi{h})]);
        for p = 1 : length(pos)
            
            
            roi = load(sprintf('%s/labels_MSM/%s.%s.Pros_%s_125_nonZero_MaskROI.mat',subject_dir,hemi{h},upper(hemi{h}(1)),pos{p}));
            if exist(sprintf('%s/LGN_%s-%s.Pros_vol.tck',subject_dir_life,hemi{h},hemi{h}))
            tck = fgRead(sprintf('%s/LGN_%s-%s.Pros_vol.tck',subject_dir_life,hemi{h},hemi{h}));
            %         fgWrite(sprintf('%s/%s',subject_dir_life,[rois(rr).name ))
            [fgOut,contentiousFibers, keep] =   dtiIntersectFibersWithRoi([], {'and'}, 1, roi.roi, tck);
            
            percent_of_fib(p,ct) = sum(keep)./length(tck.fibers);
            end
            
        end
        ct = ct + 1
        
    end
end
%%

sprintf('%% of dors fibers is %.2f',mean(percent_of_fib(1,:)))
sprintf('%% of vent fibers is %.2f',mean(percent_of_fib(2,:)))
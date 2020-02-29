clc
clear all


subjects = dir('./*')
list =regexp({subjects.name},'\d{6}','match');
mysubj = find(~cellfun(@isempty,list));
subjects = subjects(mysubj);

addpath(genpath('./vistasoft-master'))
addpath(genpath('./encode-0.45'))
Niter = 500
setenv('LD_LIBRARY_PATH','');

%%
for s = 2:  length(subjects);% 3 7 8 9 ran just before Jan left March2018
    
    subject = subjects(s).name
    
    anat = sprintf('./%s/T1w/T1w_acpc_dc_restore_1.25.nii.gz',subject);
    anatINmni = sprintf('./%s/T1w/T1w_acpc_dc_restore_1.25_mni.nii.gz',subject);
    anat2standard = sprintf('./%s/xfms/acpc_dc2standard.nii.gz',subject);
    standard2anat = sprintf('./%s/xfms/standard2acpc_dc.nii.gz',subject);
    standard_MNI = '/usr/local/fsl/data/standard/MNI152_T1_1mm.nii.gz';
    roi4track = sprintf('./%s/roi4track/',subject);
    LGNinMNI = './LGNS/';
    mkdir(roi4track)
    template_dir = sprintf('./%s/Native/',subject);
    subject_dir = sprintf('./subjects/%s/',subject);
    subject_dti_dir = sprintf('./%s/Diffusion/',subject);
    bvals = sprintf('./%s/Diffusion/bvals',subject);
    bvecs = sprintf('./%s/Diffusion/bvecs',subject);
    dwi = sprintf('./%s/Diffusion/data.nii.gz',subject);
    subjectfolder = sprintf('./%s/',subject);
    fibers_dir = sprintf('./%s/fibers/',subject);
    subject_dir_life = sprintf('./%s/life/',subject);
    dwiFile = sprintf('%sdata_aligned_trilin_noMEC.nii.gz',subjectfolder);


    
    rois = dir([subject_dir_life '*.tck']);
    rois=rois(~ismember({rois.name},{'.','..','conTrack','.DS_Store'}));
    
    
    for rr = 1 : length(rois)
        
    system(sprintf('tckmap %s%s %s%s -template %s',subject_dir_life,rois(rr).name,subject_dir_life,[rois(rr).name(1:end-4) '.nii.gz'],anat))
    system(sprintf('applywarp -v -i %s%s -r %s -w %s  -o %s%s',subject_dir_life,[rois(rr).name(1:end-4) '.nii.gz'], standard_MNI,anat2standard,subject_dir_life,[rois(rr).name(1:end-4) '_MNI.nii.gz']));

    end

end
    
    %%
    
    
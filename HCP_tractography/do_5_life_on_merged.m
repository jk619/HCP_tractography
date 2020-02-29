clc
clear all


subjects = dir('./subjects/*')
list =regexp({subjects.name},'\d{6}','match');
mysubj = find(~cellfun(@isempty,list));
subjects = subjects(mysubj);

addpath(genpath('./vistasoft-master'))
addpath(genpath('./encode-0.45'))
Niter = 500
%%
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
    fibers_dir = sprintf('./subjects_diffusion/%s/fibers_stop/',subject);
    subject_dir_life = sprintf('./subjects_diffusion/%s/life/',subject);
    dwiFile = sprintf('%sdata_aligned_trilin_noMEC.nii.gz',subjectfolder);
    
    
    rois = dir([fibers_dir '*Pros*'])
    rois=rois(~ismember({rois.name},{'.','..','conTrack','.DS_Store'}));

  
    
    %%
    
    
    for r = 1 : size(rois,1)
        
        
        allfib = load(sprintf('%s%s/allfib',fibers_dir,rois(r).name),'allfib');
        allfib = allfib.allfib;
        
        %%
        
        name = sprintf('%s%s',subject_dir_life,rois(r).name);

        
%         if exist([name '.tck'],'file')
            
            
            
%         else
            
            feFileName = sprintf('%s',rois(r).name);
            fe = feConnectomeInit(dwiFile,allfib,feFileName,[],dwiFile,anat);
            fe = feSet(fe,'fit',feFitModel(feGet(fe,'model'),feGet(fe,'dsigdemeaned'),'bbnnls',Niter,'preconditioner'));
%             fe = feSet(fe,'fit',feFitModel_gpu_opt(feGet(fe,'model'),feGet(fe,'dsigdemeaned'),'bbnnls',Niter,'preconditioner'));

            w  = feGet(fe,'fiber weights');
            positive_w_all = w > 0;
            fgl_pos = feGet(fe,'fibers acpc');
            fgl_pos = fgExtract(fgl_pos, positive_w_all, 'keep');
            fgWrite(fgl_pos,[name '.tck'],'tck');
            fgWrite(fgl_pos,[name '.mat'],'mat');

            
%         end
  
    end
end

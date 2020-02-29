clc
clear all


subjects = dir('./from_Brainlife/dtiInit/*')
list =regexp({subjects.name},'\d{6}','match');
mysubj = find(~cellfun(@isempty,list));
subjects = subjects(mysubj);

addpath(genpath('./vistasoft-master'))
addpath(genpath('./encode-0.45'))
Niter = 500
rois{1} = 'left_hemisphere'
rois{2} = 'right_hemisphere'
%%
        temp = fgRead('temp.tck');

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
    b1000_fol =  sprintf('./from_Brainlife/dtiInit/%s/b1000',subject);
    fa_map = sprintf('./from_Brainlife/dtiInit/%s/S500/fa.nii.gz',subject);
    
    subject_dti_dir = sprintf('./subjects_diffusion/%s/Diffusion/',subject);
    bvals = sprintf('./subjects_diffusion/%s/Diffusion/bvals',subject);
    bvecs = sprintf('./subjects_diffusion/%s/Diffusion/bvecs',subject);
    dwi = sprintf('./subjects_diffusion/%s/Diffusion/data.nii.gz',subject);
    subjectfolder = sprintf('./subjects_diffusion/%s/',subject);
    
    fibers_dir = sprintf('./from_Brainlife/tracts_bl/%s/',subject);
    subject_dir_life = sprintf('./from_Brainlife/dtiInit/%s/b1000/life',subject);
    mkdir(subject_dir_life)
    
    dwiFile = sprintf('%s/dwi_aligned_trilin_noMEC.nii.gz',b1000_fol);
    
    
    %     rois = dir([fibers_dir '*Pros*'])
    %     rois=rois(~ismember({rois.name},{'.','..','conTrack','.DS_Store'}));
    
    
    
    
    
    %%
    if exist(sprintf('%s%s/track.tck',fibers_dir,rois{1}),'file') && exist(sprintf('%s%s/track.tck',fibers_dir,rois{2}),'file') ...
            && exist(dwiFile,'file');
        
        
        
        for r = 1 : length(rois)
            
            
            allfib = read_mrtrix_tracks(sprintf('%s%s/track.tck',fibers_dir,rois{r}));
            %         allfib = allfib.allfib;
            
            %%
            temp.fibers = allfib.data';
            temp.fibers = cellfun(@transpose, temp.fibers,'UniformOutput',false);
            
            name = sprintf('%s/%s',subject_dir_life,rois{r});
            
            
            if ~exist([name '.tck'],'file') && ~isempty(temp.fibers)
                
                
                
                %         else
                
                feFileName = sprintf('%s',rois{r});
                fe = feConnectomeInit(dwiFile,temp,feFileName,[],dwiFile,anat);
                fe = feSet(fe,'fit',feFitModel(feGet(fe,'model'),feGet(fe,'dsigdemeaned'),'bbnnls',Niter,'preconditioner'));
                %             fe = feSet(fe,'fit',feFitModel_gpu_opt(feGet(fe,'model'),feGet(fe,'dsigdemeaned'),'bbnnls',Niter,'preconditioner'));
                
                w  = feGet(fe,'fiber weights');
                positive_w_all = w > 0;
                fgl_pos = feGet(fe,'fibers acpc');
                fgl_pos = fgExtract(fgl_pos, positive_w_all, 'keep');
                fgWrite(fgl_pos,[name '.tck'],'tck');
                fgWrite(fgl_pos,[name '.mat'],'mat');
                
            end
            %         end
            
        end
        
    end
end

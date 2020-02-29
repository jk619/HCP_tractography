clc
clear all


rois = {'LGN_lh_30.nii.gz';'LGN_rh_30.nii.gz'}
hemi = {'lh';'rh'}
FS_dir = '/Applications/freesurfer/subjects';
addpath(genpath('./vistasoft-master'))
addpath('./spm12');

%%

hemi = {'lh','rh'};
% hemi = hemi(2);
% rois_fs = {'ProS'} % for autorois
wmmask = 0; %takes the wm mask from freesurfer dir and transforms it into acpc space
dtiInitalize = 0 ;

track_roi = 1; %1

subjects = dir('./*')
list =regexp({subjects.name},'\d{6}','match');
mysubj = find(~cellfun(@isempty,list));
subjects = subjects(mysubj);

lmax_list = 10;
tic
%%
ct = 1
clear subjects
subjects.name = '102311';

for s = 1 : length(subjects)% 3 7 8 9 ran just before Jan left March2018
    
    subject = subjects(s).name;
    anat = sprintf('./%s/T1w/T1w_acpc_dc_restore_1.25.nii.gz',subject);
    anatFSmgz = sprintf('%s/%s/mri/brain.mgz',FS_dir,subject);
    anatFSnii = sprintf('%s/%s/mri/brain.nii.gz',FS_dir,subject);
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
    dwi_str = sprintf('./%s/Diffusion/data.nii.gz',subject);
    subjectfolder = sprintf('./%s/',subject);
    fibers_dir = sprintf('./%s/fibers/',subject);
%     rmdir(fibers_dir,'s')
%     mkdir(fibers_dir)

        
    %% Normalize HCP files to the VISTASOFT environment
%     b0_normalize    = 200;
%     bvals_normalize = 100;
%     bvals_val = dlmread(bvals);
%     
%     % Round the numbers to the closest thousand
%     % This is necessary because the VISTASOFT software does not handle the B0
%     % when they are not rounded.
%     [bvals_unique, ~, bvals_uindex] = unique(bvals_val);
%     bvals_unique(bvals_unique <= b0_normalize) = 0;
%     bvals_unique  = round(bvals_unique./bvals_normalize) ...
%         *bvals_normalize;
%     bvals_valnorm = bvals_unique( bvals_uindex );
%     dlmwrite(bvals,bvals_valnorm,'delimiter',' ');
%     
    
    
    
    %% dtiInit (creates dt6.mat and all necessary files; also makes it perfectly isotropic)
    
    if dtiInitalize
        
        if ~exist(sprintf('%s/dt6.mat',subjectfolder),'file')
            disp('5. Creating dt6.mat file');
            
            dwi = niftiRead(dwi_str);
            res = dwi.pixdim(1:3);
            dwParams = dtiInitParams;
            dwParams.clobber           =  1; %if 1 and processed already delete and rerun ; 0 not ovewrite
            dwParams.eddyCorrect       = -1; % if -1 only align dwi to T1 otherwise 1 = all correction 0 = motion correction
            dwParams.phaseEncodeDir    = 2;
            dwParams.rotateBvecsWithRx = 1; % allign bvecs to diffusion space
            dwParams.rotateBvecsWithCanXform = 1; % allign to bvecs to T1 space
            dwParams.bvecsFile  = bvecs; %paths to bvecs
            dwParams.bvalsFile  = bvals; %paths to bvals
            dwParams.dt6BaseName = subjectfolder; %folder name
            dwParams.outDir     = [dwParams.dt6BaseName] ; %path to outdir
            dwParams.dwOutMm    = [1.25 1.25 1.25]; % make sure its isotropic!
            
            % dtiInit(dwi, './t1/t1_acpc.nii.gz', dwParams)
            
            dtiInit(dwi_str, anat, dwParams)
        end
    end
    
    
    if wmmask
        
        system(sprintf('mri_convert %s/mri/wm.mgz %s/mri/white.nii.gz',subject_dir,subject_dir))
        white = niftiRead(sprintf('%s/mri/white.nii.gz',subject_dir));
        wm = find(white.data>0 & white.data<255);
        newwm = zeros(size(white.data));
        newwm(wm) = 1;
        white.data = newwm;
        wm_freesurfer_nii = sprintf('%s/wm_freesurfer.nii.gz',subject_dir);
        niftiWrite(white,wm_freesurfer_nii);
        wm_freesurfer_mif = sprintf('%s/wm_freesurfer.mif',subject_dir)
        system(sprintf('mrconvert %s %s',wm_freesurfer_nii,wm_freesurfer_mif))
        
    end
    
    wm_freesurfer_mif = sprintf('%swm_freesurfer.mif', subject_dir);
    %     system(sprintf('mkdir ./%s/Diffusion/Diffusion',subject))
    %         system(sprintf('mv ./%s/Diffusion/bin ./%s/Diffusion/Diffusion/bin',subject,subject))
    
    %% Rois
    for l = 1%: length(lmax_list)
        for h = 1 :length(hemi)
            
            hem = hemi{h};
            
            LGN = dir([roi4track sprintf('*LGN_%s*.nii.gz',hem)]);
            V1 =  dir([roi4track sprintf('*%s*clean*.nii.gz',hem)]);
            
            
            %% mrtrix tracking (https://github.com/francopestilli/life_scripts/blob/master/mrtrix_track_between_rois.m)
            
            if track_roi
                
                
                
                dtFile = fullfile(subjectfolder, '/dt6.mat');
                
                
                
                %         refImg = fullfile(subject_dir, '/t1/t1_acpc.nii');
                fibersFolder = fullfile(subject_dti_dir, '/fibers/');
                % Set upt the MRtrix trakign parameters
                trackingAlgorithm = {'prob'};
                lmax    = 10
                % The appropriate value depends on # of directions. For 32, use lower #'s like 4 or 6. For, 6 or 10 is good [10];
                %http://jdtournier.github.io/mrtrix-0.2/tractography/preprocess.html
                nSeeds  = 10000; % 10000; Total number of fibers that we want to get between 2 rois
                nFibers = 1000000; %1000000; %Maximum number of attempts to get above
                wmMaskName= sprintf('%swm_freesurfer',subject_dti_dir);
                
                files = mrtrix_init(dtFile,lmax,wmMaskName);
        
                
                
                
                %% Define the ROIs
                % We want to track the cortical pathway (LGN -> V1/V2 and V1/V2 -> MT)
                fromRois = [LGN.folder filesep LGN.name];
                
                for cortical_rois = 1 : length(V1)
                    toRois   = [V1(cortical_rois).folder filesep V1(cortical_rois).name];
                    
                    % Some of the following steps only need to be done once for each ROI,
                    % so we want to do some sort of unique operation on the from/toRois
                    
                    individualRois1 =  fromRois;
                    individualRois2 =  toRois; % put together all the pairs of ROIs
                    % put together all the pairs of ROIs
                    
                    % Convert the ROIs from .mat or .nii.gz to .mif format.
                    
                    
                  
                    [f,p] = fileparts(individualRois1);
                    roi_trk1 = [f '/' p(1:end-4) '.mif'];
                    delete(roi_trk1)
                    mrtrix_mrconvert(individualRois1,roi_trk1);
                    
                    
                    [f,p,e] = fileparts(individualRois2);
                    roi_trk2 = [f '/' p(1:end-4) '.mif'];
                    delete(roi_trk2)
                                        
                    mrtrix_mrconvert(individualRois2,roi_trk2);
                    
                    
                    %%
                    % Create joint from/to Rois to use as a mask
                    
                    % MRTRIX tracking between 2 ROIs template.
                    
                    roi1 = dtiRoiFromNifti(individualRois1,[],[],'.mat');
                    roi2 = dtiRoiFromNifti(individualRois2,[],[],'.mat');
                    delete(sprintf('%s_nonZero_MaskROI',individualRois2(1:end-7)))
                    % Make a union ROI to use as a seed mask:
                    % We will generate as many seeds as requested but only inside the voume
                    % defined by the Union ROI.
                    %
                    % The union ROI is used as seed, fibers will be generated starting ONLy
                    % within this union ROI.
                    
                    floor1 = strfind(roi1.name,'_');
                    floor2 = strfind(roi2.name,'_');
                    
                    roi1.name = roi1.name(1:floor1(2)-1);
                    roi2.name = roi2.name(1:floor2(2)-1);
                    
                    
                    roi1data = load_nifti(individualRois1);
                    roi2data = load_nifti(individualRois2);
                    
                    mkdir(sprintf('%s%s-%s',fibers_dir,roi1.name,roi2.name))
                    temp_dir = sprintf('%s%s-%s/',fibers_dir,roi1.name,roi2.name);
                    roiUnion        = roi1data; % seed union roi with roi1 info
                    roiUnion.name   = ['union of ' roi1.name ' and ' roi2.name]; % r lgn calcarine';
                    roiUnion.vol = roiUnion.vol + roi2data.vol;
                    roiName         = fullfile(temp_dir,[roi1.name '-' roi2.name '_union']);
                    save_nifti(roiUnion,[roiName '.nii.gz']);
                    
                    seedRoiNiftiName= sprintf('%s.nii.gz',roiName);
                    seedRoiMifName  = sprintf('%s.mif',roiName);
                    
                    % Transform the niftis into .mif
                    mrtrix_mrconvert(seedRoiNiftiName, seedRoiMifName);
                    
                    % We cd into the folder where we want to sae the fibers.
                    
                    %% tractography
                    curv = [0.25 0.5 1 2 4];
                   for x = 1:length(curv)
                        %We geenrate and save the fibers in the current folder.
                        cmd{ct} = mrtrix_track_roi2roi_ensamble_par(files, roi_trk1, roi_trk2, ...
                            seedRoiMifName, wm_freesurfer_mif, trackingAlgorithm{1}, ...
                            nSeeds, nFibers,[],[],num2str(curv(x)),temp_dir);
                        ct = ct+1;
                   end
                    
                end
                
            end
        end
    end
end
%%
parfor p = 1 : length(cmd)
    
    system(cmd{p})
    
end
toc
% cd '/home/fmridti/Documents/DTI'
% do2_life_and_plot_ensamble_takemura_hcp_life_on_all
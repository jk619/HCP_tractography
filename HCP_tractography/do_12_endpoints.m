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
setenv('SUBJECTS_DIR',fullfile('./subjects/'))

freesurfer_init
cmap =[[14 200 200];[255 140 0];[20 158 29]]
cmap = [[50 220 254];[253 255 6];[11 102 35]]
cmap = [[64 219 253];[251 251 56];[47 213 102]]

trans = 0
%%
ct = 1

temp_file_lh = './ventral_dorsal_pros/lh.Glasser2016.nii.gz';
temp_file_rh = './ventral_dorsal_pros/rh.Glasser2016.nii.gz';

dors_lh = load_nifti(temp_file_lh);
vent_lh = load_nifti(temp_file_lh);
dors_rh = load_nifti(temp_file_rh);
vent_rh = load_nifti(temp_file_rh);
ct = 1
transform = 0
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
    
    
    
    
    %%
    
    for h = 1  : length(hemi)
        fib = dir([subject_dir_life sprintf('*%s*vol*.mat',hemi{h})]);
        for p = 1 : length(pos)
            if transform == 1
                
                fib = sprintf('%s/LGN_%s-%s.Pros_vol_%s.tck',subject_dir_life,hemi{h},hemi{h},pos{p});
                
                
                fname = sprintf('%s/LGN_%s-%s.Pros_vol_%s_end.nii.gz',subject_dir_life,hemi{h},hemi{h},pos{p});                    %                 dtiFiberendpointNifti(fib, t1File, fname);
                outsurf = sprintf('%s/LGN_%s-%s.Pros_vol_%s_end_surf.nii.gz',subject_dir_life,hemi{h},hemi{h},pos{p});                    %                 dtiFiberendpointNifti(fib, t1File, fname);
                
                dtiFiberendpointNifti(fib, anat, fname);
                
                system(sprintf('%smri_vol2surf --src %s --hemi %s --regheader %s --out %s --surf white --fwhm 3',freesurfer_string,fname,hemi{h},subjects(s).name,outsurf))
                fsavgsurf = sprintf('%s/%s_LGN_%s-%s.Pros_vol_%s_end_surf_fs.nii.gz','./average_maps/endpoints/',subjects(s).name,hemi{h},hemi{h},pos{p});
                
                system(sprintf('%smri_surf2surf --srcsubject %s --trgsubject fsaverage --hemi %s --srcsurfval %s --trgsurfval %s',freesurfer_string,subjects(s).name,hemi{h},outsurf,fsavgsurf))
            else
                fsavgsurf = sprintf('%s/%s_LGN_%s-%s.Pros_vol_%s_end_surf_fs.nii.gz','./average_maps/endpoints/',subjects(s).name,hemi{h},hemi{h},pos{p});
                
            end
            
            
            
            tmp = load_nifti(fsavgsurf);
            
            if h == 1
                %
                if p == 1
                    dors_lh.vol(:,ct) = tmp.vol;
                    
                elseif p==2
                    
                    vent_lh.vol(:,ct) = tmp.vol.*-1;
                end
                
            elseif h ==2
                
                if p == 1
                    dors_rh.vol(:,ct) = tmp.vol;
                    
                elseif p==2
                    
                    vent_rh.vol(:,ct) = tmp.vol.*-1;
                end
                %
                %         end
            end
            
        end
        
    end
    ct = ct + 1;
    
    
end



for h  = 1 : length(hemi)
    
    if h  == 1
        
        sz =size(dors_lh.vol);

    elseif h == 2
        
        sz =size(dors_rh.vol);

    end
    roi_dors = [];
    path2roi = sprintf('%s.Prost_dors',hemi{h})
    l = read_label('fsaverage',path2roi);
    pros_dors = zeros([sz(1) 1]);
    roi_dors = [roi_dors; l(:,1) + 1];
    pros_dors(roi_dors) = 1;
    

    roi_vent = [];
    path2roi = sprintf('%s.Prost_vent',hemi{h})
    l = read_label('fsaverage',path2roi);
    pros_vent = zeros([sz(1) 1]);
    roi_vent = [roi_vent; l(:,1) + 1];
    pros_vent(roi_vent) = -1;
    
    roi = [];
    path2roi = sprintf('%s.%s_ProS_ROI',hemi{h},upper(hemi{h}(1)));
    l = read_label('fsaverage',path2roi);
    roi = [roi; l(:,1) + 1];
    
    pros = zeros([sz(1) 1]);
    pros(roi) = 1;
    
    
    if h  ==  1
      
        
        
        dors_avg = mean(dors_lh.vol,2).*pros;
        vent_avg = mean(vent_lh.vol,2).*pros;
        
        dors_avg(dors_avg==0) = NaN;
        vent_avg(vent_avg==0) = NaN;
        
        dors_lh.vol = dors_avg;
        vent_lh.vol = vent_avg;
        
        
        save_nifti(dors_lh,sprintf('./average_maps/%s.endpoints_dors.nii.gz',hemi{h}))
        save_nifti(vent_lh,sprintf('./average_maps/%s.endpoints_vent.nii.gz',hemi{h}))
        dors_lh.vol = dors_avg+vent_avg;
        save_nifti(dors_lh,sprintf('./average_maps/%s.both.nii.gz',hemi{h}))
        
        dors_lh.vol = pros_dors+pros_vent;
        save_nifti(dors_lh,sprintf('./average_maps/%s.rois.nii.gz',hemi{h}))

        
        
    elseif h == 2
        
        
        roi = [];
        path2roi = sprintf('%s.%s_ProS_ROI',hemi{h},upper(hemi{h}(1)));
        l = read_label('fsaverage',path2roi);
        roi = [roi; l(:,1) + 1];
        
        pros = zeros([sz(1) 1]);
        pros(roi) = 1;
        
        
        dors_avg = mean(dors_rh.vol,2).*pros;
        vent_avg = mean(vent_rh.vol,2).*pros;
        
        dors_avg(dors_avg==0) = NaN;
        vent_avg(vent_avg==0) = NaN;
        
        dors_rh.vol = dors_avg;
        vent_rh.vol = vent_avg;
        
        
        save_nifti(dors_rh,sprintf('./average_maps/%s.endpoints_dors.nii.gz',hemi{h}))
        save_nifti(vent_rh,sprintf('./average_maps/%s.endpoints_vent.nii.gz',hemi{h}))
        dors_rh.vol = dors_avg+vent_avg;
        save_nifti(dors_rh,sprintf('./average_maps/%s.both.nii.gz',hemi{h}))
        
        dors_lh.vol = pros_dors+pros_vent;
        save_nifti(dors_lh,sprintf('./average_maps/%s.rois.nii.gz',hemi{h}))

    end
end




%         %%
%         if combine
%             roi = [];
%             for he = 1 : length(hemi)
%
%
%                 fname =  load_nifti(sprintf('%s/%s/%s/%s_%s_surf.nii.gz',config.subject_dir_life,roipairs{6},subjects{s},subjects{s},hemi{he}))
%                 fname2 = load_nifti(sprintf('%s/%s/%s/%s_%s_surf.nii.gz',config.subject_dir_life,roipairs{7},subjects{s},subjects{s},hemi{he}))
%
%                 path2roi = sprintf('%s.ProS.hcp',hemi{he});
%                 l = read_label(subjects{s},path2roi);
%                 roi = [roi; l(:,1) + 1];
%
%                 fname.vol = fname.vol + (fname2.vol*-1);
%                 mask = zeros(size(fname.vol));
%                 mask(roi) = 1;
%
%                 fname.vol = fname.vol .* mask;
%
%                 mkdir(sprintf('%s/%s/%s/',config.subject_dir_life,'combo',subjects{s}))
%                 save_nifti(fname,sprintf('%s/%s/%s/combined_%s.nii.gz',config.subject_dir_life,'combo',subjects{s},hemi{he}));
%                 system(sprintf('tksurfer %s %s inflated -overlay %s/%s/%s/combined_%s.nii.gz -fminmax 0.0001 0.005',subjects{s},hemi{he},config.subject_dir_life,'combo',subjects{s},hemi{he}))
%             end
%
%
%         end
%
%
%
% if combine_fsavg
%
%
%     adding_lh_vent = [];
%     adding_rh_vent = [];
%     adding_lh_OR = [];
%     adding_rh_OR = [];
%     load('myvent')
%     load('myOR')
%
%     temp = load_nifti(myvent{1,1})
%     %         template = zeros(size(temp.vol));
%
%     for x = 1 : length(myvent)
%
%         for he = 1 : length(hemi)
%
%             vent = load_nifti(myvent{x,he})
%             OR = load_nifti(myOR{x,he})
%
%
%             if he == 1
%
%                 adding_lh_vent = cat(2,adding_lh_vent,vent.vol);
%                 adding_lh_OR = cat(2,adding_lh_OR,OR.vol);
%
%
%             elseif he == 2
%                 adding_rh_vent = cat(2,adding_rh_vent,vent.vol);
%                 adding_rh_OR = cat(2,adding_rh_OR,OR.vol);
%
%
%             end
%         end
%     end
% end
%
% if 0
% mean_lh_vent = mean(adding_lh_vent,2);
% mean_rh_vent = mean(adding_rh_vent,2);
% mean_lh_OR = mean(adding_lh_OR,2);
% mean_rh_OR = mean(adding_rh_OR,2);
%
%
% lh = mean_lh_vent + (mean_lh_OR*-1);
% rh = mean_rh_vent + (mean_rh_OR*-1);
%
%
% temp.vol = lh;
%
% roi = [];
% path2roi = sprintf('lh.ProS');
% l = read_label('fsaverage',path2roi);
% roi = [roi; l(:,1) + 1];
%
% mask = zeros(size(temp.vol));
% mask(roi) = 1;
%
% temp.vol = temp.vol .* mask;
%
% save_nifti(temp,'/Volumes/Maxtor/DTI/mrTrix/mrTrix_Koulla/Figures/mrdiffusion_clean/combo/fsaverage/lh.nii.gz')
%
%
% temp.vol = rh;
% roi = [];
% path2roi = sprintf('rh.ProS');
% l = read_label('fsaverage',path2roi);
% roi = [roi; l(:,1) + 1];
%
% mask = zeros(size(temp.vol));
% mask(roi) = 1;
%
% temp.vol = temp.vol .* mask;
%
% save_nifti(temp,'/Volumes/Maxtor/DTI/mrTrix/mrTrix_Koulla/Figures/mrdiffusion_clean/combo/fsaverage/rh.nii.gz')
% end
%
% %     system(sprintf('tksurfer %s %s inflated -overlay %s/%s/%s/combined_%s.nii.gz -fminmax 0.0001 0.005 &',subjects{s},hemi{he},config.subject_dir_life,'combo',subjects{s},hemi{he}))
%
%
% %% combine tracks
%
%
% %         w  = feGet(fe,'fiber weights');

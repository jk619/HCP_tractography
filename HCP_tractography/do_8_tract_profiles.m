clc
clear all
close all

subjects = dir('./*')
list =regexp({subjects.name},'\d{6}','match');
mysubj = find(~cellfun(@isempty,list));
subjects = subjects(mysubj);

addpath(genpath('./vistasoft-master'))
addpath(genpath('./encode-0.45'))
Niter = 500
setenv('LD_LIBRARY_PATH','');
pos  = {'dors';'vent';''}
hemi = {'lh';'rh'}


cmap =[[14 200 200];[255 140 0];[20 158 29]]
cmap = [[50 220 254];[253 255 6];[11 102 35]]
cmap = [[64 219 253];[251 251 56];[47 213 102]]

trans = 0
%%
ct = 1

% if ~exist('fa_trace.mat','file') == 2
    
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
        
        
        
        dt6path = sprintf('%sdt6.mat',subjectfolder)
        dt = dtiLoadDt6(dt6path);
        
        
        for h = 1  : length(hemi)
            fib = dir([subject_dir_life sprintf('*%s*vol*.mat',hemi{h})]);
            for p = 1 : length(pos)
                
                if p == 3
                    roi = load(sprintf('%s/roi4track/%s.Pros_vol_1.25_clean_nonZero_MaskROI.mat',subjectfolder,hemi{h}))
                else
                    roi = load(sprintf('%s/labels_MSM/%s.%s.Pros_%s_125_nonZero_MaskROI.mat',subject_dir,hemi{h},upper(hemi{h}(1)),pos{p}));
                end
                tck = fgRead(sprintf('%s/LGN_%s-%s.Pros_vol.tck',subject_dir_life,hemi{h},hemi{h}))
                [fgOut,contentiousFibers, keep] =   dtiIntersectFibersWithRoi([], {'and'}, 1, roi.roi, tck);
                
                [fa md rd ad] = AFQ_ComputeTractProperties(fgOut, dt, 100,0);
                
                fa_trace{p,ct} = fa
                md_trace{p,ct} = md
                rd_trace{p,ct} = rd
                
            end
            ct = ct + 1
            
        end
    end
    %%
    
%     save('fa_trace','fa_trace')
%     save('md_trace','md_trace')
%     save('rd_trace','rd_trace')
    
% else
%     
%     load('fa_trace')
%     load('md_trace')
%     load('rd_trace')
end

dors = zeros(100,length(fa_trace));
vent = zeros(100,length(fa_trace));
all = zeros(100,length(fa_trace));

metric = {'FA';'MD';'RD'}
ylimits = [[0.4 0.60];[0.35 0.45];[0.25 0.35]];
for m = 1 : length(metric)
    clear dors vent all
    
    for f = 1 : length(fa_trace)
        %
        if m == 1
            
            dors(:,f) =  fa_trace{1,f};
            vent(:,f) =  fa_trace{2,f};
            all(:,f) =  fa_trace{3,f};
            
        elseif m == 2
            
            dors(:,f) =  md_trace{1,f};
            vent(:,f) =  md_trace{2,f};
            all(:,f) =  md_trace{3,f};
            
        elseif m == 3
            
            
            dors(:,f) =  rd_trace{1,f};
            vent(:,f) =  rd_trace{2,f};
            all(:,f) =  rd_trace{3,f};
        end
        
    end
    
    dors = dors';
    vent = vent';
    all = all';
    
    figure(1)
    
    s=subplot(3,1,m)
    hold on
    a = shadedErrorBar(1:100,mean(vent,1),std(vent,1)/sqrt(size(vent,1)),'lineprops',{'-','color',round([cmap(1,:)]/255,3),'MarkerFaceColor',round([cmap(1,:)]/255,3)},'transparent',trans);
    set(a.edge,'Color',[1 1 1])
    set(a.patch,'FaceColor',round([cmap(1,:)]/255,3))
    
    xticks([])
    set(a.mainLine,'Color',round([0 91 187]/255,3))
    % title('mean FA along the track')
    ylabel(metric{m},'FontName','Helvetica','FontAngle','Italic')
    % plot(bigfa','-','color',round([14 200 200 100]/255,3));
    
    % xlabel('Resampled length of the track')
    hold on
%     ylim([0.4 0.6])
    set(s,'Color',[0 0 0],'XColor',[1 1 1],...
        'YColor',[1 1 1],'ZColor',[1 1 1],'FontSize',20);
    
    s=subplot(3,1,m)
    hold on
    b = shadedErrorBar(1:100,mean(dors,1),std(dors,1)/sqrt(size(dors,1)),'lineprops',{'-','color',round([cmap(2,:)]/255,3),'MarkerFaceColor',round([cmap(2,:)]/255,3)},'transparent',trans);
    set(b.edge,'Color',[1 1 1])
    xticks([])
    set(b.mainLine,'Color',round([253 106 2]/255,3))
    set(b.patch,'FaceColor',round([cmap(2,:)]/255,3))
    
    % title('mean FA along the track')
    ylabel(metric{m},'FontName','Helvetica','FontAngle','Italic')
    % xlabel('Resampled length of the track')
    
    % plot(bigfa','-','color',round([255 140 0 100]/255,3));
    
%     ylim([0.4 0.6])
     set(s,'Color',[0 0 0],'XColor',[1 1 1],...
        'YColor',[1 1 1],'ZColor',[1 1 1],'FontSize',20);
    
    
    sss=subplot(3,1,m)
    x=shadedErrorBar(1:100,mean(all,1),std(all,1)/sqrt(size(all,1)),'lineprops',{'-','color',round([cmap(3,:)]/255,3),'MarkerFaceColor',round([cmap(3,:)]/255,3)},'transparent',trans);
    set(x.edge,'Color',[1 1 1])
    set(x.mainLine,'Color',round([11 102 35]/255,3))
    set(x.patch,'FaceColor',round([cmap(3,:)]/255,3))
    
    fig = gcf;
    % set(fig.CurrentAxes,'YColor',[1 1 1])
    % set(fig.CurrentAxes,'XColor',[1 1 1])
    % set(fig.CurrentAxes,'ZColor',[1 1 1])
    % set(fig,'Color','None')
    
    xticks([])
    
    % title('mean FA along the track')
    ylabel(metric{m},'FontName','Helvetica','FontAngle','Italic')
    % xlabel('Resampled length of the track')
    % plot(bigfa','-','color',round([20 158 29]/255,3));
    hold on
%     ylim([0.4 0.6])
%     yticks([0.35 0.45 0.55])
     set(s,'Color',[0 0 0],'XColor',[1 1 1],...
        'YColor',[1 1 1],'ZColor',[1 1 1],'FontSize',20);
    
    ylim([ylimits(m,1),ylimits(m,2)])
end
xticks([25 75])
set(gcf,'position',[ 585   175   371   712])
set(gcf, 'InvertHardCopy', 'off');
eval(sprintf('export_fig -r 300 -transparent ./plots/tck_prof.png'))
% set(gcf, 'Color', [1 1 1])

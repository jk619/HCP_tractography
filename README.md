# HCP_tractography


This pipeline uses several different packages (mrtrix2, mrtrix3, Afni, spm, vistasoft, HCP workbench) to perform ensemble tractography between a set of ROIS. Tracts are validated with LiFE and group averages are created
http://francopestilli.github.io/life/

Data is downloaded with amazon aws directly from HCP bucket see the link below for setting up
https://wiki.humanconnectome.org/display/PublicData/How+To+Connect+to+Connectome+Data+via+AWS

Subcortical ROIs are mapped from fsl atlases with pre-computed MNI registration files, cortical ROIs are mapped with MSM-all approach (all registration files are also avialable on HCP)

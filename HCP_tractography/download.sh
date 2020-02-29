
subjectlist=subj.txt


while read -r subject;

do

	echo "fuck"
	echo $subject
    mkdir  ./$subject
    mkdir  ./$subject/Native/
    mkdir  ./$subject/Diffusion/
    mkdir  ./$subject/xfms/
    mkdir  ./$subject/T1w/
    mkdir  ./subjects


    
    aws s3 cp s3://hcp-openaccess/HCP_1200/$subject/MNINonLinear/Native ./$subject/Native/ --recursive
    aws s3 cp s3://hcp-openaccess/HCP_1200/$subject/MNINonLinear/$subject.L.sphere.164k_fs_LR.surf.gii ./$subject/Native/ 
    aws s3 cp s3://hcp-openaccess/HCP_1200/$subject/MNINonLinear/$subject.R.sphere.164k_fs_LR.surf.gii ./$subject/Native/ 
    aws s3 cp s3://hcp-openaccess/HCP/$subject/T1w/$subject ./subjects/$subject/ --recursive
    aws s3 cp s3://hcp-openaccess/HCP/$subject/T1w/Diffusion ./$subject/Diffusion/ --recursive
    aws s3 cp s3://hcp-openaccess/HCP/$subject/MNINonLinear/xfms ./$subject/xfms/ --recursive
    aws s3 cp s3://hcp-openaccess/HCP/$subject/T1w/ ./$subject/T1w/ --recursive  --exclude "$subject/*" --exclude "Diffusion/*" --exclude "Native/*"




done < $subjectlist

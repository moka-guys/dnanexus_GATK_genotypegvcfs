#!/bin/bash

# -e = exit on error; -x = output each line that is executed to log; -o pipefail = throw an error if there's an error in pipeline
set -e -x -o pipefail

function docker_path(){
	# Replace the home directory in a given string with the docker directory path. 
	# Allows use of dx_helper variable syntax in mounted docker containers.
	input_string=$1
	echo $input_string | sed -e "s,$home_dir,$docker_dir,g"
}

# Set variables and functions for dx-docker
home_dir=/home/dnanexus
docker_dir=/gatk/sandbox

# Download input data
dx-download-all-inputs

# Move reference genome inputs to the same directory
mv ${reference_fasta_index_path} ${reference_fasta_dict_path} $(dirname $reference_fasta_path)
# Move VCF files and their indexes to the home directory
mv ${input_gvcfs_path[@]} ${input_gvcfs_index_path[@]} $HOME

# Set helper variables for docker container
docker_reference_fasta_path=$(docker_path $reference_fasta_path)
#docker_input_gvcf_path=$(docker_path $HOME)
docker_intervals_list_path=$(docker_path $intervals_list_path)
docker_output_prefix="RUNFOLDER.combined"
input_gvcfs=$(ls ${HOME}/*.g.vcf)
docker_input_gvcfs=$(docker_path ${input_gvcfs[@]})

# Set number of cores available
CORES=$(nproc)

# Pull GATK docker to workstation
dx-docker pull broadinstitute/gatk:4.0.9.0

# Call GenomicsDBImport
dx-docker run -v /home/dnanexus/:${docker_dir} broadinstitute/gatk:4.0.9.0 gatk GenomicsDBImport \
  --genomicsdb-workspace-path gendb -V ${docker_dir}/*.g.vcf --L ${docker_intervals_list_path} \
  --reader-threads ${CORES}

# Call Genotype GVCF
dx-docker run -v /home/dnanexus/:${docker_dir} broadinstitute/gatk:4.0.9.0 gatk GenotypeGVCFs \
  -R ${docker_reference_fasta_path} -V sandbox/gendb://gendb -G StandardAnnotation -O ${docker_dir}/${docker_output_prefix}.vcf

# Create output directories and move respective files
combined_vcf_out="out/combined_vcf"
combined_vcf_index_out="out/combined_vcf_index"
mkdir -p ${combined_vcf_out} && mv ${docker_output_prefix}.vcf ${combined_vcf_out}
mkdir -p ${combined__vcf_index_out} && mv ${docker_output_prefix}.vcf.idx ${combined_vcf_index_out}

# Upload output data 
dx-upload-all-outputs

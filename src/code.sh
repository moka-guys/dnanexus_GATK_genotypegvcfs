#!/bin/bash

# -e = exit on error; -x = output each line that is executed to log; -o pipefail = throw an error if there's an error in pipeline
set -e -x -o pipefail

# Download input data
dx-download-all-inputs

# Pull GATK docker to workstation
dx-docker pull broadinstitute/gatk:4.0.9.0

# Move all inputs to the home directory
mv ${input_gvcfs_path[@]} ${input_gvcfs_index_path[@]} ${reference_fasta_path} \
  ${reference_fasta_index_path} ${reference_fasta_dict_path} ${intervals_list_path} ${HOME}

# Set command for GenomicsDBImport input GVCFs. Example:
#     "-V sample1.g.vcf -V sample2.g.vcf -V sample3.g.vcf"
for gvcf in $(ls *.g.vcf); do
	docker_input_gvcfs="${docker_input_gvcfs} -V ${docker_dir}/${gvcf}"
# Set number of cores available for multi-threading
CORES=$(nproc)

# Set output VCF prefix based on user app input
if [ "${output_vcf_prefix}" = "merge" ]; then
    output_vcf_name="$(python -c 'import sys;print("_".join(sys.argv[1:]))' "${input_gvcfs_prefix[@]}")_combined.vcf"
else
    output_vcf_name="${output_vcf_prefix}.vcf"
fi

# Call GenomicsDBImport
dx-docker run -v /home/dnanexus:/gatk/sandbox broadinstitute/gatk:4.0.9.0 gatk GenomicsDBImport \
  --genomicsdb-workspace-path /gatk/sandbox/gendb ${docker_input} --L /gatk/sandbox/${intervals_list_name} \
  --reader-threads ${CORES}

# Call GenotypeGVCFs
dx-docker run -v /home/dnanexus/:${docker_dir} broadinstitute/gatk:4.0.9.0 gatk GenotypeGVCFs \
  -R /gatk/sandbox/${reference_fasta_name} -V gendb://sandbox/gendb -G StandardAnnotation -O /gatk/sanbox/${output_vcf_name}

# Create output directories and move respective files for upload
mkdir -p ${HOME}/out/combined_vcf && mv ${output_vcf_name} ${HOME}/out/combined_vcf
mkdir -p ${HOME}/out/combined_vcf_index && mv ${output_vcf_name}.idx ${HOME}/out/combined_vcf_index

# Upload output data 
dx-upload-all-outputs

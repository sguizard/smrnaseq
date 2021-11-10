// Import generic module functions
include { saveFiles; getSoftwareName; getProcessName } from './functions'

params.options = [:]

process MIRTOP_QUANT {
    label 'process_medium'

    publishDir "${params.outdir}",
        mode: params.publish_dir_mode,
        saveAs: { filename -> saveFiles(filename:filename, options:params.options, publish_dir:".", meta:[:], publish_by_meta:[]) }

    conda (params.enable_conda ? 'bioconda::mirtop=0.4.23 bioconda::samtools=1.13 conda-base::r-base=4.0.3' : null)
    if (workflow.containerEngine == 'singularity' && !params.singularity_pull_docker_container) {
        container "https://depot.galaxyproject.org/singularity/mulled-v2-1f73c7bc18ac86871db9ef0a657fb39d6cbe1cf5:dd7c9649e165d535c1dd2c162ec900e7206398ec-0"
    } else {
        container "quay.io/biocontainers/mulled-v2-1f73c7bc18ac86871db9ef0a657fb39d6cbe1cf5:dd7c9649e165d535c1dd2c162ec900e7206398ec-0"
    }

    input:
    path ("bams/*")
    path hairpin
    path gtf

    output:
    path "mirtop/mirtop.gff"
    path "mirtop/mirtop.tsv"        , emit: mirtop_table
    path "mirtop/mirtop_rawData.tsv"
    path "mirtop/stats/*"           , emit: logs
    path "versions.yml"             , emit: versions

    script:
    """
    mirtop gff --hairpin $hairpin --gtf $gtf -o mirtop --sps $params.mirtrace_species ./bams/*
    mirtop counts --hairpin $hairpin --gtf $gtf -o mirtop --sps $params.mirtrace_species --add-extra --gff mirtop/mirtop.gff
    mirtop export --format isomir --hairpin $hairpin --gtf $gtf --sps $params.mirtrace_species -o mirtop mirtop/mirtop.gff
    mirtop stats mirtop/mirtop.gff --out mirtop/stats
    mv mirtop/stats/mirtop_stats.log mirtop/stats/full_mirtop_stats.log

    cat <<-END_VERSIONS > versions.yml
    ${getProcessName(task.process)}:
        ${getSoftwareName(task.process)}: \$(echo \$(mirtop --version 2>&1) | sed 's/^.*mirtop //')
    END_VERSIONS
    """

}

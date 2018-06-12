snakemake -s Snakefile  -c "qsub {params.sge_opts}"  -j 100  -w 30 

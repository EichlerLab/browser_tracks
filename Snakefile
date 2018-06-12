import os

configfile: "config.json"
pathToInp = config["manifestpath"]  
RPKMS  = open(config["manifestnames"]).read().strip().split('\n')

BOX = ['low','high','norm']
localrules: makebed

def createFullPath (wildcards):
	fullPath = "manifest/{holder}".format(holder=wildcards.rpkm)
	return fullPath

def onlyFilename (wildcards):
	filename  = "{newholder}".format(newholder=wildcards.rpkm)
        return filename


rule all:
	input : expand("bwfiles/{rpkm}.{box}.bw", rpkm=RPKMS, box=BOX)	

rule makenormbigwig:
	input: bedf="bedfiles/{rpkm}.norm", chrInf=config["chromInfo"]
        output : "bwfiles/{rpkm}.norm.bw"
        params: sge_opts = config["cluster_settings"]["lite"]
        shell : "bedGraphToBigWig {input.bedf} {input.chrInf} {output}"

rule makehighbigwig:
	input : bedf="bedfiles/{rpkm}.high", chrInf=config["chromInfo"]
        output : "bwfiles/{rpkm}.high.bw"
	params: sge_opts = config["cluster_settings"]["lite"]
        shell : "bedGraphToBigWig {input.bedf} {input.chrInf} {output}"
       

rule makelowbigwig:
	input : bedf="bedfiles/{rpkm}.low", chrInf=config["chromInfo"]
	output : "bwfiles/{rpkm}.low.bw"
	params: sge_opts = config["cluster_settings"]["lite"]
	shell : "bedGraphToBigWig {input.bedf} {input.chrInf} {output}"
        

rule makebed: 
	#input : "{rpkm}.makebeds.run"
	input: "{rpkm}.makebeds.run"
	output : "bedfiles/{rpkm}.high", "bedfiles/{rpkm}.low", "bedfiles/{rpkm}.norm"
	shell : "mkdir -p bedfiles; sh {input}"
	

rule prepbed:
	input : "stdDev/{rpkm}.limit", fulpat=createFullPath
	output : temp("{rpkm}.makebeds.run")
	params: sge_opts = config["cluster_settings"]["lite"]
	shell : """
	cat {input[0]} |  awk '{{ print  "  if ( $4 >= " $2 ")  print $1,$2,$3,$4  \\t  {input[1]}  | tr \\" \\" \\"\\t\\"  > bedfiles/" $1".high" }}'  | sed "s/^/awk \'{{/g" | sed "s/ \t/}}'/g" > {output}

	cat {input[0]} |  awk '{{ print  "  if ( $4 <= -" $2 ")  print $1,$2,$3,$4  \\t {input[1]} | tr \\" \\" \\"\\t\\"  > bedfiles/" $1".low" }}'  | sed "s/^/awk \'{{/g" | sed "s/ \t/}}'/g" >> {output} ;
	
	cat {input[0]} |  awk '{{ print  "  if ( $4 > -" $2 " && $4 < " $2 " )  print $1,$2,$3,$4  \\t {input[1]} | tr \\" \\" \\"\\t\\"  > bedfiles/" $1".norm" }}'  | sed "s/^/awk \'{{/g" | sed "s/ \t/}}'/g" >> {output} ;

	"""

rule stdDev:
	message: "[INFO] calculating stddev"
	input: inp=createFullPath
	output: "stdDev/{rpkm}.limit"
	params: sge_opts = config["cluster_settings"]["lite"]
	shell : """
	echo  "{input.inp}" | awk -F'/' '{{print $NF}}' | tr -d '\n' > {output} ;  cut -f4 {input.inp} | statStd.pl |  grep "Standard" | awk '{{ print $3*1.50 }}' | sed 's/^/\t/g'  >>  {output}

"""


	 


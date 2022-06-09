import shutil
import pandas as pd
import pathlib

def read_lst(path):
    with open(path) as f:
        lines =  [l.strip("\n") for l in f.readlines() if l.strip()]
    return lines

def write_lst(data, path):
    with open(path, "w") as f:
        f.write("\n".join(data))

def extract_ids(input, output):
    wb = pd.read_excel(input[0])
    negative_rows = wb.loc[
        wb["Bemerkung"].str.contains("negativ", case=False, na=False)
        &
        wb["Panel / Segregation"].str.contains("exom", case=False, na=False)
    ]
    lbids = negative_rows["Proben-Nummer"].tolist()
    write_lst(lbids, output[0])


rule all:
    input:
        "data/vcf_paths_echtvar.lst"


rule extract_ids:
    input:
        "/mnt/smb01-hum/HGDiag/Befunde/BoneMass-Skelett/Übersicht_Fälle_KnochenerkrankungenGesamt.xlsx"
    output:
        "data/unsolved_ids.lst"
    run:
        extract_ids(input, output)

rule vcf_paths:
    input:
        ids="data/unsolved_ids.lst",
        vcf_paths="static/ngs_paths.lst"
    output:
        "data/vcf_paths.lst"
    run:
        lbIds = read_lst(input.ids)
        # build list of all vcf folders
        vcfPaths = [
            l for p in map(pathlib.Path, read_lst(input.vcf_paths)) for l in p.iterdir() if l.is_dir()
        ]
        failed_items = 0
        failed_lbids = []
        vcf_paths = []
        for lbid in lbIds:
            found_dirs = [p for p in vcfPaths if lbid in p.name]
            if len(found_dirs) >= 1:
                found_vcfs = [
                    f
                    for p in found_dirs
                    for f in p.glob("**/*.vcf.gz")
                ]
                candidate = sorted(found_vcfs, key=lambda p: len(p.name))[0]
                print(candidate)
                vcf_paths.append(str(candidate))
                # found_dir = sorted(found_dirs, key=lambda l: len(l.name))[0]
                # print(found_dirs, "are ambiguous. Using", found_dir)
            else:
                failed_items += 1
                failed_lbids.append(lbid)
        with open(output[0]+".log", "w") as f:
            f.write(f"failed: {failed_items}\nids: {failed_lbids}\n")
        write_lst(vcf_paths, output[0])

rule vcf_tmp:
    input:
        "data/vcf_paths.lst"
    output:
        "data/vcf_paths_tmp.lst"
    run:
        new_paths = []
        for p in read_lst(input[0]):
            pnew = pathlib.Path("tmp") / pathlib.Path(p).name
            if not pnew.exists():
                shutil.copy(p, str(pnew))
            new_paths.append(str(pnew))
        write_lst(new_paths, output[0])

rule vcf_to_bcf:
    input:
        "data/vcf_paths_tmp.lst"
    output:
        "data/vcf_paths_tmp_bcf.lst"
    shell:
        """
        for f in $(cat {input}); do
        destname=${{f%.vcf.gz}}.bcf.gz
        if [[ ( $f == *.gt.vcf.gz ) && (! -e $destname) ]]; then
            echo $f
            zcat $f \
                | sed -e 's/ID=AD,Number=\./ID=AD,Number=R/' \
                | bcftools norm -m - -w 10000 -f HUM/bwa_index/hs37d5.fa -O b -o $destname
            echo $destname >> {output}
        fi
        done
        """

rule filter_echtvar:
    input:
        "data/vcf_paths_tmp_bcf.lst"
    params:
        outdir="tmp/filtered"
    output:
        "data/vcf_paths_echtvar.lst"
    shell:
        """
        for f in $(cat {input}); do
            echo $f
            fname=$(basename $f)
            fname=${{fname%.vcf.gz.bcf.gz}}.bcf.gz
            mkdir -p {params.outdir}
            destname={params.outdir}/$fname
            if [[ ! -e $destname ]]; then
                echo $destname
                echtvar anno -e gnomad.v2.echtvar.zip -i 'gnomad_popmax_af < 0.01' $f $destname
                echo $destname >> {output}
            fi
        done
        """

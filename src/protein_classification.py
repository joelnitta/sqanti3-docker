#!/usr/bin/env python3
import pandas as pd 
import argparse

def classify_protein_splice_fsm(row):
    if row.pr_cat=='full-splice_match' and row.pr_subcat=='multi-exon':
        if row.pr_nterm_diff==0 and row.pr_cterm_diff==0:
            return 'pFSM,,,'
        elif (row.pr_nterm_diff!=0 or row.pr_cterm_diff!=0) and row.pr_nterm_gene_diff==0 and row.pr_cterm_gene_diff==0:
            return 'pNIC,combo_nterm_cterm,,is alt nterm or cterm?'
        elif row.tx_cat=='incomplete-splice_match' and row.pr_ntermhang<0 and row.pr_ctermhang==0:
            return 'pISM,cand_ntrunc,,assume nterm novel'
        elif row.tx_cat=='full-splice_match' and row.tx_5hang<0 and row.pr_ntermhang>0:
            return 'pISM,cand_ntrunc,,assume nterm novel'
        elif (row.tx_cat=='novel_in_catalog' or row.tx_cat=='novel_not_in_catalog') and row.pr_ntermhang<0 and row.pr_ctermhang==0:
            return 'pNIC,alt_nterm,,assume nterm novel'
        elif (row.tx_cat=='full-splice_match' or row.tx_cat=='incomplete-splice_match') and row.tx_5hang>0 and row.pr_ntermhang<0 and row.pr_ctermhang==0:
            return 'pNIC,alt_nterm,,assume nterm novel'
        elif row.pr_nterm_diff==0 and row.pr_cterm_diff!=0:
            return 'pISM,cand_ctrunc,,'
        elif row.tx_cat=='full-splice_match' and row.pr_cterm_diff==0 and row.tx_5hang<0 and row.pr_ntermhang<0:
            return 'pISM,cand_ntrunc,,'
        elif row.pr_ntermhang<0 and row.pr_ctermhang<0:
            return 'unicorn?,,,'
        elif row.pr_ntermhang>0 and row.pr_ctermhang==0:
            return 'pNIC,alt_nterm,,'
        elif row.pr_nterm_gene_diff!=0 and row.pr_ntermhang>0:
            return 'pNNC,novel_nterm_known_splice_known_cterm,,'
        elif row.pr_nterm_gene_diff==0 and row.pr_ctermhang>0:
            return 'unicorn?,,,'
        elif row.pr_ntermhang>0 and row.pr_ctermhang>0:
            return 'unicorn?,,,'
        else:
            return 'orphan'
    return ''

def classify_protein_splice_ism(row):
    if row.pr_cat=='incomplete-splice_match' and 'mono-exon' not in row.pr_subcat:
        if row.pr_nterm_diff==0 and row.pr_cterm_diff!=0 and row.pr_ctermhang<0:
            return 'pISM,cand_ctrunc,,'
        elif row.pr_nterm_diff==0 and row.pr_cterm_diff!=0 and row.pr_cterm_gene_diff!=0 and row.pr_ctermhang>0:
            return 'pNNC,known_nterm_known_splice_novel_cterm,is_nmd?,'
        elif row.pr_nterm_diff==0 and row.pr_cterm_diff!=0 and row.pr_cterm_gene_diff==0 and row.pr_ctermhang>0:
            return 'pNIC,known_nterm_known_splice_alt_cterm,is_nmd?,'
        elif row.tx_cat=='incomplete-splice_match' and row.pr_nterm_diff!=0 and row.tx_5hang<0 and row.pr_ntermhang<0:
            return 'pISM,cand_ntrunc,,'
        elif row.tx_cat=='incomplete-splice_match' and row.pr_nterm_diff!=0 and row.pr_cterm_diff==0 and row.tx_5hang<=10 and row.pr_ntermhang<0:
            return 'pISM,cand_ntrunc,,'
        elif row.tx_cat=='full-splice_match' and row.pr_nterm_diff!=0 and row.pr_cterm_diff==0 and row.pr_ntermhang<0:
            return 'pISM,cand_ntrunc,,'
        elif row.tx_cat=='novel_in_catalog' and row.pr_nterm_diff!=0 and row.pr_cterm_diff==0 and row.pr_nterm_gene_diff!=0 and row.pr_ntermhang<0:
            return 'pNNC,novel_nterm_known_splice_known_cterm,,'
        elif row.tx_cat=='novel_not_in_catalog' and row.pr_nterm_diff!=0 and row.pr_cterm_diff==0 and row.pr_nterm_gene_diff==0 and row.pr_ntermhang<0:
            return 'pNIC,alt_nterm_known_splice_known_cterm,,'
        elif row.tx_cat=='novel_not_in_catalog' and row.pr_nterm_diff!=0 and row.pr_cterm_diff==0 and row.pr_nterm_gene_diff!=0 and row.pr_ntermhang<0:
            return 'pNNC,novel_nterm_known_splice_known_cterm,,'
        elif row.pr_nterm_diff!=0 and row.pr_cterm_diff==0 and row.pr_nterm_gene_diff==0 and row.pr_ntermhang>0:
            return 'pNIC,alt_nterm_known_splice_known_cterm,,'
        elif row.pr_nterm_diff!=0 and row.pr_cterm_diff==0 and row.pr_nterm_gene_diff!=0 and row.pr_ntermhang>0:
            return 'pNNC,novel_nterm_known_splice_known_cterm,,'
        elif row.pr_nterm_diff!=0 and row.pr_cterm_diff!=0:
            return 'unicorn?,,,'
        else:
            return 'orphan_ism'
    return ''
    
def classify_protein_splice_nic(row):
    if row.pr_cat=='novel_in_catalog' and 'mono-exon' not in row.pr_subcat:
        if row.pr_nterm_gene_diff==0 and row.pr_cterm_gene_diff==0:
            return 'pNIC,known_nterm_combo_splice_known_cterm,,'
        elif row.pr_nterm_gene_diff!=0 and row.pr_cterm_gene_diff==0:
            return 'pNNC,novel_nterm_combo_splice_known_cterm,,'
        elif row.pr_nterm_gene_diff==0 and row.pr_cterm_gene_diff!=0:
            return 'pNNC,known_nterm_combo_splice_novel_cterm,is_nmd?,'
        elif row.pr_nterm_gene_diff!=0 and row.pr_cterm_gene_diff!=0:
            return 'pNNC,novel_nterm_combo_splice_novel_cterm,is_nmd?,'
        else:
            return 'orphan_nic'
    return ''

def classify_protein_splice_nnc(row):
    if row.pr_cat=='novel_not_in_catalog':
        if row.pr_nterm_gene_diff==0 and row.pr_cterm_gene_diff==0:
            return 'pNNC,known_nterm_novel_splice_known_cterm,,'
        elif row.pr_nterm_gene_diff!=0 and row.pr_cterm_gene_diff==0:
            return "pNNC,novel_nterm_novel_splice_known_cterm,,could be FL or 5' deg product"
        elif row.pr_nterm_gene_diff==0 and row.pr_cterm_gene_diff!=0:
            return 'pNNC,known_nterm_novel_splice_novel_cterm,is_nmd?,could be FL or NMD product'
        elif row.pr_nterm_gene_diff!=0 and row.pr_cterm_gene_diff!=0:
            return 'pNNC,novel_nterm_novel_splice_novel_cterm,is_nmd?,,'
        else:
            return 'orphan_nnc'
    return ''

def classify_protein_splice_monoexon(row):
    if row.pr_subcat=='mono-exon' or row.pr_subcat=='mono-exon_by_intron_retention':
        if row.pr_cat=='full-splice_match' and row.pr_nterm_diff==0 and row.pr_cterm_diff==0:
            return 'pFSM,mono-exon,,'
        elif row.pr_cat=='intergenic':
            return 'intergenic,mono-exon,,'
        elif row.pr_nterm_gene_diff==0:
            return 'trunc/altnterm'
        else:
            return 'orphan_monoexon'
    return ''

def classify_protein_splice_misc(row):
    if row.pr_subcat=='multi-exon':
        if row.pr_cat=='intergenic':
            return 'intergenic,multi-exon,,'
        elif row.pr_cat=='fusion':
            return 'fusion,multi-exon,,'
    return ''


def classify_protein(row):
    fsm_classiciation = classify_protein_splice_fsm(row)
    ism_classificaiton = classify_protein_splice_ism(row)
    nic_classification = classify_protein_splice_nic(row)
    nnc_classification = classify_protein_splice_nnc(row)
    mono_classification = classify_protein_splice_monoexon(row)
    misc_classification = classify_protein_splice_misc(row)
    return (
        fsm_classiciation+
        ism_classificaiton+
        nic_classification+
        nnc_classification+
        mono_classification+
        misc_classification
    )
    

def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--sqanti_protein', action='store', dest='sqanti_protein', help='sqanti protein classification file')
    parser.add_argument('--name', action='store',dest='name')
    args = parser.parse_args()

    protein_classification = pd.read_table(args.sqanti_protein)
    protein_classification['protein_classification'] = protein_classification.apply(classify_protein, axis = 1)
    cats = protein_classification["protein_classification"].str.split(",", n = 1, expand = True)
    protein_classification['protein_classification_base'] = cats[0]
    protein_classification['protein_classification_subset'] = cats[1]

    protein_classification.to_csv(f'{args.name}.protein_classification.tsv', sep='\t', index = False)


if __name__ == "__main__":
    main()
# %%

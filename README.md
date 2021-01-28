# README

A docker image for running [SQANTI3](https://github.com/ConesaLab/SQANTI3)

## Usage

There are two main Python scripts in SQANTI3: `sqanti3_qc.py` and `sqanti3_RulesFilter.py`. They can be run in the image as follows:

[sqanti3_qc.py](https://github.com/ConesaLab/SQANTI3#running-sqanti3-quality-control-script)

```
# Using the most recent version
docker run --rm joelnitta/sqanti3:latest sqanti3_qc.py --help
# Using a specific version of SQANTI3
docker run --rm joelnitta/sqanti3:1.6.0 sqanti3_qc.py --help
```

[sqanti3_RulesFilter.py](https://github.com/ConesaLab/SQANTI3#filtering-isoforms-using-sqanti3-output-and-a-pre-defined-rules)

```
# Using the most recent version
docker run --rm joelnitta/sqanti3:latest sqanti3_RulesFilter.py --help
# Using a specific version of SQANTI3
docker run --rm joelnitta/sqanti3:1.6.0 sqanti3_RulesFilter.py --help
```

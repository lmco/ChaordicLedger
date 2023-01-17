import argparse
import json
import os

def concatenatePerConfiguration(inputdir: str, output:str):
    order = None
    
    with open(os.path.join(inputdir, "concatenationConfig.json"), "r") as f:
        order = json.load(f)
    
    with open(output, "w") as outfile:
        for file in order:
            with open(os.path.join(inputdir, file), "r") as f:
                outfile.writelines(f.readlines())
                outfile.writelines([os.linesep])

if __name__ == "__main__":
    parser = argparse.ArgumentParser(
        description='Converts gathered Kubernetes metrics from tabular form to JSON.')
    parser.add_argument('-i', '--inputdir',
                        help="The input directory.", required=True)
    parser.add_argument('-o', '--output',
                        help="The output file.", required=True)

    args = parser.parse_args()

    concatenatePerConfiguration(args.inputdir, args.output)
    print(f"Done concatenating files from {args.inputdir} to {args.output}")

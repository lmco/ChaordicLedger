import argparse
import pandas as pd
from treelib import Tree

def showHierarchy(csvFile: str):
    df = pd.read_csv(csvFile, dtype="U")

    tree = Tree()

    for index, row in df.iterrows():
        print(f'{index}: {row["parentBinding"]} {row["Name"]}')
        parentBinding=str(row["parentBinding"])
        name=str(row["Name"])

        if parentBinding == "nan":
            parentBinding=None

        tree.create_node(name, name, parentBinding)

    tree.show(line_type="ascii-em")

if __name__ == "__main__":
    parser = argparse.ArgumentParser(
        description='Visualizes the hierarchy of a CSV file containing requirements and tests.')
    parser.add_argument('-i', '--input',
                        help="The input CSV file.", required=True)

    args = parser.parse_args()

    showHierarchy(args.input)

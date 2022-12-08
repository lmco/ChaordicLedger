import argparse
import json

if __name__ == "__main__":
    parser = argparse.ArgumentParser(
        description='Visualizes resource usage samples as graphs.')
    parser.add_argument('-i', '--input',
                        help="The input file.", required=True)
    parser.add_argument('-v', '--valuecolumn',
                        help="The value column.", required=True)
    parser.add_argument('-o', '--output',
                        help="The output file.", required=True)

    args = parser.parse_args()


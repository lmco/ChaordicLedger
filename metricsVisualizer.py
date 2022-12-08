import argparse
import os
import matplotlib.pyplot as plt
import pandas as pd

def plotData(csvFile, column, prefix, outputdir):
    df = pd.read_csv(csvFile)
    outputFile=os.path.join(outputdir, f"{prefix}_{column.lower()}.png")

    pd.options.display.float_format = '{:.2f}'.format

    plt.rcParams["figure.figsize"] = [13.753, 8.5]
    plt.rcParams["figure.autolayout"] = True
    plt.rcParams["savefig.format"] = 'png'
    plt.title(f'{column} over Time', fontsize=30)
    plt.xlabel('Timestamp', fontsize=15)
    plt.ylabel(column, fontsize=15)

    lineplot = df.groupby('Timestamp')[column].sum().plot.line(colormap='jet', lw=2, grid=True)

    # Rotating X-axis labels
    plt.xticks(rotation=25)

    lineplot.figure.savefig(outputFile)

if __name__ == "__main__":
    parser = argparse.ArgumentParser(
        description='Visualizes resource usage samples as graphs.')
    parser.add_argument('-i', '--input',
                        help="The input CSV file.", required=True)
    parser.add_argument('-c', '--column',
                        help="The column to sum.", required=True)
    parser.add_argument('-p', '--prefix',
                        help="The output file's prefix.", required=True)
    parser.add_argument('-o', '--outputdir',
                        help="The output directory.", required=True)

    args = parser.parse_args()

    plotData(args.input, args.column, args.prefix, args.outputdir)

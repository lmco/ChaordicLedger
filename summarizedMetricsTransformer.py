import argparse
import json


def convertInputToJSON(inputFile: str):
    # Expected format is:
    #   Timestamp
    #   Header
    #   1-N pods

    state = "Timestamp"

    with open(inputFile, "r") as f:
        data = {}
        instantData = None
        samples = None
        sample = None
        headers = None
        podCount = 0
        for line in f:
            if state == "Timestamp":
                timestamp = line.strip()
                headers = []
                samples = []
                instantData = {"timestamp": timestamp, "samples": samples}
                data[timestamp] = instantData
                state = "Header"
            elif state == "Header":
                headers = line.strip().split()
                state = "Pods"
            elif state == "Pods":
                if line == "---":
                    state = "Timestamp"
                else:
                    sample = {}
                    podCount += 1
                    elements = line.strip().split()
                    for i in range(0, len(elements)):
                        filteredHeader = headers[i].replace("(", "_").replace(")", "")
                        sample[filteredHeader] = elements[i]
                    samples.append(sample)
                    # Hack for count ... need a delimiter between each sample.
                    if podCount >= 19:
                        state = "Timestamp"
                        podCount = 0

    return data


def writeJSON(content: dict, outputFile: str):
    with open(outputFile, "w") as f:
        json.dump(content, f, indent=4)


if __name__ == "__main__":
    parser = argparse.ArgumentParser(
        description="Converts gathered Kubernetes metrics from tabular form to JSON."
    )
    parser.add_argument("-i", "--input", help="The input file.", required=True)
    parser.add_argument("-o", "--output", help="The output file.", required=True)

    args = parser.parse_args()

    result = convertInputToJSON(args.input)
    writeJSON(result, args.output)
    print("Done")

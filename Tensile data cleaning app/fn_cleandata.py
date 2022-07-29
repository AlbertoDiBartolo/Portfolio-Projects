import pandas as pd


def cleaning(data):
    # cleans and formats the data

    # the selected file is converted to a pandas dataframe
    df = pd.read_csv(
        data,
        encoding="ISO-8859-1",
        names=[
            "info",
            "dL (mm)",
            "F (kN)",
            "specimen",
            "strain (%)",
            "stress (MPa)",
            "thickness (mm)",
        ],
    )

    #  Replace NaN with empty
    df = df.fillna("")

    #  Retrieve the values of thickness ("spessore") for each specimen
    thicknesses = [
        float(line.replace("    Spessore:         ", "").replace(" mm", ""))
        for line in df["info"]
        if "Spessore" in line
    ]

    #  Drop rows where the field "dL (mm)" is empty
    df = df[df["dL (mm)"] != ""]

    #  Populate the "specimen" field and "thickness" field
    df["info"] = df["info"].astype("int")
    specimens = []
    thick_col = []
    counter = 0

    for line in df["info"]:
        if (
            line == 1
        ):  #  the "info" field resets to 1 at the start of each specimen datapoints
            counter += 1
        specimens.append(counter)
        thick_col.append(thicknesses[counter - 1])

    df["specimen"] = specimens
    df["thickness (mm)"] = thick_col

    #  Populate "strain (%)" field (strain = dL/length_0)
    length_0 = 30  # initial length in mm, a constant value
    df["strain (%)"] = df["dL (mm)"] / length_0 * 100

    #  Populate "stress (MPa)" field (stress = F/A, A = thickness*width)
    width = 10  # width in mm, a constant value
    df["stress (MPa)"] = df["F (kN)"] * 1000 / width / thick_col
    df = df.reset_index(drop=True)

    return df, len(thicknesses)

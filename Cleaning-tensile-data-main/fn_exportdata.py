# Import
from tkinter import Tk, Button, ttk
from tkinter.filedialog import askopenfile, asksaveasfilename
import pandas as pd


def save_data(df, n_specimens):
    # saveas .xlsx
    savefile = asksaveasfilename(filetypes=[("Excel files", ".xlsx")])
    with pd.ExcelWriter(savefile + ".xlsx") as writer:
        df.to_excel(
            writer, sheet_name="Data", index=False
        )  # save the whole dataframe to the first sheet
        for i in range(
            n_specimens
        ):  # the data for each specimen are saved to separate sheets
            df[df["specimen"] == i + 1].to_excel(
                writer, sheet_name=f"specimen{i+1}", index=False
            )

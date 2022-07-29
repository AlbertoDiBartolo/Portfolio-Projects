# import Python libraries
from tkinter import Tk, Button, ttk
from tkinter.filedialog import askopenfile, asksaveasfilename
import pandas as pd

# import local libraries
from fn_cleandata import cleaning
from fn_exportdata import save_data

# instantiate Tk
root = Tk()
root.geometry("100x100")
root.eval("tk::PlaceWindow . center")


def clean_file():
    # button command; opens, cleans, and savesas data to xlsx

    # file selection
    loadfile = askopenfile(mode="r", filetypes=[("Excel files", ".csv")])

    # run the cleaning function
    df, n_specimens = cleaning(loadfile)

    # run the save function
    save_data(df=df, n_specimens=n_specimens)


Button(root, text="Clean File", command=clean_file).pack()


root.mainloop()

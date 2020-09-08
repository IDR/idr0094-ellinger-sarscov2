import pandas
import sys
import re

def printusage():
    print('''
Changes all upper or all lower case strings to capitalised case,
e. g. disodium sebacate -> Disodium sebacate or 
ENILCONAZOLE SULFATE -> Enilconazole sulfate.
Works on fields with word characters, spaces and hyphens only.
Ignores all capital strings shorter than 5 characters (these 
might be valid abbreviations).

Usage:
python fix_capitals.py [path to csv] [field] [path to output csv]
e.g. 
python fix_capitals.py annotations.csv "Compound Name" output.csv
        ''')


if len(sys.argv) < 4 or sys.argv[1] == '-h' or sys.argv[1] == '--help':
    printusage()
    sys.exit(1)


all_cap = re.compile('^[A-Z- ]{6,}$')
all_lc = re.compile('^[a-z- ]+$')


def change(field):
    # return field.title()
    return field.capitalize()


df = pandas.read_csv(sys.argv[1], dtype=str, keep_default_na=False)
for index, row in df.iterrows():
    field = row[sys.argv[2]]
    if all_cap.match(field) or all_lc.match(field):
        print("{}: {} -> {}".format((index+1), field, change(field)))
        df[sys.argv[2]][index] = change(field)

df.to_csv(sys.argv[3])

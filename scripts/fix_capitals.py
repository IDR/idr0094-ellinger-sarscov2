import pandas
import sys
import re

def printusage():
    print('''
Changes all upper or all lower case or title case strings to 
capitalised case, e. g. 
disodium sebacate -> Disodium sebacate or 
ENILCONAZOLE SULFATE -> Enilconazole sulfate or
Sodium Nitrite -> Sodium nitrite.
Works on fields with word characters, spaces and hyphens only.
Ignores all capital strings shorter than 5 characters (these 
might be valid abbreviations). For example something like
VLX600 would not be changed. Also tries to fix some common
typos, like missing space e.g. SodiumNitrite.

Usage:
python fix_capitals.py [path to csv] [field] [path to output csv]
e.g. 
python fix_capitals.py annotations.csv "Compound Name" output.csv
        ''')


if len(sys.argv) < 4 or sys.argv[1] == '-h' or sys.argv[1] == '--help':
    printusage()
    sys.exit(1)


all_uc = re.compile('^[A-Z- ]{6,}$') # all upper case
all_lc = re.compile('^[a-z- ]+$') # all lower case
tc = re.compile('^[A-Z][a-z]+[- ][A-Z][a-z]+$') # title case
typo_1 = re.compile('^([A-Z][a-z]+)([A-Z][a-z]+)$') # e.g. SodiumNitrite


def fix_typos(field):
    m = typo_1.match(field)
    if m:
        return "{} {}".format(m.group(1), m.group(2))
    return field


df = pandas.read_csv(sys.argv[1], dtype=str, keep_default_na=False)
for index, row in df.iterrows():
    field = row[sys.argv[2]].strip()
    field = fix_typos(field)
    if all_uc.match(field) or all_lc.match(field) or tc.match(field):
        print("{}: {} -> {}".format((index+1), field, field.capitalize()))
        df[sys.argv[2]][index] = field.capitalize()

df.to_csv(sys.argv[3], index=False)

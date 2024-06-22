import os

#creating a directory where japanese tex file will be saved
def create_directory(directory_path):
    if not os.path.exists(directory_path):
        os.makedirs(directory_path)
        print(f"Directory '{directory_path}' created.")
    else:
        print(f"Directory '{directory_path}' already exists. Skipping creation.")

mypath =  '/Users/kawabatahatsu/ibes-japan/ibes-japan/japanese_table'
#mypath =  '/Users/tsenga/ibes-japan/ibes-japan/japanese_table'
create_directory(mypath)

#Translating and saving the files
def replace_words_in_tex(input_path, output_dir, replacements):

    with open(input_path, 'r', encoding='utf-8') as file:
        content = file.read()
    
    for old_word, new_word in replacements.items():
        content = content.replace(old_word, new_word)
    
    os.makedirs(output_dir, exist_ok=True)
    
    output_path = os.path.join(output_dir, os.path.basename(input_path))
    
    with open(output_path, 'w', encoding='utf-8') as file:
        file.write(content)
    
    print(f"File saved to {output_path}")

input_path = '/Users/kawabatahatsu/ibes-japan/ibes-japan/table/desc_stats_a.tex'
#input_path = '/Users/tsenga/ibes-japan/ibes-japan/table/desc_stats_a.tex'
output_dir = mypath
replacements = {
    'mean': '平均',
    'sd': '標準偏差',
    'Realised EPS': 'EPS実現値（円）',
    'Forecast Dispersion': '予測誤差',
    'Median Estimated EPS': '予測EPS（円）',
    'Number of Estimates': 'カバレッジ（人）',
    'Forecast Error Log': '予測誤差（対数）',
    'Forecast Error Percentage': '予測誤差（パーセント）',
    'Observations ': '観察数',
}

replace_words_in_tex(input_path, output_dir, replacements)




import os

#creating a directory where japanese tex file will be saved
def create_directory(directory_path):
    if not os.path.exists(directory_path):
        os.makedirs(directory_path)
        print(f"Directory '{directory_path}' created.")
    else:
        print(f"Directory '{directory_path}' already exists. Skipping creation.")

#mypath =  '/Users/kawabatahatsu/ibes-japan/ibes-japan/japanese_table'
mypath =  '/Users/tsenga/ibes-japan/ibes-japan/table'
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

#desc_stats_a.tex
#input_path = '/Users/kawabatahatsu/ibes-japan/ibes-japan/table/desc_stats_a.tex'
input_path = '/Users/tsenga/ibes-japan/ibes-japan/table/desc_stats_a.tex'
output_dir = mypath
replacements = {
    'mean': '平均',
    'sd': '標準偏差',
    'Realised EPS': 'EPS実現値（円）',
    'Forecast Dispersion': '予測分散',
    'Median Estimated EPS': '予測EPS（円）',
    'Number of Estimates': 'アナリスト数（人）',
    'Forecast Error Log': '予測誤差（対数）',
    'Forecast Error Percentage': '予測誤差（%）',
    'Observations': '観察数',
}
replace_words_in_tex(input_path, output_dir, replacements)

#desc_stats_b
#input_path = '/Users/kawabatahatsu/ibes-japan/ibes-japan/table/desc_stats_b.tex'
input_path = '/Users/tsenga/ibes-japan/ibes-japan/table/desc_stats_b.tex'
output_dir = mypath
replacements = {
    'mean': '平均',
    'sd': '標準偏差',
    'Realised EPS': 'EPS実現値（円）',
    'Forecast Dispersion': '予測分散',
    'Median Estimated EPS': '予測EPS（円）',
    'Number of Estimates': 'アナリスト数（人）',
    'Forecast Error Log': '予測誤差（対数）',
    'Forecast Error Percentage': '予測誤差（%）',
    'Market Capitalization (YEN)': '時価総額（円）',
    'Sales (Mil. YEN)': '売上高（円）',
    'Observations': '観察数',
}
replace_words_in_tex(input_path, output_dir, replacements)

#reg_T01
#input_path = '/Users/kawabatahatsu/ibes-japan/ibes-japan/table/reg_T01.tex'
input_path = '/Users/tsenga/ibes-japan/ibes-japan/table/reg_T01.tex'
output_dir = mypath
replacements = {
    '(mean) NUMEST': 'アナリスト数',
    'ln\_sale': '売上高（対数）',
    'ln\_age': '企業年齢(対数) ',
    '(mean) SD\_ACTUAL\_growth': 'EPSボラティリティ',
    '(mean) stockvol': '株価ボラティリティ',
    'Year FE': '年固定効果',
    'Firm FE': '企業固定効果',
    'Observations': '観察数',
}
replace_words_in_tex(input_path, output_dir, replacements)

#reg_T02
#input_path = '/Users/kawabatahatsu/ibes-japan/ibes-japan/table/reg_T02.tex'
input_path = '/Users/tsenga/ibes-japan/ibes-japan/table/reg_T02.tex'
output_dir = mypath
replacements = {
    '(mean) NUMEST': 'アナリスト数',
    'ln\_sale': '売上高（対数）',
    'ln\_age': '企業年齢(対数) ',
    '(mean) SD\_ACTUAL\_growth': 'EPSボラティリティ',
    '(mean) stockvol': '株価ボラティリティ',
    'Year FE': '年固定効果',
    'Firm FE': '企業固定効果',
    'Observations': '観察数',
}
replace_words_in_tex(input_path, output_dir, replacements)

#reg_T02
#input_path = '/Users/kawabatahatsu/ibes-japan/ibes-japan/table/reg_T02.tex'
input_path = '/Users/tsenga/ibes-japan/ibes-japan/table/reg_T02.tex'
output_dir = mypath
replacements = {
    '(mean) ACTUAL': 'EPS実現値',
    'ln\_sale': '売上高（対数）',
    'ln\_age': '企業年齢(対数) ',
    '(mean) SD\_ACTUAL\_growth': 'EPSボラティリティ',
    '(mean) stockvol': '株価ボラティリティ',
    'Year FE': '年固定効果',
    'Firm FE': '企業固定効果',
    'Observations': '観察数',
}
replace_words_in_tex(input_path, output_dir, replacements)

#cross_correlation
#input_path = '/Users/kawabatahatsu/ibes-japan/ibes-japan/table/cross_correlation.tex'
input_path = '/Users/tsenga/ibes-japan/ibes-japan/table/cross_correlation.tex'
output_dir = mypath
replacements = {
    'Variable': '変数',
    'Fdis': '平均予測誤差',
    'vol': 'EPU（移動平均）',
    'IIP': '鉱工業生産(製造業ALL)',
    'nikkei': 'NIKKEI 225',
    'Firm FE': '企業固定効果',
    'Observations': '観察数',
}
replace_words_in_tex(input_path, output_dir, replacements)

#reg_ts_1
#input_path = '/Users/kawabatahatsu/ibes-japan/ibes-japan/table/reg_ts_1.tex'
input_path = '/Users/tsenga/ibes-japan/ibes-japan/table/reg_ts_1.tex'
output_dir = mypath
replacements = {
    'EPU': '政策不確実性指数',
    'Stock volatility': '株価ボラティリティ',
    'vol': 'EPU（移動平均）',
    'IIP': '鉱工業生産(製造業ALL)',
    'nikkei': '日経平均',
    'Firm FE': '企業固定効果',
    'Observations': '観察数',
    'Model 1': '-',
    'Model 2': '月固定効果',
    'Model 3': '年固定効果',
    'Model 4': '-',
    'Model 5': '月固定効果',
    'Model 6': '年固定効果',
}
replace_words_in_tex(input_path, output_dir, replacements)


#reg_ts_2
#input_path = '/Users/kawabatahatsu/ibes-japan/ibes-japan/table/reg_ts_2.tex'
input_path = '/Users/tsenga/ibes-japan/ibes-japan/table/reg_ts_2.tex'
output_dir = mypath
replacements = {
    'Forecast dispersion': '予測分散',
    'Forecast error': '予測誤差',
    'vol': 'EPU（移動平均）',
    'IIP': '鉱工業生産(製造業ALL)',
    'nikkei': '日経平均',
    'Firm FE': '企業固定効果',
    'Observations': '観察数',
    'Model 1': '-',
    'Model 2': '月固定効果',
    'Model 3': '年固定効果',
    'Model 4': '-',
    'Model 5': '月固定効果',
    'Model 6': '年固定効果',
}
replace_words_in_tex(input_path, output_dir, replacements)



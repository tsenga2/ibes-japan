import os

# Get a list of all PNG files in the Graph directory
graph_dir = "/Users/kawabatahatsu/Desktop/ra/IBES/international/graph"
png_files = [f for f in os.listdir(graph_dir) if f.endswith('.png')]

# Generate LaTeX code for the slides with one PNG figure per slide
latex_code = "\\documentclass{beamer}\n\\usepackage{graphicx}\n\n\\begin{document}\n\n"
    
    
for png_file in png_files:
    latex_code += "\\begin{frame}\n	\\frametitle{"+ png_file +"}\n	\\centering\n"
    latex_code += "	\\includegraphics[width=0.8\\linewidth]{" + os.path.join(graph_dir, png_file) + "}\n\n"
    latex_code += "	\\begin{itemize}\n		\\item\n	\\end{itemize}\n"
    latex_code += "\\end{frame}\n\n"

latex_code += "\\end{document}"

print(latex_code)


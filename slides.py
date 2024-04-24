import os
import pyperclip

# Get a list of all PNG files in the Graph directory
#graph_dir = "/Users/kawabatahatsu/Desktop/ra/IBES/international/graph"
graph_dir = "/Users/tsenga/ibes-japan/ibes-japan/graph"
table_dir = "/Users/tsenga/ibes-japan/ibes-japan/table"

# List all PNG and text files
png_files = sorted([f for f in os.listdir(graph_dir) if f.endswith('.png')])
text_files = sorted([f for f in os.listdir(table_dir) if f.endswith('.tex')])

# Start generating LaTeX code
latex_code = "\\documentclass{beamer}\n\\usepackage{graphicx}\n\\usepackage{verbatim}\n\n\\begin{document}\n\n"

# Generate slides for each PNG file
for png_file in png_files:
    latex_code += "\\begin{frame}\n	\\frametitle{" + png_file + "}\n	\\centering\n"
    latex_code += "	\\includegraphics[width=0.8\\linewidth]{" + os.path.join(graph_dir, png_file) + "}\n"
    latex_code += "\\end{frame}\n\n"

# Generate slides for each text file
for text_file in text_files:
    file_path = os.path.join(table_dir, text_file)
    latex_code += "\\begin{frame}[fragile]\n\t\\frametitle{" + text_file + "}\n"
    latex_code += "\t\\begin{table}[!htbp]\n"
    latex_code += "\t\\centering\n"
    latex_code += "\t\\resizebox{\\linewidth}{!}{\n"
    latex_code += "\t\\begin{threeparttable}\n"
    latex_code += "\t\\input{" + file_path + "}\n"
    latex_code += "\t\\begin{tablenotes}\n"
    latex_code += "\t\\footnotesize\n"
    latex_code += "\t\\item\n"
    latex_code += "\t\\end{tablenotes}\n"
    latex_code += "\t\\end{threeparttable}\n"
    latex_code += "\t}\n"
    latex_code += "\t\\end{table}\n"
    latex_code += "\\end{frame}\n\n"

latex_code += "\\end{document}"

pyperclip.copy(latex_code)

# Save the LaTeX code to a file named "slides.tex"
with open("slides.tex", "w") as file:
    file.write(latex_code)

!apt-get install graphviz -y
!pip install graphviz

from graphviz import Digraph
from IPython.display import Image, display
from google.colab import files

dot = Digraph("SNAP_Framework")

# Layout
dot.attr(rankdir="TB", splines="true", nodesep="0.35", ranksep="0.5")

# Node styles
dot.attr("node",
         shape="box",
         style="filled",
         fillcolor="white",
         fontname="Arial",
         fontsize="11")

# Edge styles
dot.attr("edge",
         fontname="Arial",
         fontsize="9")

# Nodes
dot.node("EconDemo",
         "Economic & Demographic Characteristics\n"
         "(Income ≤130% FPL, HH size, Age, Education, Employment)")

dot.node("Eligibility",
         "Program Eligibility\n"
         "(Gross ≤130% FPL; Net ≤100% FPL; Asset limits)")

dot.node("Selection",
         "Self-Selection Factors\n"
         "(Food hardship, health, admin barriers, motivation)")

dot.node("SNAP",
         "SNAP Participation")

dot.node("Intermediate",
         "Intermediate Effects\n"
         "(Food access, dietary choices, resource reallocation)")

dot.node("Outcome",
         "Household Food Security Outcome\n"
         "(Food secure / Insecure)",
         fillcolor="palegreen")

# Confounder
dot.node("Confound",
         "Unobserved confounding",
         shape="ellipse",
         style="dashed",
         fillcolor="white",
         color="gray40",
         fontcolor="gray40")

# Main arrows
dot.edge("EconDemo", "Eligibility", label="Determines")
dot.edge("Eligibility", "Selection", label="Influences")
dot.edge("Selection", "SNAP", label="Participation decision")
dot.edge("SNAP", "Intermediate", label="Benefit use")
dot.edge("Intermediate", "Outcome", label="Outcome change")

# Dashed arrows
dot.edge("Confound", "Selection",
         style="dashed",
         color="gray50")

dot.edge("Confound", "Outcome",
         style="dashed",
         color="gray50")

# Save 
dot.format = "png"
dot.attr(dpi="1000")

dot.render("snap_framework_final", cleanup=True)

# Display image
display(Image(filename="snap_framework_final.png"))

# Download
files.download("snap_framework_final.png")

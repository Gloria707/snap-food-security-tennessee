#!apt-get install graphviz
#!pip install graphviz

from graphviz import Digraph
from google.colab import files

dot = Digraph("SNAP_Framework", format="pdf")  
dot.attr(rankdir="TB", dpi="1000")

dot.attr(rankdir="TB", fontname="Arial")

# Node styles
dot.attr('node', shape="box", style="filled", fillcolor="white", fontsize="12")

# Nodes
dot.node("EconDemo",
         "Economic & Demographic Characteristics\n(Income ≤130% FPL, HH size, Age, Education, Employment)",
         fillcolor="white")

dot.node("Eligibility",
         "Program Eligibility\n(Gross ≤130% FPL; Net ≤100% FPL; Asset limits)",
         fillcolor="white")

dot.node("Selection",
         "Self-Selection Factors\n(Food hardship, health, admin barriers, motivation)",
         fillcolor="white")

dot.node("SNAP",
         "SNAP Participation",
         fillcolor="white")

dot.node("Intermediate",
         "Intermediate Effects\n(Food access, dietary choices, resource reallocation)",
         fillcolor="white")

dot.node("Outcome",
         "Household Food Security Outcome\n(Food secure / Insecure)",
         fillcolor="palegreen")

# Confounding ellipse
dot.node("Confound",
         "Unobserved confounding",
         shape="ellipse",
         style="dashed",
         fillcolor="white",
         fontcolor="gray40")

# Solid arrows
dot.edge("EconDemo", "Eligibility", label="Determines")
dot.edge("Eligibility", "Selection", label="Influences")
dot.edge("Selection", "SNAP", label="Participation decision")
dot.edge("SNAP", "Intermediate", label="Benefit use")
dot.edge("Intermediate", "Outcome", label="Outcome change")

# Dotted confounding edges
dot.edge("Confound", "Selection", style="dashed", color="gray40")
dot.edge("Confound", "Outcome", style="dashed", color="gray40")

# Save
dot.render("snap_framework", format="png", cleanup=True)

files.download("snap_framework.png")

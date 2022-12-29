# Tableau: Enhanced Markdown Tables for Quarto

Tableau is a Quarto extension that simplifies table layout by separating
data from layout.

Here are some sample tables:

* Easy spans, partial underlines

  ![An APA Style table](README_ASSETS/apa.png)

* Different heading styles
* Lines under every _n_ rows

  ![County data](README_ASSETS/counties.png)

* Block level cell content (single cell and spanned)

  ![Lorem](README_ASSETS/lorem.png)

* Nontraditional layout

  ![Various layouts](README_ASSETS/funky.png)

The layout language is vaguely dynamic. The following example shows the
markup on the left and the result on the right. The layout section uses
the special variables `$r` (the number of rows), and `@r` (the current
row being generated. It also does arithmetic.

![Multiplication table](README_ASSETS/times-table.png)

## Documentation

A combined guide and reference [is available](...).

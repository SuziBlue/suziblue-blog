---
title: Testing Some $\LaTeX$ in Markdown
layout: post
date: 2026-08-08
---

Einstein said $E=mc^2$.

This is a math block

$$
\int_{0}^{\infty} e^{-x^2}\,dx = \frac{\sqrt{\pi}}{2}
$$

This is a commutative diagram for $f: A\rightarrow B, g: B\rightarrow C, g\circ f: A\rightarrow C$

<script type="text/tikz">
\begin{tikzpicture}[  >=stealth,  node distance=2.5cm,  line width=0.5pt]
    \node (A) {$A$};
    \node (B) [right=of A] {$B$};
    \node (C) [below=of B] {$C$};

    \draw[->] (A) -- node[above] {$f: A\rightarrow B$} (B);
    \draw[->] (B) -- node[right]  {$g: B\rightarrow C$} (C);

    \draw[->,dashed] (A) -- node[below left] {$g\circ f: A\rightarrow C$} (C);
\end{tikzpicture}
</script>

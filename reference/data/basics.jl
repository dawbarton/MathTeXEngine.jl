BASICS = Dict()

BASICS["accents"] = [
    L"\dot{Q} \dot{q}",
    L"\vec{A} \vec{a}",
    L"\bar{L} \bar{l}",
    L"\hat{\Phi} \bar{\varphi}"
]

BASICS["delimiters"] = [
    L"(1 + 2) (\frac{1}{2})",
    L"\left(1 + 2\right) \left(\frac{1}{2}\right)",
    L"\left[a + b\right] \left[\frac{a}{b}\right]",
    L"\left{A + B \right} + \left{\frac{A}{B}\right}",
    L"\left{\alpha + \beta \right} + \left{\frac{\alpha}{\beta}\right}",
    L"\left{1 + \left[2 + \left(3 + 4\right)\right]\right}"
]

BASICS["fonts"] = [
    L"\mathrm{bonjour}",
    L"\mathbb{R} \mathbb{Q} \mathbb{C}",
    L"\mathcal{N} \mathcal{K}"
]

BASICS["fractions"] = [
    L"\frac{a + b + c}{c + b + a}",
    L"\frac{a}{A + B + C}",
    L"\frac{j - f}{f - j}"
]

BASICS["functions"] = [
    L"\sin{\omega} + \cos{\theta}",
    L"\exp{\log{2}} = 2",
    L"\inf_{x} \tan(x) \leq \sup_{x} \tan(x)" 
]

BASICS["infix"] = [
    L"T + V",
    L"7 - 2",
    L"v \cdot w",
    L"E = m c^2"
]

BASICS["integrals"] = [
    L"\int_a^b",
    L"\int \int \int"
]

BASICS["linebreaks"] = [
    L"we clearly see $x = 22$\\and $y > x^2$"
]

BASICS["punctuation"] = [
    L"x!",
    L"23.17",
    L"10,000"
]

BASICS["spaces"] = [
    L"a \! b",
    L"a \; b",
    L"a \quad b",
    L"a \qquad b"
]

BASICS["square_roots"] = [
    L"\sqrt{2}",
    L"\sqrt{\frac{1}{2}}",
    L"\sqrt{b^2 - 4ac}",
    L"\sqrt{1 + \frac{A + B}{J + U}}"
]

BASICS["subsuper"] = [
    L"V^1_2",
    L"U_{ij}",
    L"W^{(i + j)}",
    L"x_L x_y x_{y \rightarrow 0}",
    L"N_\nu L_\nu A_\nu J_\nu",
    L"N^\nu L^\nu A^\nu J^\nu",
    L"^{87} Rb"
]

BASICS["symbols"] = [
    L"k\xi",
    L"\alpha \beta \gamma \delta \epsilon \omega \theta \phi \varphi \psi",
    L"\Gamma \Delta \Omega \Theta \Phi \Psi",
    L"\nabla \rightarrow \neq \leq \hbar",
    L"\text{phi} \rightarrow \phi \quad \text{varphi} \rightarrow \varphi",
    L"\text{epsilon} \rightarrow \epsilon \quad \text{varepsilon} \rightarrow \varepsilon"
]

BASICS["underover"] = [
    L"\sum_{n = 1}^{m^2}",
    L"\sum_{N = 1}^{M^2}",
    L"\prod_{n \neq m}",
    L"\prod_{N \neq M}"
]
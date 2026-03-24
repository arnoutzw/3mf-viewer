#set document(title: "Bambu Viewer — UML Diagrams")

// Title page
#page(paper: "a4", margin: 1cm)[
  #align(center + horizon)[
    #text(size: 28pt, weight: "bold")[Bambu Viewer]
    #v(1em)
    #text(size: 16pt, fill: rgb("#666"))[UML Diagrams]
  ]
]

// uml-architecture.svg: 2784x1751 -> landscape
#page(paper: "a4", flipped: true, margin: 1cm)[
  #text(size: 9pt, fill: rgb("#999"))[uml-architecture]
  #v(0.3em)
  #align(center + horizon)[
    #image("uml-architecture.svg", width: 100%, height: 100%, fit: "contain")
  ]
]

// uml-class-diagram.svg: 2291x3869 -> portrait
#page(paper: "a4", margin: 1cm)[
  #text(size: 9pt, fill: rgb("#999"))[uml-class-diagram]
  #v(0.3em)
  #align(center + horizon)[
    #image("uml-class-diagram.svg", width: 100%, height: 100%, fit: "contain")
  ]
]

// uml-seq-gallery.svg: 1254x3357 -> portrait
#page(paper: "a4", margin: 1cm)[
  #text(size: 9pt, fill: rgb("#999"))[uml-seq-gallery]
  #v(0.3em)
  #align(center + horizon)[
    #image("uml-seq-gallery.svg", width: 100%, height: 100%, fit: "contain")
  ]
]

// uml-seq-load.svg: 1339x3616 -> portrait
#page(paper: "a4", margin: 1cm)[
  #text(size: 9pt, fill: rgb("#999"))[uml-seq-load]
  #v(0.3em)
  #align(center + horizon)[
    #image("uml-seq-load.svg", width: 100%, height: 100%, fit: "contain")
  ]
]

// uml-states.svg: 994x1416 -> portrait
#page(paper: "a4", margin: 1cm)[
  #text(size: 9pt, fill: rgb("#999"))[uml-states]
  #v(0.3em)
  #align(center + horizon)[
    #image("uml-states.svg", width: 100%, height: 100%, fit: "contain")
  ]
]

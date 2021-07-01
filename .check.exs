[
  tools: [
    {:compiler, env: %{"MIX_ENV" => "test"}},
    {:formatter, env: %{"MIX_ENV" => "test"}},
    {:ex_doc, false},
    {:sobelow, "mix sobelow --config"}
  ]
]

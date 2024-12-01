[
  inputs: ~w[
    {mix,.formatter,.credo}.exs
    {config,lib,rel,test}/**/*.{ex,exs,zig}
    installer/**/*.{ex,exs}
  ],
  plugins: [Zig.Formatter],
  line_length: 80
]

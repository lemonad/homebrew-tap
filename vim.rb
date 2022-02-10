class Vim < Formula
  desc "Vi 'workalike' with many additional features"
  homepage "https://www.vim.org/"
  # vim should only be updated every 50 releases on multiples of 50
  url "https://github.com/vim/vim/archive/v8.2.4300.tar.gz"
  sha256 "00e95d6bda783c2119a10cb25ba50d44a1378d372d7b8546de8b5746ac89db5a"
  license "Vim"
  revision 1
  head "https://github.com/vim/vim.git", branch: "master"

  bottle do
    sha256 arm64_monterey: "759bb62427355e68bcdde43b941b4329c14cc4e9f4a8bbdba0469a4fe354d53d"
    sha256 arm64_big_sur:  "16270ba0f756ec59fe80e643acff7a3bab80e10be824bbaf02457edce87674c7"
    sha256 monterey:       "7bf9f1efe6438c870095192a53dbbd9891898acd6c1ff296df93a7e8a17469ab"
    sha256 big_sur:        "1286dc1bc015241c72010d904b7ad789822e7fcca8bedd0a6080d344b99d5402"
    sha256 catalina:       "aa4a042aca20e5ddbf8f96cf182935c89310d4548b83ae04be4018bb6c22ee19"
    sha256 x86_64_linux:   "714018114c9fbd30b3728cbb1c40c17e41f6d3d99f5d27687cc519f144003118"
  end
  # env:std

  option "with-client-server", "Enable client/server mode"

  depends_on "gettext"
  depends_on "lua"
  depends_on "ncurses"
  depends_on "perl"
  depends_on "python@3.10"
  depends_on "ruby"
  depends_on "libx11" if build.with? "client-server"

  conflicts_with "ex-vi",
    because: "vim and ex-vi both install bin/ex and bin/view"

  conflicts_with "macvim",
    because: "vim and macvim both install vi* binaries"

  def install
    ENV.prepend_path "PATH", Formula["python@3.10"].opt_libexec/"bin"

    # https://github.com/Homebrew/homebrew-core/pull/1046
    ENV.delete("SDKROOT")

    # vim doesn't require any Python package, unset PYTHONPATH.
    ENV.delete("PYTHONPATH")

    opts = []
    if build.with? "client-server"
      opts << "--with-x"
      opts << "--x-includes=/opt/X11/include"
      opts << "--x-libraries=/opt/X11/lib"
    else
      opts << "--without-x"
    end

    # We specify HOMEBREW_PREFIX as the prefix to make vim look in the
    # the right place (HOMEBREW_PREFIX/share/vim/{vimrc,vimfiles}) for
    # system vimscript files. We specify the normal installation prefix
    # when calling "make install".
    # Homebrew will use the first suitable Perl & Ruby in your PATH if you
    # build from source. Please don't attempt to hardcode either.
    system "./configure", "--prefix=#{HOMEBREW_PREFIX}",
                          "--mandir=#{man}",
                          "--enable-multibyte",
                          "--with-tlib=ncurses",
                          "--with-compiledby=Homebrew",
                          "--enable-cscope",
                          "--enable-terminal",
                          "--enable-perlinterp",
                          "--enable-rubyinterp",
                          "--enable-python3interp",
                          "--enable-gui=no",
                          "--enable-luainterp",
                          "--with-lua-prefix=#{Formula["lua"].opt_prefix}",
                          *opts
    system "make"
    # Parallel install could miss some symlinks
    # https://github.com/vim/vim/issues/1031
    ENV.deparallelize
    # If stripping the binaries is enabled, vim will segfault with
    # statically-linked interpreters like ruby
    # https://github.com/vim/vim/issues/114
    system "make", "install", "prefix=#{prefix}", "STRIP=#{which "true"}"
    bin.install_symlink "vim" => "vi"
  end

  test do
    (testpath/"commands.vim").write <<~EOS
      :python3 import vim; vim.current.buffer[0] = 'hello python3'
      :wq
    EOS
    system bin/"vim", "-T", "dumb", "-s", "commands.vim", "test.txt"
    assert_equal "hello python3", File.read("test.txt").chomp
    assert_match "+gettext", shell_output("#{bin}/vim --version")
  end
end

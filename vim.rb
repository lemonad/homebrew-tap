class Vim < Formula
  desc "Vi 'workalike' with many additional features"
  homepage "https://www.vim.org/"
  # vim should only be updated every 25 releases on multiples of 25
  url "https://github.com/vim/vim/archive/v8.2.3075.tar.gz"
  sha256 "500d52af2cacfd39d403547c68677d99f2c7cfb3e18d99bc374d7a89d5d5d6b2"
  license "Vim"
  head "https://github.com/vim/vim.git"

  bottle do
    sha256 arm64_big_sur: "ff2aa9e157895b8266f695c4d87bbf4669ec798546b86dd5ab55d471d6ffd3ef"
    sha256 big_sur:       "a42064ecac026679b3d168f908b1dc47002d636339c23fa6fb6a91d5dd1916cf"
    sha256 catalina:      "784916b71abf53e1ad373f52497b51e60f270441c101e403e8723775be24284c"
    sha256 mojave:        "ef7b7f8e9bb78a05552bebacd90585f6b2154085d20de22f6388f9e595d667aa"
  end
  # env:std

  option "with-client-server", "Enable client/server mode"

  depends_on "gettext"
  depends_on "lua"
  depends_on "perl"
  depends_on "python@3.9"
  depends_on "ruby"
  depends_on "libx11" if build.with? "client-server"

  # uses_from_macos "ncurses"
  depends_on "ncurses"

  conflicts_with "ex-vi",
    because: "vim and ex-vi both install bin/ex and bin/view"

  conflicts_with "macvim",
    because: "vim and macvim both install vi* binaries"

  def install
    ENV.prepend_path "PATH", Formula["python@3.9"].opt_libexec/"bin"

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

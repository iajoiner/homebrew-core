class StoneSoup < Formula
  include Language::Python::Virtualenv

  desc "Dungeon Crawl Stone Soup: a roguelike game"
  homepage "https://crawl.develz.org/"
  url "https://github.com/crawl/crawl/archive/0.29.1.tar.gz"
  sha256 "e8ff1d09718ab3cbff6bac31651185b584c9eea2c9b6f42f0796127ca5599997"
  license "GPL-2.0-or-later"

  livecheck do
    url :stable
    regex(/^v?(\d+(?:\.\d+)+)$/i)
  end

  bottle do
    sha256 arm64_monterey: "cf6ca59c6899897889fb1dd675513941085da9832c565009a33f35d0eaa8d983"
    sha256 arm64_big_sur:  "e68f79cdfbee9e2c50c26785becab8a8e5060105657f7ea2ed1ceaf5efef83e5"
    sha256 monterey:       "7772ce20e270a7bfbc0cf3838aa780a5679eb7733987835606d7596ab64d8846"
    sha256 big_sur:        "fdc9152a3b611d3c905f86e07073bb871d2fe93f69c1940b0ab6a907c8403fd7"
    sha256 catalina:       "edbc05d07621b8424656f6d997cfce5cdae087fd4fc2f624fcd85e6f61fd8c27"
    sha256 x86_64_linux:   "eef057937a3400fbf577121fd0a8567d0295b6d1c0dd5985ee202f11a59bee57"
  end

  depends_on "pkg-config" => :build
  depends_on "python@3.10" => :build
  depends_on "lua@5.1"
  depends_on "pcre"
  depends_on "sqlite"

  fails_with gcc: "5"

  resource "PyYAML" do
    url "https://files.pythonhosted.org/packages/36/2b/61d51a2c4f25ef062ae3f74576b01638bebad5e045f747ff12643df63844/PyYAML-6.0.tar.gz"
    sha256 "68fb519c14306fec9720a2a5b45bc9f0c8d1b9c72adf45c37baedfcd949c35a2"
  end

  def install
    ENV.cxx11
    ENV.prepend_path "PATH", Formula["python@3.10"].opt_libexec/"bin"
    python3 = "python3.10"
    ENV.prepend_create_path "PYTHONPATH", buildpath/"vendor"/Language::Python.site_packages(python3)

    venv = virtualenv_create(buildpath/"vendor", python3)
    venv.pip_install resource("PyYAML")

    cd "crawl-ref/source" do
      File.write("util/release_ver", version.to_s)
      args = %W[
        prefix=#{prefix}
        DATADIR=data
        NO_PKGCONFIG=
        BUILD_ZLIB=
        BUILD_SQLITE=
        BUILD_FREETYPE=
        BUILD_LIBPNG=
        BUILD_LUA=
        BUILD_SDL2=
        BUILD_SDL2MIXER=
        BUILD_SDL2IMAGE=
        BUILD_PCRE=
        USE_PCRE=y
      ]

      unless OS.mac?
        args += %W[
          CFLAGS=-I#{Formula["pcre"].opt_include}
          LDFLAGS=-ldl
        ]
      end

      # FSF GCC doesn't support the -rdynamic flag
      args << "NO_RDYNAMIC=y" unless ENV.compiler == :clang

      # The makefile has trouble locating the developer tools for
      # CLT-only systems, so we set these manually. Reported upstream:
      # https://crawl.develz.org/mantis/view.php?id=7625
      #
      # On 10.9, stone-soup will try to use xcrun and fail due to an empty
      # DEVELOPER_DIR
      if OS.mac?
        devdir = MacOS::Xcode.prefix.to_s
        devdir += "/" unless MacOS::Xcode.installed?

        args += %W[
          DEVELOPER_DIR=#{devdir}
          SDKROOT=#{MacOS.sdk_path}
          SDK_VER=#{MacOS.version}
        ]
      end

      system "make", "install", *args
    end
  end

  test do
    output = shell_output("#{bin}/crawl --version")
    assert_match "Crawl version #{version}", output
  end
end

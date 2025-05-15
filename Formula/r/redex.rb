class Redex < Formula
  include Language::Python::Shebang
  include Language::Python::Virtualenv

  desc "Bytecode optimizer for Android apps"
  homepage "https://fbredex.com/"
  url "https://github.com/facebook/redex/archive/refs/tags/v2025.09.18.tar.gz"
  sha256 "49be286761fb89a223a9609d58faa141e584a0c6866bf083d8408357302ee2f8"
  license "MIT"
  head "https://github.com/facebook/redex.git", branch: "main"

  bottle do
    sha256 cellar: :any,                 arm64_tahoe:   "4290ded870843ef5a0f59274fe9242982c77542a1cbb367408151473849b21a1"
    sha256 cellar: :any,                 arm64_sequoia: "c894e5072ff2ebbdd21b9bcecf12d5468f6e2c1e51fe27d2d5a2ee83480b5301"
    sha256 cellar: :any,                 arm64_sonoma:  "8b739a35ed027e227bcc48ea375d6c0d7a8c7a20888a8319f828993b34a68107"
    sha256 cellar: :any,                 sonoma:        "c2eca79d391a44a6645c4d0cd17982c07316a49f20a4f3ff0b3bf5190936014b"
    sha256 cellar: :any_skip_relocation, arm64_linux:   "576c939a85047bae7e36eb7821407eb2046eb746069b4b8e5a13635837338799"
    sha256 cellar: :any_skip_relocation, x86_64_linux:  "40a31fbf584c6f289032c1d257dc26cefb218e744ff934e0d5a99c3c48c229ff"
  end

  depends_on "autoconf" => :build
  depends_on "automake" => :build
  depends_on "libevent" => :build
  depends_on "libtool" => :build
  depends_on "boost"
  depends_on "jsoncpp"
  depends_on "python@3.14"

  pypi_packages package_name: "", extra_packages: ["packaging"]

  resource "packaging" do
    url "https://files.pythonhosted.org/packages/a1/d4/1fc4078c65507b51b96ca8f8c3ba19e6a61c8253c72794544580a7b6c24d/packaging-25.0.tar.gz"
    sha256 "d443872c98d677bf60f6a1f2f8c1cb748e8fe762d2bf9d3148b5599295b0fc4f"
  end

  # Replace `pipes` usage for python 3.13
  patch do
    url "https://github.com/facebook/redex/commit/b9c7d5abf922eea7e38bc6031607eb30e8482f38.patch?full_index=1"
    sha256 "6e644764d2e2b3a7b8e69c8887e738fc6c6099f5f4a3bb6738eae6fd5677da6a"
  end

  def install
    # Skip tests, which require an Android SDK
    inreplace "Makefile.am", "SUBDIRS = . test", "SUBDIRS = ."

    venv = virtualenv_create(libexec, "python3.14")
    venv.pip_install resources
    rewrite_shebang python_shebang_rewrite_info(venv.root/"bin/python"), "redex.py"

    system "autoreconf", "--force", "--install", "--verbose"
    system "./configure", "--disable-silent-rules",
                          "--disable-tests",
                          "--disable-kotlin-tests",
                          "--with-boost=#{Formula["boost"].opt_prefix}",
                          *std_configure_args
    system "make"
    system "make", "install"
    pkgshare.install "test/instr/redex-test.apk"
  end

  test do
    system bin/"redex", "--ignore-zipalign",
                        "-Jignore_no_keep_rules=true",
                        pkgshare/"redex-test.apk", "-o", "redex-test-out.apk"
    assert_path_exists testpath/"redex-test-out.apk"
  end
end

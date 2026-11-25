class P3 < Formula
  desc "Pascal compiler built on LLVM"
  homepage "https://github.com/MrLuis/p3"
  url "https://github.com/MrLuis/p3/archive/refs/tags/v0.1.1-rc.2.tar.gz"
  sha256 "a20ee187a23c8fed1797ea2d41f8cd1600b7d6bd0f471e116261e42ea5fcfcc6"
  license "Apache-2.0" => { with: "LLVM-exception" }
  head "https://github.com/MrLuis/p3.git", branch: "main"

  bottle do
    root_url "https://github.com/MrLuis/homebrew-p3/releases/download/p3-0.1.1-rc.2"
    sha256               arm64_tahoe:   "b7959881780f661d4f8cf035f57bd05073b18a23a75cad1ea487dd415b9bb5b4"
    sha256               arm64_sequoia: "e1d1e01455122063263d5dec1f153328d37264d7ab06c7fe756fceea7477f82d"
    sha256 cellar: :any, x86_64_linux:  "5aefbacc6241b7754f1eaa18205a24bb582dc083cdc3cb7ccb705680416280b1"
  end

  depends_on "cmake" => :build
  depends_on "ninja" => :build
  depends_on "python@3.14" => :build
  depends_on "llvm"

  def install
    llvm = Formula["llvm"]
    args = %W[
      -DLLVM_DIR=#{llvm.opt_lib}/cmake/llvm
      -DPython3_EXECUTABLE=#{which("python3.14")}
      -DP3_CROSS_TARGETS=OFF
    ]
    system "cmake", "-S", ".", "-B", "build", "-G", "Ninja", *args, *std_cmake_args
    # The compiler, its runtime (and the runtime's IR, for inlining) and the
    # unit library: not the tests or the self-hosted compiler.
    system "cmake", "--build", "build", "--target", "p3", "pascalrt", "pascalrt-ir", "rtl"
    system "cmake", "--install", "build"
  end

  test do
    assert_path_exists lib/"pascal/libpascalrt.ll"

    (testpath/"hello.pas").write <<~PASCAL
      program hello;
      begin
        writeln('Hello, World!');
      end.
    PASCAL
    system bin/"p3", "hello.pas", "-o", "hello"
    assert_equal "Hello, World!", shell_output("./hello").chomp

    # A library unit, at -O2 (inlined runtime) and from its installed object.
    (testpath/"units.pas").write <<~PASCAL
      program units;
      uses sysutils;
      begin
        writeln(UpperCase('installed'), ' ', IntToStr(6 * 7));
      end.
    PASCAL
    system bin/"p3", "--mode=objfpc", "-O2", "units.pas", "-o", "units"
    assert_equal "INSTALLED 42", shell_output("./units").chomp
    system bin/"p3", "--mode=objfpc", "-O2", "-fseparate-units", "units.pas", "-o", "separate"
    assert_equal "INSTALLED 42", shell_output("./separate").chomp
  end
end

class P3 < Formula
  desc "Pascal compiler built on LLVM"
  homepage "https://github.com/MrLuis/p3"
  url "https://github.com/MrLuis/p3/archive/refs/tags/v0.1.1-rc.5.tar.gz"
  sha256 "6b8b48c3ae49fe2c811ae7be2b3a051b0ba1948fb0ecb8f9a133b6b40390cfef"
  license "Apache-2.0" => { with: "LLVM-exception" }
  head "https://github.com/MrLuis/p3.git", branch: "main"

  livecheck do
    url :stable
    regex(/^v?(\d+(?:\.\d+)+(?:-rc\.\d+)?)$/i)
  end

  bottle do
    root_url "https://github.com/MrLuis/homebrew-p3/releases/download/p3-0.1.1-rc.5"
    sha256               arm64_tahoe:   "17208c2ebc2bfb0dd17e7aa5de73d20152faec51b5e5134207aaac2a7c076db0"
    sha256               arm64_sequoia: "4d531e97bed60dda9ccb47a8f76574fe178719bd00f80a6b6bc3122b640642c5"
    sha256 cellar: :any, x86_64_linux:  "ba7974400fab4cdcbfacc3cd52ccf0bc5e5c08d3017da1fa5aff6e79b6adb169"
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

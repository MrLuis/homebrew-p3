class P3 < Formula
  desc "Pascal compiler built on LLVM"
  homepage "https://github.com/MrLuis/p3"
  url "https://github.com/MrLuis/p3/archive/refs/tags/v0.1.1-rc.1.tar.gz"
  sha256 "658c4d248a14f758f53d4595598eb56cbfdac82f171e6120051308be04011cb8"
  license "Apache-2.0" => { with: "LLVM-exception" }
  head "https://github.com/MrLuis/p3.git", branch: "main"

  depends_on "cmake" => :build
  depends_on "ninja" => :build
  depends_on "python@3.14" => :build
  depends_on "llvm@23"

  def install
    llvm = Formula["llvm@23"]
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
    assert_path_exists lib/"libpascalrt.ll"

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

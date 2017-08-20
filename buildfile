# file      : buildfile
# copyright : Copyright (c) 2014-2017 Code Synthesis Ltd
# license   : MIT; see accompanying LICENSE file

./: tests/ doc{INSTALL LICENSE NEWS README version} file{manifest}

# The version file is auto-generated (by the version module) from manifest.
# Include it in distribution and don't remove when cleaning in src (so that
# clean results in a state identical to distributed).
#
doc{version}: file{manifest}
doc{version}: dist  = true
doc{version}: clean = ($src_root != $out_root)

# Don't install tests or the INSTALL file.
#
dir{tests/}:     install = false
doc{INSTALL}@./: install = false

if! $cxx.features.modules
{
  # List sources as files so that we can prepare a distribution with any
  # compiler.
  #
  ./: {mxx cxx}{*}
}
else
{
  # We only do the static library since this is what we would have gotten
  # should we have used headers (i.e., whatever object code generated from
  # those headers would have ended up in each executable/library).
  #
  ./: liba{std-modules}

  # Building of the modules gets rather compiler-specific.
  #
  if ($cxx.id.type == 'clang')
  {
    # Use the naming scheme expected by -fprebuilt-module-path=. Can also be
    # specified with -fmodule-file=.
    #
    core = std.core.pcm
    io   = std.io.pcm

    liba{std-modules}: bmia{$core $io}

    export_target = $out_root/liba{std-modules}
  }
  elif ($cxx.id.type == 'msvc')
  {
    # Use the naming scheme expected by /module:stdIfcDir. Note that IFCPATH
    # would require an extra directory (x64 or x86; e.g., x64/Release/).
    #
    # @@ Currently VC looks in Release regardless of /MD or /MDd.
    #
    dir  = release/
    core = $dir/std.core.ifc
    io   = $dir/std.io.ifc

    bmia{$core $io}: fsdir{$dir}

    # VC expects to find std.lib next to the .ifc's. Make it the real one
    # while std-modules -- a dummy.
    #
    ./: $dir/liba{std}
    $dir/liba{std}: bmia{$core $io}
    liba{std-modules}: cxx{dummy.cxx}

    # @@ Doesn't work if installed so we don't bother installing it. But we
    #    still install dummy std-modules; the idea is to link a dummy and
    #    (try) to use Microsoft-shipped .ifc's.
    #
    $dir/liba{std}: install = false

    # Include std-modules to trigger install.
    #
    export_target = $out_root/$dir/liba{std} $out_root/liba{std-modules}
  }

  # @@ TMP: use utility library instead?
  #
  if ($cxx.target.class == 'linux' || $cxx.target.class == 'bsd')
    cxx.coptions += -fPIC

  # Clang 5.0 with libc++ (sometimes) needs it -- go figure.
  #
  if ($cxx.target.class != "windows")
    cxx.libs += -lpthread

  bmia{$core}: mxx{std-core}
  bmia{$io}:   mxx{std-io} bmia{$core}

  mxx{std-core}@./: cc.module_name = std.core
  mxx{std-io}@./:   cc.module_name = std.io

  ./: mxx{std-core std-io} # @@ install

  # Install into the libstd-modules/ subdirectory of, say, /usr/include/.
  #
  mxx{*}: install = include/$project/
}
